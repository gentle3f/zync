import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import {
  ensureAccountForIdentity,
  issuePackEntitlement,
  linkIdentityToAccount,
  listOwnershipSnapshot,
  normalizeIdentityInput,
  normalizePackIssueInput,
} from '../../api/_cardverse/ownership_store.js';

const migration = await readFile(
  new URL('../../db/migrations/0001_cardverse_ownership.sql', import.meta.url),
  'utf8',
);
const spec = await readFile(
  new URL('../../docs/ZYNC_CARDVERSE_CLOUD_OWNERSHIP_V1.md', import.meta.url),
  'utf8',
);
const pkg = JSON.parse(await readFile(new URL('../../package.json', import.meta.url), 'utf8'));

for (const table of [
  'zync_accounts',
  'zync_identity_links',
  'cardverse_pack_entitlements',
  'cardverse_stack_balances',
  'cardverse_unique_instances',
  'cardverse_idempotency_records',
  'cardverse_inventory_ledger',
]) {
  assert.match(migration, new RegExp('CREATE TABLE IF NOT EXISTS ' + table));
}

assert.match(migration, /UNIQUE \(provider, provider_subject\)/);
assert.match(migration, /UNIQUE \(account_id, provider\)/);
assert.match(migration, /locked_quantity <= quantity/);
assert.match(migration, /GENERATED ALWAYS AS IDENTITY PRIMARY KEY/);
assert.match(migration, /BEFORE UPDATE OR DELETE OR TRUNCATE/);
assert.match(migration, /cardverse_reject_ledger_mutation/);
assert.match(migration, /cardverse_pack_entitlements_grant_uidx/);
assert.equal(pkg.dependencies?.postgres, '^3.4.9');

assert.match(spec, /Neon-hosted PostgreSQL/);
assert.match(spec, /mobile app must never connect directly to PostgreSQL/i);
assert.match(spec, /Upstash Redis[\s\S]*not[\s\S]*Cardverse inventory/i);
assert.match(spec, /Production remains closed/);

assert.deepEqual(
  normalizeIdentityInput({
    provider: ' Google ',
    providerSubject: 'sub-123',
    providerEmail: 'person@example.com',
    emailVerified: true,
  }),
  {
    provider: 'google',
    providerSubject: 'sub-123',
    providerEmail: 'person@example.com',
    emailVerified: true,
  },
);
assert.throws(
  () => normalizeIdentityInput({ provider: 'email', providerSubject: 'x' }),
  /cardverse_identity_provider_invalid/,
);

const ACCOUNT = '11111111-1111-4111-8111-111111111111';
const GRANT = '22222222-2222-4222-8222-222222222222';
const PACK = '33333333-3333-4333-8333-333333333333';
const LEDGER_EVENT = '44444444-4444-4444-8444-444444444444';

assert.deepEqual(
  normalizePackIssueInput({
    accountId: ACCOUNT,
    grantId: GRANT,
    packType: 'STANDARD',
    idempotencyKey: 'quest:weekly:0001',
  }),
  {
    accountId: ACCOUNT,
    grantId: GRANT,
    packType: 'standard',
    idempotencyKey: 'quest:weekly:0001',
  },
);

{
  const calls = [];
  const tx = {
    async query(text, params = []) {
      calls.push({ text, params });
      if (text.includes('pg_advisory_xact_lock')) return [];
      if (text.includes('FROM zync_identity_links l')) return [];
      if (text.includes('INSERT INTO zync_accounts')) {
        return [{
          id: ACCOUNT,
          status: 'active',
          created_at: '2026-09-20T00:00:00.000Z',
        }];
      }
      if (text.includes('INSERT INTO zync_identity_links')) return [];
      throw new Error('unexpected query: ' + text);
    },
  };
  const db = { query: tx.query, transaction: (fn) => fn(tx) };

  const result = await ensureAccountForIdentity(db, {
    provider: 'google',
    providerSubject: 'google-user-1',
    providerEmail: 'person@example.com',
    emailVerified: true,
  });
  assert.equal(result.created, true);
  assert.equal(result.account.id, ACCOUNT);
  assert.equal(calls.some((call) => call.text.includes('pg_advisory_xact_lock')), true);
  assert.equal(calls.some((call) => call.text.includes('INSERT INTO zync_accounts')), true);
  assert.equal(calls.some((call) => call.text.includes('INSERT INTO zync_identity_links')), true);
}

{
  let insertedAccount = false;
  const tx = {
    async query(text) {
      if (text.includes('pg_advisory_xact_lock')) return [];
      if (text.includes('FROM zync_identity_links l')) {
        return [{
          id: ACCOUNT,
          status: 'active',
          created_at: '2026-09-20T00:00:00.000Z',
        }];
      }
      if (text.includes('INSERT INTO zync_accounts')) {
        insertedAccount = true;
        return [];
      }
      throw new Error('unexpected query: ' + text);
    },
  };
  const db = { query: tx.query, transaction: (fn) => fn(tx) };
  const result = await ensureAccountForIdentity(db, {
    provider: 'apple',
    providerSubject: 'apple-user-1',
  });
  assert.equal(result.created, false);
  assert.equal(insertedAccount, false);
}

{
  const tx = {
    async query(text) {
      if (text.includes('pg_advisory_xact_lock')) return [];
      if (text.includes('SELECT id, status FROM zync_accounts')) {
        return [{ id: ACCOUNT, status: 'active' }];
      }
      if (text.includes('WHERE provider = $1 AND provider_subject = $2')) return [];
      if (text.includes('WHERE account_id = $1 AND provider = $2')) return [];
      if (text.includes('INSERT INTO zync_identity_links')) return [];
      throw new Error('unexpected query: ' + text);
    },
  };
  const db = { query: tx.query, transaction: (fn) => fn(tx) };
  const result = await linkIdentityToAccount(db, ACCOUNT, {
    provider: 'apple',
    providerSubject: 'apple-user-2',
    emailVerified: true,
  });
  assert.deepEqual(result, {
    accountId: ACCOUNT,
    provider: 'apple',
    linked: true,
  });
}

{
  const calls = [];
  const tx = {
    async query(text, params = []) {
      calls.push({ text, params });
      if (text.includes("WHERE id = $1 AND status = 'active'")) return [{ id: ACCOUNT }];
      if (text.includes('INSERT INTO cardverse_idempotency_records')) {
        return [{ request_hash: 'reserved' }];
      }
      if (text.includes('FROM cardverse_pack_entitlements') && text.includes('grant_id')) return [];
      if (text.includes('INSERT INTO cardverse_pack_entitlements')) {
        return [{
          pack_id: PACK,
          account_id: ACCOUNT,
          grant_id: GRANT,
          pack_type: 'standard',
          status: 'unopened',
          version: 1,
          issued_at: '2026-09-20T00:01:00.000Z',
        }];
      }
      if (text.includes('INSERT INTO cardverse_inventory_ledger')) {
        return [{ sequence: 7, event_id: LEDGER_EVENT }];
      }
      if (text.includes('UPDATE cardverse_idempotency_records')) return [];
      throw new Error('unexpected query: ' + text);
    },
  };
  const db = { query: tx.query, transaction: (fn) => fn(tx) };
  const result = await issuePackEntitlement(db, {
    accountId: ACCOUNT,
    grantId: GRANT,
    packType: 'standard',
    idempotencyKey: 'quest:weekly:0001',
  });
  assert.equal(result.packId, PACK);
  assert.equal(result.status, 'unopened');
  assert.equal(result.ledgerSequence, 7);
  assert.equal(result.ledgerEventId, LEDGER_EVENT);
  assert.equal(result.idempotentReplay, false);
  assert.equal(calls.some((call) => call.text.includes('INSERT INTO cardverse_inventory_ledger')), true);
  assert.equal(calls.some((call) => call.text.includes('UPDATE cardverse_idempotency_records')), true);
}

{
  const normalized = normalizePackIssueInput({
    accountId: ACCOUNT,
    grantId: GRANT,
    packType: 'standard',
    idempotencyKey: 'quest:weekly:0001',
  });
  const crypto = await import('node:crypto');
  const requestHash = crypto.createHash('sha256')
    .update(JSON.stringify({
      accountId: normalized.accountId,
      grantId: normalized.grantId,
      packType: normalized.packType,
    }))
    .digest('hex');
  const persisted = {
    packId: PACK,
    accountId: ACCOUNT,
    grantId: GRANT,
    packType: 'standard',
    status: 'unopened',
    version: 1,
    issuedAt: '2026-09-20T00:01:00.000Z',
    ledgerSequence: 7,
    ledgerEventId: LEDGER_EVENT,
  };
  let minted = false;
  const tx = {
    async query(text) {
      if (text.includes("WHERE id = $1 AND status = 'active'")) return [{ id: ACCOUNT }];
      if (text.includes('INSERT INTO cardverse_idempotency_records')) return [];
      if (text.includes('SELECT request_hash, response_json')) {
        return [{ request_hash: requestHash, response_json: persisted }];
      }
      if (text.includes('INSERT INTO cardverse_pack_entitlements')) {
        minted = true;
        return [];
      }
      throw new Error('unexpected query: ' + text);
    },
  };
  const db = { query: tx.query, transaction: (fn) => fn(tx) };
  const result = await issuePackEntitlement(db, {
    accountId: ACCOUNT,
    grantId: GRANT,
    packType: 'standard',
    idempotencyKey: 'quest:weekly:0001',
  });
  assert.equal(result.packId, PACK);
  assert.equal(result.idempotentReplay, true);
  assert.equal(minted, false);
}

{
  const responses = [
    [{ id: ACCOUNT, status: 'active', created_at: '2026-09-20T00:00:00.000Z' }],
    [{ variant_key: 'sports.badminton|core|normal', quantity: 2, locked_quantity: 1, version: 3, updated_at: '2026-09-20T00:02:00.000Z' }],
    [],
    [{ pack_id: PACK, grant_id: GRANT, pack_type: 'standard', status: 'unopened', version: 1, issued_at: '2026-09-20T00:01:00.000Z' }],
    [{ ledger_cursor: 7 }],
  ];
  const db = {
    async query() {
      return responses.shift();
    },
  };
  const snapshot = await listOwnershipSnapshot(db, ACCOUNT);
  assert.equal(snapshot.account.id, ACCOUNT);
  assert.equal(snapshot.ledgerCursor, 7);
  assert.equal(snapshot.balances[0].quantity, 2);
  assert.equal(snapshot.balances[0].lockedQuantity, 1);
  assert.equal(snapshot.unopenedPacks[0].packId, PACK);
}

console.log('✓ Cardverse durable ownership SQL/domain contracts passed');

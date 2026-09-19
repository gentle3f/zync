import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import {
  normalizePackOpenRequest,
  normalizeServerRollPlan,
  openPack,
} from '../../api/_cardverse/pack_store.js';

const migration1 = await readFile(
  new URL('../../db/migrations/0001_cardverse_ownership.sql', import.meta.url),
  'utf8',
);
const migration2 = await readFile(
  new URL('../../db/migrations/0002_cardverse_pack_rolls.sql', import.meta.url),
  'utf8',
);

assert.match(migration1, /finish_id text NOT NULL/);
assert.match(migration1, /edition_id text NOT NULL/);
assert.match(migration1, /acquisition_source text NOT NULL/);
assert.doesNotMatch(migration1, /finish text NOT NULL/);
assert.match(migration2, /CREATE TABLE IF NOT EXISTS cardverse_pack_rolls/);
assert.match(migration2, /pack_id uuid NOT NULL UNIQUE/);
assert.match(migration2, /CREATE TABLE IF NOT EXISTS cardverse_pack_roll_items/);
assert.match(migration2, /PRIMARY KEY \(server_roll_id, position\)/);

const ACCOUNT = '11111111-1111-4111-8111-111111111111';
const PACK = '22222222-2222-4222-8222-222222222222';
const GRANT = '33333333-3333-4333-8333-333333333333';
const ROLL = '44444444-4444-4444-8444-444444444444';

assert.deepEqual(
  normalizePackOpenRequest({
    packId: PACK,
    idempotencyKey: 'pack-open-attempt-0001',
    clientRevealVersion: 1,
  }),
  {
    packId: PACK,
    idempotencyKey: 'pack-open-attempt-0001',
    clientRevealVersion: 1,
  },
);

for (const forbidden of ['seed', 'randomSeed', 'result', 'cards', 'finish', 'rarity', 'odds', 'accountId']) {
  assert.throws(
    () => normalizePackOpenRequest({
      packId: PACK,
      idempotencyKey: 'pack-open-attempt-0001',
      clientRevealVersion: 1,
      [forbidden]: 'client-choice',
    }),
    /cardverse_pack_open_client_authority_forbidden/,
  );
}

const plan = normalizeServerRollPlan({
  policyVersion: 1,
  items: [
    { canonicalInterestId: 'sports.badminton', finishId: 'normal', editionId: 'core_set_1', ownershipKind: 'stackable' },
    { canonicalInterestId: 'food.coffee', finishId: 'foil', editionId: 'core_set_1', ownershipKind: 'stackable' },
    { canonicalInterestId: 'outdoors.bouldering', finishId: 'holo', editionId: 'core_set_1', ownershipKind: 'stackable' },
    { canonicalInterestId: 'music.piano', finishId: 'prism', editionId: 'discovery', ownershipKind: 'stackable' },
    { canonicalInterestId: 'travel.japan', finishId: 'legendary', editionId: 'core_set_1', ownershipKind: 'stackable' },
  ],
});
assert.equal(plan.items.length, 5);
assert.equal(plan.items[0].variantKey, 'sports.badminton::normal::core_set_1');

{
  let rollerInput = null;
  let rollItemWrites = 0;
  let creditWrites = 0;
  let idempotencySaved = false;
  const tx = {
    async query(text) {
      if (text.includes("SELECT id FROM zync_accounts")) return [{ id: ACCOUNT }];
      if (text.includes('INSERT INTO cardverse_idempotency_records')) return [{ request_hash: 'reserved' }];
      if (text.includes('FROM cardverse_pack_entitlements') && text.includes('FOR UPDATE')) {
        return [{
          pack_id: PACK,
          account_id: ACCOUNT,
          grant_id: GRANT,
          pack_type: 'standard',
          status: 'unopened',
          version: 1,
          issued_at: '2026-09-20T01:00:00.000Z',
        }];
      }
      if (text.includes('INSERT INTO cardverse_pack_rolls')) {
        return [{ server_roll_id: ROLL, rolled_at: '2026-09-20T01:01:00.000Z' }];
      }
      if (text.includes('INSERT INTO cardverse_stack_balances')) return [];
      if (text.includes('INSERT INTO cardverse_pack_roll_items')) {
        rollItemWrites += 1;
        return [];
      }
      if (text.includes('INSERT INTO cardverse_inventory_ledger')) {
        if (text.includes('$2, $3, $4, $5, $6')) creditWrites += 1;
        return [];
      }
      if (text.includes('UPDATE cardverse_pack_entitlements')) return [{ version: 2 }];
      if (text.includes('UPDATE cardverse_idempotency_records')) {
        idempotencySaved = true;
        return [];
      }
      throw new Error('unexpected query: ' + text);
    },
  };
  const db = { transaction: (fn) => fn(tx) };

  const result = await openPack(
    db,
    ACCOUNT,
    {
      packId: PACK,
      idempotencyKey: 'pack-open-attempt-0001',
      clientRevealVersion: 1,
    },
    {
      rollPack(input) {
        rollerInput = input;
        return {
          policyVersion: 7,
          items: plan.items,
        };
      },
    },
  );

  assert.deepEqual(rollerInput, { packId: PACK, packType: 'standard' });
  assert.equal(result.serverRollId, ROLL);
  assert.equal(result.items.length, 5);
  assert.equal(result.items[4].variant.interestId, 'travel.japan');
  assert.equal(result.serverAuthoritative, true);
  assert.equal(result.idempotentReplay, false);
  assert.equal(rollItemWrites, 5);
  assert.equal(creditWrites, 5);
  assert.equal(idempotencySaved, true);
}

{
  const request = {
    packId: PACK,
    idempotencyKey: 'pack-open-attempt-0001',
    clientRevealVersion: 1,
  };
  const requestHash = createHash('sha256')
    .update(JSON.stringify({
      accountId: ACCOUNT,
      packId: PACK,
      clientRevealVersion: 1,
    }))
    .digest('hex');
  const persisted = {
    packId: PACK,
    serverRollId: ROLL,
    idempotencyKey: request.idempotencyKey,
    rolledAt: '2026-09-20T01:01:00.000Z',
    items: [{ variant: { interestId: 'sports.badminton', finishId: 'normal', editionId: 'core_set_1' }, quantity: 1 }],
    serverAuthoritative: true,
  };
  let rollerCalls = 0;
  const tx = {
    async query(text) {
      if (text.includes("SELECT id FROM zync_accounts")) return [{ id: ACCOUNT }];
      if (text.includes('INSERT INTO cardverse_idempotency_records')) return [];
      if (text.includes('SELECT request_hash, response_json')) {
        return [{ request_hash: requestHash, response_json: persisted }];
      }
      throw new Error('unexpected query after idempotent replay: ' + text);
    },
  };
  const db = { transaction: (fn) => fn(tx) };
  const replay = await openPack(db, ACCOUNT, request, {
    rollPack() {
      rollerCalls += 1;
      throw new Error('roller must not run on replay');
    },
  });
  assert.equal(replay.serverRollId, ROLL);
  assert.equal(replay.idempotentReplay, true);
  assert.equal(rollerCalls, 0);
}

console.log('✓ Cardverse pack-open transaction contracts passed');

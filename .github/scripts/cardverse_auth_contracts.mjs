import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import {
  verifyProviderIdToken,
} from '../../api/_cardverse/provider_auth.js';
import {
  bearerTokenFromAuthorization,
  consumeAuthChallenge,
  createAccountSession,
  createAuthChallenge,
  resolveAccountSession,
  revokeAllAccountSessions,
} from '../../api/_cardverse/session_store.js';

const migration = await readFile(
  new URL('../../db/migrations/0003_cardverse_auth_sessions.sql', import.meta.url),
  'utf8',
);
const pkg = JSON.parse(await readFile(new URL('../../package.json', import.meta.url), 'utf8'));

assert.match(migration, /CREATE TABLE IF NOT EXISTS cardverse_auth_challenges/);
assert.match(migration, /nonce_hash text NOT NULL UNIQUE/);
assert.match(migration, /CREATE TABLE IF NOT EXISTS zync_account_sessions/);
assert.match(migration, /token_hash text NOT NULL UNIQUE/);
assert.equal(pkg.dependencies?.jose, '^6.2.12');

const CHALLENGE = '11111111-1111-4111-8111-111111111111';
const ACCOUNT = '22222222-2222-4222-8222-222222222222';
const SESSION = '33333333-3333-4333-8333-333333333333';

{
  let inserted = null;
  const db = {
    async query(text, params) {
      assert.match(text, /INSERT INTO cardverse_auth_challenges/);
      inserted = params;
      return [{ challenge_id: CHALLENGE, expires_at: '2026-09-20T02:10:00.000Z' }];
    },
  };
  const challenge = await createAuthChallenge(db, 'google', { ttlMinutes: 10 });
  assert.equal(challenge.challengeId, CHALLENGE);
  assert.equal(challenge.provider, 'google');
  assert.match(challenge.nonce, /^[A-Za-z0-9_-]{43}$/);
  assert.equal(inserted[0], 'google');
  assert.equal(inserted[1], createHash('sha256').update(challenge.nonce).digest('hex'));
  assert.equal(inserted[2], 10);
}

{
  let paramsSeen = null;
  const db = {
    async query(text, params) {
      assert.match(text, /UPDATE cardverse_auth_challenges SET consumed_at/);
      paramsSeen = params;
      return [{ challenge_id: CHALLENGE }];
    },
  };
  const result = await consumeAuthChallenge(db, {
    challengeId: CHALLENGE,
    provider: 'apple',
    nonce: 'nonce-from-verified-token',
  });
  assert.equal(result.consumed, true);
  assert.equal(
    paramsSeen[2],
    createHash('sha256').update('nonce-from-verified-token').digest('hex'),
  );
}

{
  let verifierArgs = null;
  const identity = await verifyProviderIdToken(
    'google',
    'header.payload.signature',
    {
      audiences: ['zync-client.apps.googleusercontent.com'],
      async verifyJwt(args) {
        verifierArgs = args;
        return {
          payload: {
            sub: 'google-subject-123',
            nonce: 'nonce-123',
            email: 'person@example.com',
            email_verified: true,
          },
        };
      },
    },
  );
  assert.equal(identity.providerSubject, 'google-subject-123');
  assert.equal(identity.providerEmail, 'person@example.com');
  assert.equal(identity.emailVerified, true);
  assert.equal(identity.nonce, 'nonce-123');
  assert.deepEqual(verifierArgs.issuers, ['https://accounts.google.com', 'accounts.google.com']);
  assert.deepEqual(verifierArgs.algorithms, ['RS256']);
}

{
  const identity = await verifyProviderIdToken(
    'apple',
    'header.payload.signature',
    {
      audiences: ['com.example.zync'],
      async verifyJwt(args) {
        assert.deepEqual(args.issuers, ['https://appleid.apple.com']);
        return {
          payload: {
            sub: 'apple-subject-123',
            nonce: 'nonce-apple',
            email: 'relay@privaterelay.appleid.com',
            email_verified: 'true',
          },
        };
      },
    },
  );
  assert.equal(identity.provider, 'apple');
  assert.equal(identity.emailVerified, true);
}

{
  let tokenHash = null;
  let cleanupSeen = false;
  let accountLockSeen = false;
  let transactionCount = 0;
  const tx = {
    async query(text, params) {
      if (text.includes("status = 'active' FOR UPDATE")) {
        accountLockSeen = true;
        assert.equal(params[0], ACCOUNT);
        return [{ id: ACCOUNT }];
      }
      if (text.includes('INSERT INTO zync_account_sessions')) {
        tokenHash = params[1];
        return [{ session_id: SESSION, expires_at: '2026-10-20T02:00:00.000Z' }];
      }
      assert.match(text, /UPDATE zync_account_sessions/);
      assert.match(text, /LIMIT \$2/);
      assert.equal(text.includes('ORDER BY (session_id = $3) DESC'), true);
      assert.equal(params[0], ACCOUNT);
      assert.equal(params[1], 8);
      assert.equal(params[2], SESSION);
      cleanupSeen = true;
      return [];
    },
  };
  const db = {
    async transaction(callback) {
      transactionCount += 1;
      return callback(tx);
    },
  };
  const session = await createAccountSession(db, ACCOUNT, { ttlDays: 30 });
  assert.equal(session.sessionId, SESSION);
  assert.match(session.token, /^[A-Za-z0-9_-]{43}$/);
  assert.equal(tokenHash, createHash('sha256').update(session.token).digest('hex'));
  assert.equal(accountLockSeen, true);
  assert.equal(cleanupSeen, true);
  assert.equal(transactionCount, 1);
  assert.equal(bearerTokenFromAuthorization('Bearer ' + session.token), session.token);
}

await assert.rejects(
  () => createAccountSession({ query: async () => [] }, ACCOUNT),
  /cardverse_transaction_required/,
);

await assert.rejects(
  () => createAccountSession(
    { transaction: (callback) => callback({ query: async () => [] }) },
    ACCOUNT,
  ),
  /cardverse_account_not_active/,
);

{
  const rawToken = 'A'.repeat(43);
  const expectedHash = createHash('sha256').update(rawToken).digest('hex');
  let call = 0;
  const db = {
    async query(text, params) {
      call += 1;
      if (call === 1) {
        assert.match(text, /JOIN zync_accounts/);
        assert.equal(params[0], expectedHash);
        return [{
          session_id: SESSION,
          account_id: ACCOUNT,
          expires_at: '2026-10-20T02:00:00.000Z',
          status: 'active',
        }];
      }
      assert.match(text, /UPDATE zync_account_sessions SET last_seen_at/);
      return [];
    },
  };
  const session = await resolveAccountSession(db, rawToken);
  assert.equal(session.accountId, ACCOUNT);
  assert.equal(call, 2);
}

{
  const db = {
    async query(text, params) {
      assert.match(text, /WHERE account_id = \$1 AND revoked_at IS NULL/);
      assert.equal(params[0], ACCOUNT);
      return [{ session_id: SESSION }, { session_id: CHALLENGE }];
    },
  };
  const result = await revokeAllAccountSessions(db, ACCOUNT);
  assert.equal(result.revoked, 2);
}

assert.throws(
  () => bearerTokenFromAuthorization('Bearer too-short'),
  /cardverse_session_missing/,
);

console.log('✓ Cardverse auth/session contracts passed');


for (const modulePath of [
  '../../api/v1/cardverse/auth/challenge.js',
  '../../api/v1/cardverse/auth/provider.js',
  '../../api/v1/cardverse/auth/logout.js',
  '../../api/v1/cardverse/auth/logout-all.js',
  '../../api/v1/cardverse/auth/link.js',
  '../../api/v1/cardverse/auth/unlink.js',
  '../../api/v1/cardverse/account/delete.js',
  '../../api/v1/cardverse/inventory.js',
]) {
  const loaded = await import(modulePath);
  assert.equal(typeof loaded.default, 'function');
}

console.log('✓ Cardverse auth endpoint module resolution passed');


{
  const gate = await import('../../api/_cardverse/runtime_gate.js');
  const beforeApi = process.env.CARDVERSE_API_ENABLED;
  const beforePack = process.env.CARDVERSE_PACK_OPEN_ENABLED;
  const beforeLifecycle = process.env.CARDVERSE_ACCOUNT_LIFECYCLE_ENABLED;

  delete process.env.CARDVERSE_API_ENABLED;
  delete process.env.CARDVERSE_PACK_OPEN_ENABLED;
  delete process.env.CARDVERSE_ACCOUNT_LIFECYCLE_ENABLED;
  assert.equal(gate.cardverseApiEnabled(), false);
  assert.equal(gate.cardversePackOpenEnabled(), false);
  assert.equal(gate.cardverseAccountLifecycleEnabled(), false);

  process.env.CARDVERSE_API_ENABLED = 'true';
  assert.equal(gate.cardverseApiEnabled(), true);
  assert.equal(gate.cardversePackOpenEnabled(), false);

  process.env.CARDVERSE_PACK_OPEN_ENABLED = 'true';
  process.env.CARDVERSE_ACCOUNT_LIFECYCLE_ENABLED = 'true';
  assert.equal(gate.cardversePackOpenEnabled(), true);
  assert.equal(gate.cardverseAccountLifecycleEnabled(), true);

  if (beforeApi == null) delete process.env.CARDVERSE_API_ENABLED;
  else process.env.CARDVERSE_API_ENABLED = beforeApi;
  if (beforePack == null) delete process.env.CARDVERSE_PACK_OPEN_ENABLED;
  else process.env.CARDVERSE_PACK_OPEN_ENABLED = beforePack;
  if (beforeLifecycle == null) delete process.env.CARDVERSE_ACCOUNT_LIFECYCLE_ENABLED;
  else process.env.CARDVERSE_ACCOUNT_LIFECYCLE_ENABLED = beforeLifecycle;
}

console.log('✓ Cardverse runtime kill-switch contracts passed');

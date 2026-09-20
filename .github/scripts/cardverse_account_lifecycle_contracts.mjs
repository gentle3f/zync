import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import {
  deleteAccount,
  unlinkIdentityFromAccount,
} from '../../server/cardverse/account_lifecycle.js';

const ACCOUNT = '11111111-1111-4111-8111-111111111111';
const GOOGLE_LINK = '22222222-2222-4222-8222-222222222222';
const APPLE_LINK = '33333333-3333-4333-8333-333333333333';

const migration = await readFile(
  new URL('../../db/migrations/0006_cardverse_account_lifecycle.sql', import.meta.url),
  'utf8',
);
assert.match(migration, /ADD COLUMN IF NOT EXISTS deleted_at/);
assert.match(migration, /ADD COLUMN IF NOT EXISTS unlinked_at/);
assert.match(migration, /zync_identity_links_active_account_idx/);
assert.match(migration, /Soft unlink tombstone/);

{
  const calls = [];
  const tx = {
    async query(text, params = []) {
      calls.push({ text, params });
      if (text.includes('FROM zync_accounts')) return [{ id: ACCOUNT, status: 'active' }];
      if (text.includes('FROM zync_identity_links') && text.includes('ORDER BY created_at')) {
        return [
          { id: GOOGLE_LINK, provider: 'google', provider_subject: 'google-subject' },
          { id: APPLE_LINK, provider: 'apple', provider_subject: 'apple-subject' },
        ];
      }
      if (text.includes('UPDATE zync_identity_links')) return [];
      if (text.includes('UPDATE zync_account_sessions')) return [];
      throw new Error('unexpected query: ' + text);
    },
  };
  const db = { transaction: (fn) => fn(tx) };
  const result = await unlinkIdentityFromAccount(db, ACCOUNT, {
    provider: 'google',
    providerSubject: 'google-subject',
  });
  assert.equal(result.unlinked, true);
  assert.equal(result.allSessionsRevoked, true);
  const unlink = calls.find((call) => call.text.includes('UPDATE zync_identity_links'));
  assert.equal(unlink.params[0], GOOGLE_LINK);
  assert.match(unlink.text, /provider_email = NULL/);
  assert.match(unlink.text, /unlinked_at = now\(\)/);
  assert.equal(calls.some((call) => call.text.includes('UPDATE zync_account_sessions')), true);
}

{
  let mutated = false;
  const tx = {
    async query(text) {
      if (text.includes('FROM zync_accounts')) return [{ id: ACCOUNT, status: 'active' }];
      if (text.includes('FROM zync_identity_links') && text.includes('ORDER BY created_at')) {
        return [{ id: GOOGLE_LINK, provider: 'google', provider_subject: 'google-subject' }];
      }
      mutated = true;
      return [];
    },
  };
  const db = { transaction: (fn) => fn(tx) };
  await assert.rejects(
    () => unlinkIdentityFromAccount(db, ACCOUNT, {
      provider: 'google',
      providerSubject: 'google-subject',
    }),
    /cardverse_last_identity_unlink_forbidden/,
  );
  assert.equal(mutated, false);
}

{
  const calls = [];
  const tx = {
    async query(text, params = []) {
      calls.push({ text, params });
      if (text.includes('FROM zync_accounts')) {
        return [{ id: ACCOUNT, status: 'active', deleted_at: null }];
      }
      if (text.includes('FROM zync_identity_links') && text.includes('provider_subject = $3')) {
        return [{ id: GOOGLE_LINK }];
      }
      if (text.includes('UPDATE zync_accounts')) {
        return [{ deleted_at: '2026-09-20T04:00:00.000Z' }];
      }
      if (text.includes('UPDATE zync_identity_links')) return [];
      if (text.includes('UPDATE zync_account_sessions')) return [];
      throw new Error('unexpected query: ' + text);
    },
  };
  const db = { transaction: (fn) => fn(tx) };
  const result = await deleteAccount(db, ACCOUNT, {
    provider: 'google',
    providerSubject: 'google-subject',
  });
  assert.equal(result.deleted, true);
  assert.equal(result.alreadyDeleted, false);
  assert.equal(result.deletedAt, '2026-09-20T04:00:00.000Z');
  assert.equal(calls.some((call) => /status = 'deleted'/.test(call.text)), true);
  assert.equal(calls.some((call) => call.text.includes('provider_email = NULL')), true);
  assert.equal(calls.some((call) => call.text.includes('UPDATE zync_account_sessions')), true);
}

{
  const tx = {
    async query(text) {
      if (text.includes('FROM zync_accounts')) {
        return [{ id: ACCOUNT, status: 'active', deleted_at: null }];
      }
      if (text.includes('FROM zync_identity_links') && text.includes('provider_subject = $3')) {
        return [];
      }
      throw new Error('unexpected query: ' + text);
    },
  };
  const db = { transaction: (fn) => fn(tx) };
  await assert.rejects(
    () => deleteAccount(db, ACCOUNT, {
      provider: 'google',
      providerSubject: 'wrong-subject',
    }),
    /cardverse_identity_not_linked/,
  );
}

for (const route of [
  '../../server/cardverse/routes/auth/link.js',
  '../../server/cardverse/routes/auth/unlink.js',
  '../../server/cardverse/routes/auth/logout-all.js',
  '../../server/cardverse/routes/account/delete.js',
]) {
  const loaded = await import(route);
  assert.equal(typeof loaded.default, 'function');
}

console.log('✓ Cardverse account/session lifecycle contracts passed');

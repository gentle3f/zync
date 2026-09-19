import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import {
  applyCardverseAbuseHeaders,
  cardverseClientAddress,
  cardverseRateKey,
  enforceCardverseAccountRateLimit,
  enforceCardverseIpRateLimit,
} from '../../api/_cardverse/abuse_guard.js';

const SECRET = 'rate-limit-secret-'.repeat(2);
const CONFIG = {
  url: 'https://example.upstash.test',
  token: 'test-token',
  secret: SECRET,
};

{
  const req = {
    headers: {
      'x-forwarded-for': '203.0.113.7, 10.0.0.1',
      'x-real-ip': '198.51.100.9',
    },
  };
  assert.equal(cardverseClientAddress(req), '203.0.113.7');

  const key = cardverseRateKey('auth_challenge_ip', cardverseClientAddress(req), SECRET);
  assert.match(key, /^zync:cardverse:rl:auth_challenge_ip:[a-f0-9]{40}$/);
  assert.equal(key.includes('203.0.113.7'), false);
  assert.equal(
    key,
    cardverseRateKey('auth_challenge_ip', '203.0.113.7', SECRET),
  );
  assert.notEqual(
    key,
    cardverseRateKey('auth_provider_ip', '203.0.113.7', SECRET),
  );
}

{
  let commandSeen = null;
  const result = await enforceCardverseIpRateLimit(
    { headers: { 'x-forwarded-for': '203.0.113.8' } },
    'auth_challenge_ip',
    {
      config: CONFIG,
      async redisCommand(_config, command) {
        commandSeen = command;
        return [1, 60];
      },
    },
  );
  assert.equal(result.count, 1);
  assert.equal(result.limit, 20);
  assert.equal(commandSeen[0], 'EVAL');
  assert.equal(commandSeen[2], 1);
  assert.match(commandSeen[3], /^zync:cardverse:rl:auth_challenge_ip:/);
  assert.equal(commandSeen[3].includes('203.0.113.8'), false);
}

{
  const accountId = '22222222-2222-4222-8222-222222222222';
  let keySeen = '';
  const result = await enforceCardverseAccountRateLimit(
    accountId,
    'quest_claim_account',
    {
      config: CONFIG,
      async redisCommand(_config, command) {
        keySeen = command[3];
        return [30, 12];
      },
    },
  );
  assert.equal(result.limit, 30);
  assert.equal(keySeen.includes(accountId), false);
}

{
  await assert.rejects(
    () => enforceCardverseIpRateLimit(
      { headers: { 'x-forwarded-for': '203.0.113.9' } },
      'auth_challenge_ip',
      {
        config: CONFIG,
        async redisCommand() {
          return [21, 37];
        },
      },
    ),
    (error) => {
      assert.equal(error.code, 'cardverse_rate_limited');
      assert.equal(error.retryAfterSeconds, 37);
      return true;
    },
  );

  const headers = {};
  applyCardverseAbuseHeaders(
    { setHeader(name, value) { headers[name] = value; } },
    { code: 'cardverse_rate_limited', retryAfterSeconds: 37 },
  );
  assert.equal(headers['Retry-After'], '37');
}

{
  await assert.rejects(
    () => enforceCardverseIpRateLimit(
      { headers: { 'x-forwarded-for': '203.0.113.10' } },
      'auth_provider_ip',
      {
        config: CONFIG,
        async redisCommand() {
          return ['broken'];
        },
      },
    ),
    (error) => error.code === 'cardverse_abuse_guard_unavailable',
  );
}

const endpointExpectations = new Map([
  ['../../api/v1/cardverse/auth/challenge.js', ['auth_challenge_ip']],
  ['../../api/v1/cardverse/auth/provider.js', ['auth_provider_ip']],
  ['../../api/v1/cardverse/proofs/redeem.js', ['proof_redeem_ip', 'proof_redeem_account']],
  ['../../api/v1/cardverse/quests/claim.js', ['quest_claim_ip', 'quest_claim_account']],
  ['../../api/v1/cardverse/packs/open.js', ['pack_open_ip', 'pack_open_account']],
]);

for (const [modulePath, profiles] of endpointExpectations) {
  const source = await readFile(new URL(modulePath, import.meta.url), 'utf8');
  assert.match(source, /applyCardverseAbuseHeaders/);
  for (const profile of profiles) assert.match(source, new RegExp(profile));
}

console.log('✓ Cardverse distributed abuse/rate-limit contracts passed');

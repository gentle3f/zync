import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import {
  applyCardverseAbuseHeaders,
  cardverseAbuseGuardConfigured,
  checkCardverseAbuseGuard,
  cardverseClientAddress,
  cardverseRateKey,
  enforceCardverseAccountRateLimit,
  enforceCardverseIpRateLimit,
} from '../../server/cardverse/abuse_guard.js';

const SECRET = 'rate-limit-secret-'.repeat(2);
const CONFIG = {
  url: 'https://example.upstash.test',
  token: 'test-token',
  secret: SECRET,
};

{
  const oldUrl = process.env.UPSTASH_REDIS_REST_URL;
  const oldToken = process.env.UPSTASH_REDIS_REST_TOKEN;
  const oldSecret = process.env.ZYNC_CARDVERSE_RATE_LIMIT_SECRET;
  try {
    delete process.env.UPSTASH_REDIS_REST_URL;
    delete process.env.UPSTASH_REDIS_REST_TOKEN;
    delete process.env.ZYNC_CARDVERSE_RATE_LIMIT_SECRET;
    assert.equal(cardverseAbuseGuardConfigured(), false);

    process.env.UPSTASH_REDIS_REST_URL = 'https://example.upstash.test/';
    process.env.UPSTASH_REDIS_REST_TOKEN = 'redis-token';
    process.env.ZYNC_CARDVERSE_RATE_LIMIT_SECRET = SECRET;
    assert.equal(cardverseAbuseGuardConfigured(), true);
  } finally {
    if (oldUrl == null) delete process.env.UPSTASH_REDIS_REST_URL;
    else process.env.UPSTASH_REDIS_REST_URL = oldUrl;
    if (oldToken == null) delete process.env.UPSTASH_REDIS_REST_TOKEN;
    else process.env.UPSTASH_REDIS_REST_TOKEN = oldToken;
    if (oldSecret == null) delete process.env.ZYNC_CARDVERSE_RATE_LIMIT_SECRET;
    else process.env.ZYNC_CARDVERSE_RATE_LIMIT_SECRET = oldSecret;
  }
}

{
  let commandSeen = null;
  const result = await checkCardverseAbuseGuard({
    config: CONFIG,
    async redisCommand(_config, command) {
      commandSeen = command;
      return 'PONG';
    },
  });
  assert.equal(result.reachable, true);
  assert.deepEqual(commandSeen, ['PING']);

  await assert.rejects(
    () => checkCardverseAbuseGuard({
      config: CONFIG,
      async redisCommand() { return 'NOPE'; },
    }),
    (error) => error.code === 'cardverse_abuse_guard_unavailable',
  );
}

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
  let drawKeySeen = '';
  const drawResult = await enforceCardverseAccountRateLimit(
    '33333333-3333-4333-8333-333333333333',
    'draw_redeem_account',
    {
      config: CONFIG,
      async redisCommand(_config, command) {
        drawKeySeen = command[3];
        return [1, 60];
      },
    },
  );
  assert.equal(drawResult.limit, 60);
  assert.match(drawKeySeen, /^zync:cardverse:rl:draw_redeem_account:/);

  let dailyKeySeen = '';
  const dailyResult = await enforceCardverseIpRateLimit(
    { headers: { 'x-forwarded-for': '203.0.113.11' } },
    'daily_login_ip',
    {
      config: CONFIG,
      async redisCommand(_config, command) {
        dailyKeySeen = command[3];
        return [1, 60];
      },
    },
  );
  assert.equal(dailyResult.limit, 120);
  assert.match(dailyKeySeen, /^zync:cardverse:rl:daily_login_ip:/);
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
  ['../../server/cardverse/routes/auth/challenge.js', ['auth_challenge_ip']],
  ['../../server/cardverse/routes/auth/provider.js', ['auth_provider_ip']],
  ['../../server/cardverse/routes/proofs/redeem.js', ['proof_redeem_ip', 'proof_redeem_account']],
  ['../../server/cardverse/routes/quests/claim.js', ['quest_claim_ip', 'quest_claim_account']],
  ['../../server/cardverse/routes/packs/open.js', ['pack_open_ip', 'pack_open_account']],
  ['../../server/cardverse/routes/draws/redeem.js', ['draw_redeem_ip', 'draw_redeem_account']],
  ['../../server/cardverse/routes/rewards/daily-login.js', ['daily_login_ip', 'daily_login_account']],
  ['../../server/cardverse/routes/auth/link.js', ['account_lifecycle_ip', 'account_lifecycle_account']],
  ['../../server/cardverse/routes/auth/unlink.js', ['account_lifecycle_ip', 'account_lifecycle_account']],
  ['../../server/cardverse/routes/auth/logout-all.js', ['account_lifecycle_ip', 'account_lifecycle_account']],
  ['../../server/cardverse/routes/account/delete.js', ['account_lifecycle_ip', 'account_lifecycle_account']],
]);

for (const [modulePath, profiles] of endpointExpectations) {
  const source = await readFile(new URL(modulePath, import.meta.url), 'utf8');
  assert.match(source, /applyCardverseAbuseHeaders/);
  for (const profile of profiles) assert.match(source, new RegExp(profile));
}

console.log('✓ Cardverse distributed abuse/rate-limit contracts passed');

import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

const source = await readFile('api/v1/interest-popularity.js', 'utf8');
const encoded = Buffer.from(source).toString('base64');
const imported = await import('data:text/javascript;base64,' + encoded);
const handler = imported.default;

function responseState() {
  const state = { status: 200, body: null, headers: {} };
  const res = {
    status(code) { state.status = code; return res; },
    json(body) { state.body = body; return res; },
    setHeader(name, value) { state.headers[String(name).toLowerCase()] = value; return res; },
  };
  return { state, res };
}

async function invoke({ method = 'GET', query = {}, body = {} } = {}) {
  const { state, res } = responseState();
  await handler({
    method,
    query,
    body,
    headers: { 'x-forwarded-for': '203.0.113.77' },
  }, res);
  return state;
}

const hashes = new Map();
const expiries = new Map();
const counters = new Map();
const pipelineCalls = [];

function redisCommand(command) {
  const [op, ...args] = command;
  if (op === 'EVAL') {
    const key = args[2];
    const next = (counters.get(key) ?? 0) + 1;
    counters.set(key, next);
    return next;
  }
  if (op === 'HGETALL') {
    const value = hashes.get(args[0]) ?? {};
    return Object.entries(value).flat();
  }
  throw new Error('unsupported fake redis command ' + op);
}

function applyPipeline(commands) {
  pipelineCalls.push(commands);
  for (const command of commands) {
    const [op, key, field, amount] = command;
    if (op === 'HINCRBY') {
      const hash = hashes.get(key) ?? {};
      hash[field] = Number(hash[field] ?? 0) + Number(amount);
      hashes.set(key, hash);
    } else if (op === 'EXPIRE') {
      expiries.set(key, Number(field));
    } else {
      throw new Error('unsupported fake pipeline command ' + op);
    }
  }
}

globalThis.fetch = async (url, options) => {
  assert.equal(options.method, 'POST');
  assert.equal(options.headers.Authorization, 'Bearer unit-test-token');
  if (url.endsWith('/pipeline')) {
    const commands = JSON.parse(options.body);
    applyPipeline(commands);
    return {
      ok: true,
      json: async () => commands.map(() => ({ result: 1 })),
    };
  }
  assert.equal(url, 'https://fake-upstash.example');
  const command = JSON.parse(options.body);
  return {
    ok: true,
    json: async () => ({ result: redisCommand(command) }),
  };
};

process.env.UPSTASH_REDIS_REST_URL = 'https://fake-upstash.example';
process.env.UPSTASH_REDIS_REST_TOKEN = 'unit-test-token';
process.env.ZYNC_RELAY_RATE_LIMIT_SECRET = 'unit-test-rate-secret-1234567890';

let failures = 0;
const cases = [];
const test = (name, fn) => cases.push({ name, fn });

test('write stores only aggregate canonical IDs under regional weekly namespace', async () => {
  pipelineCalls.length = 0;
  const result = await invoke({
    method: 'POST',
    body: {
      version: 1,
      region: 'hk',
      impressions: ['sports.badminton', 'music.cantopop', 'sports.badminton'],
      selections: ['music.cantopop'],
    },
  });
  assert.equal(result.status, 202);
  assert.equal(result.body.impressions, 2);
  assert.equal(result.body.selections, 1);
  const commands = pipelineCalls.at(-1);
  assert.ok(commands.some((c) => c[0] === 'HINCRBY' && c[2] === 'i:sports.badminton'));
  assert.ok(commands.some((c) => c[0] === 'HINCRBY' && c[2] === 's:music.cantopop'));
  assert.ok(commands.every((c) => String(c[1]).startsWith('zync:interest:v1:')));
  assert.equal(JSON.stringify(commands).includes('203.0.113.77'), false);
});

test('write rejects custom interests and selection without an impression', async () => {
  let result = await invoke({
    method: 'POST',
    body: {
      version: 1,
      region: 'hk',
      impressions: ['custom.deadbeef'],
      selections: [],
    },
  });
  assert.equal(result.status, 400);

  result = await invoke({
    method: 'POST',
    body: {
      version: 1,
      region: 'hk',
      impressions: ['sports.badminton'],
      selections: ['music.cantopop'],
    },
  });
  assert.equal(result.status, 400);
  assert.equal(result.body.error, 'interest_selection_without_impression');
});

test('read uses completed weeks only and returns aggregate counts', async () => {
  const result = await invoke({ method: 'GET', query: { region: 'hk' } });
  assert.equal(result.status, 200);
  assert.equal(result.body.region, 'hk');
  assert.match(result.body.previousWeek, /^\d{4}-\d{2}-\d{2}$/);
  assert.match(result.body.olderWeek, /^\d{4}-\d{2}-\d{2}$/);
  assert.notEqual(result.body.previousWeek, result.body.olderWeek);
  assert.match(result.headers['cache-control'], /max-age=3600/);
});

test('configuration accepts Vercel KV aliases and source contains no persistent user identifier', async () => {
  const oldUrl = process.env.UPSTASH_REDIS_REST_URL;
  const oldToken = process.env.UPSTASH_REDIS_REST_TOKEN;
  delete process.env.UPSTASH_REDIS_REST_URL;
  delete process.env.UPSTASH_REDIS_REST_TOKEN;
  process.env.KV_REST_API_URL = 'https://fake-upstash.example';
  process.env.KV_REST_API_TOKEN = 'unit-test-token';
  const result = await invoke({ method: 'GET', query: { region: 'tw' } });
  assert.equal(result.status, 200);
  process.env.UPSTASH_REDIS_REST_URL = oldUrl;
  process.env.UPSTASH_REDIS_REST_TOKEN = oldToken;
  delete process.env.KV_REST_API_URL;
  delete process.env.KV_REST_API_TOKEN;

  assert.equal(/install.?id|account.?id|nickname/i.test(source), false);
  assert.equal(/console\.(log|error|warn)/.test(source), false);
  assert.match(source, /zync:interest:v1:/);
  assert.match(source, /zync:interest:rl:v1:/);
});

for (const entry of cases) {
  try {
    await entry.fn();
    console.log('✓ ' + entry.name);
  } catch (error) {
    failures += 1;
    console.error('✗ ' + entry.name);
    console.error(error);
  }
}

if (failures) process.exit(1);
console.log('\n' + cases.length + ' regional-interest popularity contract tests passed.');

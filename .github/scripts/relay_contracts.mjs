import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';

const source = await readFile('api/v1/relay.js', 'utf8');
const encoded = Buffer.from(source).toString('base64');
const { default: relay } = await import(`data:text/javascript;base64,${encoded}`);

function makeResponse() {
  const state = { status: 200, body: undefined, headers: {} };
  const res = {
    status(code) { state.status = code; return res; },
    json(value) { state.body = value; return res; },
    setHeader(name, value) { state.headers[String(name).toLowerCase()] = value; return res; },
  };
  return { state, res };
}

async function invoke(body, method = 'POST') {
  const { state, res } = makeResponse();
  await relay({
    method,
    body,
    headers: { 'x-forwarded-for': '203.0.113.17' },
  }, res);
  return state;
}

const store = new Map();
let nowMs = Date.now();

function alive(key) {
  const entry = store.get(key);
  if (!entry) return null;
  if (entry.expiresAt != null && entry.expiresAt <= nowMs) {
    store.delete(key);
    return null;
  }
  return entry;
}

function result(value, ok = true) {
  return {
    ok,
    status: ok ? 200 : 500,
    json: async () => ok ? { result: value } : { error: 'fake_redis_error' },
  };
}

function fakeRedis(command) {
  const [op, ...args] = command;
  if (op === 'SET') {
    const [key, value, exToken, ttlValue, nxToken] = args;
    const existing = alive(key);
    if (nxToken === 'NX' && existing) return null;
    const ttl = exToken === 'EX' ? Number(ttlValue) : null;
    store.set(key, { value, expiresAt: ttl == null ? null : nowMs + ttl * 1000 });
    return 'OK';
  }
  if (op === 'GET') return alive(args[0])?.value ?? null;
  if (op === 'DEL') return store.delete(args[0]) ? 1 : 0;
  if (op === 'EVAL') {
    const script = String(args[0]);
    const keyCount = Number(args[1]);
    const keys = args.slice(2, 2 + keyCount);
    const argv = args.slice(2 + keyCount);

    if (script.includes("redis.call('INCR'")) {
      const key = keys[0];
      const entry = alive(key);
      const next = entry ? Number(entry.value) + 1 : 1;
      store.set(key, { value: String(next), expiresAt: entry?.expiresAt ?? nowMs + 60000 });
      return next;
    }

    if (script.includes("return 'accepted'")) {
      const key = keys[0];
      const entry = alive(key);
      if (!entry) return 'missing';
      if (entry.value === 'P') {
        entry.value = argv[0];
        return 'accepted';
      }
      if (entry.value === argv[0]) return 'same';
      return 'duplicate';
    }
    throw new Error(`Unsupported fake EVAL: ${script}`);
  }
  throw new Error(`Unsupported fake Redis command: ${op}`);
}

globalThis.fetch = async (url, options) => {
  assert.equal(url, 'https://fake-upstash.example');
  assert.equal(options.method, 'POST');
  assert.equal(options.headers.Authorization, 'Bearer unit-test-token');
  const command = JSON.parse(options.body);
  return result(fakeRedis(command));
};

process.env.UPSTASH_REDIS_REST_URL = 'https://fake-upstash.example';
process.env.UPSTASH_REDIS_REST_TOKEN = 'unit-test-token';
process.env.ZYNC_RELAY_RATE_LIMIT_SECRET = 'unit-test-rate-secret-1234567890';

const sid = 'ABCDEFGHIJKLMNOPQRSTUVWX';
const expiry = () => new Date(nowMs + 180000).toISOString();
const base = { protocolVersion: 2, sessionId: sid };

let failures = 0;
const cases = [];
const test = (name, fn) => cases.push({ name, fn });

test('relay rejects non-POST and does not cache responses', async () => {
  const r = await invoke({}, 'GET');
  assert.equal(r.status, 405);
  assert.equal(r.headers.allow, 'POST');
  assert.equal(r.headers['cache-control'], 'no-store');
});

test('relay refuses to run without the shared-store configuration', async () => {
  const token = process.env.UPSTASH_REDIS_REST_TOKEN;
  delete process.env.UPSTASH_REDIS_REST_TOKEN;
  const r = await invoke({ action: 'create', ...base, expiresAt: expiry() });
  process.env.UPSTASH_REDIS_REST_TOKEN = token;
  assert.equal(r.status, 503);
  assert.deepEqual(r.body, { error: 'relay_not_configured' });
});

test('create establishes only a short-lived pending session and is retry-safe', async () => {
  store.clear();
  let r = await invoke({ action: 'create', ...base, expiresAt: expiry() });
  assert.equal(r.status, 201);
  assert.equal(r.body.status, 'created');
  const entry = alive(`zync:relay:v2:${sid}`);
  assert.equal(entry.value, 'P');
  assert.ok(entry.expiresAt - nowMs <= 180000);
  assert.ok(entry.expiresAt - nowMs >= 15000);

  r = await invoke({ action: 'create', ...base, expiresAt: expiry() });
  assert.equal(r.status, 200);
  assert.equal(r.body.status, 'already_created');
});

test('only one encrypted response wins but identical retry is idempotent', async () => {
  const payload = 'AbCdEf0123_-';
  let r = await invoke({ action: 'respond', ...base, payload });
  assert.equal(r.status, 200);
  assert.equal(r.body.status, 'received');

  r = await invoke({ action: 'respond', ...base, payload });
  assert.equal(r.status, 200);
  assert.equal(r.body.status, 'already_received');

  r = await invoke({ action: 'respond', ...base, payload: 'DifferentOpaquePayload_123' });
  assert.equal(r.status, 409);
  assert.deepEqual(r.body, { error: 'relay_already_answered' });
});

test('host polling is non-destructive until authenticated consume', async () => {
  let r = await invoke({ action: 'take', ...base });
  assert.equal(r.status, 200);
  assert.equal(r.body.status, 'ready');
  assert.equal(r.body.payload, 'AbCdEf0123_-');

  r = await invoke({ action: 'take', ...base });
  assert.equal(r.status, 200);
  assert.equal(r.body.payload, 'AbCdEf0123_-');

  r = await invoke({ action: 'consume', ...base });
  assert.equal(r.status, 200);
  r = await invoke({ action: 'take', ...base });
  assert.equal(r.status, 410);
  assert.deepEqual(r.body, { error: 'relay_session_expired' });
});

test('malformed session and plaintext-like payload shapes are rejected', async () => {
  let r = await invoke({ action: 'create', protocolVersion: 2, sessionId: 'short', expiresAt: expiry() });
  assert.equal(r.status, 400);
  r = await invoke({ action: 'respond', ...base, payload: '{"profile":"plaintext"}' });
  assert.equal(r.status, 413);
});

test('TTL removes abandoned pending or answered sessions without scheduled cleanup', async () => {
  const ttlSid = 'ZYXWVUTSRQPONMLKJIHGFEDC';
  let r = await invoke({ action: 'create', protocolVersion: 2, sessionId: ttlSid, expiresAt: new Date(nowMs + 15000).toISOString() });
  assert.equal(r.status, 201);
  nowMs += 16000;
  r = await invoke({ action: 'take', protocolVersion: 2, sessionId: ttlSid });
  assert.equal(r.status, 410);
});

test('source never logs relay payloads or secrets', async () => {
  assert.equal(/console\.(log|error|warn)/.test(source), false);
  assert.equal(source.includes('UPSTASH_REDIS_REST_TOKEN'), true);
  assert.equal(source.includes("createHmac('sha256'"), true);
});

for (const entry of cases) {
  try {
    await entry.fn();
    console.log(`✓ ${entry.name}`);
  } catch (error) {
    failures += 1;
    console.error(`✗ ${entry.name}`);
    console.error(error);
  }
}

if (failures) process.exit(1);
console.log(`\n${cases.length} relay contract tests passed.`);

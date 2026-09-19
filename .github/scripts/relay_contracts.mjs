import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFile } from 'node:fs/promises';

process.env.ZYNC_CARDVERSE_PROOF_SECRET =
  'unit-test-cardverse-proof-secret-1234567890';

const source = await readFile('api/v1/relay.js', 'utf8');
const { default: relay } = await import('../../api/v1/relay.js');

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
      if (entry.value.startsWith('P|')) {
        const auth = entry.value.slice(2);
        if (auth.length !== 64) return 'invalid';
        entry.value = argv[1]
          ? `R2|${auth}|${argv[1]}|${argv[0]}`
          : `R|${auth}|${argv[0]}`;
        return 'accepted';
      }
      if (entry.value.startsWith('R2|')) {
        const parts = entry.value.split('|');
        if (parts.length !== 4) return 'invalid';
        if (parts[3] === argv[0] && parts[2] === argv[1]) return 'same';
        return 'duplicate';
      }
      if (entry.value.startsWith('R|')) {
        if (entry.value.length < 68 || entry.value[66] !== '|') return 'invalid';
        if (entry.value.slice(67) === argv[0]) return 'same';
        return 'duplicate';
      }
      if (entry.value.startsWith('C2|')) return 'completed';
      return 'invalid';
    }

    if (script.includes("return 'completed:'..ARGV[2]")) {
      const key = keys[0];
      const entry = alive(key);
      if (!entry) return 'missing';
      if (entry.value.startsWith('C2|')) {
        const parts = entry.value.split('|');
        if (parts.length !== 4) return 'invalid';
        if (parts[1] !== argv[0]) return 'forbidden';
        return 'completed:' + parts[3];
      }
      if (entry.value.startsWith('R2|')) {
        const parts = entry.value.split('|');
        if (parts.length !== 4) return 'invalid';
        if (parts[1] !== argv[0]) return 'forbidden';
        entry.value = `C2|${parts[1]}|${parts[2]}|${argv[1]}`;
        return 'completed:' + argv[1];
      }
      if (entry.value.startsWith('R|')) {
        const auth = entry.value.slice(2, 66);
        if (auth !== argv[0]) return 'forbidden';
        store.delete(key);
        return 'deleted';
      }
      return 'invalid';
    }

    if (script.includes("return 'deleted'")) {
      const key = keys[0];
      const entry = alive(key);
      if (!entry) return 'missing';
      let auth = null;
      if (entry.value.startsWith('P|')) auth = entry.value.slice(2);
      if (entry.value.startsWith('R|')) auth = entry.value.slice(2, 66);
      if (entry.value.startsWith('R2|') || entry.value.startsWith('C2|')) {
        auth = entry.value.split('|')[1];
      }
      if (!auth || auth.length !== 64) {
        store.delete(key);
        return 'invalid';
      }
      if (auth !== argv[0]) return 'forbidden';
      store.delete(key);
      return 'deleted';
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
const hostToken = '0123456789ABCDEFGHIJKLMNOPQRSTUV';
const wrongHostToken = 'ZYXWVUTSRQPONMLKJIHGFEDCBA987654';
const hostHash = createHash('sha256').update(hostToken).digest('hex');
const expiry = () => new Date(nowMs + 180000).toISOString();
const peerBase = { protocolVersion: 2, sessionId: sid };
const hostBase = { ...peerBase, hostToken };

let failures = 0;
const cases = [];
const test = (name, fn) => cases.push({ name, fn });

test('relay rejects non-POST and does not cache responses', async () => {
  const r = await invoke({}, 'GET');
  assert.equal(r.status, 405);
  assert.equal(r.headers.allow, 'POST');
  assert.equal(r.headers['cache-control'], 'no-store');
});

test('relay refuses to run without any supported shared-store configuration', async () => {
  const saved = {
    upstashUrl: process.env.UPSTASH_REDIS_REST_URL,
    upstashToken: process.env.UPSTASH_REDIS_REST_TOKEN,
    kvUrl: process.env.KV_REST_API_URL,
    kvToken: process.env.KV_REST_API_TOKEN,
  };
  delete process.env.UPSTASH_REDIS_REST_URL;
  delete process.env.UPSTASH_REDIS_REST_TOKEN;
  delete process.env.KV_REST_API_URL;
  delete process.env.KV_REST_API_TOKEN;
  const r = await invoke({ action: 'create', ...hostBase, expiresAt: expiry() });
  process.env.UPSTASH_REDIS_REST_URL = saved.upstashUrl;
  process.env.UPSTASH_REDIS_REST_TOKEN = saved.upstashToken;
  if (saved.kvUrl == null) delete process.env.KV_REST_API_URL; else process.env.KV_REST_API_URL = saved.kvUrl;
  if (saved.kvToken == null) delete process.env.KV_REST_API_TOKEN; else process.env.KV_REST_API_TOKEN = saved.kvToken;
  assert.equal(r.status, 503);
  assert.deepEqual(r.body, { error: 'relay_not_configured' });
});

test('relay accepts Vercel Upstash integration KV_REST_API aliases', async () => {
  const upstashUrl = process.env.UPSTASH_REDIS_REST_URL;
  const upstashToken = process.env.UPSTASH_REDIS_REST_TOKEN;
  delete process.env.UPSTASH_REDIS_REST_URL;
  delete process.env.UPSTASH_REDIS_REST_TOKEN;
  process.env.KV_REST_API_URL = 'https://fake-upstash.example';
  process.env.KV_REST_API_TOKEN = 'unit-test-token';

  const aliasSessionId = 'KVRELAYABCDEFGHIJKLMNOPQ';
  const aliasHostToken = 'AA23456789ABCDEFGHIJKLMNOPQRSTUV';
  let r = await invoke({
    action: 'create',
    protocolVersion: 2,
    sessionId: aliasSessionId,
    hostToken: aliasHostToken,
    expiresAt: expiry(),
  });
  assert.equal(r.status, 201);
  assert.equal(r.body.status, 'created');

  r = await invoke({
    action: 'cancel',
    protocolVersion: 2,
    sessionId: aliasSessionId,
    hostToken: aliasHostToken,
  });
  assert.equal(r.status, 200);

  process.env.UPSTASH_REDIS_REST_URL = upstashUrl;
  process.env.UPSTASH_REDIS_REST_TOKEN = upstashToken;
  delete process.env.KV_REST_API_URL;
  delete process.env.KV_REST_API_TOKEN;
});

test('create stores only a short-lived host capability hash and is retry-safe', async () => {
  store.clear();
  let r = await invoke({ action: 'create', ...hostBase, expiresAt: expiry() });
  assert.equal(r.status, 201);
  assert.equal(r.body.status, 'created');
  const entry = alive(`zync:relay:v2:${sid}`);
  assert.equal(entry.value, `P|${hostHash}`);
  assert.equal(entry.value.includes(hostToken), false);
  assert.ok(entry.expiresAt - nowMs <= 180000);
  assert.ok(entry.expiresAt - nowMs >= 15000);

  r = await invoke({ action: 'create', ...hostBase, expiresAt: expiry() });
  assert.equal(r.status, 200);
  assert.equal(r.body.status, 'already_created');

  r = await invoke({ action: 'create', ...peerBase, hostToken: wrongHostToken, expiresAt: expiry() });
  assert.equal(r.status, 409);
  assert.deepEqual(r.body, { error: 'relay_session_exists' });
});

test('scanner can write without the host capability and only one encrypted response wins', async () => {
  const payload = 'AbCdEf0123_-';
  let r = await invoke({ action: 'respond', ...peerBase, payload });
  assert.equal(r.status, 200);
  assert.equal(r.body.status, 'received');
  assert.match(r.body.proofCapability, /^[A-Za-z0-9_-]{43}$/);
  const proofCapability = r.body.proofCapability;

  r = await invoke({ action: 'proof', ...peerBase, proofCapability });
  assert.equal(r.status, 200);
  assert.equal(r.body.status, 'waiting');

  r = await invoke({ action: 'respond', ...peerBase, payload });
  assert.equal(r.status, 200);
  assert.equal(r.body.status, 'already_received');

  r = await invoke({ action: 'respond', ...peerBase, payload: 'DifferentOpaquePayload_123' });
  assert.equal(r.status, 409);
  assert.deepEqual(r.body, { error: 'relay_already_answered' });
});

test('wrong host capability cannot poll or consume the scanner response', async () => {
  let r = await invoke({ action: 'take', ...peerBase, hostToken: wrongHostToken });
  assert.equal(r.status, 403);
  assert.deepEqual(r.body, { error: 'relay_host_not_authorized' });

  r = await invoke({ action: 'consume', ...peerBase, hostToken: wrongHostToken });
  assert.equal(r.status, 403);
  assert.deepEqual(r.body, { error: 'relay_host_not_authorized' });
});

test('authorized host polling is non-destructive until consume and both sides get anonymous proof tickets', async () => {
  let r = await invoke({ action: 'take', ...hostBase });
  assert.equal(r.status, 200);
  assert.equal(r.body.status, 'ready');
  assert.equal(r.body.payload, 'AbCdEf0123_-');

  r = await invoke({ action: 'take', ...hostBase });
  assert.equal(r.status, 200);
  assert.equal(r.body.payload, 'AbCdEf0123_-');

  const priorRespond = await invoke({
    action: 'respond',
    ...peerBase,
    payload: 'AbCdEf0123_-',
  });
  const proofCapability = priorRespond.body.proofCapability;

  r = await invoke({ action: 'consume', ...hostBase });
  assert.equal(r.status, 200);
  assert.match(r.body.proofTicket, /^ZP1\./);

  const retry = await invoke({ action: 'consume', ...hostBase });
  assert.equal(retry.status, 200);
  assert.equal(retry.body.proofTicket, r.body.proofTicket);

  const scannerProof = await invoke({
    action: 'proof',
    ...peerBase,
    proofCapability,
  });
  assert.equal(scannerProof.status, 200);
  assert.equal(scannerProof.body.status, 'ready');
  assert.match(scannerProof.body.proofTicket, /^ZP1\./);
  assert.notEqual(scannerProof.body.proofTicket, r.body.proofTicket);

  const takenAfterCompletion = await invoke({ action: 'take', ...hostBase });
  assert.equal(takenAfterCompletion.status, 200);
  assert.equal(takenAfterCompletion.body.status, 'completed');
});

test('malformed session, missing host auth and plaintext-like payload shapes are rejected', async () => {
  let r = await invoke({ action: 'create', protocolVersion: 2, sessionId: 'short', hostToken, expiresAt: expiry() });
  assert.equal(r.status, 400);
  r = await invoke({ action: 'create', ...peerBase, expiresAt: expiry() });
  assert.equal(r.status, 400);
  r = await invoke({ action: 'respond', ...peerBase, payload: '{"profile":"plaintext"}' });
  assert.equal(r.status, 413);
});

test('TTL removes abandoned sessions without scheduled cleanup', async () => {
  const ttlSid = 'ZYXWVUTSRQPONMLKJIHGFEDC';
  const ttlToken = 'ABCDEFGHIJKLMNOPQRSTUV0123456789';
  let r = await invoke({
    action: 'create',
    protocolVersion: 2,
    sessionId: ttlSid,
    hostToken: ttlToken,
    expiresAt: new Date(nowMs + 15000).toISOString(),
  });
  assert.equal(r.status, 201);
  nowMs += 16000;
  r = await invoke({ action: 'take', protocolVersion: 2, sessionId: ttlSid, hostToken: ttlToken });
  assert.equal(r.status, 410);
});

test('source never logs relay payloads or secrets', async () => {
  assert.equal(/console\.(log|error|warn)/.test(source), false);
  assert.equal(source.includes('UPSTASH_REDIS_REST_TOKEN'), true);
  assert.equal(source.includes('KV_REST_API_TOKEN'), true);
  assert.equal(source.includes("createHmac('sha256'"), true);
  assert.equal(source.includes("createHash('sha256'"), true);
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

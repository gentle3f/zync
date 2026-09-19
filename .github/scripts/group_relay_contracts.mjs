import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFile } from 'node:fs/promises';

const source = await readFile('api/v1/group-relay.js', 'utf8');
const encoded = Buffer.from(source).toString('base64');
const { default: relay } = await import(`data:text/javascript;base64,${encoded}`);

function makeResponse() {
  const state = { status: 200, body: undefined, headers: {} };
  const res = {
    status(code) { state.status = code; return res; },
    json(value) { state.body = value; return res; },
    setHeader(name, value) {
      state.headers[String(name).toLowerCase()] = value;
      return res;
    },
  };
  return { state, res };
}

async function invoke(body, method = 'POST') {
  const { state, res } = makeResponse();
  await relay({
    method,
    body,
    headers: { 'x-forwarded-for': '203.0.113.88' },
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

function ensureHash(key) {
  let entry = alive(key);
  if (!entry) {
    entry = { type: 'hash', value: new Map(), expiresAt: null };
    store.set(key, entry);
  }
  assert.equal(entry.type, 'hash');
  return entry;
}

function result(value, ok = true) {
  return {
    ok,
    status: ok ? 200 : 500,
    json: async () => ok ? { result: value } : { error: 'fake_redis_error' },
  };
}

function parseMeta(value) {
  if (typeof value !== 'string') return null;
  const parts = value.split('|');
  if (parts.length !== 5 || parts[0] !== 'M') return null;
  return {
    hostHash: parts[1],
    joinHash: parts[2],
    max: Number(parts[3]),
    phase: parts[4],
  };
}

function fakeRedis(command) {
  const [op, ...args] = command;

  if (op === 'SET') {
    const [key, value, ...rest] = args;
    const existing = alive(key);
    const nx = rest.includes('NX');
    const xx = rest.includes('XX');
    if (nx && existing) return null;
    if (xx && !existing) return null;

    let expiresAt = existing?.expiresAt ?? null;
    const exIndex = rest.indexOf('EX');
    if (exIndex >= 0) {
      expiresAt = nowMs + Number(rest[exIndex + 1]) * 1000;
    }
    store.set(key, { type: 'string', value: String(value), expiresAt });
    return 'OK';
  }

  if (op === 'GET') {
    const entry = alive(args[0]);
    if (!entry) return null;
    assert.equal(entry.type, 'string');
    return entry.value;
  }

  if (op === 'DEL') {
    let count = 0;
    for (const key of args) {
      if (store.delete(key)) count += 1;
    }
    return count;
  }

  if (op === 'HGET') {
    const entry = alive(args[0]);
    if (!entry) return null;
    assert.equal(entry.type, 'hash');
    return entry.value.get(args[1]) ?? null;
  }

  if (op === 'HSET') {
    const entry = ensureHash(args[0]);
    const existed = entry.value.has(args[1]);
    entry.value.set(args[1], String(args[2]));
    return existed ? 0 : 1;
  }

  if (op === 'HLEN') {
    const entry = alive(args[0]);
    if (!entry) return 0;
    assert.equal(entry.type, 'hash');
    return entry.value.size;
  }

  if (op === 'HGETALL') {
    const entry = alive(args[0]);
    if (!entry) return [];
    assert.equal(entry.type, 'hash');
    return [...entry.value.entries()].flat();
  }

  if (op === 'HDEL') {
    const entry = alive(args[0]);
    if (!entry) return 0;
    assert.equal(entry.type, 'hash');
    return entry.value.delete(args[1]) ? 1 : 0;
  }

  if (op === 'EXPIRE') {
    const entry = alive(args[0]);
    if (!entry) return 0;
    entry.expiresAt = nowMs + Number(args[1]) * 1000;
    return 1;
  }

  if (op === 'TTL') {
    const entry = alive(args[0]);
    if (!entry) return -2;
    if (entry.expiresAt == null) return -1;
    return Math.max(0, Math.ceil((entry.expiresAt - nowMs) / 1000));
  }

  if (op === 'EVAL') {
    const script = String(args[0]);
    const keyCount = Number(args[1]);
    const keys = args.slice(2, 2 + keyCount);
    const argv = args.slice(2 + keyCount);

    if (script.includes("redis.call('INCR'")) {
      const key = keys[0];
      const entry = alive(key);
      const next = entry ? Number(entry.value) + 1 : 1;
      store.set(key, {
        type: 'string',
        value: String(next),
        expiresAt: entry?.expiresAt ?? nowMs + 60000,
      });
      return next;
    }

    if (script.includes('-- group_join')) {
      const metaEntry = alive(keys[0]);
      if (!metaEntry) return 'missing';
      const meta = parseMeta(metaEntry.value);
      if (!meta) return 'invalid';
      if (meta.joinHash !== argv[0]) return 'forbidden';
      if (meta.phase !== 'L') return 'locked';

      const participants = ensureHash(keys[1]);
      const existing = participants.value.get(argv[1]);
      if (existing != null) {
        return existing === argv[2] ? 'same' : 'duplicate';
      }
      if (participants.value.size >= meta.max - 1) return 'full';
      participants.value.set(argv[1], argv[2]);
      participants.expiresAt = metaEntry.expiresAt;
      return 'joined';
    }

    if (script.includes('-- group_lock')) {
      const metaEntry = alive(keys[0]);
      if (!metaEntry) return 'missing';
      const meta = parseMeta(metaEntry.value);
      if (!meta) return 'invalid';
      if (meta.hostHash !== argv[0]) return 'forbidden';
      if (meta.phase === 'S') return 'same';
      metaEntry.value = `M|${meta.hostHash}|${meta.joinHash}|${meta.max}|S`;
      return 'locked';
    }

    if (script.includes('-- group_input')) {
      const metaEntry = alive(keys[0]);
      if (!metaEntry) return 'missing';
      const meta = parseMeta(metaEntry.value);
      if (!meta) return 'invalid';
      if (meta.joinHash !== argv[0]) return 'forbidden';
      if (meta.phase !== 'S') return 'not_started';

      const participants = alive(keys[1]);
      if (!participants || !participants.value.has(argv[1])) return 'unknown';

      const inputs = ensureHash(keys[2]);
      const existing = inputs.value.get(argv[1]);
      if (existing != null) {
        return existing === argv[2] ? 'same' : 'duplicate';
      }
      inputs.value.set(argv[1], argv[2]);
      inputs.expiresAt = metaEntry.expiresAt;
      return 'accepted';
    }

    if (script.includes('-- group_publish_state')) {
      const metaEntry = alive(keys[0]);
      if (!metaEntry) return 'missing';
      const meta = parseMeta(metaEntry.value);
      if (!meta) return 'invalid';
      if (meta.hostHash !== argv[0]) return 'forbidden';

      const nextRevision = Number(argv[1]);
      const nextPayload = argv[2];
      const stateEntry = alive(keys[1]);
      if (stateEntry) {
        const match = /^S\|([0-9]+)\|([A-Za-z0-9_-]+)$/.exec(stateEntry.value);
        if (!match) return 'invalid';
        const currentRevision = Number(match[1]);
        if (currentRevision > nextRevision) return 'stale';
        if (currentRevision === nextRevision) {
          return match[2] === nextPayload ? 'same' : 'conflict';
        }
      }
      store.set(keys[1], {
        type: 'string',
        value: `S|${nextRevision}|${nextPayload}`,
        expiresAt: metaEntry.expiresAt,
      });
      return 'published';
    }

    throw new Error(`Unsupported fake EVAL: ${script}`);
  }

  throw new Error(`Unsupported fake Redis command: ${op}`);
}

globalThis.fetch = async (url, options) => {
  assert.equal(url, 'https://fake-upstash.example');
  assert.equal(options.method, 'POST');
  assert.equal(options.headers.Authorization, 'Bearer unit-test-token');
  return result(fakeRedis(JSON.parse(options.body)));
};

process.env.UPSTASH_REDIS_REST_URL = 'https://fake-upstash.example';
process.env.UPSTASH_REDIS_REST_TOKEN = 'unit-test-token';
process.env.ZYNC_RELAY_RATE_LIMIT_SECRET = 'unit-test-rate-secret-1234567890';

const roomId = 'ABCDEFGHIJKLMNOPQRSTUVWX';
const hostToken = '0123456789ABCDEFGHIJKLMNOPQRSTUV';
const joinToken = 'ABCDEFGHIJKLMNOPQRSTUV0123456789';
const wrongHostToken = 'ZYXWVUTSRQPONMLKJIHGFEDCBA987654';
const wrongJoinToken = '9876543210ZYXWVUTSRQPONMLKJIHGFE';
const hostHash = createHash('sha256').update(hostToken).digest('hex');
const joinHash = createHash('sha256').update(joinToken).digest('hex');
const p1 = 'AAAABBBBCCCCDDDDEEEEFFFF';
const p2 = 'FFFFEEEEDDDDCCCCBBBBAAAA';
const p3 = '111122223333444455556666';
const expiry = (seconds = 1200) => new Date(nowMs + seconds * 1000).toISOString();
const base = { protocolVersion: 1, roomId };

let failures = 0;
const cases = [];
const test = (name, fn) => cases.push({ name, fn });

test('group relay rejects non-POST and disables caching', async () => {
  const r = await invoke({}, 'GET');
  assert.equal(r.status, 405);
  assert.equal(r.headers.allow, 'POST');
  assert.equal(r.headers['cache-control'], 'no-store');
});

test('group relay refuses to run without shared-store configuration', async () => {
  const url = process.env.UPSTASH_REDIS_REST_URL;
  const token = process.env.UPSTASH_REDIS_REST_TOKEN;
  delete process.env.UPSTASH_REDIS_REST_URL;
  delete process.env.UPSTASH_REDIS_REST_TOKEN;
  const r = await invoke({ action: 'create', ...base });
  process.env.UPSTASH_REDIS_REST_URL = url;
  process.env.UPSTASH_REDIS_REST_TOKEN = token;
  assert.equal(r.status, 503);
  assert.deepEqual(r.body, { error: 'group_relay_not_configured' });
});

test('create stores only short-lived capability hashes and is retry-safe', async () => {
  store.clear();
  let r = await invoke({
    action: 'create',
    ...base,
    hostToken,
    joinToken,
    expiresAt: expiry(),
    maxParticipants: 4,
  });
  assert.equal(r.status, 201);
  assert.equal(r.body.status, 'created');

  const meta = alive(`zync:group:v1:${roomId}:meta`);
  assert.ok(meta);
  assert.equal(meta.value, `M|${hostHash}|${joinHash}|4|L`);
  assert.equal(meta.value.includes(hostToken), false);
  assert.equal(meta.value.includes(joinToken), false);

  r = await invoke({
    action: 'create',
    ...base,
    hostToken,
    joinToken,
    expiresAt: expiry(),
    maxParticipants: 4,
  });
  assert.equal(r.status, 200);
  assert.equal(r.body.status, 'already_created');
});

test('join is capability-gated, duplicate-safe and host can fetch only opaque payloads',
async () => {
  let r = await invoke({
    action: 'join',
    ...base,
    joinToken: wrongJoinToken,
    participantId: p1,
    payload: 'OpaquePayload_AAA111',
  });
  assert.equal(r.status, 403);

  r = await invoke({
    action: 'join',
    ...base,
    joinToken,
    participantId: p1,
    payload: 'OpaquePayload_AAA111',
  });
  assert.equal(r.status, 200);
  assert.equal(r.body.participantCount, 2);

  r = await invoke({
    action: 'join',
    ...base,
    joinToken,
    participantId: p1,
    payload: 'OpaquePayload_AAA111',
  });
  assert.equal(r.status, 200);
  assert.equal(r.body.status, 'already_joined');

  r = await invoke({
    action: 'join',
    ...base,
    joinToken,
    participantId: p1,
    payload: 'DifferentOpaque_BBB222',
  });
  assert.equal(r.status, 409);
  assert.equal(r.body.error, 'group_participant_conflict');

  await invoke({
    action: 'join',
    ...base,
    joinToken,
    participantId: p2,
    payload: 'OpaquePayload_CCC333',
  });

  r = await invoke({
    action: 'take_participants',
    ...base,
    hostToken: wrongHostToken,
  });
  assert.equal(r.status, 403);

  r = await invoke({
    action: 'take_participants',
    ...base,
    hostToken,
  });
  assert.equal(r.status, 200);
  assert.equal(r.body.participantCount, 3);
  assert.equal(r.body.participants.length, 2);
  assert.deepEqual(
    new Set(r.body.participants.map((item) => item.participantId)),
    new Set([p1, p2]),
  );
  assert.equal(
    r.body.participants.every((item) => /^[A-Za-z0-9_-]+$/.test(item.payload)),
    true,
  );
});

test('participant can leave before lock and rejoin', async () => {
  let r = await invoke({
    action: 'leave',
    ...base,
    joinToken,
    participantId: p2,
  });
  assert.equal(r.status, 200);

  r = await invoke({
    action: 'take_participants',
    ...base,
    hostToken,
  });
  assert.equal(r.body.participantCount, 2);

  r = await invoke({
    action: 'join',
    ...base,
    joinToken,
    participantId: p2,
    payload: 'OpaquePayload_CCC333',
  });
  assert.equal(r.status, 200);
});

test('host lock is private and late joins are rejected', async () => {
  let r = await invoke({
    action: 'lock',
    ...base,
    hostToken: wrongHostToken,
  });
  assert.equal(r.status, 403);

  r = await invoke({
    action: 'lock',
    ...base,
    hostToken,
  });
  assert.equal(r.status, 200);
  assert.equal(r.body.status, 'locked');

  r = await invoke({
    action: 'join',
    ...base,
    joinToken,
    participantId: p3,
    payload: 'OpaquePayload_DDD444',
  });
  assert.equal(r.status, 409);
  assert.equal(r.body.error, 'group_room_locked');

  r = await invoke({
    action: 'leave',
    ...base,
    joinToken,
    participantId: p1,
  });
  assert.equal(r.status, 409);
  assert.equal(r.body.error, 'group_room_locked');
});

test('private round input is member-only, idempotent and host-readable', async () => {
  let r = await invoke({
    action: 'submit_input',
    ...base,
    joinToken,
    participantId: p3,
    roundNumber: 1,
    payload: 'PrivateInput_UNKNOWN',
  });
  assert.equal(r.status, 403);
  assert.equal(r.body.error, 'group_participant_unknown');

  r = await invoke({
    action: 'submit_input',
    ...base,
    joinToken,
    participantId: p1,
    roundNumber: 1,
    payload: 'PrivateInput_111',
  });
  assert.equal(r.status, 200);
  assert.equal(r.body.status, 'received');

  r = await invoke({
    action: 'submit_input',
    ...base,
    joinToken,
    participantId: p1,
    roundNumber: 1,
    payload: 'PrivateInput_111',
  });
  assert.equal(r.status, 200);
  assert.equal(r.body.status, 'already_received');

  r = await invoke({
    action: 'submit_input',
    ...base,
    joinToken,
    participantId: p1,
    roundNumber: 1,
    payload: 'PrivateInput_Changed',
  });
  assert.equal(r.status, 409);

  r = await invoke({
    action: 'take_inputs',
    ...base,
    hostToken,
    roundNumber: 1,
  });
  assert.equal(r.status, 200);
  assert.deepEqual(r.body.inputs, [
    { participantId: p1, payload: 'PrivateInput_111' },
  ]);
});

test('bounded room state is monotonic and pollable only with join capability',
async () => {
  let r = await invoke({
    action: 'publish_state',
    ...base,
    hostToken,
    revision: 1,
    payload: 'EncryptedState_111',
  });
  assert.equal(r.status, 200);

  r = await invoke({
    action: 'poll_state',
    ...base,
    joinToken: wrongJoinToken,
    sinceRevision: 0,
  });
  assert.equal(r.status, 403);

  r = await invoke({
    action: 'poll_state',
    ...base,
    joinToken,
    sinceRevision: 0,
  });
  assert.equal(r.status, 200);
  assert.equal(r.body.status, 'ready');
  assert.equal(r.body.revision, 1);
  assert.equal(r.body.payload, 'EncryptedState_111');
  assert.equal(r.body.locked, true);

  r = await invoke({
    action: 'poll_state',
    ...base,
    joinToken,
    sinceRevision: 1,
  });
  assert.equal(r.status, 200);
  assert.equal(r.body.status, 'waiting');

  r = await invoke({
    action: 'publish_state',
    ...base,
    hostToken,
    revision: 0,
    payload: 'StaleState_000',
  });
  assert.equal(r.status, 409);
  assert.equal(r.body.error, 'group_state_conflict');
});

test('room capacity counts host plus guests', async () => {
  const capRoom = 'CAPACITYABCDEFGHIJKLMNOP';
  const capBase = { protocolVersion: 1, roomId: capRoom };
  let r = await invoke({
    action: 'create',
    ...capBase,
    hostToken,
    joinToken,
    expiresAt: expiry(),
    maxParticipants: 3,
  });
  assert.equal(r.status, 201);

  for (const [participantId, payload] of [
    [p1, 'Capacity_AAA'],
    [p2, 'Capacity_BBB'],
  ]) {
    r = await invoke({
      action: 'join',
      ...capBase,
      joinToken,
      participantId,
      payload,
    });
    assert.equal(r.status, 200);
  }

  r = await invoke({
    action: 'join',
    ...capBase,
    joinToken,
    participantId: p3,
    payload: 'Capacity_CCC',
  });
  assert.equal(r.status, 409);
  assert.equal(r.body.error, 'group_room_full');
});

test('TTL removes abandoned group rooms without scheduled cleanup', async () => {
  const ttlRoom = 'TTLROOMABCDEFGHIJKLMNOPQ';
  const ttlBase = { protocolVersion: 1, roomId: ttlRoom };
  let r = await invoke({
    action: 'create',
    ...ttlBase,
    hostToken,
    joinToken,
    expiresAt: expiry(30),
    maxParticipants: 3,
  });
  assert.equal(r.status, 201);

  nowMs += 31000;
  r = await invoke({
    action: 'poll_state',
    ...ttlBase,
    joinToken,
    sinceRevision: -1,
  });
  assert.equal(r.status, 410);
  nowMs -= 31000;
});

test('only host can close room and close is idempotent', async () => {
  let r = await invoke({
    action: 'close',
    ...base,
    hostToken: wrongHostToken,
  });
  assert.equal(r.status, 403);

  r = await invoke({
    action: 'close',
    ...base,
    hostToken,
  });
  assert.equal(r.status, 200);

  r = await invoke({
    action: 'close',
    ...base,
    hostToken,
  });
  assert.equal(r.status, 200);

  r = await invoke({
    action: 'poll_state',
    ...base,
    joinToken,
    sinceRevision: -1,
  });
  assert.equal(r.status, 410);
});

test('source never logs group payloads or capabilities', async () => {
  assert.equal(/console\.(log|error|warn)/.test(source), false);
  assert.equal(source.includes('UPSTASH_REDIS_REST_TOKEN'), true);
  assert.equal(source.includes("createHash('sha256'"), true);
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
console.log(`\n${cases.length} Group Zync relay contract tests passed.`);

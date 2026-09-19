import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFile } from 'node:fs/promises';

const source = await readFile('api/v1/group-relay.js', 'utf8');
const encoded = Buffer.from(source).toString('base64');
const imported = await import('data:text/javascript;base64,' + encoded);
const relay = imported.default;

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
  const pair = makeResponse();
  await relay({
    method,
    body,
    headers: { 'x-forwarded-for': '203.0.113.88' },
  }, pair.res);
  return pair.state;
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

function stringEntry(value, expiresAt = null) {
  return { type: 'string', value: String(value), expiresAt };
}

function hashEntry(expiresAt = null) {
  return { type: 'hash', value: new Map(), expiresAt };
}

function ensureHash(key) {
  let entry = alive(key);
  if (!entry) {
    entry = hashEntry();
    store.set(key, entry);
  }
  assert.equal(entry.type, 'hash');
  return entry;
}

function redisResponse(value, ok = true) {
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

function parseParticipant(value) {
  const match = /^A\|([a-f0-9]{64})\|([A-Za-z0-9_-]+)$/.exec(String(value));
  if (!match) return null;
  return { authHash: match[1], payload: match[2] };
}

function fakeRedis(command) {
  const op = command[0];
  const args = command.slice(1);

  if (op === 'SET') {
    const key = args[0];
    const value = args[1];
    const rest = args.slice(2);
    const existing = alive(key);
    const nx = rest.includes('NX');
    const xx = rest.includes('XX');
    if (nx && existing) return null;
    if (xx && !existing) return null;

    let expiresAt = existing ? existing.expiresAt : null;
    const exIndex = rest.indexOf('EX');
    if (exIndex >= 0) {
      expiresAt = nowMs + Number(rest[exIndex + 1]) * 1000;
    }
    store.set(key, stringEntry(value, expiresAt));
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
      store.set(
        key,
        stringEntry(String(next), entry ? entry.expiresAt : nowMs + 60000),
      );
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
        const parsed = parseParticipant(existing);
        if (!parsed) return 'invalid';
        if (parsed.authHash === argv[2] && parsed.payload === argv[3]) {
          return 'same';
        }
        return 'duplicate';
      }
      if (participants.value.size >= meta.max - 1) return 'full';

      participants.value.set(argv[1], 'A|' + argv[2] + '|' + argv[3]);
      participants.expiresAt = metaEntry.expiresAt;
      return 'joined';
    }

    if (script.includes('-- group_leave')) {
      const metaEntry = alive(keys[0]);
      if (!metaEntry) return 'missing';
      const meta = parseMeta(metaEntry.value);
      if (!meta) return 'invalid';
      if (meta.joinHash !== argv[0]) return 'forbidden_room';
      if (meta.phase !== 'L') return 'locked';

      const participants = alive(keys[1]);
      const stored = participants?.value.get(argv[1]);
      if (stored == null) return 'missing_member';
      const parsed = parseParticipant(stored);
      if (!parsed) return 'invalid';
      if (parsed.authHash !== argv[2]) return 'forbidden_participant';

      participants.value.delete(argv[1]);
      return 'left';
    }

    if (script.includes('-- group_lock')) {
      const metaEntry = alive(keys[0]);
      if (!metaEntry) return 'missing';
      const meta = parseMeta(metaEntry.value);
      if (!meta) return 'invalid';
      if (meta.hostHash !== argv[0]) return 'forbidden';
      if (meta.phase === 'S') return 'same';
      metaEntry.value =
        'M|' + meta.hostHash + '|' + meta.joinHash + '|' + meta.max + '|S';
      return 'locked';
    }

    if (script.includes('-- group_input')) {
      const metaEntry = alive(keys[0]);
      if (!metaEntry) return 'missing';
      const meta = parseMeta(metaEntry.value);
      if (!meta) return 'invalid';
      if (meta.joinHash !== argv[0]) return 'forbidden_room';
      if (meta.phase !== 'S') return 'not_started';

      const participants = alive(keys[1]);
      const stored = participants?.value.get(argv[1]);
      if (stored == null) return 'unknown';
      const parsed = parseParticipant(stored);
      if (!parsed) return 'invalid';
      if (parsed.authHash !== argv[2]) return 'forbidden_participant';

      const inputs = ensureHash(keys[2]);
      const existing = inputs.value.get(argv[1]);
      if (existing != null) return existing === argv[3] ? 'same' : 'duplicate';
      inputs.value.set(argv[1], argv[3]);
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

      store.set(
        keys[1],
        stringEntry('S|' + nextRevision + '|' + nextPayload, metaEntry.expiresAt),
      );
      return 'published';
    }

    throw new Error('Unsupported fake EVAL: ' + script);
  }

  throw new Error('Unsupported fake Redis command: ' + op);
}

globalThis.fetch = async (url, options) => {
  assert.equal(url, 'https://fake-upstash.example');
  assert.equal(options.method, 'POST');
  assert.equal(options.headers.Authorization, 'Bearer unit-test-token');
  return redisResponse(fakeRedis(JSON.parse(options.body)));
};

process.env.UPSTASH_REDIS_REST_URL = 'https://fake-upstash.example';
process.env.UPSTASH_REDIS_REST_TOKEN = 'unit-test-token';
process.env.ZYNC_RELAY_RATE_LIMIT_SECRET =
  'unit-test-rate-secret-1234567890';

const roomId = 'ABCDEFGHIJKLMNOPQRSTUVWX';
const hostToken = '0123456789ABCDEFGHIJKLMNOPQRSTUV';
const joinToken = 'ABCDEFGHIJKLMNOPQRSTUV0123456789';
const wrongHostToken = 'ZYXWVUTSRQPONMLKJIHGFEDCBA987654';
const wrongJoinToken = '9876543210ZYXWVUTSRQPONMLKJIHGFE';

const p1 = 'AAAABBBBCCCCDDDDEEEEFFFF';
const p2 = 'FFFFEEEEDDDDCCCCBBBBAAAA';
const p3 = '111122223333444455556666';

const p1Token = 'P1TOKENABCDEFGHIJKLMNOPQRSTUVWXY';
const p2Token = 'P2TOKENABCDEFGHIJKLMNOPQRSTUVWXY';
const p3Token = 'P3TOKENABCDEFGHIJKLMNOPQRSTUVWXY';

const hostHash = createHash('sha256').update(hostToken).digest('hex');
const joinHash = createHash('sha256').update(joinToken).digest('hex');
const p1Hash = createHash('sha256').update(p1Token).digest('hex');
const p2Hash = createHash('sha256').update(p2Token).digest('hex');

const expiry = (seconds = 1200) =>
  new Date(nowMs + seconds * 1000).toISOString();
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

  const meta = alive('zync:group:v1:' + roomId + ':meta');
  assert.ok(meta);
  assert.equal(meta.value, 'M|' + hostHash + '|' + joinHash + '|4|L');
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

test('join binds profile to a private participant capability', async () => {
  let r = await invoke({
    action: 'join',
    ...base,
    joinToken: wrongJoinToken,
    participantId: p1,
    participantToken: p1Token,
    payload: 'OpaquePayload_AAA111',
  });
  assert.equal(r.status, 403);

  r = await invoke({
    action: 'join',
    ...base,
    joinToken,
    participantId: p1,
    participantToken: p1Token,
    payload: 'OpaquePayload_AAA111',
  });
  assert.equal(r.status, 200);
  assert.equal(r.body.participantCount, 2);

  const stored = alive('zync:group:v1:' + roomId + ':participants').value.get(p1);
  assert.equal(stored, 'A|' + p1Hash + '|OpaquePayload_AAA111');
  assert.equal(stored.includes(p1Token), false);

  r = await invoke({
    action: 'join',
    ...base,
    joinToken,
    participantId: p1,
    participantToken: p1Token,
    payload: 'OpaquePayload_AAA111',
  });
  assert.equal(r.status, 200);
  assert.equal(r.body.status, 'already_joined');

  r = await invoke({
    action: 'join',
    ...base,
    joinToken,
    participantId: p1,
    participantToken: p2Token,
    payload: 'OpaquePayload_AAA111',
  });
  assert.equal(r.status, 409);
  assert.equal(r.body.error, 'group_participant_conflict');
});

test('host snapshot never exposes participant auth hashes', async () => {
  await invoke({
    action: 'join',
    ...base,
    joinToken,
    participantId: p2,
    participantToken: p2Token,
    payload: 'OpaquePayload_BBB222',
  });

  let r = await invoke({
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
  const serialized = JSON.stringify(r.body.participants);
  assert.equal(serialized.includes(p1Hash), false);
  assert.equal(serialized.includes(p2Hash), false);
});

test('another participant cannot remove someone from lobby', async () => {
  let r = await invoke({
    action: 'leave',
    ...base,
    joinToken,
    participantId: p1,
    participantToken: p2Token,
  });
  assert.equal(r.status, 403);
  assert.equal(r.body.error, 'group_participant_not_authorized');

  r = await invoke({
    action: 'leave',
    ...base,
    joinToken,
    participantId: p2,
    participantToken: p2Token,
  });
  assert.equal(r.status, 200);

  r = await invoke({
    action: 'join',
    ...base,
    joinToken,
    participantId: p2,
    participantToken: p2Token,
    payload: 'OpaquePayload_BBB222',
  });
  assert.equal(r.status, 200);
});

test('host lock is private and rejects late joins', async () => {
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

  r = await invoke({
    action: 'join',
    ...base,
    joinToken,
    participantId: p3,
    participantToken: p3Token,
    payload: 'OpaquePayload_CCC333',
  });
  assert.equal(r.status, 409);
  assert.equal(r.body.error, 'group_room_locked');

  r = await invoke({
    action: 'leave',
    ...base,
    joinToken,
    participantId: p1,
    participantToken: p1Token,
  });
  assert.equal(r.status, 409);
  assert.equal(r.body.error, 'group_room_locked');
});

test('private input cannot be impersonated by another participant', async () => {
  let r = await invoke({
    action: 'submit_input',
    ...base,
    joinToken,
    participantId: p1,
    participantToken: p2Token,
    roundNumber: 1,
    payload: 'PrivateInput_FORGED',
  });
  assert.equal(r.status, 403);
  assert.equal(r.body.error, 'group_participant_not_authorized');

  r = await invoke({
    action: 'submit_input',
    ...base,
    joinToken,
    participantId: p1,
    participantToken: p1Token,
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
    participantToken: p1Token,
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
    participantToken: p1Token,
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

test('bounded state is monotonic and join-capability readable', async () => {
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
});

test('shared relay accepts a two-person Zync Now room', async () => {
  const pairRoom = 'PAIRROOMABCDEFGHIJKLMNOPQ';
  const pairBase = { protocolVersion: 1, roomId: pairRoom };

  let r = await invoke({
    action: 'create',
    ...pairBase,
    hostToken,
    joinToken,
    expiresAt: expiry(),
    maxParticipants: 2,
  });
  assert.equal(r.status, 201);

  r = await invoke({
    action: 'join',
    ...pairBase,
    joinToken,
    participantId: p1,
    participantToken: p1Token,
    payload: 'PairOpaque_AAA',
  });
  assert.equal(r.status, 200);
  assert.equal(r.body.participantCount, 2);

  r = await invoke({
    action: 'join',
    ...pairBase,
    joinToken,
    participantId: p2,
    participantToken: p2Token,
    payload: 'PairOpaque_BBB',
  });
  assert.equal(r.status, 409);
  assert.equal(r.body.error, 'group_room_full');
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

  const joins = [
    [p1, p1Token, 'Capacity_AAA'],
    [p2, p2Token, 'Capacity_BBB'],
  ];
  for (const item of joins) {
    r = await invoke({
      action: 'join',
      ...capBase,
      joinToken,
      participantId: item[0],
      participantToken: item[1],
      payload: item[2],
    });
    assert.equal(r.status, 200);
  }

  r = await invoke({
    action: 'join',
    ...capBase,
    joinToken,
    participantId: p3,
    participantToken: p3Token,
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

test('source never logs group payloads or raw capabilities', async () => {
  assert.equal(/console\.(log|error|warn)/.test(source), false);
  assert.equal(source.includes('UPSTASH_REDIS_REST_TOKEN'), true);
  assert.equal(source.includes("createHash('sha256'"), true);
  assert.equal(source.includes("createHmac('sha256'"), true);
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
console.log('\n' + cases.length + ' Group Zync relay contract tests passed.');

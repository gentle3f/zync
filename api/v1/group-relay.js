import { createHash, createHmac } from 'node:crypto';

const PROTOCOL_VERSION = 1;
const MAX_ROOM_SECONDS = 1800;
const MIN_ROOM_SECONDS = 30;
const MAX_PARTICIPANTS = 8;
const MIN_PARTICIPANTS = 2;
const MAX_OPAQUE_CHARS = 48 * 1024;
const CREATE_LIMIT_PER_MINUTE = 20;
const JOIN_LIMIT_PER_MINUTE = 90;
const STATE_LIMIT_PER_MINUTE = 180;

const ID_RE = /^[A-Za-z0-9_-]{22,64}$/;
const CAP_RE = /^[A-Za-z0-9_-]{22,64}$/;
const OPAQUE_RE = /^[A-Za-z0-9_-]+$/;
const HASH_RE = /^[a-f0-9]{64}$/;

function json(res, status, body) {
  res.setHeader('Cache-Control', 'no-store');
  return res.status(status).json(body);
}

function firstEnv(...names) {
  for (const name of names) {
    const value = (process.env[name] || '').trim();
    if (value) return value;
  }
  return '';
}

function configuration() {
  const url = firstEnv(
    'UPSTASH_REDIS_REST_URL',
    'KV_REST_API_URL',
  ).replace(/\/$/, '');
  const token = firstEnv(
    'UPSTASH_REDIS_REST_TOKEN',
    'KV_REST_API_TOKEN',
  );
  const rateSecret =
    (process.env.ZYNC_RELAY_RATE_LIMIT_SECRET || '').trim();
  if (
    !url.startsWith('https://') ||
    !token ||
    rateSecret.length < 24
  ) {
    return null;
  }
  return { url, token, rateSecret };
}

function clientIp(req) {
  const forwarded = req.headers?.['x-forwarded-for'];
  if (typeof forwarded === 'string' && forwarded.trim()) {
    return forwarded
      .split(',')[0]
      .trim()
      .slice(0, 128);
  }
  const real = req.headers?.['x-real-ip'];
  if (typeof real === 'string' && real.trim()) {
    return real.trim().slice(0, 128);
  }
  return 'unknown';
}

function hashCapability(value) {
  return createHash('sha256').update(value).digest('hex');
}

function rateKey(kind, ip, secret) {
  const digest = createHmac('sha256', secret)
    .update(ip)
    .digest('hex')
    .slice(0, 32);
  return 'zync:group:rl:' + kind + ':' + digest;
}

async function redis(config, command) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 4500);
  try {
    const response = await fetch(config.url, {
      method: 'POST',
      headers: {
        Authorization: 'Bearer ' + config.token,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(command),
      signal: controller.signal,
    });
    const data = await response.json().catch(() => ({}));
    if (!response.ok || data.error) {
      throw new Error('group_relay_store_unavailable');
    }
    return data.result;
  } finally {
    clearTimeout(timer);
  }
}

async function enforceRateLimit(
  config,
  req,
  kind,
  limit,
) {
  const key = rateKey(
    kind,
    clientIp(req),
    config.rateSecret,
  );
  const script =
    "local n=redis.call('INCR',KEYS[1]); " +
    "if n==1 then redis.call('EXPIRE',KEYS[1],60) end; " +
    'return n';
  const count = Number(
    await redis(config, [
      'EVAL',
      script,
      1,
      key,
    ]),
  );
  return Number.isFinite(count) && count <= limit;
}

function metaKey(roomId) {
  return 'zync:group:v1:' + roomId + ':meta';
}

function participantsKey(roomId) {
  return 'zync:group:v1:' + roomId + ':participants';
}

function stateKey(roomId) {
  return 'zync:group:v1:' + roomId + ':state';
}

function inputKey(roomId, roundNumber) {
  return (
    'zync:group:v1:' +
    roomId +
    ':input:' +
    roundNumber
  );
}

function validId(value) {
  return (
    typeof value === 'string' &&
    ID_RE.test(value)
  );
}

function validCapability(value) {
  return (
    typeof value === 'string' &&
    CAP_RE.test(value)
  );
}

function validOpaque(value) {
  return (
    typeof value === 'string' &&
    value.length > 0 &&
    value.length <= MAX_OPAQUE_CHARS &&
    OPAQUE_RE.test(value)
  );
}

function validBase(body) {
  return (
    body.protocolVersion === PROTOCOL_VERSION &&
    validId(body.roomId)
  );
}

function ttlFor(expiresAt) {
  const parsed = Date.parse(expiresAt);
  if (!Number.isFinite(parsed)) return null;
  const seconds = Math.ceil(
    (parsed - Date.now()) / 1000,
  );
  if (
    seconds < MIN_ROOM_SECONDS ||
    seconds > MAX_ROOM_SECONDS
  ) {
    return null;
  }
  return seconds;
}

function encodeMeta(
  hostHash,
  joinHash,
  maxParticipants,
  phase,
) {
  return (
    'M|' +
    hostHash +
    '|' +
    joinHash +
    '|' +
    maxParticipants +
    '|' +
    phase
  );
}

function parseMeta(value) {
  if (typeof value !== 'string') return null;
  const parts = value.split('|');
  if (
    parts.length !== 5 ||
    parts[0] !== 'M' ||
    !HASH_RE.test(parts[1]) ||
    !HASH_RE.test(parts[2])
  ) {
    return null;
  }

  const maxParticipants = Number(parts[3]);
  const phase = parts[4];
  if (
    !Number.isInteger(maxParticipants) ||
    maxParticipants < MIN_PARTICIPANTS ||
    maxParticipants > MAX_PARTICIPANTS ||
    !['L', 'S'].includes(phase)
  ) {
    return null;
  }

  return {
    hostHash: parts[1],
    joinHash: parts[2],
    maxParticipants,
    phase,
  };
}

function parseParticipantRecord(value) {
  if (typeof value !== 'string') return null;
  const match =
    /^A\|([a-f0-9]{64})\|([A-Za-z0-9_-]+)$/
      .exec(value);
  if (!match) return null;
  return {
    participantHash: match[1],
    payload: match[2],
  };
}

async function loadMeta(config, roomId) {
  const value = await redis(
    config,
    ['GET', metaKey(roomId)],
  );
  if (value == null) return null;
  return parseMeta(value);
}

async function createRoom(
  req,
  res,
  config,
  body,
) {
  if (
    !validBase(body) ||
    !validCapability(body.hostToken) ||
    !validCapability(body.joinToken)
  ) {
    return json(
      res,
      400,
      { error: 'group_room_invalid' },
    );
  }

  const maxParticipants =
    Number(body.maxParticipants);
  if (
    !Number.isInteger(maxParticipants) ||
    maxParticipants < MIN_PARTICIPANTS ||
    maxParticipants > MAX_PARTICIPANTS
  ) {
    return json(
      res,
      400,
      { error: 'group_capacity_invalid' },
    );
  }

  const ttl = ttlFor(body.expiresAt);
  if (ttl == null) {
    return json(
      res,
      400,
      { error: 'group_expiry_invalid' },
    );
  }

  if (
    !(await enforceRateLimit(
      config,
      req,
      'create',
      CREATE_LIMIT_PER_MINUTE,
    ))
  ) {
    return json(
      res,
      429,
      { error: 'group_rate_limited' },
    );
  }

  const value = encodeMeta(
    hashCapability(body.hostToken),
    hashCapability(body.joinToken),
    maxParticipants,
    'L',
  );

  const result = await redis(config, [
    'SET',
    metaKey(body.roomId),
    value,
    'EX',
    ttl,
    'NX',
  ]);

  if (result === 'OK') {
    return json(res, 201, {
      ok: true,
      status: 'created',
      expiresInSeconds: ttl,
    });
  }

  const existing = await redis(
    config,
    ['GET', metaKey(body.roomId)],
  );
  if (existing === value) {
    return json(res, 200, {
      ok: true,
      status: 'already_created',
      expiresInSeconds: ttl,
    });
  }

  return json(
    res,
    409,
    { error: 'group_room_exists' },
  );
}

async function joinRoom(
  req,
  res,
  config,
  body,
) {
  if (
    !validBase(body) ||
    !validCapability(body.joinToken) ||
    !validId(body.participantId) ||
    !validCapability(body.participantToken) ||
    !validOpaque(body.payload)
  ) {
    return json(
      res,
      400,
      { error: 'group_join_invalid' },
    );
  }

  if (
    !(await enforceRateLimit(
      config,
      req,
      'join',
      JOIN_LIMIT_PER_MINUTE,
    ))
  ) {
    return json(
      res,
      429,
      { error: 'group_rate_limited' },
    );
  }

  const script = [
    '-- group_join',
    "local meta=redis.call('GET',KEYS[1])",
    "if not meta then return 'missing' end",
    "local host,join,max,phase=string.match(meta,'^M|([0-9a-f]+)|([0-9a-f]+)|([2-8])|([LS])$')",
    "if not join then return 'invalid' end",
    "if join~=ARGV[1] then return 'forbidden' end",
    "if phase~='L' then return 'locked' end",
    "local existing=redis.call('HGET',KEYS[2],ARGV[2])",
    'if existing then',
    "  local auth,payload=string.match(existing,'^A|([0-9a-f]+)|([A-Za-z0-9_-]+)$')",
    "  if not auth then return 'invalid' end",
    "  if auth==ARGV[3] and payload==ARGV[4] then return 'same' end",
    "  return 'duplicate'",
    'end',
    'local guestLimit=tonumber(max)-1',
    "if redis.call('HLEN',KEYS[2])>=guestLimit then return 'full' end",
    "redis.call('HSET',KEYS[2],ARGV[2],'A|'..ARGV[3]..'|'..ARGV[4])",
    "local ttl=redis.call('TTL',KEYS[1])",
    "if ttl<=0 then return 'missing' end",
    "redis.call('EXPIRE',KEYS[2],ttl)",
    "return 'joined'",
  ].join('\n');

  const result = await redis(config, [
    'EVAL',
    script,
    2,
    metaKey(body.roomId),
    participantsKey(body.roomId),
    hashCapability(body.joinToken),
    body.participantId,
    hashCapability(body.participantToken),
    body.payload,
  ]);

  if (
    result === 'joined' ||
    result === 'same'
  ) {
    const guestCount = Number(
      await redis(config, [
        'HLEN',
        participantsKey(body.roomId),
      ]),
    );
    return json(res, 200, {
      ok: true,
      status:
        result === 'same'
          ? 'already_joined'
          : 'joined',
      participantCount: guestCount + 1,
    });
  }

  if (result === 'full') {
    return json(
      res,
      409,
      { error: 'group_room_full' },
    );
  }
  if (result === 'locked') {
    return json(
      res,
      409,
      { error: 'group_room_locked' },
    );
  }
  if (result === 'duplicate') {
    return json(
      res,
      409,
      { error: 'group_participant_conflict' },
    );
  }
  if (result === 'forbidden') {
    return json(
      res,
      403,
      { error: 'group_join_not_authorized' },
    );
  }
  if (result === 'invalid') {
    return json(
      res,
      502,
      { error: 'group_room_state_invalid' },
    );
  }

  return json(
    res,
    410,
    { error: 'group_room_expired' },
  );
}

async function leaveRoom(
  res,
  config,
  body,
) {
  if (
    !validBase(body) ||
    !validCapability(body.joinToken) ||
    !validId(body.participantId) ||
    !validCapability(body.participantToken)
  ) {
    return json(
      res,
      400,
      { error: 'group_leave_invalid' },
    );
  }

  const script = [
    '-- group_leave',
    "local meta=redis.call('GET',KEYS[1])",
    "if not meta then return 'missing' end",
    "local host,join,max,phase=string.match(meta,'^M|([0-9a-f]+)|([0-9a-f]+)|([2-8])|([LS])$')",
    "if not join then return 'invalid' end",
    "if join~=ARGV[1] then return 'forbidden_room' end",
    "if phase~='L' then return 'locked' end",
    "local member=redis.call('HGET',KEYS[2],ARGV[2])",
    "if not member then return 'missing_member' end",
    "local auth=string.match(member,'^A|([0-9a-f]+)|[A-Za-z0-9_-]+$')",
    "if not auth then return 'invalid' end",
    "if auth~=ARGV[3] then return 'forbidden_participant' end",
    "redis.call('HDEL',KEYS[2],ARGV[2])",
    "return 'left'",
  ].join('\n');

  const result = await redis(config, [
    'EVAL',
    script,
    2,
    metaKey(body.roomId),
    participantsKey(body.roomId),
    hashCapability(body.joinToken),
    body.participantId,
    hashCapability(body.participantToken),
  ]);

  if (
    result === 'left' ||
    result === 'missing_member'
  ) {
    return json(res, 200, { ok: true });
  }
  if (result === 'locked') {
    return json(
      res,
      409,
      { error: 'group_room_locked' },
    );
  }
  if (result === 'forbidden_room') {
    return json(
      res,
      403,
      { error: 'group_join_not_authorized' },
    );
  }
  if (result === 'forbidden_participant') {
    return json(
      res,
      403,
      { error: 'group_participant_not_authorized' },
    );
  }
  if (result === 'invalid') {
    return json(
      res,
      502,
      { error: 'group_room_state_invalid' },
    );
  }

  return json(
    res,
    410,
    { error: 'group_room_expired' },
  );
}

async function takeParticipants(
  res,
  config,
  body,
) {
  if (
    !validBase(body) ||
    !validCapability(body.hostToken)
  ) {
    return json(
      res,
      400,
      { error: 'group_host_request_invalid' },
    );
  }

  const meta = await loadMeta(
    config,
    body.roomId,
  );
  if (meta == null) {
    return json(
      res,
      410,
      { error: 'group_room_expired' },
    );
  }
  if (
    meta.hostHash !==
    hashCapability(body.hostToken)
  ) {
    return json(
      res,
      403,
      { error: 'group_host_not_authorized' },
    );
  }

  const raw =
    (await redis(config, [
      'HGETALL',
      participantsKey(body.roomId),
    ])) || [];

  const participants = [];
  for (
    let i = 0;
    i + 1 < raw.length;
    i += 2
  ) {
    const stored =
      parseParticipantRecord(raw[i + 1]);
    if (!stored) {
      return json(
        res,
        502,
        { error: 'group_room_state_invalid' },
      );
    }
    participants.push({
      participantId: raw[i],
      payload: stored.payload,
    });
  }

  return json(res, 200, {
    status: 'ready',
    participantCount:
      participants.length + 1,
    maxParticipants: meta.maxParticipants,
    locked: meta.phase === 'S',
    participants,
  });
}

async function lockRoom(
  res,
  config,
  body,
) {
  if (
    !validBase(body) ||
    !validCapability(body.hostToken)
  ) {
    return json(
      res,
      400,
      { error: 'group_host_request_invalid' },
    );
  }

  const script = [
    '-- group_lock',
    "local meta=redis.call('GET',KEYS[1])",
    "if not meta then return 'missing' end",
    "local host,join,max,phase=string.match(meta,'^M|([0-9a-f]+)|([0-9a-f]+)|([2-8])|([LS])$')",
    "if not host then return 'invalid' end",
    "if host~=ARGV[1] then return 'forbidden' end",
    "if phase=='S' then return 'same' end",
    "redis.call('SET',KEYS[1],'M|'..host..'|'..join..'|'..max..'|S','KEEPTTL','XX')",
    "return 'locked'",
  ].join('\n');

  const result = await redis(config, [
    'EVAL',
    script,
    1,
    metaKey(body.roomId),
    hashCapability(body.hostToken),
  ]);

  if (
    result === 'locked' ||
    result === 'same'
  ) {
    return json(res, 200, {
      ok: true,
      status:
        result === 'same'
          ? 'already_locked'
          : 'locked',
    });
  }
  if (result === 'forbidden') {
    return json(
      res,
      403,
      { error: 'group_host_not_authorized' },
    );
  }
  if (result === 'invalid') {
    return json(
      res,
      502,
      { error: 'group_room_state_invalid' },
    );
  }

  return json(
    res,
    410,
    { error: 'group_room_expired' },
  );
}

async function submitInput(
  req,
  res,
  config,
  body,
) {
  if (
    !validBase(body) ||
    !validCapability(body.joinToken) ||
    !validId(body.participantId) ||
    !validCapability(body.participantToken) ||
    !Number.isInteger(body.roundNumber) ||
    body.roundNumber < 1 ||
    body.roundNumber > 99 ||
    !validOpaque(body.payload)
  ) {
    return json(
      res,
      400,
      { error: 'group_input_invalid' },
    );
  }

  if (
    !(await enforceRateLimit(
      config,
      req,
      'input',
      JOIN_LIMIT_PER_MINUTE,
    ))
  ) {
    return json(
      res,
      429,
      { error: 'group_rate_limited' },
    );
  }

  const script = [
    '-- group_input',
    "local meta=redis.call('GET',KEYS[1])",
    "if not meta then return 'missing' end",
    "local host,join,max,phase=string.match(meta,'^M|([0-9a-f]+)|([0-9a-f]+)|([2-8])|([LS])$')",
    "if not join then return 'invalid' end",
    "if join~=ARGV[1] then return 'forbidden_room' end",
    "if phase~='S' then return 'not_started' end",
    "local member=redis.call('HGET',KEYS[2],ARGV[2])",
    "if not member then return 'unknown' end",
    "local auth=string.match(member,'^A|([0-9a-f]+)|[A-Za-z0-9_-]+$')",
    "if not auth then return 'invalid' end",
    "if auth~=ARGV[3] then return 'forbidden_participant' end",
    "local existing=redis.call('HGET',KEYS[3],ARGV[2])",
    'if existing then',
    "  if existing==ARGV[4] then return 'same' end",
    "  return 'duplicate'",
    'end',
    "redis.call('HSET',KEYS[3],ARGV[2],ARGV[4])",
    "local ttl=redis.call('TTL',KEYS[1])",
    "if ttl<=0 then return 'missing' end",
    "redis.call('EXPIRE',KEYS[3],ttl)",
    "return 'accepted'",
  ].join('\n');

  const result = await redis(config, [
    'EVAL',
    script,
    3,
    metaKey(body.roomId),
    participantsKey(body.roomId),
    inputKey(
      body.roomId,
      body.roundNumber,
    ),
    hashCapability(body.joinToken),
    body.participantId,
    hashCapability(body.participantToken),
    body.payload,
  ]);

  if (
    result === 'accepted' ||
    result === 'same'
  ) {
    return json(res, 200, {
      ok: true,
      status:
        result === 'same'
          ? 'already_received'
          : 'received',
    });
  }
  if (result === 'duplicate') {
    return json(
      res,
      409,
      { error: 'group_input_already_received' },
    );
  }
  if (result === 'not_started') {
    return json(
      res,
      409,
      { error: 'group_round_not_started' },
    );
  }
  if (result === 'unknown') {
    return json(
      res,
      403,
      { error: 'group_participant_unknown' },
    );
  }
  if (result === 'forbidden_participant') {
    return json(
      res,
      403,
      { error: 'group_participant_not_authorized' },
    );
  }
  if (result === 'forbidden_room') {
    return json(
      res,
      403,
      { error: 'group_join_not_authorized' },
    );
  }
  if (result === 'invalid') {
    return json(
      res,
      502,
      { error: 'group_room_state_invalid' },
    );
  }

  return json(
    res,
    410,
    { error: 'group_room_expired' },
  );
}

async function takeInputs(
  res,
  config,
  body,
) {
  if (
    !validBase(body) ||
    !validCapability(body.hostToken) ||
    !Number.isInteger(body.roundNumber) ||
    body.roundNumber < 1 ||
    body.roundNumber > 99
  ) {
    return json(
      res,
      400,
      { error: 'group_host_request_invalid' },
    );
  }

  const meta = await loadMeta(
    config,
    body.roomId,
  );
  if (meta == null) {
    return json(
      res,
      410,
      { error: 'group_room_expired' },
    );
  }
  if (
    meta.hostHash !==
    hashCapability(body.hostToken)
  ) {
    return json(
      res,
      403,
      { error: 'group_host_not_authorized' },
    );
  }

  const raw =
    (await redis(config, [
      'HGETALL',
      inputKey(
        body.roomId,
        body.roundNumber,
      ),
    ])) || [];

  const inputs = [];
  for (
    let i = 0;
    i + 1 < raw.length;
    i += 2
  ) {
    inputs.push({
      participantId: raw[i],
      payload: raw[i + 1],
    });
  }

  return json(res, 200, {
    status: 'ready',
    inputs,
  });
}

async function publishState(
  req,
  res,
  config,
  body,
) {
  if (
    !validBase(body) ||
    !validCapability(body.hostToken) ||
    !Number.isInteger(body.revision) ||
    body.revision < 0 ||
    body.revision > 9999 ||
    !validOpaque(body.payload)
  ) {
    return json(
      res,
      400,
      { error: 'group_state_invalid' },
    );
  }

  if (
    !(await enforceRateLimit(
      config,
      req,
      'state',
      STATE_LIMIT_PER_MINUTE,
    ))
  ) {
    return json(
      res,
      429,
      { error: 'group_rate_limited' },
    );
  }

  const script = [
    '-- group_publish_state',
    "local meta=redis.call('GET',KEYS[1])",
    "if not meta then return 'missing' end",
    "local host=string.match(meta,'^M|([0-9a-f]+)|')",
    "if not host then return 'invalid' end",
    "if host~=ARGV[1] then return 'forbidden' end",
    "local current=redis.call('GET',KEYS[2])",
    'if current then',
    "  local rev,payload=string.match(current,'^S|([0-9]+)|([A-Za-z0-9_-]+)$')",
    "  if not rev then return 'invalid' end",
    '  rev=tonumber(rev)',
    '  local nextRev=tonumber(ARGV[2])',
    "  if rev>nextRev then return 'stale' end",
    '  if rev==nextRev then',
    "    if payload==ARGV[3] then return 'same' end",
    "    return 'conflict'",
    '  end',
    'end',
    "local ttl=redis.call('TTL',KEYS[1])",
    "if ttl<=0 then return 'missing' end",
    "redis.call('SET',KEYS[2],'S|'..ARGV[2]..'|'..ARGV[3],'EX',ttl)",
    "return 'published'",
  ].join('\n');

  const result = await redis(config, [
    'EVAL',
    script,
    2,
    metaKey(body.roomId),
    stateKey(body.roomId),
    hashCapability(body.hostToken),
    String(body.revision),
    body.payload,
  ]);

  if (
    result === 'published' ||
    result === 'same'
  ) {
    return json(res, 200, {
      ok: true,
      status:
        result === 'same'
          ? 'already_published'
          : 'published',
    });
  }
  if (
    result === 'stale' ||
    result === 'conflict'
  ) {
    return json(
      res,
      409,
      { error: 'group_state_conflict' },
    );
  }
  if (result === 'forbidden') {
    return json(
      res,
      403,
      { error: 'group_host_not_authorized' },
    );
  }
  if (result === 'invalid') {
    return json(
      res,
      502,
      { error: 'group_room_state_invalid' },
    );
  }

  return json(
    res,
    410,
    { error: 'group_room_expired' },
  );
}

async function pollState(
  res,
  config,
  body,
) {
  if (
    !validBase(body) ||
    !validCapability(body.joinToken) ||
    !Number.isInteger(body.sinceRevision) ||
    body.sinceRevision < -1 ||
    body.sinceRevision > 9999
  ) {
    return json(
      res,
      400,
      { error: 'group_poll_invalid' },
    );
  }

  const meta = await loadMeta(
    config,
    body.roomId,
  );
  if (meta == null) {
    return json(
      res,
      410,
      { error: 'group_room_expired' },
    );
  }
  if (
    meta.joinHash !==
    hashCapability(body.joinToken)
  ) {
    return json(
      res,
      403,
      { error: 'group_join_not_authorized' },
    );
  }

  const guestCount = Number(
    await redis(config, [
      'HLEN',
      participantsKey(body.roomId),
    ]),
  );

  const stored = await redis(
    config,
    ['GET', stateKey(body.roomId)],
  );

  if (stored == null) {
    return json(res, 200, {
      status: 'waiting',
      revision: -1,
      participantCount: guestCount + 1,
      maxParticipants: meta.maxParticipants,
      locked: meta.phase === 'S',
    });
  }

  const match =
    /^S\|([0-9]+)\|([A-Za-z0-9_-]+)$/
      .exec(stored);
  if (!match) {
    return json(
      res,
      502,
      { error: 'group_room_state_invalid' },
    );
  }

  const revision = Number(match[1]);
  if (revision <= body.sinceRevision) {
    return json(res, 200, {
      status: 'waiting',
      revision,
      participantCount: guestCount + 1,
      maxParticipants: meta.maxParticipants,
      locked: meta.phase === 'S',
    });
  }

  return json(res, 200, {
    status: 'ready',
    revision,
    payload: match[2],
    participantCount: guestCount + 1,
    maxParticipants: meta.maxParticipants,
    locked: meta.phase === 'S',
  });
}

async function closeRoom(
  res,
  config,
  body,
) {
  if (
    !validBase(body) ||
    !validCapability(body.hostToken)
  ) {
    return json(
      res,
      400,
      { error: 'group_host_request_invalid' },
    );
  }

  const meta = await loadMeta(
    config,
    body.roomId,
  );
  if (meta == null) {
    return json(res, 200, { ok: true });
  }
  if (
    meta.hostHash !==
    hashCapability(body.hostToken)
  ) {
    return json(
      res,
      403,
      { error: 'group_host_not_authorized' },
    );
  }

  const keys = [
    metaKey(body.roomId),
    participantsKey(body.roomId),
    stateKey(body.roomId),
  ];
  for (
    let round = 1;
    round <= 99;
    round += 1
  ) {
    keys.push(
      inputKey(body.roomId, round),
    );
  }

  await redis(
    config,
    ['DEL', ...keys],
  );
  return json(res, 200, { ok: true });
}

export default async function handler(
  req,
  res,
) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return json(
      res,
      405,
      { error: 'method_not_allowed' },
    );
  }

  const config = configuration();
  if (!config) {
    return json(
      res,
      503,
      { error: 'group_relay_not_configured' },
    );
  }

  const body =
    req.body &&
    typeof req.body === 'object' &&
    !Array.isArray(req.body)
      ? req.body
      : {};

  try {
    switch (body.action) {
      case 'create':
        return await createRoom(
          req,
          res,
          config,
          body,
        );
      case 'join':
        return await joinRoom(
          req,
          res,
          config,
          body,
        );
      case 'leave':
        return await leaveRoom(
          res,
          config,
          body,
        );
      case 'take_participants':
        return await takeParticipants(
          res,
          config,
          body,
        );
      case 'lock':
        return await lockRoom(
          res,
          config,
          body,
        );
      case 'submit_input':
        return await submitInput(
          req,
          res,
          config,
          body,
        );
      case 'take_inputs':
        return await takeInputs(
          res,
          config,
          body,
        );
      case 'publish_state':
        return await publishState(
          req,
          res,
          config,
          body,
        );
      case 'poll_state':
        return await pollState(
          res,
          config,
          body,
        );
      case 'close':
        return await closeRoom(
          res,
          config,
          body,
        );
      default:
        return json(
          res,
          400,
          { error: 'group_action_invalid' },
        );
    }
  } catch (_) {
    return json(
      res,
      503,
      { error: 'group_relay_temporarily_unavailable' },
    );
  }
}

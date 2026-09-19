import { createHash, createHmac } from 'node:crypto';

import {
  createRelayCompletionTicket,
  createRelayResponderCapability,
  relayProofTicketsEnabled,
  relayResponderCapabilityHash,
} from '../_cardverse/proof_ticket.js';

const PROTOCOL_VERSION = 2;
const MAX_SESSION_SECONDS = 300;
const MIN_SESSION_SECONDS = 15;
const MAX_RESPONSE_CHARS = 24 * 1024;
const CREATE_LIMIT_PER_MINUTE = 30;
const RESPONSE_LIMIT_PER_MINUTE = 90;
const SESSION_RE = /^[A-Za-z0-9_-]{22,64}$/;
const HOST_TOKEN_RE = /^[A-Za-z0-9_-]{32,64}$/;
const OPAQUE_RE = /^[A-Za-z0-9_-]+$/;
const HASH_RE = /^[a-f0-9]{64}$/;
const PENDING_PREFIX = 'P|';
const RESPONSE_PREFIX = 'R|';
const RESPONSE_V2_PREFIX = 'R2|';
const COMPLETED_V2_PREFIX = 'C2|';
const PROOF_CAPABILITY_RE = /^[A-Za-z0-9_-]{43}$/;

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
  const url = firstEnv('UPSTASH_REDIS_REST_URL', 'KV_REST_API_URL').replace(/\/$/, '');
  const token = firstEnv('UPSTASH_REDIS_REST_TOKEN', 'KV_REST_API_TOKEN');
  const rateSecret = (process.env.ZYNC_RELAY_RATE_LIMIT_SECRET || '').trim();
  if (!url.startsWith('https://') || !token || rateSecret.length < 24) return null;
  return { url, token, rateSecret };
}

function clientIp(req) {
  const forwarded = req.headers?.['x-forwarded-for'];
  if (typeof forwarded === 'string' && forwarded.trim()) return forwarded.split(',')[0].trim().slice(0, 128);
  const real = req.headers?.['x-real-ip'];
  if (typeof real === 'string' && real.trim()) return real.trim().slice(0, 128);
  return 'unknown';
}

function rateKey(prefix, ip, secret) {
  const digest = createHmac('sha256', secret).update(ip).digest('hex').slice(0, 32);
  return `zync:relay:rl:${prefix}:${digest}`;
}

function hostAuthHash(hostToken) {
  return createHash('sha256').update(hostToken).digest('hex');
}

async function redis(config, command) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 4500);
  try {
    const response = await fetch(config.url, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${config.token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(command),
      signal: controller.signal,
    });
    const data = await response.json().catch(() => ({}));
    if (!response.ok || data.error) throw new Error('relay_store_unavailable');
    return data.result;
  } finally {
    clearTimeout(timer);
  }
}

async function enforceRateLimit(config, req, kind, limit) {
  const key = rateKey(kind, clientIp(req), config.rateSecret);
  const script = "local n=redis.call('INCR',KEYS[1]); if n==1 then redis.call('EXPIRE',KEYS[1],60) end; return n";
  const count = Number(await redis(config, ['EVAL', script, 1, key]));
  return Number.isFinite(count) && count <= limit;
}

function validSessionId(value) {
  return typeof value === 'string' && SESSION_RE.test(value);
}

function validHostToken(value) {
  return typeof value === 'string' && HOST_TOKEN_RE.test(value);
}

function validHostRequest(body) {
  return body.protocolVersion === PROTOCOL_VERSION && validSessionId(body.sessionId) && validHostToken(body.hostToken);
}

function sessionKey(sessionId) {
  return `zync:relay:v2:${sessionId}`;
}

function ttlFor(expiresAt) {
  const parsed = Date.parse(expiresAt);
  if (!Number.isFinite(parsed)) return null;
  const seconds = Math.ceil((parsed - Date.now()) / 1000);
  if (seconds < MIN_SESSION_SECONDS || seconds > MAX_SESSION_SECONDS) return null;
  return seconds;
}

function parseStored(value) {
  if (typeof value !== 'string') return null;
  if (value.startsWith(PENDING_PREFIX)) {
    const authHash = value.slice(PENDING_PREFIX.length);
    if (!HASH_RE.test(authHash)) return null;
    return { status: 'waiting', authHash, payload: null };
  }
  if (value.startsWith(RESPONSE_V2_PREFIX)) {
    const parts = value.split('|');
    if (parts.length !== 4) return null;
    const [, authHash, capabilityHash, payload] = parts;
    if (!HASH_RE.test(authHash) ||
        !HASH_RE.test(capabilityHash) ||
        !payload ||
        payload.length > MAX_RESPONSE_CHARS ||
        !OPAQUE_RE.test(payload)) return null;
    return { status: 'ready', authHash, capabilityHash, payload, proofVersion: 2 };
  }
  if (value.startsWith(COMPLETED_V2_PREFIX)) {
    const parts = value.split('|');
    if (parts.length !== 4) return null;
    const [, authHash, capabilityHash, completedAtRaw] = parts;
    const completedAtMs = Number(completedAtRaw);
    if (!HASH_RE.test(authHash) ||
        !HASH_RE.test(capabilityHash) ||
        !Number.isInteger(completedAtMs) ||
        completedAtMs < 1) return null;
    return {
      status: 'completed',
      authHash,
      capabilityHash,
      payload: null,
      proofVersion: 2,
      completedAtMs,
    };
  }
  if (value.startsWith(RESPONSE_PREFIX)) {
    const separator = value.indexOf('|', RESPONSE_PREFIX.length);
    if (separator < 0) return null;
    const authHash = value.slice(RESPONSE_PREFIX.length, separator);
    const payload = value.slice(separator + 1);
    if (!HASH_RE.test(authHash) || !payload || payload.length > MAX_RESPONSE_CHARS || !OPAQUE_RE.test(payload)) return null;
    return { status: 'ready', authHash, payload, proofVersion: 1 };
  }
  return null;
}

async function createSession(req, res, config, body) {
  if (!validHostRequest(body)) {
    return json(res, 400, { error: 'relay_session_invalid' });
  }
  const ttl = ttlFor(body.expiresAt);
  if (ttl == null) return json(res, 400, { error: 'relay_expiry_invalid' });
  if (!(await enforceRateLimit(config, req, 'create', CREATE_LIMIT_PER_MINUTE))) {
    return json(res, 429, { error: 'relay_rate_limited' });
  }

  const key = sessionKey(body.sessionId);
  const pending = `${PENDING_PREFIX}${hostAuthHash(body.hostToken)}`;
  const result = await redis(config, ['SET', key, pending, 'EX', ttl, 'NX']);
  if (result === 'OK') return json(res, 201, { ok: true, status: 'created', expiresInSeconds: ttl });

  // A create request can succeed upstream while the phone times out locally. Treat a
  // retry as idempotent only when both the random session ID and private host capability match.
  const existing = await redis(config, ['GET', key]);
  if (existing === pending) return json(res, 200, { ok: true, status: 'already_created', expiresInSeconds: ttl });
  return json(res, 409, { error: 'relay_session_exists' });
}

async function respond(req, res, config, body) {
  if (body.protocolVersion !== PROTOCOL_VERSION || !validSessionId(body.sessionId)) {
    return json(res, 400, { error: 'relay_session_invalid' });
  }
  const payload = typeof body.payload === 'string' ? body.payload.trim() : '';
  if (!payload || payload.length > MAX_RESPONSE_CHARS || !OPAQUE_RE.test(payload)) {
    return json(res, 413, { error: 'relay_payload_invalid' });
  }
  if (!(await enforceRateLimit(config, req, 'respond', RESPONSE_LIMIT_PER_MINUTE))) {
    return json(res, 429, { error: 'relay_rate_limited' });
  }

  const proofCapability = relayProofTicketsEnabled()
    ? createRelayResponderCapability(body.sessionId, payload)
    : null;
  const capabilityHash = proofCapability
    ? relayResponderCapabilityHash(proofCapability)
    : '';

  const script = [
    "local current=redis.call('GET',KEYS[1])",
    "if not current then return 'missing' end",
    "if string.sub(current,1,2)=='P|' then",
    "  local auth=string.sub(current,3)",
    "  if string.len(auth)~=64 then return 'invalid' end",
    "  local ttl=redis.call('TTL',KEYS[1])",
    "  if ttl<=0 then return 'missing' end",
    "  if ARGV[2]~='' then",
    "    redis.call('SET',KEYS[1],'R2|'..auth..'|'..ARGV[2]..'|'..ARGV[1],'EX',ttl,'XX')",
    "  else",
    "    redis.call('SET',KEYS[1],'R|'..auth..'|'..ARGV[1],'EX',ttl,'XX')",
    "  end",
    "  return 'accepted'",
    "end",
    "if string.sub(current,1,3)=='R2|' then",
    "  local a,b,p=string.match(current,'^R2|([^|]+)|([^|]+)|(.+)$')",
    "  if not a or not b or not p then return 'invalid' end",
    "  if p==ARGV[1] and b==ARGV[2] then return 'same' end",
    "  return 'duplicate'",
    "end",
    "if string.sub(current,1,2)=='R|' then",
    "  if string.len(current)<68 or string.sub(current,67,67)~='|' then return 'invalid' end",
    "  if string.sub(current,68)==ARGV[1] then return 'same' end",
    "  return 'duplicate'",
    "end",
    "if string.sub(current,1,3)=='C2|' then return 'completed' end",
    "return 'invalid'",
  ].join('\n');
  const result = await redis(config, [
    'EVAL',
    script,
    1,
    sessionKey(body.sessionId),
    payload,
    capabilityHash,
  ]);
  if (result === 'accepted' || result === 'same') {
    return json(res, 200, {
      ok: true,
      status: result === 'same' ? 'already_received' : 'received',
      ...(proofCapability ? { proofCapability } : {}),
    });
  }
  if (result === 'completed') {
    return json(res, 409, { error: 'relay_already_consumed' });
  }
  if (result === 'duplicate') return json(res, 409, { error: 'relay_already_answered' });
  if (result === 'invalid') return json(res, 502, { error: 'relay_response_invalid' });
  return json(res, 410, { error: 'relay_session_expired' });
}

async function take(res, config, body) {
  if (!validHostRequest(body)) {
    return json(res, 400, { error: 'relay_session_invalid' });
  }
  const value = await redis(config, ['GET', sessionKey(body.sessionId)]);
  if (value == null) return json(res, 410, { error: 'relay_session_expired' });
  const stored = parseStored(value);
  if (stored == null) {
    await redis(config, ['DEL', sessionKey(body.sessionId)]);
    return json(res, 502, { error: 'relay_response_invalid' });
  }
  if (stored.authHash !== hostAuthHash(body.hostToken)) {
    return json(res, 403, { error: 'relay_host_not_authorized' });
  }
  if (stored.status === 'waiting') return json(res, 200, { status: 'waiting' });
  if (stored.status === 'completed') return json(res, 200, { status: 'completed' });

  // Deliberately non-destructive. If the HTTP response is lost, the host can poll again.
  // The host calls consume only after authenticated decryption succeeds; TTL is the fallback.
  return json(res, 200, { status: 'ready', payload: stored.payload });
}

async function consumeSession(res, config, body) {
  if (!validHostRequest(body)) {
    return json(res, 400, { error: 'relay_session_invalid' });
  }
  const expectedAuth = hostAuthHash(body.hostToken);
  const completedAtMs = Date.now();
  const script = [
    "local current=redis.call('GET',KEYS[1])",
    "if not current then return 'missing' end",
    "if string.sub(current,1,3)=='C2|' then",
    "  local auth,cap,completed=string.match(current,'^C2|([^|]+)|([^|]+)|([^|]+)$')",
    "  if not auth or not cap or not completed then return 'invalid' end",
    "  if auth~=ARGV[1] then return 'forbidden' end",
    "  return 'completed:'..completed",
    "end",
    "if string.sub(current,1,3)=='R2|' then",
    "  local auth,cap,payload=string.match(current,'^R2|([^|]+)|([^|]+)|(.+)$')",
    "  if not auth or not cap or not payload then return 'invalid' end",
    "  if auth~=ARGV[1] then return 'forbidden' end",
    "  local ttl=redis.call('TTL',KEYS[1])",
    "  if ttl<=0 then return 'missing' end",
    "  redis.call('SET',KEYS[1],'C2|'..auth..'|'..cap..'|'..ARGV[2],'EX',ttl,'XX')",
    "  return 'completed:'..ARGV[2]",
    "end",
    "if string.sub(current,1,2)=='R|' then",
    "  local auth=string.sub(current,3,66)",
    "  if string.len(auth)~=64 then return 'invalid' end",
    "  if auth~=ARGV[1] then return 'forbidden' end",
    "  redis.call('DEL',KEYS[1])",
    "  return 'deleted'",
    "end",
    "return 'invalid'",
  ].join('\n');

  const result = await redis(config, [
    'EVAL',
    script,
    1,
    sessionKey(body.sessionId),
    expectedAuth,
    String(completedAtMs),
  ]);
  if (result === 'deleted') return json(res, 200, { ok: true });
  if (typeof result === 'string' && result.startsWith('completed:')) {
    const storedCompletedAt = Number(result.slice('completed:'.length));
    if (!Number.isInteger(storedCompletedAt) || storedCompletedAt < 1) {
      return json(res, 502, { error: 'relay_response_invalid' });
    }
    const proofTicket = createRelayCompletionTicket({
      sessionId: body.sessionId,
      role: 'host',
      completedAtMs: storedCompletedAt,
    });
    return json(res, 200, { ok: true, proofTicket });
  }
  if (result === 'forbidden') return json(res, 403, { error: 'relay_host_not_authorized' });
  if (result === 'invalid') return json(res, 502, { error: 'relay_response_invalid' });
  return json(res, 410, { error: 'relay_session_expired' });
}

async function proofStatus(req, res, config, body) {
  if (body.protocolVersion !== PROTOCOL_VERSION ||
      !validSessionId(body.sessionId) ||
      !PROOF_CAPABILITY_RE.test(String(body.proofCapability || ''))) {
    return json(res, 400, { error: 'relay_proof_invalid' });
  }
  if (!relayProofTicketsEnabled()) {
    return json(res, 503, { error: 'relay_proof_not_configured' });
  }
  if (!(await enforceRateLimit(config, req, 'proof', RESPONSE_LIMIT_PER_MINUTE))) {
    return json(res, 429, { error: 'relay_rate_limited' });
  }

  const storedRaw = await redis(config, ['GET', sessionKey(body.sessionId)]);
  if (storedRaw == null) return json(res, 410, { error: 'relay_session_expired' });
  const stored = parseStored(storedRaw);
  if (stored == null || stored.proofVersion !== 2 || !stored.capabilityHash) {
    return json(res, 409, { error: 'relay_proof_unavailable' });
  }

  let providedHash;
  try {
    providedHash = relayResponderCapabilityHash(body.proofCapability);
  } catch (_) {
    return json(res, 400, { error: 'relay_proof_invalid' });
  }
  if (providedHash !== stored.capabilityHash) {
    return json(res, 403, { error: 'relay_proof_not_authorized' });
  }
  if (stored.status !== 'completed') {
    return json(res, 200, { status: 'waiting' });
  }

  const proofTicket = createRelayCompletionTicket({
    sessionId: body.sessionId,
    role: 'scanner',
    completedAtMs: stored.completedAtMs,
  });
  return json(res, 200, { status: 'ready', proofTicket });
}

async function cancelSession(res, config, body) {
  if (!validHostRequest(body)) {
    return json(res, 400, { error: 'relay_session_invalid' });
  }
  const expectedAuth = hostAuthHash(body.hostToken);
  const script = [
    "local current=redis.call('GET',KEYS[1])",
    "if not current then return 'missing' end",
    "local auth=nil",
    "if string.sub(current,1,2)=='P|' then auth=string.sub(current,3) end",
    "if string.sub(current,1,2)=='R|' then auth=string.sub(current,3,66) end",
    "if string.sub(current,1,3)=='R2|' then auth=string.sub(current,4,67) end",
    "if string.sub(current,1,3)=='C2|' then auth=string.sub(current,4,67) end",
    "if not auth or string.len(auth)~=64 then redis.call('DEL',KEYS[1]); return 'invalid' end",
    "if auth~=ARGV[1] then return 'forbidden' end",
    "redis.call('DEL',KEYS[1])",
    "return 'deleted'",
  ].join('\n');
  const result = await redis(config, ['EVAL', script, 1, sessionKey(body.sessionId), expectedAuth]);
  if (result === 'deleted' || result === 'missing') return json(res, 200, { ok: true });
  if (result === 'forbidden') return json(res, 403, { error: 'relay_host_not_authorized' });
  return json(res, 502, { error: 'relay_response_invalid' });
}

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return json(res, 405, { error: 'method_not_allowed' });
  }
  const config = configuration();
  if (!config) return json(res, 503, { error: 'relay_not_configured' });
  const body = req.body && typeof req.body === 'object' && !Array.isArray(req.body) ? req.body : {};

  try {
    switch (body.action) {
      case 'create': return await createSession(req, res, config, body);
      case 'respond': return await respond(req, res, config, body);
      case 'take': return await take(res, config, body);
      case 'consume': return await consumeSession(res, config, body);
      case 'proof': return await proofStatus(req, res, config, body);
      case 'cancel': return await cancelSession(res, config, body);
      default: return json(res, 400, { error: 'relay_action_invalid' });
    }
  } catch (_) {
    return json(res, 503, { error: 'relay_temporarily_unavailable' });
  }
}

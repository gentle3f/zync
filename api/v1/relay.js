import { createHmac } from 'node:crypto';

const PROTOCOL_VERSION = 2;
const MAX_SESSION_SECONDS = 300;
const MIN_SESSION_SECONDS = 15;
const MAX_RESPONSE_CHARS = 24 * 1024;
const CREATE_LIMIT_PER_MINUTE = 30;
const RESPONSE_LIMIT_PER_MINUTE = 90;
const SESSION_RE = /^[A-Za-z0-9_-]{22,64}$/;
const OPAQUE_RE = /^[A-Za-z0-9_-]+$/;

function json(res, status, body) {
  res.setHeader('Cache-Control', 'no-store');
  return res.status(status).json(body);
}

function configuration() {
  const url = (process.env.UPSTASH_REDIS_REST_URL || '').trim().replace(/\/$/, '');
  const token = (process.env.UPSTASH_REDIS_REST_TOKEN || '').trim();
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

async function createSession(req, res, config, body) {
  if (body.protocolVersion !== PROTOCOL_VERSION || !validSessionId(body.sessionId)) {
    return json(res, 400, { error: 'relay_session_invalid' });
  }
  const ttl = ttlFor(body.expiresAt);
  if (ttl == null) return json(res, 400, { error: 'relay_expiry_invalid' });
  if (!(await enforceRateLimit(config, req, 'create', CREATE_LIMIT_PER_MINUTE))) {
    return json(res, 429, { error: 'relay_rate_limited' });
  }

  const result = await redis(config, ['SET', sessionKey(body.sessionId), 'P', 'EX', ttl, 'NX']);
  if (result !== 'OK') return json(res, 409, { error: 'relay_session_exists' });
  return json(res, 201, { ok: true, expiresInSeconds: ttl });
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

  const value = `R:${payload}`;
  const script = [
    "local current=redis.call('GET',KEYS[1])",
    "if not current then return 'missing' end",
    "if current=='P' then",
    "  local ttl=redis.call('TTL',KEYS[1])",
    "  if ttl<=0 then return 'missing' end",
    "  redis.call('SET',KEYS[1],ARGV[1],'EX',ttl,'XX')",
    "  return 'accepted'",
    "end",
    "if current==ARGV[1] then return 'same' end",
    "return 'duplicate'",
  ].join('\n');
  const result = await redis(config, ['EVAL', script, 1, sessionKey(body.sessionId), value]);
  if (result === 'accepted' || result === 'same') {
    return json(res, 200, { ok: true, status: result === 'same' ? 'already_received' : 'received' });
  }
  if (result === 'duplicate') return json(res, 409, { error: 'relay_already_answered' });
  return json(res, 410, { error: 'relay_session_expired' });
}

async function take(res, config, body) {
  if (body.protocolVersion !== PROTOCOL_VERSION || !validSessionId(body.sessionId)) {
    return json(res, 400, { error: 'relay_session_invalid' });
  }
  const script = [
    "local current=redis.call('GET',KEYS[1])",
    "if not current then return 'missing' end",
    "if current=='P' then return 'waiting' end",
    "if string.sub(current,1,2)~='R:' then redis.call('DEL',KEYS[1]); return 'invalid' end",
    "redis.call('DEL',KEYS[1])",
    "return current",
  ].join('\n');
  const result = await redis(config, ['EVAL', script, 1, sessionKey(body.sessionId)]);
  if (result === 'waiting') return json(res, 200, { status: 'waiting' });
  if (result === 'missing') return json(res, 410, { error: 'relay_session_expired' });
  if (result === 'invalid' || typeof result !== 'string' || !result.startsWith('R:')) {
    return json(res, 502, { error: 'relay_response_invalid' });
  }
  const payload = result.slice(2);
  if (!payload || payload.length > MAX_RESPONSE_CHARS || !OPAQUE_RE.test(payload)) {
    return json(res, 502, { error: 'relay_response_invalid' });
  }
  return json(res, 200, { status: 'ready', payload });
}

async function cancel(res, config, body) {
  if (body.protocolVersion !== PROTOCOL_VERSION || !validSessionId(body.sessionId)) {
    return json(res, 400, { error: 'relay_session_invalid' });
  }
  await redis(config, ['DEL', sessionKey(body.sessionId)]);
  return json(res, 200, { ok: true });
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
      case 'cancel': return await cancel(res, config, body);
      default: return json(res, 400, { error: 'relay_action_invalid' });
    }
  } catch (_) {
    return json(res, 503, { error: 'relay_temporarily_unavailable' });
  }
}

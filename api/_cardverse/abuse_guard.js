import { createHmac } from 'node:crypto';

const WINDOW_SECONDS = 60;
const PROFILE_LIMITS = Object.freeze({
  auth_challenge_ip: { fallback: 20, env: 'CARDVERSE_RL_AUTH_CHALLENGE_PER_MINUTE', max: 300 },
  auth_provider_ip: { fallback: 10, env: 'CARDVERSE_RL_AUTH_PROVIDER_PER_MINUTE', max: 120 },
  proof_redeem_ip: { fallback: 120, env: 'CARDVERSE_RL_PROOF_REDEEM_IP_PER_MINUTE', max: 600 },
  proof_redeem_account: { fallback: 60, env: 'CARDVERSE_RL_PROOF_REDEEM_ACCOUNT_PER_MINUTE', max: 300 },
  quest_claim_ip: { fallback: 120, env: 'CARDVERSE_RL_QUEST_CLAIM_IP_PER_MINUTE', max: 600 },
  quest_claim_account: { fallback: 30, env: 'CARDVERSE_RL_QUEST_CLAIM_ACCOUNT_PER_MINUTE', max: 180 },
  pack_open_ip: { fallback: 120, env: 'CARDVERSE_RL_PACK_OPEN_IP_PER_MINUTE', max: 600 },
  pack_open_account: { fallback: 30, env: 'CARDVERSE_RL_PACK_OPEN_ACCOUNT_PER_MINUTE', max: 180 },
  account_lifecycle_ip: { fallback: 30, env: 'CARDVERSE_RL_ACCOUNT_LIFECYCLE_IP_PER_MINUTE', max: 120 },
  account_lifecycle_account: { fallback: 10, env: 'CARDVERSE_RL_ACCOUNT_LIFECYCLE_ACCOUNT_PER_MINUTE', max: 60 },
});

function domainError(code, details = {}) {
  const error = new Error(code);
  error.code = code;
  Object.assign(error, details);
  return error;
}

function firstEnv(...names) {
  for (const name of names) {
    const value = String(process.env[name] || '').trim();
    if (value) return value;
  }
  return '';
}

export function cardverseAbuseGuardConfigured() {
  const url = firstEnv('UPSTASH_REDIS_REST_URL', 'KV_REST_API_URL').replace(/\\/$/, '');
  const token = firstEnv('UPSTASH_REDIS_REST_TOKEN', 'KV_REST_API_TOKEN');
  const secret = String(process.env.ZYNC_CARDVERSE_RATE_LIMIT_SECRET || '').trim();
  return url.startsWith('https://') && Boolean(token) && secret.length >= 24;
}

function configFromEnv() {
  const url = firstEnv('UPSTASH_REDIS_REST_URL', 'KV_REST_API_URL').replace(/\/$/, '');
  const token = firstEnv('UPSTASH_REDIS_REST_TOKEN', 'KV_REST_API_TOKEN');
  const secret = String(process.env.ZYNC_CARDVERSE_RATE_LIMIT_SECRET || '').trim();
  if (!cardverseAbuseGuardConfigured()) {
    throw domainError('cardverse_abuse_guard_not_configured');
  }
  return { url, token, secret };
}

function positiveLimit(value, fallback, max) {
  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed < 1 || parsed > max) return fallback;
  return parsed;
}

function limitFor(profile) {
  const spec = PROFILE_LIMITS[profile];
  if (!spec) throw domainError('cardverse_rate_limit_profile_invalid');
  return positiveLimit(process.env[spec.env], spec.fallback, spec.max);
}

export function cardverseClientAddress(req) {
  const forwarded = req?.headers?.['x-forwarded-for'];
  if (typeof forwarded === 'string' && forwarded.trim()) {
    return forwarded.split(',')[0].trim().slice(0, 128) || 'unknown';
  }
  const real = req?.headers?.['x-real-ip'];
  if (typeof real === 'string' && real.trim()) return real.trim().slice(0, 128);
  return 'unknown';
}

export function cardverseRateKey(profile, principal, secret) {
  const cleanProfile = String(profile || '').trim();
  const cleanPrincipal = String(principal || '').trim();
  const cleanSecret = String(secret || '');
  if (!PROFILE_LIMITS[cleanProfile] || !cleanPrincipal || cleanSecret.length < 24) {
    throw domainError('cardverse_rate_limit_key_invalid');
  }
  const digest = createHmac('sha256', cleanSecret)
    .update(cleanProfile)
    .update('\0')
    .update(cleanPrincipal)
    .digest('hex')
    .slice(0, 40);
  return `zync:cardverse:rl:${cleanProfile}:${digest}`;
}

async function redisCommand(config, command) {
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
    if (!response.ok || data.error) {
      throw domainError('cardverse_abuse_guard_unavailable');
    }
    return data.result;
  } catch (error) {
    if (error?.code === 'cardverse_abuse_guard_unavailable') throw error;
    throw domainError('cardverse_abuse_guard_unavailable');
  } finally {
    clearTimeout(timer);
  }
}

async function takeFixedWindow(config, key, limit, options = {}) {
  const call = options.redisCommand || redisCommand;
  const script = [
    "local n=redis.call('INCR',KEYS[1])",
    "if n==1 then redis.call('EXPIRE',KEYS[1],ARGV[1]) end",
    "local ttl=redis.call('TTL',KEYS[1])",
    "return {n,ttl}",
  ].join('\n');
  let result;
  try {
    result = await call(config, ['EVAL', script, 1, key, String(WINDOW_SECONDS)]);
  } catch (error) {
    if (error?.code === 'cardverse_abuse_guard_unavailable') throw error;
    throw domainError('cardverse_abuse_guard_unavailable');
  }
  const count = Number(Array.isArray(result) ? result[0] : NaN);
  const ttl = Number(Array.isArray(result) ? result[1] : NaN);
  if (!Number.isFinite(count) || count < 1 || !Number.isFinite(ttl)) {
    throw domainError('cardverse_abuse_guard_unavailable');
  }
  if (count > limit) {
    throw domainError('cardverse_rate_limited', {
      retryAfterSeconds: Math.max(1, Math.min(WINDOW_SECONDS, Math.ceil(ttl > 0 ? ttl : WINDOW_SECONDS))),
    });
  }
  return { count, limit, retryAfterSeconds: Math.max(1, Math.ceil(ttl > 0 ? ttl : WINDOW_SECONDS)) };
}

export async function enforceCardverseIpRateLimit(req, profile, options = {}) {
  const config = options.config || configFromEnv();
  const principal = cardverseClientAddress(req);
  const key = cardverseRateKey(profile, principal, config.secret);
  return takeFixedWindow(config, key, limitFor(profile), options);
}

export async function enforceCardverseAccountRateLimit(accountId, profile, options = {}) {
  const config = options.config || configFromEnv();
  const principal = String(accountId || '').trim();
  if (!principal) throw domainError('cardverse_rate_limit_principal_invalid');
  const key = cardverseRateKey(profile, principal, config.secret);
  return takeFixedWindow(config, key, limitFor(profile), options);
}

export function applyCardverseAbuseHeaders(res, error) {
  if (error?.code === 'cardverse_rate_limited') {
    res.setHeader('Retry-After', String(error.retryAfterSeconds || WINDOW_SECONDS));
  }
}

export async function checkCardverseAbuseGuard(options = {}) {
  const config = options.config || configFromEnv();
  const call = options.redisCommand || redisCommand;
  let result;
  try {
    result = await call(config, ['PING']);
  } catch (error) {
    if (error?.code === 'cardverse_abuse_guard_unavailable') throw error;
    throw domainError('cardverse_abuse_guard_unavailable');
  }
  if (result !== 'PONG') throw domainError('cardverse_abuse_guard_unavailable');
  return { reachable: true };
}

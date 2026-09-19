import { createHmac } from 'node:crypto';

const VERSION = 1;
const MAX_IMPRESSIONS = 100;
const MAX_SELECTIONS = 50;
const WRITE_LIMIT_PER_MINUTE = 20;
const READ_LIMIT_PER_MINUTE = 90;
const RETENTION_SECONDS = 120 * 24 * 60 * 60;
const ID_RE = /^[a-z0-9][a-z0-9._-]{1,95}$/;
const REGIONS = new Set([
  'global', 'hk', 'tw', 'mo', 'cn', 'sg', 'jp', 'kr',
  'us', 'gb', 'au', 'ca', 'fr', 'es', 'pt', 'br', 'de', 'in',
]);

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
  if (typeof forwarded === 'string' && forwarded.trim()) {
    return forwarded.split(',')[0].trim().slice(0, 128);
  }
  const real = req.headers?.['x-real-ip'];
  if (typeof real === 'string' && real.trim()) return real.trim().slice(0, 128);
  return 'unknown';
}

function rateKey(kind, ip, secret) {
  const digest = createHmac('sha256', secret).update(ip).digest('hex').slice(0, 32);
  return 'zync:interest:rl:v1:' + kind + ':' + digest;
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
    if (!response.ok || data.error) throw new Error('interest_store_unavailable');
    return data.result;
  } finally {
    clearTimeout(timer);
  }
}

async function pipeline(config, commands) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 4500);
  try {
    const response = await fetch(config.url + '/pipeline', {
      method: 'POST',
      headers: {
        Authorization: 'Bearer ' + config.token,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(commands),
      signal: controller.signal,
    });
    const data = await response.json().catch(() => null);
    if (!response.ok || !Array.isArray(data) || data.some((entry) => entry?.error)) {
      throw new Error('interest_store_unavailable');
    }
    return data;
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

function canonicalRegion(raw) {
  const value = typeof raw === 'string' ? raw.trim().toLowerCase() : '';
  return REGIONS.has(value) ? value : null;
}

function canonicalIds(raw, max) {
  if (!Array.isArray(raw) || raw.length > max) return null;
  const set = new Set();
  for (const value of raw) {
    if (typeof value !== 'string') return null;
    const id = value.trim();
    if (!ID_RE.test(id) || id.startsWith('custom.')) return null;
    set.add(id);
  }
  return [...set];
}

function mondayKey(offsetWeeks = 0, now = Date.now()) {
  const source = new Date(now);
  const day = new Date(Date.UTC(
    source.getUTCFullYear(),
    source.getUTCMonth(),
    source.getUTCDate(),
  ));
  const mondayOffset = (day.getUTCDay() + 6) % 7;
  day.setUTCDate(day.getUTCDate() - mondayOffset - (offsetWeeks * 7));
  return day.toISOString().slice(0, 10);
}

function signalKey(week, region) {
  return 'zync:interest:v1:' + week + ':' + region;
}

function parseHash(raw) {
  const fields = raw && !Array.isArray(raw) && typeof raw === 'object'
    ? Object.entries(raw).flat()
    : Array.isArray(raw) ? raw : [];
  const output = {};
  for (let i = 0; i + 1 < fields.length; i += 2) {
    const field = String(fields[i]);
    const value = Number(fields[i + 1]);
    if (!Number.isFinite(value) || value < 0) continue;
    const separator = field.indexOf(':');
    if (separator < 2) continue;
    const kind = field.slice(0, separator);
    const id = field.slice(separator + 1);
    if ((kind !== 'i' && kind !== 's') || !ID_RE.test(id) || id.startsWith('custom.')) continue;
    const row = output[id] ??= { impressions: 0, selections: 0 };
    if (kind === 'i') row.impressions = Math.round(value);
    if (kind === 's') row.selections = Math.round(value);
  }
  return output;
}

function noStore(res, status, body) {
  res.setHeader('Cache-Control', 'no-store');
  return res.status(status).json(body);
}

async function handleRead(req, res, config) {
  const region = canonicalRegion(req.query?.region);
  if (!region) return noStore(res, 400, { error: 'interest_region_invalid' });
  if (!(await enforceRateLimit(config, req, 'read', READ_LIMIT_PER_MINUTE))) {
    return noStore(res, 429, { error: 'interest_rate_limited' });
  }

  const previousWeek = mondayKey(1);
  const olderWeek = mondayKey(2);
  const [previousRaw, olderRaw] = await Promise.all([
    redis(config, ['HGETALL', signalKey(previousWeek, region)]),
    redis(config, ['HGETALL', signalKey(olderWeek, region)]),
  ]);

  res.setHeader('Cache-Control', 'public, max-age=3600, stale-while-revalidate=86400');
  return res.status(200).json({
    version: VERSION,
    region,
    previousWeek,
    olderWeek,
    previous: parseHash(previousRaw),
    older: parseHash(olderRaw),
  });
}

async function handleWrite(req, res, config) {
  const body = req.body && typeof req.body === 'object' ? req.body : {};
  if (body.version !== VERSION) return noStore(res, 400, { error: 'interest_version_invalid' });

  const region = canonicalRegion(body.region);
  const impressions = canonicalIds(body.impressions, MAX_IMPRESSIONS);
  const selections = canonicalIds(body.selections, MAX_SELECTIONS);
  if (!region || impressions == null || selections == null || impressions.length === 0) {
    return noStore(res, 400, { error: 'interest_signal_invalid' });
  }

  const impressionSet = new Set(impressions);
  if (selections.some((id) => !impressionSet.has(id))) {
    return noStore(res, 400, { error: 'interest_selection_without_impression' });
  }

  if (!(await enforceRateLimit(config, req, 'write', WRITE_LIMIT_PER_MINUTE))) {
    return noStore(res, 429, { error: 'interest_rate_limited' });
  }

  const week = mondayKey(0);
  const key = signalKey(week, region);
  const commands = [];
  for (const id of impressions) commands.push(['HINCRBY', key, 'i:' + id, 1]);
  for (const id of selections) commands.push(['HINCRBY', key, 's:' + id, 1]);
  commands.push(['EXPIRE', key, RETENTION_SECONDS]);
  await pipeline(config, commands);

  return noStore(res, 202, {
    ok: true,
    week,
    impressions: impressions.length,
    selections: selections.length,
  });
}

export default async function handler(req, res) {
  const config = configuration();
  if (!config) return noStore(res, 503, { error: 'interest_learning_not_configured' });

  try {
    if (req.method === 'GET') return await handleRead(req, res, config);
    if (req.method === 'POST') return await handleWrite(req, res, config);
    res.setHeader('Allow', 'GET, POST');
    return noStore(res, 405, { error: 'method_not_allowed' });
  } catch (_) {
    return noStore(res, 503, { error: 'interest_learning_unavailable' });
  }
}

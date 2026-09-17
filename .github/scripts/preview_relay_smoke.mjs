import assert from 'node:assert/strict';
import { randomBytes } from 'node:crypto';

const rawBase = (process.env.ZYNC_PREVIEW_BASE || '').trim();
assert.ok(rawBase.startsWith('https://'), 'ZYNC_PREVIEW_BASE must be https');
const base = rawBase.replace(/\/$/, '');
const protocolVersion = 2;
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const sessionId = () => randomBytes(18).toString('base64url');
const hostToken = () => randomBytes(24).toString('base64url');

async function relay(body) {
  const response = await fetch(`${base}/api/v1/relay`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(20000),
  });
  const json = await response.json().catch(() => ({}));
  assert.equal(response.headers.get('cache-control'), 'no-store');
  return { response, json };
}

const sid = sessionId();
const token = hostToken();
const wrongToken = hostToken();
const peer = { protocolVersion, sessionId: sid };
const host = { ...peer, hostToken: token };
const expiresAt = new Date(Date.now() + 120000).toISOString();
const opaque = randomBytes(48).toString('base64url');
const otherOpaque = randomBytes(48).toString('base64url');

let r = await relay({ action: 'create', ...host, expiresAt });
assert.equal(r.response.status, 201, `create failed: ${r.response.status} ${JSON.stringify(r.json)}`);
assert.equal(r.json.status, 'created');
console.log('✓ create uses live preview relay');

r = await relay({ action: 'create', ...host, expiresAt });
assert.equal(r.response.status, 200);
assert.equal(r.json.status, 'already_created');
console.log('✓ create retry is idempotent');

r = await relay({ action: 'take', ...peer, hostToken: wrongToken });
assert.equal(r.response.status, 403);
assert.deepEqual(r.json, { error: 'relay_host_not_authorized' });
console.log('✓ wrong host token cannot poll');

r = await relay({ action: 'take', ...host });
assert.equal(r.response.status, 200);
assert.equal(r.json.status, 'waiting');

r = await relay({ action: 'respond', ...peer, payload: opaque });
assert.equal(r.response.status, 200);
assert.equal(r.json.status, 'received');
console.log('✓ scanner response stored');

r = await relay({ action: 'respond', ...peer, payload: opaque });
assert.equal(r.response.status, 200);
assert.equal(r.json.status, 'already_received');

r = await relay({ action: 'respond', ...peer, payload: otherOpaque });
assert.equal(r.response.status, 409);
assert.deepEqual(r.json, { error: 'relay_already_answered' });
console.log('✓ duplicate scanner protection works');

r = await relay({ action: 'take', ...host });
assert.equal(r.response.status, 200);
assert.equal(r.json.status, 'ready');
assert.equal(r.json.payload, opaque);

r = await relay({ action: 'take', ...host });
assert.equal(r.response.status, 200);
assert.equal(r.json.payload, opaque);
console.log('✓ host polling is non-destructive');

r = await relay({ action: 'consume', ...peer, hostToken: wrongToken });
assert.equal(r.response.status, 403);

r = await relay({ action: 'consume', ...host });
assert.equal(r.response.status, 200);
assert.deepEqual(r.json, { ok: true });

r = await relay({ action: 'take', ...host });
assert.equal(r.response.status, 410);
assert.deepEqual(r.json, { error: 'relay_session_expired' });
console.log('✓ consume deletes the live session');

const ttlSid = sessionId();
const ttlToken = hostToken();
const ttlHost = { protocolVersion, sessionId: ttlSid, hostToken: ttlToken };
r = await relay({ action: 'create', ...ttlHost, expiresAt: new Date(Date.now() + 15000).toISOString() });
assert.equal(r.response.status, 201, `ttl create failed: ${r.response.status} ${JSON.stringify(r.json)}`);
await sleep(16500);
r = await relay({ action: 'take', ...ttlHost });
assert.equal(r.response.status, 410);
assert.deepEqual(r.json, { error: 'relay_session_expired' });
console.log('✓ Redis TTL removes abandoned sessions without a cleanup schedule');

console.log('\nPreview relay smoke passed.');

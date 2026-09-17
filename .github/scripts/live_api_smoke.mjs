import assert from 'node:assert/strict';
import { randomBytes } from 'node:crypto';

const rawBase = (process.env.ZYNC_API_BASE || '').trim();
assert.ok(rawBase.startsWith('https://'), 'ZYNC_API_BASE must be a production https:// origin');
const base = rawBase.replace(/\/$/, '');

const rawPrivacyUrl = (process.env.ZYNC_PRIVACY_URL || '').trim();
assert.ok(rawPrivacyUrl.startsWith('https://'), 'ZYNC_PRIVACY_URL must be a public https:// URL');

const timeoutMs = 20000;
const protocolVersion = 2;
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
const sessionId = () => randomBytes(18).toString('base64url');
const hostToken = () => randomBytes(24).toString('base64url');

async function post(path, body) {
  const response = await fetch(`${base}${path}`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(timeoutMs),
  });
  const json = await response.json().catch(() => ({}));
  return { response, json };
}

function assertAiPrivacyHeaders(response, route) {
  assert.equal(
    response.headers.get('x-zync-api-version'),
    'v1',
    `${route} is not serving the expected Zync V1 handler`,
  );
  assert.equal(
    response.headers.get('x-zync-ai-privacy'),
    'zdr-data-collection-deny',
    `${route} is not serving the required ZDR/data-collection-deny handler`,
  );
}

async function relay(body) {
  const result = await post('/api/v1/relay', body);
  assert.equal(result.response.headers.get('cache-control'), 'no-store');
  return result;
}

{
  const response = await fetch(rawPrivacyUrl, {
    method: 'GET',
    redirect: 'follow',
    signal: AbortSignal.timeout(timeoutMs),
  });
  assert.ok(response.ok, `privacy policy live smoke failed with HTTP ${response.status}`);
  assert.ok(response.url.startsWith('https://'), 'privacy policy must remain on HTTPS after redirects');
  const contentType = (response.headers.get('content-type') || '').toLowerCase();
  assert.ok(!contentType.includes('application/pdf'), 'Google Play privacy policy must not be a PDF');
  assert.ok(
    contentType.includes('text/html') || contentType.includes('text/plain'),
    `privacy policy should be a browser-readable page, got content-type ${contentType || '(missing)'}`,
  );
  const privacyText = await response.text();
  assert.match(privacyText, /Upstash Redis/i);
  assert.match(privacyText, /AES-GCM/i);
  assert.match(privacyText, /about three minutes/i);
  console.log('✓ public privacy policy URL is reachable and discloses the encrypted relay');
}

{
  const sid = sessionId();
  const token = hostToken();
  const wrongToken = hostToken();
  const peerRelay = { protocolVersion, sessionId: sid };
  const hostRelay = { ...peerRelay, hostToken: token };
  const expiresAt = new Date(Date.now() + 120000).toISOString();
  const opaque = randomBytes(48).toString('base64url');
  const otherOpaque = randomBytes(48).toString('base64url');

  let r = await relay({ action: 'create', ...hostRelay, expiresAt });
  assert.equal(r.response.status, 201, `relay create failed: HTTP ${r.response.status} ${JSON.stringify(r.json)}`);
  assert.equal(r.json.status, 'created');

  r = await relay({ action: 'create', ...hostRelay, expiresAt });
  assert.equal(r.response.status, 200, 'relay create retry should be idempotent while pending');
  assert.equal(r.json.status, 'already_created');

  r = await relay({ action: 'take', ...peerRelay, hostToken: wrongToken });
  assert.equal(r.response.status, 403, 'a scanner or observer without the private host token must not poll');
  assert.deepEqual(r.json, { error: 'relay_host_not_authorized' });

  r = await relay({ action: 'take', ...hostRelay });
  assert.equal(r.response.status, 200);
  assert.equal(r.json.status, 'waiting');

  r = await relay({ action: 'respond', ...peerRelay, payload: opaque });
  assert.equal(r.response.status, 200);
  assert.equal(r.json.status, 'received');

  r = await relay({ action: 'respond', ...peerRelay, payload: opaque });
  assert.equal(r.response.status, 200);
  assert.equal(r.json.status, 'already_received');

  r = await relay({ action: 'respond', ...peerRelay, payload: otherOpaque });
  assert.equal(r.response.status, 409, 'a different second scanner response must be rejected');
  assert.deepEqual(r.json, { error: 'relay_already_answered' });

  r = await relay({ action: 'take', ...peerRelay, hostToken: wrongToken });
  assert.equal(r.response.status, 403, 'wrong host token must not read the encrypted scanner response');

  r = await relay({ action: 'take', ...hostRelay });
  assert.equal(r.response.status, 200);
  assert.equal(r.json.status, 'ready');
  assert.equal(r.json.payload, opaque);

  r = await relay({ action: 'take', ...hostRelay });
  assert.equal(r.response.status, 200, 'host retry must remain possible after a lost poll response');
  assert.equal(r.json.payload, opaque);

  r = await relay({ action: 'consume', ...peerRelay, hostToken: wrongToken });
  assert.equal(r.response.status, 403, 'wrong host token must not consume another host session');

  r = await relay({ action: 'consume', ...hostRelay });
  assert.equal(r.response.status, 200);
  assert.deepEqual(r.json, { ok: true });

  r = await relay({ action: 'take', ...hostRelay });
  assert.equal(r.response.status, 410);
  assert.deepEqual(r.json, { error: 'relay_session_expired' });

  console.log('✓ live encrypted relay enforces host-only polling/consume and idempotent scanner response');
}

{
  const sid = sessionId();
  const token = hostToken();
  const hostRelay = { protocolVersion, sessionId: sid, hostToken: token };
  const expiresAt = new Date(Date.now() + 15000).toISOString();
  let r = await relay({ action: 'create', ...hostRelay, expiresAt });
  assert.equal(r.response.status, 201, 'short-lived TTL smoke session should be created');
  await sleep(16500);
  r = await relay({ action: 'take', ...hostRelay });
  assert.equal(r.response.status, 410, 'abandoned relay session must disappear by TTL without scheduled cleanup');
  console.log('✓ live relay TTL removes abandoned sessions without a cleanup schedule');
}

{
  const { response, json } = await post('/api/v1/normalize-interest', {
    input: 'urban sketching',
    language: 'en',
  });
  assertAiPrivacyHeaders(response, '/api/v1/normalize-interest');
  assert.ok(response.ok, `normalize-interest live smoke failed with HTTP ${response.status}`);
  assert.equal(typeof json.id, 'string');
  assert.ok(json.id.startsWith('custom.'));
  assert.equal(typeof json.canonicalName, 'string');
  assert.ok(json.canonicalName.trim());
  assert.equal(typeof json.displayName, 'string');
  assert.ok(json.displayName.trim());
  console.log('✓ live normalize-interest works on the expected privacy-hardened V1 handler');
}

{
  const { response, json } = await post('/api/v1/question', {
    language: 'en',
    mode: 'easy',
    shared: ['Badminton'],
    sessionSeed: sessionId(),
  });
  assertAiPrivacyHeaders(response, '/api/v1/question');
  assert.ok(response.ok, `question live smoke failed with HTTP ${response.status}`);
  assert.equal(typeof json.question, 'string');
  assert.ok(json.question.trim());
  console.log('✓ live question generation works on the expected privacy-hardened V1 handler');
}

{
  const { response, json } = await post('/api/v1/analytics', {
    event: 'app_open',
    installId: '11111111-1111-1111-1111-111111111111',
    sessionId: '22222222-2222-2222-2222-222222222222',
    properties: { locale: 'en', profile_ready: true },
  });

  if (response.status === 503) {
    assert.deepEqual(json, { error: 'analytics_not_configured' });
    console.log('✓ live analytics endpoint exists; provider is intentionally/not-yet configured');
  } else {
    assert.ok(response.ok, `analytics live smoke failed with HTTP ${response.status}`);
    assert.deepEqual(json, { ok: true });
    console.log('✓ live analytics endpoint is configured and accepts the allowlisted smoke event');
  }
}

console.log('\nProduction Zync V1 release smoke passed.');

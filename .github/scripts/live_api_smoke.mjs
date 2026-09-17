import assert from 'node:assert/strict';

const rawBase = (process.env.ZYNC_API_BASE || '').trim();
assert.ok(rawBase.startsWith('https://'), 'ZYNC_API_BASE must be a production https:// origin');
const base = rawBase.replace(/\/$/, '');

const rawPrivacyUrl = (process.env.ZYNC_PRIVACY_URL || '').trim();
assert.ok(rawPrivacyUrl.startsWith('https://'), 'ZYNC_PRIVACY_URL must be a public https:// URL');

const timeoutMs = 20000;

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
  console.log('✓ public privacy policy URL is reachable over HTTPS and browser-readable');
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

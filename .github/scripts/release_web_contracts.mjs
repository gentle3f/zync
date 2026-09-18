import assert from 'node:assert/strict';
import fs from 'node:fs';

const read = (path) => fs.readFileSync(path, 'utf8');

const landing = read('index.html');
const privacy = read('privacy.html');
const terms = read('terms.html');
const disclaimer = read('disclaimer.html');
const vercel = JSON.parse(read('vercel.json'));
const analytics = read('mobile/lib/core/analytics_service.dart');
const interestLearning = read('api/v1/interest-popularity.js');
const question = read('api/v1/question.js');
const relay = read('api/v1/relay.js');
const relayClient = read('mobile/lib/core/relay_service.dart');
const signedRelease = read('.github/workflows/zync-v1-signed-release.yml');

for (const [name, html] of [
  ['landing', landing],
  ['privacy', privacy],
  ['terms', terms],
  ['disclaimer', disclaimer],
]) {
  assert.match(html, /<!doctype html>/i, `${name} page must be plain browser-readable HTML`);
  assert.match(html, /<meta name="viewport"/i, `${name} page must be mobile readable`);
  assert.ok(!/RELEASE_BLOCKER|\[[A-Z][A-Z _-]{4,}\]|__ZYNC_/i.test(html), `${name} page contains a release placeholder`);
}

assert.match(landing, /<title>Zync — Discover what connects you<\/title>/i);
assert.match(landing, /Discover what <span>connects<\/span> you\./i);
assert.match(landing, /No account required/i);
assert.match(landing, /QR matching/i);
assert.match(landing, /hidden connections/i);
assert.match(landing, /Zero match isn't a dead end/i);
assert.ok(!/AI can normalize unfamiliar|custom-interest normalization/i.test(landing));
assert.match(landing, /Zync Again/i);
assert.match(landing, /Interest DNA/i);
assert.match(landing, /eight interface languages/i);
assert.match(landing, /Analytics off for the public V1 release/i);
assert.match(landing, /href="\/privacy"/i);
assert.match(landing, /href="\/terms"/i);
assert.match(landing, /href="\/disclaimer"/i);
assert.ok(!/download now|available now|join the community|nearby people|create an account/i.test(landing), 'landing page contains a claim outside the frozen V1 scope');

assert.match(privacy, /<title>Zync Privacy Policy<\/title>/i);
assert.match(privacy, /com\.gmail\.gentle3f\.myproject/);
assert.match(privacy, /Vercel/);
assert.match(privacy, /Upstash Redis/i);
assert.match(privacy, /OpenRouter/);
assert.match(privacy, /AES-GCM/i);
assert.match(privacy, /one-time 256-bit secret/i);
assert.match(privacy, /about three minutes/i);
assert.match(privacy, /opaque encrypted response/i);
assert.match(privacy, /does not receive the one-time decryption secret/i);
assert.match(privacy, /Zero Data Retention/i);
assert.match(privacy, /Product analytics are disabled by default/i);
assert.match(privacy, /regional interest discovery/i);
assert.match(privacy, /does not use GPS or precise location/i);
assert.match(privacy, /canonical interest identifiers/i);
assert.match(privacy, /about fifteen minutes/i);
assert.match(privacy, /same semantic question/i);
assert.match(privacy, /play\.google\.com\/store\/apps\/details\?id=com\.gmail\.gentle3f\.myproject/);
assert.match(privacy, /Retention and deletion/i);
assert.match(privacy, /Security/i);
assert.ok(
  !/QR body is not uploaded to Zync's backend as part of scanning or matching/i.test(privacy),
  'privacy policy has regressed to the obsolete direct-transfer-only statement',
);

assert.match(terms, /<title>Zync Terms of Use<\/title>/i);
assert.match(terms, /AI-assisted features/i);
assert.match(terms, /short-lived encrypted relay/i);
assert.match(terms, /Privacy Policy/i);

assert.match(disclaimer, /<title>Zync Disclaimer<\/title>/i);
assert.match(disclaimer, /AI-generated content/i);
assert.match(disclaimer, /Interest matches/i);

const rewrites = Array.isArray(vercel.rewrites) ? vercel.rewrites : [];
const routeMap = new Map(rewrites.map((entry) => [entry.source, entry.destination]));
assert.equal(routeMap.get('/privacy'), '/privacy.html');
assert.equal(routeMap.get('/terms'), '/terms.html');
assert.equal(routeMap.get('/disclaimer'), '/disclaimer.html');

assert.match(analytics, /ZYNC_ANALYTICS_ENABLED/);
assert.match(analytics, /defaultValue:\s*false/);
assert.match(analytics, /if \(!enabled\) return;/);

assert.match(question, /zync:question:v1:/);
assert.match(question, /QUESTION_CACHE_SECONDS\s*=\s*15\s*\*\s*60/);
assert.match(question, /createHash\('sha256'\)/);

assert.match(interestLearning, /zync:interest:v1:/);
assert.match(interestLearning, /zync:interest:rl:v1:/);
assert.match(interestLearning, /HINCRBY/);
assert.ok(!/install.?id|account.?id|nickname/i.test(interestLearning));
assert.ok(!/console\.(log|error|warn)/.test(interestLearning));

assert.match(relay, /UPSTASH_REDIS_REST_URL/);
assert.match(relay, /UPSTASH_REDIS_REST_TOKEN/);
assert.match(relay, /ZYNC_RELAY_RATE_LIMIT_SECRET/);
assert.match(relay, /'EX', ttl, 'NX'/);
assert.match(relay, /case 'consume'/);
assert.match(relay, /Cache-Control', 'no-store'/);
assert.ok(!/console\.(log|error|warn)/.test(relay), 'relay must not log opaque pairing payloads or secrets');
assert.match(relayClient, /AesGcm\.with256bits\(\)/);
assert.match(relayClient, /Random\.secure\(\)/);
assert.match(relayClient, /Future<void> consume/);

assert.match(signedRelease, /Smoke production API and privacy policy/);
assert.match(signedRelease, /live_api_smoke\.mjs/);
assert.match(signedRelease, /ZYNC_PRIVACY_URL/);
assert.match(signedRelease, /--dart-define=ZYNC_ANALYTICS_ENABLED=false/);
assert.match(signedRelease, /--dart-define=ZYNC_INTEREST_LEARNING_ENABLED=true/);
assert.match(signedRelease, /jarsigner -verify -strict/);

console.log('✓ Zync landing page matches the frozen local-first V1 product scope');
console.log('✓ public legal pages disclose the short-lived encrypted relay and remain browser-readable');
console.log('✓ relay source keeps TTL, server-only configuration, no payload logging and on-device AES-GCM');
console.log('✓ stable /privacy, /terms and /disclaimer routes are configured');
console.log('✓ public V1 product analytics stay off while regional interest learning is aggregate-only');
console.log('✓ signed release keeps live smoke, privacy URL, analytics-off and strict signature verification');

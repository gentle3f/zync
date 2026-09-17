import assert from 'node:assert/strict';
import fs from 'node:fs';

const read = (path) => fs.readFileSync(path, 'utf8');

const privacy = read('privacy.html');
const terms = read('terms.html');
const disclaimer = read('disclaimer.html');
const vercel = JSON.parse(read('vercel.json'));
const analytics = read('mobile/lib/core/analytics_service.dart');
const signedRelease = read('.github/workflows/zync-v1-signed-release.yml');

for (const [name, html] of [
  ['privacy', privacy],
  ['terms', terms],
  ['disclaimer', disclaimer],
]) {
  assert.match(html, /<!doctype html>/i, `${name} page must be plain browser-readable HTML`);
  assert.match(html, /<meta name="viewport"/i, `${name} page must be mobile readable`);
  assert.ok(!/RELEASE_BLOCKER|\[[A-Z][A-Z _-]{4,}\]|__ZYNC_/i.test(html), `${name} page contains a release placeholder`);
}

assert.match(privacy, /<title>Zync Privacy Policy<\/title>/i);
assert.match(privacy, /com\.gmail\.gentle3f\.myproject/);
assert.match(privacy, /Vercel/);
assert.match(privacy, /OpenRouter/);
assert.match(privacy, /Zero Data Retention/i);
assert.match(privacy, /Product analytics are disabled by default/i);
assert.match(privacy, /play\.google\.com\/store\/apps\/details\?id=com\.gmail\.gentle3f\.myproject/);
assert.match(privacy, /Retention and deletion/i);
assert.match(privacy, /Security/i);

assert.match(terms, /<title>Zync Terms of Use<\/title>/i);
assert.match(terms, /AI-assisted features/i);
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

assert.match(signedRelease, /Smoke production API and privacy policy/);
assert.match(signedRelease, /live_api_smoke\.mjs/);
assert.match(signedRelease, /ZYNC_PRIVACY_URL/);
assert.match(signedRelease, /--dart-define=ZYNC_ANALYTICS_ENABLED=false/);
assert.match(signedRelease, /jarsigner -verify -strict/);

console.log('✓ public legal pages are browser-readable and release-complete');
console.log('✓ stable /privacy, /terms and /disclaimer routes are configured');
console.log('✓ public V1 analytics posture is explicitly default-off');
console.log('✓ signed release keeps live smoke, privacy URL, analytics-off and strict signature verification');

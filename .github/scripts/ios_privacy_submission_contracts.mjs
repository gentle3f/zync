import assert from 'node:assert/strict';
import fs from 'node:fs';

const spec = JSON.parse(fs.readFileSync('mobile/app_store_privacy_details.json', 'utf8'));
const privacy = fs.readFileSync('privacy.html', 'utf8');
const terms = fs.readFileSync('terms.html', 'utf8');
const landing = fs.readFileSync('index.html', 'utf8');
const compile = fs.readFileSync('.github/workflows/zync-ios-compile-smoke.yml', 'utf8');
const signed = fs.readFileSync('.github/workflows/zync-ios-signed-archive.yml', 'utf8');
const branding = fs.readFileSync('mobile/tool/apply_ios_branding.py', 'utf8');
const manifest = fs.readFileSync('mobile/tool/apply_ios_privacy_manifest.py', 'utf8');
const deps = fs.readFileSync('mobile/tool/audit_ios_privacy_dependencies.py', 'utf8');
const audit = fs.readFileSync('mobile/tool/audit_ios_app_store_submission.py', 'utf8');

assert.equal(spec.tracking, false);
assert.deepEqual(spec.trackingDomains, []);
assert.equal(spec.productionAnalytics.enabled, false);
assert.equal(spec.permissions.camera.required, true);
assert.equal(spec.permissions.camera.collectedOffDevice, false);
assert.equal(spec.permissions.trackingTransparency.required, false);
assert.equal(spec.permissions.location.required, false);
assert.equal(spec.permissions.photos.required, false);
assert.equal(spec.permissions.contacts.required, false);
assert.deepEqual(
  new Set(spec.collectedData.map((x) => x.appleType)),
  new Set([
    'NSPrivacyCollectedDataTypeEmailAddress',
    'NSPrivacyCollectedDataTypeProductInteraction',
    'NSPrivacyCollectedDataTypeUserID',
  ]),
);
for (const item of spec.collectedData) {
  assert.equal(item.linkedToUser, true);
  assert.equal(item.tracking, false);
  assert.deepEqual(item.purposes, ['NSPrivacyCollectedDataTypePurposeAppFunctionality']);
}

assert.match(manifest, /app_store_privacy_details\.json/);
assert.match(manifest, /PrivacyInfo\.xcprivacy/);
assert.match(manifest, /PBXResourcesBuildPhase/);
assert.match(deps, /shared_preferences_foundation/);
assert.match(deps, /NSPrivacyAccessedAPICategoryUserDefaults/);

for (const workflow of [compile, signed]) {
  assert.match(workflow, /apply_ios_privacy_manifest\.py/);
  assert.match(workflow, /audit_ios_privacy_dependencies\.py/);
  assert.match(workflow, /ZYNC_ANALYTICS_ENABLED=false/);
}
assert.match(signed, /PrivacyInfo\.xcprivacy/);

assert.match(branding, /NSCameraUsageDescription/);
for (const forbiddenPermission of [
  'NSUserTrackingUsageDescription',
  'NSLocationWhenInUseUsageDescription',
  'NSLocationAlwaysAndWhenInUseUsageDescription',
  'NSPhotoLibraryUsageDescription',
  'NSContactsUsageDescription',
]) {
  assert.ok(!branding.includes(forbiddenPermission), `unexpected iOS permission declaration: ${forbiddenPermission}`);
}

assert.match(privacy, /Android and iOS apps/i);
assert.match(privacy, /Google or Apple/i);
assert.match(privacy, /cards, packs, rewards/i);
assert.match(privacy, /private People history/i);
assert.match(privacy, /camera access only when you choose to scan/i);
assert.match(terms, /Optional account and cloud collection/i);
assert.match(landing, /Optional cloud collection/i);

for (const obsolete of [
  'Zync V1 has no permanent cloud user profile',
  'Because Zync V1 has no account',
  'designed without login or registration',
]) {
  assert.ok(!privacy.includes(obsolete), `privacy contains obsolete claim: ${obsolete}`);
  assert.ok(!terms.includes(obsolete), `terms contains obsolete claim: ${obsolete}`);
  assert.ok(!landing.includes(obsolete), `landing contains obsolete claim: ${obsolete}`);
}

assert.match(audit, /account_deletion_flow_missing/);
assert.match(audit, /apple_token_revocation_not_verifiable/);
assert.match(audit, /runtime_roots/);
assert.match(audit, /apple_token_revocation_sources/);
assert.match(audit, /--strict-submission/);

console.log('Zync iOS privacy/submission contract checks passed');
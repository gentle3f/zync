import assert from 'node:assert/strict';
import fs from 'node:fs';

const workflow = fs.readFileSync('.github/workflows/zync-ios-signed-archive.yml', 'utf8');
const profile = fs.readFileSync('mobile/tool/ios_provisioning_profile.py', 'utf8');
const signing = fs.readFileSync('mobile/tool/configure_ios_signing.py', 'utf8');
const ipa = fs.readFileSync('.github/scripts/verify_signed_ipa.py', 'utf8');
const version = fs.readFileSync('.github/scripts/release_version.py', 'utf8');

// Manual-only and intentionally expensive.
assert.match(workflow, /workflow_dispatch:/, 'signed iOS archive must be manual-only');
assert.ok(!/^\s*push:/m.test(workflow), 'signed iOS archive must never run on push');
assert.ok(!/^\s*pull_request:/m.test(workflow), 'signed iOS archive must never run on pull request');
assert.match(workflow, /BUILD_SIGNED_IPA/, 'workflow must require explicit macOS/signing confirmation');
assert.match(workflow, /runs-on:\s*macos-15/, 'signed iOS archive must run on macOS');

// Production identity and explicit versioning.
assert.match(workflow, /BUNDLE_ID:\s*com\.gmail\.gentle3f\.myproject\b/);
assert.ok(!workflow.includes('com.gmail.gentle3f.myproject.qa'), 'signed archive must not use QA bundle ID');
assert.match(workflow, /version_name:/);
assert.match(workflow, /build_number:/);
assert.match(workflow, /--build-name=\$\{RELEASE_VERSION_NAME\}/);
assert.match(workflow, /--build-number=\$\{RELEASE_BUILD_NUMBER\}/);
assert.match(workflow, /--ios-info-plist/);
assert.match(version, /def verify_ios_info_plist/, 'shared version helper must validate final iOS Info.plist');

// OAuth + Apple capability.
assert.match(workflow, /ZYNC_GOOGLE_SERVER_CLIENT_ID/);
assert.match(workflow, /ZYNC_GOOGLE_IOS_CLIENT_ID/);
assert.match(workflow, /apply_ios_google_identity\.py/);
assert.match(workflow, /apply_ios_apple_identity\.py/);
assert.match(workflow, /com\.apple\.developer\.applesignin/);

// Dedicated signing material, no hardcoded private credentials.
for (const secret of [
  'ZYNC_IOS_DISTRIBUTION_P12_BASE64',
  'ZYNC_IOS_DISTRIBUTION_P12_PASSWORD',
  'ZYNC_IOS_APP_STORE_PROFILE_BASE64',
]) {
  assert.ok(workflow.includes(`secrets.${secret}`), `workflow must consume ${secret}`);
}
assert.ok(!/-----BEGIN [A-Z ]*PRIVATE KEY-----/.test(workflow));
assert.ok(!/BEGIN CERTIFICATE/.test(workflow));

// Provisioning profile must be App Store-shaped and capability-bound.
assert.match(workflow, /ios_provisioning_profile\.py/);
assert.match(profile, /ProvisionedDevices/);
assert.match(profile, /ProvisionsAllDevices/);
assert.match(profile, /get-task-allow/);
assert.match(profile, /com\.apple\.developer\.applesignin/);
assert.match(profile, /application-identifier/);

// Manual signing + deterministic export.
assert.match(workflow, /configure_ios_signing\.py/);
assert.match(signing, /CODE_SIGN_STYLE = Manual/);
assert.match(signing, /Apple Distribution/);
assert.match(signing, /PROVISIONING_PROFILE_SPECIFIER/);
assert.match(signing, /"method": "app-store-connect"/);
assert.match(signing, /"manageAppVersionAndBuildNumber": False/);

// Real archive verification and provenance.
assert.match(workflow, /flutter build ipa --release/);
assert.match(workflow, /codesign --verify --deep --strict/);
assert.match(workflow, /verify_signed_ipa\.py/);
assert.match(ipa, /CFBundleIdentifier/);
assert.match(ipa, /CFBundleShortVersionString/);
assert.match(ipa, /CFBundleVersion/);
assert.match(ipa, /profile_uuid/);
assert.match(ipa, /team_id/);
assert.match(workflow, /Zync-iOS-signed\.sha256\.txt/);
assert.match(workflow, /Zync-iOS-signed-build\.txt/);

// Crash-symbol handoff is part of a real archive.
assert.match(workflow, /Runner\.xcarchive/);
assert.match(workflow, /Zync-iOS-dSYMs\.zip/);
assert.match(workflow, /Zync-iOS-dSYMs\.sha256\.txt/);

// Signing material cleanup must run even on failure.
assert.match(workflow, /Remove temporary signing material/);
assert.match(workflow, /if:\s*always\(\)/);
assert.match(workflow, /security delete-keychain/);
assert.match(workflow, /rm -f "\$ZYNC_INSTALLED_PROFILE"/);

// This workflow builds an artifact only. It must never upload to App Store Connect.
for (const forbidden of [
  /xcrun\s+altool/i,
  /iTMSTransporter/i,
  /xcrun\s+notarytool/i,
  /fastlane\s+(pilot|deliver)/i,
  /app-store-connect\/v1/i,
  /upload.*app store/i,
]) {
  assert.ok(!forbidden.test(workflow), `signed archive workflow contains forbidden upload path: ${forbidden}`);
}

// Must not touch Play or Vercel.
assert.ok(!/google play|androidpublisher/i.test(workflow));
assert.ok(!/npx vercel|vercel --prod|vercel deploy|amondnet\/vercel-action/i.test(workflow));

console.log('Zync iOS signed-archive contract checks passed');

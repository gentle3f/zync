import assert from 'node:assert/strict';
import fs from 'node:fs';

const signed = fs.readFileSync('.github/workflows/zync-v1-signed-release.yml', 'utf8');
const play = fs.readFileSync('.github/workflows/zync-play-internal-release.yml', 'utf8');
const publisher = fs.readFileSync('.github/scripts/play_internal_release.py', 'utf8');
const verifier = fs.readFileSync('.github/scripts/verify_signed_aab.py', 'utf8');
const version = fs.readFileSync('.github/scripts/release_version.py', 'utf8');

assert.match(signed, /version_name:/, 'signed-release must require version_name input');
assert.match(signed, /version_code:/, 'signed-release must require version_code input');
assert.match(signed, /release_version\.py/, 'signed-release must validate release version inputs');
assert.match(signed, /--build-name=\$\{RELEASE_VERSION_NAME\}/, 'Flutter build must use explicit version name');
assert.match(signed, /--build-number=\$\{RELEASE_VERSION_CODE\}/, 'Flutter build must use explicit version code');
assert.match(signed, /version_name=\$RELEASE_VERSION_NAME/, 'release metadata must record version name');
assert.match(signed, /version_code=\$RELEASE_VERSION_CODE/, 'release metadata must record version code');
assert.match(signed, /packaged_manifests\/release/, 'signed-release must verify actual packaged-manifest output');
assert.match(signed, /--android-metadata/, 'signed-release must validate actual Android build metadata');
assert.match(signed, /--expected-package com\.gmail\.gentle3f\.myproject/, 'actual Android build metadata must be bound to the production package');
assert.match(signed, /--expected-version-name/, 'signed-release verifier must bind version name');
assert.match(signed, /--expected-version-code/, 'signed-release verifier must bind version code');
assert.ok(!signed.includes('version=1.0.0+6'), 'signed-release must not hardcode the old release version');

assert.match(play, /id: verify_aab/, 'Play workflow must expose verified provenance outputs');
assert.match(play, /--github-output "\$GITHUB_OUTPUT"/, 'Play workflow must export only verified version metadata');
assert.match(
  play,
  /--expected-version-code "\$\{\{ steps\.verify_aab\.outputs\.version_code \}\}"/,
  'Play publisher must receive versionCode from verified signed-release metadata',
);

assert.match(verifier, /validate_version_name/, 'AAB verifier must validate metadata version name');
assert.match(verifier, /validate_version_code/, 'AAB verifier must validate metadata version code');
assert.match(verifier, /version_name=/, 'AAB verifier must expose verified version name');
assert.match(verifier, /version_code=/, 'AAB verifier must expose verified version code');

assert.match(publisher, /require_expected_version_code/, 'publisher must validate expected versionCode');
assert.match(
  publisher,
  /Uploaded Play versionCode does not match signed-release provenance/,
  'publisher must abort on Play/signed-release versionCode mismatch',
);

assert.match(version, /MAX_ANDROID_VERSION_CODE = 2_100_000_000/, 'versionCode upper bound must stay explicit');
assert.match(version, /major\.minor\.patch/, 'versionName format must stay explicit');
assert.match(version, /verify_android_output_metadata/, 'version helper must verify actual AGP output metadata');
assert.match(version, /Android versionCode mismatch/, 'version helper must reject an actual build/output versionCode mismatch');

console.log('Zync release-version contract checks passed');
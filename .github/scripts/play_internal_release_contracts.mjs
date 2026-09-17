import assert from 'node:assert/strict';
import fs from 'node:fs';

const read = (path) => fs.readFileSync(path, 'utf8');

const workflow = read('.github/workflows/zync-play-internal-release.yml');
const script = read('.github/scripts/play_internal_release.py');

// Package identity must be the real, frozen Zync Play package.
assert.match(workflow, /PACKAGE_NAME:\s*com\.gmail\.gentle3f\.myproject/, 'workflow must target the frozen Zync package name');
assert.match(script, /EXPECTED_PACKAGE = "com\.gmail\.gentle3f\.myproject"/, 'publishing script must hard-code the frozen Zync package name');

// Track must be exactly "internal" and never a variable/user-controlled value.
assert.match(workflow, /TRACK:\s*internal/, 'workflow must pin the track to internal');
assert.match(script, /ALLOWED_TRACK = "internal"/, 'publishing script must hard-code the allowed track as internal');
assert.ok(
  !/track:\s*\$\{\{\s*inputs\./.test(workflow),
  'workflow must not accept the Play track as a workflow_dispatch input (prevents accidental production/beta/alpha selection)',
);
for (const forbiddenTrack of ['production', 'beta', 'alpha', 'rollout']) {
  assert.ok(
    !new RegExp(`TRACK:\\s*${forbiddenTrack}\\b`).test(workflow),
    `workflow must never set TRACK to ${forbiddenTrack}`,
  );
}

// The script's own guard function must reject every non-internal track,
// independent of whatever the workflow passes in.
assert.match(script, /def require_internal_track/, 'publishing script must have a track guard function');
assert.match(script, /if track != ALLOWED_TRACK:/, 'track guard must reject anything other than the allowed track');

// Must consume a pre-existing signed AAB, never build or sign one itself.
assert.match(workflow, /download-artifact@v4/, 'workflow must download an existing artifact rather than building an AAB');
assert.match(workflow, /zync-v1-play-signed-aab/, 'workflow must consume the existing signed-release artifact');
assert.match(workflow, /jarsigner -verify -strict/, 'workflow must re-verify the AAB signature before publishing');
assert.match(script, /def require_signed_aab/, 'publishing script must have a signed-AAB guard function');
assert.match(script, /jarsigner", "-verify", "-strict"/, 'publishing script must verify the JAR signature itself');
assert.ok(
  !/flutter build appbundle|keytool -genkey|keytool -genkeypair/.test(workflow) &&
  !/flutter build appbundle|keytool -genkey|keytool -genkeypair/.test(script),
  'workflow/script must never build an AAB or generate a signing key',
);

// Credentials must come from the named secret and must never be printed.
assert.match(workflow, /secrets\.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON/, 'workflow must authenticate with GOOGLE_PLAY_SERVICE_ACCOUNT_JSON');
assert.ok(
  !/echo\s+"?\$GOOGLE_PLAY_SERVICE_ACCOUNT_JSON"?/.test(workflow) &&
  !/cat\s+.*play-credentials\.json/.test(workflow),
  'workflow must never echo/cat the service-account credentials',
);
assert.ok(
  !/-----BEGIN [A-Z ]*PRIVATE KEY-----/.test(workflow) && !/-----BEGIN [A-Z ]*PRIVATE KEY-----/.test(script),
  'no hardcoded private key material may appear in the workflow or script',
);
assert.ok(
  !/GOOGLE_PLAY_SERVICE_ACCOUNT_JSON\s*=\s*['"]/.test(script),
  'publishing script must not hardcode the service-account JSON',
);
assert.match(workflow, /rm -f .*play-credentials\.json/, 'workflow must remove the ephemeral credentials file');
assert.match(workflow, /if: always\(\)/, 'credential cleanup step must run even if earlier steps fail');

// Edit lifecycle: commit only after success, delete/abandon on any failure before commit.
assert.match(script, /edits\(\)\.commit\(/, 'publishing script must commit the Play edit on success');
assert.match(script, /edits\(\)\.delete\(/, 'publishing script must delete/abandon the Play edit on failure');
assert.match(script, /except Exception:/, 'publishing script must catch failures before commit and clean up the edit');

// Explicit operator confirmation and concurrency protection.
assert.match(workflow, /UPLOAD_TO_INTERNAL_TESTING/, 'workflow must require an explicit internal-testing confirmation input');
assert.match(workflow, /concurrency:/, 'workflow must declare a concurrency group');
assert.match(workflow, /cancel-in-progress:\s*false/, 'concurrent Play releases must queue, not cancel, to avoid racing edits');
assert.match(workflow, /timeout-minutes:/, 'workflow must declare a job timeout');
assert.match(workflow, /permissions:\s*\n\s*contents: read/, 'workflow must use least-privilege permissions');

// Must not touch Vercel.
assert.ok(!/vercel\.json/i.test(workflow), 'workflow must not modify Vercel configuration');
assert.ok(
  !/npx vercel|vercel --prod|vercel deploy\b|amondnet\/vercel-action|uses:\s*vercel/i.test(workflow),
  'workflow must not trigger a Vercel deployment',
);

console.log('Zync Play internal-release contract checks passed');

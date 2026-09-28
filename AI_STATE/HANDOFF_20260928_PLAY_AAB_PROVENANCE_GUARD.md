# Zync — Stable QA AAB + Play Provenance Guard

Date: 2026-09-28
Branch: `card-art-pilot-v1-20260921`
Source HEAD before this round: `adb98b8`

## Goal

Close the next Android release-packaging gap without publishing anything to
Google Play.

The APK path was already proven. This round verifies that current Zync source,
the stable QA signer and the current Flutter/Gradle toolchain can also produce a
real Android App Bundle, then hardens the handoff from the signed-release
workflow to the Play Internal uploader.

No Play upload, GitHub Actions run, Vercel deployment or production action was
performed.

## Stable QA AAB proof

Using the existing fresh Android QA wrapper and the dedicated stable QA signer,
a release App Bundle was built successfully:

`C:\Users\FUJITSU\Zync-QA-Stable-20260928.aab`

Artifact facts:

- package lineage: QA wrapper
  `com.gmail.gentle3f.myproject.qa`
- size: 80,351,983 bytes
- signer:
  `CN=Zync QA, OU=QA, O=Zync, L=Hong Kong, C=HK`
- signer SHA-1:
  `E9:00:0B:0A:A3:AE:B6:2E:FF:5D:C3:C9:D1:3E:9B:7B:61:81:1F:1D`
- signer SHA-256:
  `4E:3F:7F:DB:E5:00:2A:18:15:E9:8A:9C:7C:5B:BD:6E:33:79:CE:D7:65:D3:D7:5C:1E:6B:C1:10:BB:83:7F:6C`
- AAB SHA-256:
  `5D7BCDC16ABE6F20E47A5CDC047E36A72FD6F5933688513C0899B5261A248DAE`

Direct bundle inspection confirms the real repository Google Web/server client
ID is embedded in the release app binaries for arm64-v8a, armeabi-v7a and
x86_64.

This is a packaging/signing proof only. It is not a production Play artifact:
the wrapper deliberately uses the QA package and QA certificate.

## Real Play workflow bug found

The existing signed-release and Play Internal workflows both used:

`jarsigner -verify -strict`

Against the real current Flutter/Gradle AAB:

- `jarsigner -verify` -> exit **0**
- `jarsigner -verify -strict` -> exit **4**

Strict mode emits a large set of JarFile/JarInputStream compatibility warnings
for current Android bundle contents even though the bundle is signed and normal
JAR verification succeeds.

Therefore the existing Play path would reject a valid current AAB before any
Play API call.

This was reproduced on the real stable-signed QA AAB rather than inferred from a
fixture.

## New signed-AAB provenance guard

Added:

`.github/scripts/verify_signed_aab.py`

It verifies:

- AAB exists and is non-empty
- AAB SHA-256 matches both release metadata and SHA-256 sidecar
- actual signer SHA-1 matches release metadata
- expected package matches release metadata
- operator-selected signed-release run ID matches release metadata
- source SHA has valid commit-shape provenance
- release version is present

It does not replace JAR signature verification. Workflows first run normal
`jarsigner -verify`, then use this provenance verifier.

The verifier has a local self-test and was additionally exercised against the
real stable QA AAB.

Positive real-AAB probe: PASS.

Negative probes:

- wrong expected package -> rejected
- wrong expected signed-release run ID -> rejected

## Signed-release workflow

Updated:

`.github/workflows/zync-v1-signed-release.yml`

The manual signed-release workflow now:

1. runs the provenance verifier self-test
2. builds the signed AAB as before
3. runs normal `jarsigner -verify`
4. extracts the actual signer SHA-1 from the built AAB
5. computes the AAB SHA-256
6. writes:
   - `app-release.aab`
   - `app-release.sha256.txt`
   - `app-release-build.txt`
7. validates those files through `verify_signed_aab.py`
8. uploads all three in the existing
   `zync-v1-play-signed-aab` artifact

Metadata binds the artifact to:

- package
- signer SHA-1
- AAB SHA-256
- GitHub run ID
- source commit SHA
- release version

The workflow remains `workflow_dispatch` only.

## Play Internal workflow

Updated:

`.github/workflows/zync-play-internal-release.yml`

Before any Google Play API call it now requires all three files from the exact
operator-supplied signed-release run.

It then:

1. runs the provenance verifier self-test
2. checks all artifact files are present
3. re-runs normal JAR signature verification
4. extracts the actual signer SHA-1 from the downloaded AAB
5. verifies hash + signer + package + selected run ID against the sidecars
6. only then installs the Google API client and reaches the existing
   internal-track publisher

The publisher still hard-locks:

- package `com.gmail.gentle3f.myproject`
- Play track `internal`
- no build/signing inside the upload workflow
- explicit operator confirmation
- edit validate-before-commit
- edit cleanup on failure

## Publisher defense-in-depth

Updated:

`.github/scripts/play_internal_release.py`

Its own preflight now uses normal:

`jarsigner -verify`

instead of strict mode.

It still independently requires:

- exact production package
- exact internal track
- non-empty signed AAB
- META-INF signature block
- successful JAR signature verification
- credentials file
- no Play API call before guards pass

The workflow adds provenance verification before this script runs.

## Contract updates

Updated:

- `.github/scripts/play_internal_release_contracts.mjs`
- `.github/scripts/release_web_contracts.mjs`

The contracts now explicitly require:

- normal JAR verification
- no runtime `jarsigner -verify -strict`
- signed-release provenance verifier
- SHA-256 sidecar
- build metadata sidecar
- selected run-ID binding

## Validation

PASS:

- `verify_signed_aab.py --self-test`
- `play_internal_release.py --self-test`
- real stable QA AAB through `require_signed_aab(...)`
- real stable QA AAB through the provenance verifier
- wrong-package rejection
- wrong-run-ID rejection
- Play Internal release contract checks
- JavaScript syntax for release contract scripts
- all 8 workflow YAML files parse
- runtime strict-jarsigner references: **0**
- `git diff --check`: clean before handoff write

The full `release_web_contracts.mjs` suite cannot run on this branch because the
branch does not contain `api/v1/interest-popularity.js`. This is a pre-existing
branch-content limitation, not a failure introduced by this round. The modified
file passes JavaScript syntax checking and its signed-release assertions were
validated directly.

## Remaining release gates

Android QA:

1. Google Android OAuth registration/verification for the stable QA
   package/SHA-1 pair
2. physical-device Google/session/provider-link/reward smoke

Production Play:

1. production upload signing secrets remain intentionally unopened
2. a deliberate signed-release workflow run when release work is actually
   authorized
3. Play Console/service-account/package readiness
4. explicit Internal Testing upload authorization

No production AAB was generated or uploaded in this round.

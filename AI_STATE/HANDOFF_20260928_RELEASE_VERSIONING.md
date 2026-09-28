# Zync — Explicit Release Versioning + Play versionCode Guard

Date: 2026-09-28
Branch: `card-art-pilot-v1-20260921`
Starting HEAD: `000ed1f`

## Goal

Close the next release-pipeline gap after signed-AAB provenance: production
signed releases must not silently reuse the repository development version
(`1.0.0+6`), and the Play uploader must not trust an unverified or mismatched
versionCode.

No GitHub Actions workflow, Google Play upload, Vercel deployment or production
release was run.

## Explicit release inputs

Updated:

`.github/workflows/zync-v1-signed-release.yml`

Every manual signed-release run now requires both:

- `version_name`
- `version_code`

There are deliberately **no defaults**.

The operator must therefore choose the release identity explicitly rather than
accidentally reusing the pubspec development baseline.

The workflow passes the values to Flutter as:

- `--build-name=$RELEASE_VERSION_NAME`
- `--build-number=$RELEASE_VERSION_CODE`

The old hard-coded release assertion/metadata value `1.0.0+6` is no longer used
as the production release identity.

## Shared version validator

Added:

`.github/scripts/release_version.py`

It enforces:

- versionName is explicit numeric `major.minor.patch`
- versionCode is a positive integer
- Android versionCode maximum is explicitly bounded at 2,100,000,000

It also validates **actual AGP build output** rather than trusting only workflow
inputs.

Given packaged-manifest `output-metadata.json`, it verifies:

- applicationId
- versionName
- versionCode
- exactly one release element

This catches a build that ignored/misapplied the requested release version.

## Real artifact proof

A stable-signed QA release APK was built with explicit version override:

- versionName: `1.0.1`
- versionCode: `7`

Artifact:

`C:\Users\FUJITSU\Zync-QA-Version-Proof-1.0.1-7-20260928.apk`

Verified by the real generated Android packaged-manifest metadata:

- package: `com.gmail.gentle3f.myproject.qa`
- versionCode: `7`
- versionName: `1.0.1`

Verified again from the final APK with `aapt dump badging`:

- package: `com.gmail.gentle3f.myproject.qa`
- versionCode: `7`
- versionName: `1.0.1`
- minSdk: 24
- targetSdk: 36

Stable QA signer remained unchanged:

`E9:00:0B:0A:A3:AE:B6:2E:FF:5D:C3:C9:D1:3E:9B:7B:61:81:1F:1D`

APK SHA-256:

`BBB1AFEDE45E9DDE81F2523D37E7CEAD3D7A93759F69D8BCF6B1EBC1E804F1DA`

This proves the Flutter/Gradle release path actually honors explicit version
overrides while retaining stable signing.

## Signed-release provenance

Updated:

`.github/scripts/verify_signed_aab.py`

Signed-release metadata now records separate:

- `version_name`
- `version_code`

The verifier validates both through the shared release-version helper.

The signed-release workflow also passes its expected version name/code back into
the verifier, so metadata cannot silently diverge from the operator's release
inputs.

The verifier can write only already-validated provenance values to a GitHub
step-output file:

- version_name
- version_code
- source_sha
- aab_sha256
- signer_sha1

This output path was exercised locally against the real stable QA AAB and
returned the expected validated values.

## Actual build identity gate

After the production AAB build, the signed-release workflow locates AGP's
packaged-manifest `output-metadata.json` and runs:

`release_version.py --android-metadata ...`

against:

- requested release version
- production package `com.gmail.gentle3f.myproject`

If Gradle's actual versionName/versionCode/package does not match the requested
production identity, the workflow stops before provenance sidecars are created.

## Play Internal versionCode binding

Updated:

- `.github/workflows/zync-play-internal-release.yml`
- `.github/scripts/play_internal_release.py`

The Play workflow's signed-AAB provenance step now has an ID and exports the
verified versionCode from signed-release metadata.

The publisher receives:

`--expected-version-code <verified signed-release versionCode>`

After Google Play accepts the bundle upload, the API-returned `versionCode` is
validated and compared with the signed-release provenance value.

If they differ:

- the publisher raises a guard failure
- track update does not occur
- the existing failure path deletes/abandons the Play edit
- nothing is committed

The uploader therefore cannot quietly publish a bundle whose Play versionCode
differs from the artifact provenance selected by the operator.

Google Play remains the final authority for uniqueness/monotonicity versus
historical uploads. The signed-release input description explicitly tells the
operator that versionCode must exceed every previously uploaded Play
versionCode. The current environment cannot query that production history
without the external Play release authorization path.

## Contracts

Added:

`.github/scripts/release_version_contracts.mjs`

It locks:

- required signed-release version inputs
- Flutter build-name/build-number wiring
- actual packaged-manifest verification
- metadata version_name/version_code
- expected-version verification
- no hardcoded `version=1.0.0+6`
- verified provenance -> GitHub output -> Play publisher versionCode handoff
- Play/signed-release mismatch guard

Updated:

`.github/scripts/play_internal_release_contracts.mjs`

It additionally requires:

- the provenance step output ID
- verified GitHub-output handoff
- expected-version-code passed to publisher
- publisher versionCode validation/mismatch guard

Both manual release workflows run the release-version contract when deliberately
invoked.

## Validation

PASS:

- `release_version.py --self-test`
- valid `1.0.1+7`
- invalid version-name rejection
- invalid/zero versionCode rejection
- real AGP packaged-manifest validation for `1.0.1+7`
- actual final APK reports `1.0.1+7`
- final APK still uses the stable QA signer
- `verify_signed_aab.py --self-test`
- wrong expected versionCode rejection
- verified GitHub-output handoff using the real stable QA AAB
- `play_internal_release.py --self-test`
- `release_version_contracts.mjs`
- `play_internal_release_contracts.mjs`
- all workflow YAML parses
- `git diff --check`

## Remaining external gates

Android QA still requires:

1. Google Android OAuth registration/verification for
   `com.gmail.gentle3f.myproject.qa` + stable QA SHA-1
2. physical-device Google/session/provider-link/reward smoke

Production Play still requires deliberate authorization for:

1. production upload signing
2. a real signed-release run with a versionCode known to be higher than Play
   history
3. service-account/Play Console readiness
4. explicit Internal Testing upload

No Play history was queried and no Play API write occurred in this work.

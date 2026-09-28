# Zync Mobile Build State

Date: 2026-09-28

Zync keeps Flutter UI/business source under `mobile/`. Android and iOS native
projects are generated as disposable wrappers rather than committed as long-lived
platform trees.

## Shared wrapper

Use:

```text
python mobile/tool/generate_mobile_wrapper.py android <output>
python mobile/tool/generate_mobile_wrapper.py ios <output>
```

The generator copies:

- `mobile/lib/`
- `mobile/test/`
- `mobile/assets/`
- `mobile/pubspec.yaml`
- `mobile/l10n.yaml`

Copying `mobile/assets/` is mandatory because Card FX uses locked frame PNGs and
bundled reveal/rarity SFX.

## Android

Android generated wrappers apply:

- `apply_android_branding.py`
- `apply_android_variant_identity.py`
- `apply_android_google_identity.py`
- `configure_android_signing.py` for stable signed release/QA wrappers

Google auth uses Android Credential Manager and binds the Cardverse one-time
challenge nonce into the Google ID-token request.

### Current stable QA signer

A dedicated QA-only signer now exists locally at:

`C:\Users\FUJITSU\.zync\qa-signing\zync-qa.jks`

It is not source-controlled and is protected with non-inherited ACLs.

Stable QA signer SHA-1:

`E9:00:0B:0A:A3:AE:B6:2E:FF:5D:C3:C9:D1:3E:9B:7B:61:81:1F:1D`

Certificate validity ends 2054-02-13.

### Stable-signed current QA APK

Current stable-signed artifact:

`C:\Users\FUJITSU\Zync-QA-Stable-20260928.apk`

Verified:

- package `com.gmail.gentle3f.myproject.qa`
- label `Zync QA Local`
- minSdk 24 / targetSdk 36
- APK Signature Scheme v2 valid
- real repository `ZYNC_GOOGLE_SERVER_CLIENT_ID` is embedded in the release app binaries
- signer SHA-1 exactly matches the stable QA certificate above
- APK SHA-256:
  `A7FFC73FD6D63E61F276DC14DB3DB412E485FF3AC322EA80A42FF121C061F121`

The signing helper was hardened for the current Flutter/AGP/Gradle toolchain:

- explicit Kotlin imports avoid Gradle 9 `java`-extension shadowing
- Windows `storeFile` paths are normalized to forward slashes before Java Properties/Gradle consume them
- the self-test covers Windows path normalization and BOM-prefixed properties

The fixed helper produced the stable-signed release APK successfully.

### QA vs production signing

QA preview signing now uses dedicated names:

- variable `ZYNC_ANDROID_QA_SHA1`
- secrets `ZYNC_ANDROID_QA_KEYSTORE_BASE64`
- `ZYNC_ANDROID_QA_STORE_PASSWORD`
- `ZYNC_ANDROID_QA_KEY_ALIAS`
- `ZYNC_ANDROID_QA_KEY_PASSWORD`

Production release continues to use separate `ZYNC_ANDROID_*` signing secrets.

The non-secret QA SHA-1 variable is already configured in GitHub and the QA
workflow verifies the final APK signer exactly matches it.

All four QA-only signing secrets are now configured in GitHub:

- `ZYNC_ANDROID_QA_KEYSTORE_BASE64`
- `ZYNC_ANDROID_QA_STORE_PASSWORD`
- `ZYNC_ANDROID_QA_KEY_ALIAS`
- `ZYNC_ANDROID_QA_KEY_PASSWORD`

They were uploaded directly from the protected local signer without printing
their values. Production `ZYNC_ANDROID_*` signing secrets were not populated or
changed. Secret/variable installation triggered no workflow run.

Stable local QA signing, stable signed APK generation and GitHub QA-signing
configuration are therefore **closed**.

Remaining Android QA gates:

1. register/verify Google Android OAuth for package `com.gmail.gentle3f.myproject.qa` + stable SHA-1 `E9:00:0B:0A:A3:AE:B6:2E:FF:5D:C3:C9:D1:3E:9B:7B:61:81:1F:1D`
2. physical Google chooser/session/provider-link/reward-loop smoke

The active local gcloud account cannot see Google project number
`809680073916`, so no OAuth client was created or changed in a different
project.

Production upload signing remains separate and unopened.

## Stable QA AAB + Play provenance

Current stable QA App Bundle:

`C:\Users\FUJITSU\Zync-QA-Stable-20260928.aab`

Verified:

- size: 80,351,983 bytes
- stable QA signer SHA-1:
  `E9:00:0B:0A:A3:AE:B6:2E:FF:5D:C3:C9:D1:3E:9B:7B:61:81:1F:1D`
- AAB SHA-256:
  `5D7BCDC16ABE6F20E47A5CDC047E36A72FD6F5933688513C0899B5261A248DAE`
- real Google Web/server client ID is embedded in all release ABI app binaries

This proves the current source/toolchain can produce a stable-signed release AAB.
It is a QA package/signing artifact, not a production Play artifact.

A real current AAB exposed a release-pipeline bug: normal
`jarsigner -verify` succeeds, while `jarsigner -verify -strict` exits 4 due to
current Android bundle JarInputStream compatibility warnings. The previous
signed-release and Play Internal workflows would therefore reject a valid AAB.

The Play handoff is now hardened:

- `verify_signed_aab.py` verifies AAB SHA-256, signer SHA-1, package, release
  version, source commit SHA and selected signed-release run ID
- signed-release emits AAB + SHA-256 sidecar + build metadata sidecar
- Play Internal requires all three from the exact operator-selected run
- both workflows use normal JAR signature verification before provenance checks
- runtime `jarsigner -verify -strict` references are removed
- the publisher still independently enforces exact production package,
  `internal` track, signature presence/verification, credentials and safe edit
  lifecycle

Both release workflows remain `workflow_dispatch` only. No Actions run or Play
upload was performed while validating this path.

## iOS native foundation

`apply_ios_branding.py` configures Zync naming, bundle-ID baseline, iOS 15,
camera permission, deterministic icons and deterministic LaunchScreen branding.

Google iOS auth uses `google_sign_in_ios` from Dart. The generated AppDelegate
remains Flutter-default.

`apply_ios_google_identity.py` configures:

- dedicated iOS `GIDClientID`
- reversed Google URL scheme

Dart passes the iOS client ID, Web/server client ID and exact Cardverse one-time
nonce into every iOS Google sign-in.

## Sign in with Apple

Dependency:

`sign_in_with_apple: 8.2.0`

Apple identity uses the exact Cardverse server challenge nonce. The installed
plugin's native Swift was verified to forward it directly:

`appleIDRequest.nonce = nonce`

`apply_ios_apple_identity.py` reproducibly adds:

- `Runner.entitlements`
- `com.apple.developer.applesignin = [Default]`
- `CODE_SIGN_ENTITLEMENTS` in Debug/Release/Profile
- Runner target Sign in with Apple capability metadata

The production Account screen shows the official Apple button only on native iOS.

## Same-world provider linking / recovery

Cardverse production-lineage already exposes:

`POST /api/v1/cardverse/auth/link`

The mobile app now uses that route through:

- `CardverseCloudClient.linkProviderIdentity(...)`
- `CardverseIdentityLinkService`

Linking always requires:

1. an existing valid Cardverse bearer session
2. a fresh provider-specific one-time challenge
3. fresh Google/Apple re-verification using the exact challenge nonce
4. authenticated server-side link transaction

The client never sends accountId in the link request.

Important conflict behavior is preserved:

- `cardverse_identity_already_linked` — identity belongs to another Zync World
- `cardverse_provider_already_linked` — current world already has a different
  identity for the same provider

Neither conflict triggers account merging or replacement.

A 401 clears the stale local session. A 409 preserves the current session.

### Production UX

On signed-in iOS, Account shows:

**Keep one Zync World across devices**

It can verify/link Google and Apple to the Zync World already open.

The UI explicitly states that:

- another existing Zync World is not automatically merged
- People history/private conversations are not uploaded
- identity ownership conflicts make no data changes

Successful links are shown only as **linked this visit**. This is intentionally
not persisted as provider inventory because the server currently exposes no
authoritative linked-provider list endpoint.

Android keeps this recovery surface hidden because Zync's current Apple identity
path is iOS-only.

### QA Lab

Signed-in Account Lab can run provider-link actions and reports provider,
client/provider error, cloud failure, HTTP status, serverCode and restored flag.

No ID token is displayed.

## Unlink deliberately not exposed

The backend also has `auth/unlink`, but a successful unlink:

- requires provider re-verification
- refuses to remove the last linked identity
- revokes all active account sessions

Unlink therefore needs a separate destructive-action / re-auth UX and was not
added to the normal Account screen.

## Manual iOS compile smoke

`.github/workflows/zync-ios-compile-smoke.yml` remains
**workflow_dispatch only**.

It checks:

- Zync branding
- Google iOS metadata
- Apple entitlement/capability
- representative Card FX assets
- Google + Apple identity
- provider-link cloud/service contracts
- production provider UI
- unsigned iOS release compilation when deliberately run on macOS

It has not been run during these Windows/local checkpoints.

## Current validation

Repo:

- focused identity/link/session/proof suite: **34 / 34 PASS**
- full Flutter analyze: **No issues found**
- canonical non-golden regression:
  - **62 files**
  - **379 tests PASS** across three batches
- legacy Card Art golden remains excluded only because
  `goldens/card_art_engine_v1_flagships.png` does not exist

Fresh generated iOS wrapper:

`C:\Users\FUJITSU\zync_ios_link_probe_20260928`

- wrapper generation: PASS
- branding: PASS
- Google metadata: PASS
- Apple capability: PASS
- shared generator copied provider-link source/tests: PASS
- Google + Apple + link + production provider UI: **29 / 29 PASS**
- analyzer: no errors/warnings; INFO-only template lint output

## Release gates still closed

Android:

1. Android OAuth registration/verification for package
   `com.gmail.gentle3f.myproject.qa` + stable QA signer SHA-1
   `E9:00:0B:0A:A3:AE:B6:2E:FF:5D:C3:C9:D1:3E:9B:7B:61:81:1F:1D`
2. physical Android Google/session/reward-loop/provider-link smoke

Stable QA signing, stable signed APK generation and GitHub QA-signing secret
configuration are closed.

iOS:

1. real Google iOS OAuth client ID
2. enable Sign in with Apple on real Apple App ID
3. configure server `ZYNC_APPLE_CLIENT_IDS`
4. manual macOS unsigned compile smoke
5. Apple signing/provisioning
6. physical iPhone Google/Apple/provider-link/QR/audio/lifecycle/reveal smoke

Production, Google Play, App Store, Vercel and paid generation remain closed.

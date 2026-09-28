# Zync — Stable Android QA Signing

Date: 2026-09-28
Branch: `card-art-pilot-v1-20260921`
Starting HEAD: `21d7857`

## Goal

Move Android QA from an ephemeral machine debug certificate to a dedicated,
reproducible QA signer so the Android OAuth package/SHA-1 pair stays stable
across builds and machines.

Production signing remains separate and untouched.

## Stable QA signer

Created locally on GEN-FUJI:

`C:\Users\FUJITSU\.zync\qa-signing\zync-qa.jks`

Properties are stored separately at:

`C:\Users\FUJITSU\.zync\qa-signing\key.properties`

No key material or password is source-controlled.

Certificate:

- DN: `CN=Zync QA, OU=QA, O=Zync, L=Hong Kong, C=HK`
- algorithm: RSA 2048
- valid until: 2054-02-13
- SHA-1:
  `E9:00:0B:0A:A3:AE:B6:2E:FF:5D:C3:C9:D1:3E:9B:7B:61:81:1F:1D`
- SHA-256:
  `4E:3F:7F:DB:E5:00:2A:18:15:E9:8A:9C:7C:5B:BD:6E:33:79:CE:D7:65:D3:D7:5C:1E:6B:C1:10:BB:83:7F:6C`

The signing directory/files use explicit non-inherited Windows ACLs limited to:

- the current GEN-FUJI user
- SYSTEM
- local Administrators

## Stable-signed QA release APK

Built from the current generated QA wrapper with the real repository
`ZYNC_GOOGLE_SERVER_CLIENT_ID`.

Artifact:

`C:\Users\FUJITSU\Zync-QA-Stable-20260928.apk`

Verified:

- size: 90,520,315 bytes
- package: `com.gmail.gentle3f.myproject.qa`
- label: `Zync QA Local`
- versionCode: 6
- versionName: 1.0.0
- minSdk: 24
- targetSdk: 36
- compileSdk: 36
- APK Signature Scheme v2: PASS
- signer SHA-1:
  `E9:00:0B:0A:A3:AE:B6:2E:FF:5D:C3:C9:D1:3E:9B:7B:61:81:1F:1D`
- APK SHA-256:
  `A7FFC73FD6D63E61F276DC14DB3DB412E485FF3AC322EA80A42FF121C061F121`

Direct APK inspection confirmed the real Google server client ID is embedded in
all three release ABI `libapp.so` files.

No physical Android device was attached, so Google chooser/session/provider-link
and reward-loop device smoke are not claimed.

## Signing-helper bugs found and fixed

The existing `mobile/tool/configure_android_signing.py` had two current-toolchain
compatibility problems.

### 1. Kotlin DSL / Gradle 9 `java` shadowing

The old generated KTS used:

- `java.util.Properties()`
- `java.io.FileInputStream(...)`

With the current Flutter/AGP/Gradle toolchain, the Gradle `java` extension can
shadow the JVM package root in Kotlin DSL, producing:

- `Unresolved reference 'util'`
- `Unresolved reference 'io'`

The helper now adds explicit Kotlin imports:

- `import java.util.Properties`
- `import java.io.FileInputStream`

and uses unqualified class names.

It can also repair wrappers already patched by the older helper.

### 2. Windows absolute keystore paths in Java Properties

A raw Windows `storeFile=C:\...\zync-qa.jks` is corrupted by Java Properties
because backslashes are escape characters.

The helper now normalizes Windows absolute `storeFile` values to forward-slash
form before Gradle loads them, for example:

`C:/Users/FUJITSU/.zync/qa-signing/zync-qa.jks`

This is covered by the helper self-test, including a BOM-prefixed
`key.properties` fixture.

The fixed helper successfully produced the stable-signed release APK above.

## QA vs production signing separation

The QA preview workflow now uses dedicated QA-only configuration:

Repository variable:

- `ZYNC_ANDROID_QA_SHA1`

QA secrets:

- `ZYNC_ANDROID_QA_KEYSTORE_BASE64`
- `ZYNC_ANDROID_QA_STORE_PASSWORD`
- `ZYNC_ANDROID_QA_KEY_ALIAS`
- `ZYNC_ANDROID_QA_KEY_PASSWORD`

Production release continues to use the separate existing names:

- `ZYNC_ANDROID_KEYSTORE_BASE64`
- `ZYNC_ANDROID_STORE_PASSWORD`
- `ZYNC_ANDROID_KEY_ALIAS`
- `ZYNC_ANDROID_KEY_PASSWORD`

The QA workflow now:

- refuses to run without all four QA signing secrets
- requires the pinned QA SHA-1 variable
- validates the generated signing transform before installing secrets
- verifies the final APK signer SHA-1 exactly matches the pinned value
- labels build metadata as `stable-zync-qa-key`

The production signed-release workflow only gains a template compatibility check;
it does not consume the QA signer.

## GitHub state

Configured non-secret repository variable:

`ZYNC_ANDROID_QA_SHA1=E9:00:0B:0A:A3:AE:B6:2E:FF:5D:C3:C9:D1:3E:9B:7B:61:81:1F:1D`

Configured QA-only repository secrets:

- `ZYNC_ANDROID_QA_KEYSTORE_BASE64`
- `ZYNC_ANDROID_QA_STORE_PASSWORD`
- `ZYNC_ANDROID_QA_KEY_ALIAS`
- `ZYNC_ANDROID_QA_KEY_PASSWORD`

The values were read from the protected local signer files and piped directly
into `gh secret set`; no secret value was printed or written into the repository.

Production `ZYNC_ANDROID_*` signing secret names were not populated or changed.

Repository secret listing confirms all four QA names exist. Writing these
secrets/variable triggered **no GitHub Actions run**; the repository's latest
workflow runs still predate this work.

A local installer containing no embedded secret values remains at:

`C:\Users\FUJITSU\.zync\qa-signing\install-github-qa-secrets.ps1`

It can re-install the same protected local signer into the QA-only secret
namespace if recovery is ever needed.

## Validation

- stable QA keystore generated: PASS
- certificate fingerprint verified: PASS
- explicit local ACLs: PASS
- signing-helper Python syntax: PASS
- signing-helper self-test: PASS
- Gradle 9 Kotlin DSL signing transform: proven by successful release APK
- Windows key.properties normalization: proven by successful release APK
- stable-signed release APK signature verification: PASS
- real Google server client ID embedded in stable APK: PASS
- all workflow YAML files parse: PASS
- `git diff --check`: clean

No GitHub Actions workflow was run. No Vercel, Play, production deployment or
paid generation was used.

## Remaining Android QA gates

1. register/verify the Android OAuth client for:
   - package `com.gmail.gentle3f.myproject.qa`
   - SHA-1 `E9:00:0B:0A:A3:AE:B6:2E:FF:5D:C3:C9:D1:3E:9B:7B:61:81:1F:1D`
2. physical-device Google chooser -> Cardverse session smoke
3. physical-device provider-link/reward-reveal smoke

The currently active local gcloud account cannot see project number
`809680073916`, which owns the configured Google server client ID. The active
gcloud project is a different project. No OAuth client was created or changed in
the wrong Google project.

Stable local QA signing and stable signed APK generation are now closed.

Production upload signing remains a separate unopened release gate.

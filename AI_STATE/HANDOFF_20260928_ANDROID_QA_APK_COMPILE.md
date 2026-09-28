# Zync — Current Android QA APK Compile Proof

Date: 2026-09-28
Branch: `card-art-pilot-v1-20260921`
Source HEAD: `711d0b3`

## Goal

Close the long-standing uncertainty around whether the current Zync source,
including the latest reward reveal work, iOS/account work and same-world provider
linking, can produce a real installable Android APK.

This milestone is a **compile/install artifact proof**. It is not yet a claim
that Google sign-in has passed on a physical Android device.

## Fresh wrapper

Generated from current source:

`C:\Users\FUJITSU\zync_android_compile_probe_20260928`

Applied:

- shared mobile wrapper generator
- Zync Android branding
- QA package identity: `com.gmail.gentle3f.myproject.qa`
- QA label: `Zync QA Local`
- Android Credential Manager Google identity bridge
- full current assets, including locked Card FX frames and rarity SFX
- latest same-world provider-link source

Representative assets and provider-link source were verified in the generated
tree before compilation.

## First build race and root cause

The first long Gradle attempt was accidentally duplicated after the tool-layer
timeout. Two independent `assembleDebug` processes wrote the same generated
asset directory concurrently.

Gradle's real failure was:

`Execution failed for task ':app:mergeDebugAssets'`

with an IOException reporting that `mergeDebugAssets/flutter_assets` could not
be deleted because files were still being written.

This was an infrastructure/process race, not a Zync compile error.

Recovery:

1. stop Gradle daemons
2. `flutter clean`
3. `flutter pub get`
4. `flutter gen-l10n`
5. run exactly one `assembleDebug` build
6. monitor the actual Gradle child instead of starting a second build after the
   shell detached

## Current-source compile proof

The clean single build succeeded and produced:

`C:\Users\FUJITSU\Zync-QA-Compile-Proof-no-google-20260928.apk`

This proved the current source tree compiles into an installable QA APK.

The compile-proof build intentionally did not inject a fake Google client ID.

## Google-configured current QA APK

The repository's actual non-secret Google Web/server client ID was retrieved from
the existing GitHub repository variable:

`ZYNC_GOOGLE_SERVER_CLIENT_ID`

Value used:

`809680073916-4a0girebokh8qdqqho1jr92b74vov7on.apps.googleusercontent.com`

A second clean, single incremental build succeeded with that real server client
ID and produced:

`C:\Users\FUJITSU\Zync-QA-Google-Current-20260928.apk`

Artifact facts:

- size: 223,348,621 bytes
- package: `com.gmail.gentle3f.myproject.qa`
- label: `Zync QA Local`
- versionCode: 6
- versionName: 1.0.0
- minSdk: 24
- targetSdk: 36
- compileSdk: 36
- APK Signature Scheme v2: verified
- signer: Android Debug
- signer certificate SHA-1:
  `10:F4:27:CD:6E:CF:A5:38:0C:E3:3B:A5:0F:63:98:37:FB:69:8B:A8`
- signer certificate SHA-256:
  `DF:1E:4D:C9:9C:C8:07:AE:4D:8A:F8:33:D3:4B:7E:D8:44:4E:C0:61:21:69:48:73:EA:3B:6A:CF:DC:11:F8:9D`
- APK SHA-256:
  `EA731AD3076C0ED60D3BAFBC58D5D22903976AF9903F237588A45D23778F5146`

The actual APK was inspected and the Google server client ID was found inside:

`assets/flutter_assets/kernel_blob.bin`

so the final artifact is genuinely built with the current Google server-client
configuration rather than merely relying on the command line used to invoke the
build.

## Google Android OAuth gate

Google sign-in still requires the Android OAuth client to match both:

- package:
  `com.gmail.gentle3f.myproject.qa`
- signer SHA-1:
  `10:F4:27:CD:6E:CF:A5:38:0C:E3:3B:A5:0F:63:98:37:FB:69:8B:A8`

Whether this exact package/SHA-1 pair is already registered in Google Cloud has
not been verified.

No Android device was attached during this work:

`adb devices` returned no devices.

Therefore no chooser-return, Cardverse session, provider-link or reward-loop
physical-device smoke is claimed yet.

## Signing state

Repository variables currently include the Google server client ID.

Repository secret names currently show only:

- `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`

The signing secrets expected by the existing signed-release workflow are not
currently configured under their expected names:

- `ZYNC_ANDROID_KEYSTORE_BASE64`
- `ZYNC_ANDROID_STORE_PASSWORD`
- `ZYNC_ANDROID_KEY_ALIAS`
- `ZYNC_ANDROID_KEY_PASSWORD`

So the current APK is debug-signed. It is suitable for compile/install testing,
but it is not the final stable QA/release signing setup.

## Status change

The old release gate:

**local Android APK compile proof**

is now **CLOSED**.

Remaining Android gates:

1. stable QA signing strategy/secrets
2. Android OAuth client registration for the chosen stable QA signer SHA-1
3. stable signed QA APK
4. physical Android Google chooser-return/session smoke
5. physical reward/reveal/provider-link smoke

No GitHub Actions, Vercel, Play, production deployment or paid generation was
used.

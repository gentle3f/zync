# Zync — Reproducible Mobile Packaging + iOS Foundation

Date: 2026-09-28
Branch: `card-art-pilot-v1-20260921`
Starting HEAD: `7bc9964`

## Why this became the next mainline task

After the reward-reveal fix, the next product-level risk was native packaging rather
than another Card FX micro-tune. Zync intentionally keeps the Flutter app under
`mobile/` and generates disposable native wrappers instead of committing long-lived
Android/iOS project trees.

The old Android wrapper steps copied `lib/`, `test/`, `pubspec.yaml` and
`l10n.yaml`, but **not `mobile/assets/`**. That became a real release regression
once Card FX added locked frame PNGs and bundled reveal/rarity SFX. A fresh APK
built by those old steps could be incomplete or fail.

At the same time, iOS had no reproducible packaging/identity foundation.

## Shared native-wrapper architecture

Added:

`mobile/tool/generate_mobile_wrapper.py`

This is now the common generated-wrapper entry point for Android and iOS. It:

- runs `flutter create` for the requested native platform
- copies `mobile/lib/`
- copies `mobile/test/`
- copies **`mobile/assets/`**
- copies `mobile/pubspec.yaml`
- copies `mobile/l10n.yaml`
- resolves `flutter.bat` correctly on Windows
- uses bounded retry cleanup for the short-lived Windows template file-handle race

Fresh Android and iOS probes both contain the locked Legendary frame and
Legendary rarity SFX.

## Android packaging repair

The existing Android workflows now use the shared generator:

- `.github/workflows/zync-google-auth-diagnostic.yml`
- `.github/workflows/zync-qa-preview-build.yml`
- `.github/workflows/zync-v1-ci.yml`
- `.github/workflows/zync-v1-signed-release.yml`

Representative Card FX frame/SFX files are explicitly checked in the QA/CI/release
build trees so future wrapper changes cannot silently omit them.

Added:

`mobile/tool/apply_android_variant_identity.py`

It reproducibly applies Android QA/diagnostic package IDs and labels and replaces
the duplicated inline workflow Python that previously patched those fields.

Fresh generated Android validation:

- Zync Android branding: PASS
- existing Credential Manager Google bridge self-test: PASS
- generated-template Google bridge check: PASS
- QA package/label variant self-test: PASS
- Card FX frame/SFX asset copy: PASS

### Current APK truth

A current-source local QA wrapper was generated at:

`C:\Users\FUJITSU\zync_android_qa_local_20260928`

with package `com.gmail.gentle3f.myproject.qa`, Zync QA branding, the Android
Credential Manager bridge, and the full asset bundle.

The first local debug build reached Gradle but failed only after the C: drive fell
to roughly 64 MB free; `processDebugMainManifest` and `compressDebugAssets`
both threw `java.io.IOException` during the same disk-exhaustion event. Disposable
probe build artifacts created during this work were removed, freeing several GB,
and a second incremental build was started from the latest source.

Do **not** describe this local debug build as the real Google-auth QA release even
when it compiles. The production QA gate still requires a stable QA signing
certificate and its SHA-1 registered with the Google Android OAuth client.

## iOS packaging foundation

Added:

`mobile/tool/apply_ios_branding.py`

It makes the generated iOS wrapper reproducible:

- display name: Zync
- bundle identity baseline: `com.gmail.gentle3f.myproject`
- minimum iOS target: 15.0
- camera permission copy for QR scanning
- deterministic complete iPhone/iPad/App Store AppIcon set
- deterministic LaunchScreen image/background
- same cream + orange/plum linked-ring geometry as Android
- Python stdlib-only image generation; no Pillow/Photoshop/Canva dependency

Validated examples:

- App Store icon: 1024x1024
- 3x LaunchImage: 504x555

## Final iOS Google identity design

The final implementation deliberately **does not** put a custom Google
MethodChannel into AppDelegate.

iOS uses the official Flutter `google_sign_in_ios 6.3.5` plugin directly from
Dart. The installed plugin source was inspected locally and supports a per-sign-in
nonce through `InitParameters(nonce: ...)`; its native implementation forwards
that nonce into Google Sign-In.

This keeps Cardverse's security contract unchanged:

1. Cardverse server issues a one-time Google challenge nonce.
2. Dart initializes the iOS Google plugin with:
   - the dedicated iOS OAuth client ID
   - the Web/server OAuth client ID
   - the exact Cardverse challenge nonce
3. Google returns an ID token containing the nonce.
4. Cardverse verifies the token and consumes the one-time challenge.

Android continues to use the existing Credential Manager MethodChannel bridge.
Web/Chrome remains explicitly unsupported for Google identity.

Modified:

`mobile/lib/core/google_identity_bridge.dart`

Added:

- `IosGoogleIdentityClient`
- `PluginIosGoogleIdentityClient`
- `GoogleIdentityRuntime.nativeIosBridgeAvailable`
- `GoogleIdentityRuntime.iosClientConfigured`
- `GoogleIdentityRuntime.nativeGoogleLinkAvailable`
- compile-time `ZYNC_GOOGLE_IOS_CLIENT_ID`

Dependencies:

- `google_sign_in_ios: ^6.3.5`
- `google_sign_in_platform_interface: ^3.1.0`

The production account screen and Account Lab now treat correctly configured
native Android and iOS builds as supported and keep web fail-closed.

## iOS native Google metadata

Added:

`mobile/tool/apply_ios_google_identity.py`

The generated iOS wrapper keeps Flutter's default AppDelegate and
`GeneratedPluginRegistrant`. The tool only configures the native metadata the
official plugin needs:

- `GIDClientID`
- reversed Google client URL scheme

Template validation explicitly rejects reintroducing a custom AppDelegate Google
bridge and confirms the `google_sign_in_ios` dependency is present.

A dummy syntactically valid iOS OAuth client ID was used only for local template
validation; no claim is made that production iOS OAuth has been configured.

## iOS compile-smoke gate

Added:

`.github/workflows/zync-ios-compile-smoke.yml`

It is **workflow_dispatch only**. It has no push or pull-request trigger and was
not run.

When deliberately run later on a macOS runner it will require separate:

- `ZYNC_GOOGLE_SERVER_CLIENT_ID`
- `ZYNC_GOOGLE_IOS_CLIENT_ID`

It rejects reusing the Web/server client as the iOS client, then:

1. generates the iOS wrapper
2. applies branding + Google metadata
3. verifies representative Card FX assets
4. runs pub get / gen-l10n / analyze
5. runs shared Google identity tests
6. compiles `flutter build ios --release --no-codesign`
7. uploads an unsigned compile-smoke app archive

No Apple signing, TestFlight or App Store action is performed.

## Fresh final iOS probe

A fresh generated wrapper at:

`C:\Users\FUJITSU\zync_ios_final_probe_20260928`

completed:

- wrapper generation: PASS
- branding: PASS
- Google metadata/template check: PASS
- default Flutter AppDelegate preserved: PASS
- Card FX assets present: PASS
- pub get / gen-l10n: PASS
- generated-wrapper analyze: no errors or warnings; 9 INFO-only lints from the
  default Flutter template lint profile
- shared Google/Cardverse identity tests: **7 / 7 PASS**

Repo-level targeted identity/account analyze is clean.

## Cardverse Apple readiness discovery

Without switching away from the current branch, the backend contract on
`origin/zync-v1-rebuild-20260917` was inspected.

Cardverse already supports an `apple` identity provider:

- ownership store accepts Google + Apple
- session/challenge store accepts Google + Apple
- Apple issuer: `https://appleid.apple.com`
- Apple JWKS: `https://appleid.apple.com/auth/keys`
- Apple audience env: `ZYNC_APPLE_CLIENT_IDS`
- the same provider nonce claim is verified
- the same one-time challenge is consumed
- readiness already reports Apple provider configuration

Therefore the next substantial iOS authentication milestone is a nonce-safe
**Sign in with Apple mobile path + account UI**, not a backend account-model
rewrite.

## Validation status

Confirmed:

- Python packaging tool syntax/self-tests: PASS
- all 8 workflow YAML files parse: PASS
- `git diff --check`: clean
- final repo full Flutter analyze: **No issues found**
- final targeted Google/Cardverse identity tests: **7 / 7 PASS**
- fresh generated iOS identity tests: **7 / 7 PASS**
- an earlier complete non-golden regression run in this work: **360 / 360 PASS**
- the legacy full run still fails only because
  `goldens/card_art_engine_v1_flagships.png` does not exist; no baseline was
  fabricated or updated

A final non-golden rerun after the last iOS identity refactor reached 253 tests
without a failure, but its background shell ended without an exit marker and is
therefore not counted as a completed suite. The earlier complete 360/360 pass
remains the full-suite regression evidence; the final iOS identity delta itself
is covered by the clean full analyzer and dedicated 7/7 identity tests.

The second local Android debug build likewise reached `assembleDebug` after disk
space was restored, but its background shell ended without an exit marker and no
APK was emitted. It is recorded as an **incomplete local compile proof**, not a
code failure and not a successful APK build.

## Remaining release gates

Android:

1. complete a current local compile proof
2. configure the stable QA signing key/secrets
3. register the stable QA signer SHA-1 with Google Android OAuth
4. produce a current signed QA APK
5. physical Google chooser-return/session + reward-loop smoke

iOS:

1. create/configure the real Google iOS OAuth client ID
2. implement the existing Cardverse Apple provider on-device
3. deliberately run the manual macOS unsigned compile smoke when CI spend is justified
4. configure Apple signing/provisioning
5. physical iPhone smoke: QR/camera, audio, lifecycle/background return,
   identity, Single Draw and five-card reveal

Production, Google Play, App Store, Vercel and paid generation remain closed.

# Zync Mobile Build State

Date: 2026-09-28

Zync keeps its Flutter UI/business source under `mobile/`. Android and iOS
native projects are generated as disposable wrappers instead of being committed
as long-lived platform trees.

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

Copying `mobile/assets/` is mandatory because Card FX depends on locked frame
PNGs and bundled reveal/rarity SFX.

The generator handles Windows `flutter.bat` and retries transient generated-tree
cleanup races.

## Android

Android remains the more mature native packaging path.

Generated wrappers apply:

- `apply_android_branding.py`
- `apply_android_variant_identity.py` for QA/diagnostic package + label variants
- `apply_android_google_identity.py`
- signing patches where required by release workflows

Google authentication uses the existing Android Credential Manager bridge and
binds the Cardverse server's one-time challenge nonce into the Google ID-token
request.

The Android QA/CI/release workflows use the shared wrapper generator and verify
representative Card FX frame/SFX assets exist in the build tree.

A previous QA APK predates current reward/Card FX source. A current local debug
compile reached `assembleDebug` but the background shell ended without an exit
marker and emitted no APK. Local APK compile proof therefore remains open.

A true Google-auth QA APK still requires:

1. stable QA signing key/secrets
2. stable QA signer SHA-1 registered with Google Android OAuth
3. a current signed QA APK
4. physical chooser-return/session/reward-loop smoke

## iOS wrapper foundation

`apply_ios_branding.py` configures:

- Zync display/bundle name
- bundle-ID baseline `com.gmail.gentle3f.myproject`
- iOS minimum target 15.0
- camera permission copy
- deterministic iPhone/iPad/App Store icons
- deterministic cream + orange/plum linked-ring LaunchScreen

Google identity uses the official Flutter `google_sign_in_ios` plugin from Dart.
The generated AppDelegate remains Flutter-default with
`GeneratedPluginRegistrant`.

`apply_ios_google_identity.py` configures:

- dedicated iOS `GIDClientID`
- reversed Google URL scheme

Dart passes the dedicated iOS client ID, Web/server client ID and exact Cardverse
one-time nonce into every iOS Google sign-in.

## Sign in with Apple

The iOS app now has a complete source-level Apple identity path.

Dependency:

- `sign_in_with_apple: 8.2.0` (exactly pinned because the repo does not commit
  `pubspec.lock`)

New Dart identity/provider path:

- `apple_identity_provider.dart`
- `cardverse_apple_auth.dart`

The flow is:

1. request Cardverse challenge with provider `apple`
2. pass the exact server-issued nonce into Sign in with Apple
3. require a structurally valid Apple identity token
4. post provider/challenge/token to Cardverse
5. reject any challenge/auth response whose provider is not `apple`
6. save the returned Cardverse session only after validation
7. sync pending privacy-bounded proof tickets without invalidating a successful
   login if proof maintenance fails

The installed plugin's native Swift was inspected and forwards the nonce directly
with `appleIDRequest.nonce = nonce`; it does not hash or rewrite the Cardverse
challenge.

`apply_ios_apple_identity.py` makes the native capability reproducible:

- writes `ios/Runner/Runner.entitlements`
- adds `com.apple.developer.applesignin = [Default]`
- attaches the entitlements file to Debug/Release/Profile
- enables `com.apple.SignInWithApple` on the Runner target

The production Account screen now shows the official Apple button only on native
iOS. Android does not expose the Apple button. The QA Account Lab also exposes
Apple runtime/errors alongside Google diagnostics.

The Cardverse backend lineage already supports:

- provider `apple`
- issuer `https://appleid.apple.com`
- Apple JWKS
- `ZYNC_APPLE_CLIENT_IDS`
- nonce verification
- one-time challenge consumption

For native iOS, the server audience must include the real app/bundle ID used by
the signed build.

## Manual iOS compile smoke

`.github/workflows/zync-ios-compile-smoke.yml` remains
**workflow_dispatch only**.

It now also:

- applies/checks the Apple entitlement generator
- verifies `sign_in_with_apple` is bundled
- verifies the Runner entitlement/capability wiring
- runs Google + Apple identity/auth + provider-UI tests
- builds an unsigned iOS release when intentionally invoked on macOS

It was not run during this work.

## Validation

Confirmed:

- Apple identity/auth unit tests: PASS
- production provider UI regression: iOS shows Apple, Android does not
- final focused auth/session/proof regression: **21 / 21 PASS**
- final full Flutter analyze: **No issues found**
- fresh generated iOS wrapper capability checks: PASS
- fresh generated iOS wrapper final Google + Apple identity/provider UI suite:
  **16 / 16 PASS**
- all workflow YAML files parse successfully
- `git diff --check`: clean
- earlier complete non-golden regression baseline remains **360 / 360 PASS**
- legacy Card Art golden remains blocked only because
  `goldens/card_art_engine_v1_flagships.png` does not exist; do not fabricate it

## iOS release gates still closed

1. create/configure the real Google iOS OAuth client ID
2. enable Sign in with Apple for the real Apple App ID in Apple Developer
3. configure server `ZYNC_APPLE_CLIENT_IDS` for the real iOS bundle ID
4. deliberately run the manual macOS unsigned compile smoke when justified
5. configure Apple signing/provisioning
6. physical iPhone smoke:
   - Google sign-in
   - Sign in with Apple
   - QR/camera
   - app background/return lifecycle
   - audio
   - Single Draw
   - five-card Pack reveal

Production, Google Play, App Store, Vercel and paid generation remain closed.

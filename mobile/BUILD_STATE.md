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

The generator copies the complete app source surface:

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

Generated wrappers then apply:

- `apply_android_branding.py`
- `apply_android_variant_identity.py` for QA/diagnostic package + label variants
- `apply_android_google_identity.py`
- signing patches where required by release workflows

Google authentication uses the existing Android Credential Manager bridge and
binds the Cardverse server's one-time challenge nonce into the Google ID-token
request.

The Android QA/CI/release workflows now use the shared wrapper generator and
explicitly verify representative Card FX frame/SFX assets exist in the build tree.

A previous QA APK exists but predates the current reward/Card FX source. A
current local debug compile is being used only as a compile proof. A true
Google-auth QA APK still requires the stable QA signer and that signer's SHA-1
registered on the Android OAuth client.

## iOS

The iOS generated wrapper now has a real reproducible foundation.

`apply_ios_branding.py` configures:

- Zync display/bundle name
- production bundle-ID baseline
- iOS minimum target 15.0
- camera permission copy
- deterministic iPhone/iPad/App Store icons
- deterministic cream + orange/plum linked-ring LaunchScreen

Google identity uses the official Flutter `google_sign_in_ios` plugin from Dart,
not a custom AppDelegate bridge. The iOS wrapper keeps Flutter's default
`GeneratedPluginRegistrant` AppDelegate.

`apply_ios_google_identity.py` configures only:

- dedicated iOS `GIDClientID`
- reversed Google URL scheme

Dart passes three distinct values into the iOS plugin for every sign-in:

- dedicated iOS OAuth client ID
- Web/server OAuth client ID
- exact Cardverse one-time challenge nonce

Web/Chrome remains fail-closed.

A manual-only `zync-ios-compile-smoke.yml` workflow can later compile an
unsigned iOS release on a macOS runner. It has no push/PR trigger and must not be
run merely for convenience.

## Apple identity readiness

The Cardverse backend on the production-lineage branch already supports
`apple` as a provider, including Apple issuer/JWKS, `ZYNC_APPLE_CLIENT_IDS`,
nonce verification and one-time challenge consumption.

The next iOS authentication milestone is therefore Sign in with Apple on-device
plus account UI, not a backend identity-model rewrite.

## Current validation

Confirmed:

- Android generated-wrapper branding + Google bridge checks: PASS
- iOS generated-wrapper branding + Google metadata checks: PASS
- generated Android/iOS wrappers contain representative locked frame + SFX assets
- fresh generated iOS wrapper Google/Cardverse identity tests: 7 / 7 PASS
- repo targeted Google/Cardverse identity tests: 7 / 7 PASS
- full Flutter analyze: No issues found
- all workflow YAML files parse successfully
- an earlier complete non-golden regression run in this work: 360 / 360 PASS
- legacy Card Art golden remains blocked only because
  `goldens/card_art_engine_v1_flagships.png` does not exist; do not fabricate it

A final non-golden rerun after the last iOS identity refactor reached 253 tests
with no failures before the background shell ended without an exit marker; it is
not counted as a completed suite. The earlier complete 360/360 run remains the
full-suite regression evidence, and the final identity delta is covered by the
clean full analyzer plus dedicated 7/7 tests.

The second local Android debug build reached `assembleDebug` after disk space was
restored, but its background shell also ended without an exit marker and emitted
no APK. Local APK compile proof therefore remains open.

## Release gates still closed

Android:
1. current local compile proof
2. stable QA signing key/secrets
3. stable QA signer SHA-1 registered with Google Android OAuth
4. current signed QA APK
5. physical Google/session/reward-loop smoke

iOS:
1. real Google iOS OAuth client ID
2. Sign in with Apple mobile path
3. manual macOS unsigned compile smoke
4. Apple signing/provisioning
5. physical iPhone QR/camera/audio/lifecycle/identity/reveal smoke

Production, Google Play, App Store, Vercel and paid generation remain closed.

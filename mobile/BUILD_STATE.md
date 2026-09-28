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
- signing patches where required by release workflows

Google auth uses Android Credential Manager and binds the Cardverse one-time
challenge nonce into the Google ID-token request.

A fresh current-source QA wrapper now compiles successfully on GEN-FUJI.

Current installable artifact:

`C:\Users\FUJITSU\Zync-QA-Google-Current-20260928.apk`

Verified:

- package `com.gmail.gentle3f.myproject.qa`
- label `Zync QA Local`
- minSdk 24 / targetSdk 36
- APK Signature Scheme v2 valid
- real repository `ZYNC_GOOGLE_SERVER_CLIENT_ID` is embedded in the Flutter
  kernel blob
- current debug signer certificate SHA-1:
  `10:F4:27:CD:6E:CF:A5:38:0C:E3:3B:A5:0F:63:98:37:FB:69:8B:A8`
- APK SHA-256:
  `EA731AD3076C0ED60D3BAFBC58D5D22903976AF9903F237588A45D23778F5146`

The previous Gradle failures were traced to duplicate concurrent
`assembleDebug` processes racing on `mergeDebugAssets`, not a Zync compile
error. A clean single-process build succeeds.

Local APK compile proof is therefore **closed**.

A true Google-auth QA/release path still requires:

1. stable QA signing key/secrets
2. Android OAuth client registration for the chosen stable signer SHA-1
3. stable signed QA APK
4. physical chooser-return/session/reward-loop/provider-link smoke

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

1. stable QA signing
2. Android OAuth SHA-1 registration for the stable QA signer
3. stable signed QA APK
4. physical Android Google/session/reward-loop/provider-link smoke

iOS:

1. real Google iOS OAuth client ID
2. enable Sign in with Apple on real Apple App ID
3. configure server `ZYNC_APPLE_CLIENT_IDS`
4. manual macOS unsigned compile smoke
5. Apple signing/provisioning
6. physical iPhone Google/Apple/provider-link/QR/audio/lifecycle/reveal smoke

Production, Google Play, App Store, Vercel and paid generation remain closed.

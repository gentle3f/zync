# Zync — Sign in with Apple + iOS Account Path

Date: 2026-09-28
Branch: `card-art-pilot-v1-20260921`
Starting HEAD: `c8ff399`

## Why this is the next platform milestone

Zync already uses Google Sign-In to establish/restore the Cardverse primary
account. Apple App Review Guideline 4.8 requires an equivalent privacy-preserving
login option when third-party/social login is used for the primary account.
Cardverse's backend lineage already supported an `apple` identity provider, so
the correct work was to complete the iOS mobile identity path and native
capability rather than redesign accounts.

No backend, economy, RNG, Card FX, Play, App Store or production deployment was
changed.

## Dependency

Added and deliberately pinned:

`sign_in_with_apple: 8.2.0`

The repo intentionally does not commit `mobile/pubspec.lock`, so the Apple
package is pinned exactly instead of using a caret range.

The installed 8.2.0 native Swift was inspected locally. Its Apple request forwards
the supplied nonce directly:

`appleIDRequest.nonce = nonce`

It does not hash or rewrite the Cardverse challenge nonce.

## Apple identity provider

Added:

`mobile/lib/core/apple_identity_provider.dart`

Production contract:

- Zync enables Apple identity only on native iOS
- nonce must be non-empty and <= 512 chars
- the exact Cardverse server nonce is passed to Sign in with Apple
- only a structurally valid JWT-like identity token is returned
- cancellation, unavailable platform/plugin and invalid-token states map to
  explicit Zync errors
- no identity token is logged or placed in ordinary local storage

## Cardverse Apple auth

Added:

`mobile/lib/core/cardverse_apple_auth.dart`

Flow:

1. `POST /auth/challenge` with provider `apple`
2. reject if the returned challenge provider is not `apple`
3. obtain Apple identity token using the exact challenge nonce
4. `POST /auth/provider` with provider/challenge/token
5. reject if the returned auth provider is not `apple`
6. only then persist the Cardverse session
7. best-effort pending proof sync after successful login

The existing Cardverse server lineage already has:

- Apple issuer `https://appleid.apple.com`
- Apple JWKS `https://appleid.apple.com/auth/keys`
- audience env `ZYNC_APPLE_CLIENT_IDS`
- provider nonce verification
- one-time challenge consumption
- Apple ownership/session support

For a real native iOS login, the server audience must include the actual signed
app/bundle ID.

## Native Sign in with Apple capability

Added:

`mobile/tool/apply_ios_apple_identity.py`

Generated wrappers now get:

- `ios/Runner/Runner.entitlements`
- `com.apple.developer.applesignin = [Default]`
- `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements` in all three Runner
  build configurations
- Runner target `com.apple.SignInWithApple` capability metadata

The tool is idempotent, has a self-test and a generated-wrapper `--check`.

This is still not a substitute for enabling Sign in with Apple on the real Apple
Developer App ID / provisioning profile.

## Production Account UI

`CardverseAccountScreen` now:

- keeps existing Google login
- shows the package-provided official Apple button only on native iOS
- never shows Apple login on Android
- routes Apple success into the same Cardverse session/proof-sync model
- maps Apple cancellation/unavailable/plugin/token/cloud errors separately
- keeps People history/conversations local-first
- accepts an optional session-store injection only to make the real production
  provider UI testable; production default behavior is unchanged

## Account Lab

`CardverseAccountLabScreen` now exposes:

- Google + Apple one-time nonce flow
- Apple native-iOS runtime diagnostic
- Apple-specific error mapping
- server audience-not-configured diagnostics
- Sign in with Apple QA button on iOS

## Manual iOS compile smoke

Updated:

`.github/workflows/zync-ios-compile-smoke.yml`

It remains **workflow_dispatch only** and was not run.

It now additionally:

- applies and checks Apple entitlements/capability
- verifies `sign_in_with_apple` in the generated pubspec
- verifies Apple nonce wiring
- verifies Runner entitlements
- runs Google + Apple identity/auth + production provider-UI tests

## Tests

Added:

- `test/apple_identity_provider_test.dart`
- `test/cardverse_apple_auth_test.dart`
- `test/cardverse_account_provider_ui_test.dart`

Coverage includes:

- Android rejected by the Zync Apple identity contract
- exact Cardverse nonce forwarding
- empty/oversized nonce rejection
- malformed token rejection
- Apple challenge provider mismatch rejection
- Apple auth response provider mismatch rejection before session persistence
- session persistence only after a valid Apple result
- iOS signed-out production Account UI contains Apple button
- Android signed-out Account UI does not contain Apple button

## Validation

Final repo validation:

- focused auth/session/proof regression: **21 / 21 PASS**
- full `flutter analyze --no-pub`: **No issues found**
- workflow YAML parse: PASS
- `git diff --check`: clean

Fresh generated iOS wrapper:

`C:\Users\FUJITSU\zync_ios_apple_probe_20260928`

Validated:

- wrapper generation: PASS
- Zync branding: PASS
- Google metadata: PASS
- Apple entitlement/capability: PASS
- Google + Apple identity/auth + production provider UI: **16 / 16 PASS**

No macOS/Xcode compile was claimed; Windows cannot provide that final native
compile proof. The manual macOS workflow remains the deliberate compile gate.

## Remaining iOS release gates

1. create/configure the real Google iOS OAuth client ID
2. enable Sign in with Apple on the real Apple Developer App ID
3. configure server `ZYNC_APPLE_CLIENT_IDS` for the real iOS bundle ID
4. run the manual unsigned macOS compile smoke when CI spend is justified
5. configure Apple signing/provisioning
6. physical iPhone identity/lifecycle/QR/audio/reward-reveal smoke

## Best next substantial work

Two reasonable next branches of work:

- **Account provider linking / recovery:** expose Cardverse's existing provider
  link route so a player can attach Apple and Google to the same Zync World
  instead of accidentally creating separate provider-specific accounts.
- **Native release readiness:** close Android local APK compile/stable QA signing
  and prepare iOS Apple Developer/OAuth configuration for real-device smoke.

Do not return to Card FX micro-tuning without fresh user feedback.

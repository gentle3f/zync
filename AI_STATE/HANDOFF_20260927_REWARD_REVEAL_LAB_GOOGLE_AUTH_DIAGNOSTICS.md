# Zync — Reward Reveal Test Lab + Google Linking Diagnostics

Date: 2026-09-27 HKT
Branch: `card-art-pilot-v1-20260921`
Parent before this round: `664d9c3`

## Reward Reveal Test Lab

A dedicated local test entrypoint now exists:

`mobile/lib/main_reward_reveal_lab.dart`

It opens `RewardRevealTestScreen` with two direct production-presentation tests:

1. **Single Draw — 1 Card**
   - fixed immutable proof single-draw receipt;
   - no booster wrapper;
   - one card back -> Reveal -> suspense -> flip -> bloom -> rarity payoff -> real card front.

2. **Pack Opening — 5 Cards**
   - fixed immutable five-card proof pack receipt;
   - production B — Split Open;
   - layered five-card stack is visible through the first physical split;
   - full stack extracts;
   - five receipt cards reveal sequentially;
   - existing five-card recap remains the terminal state.

No account, token, unopened inventory, backend RNG or economy mutation is required.

Local Chrome endpoint used for this review:
`http://127.0.0.1:7358`

## Google linking diagnosis

Two separate conditions must not be confused.

### Chrome / Web

The current production identity provider is intentionally Android-native only.
`NativeGoogleIdentityProvider` uses the `zync/google_identity` MethodChannel and
Android Credential Manager.

Chrome/web therefore did not have an identity implementation. Previously this
could look like a generic Google failure after a server challenge had already
been created.

This round makes the platform boundary explicit:
- non-Android runtimes fail with `google_sign_in_platform_unsupported`;
- a missing generated Android MethodChannel bridge fails with
  `google_sign_in_native_bridge_missing`;
- production account UI disables the Google button when the native Android
  bridge is unavailable and explains that Chrome/web linking is not implemented;
- the QA account lab shows runtime/API/client-id/native-bridge diagnostics;
- Reward Reveal Lab also exposes the same platform-level diagnostic state.

Do not bolt on a fake web login. The current Cardverse flow binds every Google
ID token to a one-time server-issued nonce. A future web GIS implementation must
preserve that same nonce/JWT validation model.

### Android real-device historical failure

The repository's earlier forensic checkpoint remains the strongest root-cause
boundary:

- Cardverse challenge POST succeeded;
- native Google chooser opened;
- account selection completed visually;
- no Google ID token reached Flutter / no provider POST followed;
- the tested QA APK used package `com.gmail.gentle3f.myproject.qa`;
- old QA artifacts were signed by different ephemeral Android debug certificates.

Google Android OAuth requires the Android OAuth client registration to match the
app package and signing-certificate SHA-1, while the Web OAuth client remains the
server-client-ID / ID-token audience.

Therefore an Android OAuth client cannot remain valid across those old
ephemeral-signed QA builds.

The repository already contains the permanent direction:
- fail closed unless stable QA signing material exists;
- keep one stable QA package + signer;
- register that exact package + stable SHA-1 once in Google Auth Platform;
- keep the Web client ID for server token audience validation.

This round does not weaken nonce, issuer, audience, JWT signature or session
validation.

## Android wrapper review

Current official Android guidance was checked against
`mobile/tool/apply_android_google_identity.py`:

- `MutableContextWrapper` around the foreground Activity is correct current
  guidance, so the old suspicion around that context pattern is not a valid fix;
- explicit Sign in with Google uses `GetSignInWithGoogleOption`;
- fallback can request unfiltered Google accounts with `GetGoogleIdOption`;
- the wrapper uses current `googleid:1.2.1`;
- sanitized exception type/class/cause diagnostics are retained;
- token, nonce, email/account identity and bearer secrets are never logged.

No Android device/emulator is currently attached to GEN-FUJI, so no fresh
real-device credential exchange is claimed in this round.

## Validation

- focused reward + Google auth tests: PASS;
- combined reward/pack/single/Google focused run: **15 / 15 PASS**;
- latest focused Reward Lab + Google auth subset: **7 / 7 PASS**;
- targeted `flutter analyze`: **No issues found**;
- Android Google wrapper self-test: PASS;
- `git diff --check`: clean;
- local Reward Reveal Lab server responds HTTP 200 on port 7358.

## Guardrails

No GitHub Actions, Vercel, Production, Play, release, paid generation, economy,
backend schema, RNG, Cardverse receipt semantics, rarity logic, locked frames or
existing accepted Card FX tuning changed.

Pre-existing untracked generated localization output and `mobile/pubspec.lock`
remain untouched and must not be staged.

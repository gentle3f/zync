# Zync V1 — Latest Handoff

## Branch
`zync-v1-rebuild-20260917`

## Mission
Rebuild the old Thunkable Zync MVP as a modern, low-cost, international Flutter app while preserving the existing Google Play Android identity.

## Frozen V1 scope
Authoritative product scope: `docs/ZYNC_V1_PRODUCT_SPEC.md`.

Core: local interest profile, multilingual canonical-interest model, QR peer exchange, local match detection, hidden-match reveal, AI conversation questions, zero-match crossover questions, conversation modes, Zync Again history, Interest DNA, local fallback questions, Vercel/OpenRouter proxy. No login/Firebase/community/chat/location/social-import/commerce in V1.

## Existing Play compatibility
- Android applicationId: `com.gmail.gentle3f.myproject`
- Current known Play versionCode: 5
- New versionCode: >= 6 (`mobile/pubspec.yaml` is currently `1.0.0+6`)
- targetSdk / compileSdk target: 36
- Final artifact: Android AAB
- Existing keystore supplied by user separately; never commit it or its password.

## Current progress
1. Frozen product scope and established this rolling handoff.
2. Added Flutter package definition and core models: canonical interests, interest strength, local profile, compact/versioned QR payload, match result, Zync history, conversation modes.
3. Added multilingual canonical seed catalog across EN / zh-Hant / zh-Hans / JA / KO / ES / FR / PT.
4. Added local-only matching and SharedPreferences profile/history persistence.
5. Added localization generation and all eight initial UI locale files plus required base `zh` fallback for Flutter localization generation.
6. Added localized Flutter app shell and interest onboarding/editor.
7. Added home hub, local QR display, QR scanner, canonical local match, Zync Again delta detection, hidden-match reveal, zero-match path, conversation modes, AI client + multilingual local fallback, Zync history, and Interest DNA.
8. Added Vercel `POST /api/v1/question` using `OPENROUTER_API_KEY` (with legacy `API_KEY` fallback), optional `OPENROUTER_MODEL`, strict bounded request parsing, and no mutable GitHub prompt fetch.
9. Added Vercel `POST /api/v1/normalize-interest`; it translates/normalizes unknown free text into a stable English concept and derives a deterministic `custom.<sha256-prefix>` ID without a user database.
10. Added core Dart tests for QR round-trip, canonical matching, and zero-match crossover readiness.
11. Added GitHub Actions `Zync V1 CI`: generates an Android wrapper as org `com.gmail.gentle3f` / project `myproject` so package identity is `com.gmail.gentle3f.myproject`; injects camera permission; verifies version `1.0.0+6`; runs gen-l10n/analyze/test/build appbundle and uploads the AAB artifact.
12. Added CI concurrency cancellation so stale branch runs do not waste minutes.
13. Added `.gitignore` protection for env files, keystores/JKS/P12, key.properties and generated Flutter files.
14. Corrected the known invalid `FontWeight.w650` before compile.

## Current compile/CI checkpoint
- CI run #3 (`35131801550`) failed only at `flutter pub get` because Flutter requires a base `zh` ARB when both `zh_Hans` and `zh_Hant` exist.
- Fixed that evidenced issue by adding `mobile/lib/l10n/app_zh.arb` in commit `913c380bfebcc78e83f8fcafc2653f32cb51fd68`.
- Current CI run #4: `35132170500`.
- Run #4 has passed: Flutter setup, Android wrapper generation, package-identity verification, dependency install, localization generation, `flutter analyze`, and `flutter test`.
- At last check, run #4 is actively building the unsigned release AAB. Do not yet claim AAB success until build + artifact upload complete.

## Still missing / next active task
1. Finish observing CI run #4. If AAB build fails, read exact job logs and fix only evidenced errors until green.
2. Hook the existing `/api/v1/normalize-interest` endpoint into the interest picker so an unknown typed hobby can be AI-normalized, confirmed by the user, and stored locally. At present the endpoint exists but the UI only searches seed interests.
3. Improve AI request payload from raw canonical IDs to useful localized labels where appropriate.
4. Set Android display name to `Zync` in generated wrapper (current generated project label may still say `myproject`).
5. After CI green, configure signed AAB path via GitHub Secrets using the user's existing keystore; never commit keystore/password. Need verify keystore alias/password separately.
6. Document/set repository variable `ZYNC_API_BASE` to the existing Vercel deployment URL; builds with it unset deliberately fall back to local questions.
7. Only after signed build succeeds consider Play internal-test upload. Do not widen to Phase 2.

## Safety / scope guard
- `main` remains untouched. All rebuild work is on `zync-v1-rebuild-20260917`.
- Do not commit secrets, API keys, keystores or passwords.
- Do not add Firebase/accounts/community/chat/location/social import/commerce to V1.
- Keep writing mini-checkpoints here after every meaningful slice so a timeout/new chat can resume directly without rediscovery.

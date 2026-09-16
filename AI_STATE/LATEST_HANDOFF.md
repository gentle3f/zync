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

## Verified build checkpoint — FIRST GREEN AAB
- CI run #3 (`35131801550`) exposed one real issue: Flutter requires base `zh` ARB when `zh_Hans` + `zh_Hant` exist.
- Fixed with `mobile/lib/l10n/app_zh.arb` in commit `913c380bfebcc78e83f8fcafc2653f32cb51fd68`.
- CI run #4: `35132170500` — **SUCCESS**.
- Verified success stages: Flutter setup; Android wrapper generation; exact package identity verification; dependency install; `flutter gen-l10n`; `flutter analyze`; `flutter test`; release AAB build; artifact upload.
- Artifact: `zync-v1-unsigned-aab`, artifact id `10461389685`, 60,292,860 bytes, digest `sha256:c95a3ed56cdae738925b578ab7a59f28f0d6347009afcdd2befb15554a80e900`, expires 2026-09-30.
- This proves the current V1 source compiles and produces an Android App Bundle. It is not yet the production-signed Play upload artifact.

## Still missing / next active task
1. Hook `/api/v1/normalize-interest` into the interest picker for unknown typed hobbies, with user confirmation and durable local label/category storage so custom interests remain readable after restart/QR exchange.
2. Improve AI question payload from opaque canonical IDs to useful localized labels while retaining canonical IDs for matching.
3. Set Android display name to `Zync` in generated wrapper and assert target/compile SDK 36 in CI rather than relying only on current Flutter template defaults.
4. Configure production signing via GitHub Secrets using the user's existing keystore; never commit keystore/password. Need verify keystore alias/password separately.
5. Document/set `ZYNC_API_BASE` repository variable to the existing Vercel deployment URL; with it unset the app deliberately falls back to local questions.
6. Only after signed build succeeds consider Play internal-test upload. Do not widen to Phase 2.

## Safety / scope guard
- `main` remains untouched. All rebuild work is on `zync-v1-rebuild-20260917`.
- Do not commit secrets, API keys, keystores or passwords.
- Do not add Firebase/accounts/community/chat/location/social import/commerce to V1.
- Keep writing mini-checkpoints here after every meaningful slice so a timeout/new chat can resume directly without rediscovery.

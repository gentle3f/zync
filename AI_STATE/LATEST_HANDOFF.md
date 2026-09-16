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
- New versionCode: >= 6 (`mobile/pubspec.yaml` currently `1.0.0+6`)
- targetSdk / compileSdk: explicitly pinned and CI-asserted at 36
- Android display label: explicitly set and CI-asserted as `Zync`
- Final artifact: Android AAB
- Existing keystore supplied by user separately; never commit it or its password.

## Implemented V1 surface
1. Frozen product scope in `docs/ZYNC_V1_PRODUCT_SPEC.md`.
2. Flutter project definition, Material 3 app shell and local-first architecture.
3. Canonical interest model with `love` / `like` / `wantToTry` strengths.
4. Multilingual seed catalog across EN / zh-Hant / zh-Hans / JA / KO / ES / FR / PT.
5. Local-only profile + Zync history persistence with SharedPreferences.
6. Interest onboarding/editor, home hub, QR display, QR scanner, canonical local matching, Hidden Match reveal, zero-match path, conversation modes, Zync Again history, and Interest DNA.
7. Vercel `POST /api/v1/question` using server-side `OPENROUTER_API_KEY` (legacy `API_KEY` fallback), optional `OPENROUTER_MODEL`, bounded request parsing, and no mutable prompt fetch.
8. Multilingual local question fallback when API is missing/unavailable.
9. Vercel `POST /api/v1/normalize-interest`, which normalizes arbitrary free text into a stable English concept and deterministic `custom.<sha256-prefix>` ID without any user database.
10. Free-text interest UI is now wired to normalization: unknown typed interests can be AI-normalized, shown for user confirmation, added locally, assigned a strength, persisted, carried through QR, matched canonically, revealed with a readable label, included in Interest DNA, and sent to question generation as a readable label rather than an opaque ID.
11. `SelectedInterest` now preserves optional custom label/category in local JSON and backward-compatible variable-length QR interest tuples; QR schema remains version 1 for existing seed payloads.
12. `.gitignore` protects env files, keystores/JKS/P12, key.properties and generated Flutter files.

## Verified build history
### First green AAB
- CI run #4: `35132170500` — SUCCESS.
- Passed wrapper generation, exact package-ID check, pub get, gen-l10n, analyze, tests, release AAB build and artifact upload.
- Artifact id `10461389685`; digest `sha256:c95a3ed56cdae738925b578ab7a59f28f0d6347009afcdd2befb15554a80e900`.

### Current feature-validation run
- Latest branch head at this checkpoint: `e8cf6cf78955bc92803d99847426317fcc095c68`.
- Current CI run #15: `35133352150`.
- It has already PASSED: Flutter setup, generated Android wrapper, explicit Play identity + SDK 36 + display-name verification, dependency install, localization generation, `flutter analyze`, and `flutter test`.
- At last check, release AAB build is still IN PROGRESS. Do not claim this latest free-text slice fully green until AAB build + artifact upload complete.
- CI concurrency cancellation is active; older runs created during sequential commits can safely appear cancelled.

## Immediate next active task
1. Finish observing CI run #15; if AAB build fails, inspect exact logs and fix only evidenced errors until green.
2. After #15 is green, add regression tests for custom-interest QR metadata round-trip and custom shared-match label preservation.
3. Add the four new custom-interest UI strings to JA / KO / ES / FR / PT rather than relying on fallback English.
4. Discover or obtain the production Vercel base URL and set repository variable `ZYNC_API_BASE`; it is currently unset in CI, so built apps deliberately use local question fallback and cannot AI-normalize unknown interests until configured.
5. Configure production signing through GitHub Secrets using the user's existing keystore; GitHub connector cannot safely write secrets. Need keystore alias/password handled outside source control.
6. Only after signed build succeeds consider Play internal testing. Do not widen into Phase 2.

## Safety / scope guard
- `main` remains untouched. All work is on `zync-v1-rebuild-20260917`.
- Never commit secrets, API keys, keystores or passwords.
- Do not add Firebase/accounts/community/chat/location/social import/commerce to V1.
- Keep updating this file after meaningful slices so timeout/new chat can resume without rediscovery.

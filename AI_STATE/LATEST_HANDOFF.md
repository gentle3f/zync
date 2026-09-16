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
- New versionCode: >= 6
- targetSdk / compileSdk target: 36
- Final artifact: Android AAB
- Existing keystore supplied by user separately; never commit it or its password.

## Existing repository facts
- Repo: `gentle3f/zync`
- Existing legacy Vercel API files under `api/` call OpenRouter with server-side `process.env.API_KEY`.
- Legacy `main` must remain untouched while rebuilding.

## Current progress
1. Created branch `zync-v1-rebuild-20260917` from `main`.
2. Froze V1 product scope in `docs/ZYNC_V1_PRODUCT_SPEC.md`.
3. Added durable handoff before implementation.
4. Added `mobile/pubspec.yaml` at version `1.0.0+6` with Flutter/localization/HTTP/QR/scanner/local-storage dependencies.
5. Added core domain models in `mobile/lib/core/models.dart`: interest strength, canonical definitions, local profile, compact/versioned QR payload, match result, local Zync history, conversation modes.
6. Added multilingual seed interest catalog in `mobile/lib/core/interest_catalog.dart` with canonical IDs and labels/aliases across the initial eight target locales.
7. Added exact canonical-ID local matching in `mobile/lib/core/matching_service.dart`.
8. Added local-only profile + Zync Again history persistence in `mobile/lib/core/local_store.dart` using SharedPreferences. No account/database/server storage introduced.

## Current implementation checkpoint
The durable data layer now exists. No UI/QR scanner/API V1 endpoint/CI has been added yet. Nothing has been merged into `main`.

## Next implementation sequence
1. Add localization files and app shell.
2. Add onboarding / interest selection / home UI.
3. Add QR show + scan using compact payload.
4. Add hidden-match reveal + Zync Again delta detection.
5. Add conversation UI + local fallback question engine.
6. Add V1 Vercel `/api/v1/question` and `/api/v1/normalize-interest` endpoints using server-side OpenRouter env vars.
7. Add tests.
8. Add GitHub Actions that generates an Android wrapper with package `com.gmail.gentle3f.myproject`, runs analyze/test, and builds an unsigned AAB.
9. Iterate on CI failures until green; only then prepare signed-release path.

## Safety / scope guard
Do not widen into Phase 2. Do not commit secrets, keystores, API keys, or passwords. Update this handoff after every meaningful implementation slice.
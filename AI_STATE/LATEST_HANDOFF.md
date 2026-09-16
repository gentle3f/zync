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
3. Created this durable handoff before implementation to protect against chat/session timeout.

## Next implementation sequence
1. Add Flutter project skeleton under `mobile/` with package/application identity locked to `com.gmail.gentle3f.myproject` and version `1.0.0+6`.
2. Add core domain models and seed interest catalog.
3. Add local persistence and matching services.
4. Add onboarding/interests/home UI.
5. Add QR encode/show/scan.
6. Add hidden-match reveal + conversation UI.
7. Add V1 Vercel endpoints for OpenRouter, validated schemas, no runtime mutable-prompt fetch from `main`.
8. Add localization architecture and initial translations.
9. Add tests + GitHub Actions analyze/test/build.
10. Iterate on CI failures until green; only then prepare signed-release path.

## Safety / scope guard
Do not widen into Phase 2. Do not commit secrets, keystores, API keys, or passwords. Update this handoff after every meaningful implementation slice.
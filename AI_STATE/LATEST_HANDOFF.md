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
- Legacy `main` remains untouched; all rebuild work is on this branch.

## Current progress
1. Frozen product scope in `docs/ZYNC_V1_PRODUCT_SPEC.md` and established this rolling handoff.
2. Added Flutter package definition `mobile/pubspec.yaml` at `1.0.0+6`.
3. Added core models, compact/versioned QR payload, local matching, local profile/history storage, and multilingual canonical seed catalog.
4. Added localization generation config and all eight initial locale files: English, Traditional Chinese, Simplified Chinese, Japanese, Korean, Spanish, French, Portuguese.
5. Added localized app bootstrap in `mobile/lib/main.dart` + `zync_app.dart`.
6. Added interest onboarding/editor with search, canonical seed interests and love/like/want-to-try strength.
7. Added V1 home hub.
8. Added QR display using local compact profile payload.
9. Added QR scanner using `mobile_scanner`; scan decodes locally, compares canonical IDs locally, detects Zync Again deltas, and records only local history.
10. Added hidden-match reveal screen, including zero-exact-match path to conversation rather than a dead end.
11. Added conversation modes + Vercel AI client with a multilingual local fallback question engine when API is missing/unavailable.
12. Added local Zync history and descriptive Interest DNA screens.

## Current implementation checkpoint
The first end-to-end app source path now exists in code: interests -> home -> show/scan QR -> local match -> hidden reveal -> conversation. It has NOT yet been compiled, so syntax/package API issues may remain and must be caught by CI. V1 Vercel endpoints and GitHub Actions are still pending. Free-text AI normalization UI is also pending.

## Immediate next steps
1. Add `/api/v1/question` Vercel endpoint with strict request validation and server-side OpenRouter key/model env vars.
2. Add `/api/v1/normalize-interest` endpoint and then hook unknown free-text interest input to it.
3. Add focused Dart tests for QR round-trip + matching.
4. Add GitHub Actions that creates the Android platform wrapper with org `com.gmail.gentle3f` / project `myproject`, copies this source, verifies package identity, runs `flutter gen-l10n`, `flutter analyze`, `flutter test`, and builds an unsigned AAB.
5. Inspect CI errors and iterate until green.
6. Once green, document signing with GitHub Secrets / existing keystore without committing secrets.

## Known items to verify during CI
- Flutter version compatibility for `CardThemeData`, `Color.withValues`, `mobile_scanner` API, ARB locale naming, generated localization import path, and any Dart analyzer warnings.
- Conversation screen currently contains a `FontWeight.w650` usage that should be corrected if analyzer rejects it.
- Android camera permission must be present in generated wrapper before release build.

## Safety / scope guard
Do not widen into Phase 2. Do not commit secrets, keystores, API keys, or passwords. Update this file after every meaningful implementation slice so a timeout/new chat can resume immediately.
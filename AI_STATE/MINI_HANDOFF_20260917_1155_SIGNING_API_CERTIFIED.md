# Zync V1 mini handoff — signing/API certification

Timestamp context: 2026-09-17 around 11:55 HKT. Branch: `zync-v1-rebuild-20260917`. Do not rediscover the repository; continue from `AI_STATE/LATEST_HANDOFF.md` plus this delta.

## What changed since the previous handoff

The previously referenced CI #63 (`35178685334`) was cancelled during the unsigned AAB build because newer pushes superseded it. Importantly, before cancellation it had already passed the release-signing configurator self-test, wrapper generation, legacy Play identity checks, dependency install, localization generation, `flutter analyze`, and all Flutter tests. The cancellation is therefore not evidence of a code failure.

The authoritative newer validation is CI #67 (`35178975781`) on branch-head commit `b5bef09bf193d47a7838742c5c283155070a9a06`, and it is **SUCCESS**.

CI #67 passed all of the following:
- Flutter/toolchain setup;
- JavaScript syntax validation for legacy API files and both V1 serverless endpoints;
- `mobile/tool/configure_android_signing.py --self-test`;
- generated Android wrapper with preserved Play identity;
- signing-patch compatibility check against the current generated Flutter Android template;
- Play identity / Android requirement assertions;
- Flutter dependencies;
- localization generation;
- `flutter analyze`;
- all Flutter tests;
- unsigned release AAB build;
- AAB artifact upload.

Therefore the signing-preparation tooling and its integration into normal CI can now be considered **certified**. This does NOT mean a production-signed AAB exists yet; the real four GitHub Secrets are still required before running the manual signed-release workflow.

## Release secrets still required

Never commit or expose these values in source:
- `ZYNC_ANDROID_KEYSTORE_BASE64`
- `ZYNC_ANDROID_STORE_PASSWORD`
- `ZYNC_ANDROID_KEY_ALIAS`
- `ZYNC_ANDROID_KEY_PASSWORD`

Do not run the signed-release workflow merely to prove that missing secrets fail.

## Vercel/API status

The V1 app and API code are present and syntax-valid. The GitHub CI now watches all `api/**`, not only `api/v1/**`, and syntax-checks `api/generate.js`, `api/generate1.js`, `api/generate2.js`, `api/v1/question.js`, and `api/v1/normalize-interest.js`.

The connected Vercel tool currently exposes no teams/projects, so the production base URL still cannot be discovered from the connector. `ZYNC_API_BASE` therefore remains an external/account configuration blocker. Do not guess the URL.

## Recommended next active slice

Without needing secrets or the production Vercel URL, the best next hardening task is **serverless behavioral contract testing**, not more syntax-only checking. Add dependency-free CI tests that exercise the V1 handlers with mocked request/response/fetch/env and cover at minimum:
- method validation;
- missing-interest validation;
- missing API-key behavior;
- same-language question response;
- bilingual separator parsing and invalid bilingual response rejection;
- normalization request bounds;
- stable deterministic custom canonical ID behavior;
- category allow-list fallback to `other`;
- upstream failure handling;
- no API secret echoed in output.

After that, continue release readiness work that does not require external credentials. Real-device QA and real Vercel/OpenRouter integration remain blockers that cannot be honestly certified from CI alone.

# Zync V1 — Authoritative Handoff: Analytics Certified / Release Integration

Date: 2026-09-17
Branch: `zync-v1-rebuild-20260917`
Repository: `gentle3f/zync`

## 0. Resume rule

Read `AI_STATE/LATEST_HANDOFF.md` first, then this file in full. Continue directly from **Recommended continuation order** below. Do not restart repository discovery, re-plan V1, or reopen old Thunkable archaeology. Keep mini-handoffs frequent because chat streams may disappear around ~25m40s; durable state belongs in GitHub.

This file supersedes status fields in `AI_STATE/HANDOFF_20260917_ZYNC_V1_RELEASE_READINESS.md` while retaining it and all older mini-handoffs as audit lineage.

## 1. Frozen product/release guardrails remain unchanged

- V1 is a local-first two-person social icebreaker built around hidden shared interests and conversation.
- No login/account, Firebase profile, cloud profile sync, feed, friends/follows, chat, community, location/nearby, activity matching, merchant/ads/payment/subscription, dating or career matching.
- Group Zync remains V1.1-capable and must not delay V1.
- Android applicationId remains `com.gmail.gentle3f.myproject`.
- Existing known Play versionCode: `5`; rebuild version: `1.0.0+6`.
- targetSdk/compileSdk: `36`.
- Final Play artifact: AAB.
- Work only on `zync-v1-rebuild-20260917`; do not touch `main`.

## 2. Previously certified product surface remains intact

Implemented/certified before this handoff:

- professional Zync visual system and Android branding;
- local canonical interest profile + strengths;
- free-text AI normalization with confirmation;
- eight initial locales;
- adaptive legacy/compressed QR transport;
- scanner recovery UX;
- local canonical matching + Hidden Match reveal;
- zero-match crossover path;
- conversation modes + local fallback;
- true bilingual semantic-question rendering;
- Zync Again local history;
- Interest DNA;
- hardened Vercel/OpenRouter question/normalization handlers;
- release-signing preparation and manual signed-release workflow.

Historical certification remains recorded in the previous authoritative handoff, including CI #41, #61, #67 and #71.

## 3. Android signing documentation drift — fixed

`docs/ANDROID_RELEASE_SIGNING.md` now correctly states:

- normal development/ordinary CI may build with empty `ZYNC_API_BASE` and rely on local fallback;
- production signed release requires a real non-empty HTTPS `ZYNC_API_BASE`;
- production signed release also requires all four real Play upload-key secrets;
- signed release should not be run until both are configured.

Fix commit: `46b05d8663afaba99f839a6dd84c48072e539788`.

Required signing secrets remain:

- `ZYNC_ANDROID_KEYSTORE_BASE64`
- `ZYNC_ANDROID_STORE_PASSWORD`
- `ZYNC_ANDROID_KEY_ALIAS`
- `ZYNC_ANDROID_KEY_PASSWORD`

Never commit/log/paste keystore material or replace the existing Play upload key merely to make CI green.

## 4. Privacy-light V1 analytics — implemented and certified

The frozen analytics gap from the previous handoff is now closed in code and tests.

### Mobile analytics client

File: `mobile/lib/core/analytics_service.dart`.

Behavior:

- uses existing `ZYNC_API_BASE`; no third-party Flutter analytics SDK/native integration;
- creates a separate random anonymous analytics install UUID in SharedPreferences;
- does not reuse the user/peer local profile ID;
- creates a memory-only session UUID per app process;
- best-effort delivery with short timeout;
- analytics failure never blocks the local-first product;
- event names are allowlisted;
- client properties are pre-filtered before sending.

### Instrumented frozen V1 events

Implemented:

- `app_open`
- `interest_setup_complete`
- `interest_added`
- `qr_generated`
- `qr_scanned`
- `match_complete`
- `match_count`
- `question_generated`
- `question_next`
- `mode_selected`
- `zync_again`

Instrumentation locations cover app boot, onboarding/editor additions, one-time QR generation lifecycle, valid QR decode/match completion/repeat-peer detection, and conversation generation/mode/next-question flow.

`qr_generated` is lifecycle-based rather than emitted from repeated widget `build()` calls.

Conversation mode switching is disabled while a question request is in flight, preventing a stale request/result from being displayed under a newly selected mode.

### Server-side analytics privacy relay

Endpoint: `POST /api/v1/analytics`.

Behavior:

- strict event allowlist;
- per-event property schema/allowlist;
- validates anonymous UUID-like install/session identifiers;
- clamps numeric counts and validates enums/locales;
- does not accept/forward raw/canonical interest content, nickname, peer ID, QR body, precise location, email, phone, account token or advertising ID;
- no client IP/User-Agent is deliberately forwarded as event data;
- optional PostHog relay using Vercel environment variables `POSTHOG_PROJECT_API_KEY` + HTTPS `POSTHOG_HOST`;
- sends `$process_person_profile: false`;
- bounded upstream timeout;
- stable 400/503/502 errors;
- app ignores analytics failures by design.

### Analytics documentation

`docs/ZYNC_V1_ANALYTICS.md` documents:

- exact collected event/property contract;
- prohibited data;
- provider configuration;
- privacy/retention implications;
- metric limitations.

Important limitation: V1 does **not** implement or pretend to implement causal invitation -> install attribution. QR generation/scanning/completion can be measured, but a true second-person installation attribution loop is not proven by these events alone.

### Tests / quality gates

Mobile:

- `mobile/test/analytics_service_test.dart` protects client-side privacy allowlisting/sanitization.

Serverless:

- `.github/scripts/serverless_contracts.mjs` now includes analytics method/event/identity validation, missing-provider behavior, strict privacy stripping, locale/count normalization and upstream failure behavior.
- Tests explicitly prove that fields such as `interest_name`, `canonical_interest_id`, `peer_id` and `nickname` are not forwarded even if present in an incoming request.

CI/release workflows:

- normal CI syntax-checks `api/v1/analytics.js` and runs the expanded contracts;
- signed-release workflow also runs serverless syntax/contracts before Flutter build/signing.

## 5. Analytics certification checkpoint — green

Authoritative analytics code/test certification:

- CI: #81
- run id: `35183238663`
- head commit: `ddf42c02f9ff8d28760453efcdb67b3881a98f6f`
- conclusion: **SUCCESS**

All recorded steps passed:

- serverless JavaScript syntax;
- V1 serverless contract tests;
- release-signing configurator self-test;
- generated Android signing-template compatibility;
- Play identity / Android requirement checks;
- dependency install;
- localization generation;
- `flutter analyze`;
- all Flutter tests;
- unsigned release AAB build;
- artifact upload.

Artifact:

- id: `10481650493`
- name: `zync-v1-unsigned-aab`
- size: `60,827,864` bytes
- digest: `sha256:ddf1f24ba1e530c5cb026d6c554376bfa989ab7dd73ad47938dfd19df9088b0d`
- expires: 2026-10-01

Documentation-only commits after the certified code include:

- `2d16474d28ff609ece53059b8edfa7a904a2dae9` — analytics contract/privacy documentation;
- `110bdcc751918c50a6ebf35b559d6925d0376555` — analytics CI-progress mini-handoff.

They do not invalidate the CI #81 executable-code certification.

## 6. Current real release blockers

The main remaining blockers are now external integration/device evidence, not the previously missing analytics implementation.

### A. Production Vercel/API origin

Need the actual deployed production origin for Zync and repository variable:

`ZYNC_API_BASE=https://<actual-production-origin>`

Do not guess the URL and do not assume the OpenRouter HTTP-Referer placeholder is the deployed API origin.

After discovering/configuring the real origin, live-smoke at minimum:

- `POST /api/v1/question`
- `POST /api/v1/normalize-interest`
- `POST /api/v1/analytics` when analytics provider config exists

Verify success and stable failure/fallback behavior.

Analytics provider configuration is optional for internal-device QA; missing analytics must not block core Zync.

### B. Real Play upload-key secrets

Need all four real GitHub Actions secrets listed above. Use the existing accepted upload key or Play Console upload-key reset process if unavailable. Do not invent a new unrelated key.

### C. Signed production AAB

Only after production `ZYNC_API_BASE` + real signing secrets exist:

- run **Zync V1 Signed Release** on `zync-v1-rebuild-20260917`;
- require workflow success;
- require `jarsigner -verify -strict` success;
- record signed artifact ID/digest in durable state.

### D. Real-device QA

Still physically verify before Play internal testing:

- launcher icon and splash continuity;
- onboarding ordinary/small phones and keyboard behavior;
- camera grant/deny/retry;
- scanner focus/framing in real lighting;
- small legacy QR device-to-device;
- large compressed QR device-to-device;
- zero-match AI crossover;
- same-language AI question;
- two-device bilingual flow, e.g. zh-Hant + Japanese;
- long translated text on small Android;
- AI timeout/local fallback presentation;
- Hidden Match animation/haptic feel.

CI/widget tests do not certify camera optics or real-device feel.

## 7. Analytics provider note

The current relay is designed for optional PostHog Product Analytics configuration without adding a mobile SDK. Provider setup is not required to preserve the product flow; analytics silently degrades if not configured.

Do not widen this into replay, autocapture, profiles, location or a general data warehouse project. V1 analytics exists only to validate coarse product behavior while keeping hobby/profile content local.

## 8. Recommended continuation order

Continue in this order unless the user supplies signing/device evidence first:

1. Discover/confirm the actual production Vercel project/origin; do not guess.
2. Configure/confirm `ZYNC_API_BASE` and live-smoke the V1 question + normalize endpoints; smoke analytics only if provider env is configured.
3. Confirm real Play upload-key GitHub Secrets exist.
4. Run and certify **Zync V1 Signed Release** only when #2 + #3 are ready.
5. Perform real-device QA and log evidence/results in `AI_STATE`.
6. Only after signed artifact + real-device QA should Play internal testing be considered.
7. Do not widen into Phase 2.

If external Vercel/signing access remains unavailable, do not fake success. Record the exact blocker and continue with any release-readiness work that does not require those credentials/devices.

## 9. Safety/branch guardrails

- Work only on `zync-v1-rebuild-20260917` unless explicitly changed.
- Do not touch `main`.
- Never commit API secrets, Vercel secrets, PostHog keys, keystores, passwords, `key.properties` or secret base64 blobs.
- Do not run production signed release merely to demonstrate missing secrets fail.
- Do not invent a Vercel production URL.
- Do not replace the Play upload key with a random key.
- Do not remove local AI fallback.
- Do not regress legacy QR compatibility.
- Keep professional UI/UX/graphics as a release requirement.
- Keep mini-handoffs frequent.

## 10. Durable lineage retained

Keep, do not delete:

- `AI_STATE/HANDOFF_20260917_ZYNC_V1_RELEASE_READINESS.md`
- `AI_STATE/MINI_HANDOFF_20260917_1245_SIGNING_DOC_FIXED_ANALYTICS_START.md`
- `AI_STATE/MINI_HANDOFF_20260917_1258_ANALYTICS_CORE_ADDED.md`
- `AI_STATE/MINI_HANDOFF_20260917_1305_ANALYTICS_CI_IN_PROGRESS.md`
- all older QR/scanner/signing/API handoffs listed by the previous authoritative file.

## 11. Bottom line

The privacy-light analytics item is no longer an outstanding product-spec gap. It is implemented, privacy-filtered on both client and server, documented, tested, and certified by fully green CI #81 with a new release AAB artifact.

The project is now at external release integration: real production Vercel origin/live endpoint evidence, real Play signing secrets/signed AAB, then physical-device QA.

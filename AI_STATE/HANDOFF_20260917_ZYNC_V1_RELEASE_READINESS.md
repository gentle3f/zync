# Zync V1 — Authoritative Handoff (Release Readiness)

Date: 2026-09-17
Branch: `zync-v1-rebuild-20260917`
Repository: `gentle3f/zync`

## 0. How the next chat must resume

Read `AI_STATE/LATEST_HANDOFF.md` first. It points to this file. Treat this file as the authoritative state snapshot and continue directly from the active tasks below. Do **not** restart repository discovery, re-plan V1 from scratch, or reopen old Thunkable archaeology.

Keep using mini-handoffs/checkpoints during long chat sessions because the user explicitly warned that chat-mode sessions can time out around 25m40s and replies may disappear. Durable state belongs in GitHub, not only in chat.

## 1. Product mission and frozen scope

Authoritative product spec: `docs/ZYNC_V1_PRODUCT_SPEC.md`.

Zync V1 is a low-cost, international, local-first social icebreaker that helps two people discover hidden shared interests and turns those interests into natural conversation.

Consumer idea: **Discover what connects you.**

Core V1 flow is frozen:

1. User builds a local interest profile.
2. Interests are canonical IDs with localized labels.
3. Interests can be marked `love`, `like`, or `wantToTry`.
4. One user shows a QR; the other scans it.
5. Matching happens locally on-device.
6. Shared interests are initially hidden and revealed progressively.
7. If shared interests exist, AI generates a conversation question around them.
8. If there is no exact match, AI creates a crossover question between the two users' different interests rather than showing a dead end.
9. Conversation modes: Easy / Fun / Debate / Deep / Guess / Surprise.
10. Zync Again history is local only.
11. Interest DNA is descriptive, not personality pseudo-science.

Explicit V1 exclusions remain frozen:

- no login / registration;
- no Firebase user profile;
- no cloud account sync;
- no feed/posts/friends/follows;
- no chat/messaging;
- no community rooms;
- no location/nearby people;
- no activity matching;
- no social-account import;
- no merchant/ads/payment/subscription;
- no dating/career matching.

Group Zync remains V1.1-capable and must not delay the core two-person release.

## 2. Non-negotiable UI/UX and graphics quality bar

Visual source of truth: `docs/ZYNC_V1_VISUAL_SYSTEM.md`.

The app must not ship looking like a default Flutter demo or a functional prototype. Professional UI/UX and graphics are part of the deliverable, not something the user will source later.

Current visual direction:

- warm, modern, international social product;
- dominant Zync Orange `#FF6A21`;
- dark Ink `#17181C`;
- warm Cream `#FFFAF6`;
- Plum `#6E5AE6` as counterpart/connection accent;
- Mint/Blue only as secondary states;
- generous rounded geometry;
- restrained shadows;
- recurring overlapping-rings / connection motif.

Graphics already in source include:

- reusable custom `ZyncMark` (two overlapping rings);
- connection backdrop motif;
- native Android launcher/adaptive/monochrome icon;
- branded pre/post Android 12 splash/launch resources;
- scanner frame and scan-line presentation;
- branded loading/error/empty states.

Native Android branding is reproducibly applied by `mobile/tool/apply_android_branding.py` during CI-generated wrapper creation.

## 3. Platform and release identity

Do not change these:

- Android applicationId: `com.gmail.gentle3f.myproject`
- Existing known Play versionCode: `5`
- Rebuild version: `1.0.0+6`
- targetSdk: `36`
- compileSdk: `36`
- Android display label: `Zync`
- final Play artifact: AAB

`mobile/pubspec.yaml` currently uses Flutter/Dart with:

- `http`
- `mobile_scanner`
- `qr_flutter`
- `shared_preferences`
- `uuid`
- `intl`

Do not change the installed app identity. `main` remains untouched; all current work is on `zync-v1-rebuild-20260917`.

## 4. Implemented mobile product surface

The following consumer surface is implemented on the rebuild branch:

- branded app boot/loading;
- interest onboarding/editor;
- local canonical interest catalog;
- free-text interest input;
- AI normalization for unknown interests, with user confirmation;
- interest strengths (`love`, `like`, `wantToTry`);
- local persistence through SharedPreferences;
- Show My QR;
- Scan QR;
- local canonical matching;
- Hidden Match progressive reveal;
- no-match crossover path;
- conversation modes;
- local AI-fallback questions;
- Zync Again history;
- Interest DNA;
- scanner permission / unsupported camera / generic failure recovery UX;
- true bilingual conversation rendering when peers use different supported languages.

Main screen files currently include:

- `mobile/lib/screens/home_screen.dart`
- `mobile/lib/screens/interest_setup_screen.dart`
- `mobile/lib/screens/show_qr_screen.dart`
- `mobile/lib/screens/scan_qr_screen.dart`
- `mobile/lib/screens/match_screen.dart`
- `mobile/lib/screens/conversation_screen.dart`
- `mobile/lib/screens/history_screen.dart`
- `mobile/lib/screens/interest_dna_screen.dart`

Core files include:

- `mobile/lib/core/ai_service.dart`
- `mobile/lib/core/interest_catalog.dart`
- `mobile/lib/core/language_support.dart`
- `mobile/lib/core/local_store.dart`
- `mobile/lib/core/localized_domain_text.dart`
- `mobile/lib/core/matching_service.dart`
- `mobile/lib/core/models.dart`

## 5. Internationalization status

Eight initial locales are implemented:

- English `en`
- Traditional Chinese `zh-Hant`
- Simplified Chinese `zh-Hans`
- Japanese `ja`
- Korean `ko`
- Spanish `es`
- French `fr`
- Portuguese `pt`

All core UI strings use localization resources. Internal category keys are localized before display. History metadata is localized rather than hard-coded English.

`mobile/lib/core/language_support.dart` canonicalizes locale variants into the supported set. Unknown/unsupported locales fall back safely to English; Chinese variants map to zh-Hant/zh-Hans as designed.

Cross-language conversation is implemented as one semantic question plus one equivalent translation, not two independently generated questions. QR carries peer language; Match propagates that to Conversation. Same-language peers see one question. Different-language peers see primary + secondary versions.

Local fallback questions also support both languages when the API is unavailable.

## 6. QR transport and scan reliability — certified

Design note: `docs/QR_TRANSPORT_V2.md`.

Transport behavior:

- semantic payload schema remains `v:1`;
- small profiles keep legacy compact raw JSON for maximum backward compatibility;
- larger profiles adaptively switch to `Z2:` + URL-safe base64(zlib(compact JSON)) when the raw payload exceeds the compression threshold and compression is actually smaller;
- new decoder accepts both legacy raw JSON and compressed `Z2:` transport;
- malformed compressed data is rejected;
- decompressed payload has a 64 KiB guard;
- custom interest label/category/strength metadata survives compression round-trip.

Regression coverage includes an 80-interest multilingual/custom profile and a narrow 320dp Show QR render.

Show QR presentation uses:

- responsive approximately 180–300dp QR size;
- error correction M;
- gapless modules;
- clean white quiet-zone surface;
- no decorative content intruding into the QR;
- localized semantics/error state.

Certification checkpoint:

- CI #41 `35141089002` — SUCCESS
- commit: `dfa3a4a312169bb9ad632973ad4f559984674101`
- artifact: `10465556475`
- size: `60,752,363` bytes
- digest: `sha256:6df41d2534493108345f50d3855b566a2b76da72eb73a8268921bbcf766d9dcd`

Physical-device scan reliability is still a real-device QA item; CI cannot certify camera optics/focus/brightness behavior.

## 7. Scanner recovery UX + bilingual conversation — certified

Scanner currently uses branded nontechnical error states through `MobileScanner.errorBuilder`:

- camera permission denied;
- camera unsupported/unavailable;
- generic camera failure.

Permission/generic failure paths have Retry. Unsupported-camera state explains that the user can use Show My QR instead. Scanner frame/status overlay is hidden when camera is not initialized or is in error state. Raw plugin error text is not exposed.

Tests cover Traditional Chinese permission/retry and English unsupported-camera fallback.

Cross-language conversation behavior is also certified in the same release-readiness slice:

- peer language flows from QR -> Match -> Conversation;
- supported locale tags are canonicalized;
- Vercel question endpoint can return one semantic question plus translated equivalent using strict `<<<ZYNC_TRANSLATION>>>` separator parsing;
- malformed bilingual output is rejected and the app falls back locally;
- same-language path remains single-question;
- bilingual layout has narrow-phone coverage.

Certification checkpoint:

- CI #61 `35176798122` — SUCCESS
- commit: `5c3b7f11d3bfb04300721508f5130cadeac58720`
- artifact: `10479296575`
- size: `60,802,404` bytes
- digest: `sha256:b0e2ec36c40bd9175be7d0d2bc0fe3ce2ecb6f096b40a818c19d0b92e86b1bd9`

## 8. Android production signing preparation — certified, real signing still blocked by credentials

Files:

- `mobile/tool/configure_android_signing.py`
- `.github/workflows/zync-v1-signed-release.yml`
- `docs/ANDROID_RELEASE_SIGNING.md`

The signing helper patches a generated Flutter Android wrapper to use a dedicated `zyncRelease` signing config. It validates `key.properties` and keystore presence and supports current Kotlin DSL plus Groovy fallback. It has a secret-free self-test and a generated-template compatibility check.

Normal CI verifies that the signing transform still matches Flutter's current generated Android template.

The manual `Zync V1 Signed Release` workflow:

- requires a production HTTPS `ZYNC_API_BASE`;
- requires all four signing secrets;
- generates the Android wrapper with the legacy app identity;
- applies Zync branding;
- installs the keystore only in the ephemeral runner;
- patches Gradle to use `zyncRelease`;
- runs localization/analyze/tests;
- builds the AAB;
- verifies the AAB JAR signature with `jarsigner -verify -strict`;
- uploads `zync-v1-play-signed-aab`.

Required GitHub Actions secrets:

- `ZYNC_ANDROID_KEYSTORE_BASE64`
- `ZYNC_ANDROID_STORE_PASSWORD`
- `ZYNC_ANDROID_KEY_ALIAS`
- `ZYNC_ANDROID_KEY_PASSWORD`

Never commit, log, or paste these into source. Do not invent a new upload key merely to make CI green. The real existing Play upload key must be used or reset through the Play Console process if necessary.

Signing-prep certification checkpoint:

- CI #67 `35178975781` — SUCCESS
- code commit: `b5bef09bf193d47a7838742c5c283155070a9a06`
- passed JavaScript syntax checks, signing self-test, generated-template compatibility, Play identity assertions, localization, `flutter analyze`, all Flutter tests, release AAB build and artifact upload.

Earlier CI #63 was cancelled only because later pushes superseded it; it had already passed all checks before the unsigned AAB build. Treat cancellation as superseded, not a failure.

Important documentation drift found at this handoff: `docs/ANDROID_RELEASE_SIGNING.md` still describes `ZYNC_API_BASE` as optional for release, but `.github/workflows/zync-v1-signed-release.yml` now correctly requires a non-empty `https://` base for production. The next chat should update this doc before release.

## 9. V1 serverless API and hardening — certified

Endpoints:

- `POST /api/v1/question`
- `POST /api/v1/normalize-interest`

OpenRouter key is server-side only through `OPENROUTER_API_KEY` or legacy `API_KEY` fallback. The Android app contains no OpenRouter secret.

### Question endpoint hardening

`api/v1/question.js` currently:

- supports only known Zync language families after canonicalization;
- falls back unknown/untrusted locale strings safely rather than inserting them verbatim as prompt instructions;
- caps interest arrays and individual interest string lengths;
- treats supplied interest names as data rather than instructions;
- JSON-frames interest values in the prompt;
- validates conversation mode;
- handles shared-interest and zero-match crossover modes;
- supports one-question + equivalent-translation bilingual output;
- requires strict translation separator parsing;
- maps malformed bilingual output to stable error behavior;
- has a 12-second upstream abort timeout;
- maps provider failures to stable API errors;
- uses `Cache-Control: no-store` on success.

### Normalize-interest endpoint hardening

`api/v1/normalize-interest.js` currently:

- validates POST;
- bounds user input to 2..100 characters;
- canonicalizes supported locale families server-side;
- frames raw input as data rather than instructions;
- uses a strict allowed category set;
- coerces arbitrary/unknown AI categories to `other`;
- preserves niche concepts rather than intentionally broadening everything;
- generates deterministic hashed `custom.<digest>` canonical IDs from normalized English canonical names;
- has a 12-second upstream abort timeout;
- returns no API secret or hidden configuration.

### Serverless contract tests

`.github/scripts/serverless_contracts.mjs` contains dependency-free behavioral tests with mocked req/res/fetch/env. Coverage includes:

- non-POST rejection;
- interests-required validation;
- missing AI key behavior;
- same-language question output;
- bilingual separator parsing;
- malformed bilingual output rejection;
- upstream/provider failure mapping;
- normalize method/input bounds;
- deterministic custom canonical IDs;
- allowed category handling and fallback to `other`;
- locale/request hardening;
- interest count/length bounding;
- timeout-signal presence.

Normal CI now watches all `api/**`, syntax-checks legacy API files plus V1 endpoints, and runs these contract tests before Flutter analysis/build.

Authoritative API-hardening certification:

- CI #71 `35180203133` — SUCCESS
- code commit: `bd2505388551c31cdf2eb256b0798d436b9fcfb2`
- passed serverless syntax checks;
- passed V1 serverless contract tests;
- passed signing configurator self-test;
- passed generated signing-template compatibility;
- passed Play identity and Android requirement checks;
- passed localization generation;
- passed `flutter analyze`;
- passed all Flutter tests;
- built release AAB;
- uploaded AAB artifact.

Artifact:

- id: `10480196870`
- name: `zync-v1-unsigned-aab`
- size: `60,802,408` bytes
- digest: `sha256:943e2d931c683caa38632829ee496fe02a38bb984d5a55a4d1bb11d2257c1def`
- expires: 2026-10-01

Current branch head at the time of this handoff was a documentation-only checkpoint after the certified code: `95e6d69d605c4dfc76fd379ee8fcb110019c8b9e`. No mobile/API code changed after the CI #71 code commit in that documentation checkpoint.

## 10. Tests and automated quality gates currently present

Mobile tests include:

- `mobile/test/core_test.dart`
- `mobile/test/layout_smoke_test.dart`
- `mobile/test/scanner_error_test.dart`

Coverage includes:

- canonical matching and custom-interest metadata;
- QR legacy/compressed round-trips;
- malformed compressed payload rejection;
- multilingual/bilingual fallback behavior;
- language normalization;
- 320dp narrow layouts;
- long French/Portuguese content;
- enlarged text smoke coverage;
- large compressed QR rendering;
- scanner error/retry UX;
- bilingual conversation layout.

Normal CI (`.github/workflows/zync-v1-ci.yml`) enforces:

1. Flutter setup;
2. Node/Dart toolchain visibility;
3. JavaScript syntax checks;
4. V1 serverless contract tests;
5. signing helper self-test;
6. Android wrapper generation with legacy Play identity;
7. signing-transform compatibility against current Flutter template;
8. Play identity / SDK / branding assertions;
9. `flutter pub get`;
10. `flutter gen-l10n`;
11. `flutter analyze`;
12. `flutter test`;
13. release AAB build;
14. artifact upload.

## 11. Vercel / production API blocker

The app code already reads `ZYNC_API_BASE` as a Dart define. Normal CI injects repository variable `${{ vars.ZYNC_API_BASE }}` when present. The signed-release workflow now **requires** a valid `https://` production base.

The connected Vercel connector currently returns no teams/projects, so it cannot discover the user's existing production Zync Vercel URL. Do not guess the URL and do not assume the placeholder `https://zync.app` used as OpenRouter HTTP-Referer is the deployed API origin.

Required next external action is to obtain the actual existing Vercel project production origin and set GitHub repository variable:

`ZYNC_API_BASE=https://<actual-production-origin>`

Then verify live calls against:

- `/api/v1/question`
- `/api/v1/normalize-interest`

Live integration must verify both success and fallback/error behavior. The current CI only certifies handler logic with mocked upstream fetch; it does not prove the user's live Vercel deployment or OpenRouter account configuration.

## 12. Remaining real-world release blockers

These are not code failures; they require account/device evidence.

### A. Production API origin

Need the actual Vercel URL and GitHub repository variable `ZYNC_API_BASE`.

### B. Real Play upload-key secrets

Need all four real GitHub Actions secrets listed above. Do not expose them in source or chat if avoidable; configure them directly in GitHub Settings -> Secrets and variables -> Actions.

### C. Signed production AAB

After A+B exist, run `Zync V1 Signed Release` on `zync-v1-rebuild-20260917`, confirm workflow success, confirm `jarsigner` verification, and record artifact ID/digest in the handoff.

### D. Real-device QA

Before Play internal testing, physically verify at minimum:

- launcher icon on Android home screen;
- Android splash/launch screen continuity;
- onboarding on ordinary phone sizes;
- keyboard does not obstruct final action;
- camera permission grant/deny/retry;
- scanner focus/framing in real lighting;
- small-profile legacy QR scan device-to-device;
- large compressed QR scan device-to-device;
- zero-match AI crossover;
- same-language AI question;
- two-device bilingual interaction, e.g. zh-Hant + Japanese;
- long translated text on a real small Android phone;
- AI timeout/local fallback presentation;
- Hidden Match reveal haptic/animation feel.

Do not claim these certified from widget tests alone.

## 13. Outstanding product-spec gap: analytics

`docs/ZYNC_V1_PRODUCT_SPEC.md` includes privacy-light V1 analytics goals/events such as:

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

As of this handoff there is no dedicated analytics service in `mobile/lib/core`; the implemented core files are AI/catalog/language/local-store/domain-text/matching/models. Therefore analytics should be treated as **not yet implemented**, not silently assumed done.

Before shipping a validation-focused public beta, decide and implement the smallest privacy-respecting analytics mechanism that does not upload raw interest content. Keep it low-cost and do not introduce Firebase user accounts or a heavy backend. If a no-cost provider or existing endpoint is used, record the exact data collected and retention/privacy implications. Do not block basic internal-device QA on analytics if external configuration is unavailable.

## 14. Minor documentation cleanup required

Update `docs/ANDROID_RELEASE_SIGNING.md` to match current workflow behavior:

- normal development/CI can build with empty `ZYNC_API_BASE` and use local fallback;
- **production signed release requires a non-empty HTTPS `ZYNC_API_BASE`**;
- signed release should not be run until both API base and all four signing secrets are configured.

This is documentation drift only; current workflow behavior is already safer than the doc.

## 15. Recommended continuation order

Continue in this order unless the user provides missing credentials/config first:

1. Update `docs/ANDROID_RELEASE_SIGNING.md` to reflect production API-base requirement.
2. Decide/implement minimal V1 analytics from the frozen product spec, without uploading raw hobby names/interests and without adding Firebase accounts.
3. If the user supplies/discovers the production Vercel URL, set/confirm `ZYNC_API_BASE` and perform live V1 endpoint smoke tests.
4. If signing secrets are configured, run **Zync V1 Signed Release** and certify the signed artifact/digest.
5. Perform real-device QA and log evidence/results in `AI_STATE`.
6. Only after signed artifact + real-device QA should Play internal testing be considered.
7. Do not widen into Phase 2.

If analytics architecture risks becoming a backend project, keep it minimal and explicitly defer rather than violating the near-zero-cost V1 principle.

## 16. Branch / safety guardrails

- Work only on `zync-v1-rebuild-20260917` unless the user explicitly changes this.
- Do not touch `main`.
- Never commit API keys, Vercel secrets, keystores, key passwords, `key.properties`, or secret base64 blobs.
- Do not run a production signed release just to demonstrate that missing secrets fail.
- Do not invent the Vercel production URL.
- Do not replace the existing Play upload key with a random new key merely to make a build sign.
- Do not remove local AI fallback behavior.
- Do not regress legacy raw QR compatibility while improving compressed transport.
- Keep UI/UX/graphics quality as a release requirement.
- Continue frequent mini-handoffs because chat timeout/lost replies are a known operational risk.

## 17. Previous durable checkpoints retained

Do not delete old handoffs. Useful lineage files include:

- `AI_STATE/MINI_HANDOFF_20260917_QR_COMPRESSION_START.md`
- `AI_STATE/MINI_HANDOFF_20260917_SCANNER_ERROR_START.md`
- `AI_STATE/MINI_HANDOFF_20260917_SCANNER_ERROR_UX_START.md`
- `AI_STATE/MINI_HANDOFF_20260917_1155_SIGNING_API_CERTIFIED.md`
- `AI_STATE/MINI_HANDOFF_20260917_1200_API_HARDENING.md`

The new authoritative snapshot supersedes their status fields but they remain useful audit history.

## 18. Bottom-line state

Zync V1 is no longer just a concept or UI mock. The branch currently has a functioning Flutter rebuild, professional visual system, multilingual/local-first interest profile, adaptive QR transport, scanner recovery UX, hidden-match interaction, conversation modes, bilingual question flow, hardened Vercel/OpenRouter handlers, release-signing tooling, broad automated tests, and repeatedly green release-AAB CI.

The remaining blockers are mostly release integration and real-world evidence: production Vercel origin, real Play upload-key secrets, signed AAB, physical-device QA, plus the still-unimplemented privacy-light analytics layer called for by the V1 validation spec.

Continue from release readiness; do not restart product architecture.
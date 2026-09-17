# Zync V1 — Authoritative Handoff: Privacy-Hardened Release Candidate

Date: 2026-09-17
Branch: `zync-v1-rebuild-20260917`
Repository: `gentle3f/zync`
Current certified head: `310360be80fc1bdd3c2c595a964172d00be87a0a`

## 0. Resume rule

Read `AI_STATE/LATEST_HANDOFF.md` first, then this file in full. Continue directly from **Recommended continuation order** below. Do not restart repository discovery, re-plan V1, or reopen old Thunkable archaeology. Keep mini-handoffs frequent because chat streams may disappear.

This file supersedes status fields in `AI_STATE/HANDOFF_20260917_ZYNC_V1_ANALYTICS_CERTIFIED_RELEASE_INTEGRATION.md` while retaining all older handoffs as lineage.

## 1. Frozen product/release guardrails

Unchanged:

- local-first two-person social icebreaker;
- no login/account, Firebase profile, cloud profile sync, feed, friends/follows, chat, communities, location/nearby, payments/subscriptions, dating/career matching;
- Group Zync remains V1.1-capable and must not delay V1;
- Android applicationId `com.gmail.gentle3f.myproject`;
- version `1.0.0+6`, known prior Play versionCode 5;
- compileSdk/targetSdk 36;
- final Play artifact AAB;
- work only on `zync-v1-rebuild-20260917`; keep `main` untouched.

## 2. Product/analytics state remains certified

All product surface and analytics implementation recorded in the previous authoritative handoff remain intact, including:

- professional Zync visual/Android branding;
- local canonical interest profile + strengths;
- eight locales;
- adaptive legacy/compressed QR transport;
- scanner recovery UX;
- Hidden Match / zero-match crossover;
- conversation modes + bilingual output + local fallback;
- local Zync Again history + Interest DNA;
- privacy-light analytics with strict client/server allowlists;
- no raw/canonical interest content, peer ID, nickname or QR payload in analytics;
- release-signing preparation.

## 3. Generic Chinese localization gap — fixed and certified

CI #81 had shown `"zh": 6 untranslated message(s).`.

Audit found generic `mobile/lib/l10n/app_zh.arb` lacked six scanner recovery strings:

- camera permission title/body;
- camera unavailable title/body;
- scanner error title/body.

They were aligned with the existing Simplified Chinese translations in `app_zh_Hans.arb`.

Fix commit: `c4177d21657de0cd00e1890c13fdd73a7e9c55f1`.

CI #88 logs show localization generation with **no untranslated-message warning**.

## 4. OpenRouter privacy hardening — implemented and enforced

Both production AI handlers now send per-request provider routing constraints:

```json
"provider": {
  "zdr": true,
  "data_collection": "deny"
}
```

Files:

- `api/v1/question.js`
- `api/v1/normalize-interest.js`

Meaning for Zync release behavior:

- required interest text still leaves the device when the user invokes AI normalization/question generation;
- Zync requests only provider routes compatible with zero data retention and denied provider data collection;
- if no compatible route succeeds, the app must prefer failure/local fallback rather than relaxing the privacy requirement.

This is a routing/privacy invariant, not a claim that AI data never leaves the device.

Automated protection:

- `.github/scripts/openrouter_privacy_contracts.mjs`
- normal CI executes it;
- signed-release workflow executes it;
- CI #88 shows both privacy-contract tests passing.

OpenRouter response caching was reviewed separately: Zync does not send the opt-in cache header or use a cache-enabled preset, so no additional cache-disable parameter was required.

## 5. Production live-smoke gate added before signing

New script:

- `.github/scripts/live_api_smoke.mjs`

Signed-release workflow now requires the actual production `ZYNC_API_BASE` to pass live smoke **before building/signing**.

The live smoke uses fixed non-sensitive dummy interests and verifies:

- `POST /api/v1/normalize-interest` responds from the expected V1 handler;
- `POST /api/v1/question` responds from the expected V1 handler;
- deployed handlers expose the release privacy contract proving the production deployment is the ZDR/data-collection-deny build;
- `POST /api/v1/analytics` returns success when configured or the explicit expected `503 analytics_not_configured` when intentionally disabled.

This prevents a signed AAB from being certified against a dead URL, stale API deployment, or pre-privacy-hardening handler.

Normal CI syntax-checks all release scripts, including `live_api_smoke.mjs`.

## 6. Latest authoritative CI certification — #88 green

Run:

- workflow: `Zync V1 CI`
- run number: #88
- run id: `35185113602`
- head: `310360be80fc1bdd3c2c595a964172d00be87a0a`
- conclusion: **SUCCESS**

Passed:

- serverless/API/release-script JavaScript syntax;
- 20 serverless contract tests;
- 2 OpenRouter privacy contract tests;
- signing helper self-test;
- generated Android signing-template compatibility;
- Play identity / target/compile SDK / branding assertions;
- localization generation with no generic-Chinese untranslated warning;
- `flutter analyze` with no issues;
- all 21 Flutter tests;
- unsigned release AAB build;
- artifact upload.

Latest unsigned release artifact:

- id: `10482286235`
- name: `zync-v1-unsigned-aab`
- size: `60,827,444` bytes
- digest: `sha256:37c4f68d233d0d205952ea54da1568ec74742591e7ac138bbded0407ceebaa7b`
- expires: 2026-10-01

CI logs still explicitly show `ZYNC_API_BASE:` empty. This remains a real production blocker, not just an unknown value.

## 7. Production Vercel origin remains unresolved — do not guess

Evidence already gathered:

- GitHub Actions repository variable `ZYNC_API_BASE` is empty in CI logs;
- connected Vercel connector returns no teams/projects;
- `.vercel/project.json` absent;
- `vercel.json` absent;
- targeted repo/public searches did not produce a trustworthy production origin.

Do not invent `https://zync.app` or another Vercel URL. The OpenRouter `HTTP-Referer` fallback is not proof of the deployed API origin.

Production release cannot be signed/certified until the real origin is discovered/supplied, deployed with current code, configured as `ZYNC_API_BASE`, and passes `live_api_smoke.mjs`.

## 8. Play listing / Data Safety / privacy release gate

New release checklist:

- `docs/PLAY_RELEASE_DATA_SAFETY.md`

The currently published Play listing describes the old app with login/remote matching language; rebuilt V1 has no login and uses local QR matching. Store description/screenshots therefore need replacement before public rollout.

Data Safety must also be re-reviewed. Important distinction:

### AI functionality path

When a user invokes AI:

- free-text unknown interest is sent for normalization;
- bounded interest labels are sent for conversation-question generation;
- purpose is app functionality;
- ZDR/data-collection-deny routing reduces provider retention but does not change the fact that data is transmitted off-device.

### Analytics path

When public analytics is enabled:

- random anonymous installation/session identifiers;
- coarse app-interaction events/counts/enums;
- no raw interest content;
- purpose is analytics.

Do not retain the old blanket `No data collected` answer without redoing the Play Data Safety declaration against the actual shipped configuration.

A public privacy notice must match these actual flows. No verified updated V1 privacy-policy source currently exists in the repo.

## 9. Cost/abuse release gate

V1 deliberately has no login/auth account. The public serverless AI endpoints therefore need production account-level cost protection before open rollout:

- configure/review OpenRouter key spend/budget limits;
- review Vercel request/firewall/rate controls appropriate for a public mobile API;
- do not add Firebase/login merely to solve this;
- do not claim abuse protection is active until external configuration is verified.

## 10. Real Play signing remains external

Required real GitHub Actions secrets:

- `ZYNC_ANDROID_KEYSTORE_BASE64`
- `ZYNC_ANDROID_STORE_PASSWORD`
- `ZYNC_ANDROID_KEY_ALIAS`
- `ZYNC_ANDROID_KEY_PASSWORD`

No signed-release run has been performed. Do not run it simply to demonstrate missing secrets. Use the existing Play-accepted upload key or the Play Console upload-key reset process if required; never fabricate a replacement key.

## 11. Real-device QA remains required

Still not certifiable in GitHub CI:

- launcher/splash visual continuity;
- actual camera permission transitions;
- scanner focus/framing/lighting;
- legacy QR device-to-device;
- large compressed QR device-to-device;
- same-language AI;
- zero-match AI crossover;
- two-device bilingual flow;
- local fallback under AI timeout/failure;
- narrow-device translated content;
- Hidden Match animation/haptic feel.

## 12. Recommended continuation order

1. Keep branch/handoff state durable; do not rediscover old repo history.
2. Finish release collateral that does **not** require external credentials: accurate V1 Play listing draft, privacy-policy draft/source, reviewer QR/access instructions, QA checklist/evidence template.
3. Discover/supply the real production Vercel project/origin; configure `ZYNC_API_BASE`; deploy current privacy-hardened handlers.
4. Configure/verify OpenRouter production key + budget/abuse controls; optionally configure analytics provider/retention.
5. Run production live smoke and require all expected contracts.
6. Confirm real Play upload-key secrets.
7. Run/certify `Zync V1 Signed Release`; record signed artifact/digest.
8. Perform real-device QA and log evidence.
9. Update Play listing, Data Safety and public privacy policy to match the actual shipped configuration.
10. Only then move to Play internal testing/public rollout. Do not widen into Phase 2.

## 13. Durable lineage retained

Retain, do not delete:

- `AI_STATE/HANDOFF_20260917_ZYNC_V1_RELEASE_READINESS.md`
- `AI_STATE/HANDOFF_20260917_ZYNC_V1_ANALYTICS_CERTIFIED_RELEASE_INTEGRATION.md`
- all `AI_STATE/MINI_HANDOFF_20260917_*` checkpoints
- `docs/ZYNC_V1_ANALYTICS.md`
- `docs/PLAY_RELEASE_DATA_SAFETY.md`
- `docs/ANDROID_RELEASE_SIGNING.md`

## 14. Bottom line

The executable V1 branch is now a **privacy-hardened unsigned release candidate** with fully green CI #88. The remaining release blockers are primarily production deployment/configuration, real Play signing, physical-device evidence, and accurate Play/privacy metadata — not missing core app code.

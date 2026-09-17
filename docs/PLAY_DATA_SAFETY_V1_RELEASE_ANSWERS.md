# Zync V1 — Google Play Data Safety Release Answers

Date: 2026-09-17  
Branch: `zync-v1-rebuild-20260917`  
Android package: `com.gmail.gentle3f.myproject`

This file is the release-facing answer sheet for the rebuilt local-first V1. It separates facts proven by the shipped code from Play Console classifications that still require a final check against the current form wording.

## Frozen public-V1 privacy posture

- No login or cloud user account.
- Local interest profile and Zync Again history remain on-device.
- QR profile exchange is direct device-to-device visual transfer; the QR body is not uploaded to Zync for matching.
- AI is optional and used only for unknown-interest normalization and conversation-question generation.
- AI requests go through the Zync Vercel API and OpenRouter.
- Every OpenRouter request requires `provider.zdr: true` and `provider.data_collection: "deny"`.
- Model selection is `openrouter/free`, so the underlying free model/provider can vary; requests must still satisfy the privacy-routing constraints.
- Product analytics are explicitly **OFF** in the public V1 Android build with `ZYNC_ANALYTICS_ENABLED=false`.
- Because analytics are off before identifier creation/networking, the public V1 build does not create the optional analytics installation UUID and does not send product-analytics events.

## Data Safety top-level answer

### Does the app collect or share any of the required user data types?

**Yes — collect.**

Reason: Google defines collection broadly as transmitting user data off the device. When a user invokes an AI feature, limited interest text / relevant interest labels and language/mode information are transmitted to the Zync API and AI processing path. Zero Data Retention does not make that transmission disappear for Data Safety purposes.

Do **not** answer "No data collected" for this V1.

### Is all user data encrypted in transit?

**Yes for the Zync-controlled production network paths.**

The release gate requires an HTTPS `ZYNC_API_BASE`, and the Zync server calls OpenRouter over HTTPS.

### Does the app support account creation?

**No.**

Zync V1 has no user account, login or registration flow, so Google Play's account-deletion requirement for apps that let users create accounts is not applicable to this release.

## Data type 1 — interest / conversation content sent for AI functionality

### What leaves the device

`POST /api/v1/normalize-interest`:

- user-entered unknown interest text, bounded to 2–100 characters;
- supported language/locale.

`POST /api/v1/question`:

- bounded relevant interest labels needed for that conversation;
- conversation mode;
- primary/secondary supported language where needed.

### What is deliberately not required by the AI endpoints

- nickname;
- peer local ID;
- QR payload/body;
- email address;
- phone number;
- precise or coarse location;
- advertising ID;
- contacts/social graph;
- login/account token;
- full local profile as a persistent cloud object.

### Recommended Play category

Use the current Play Console wording and choose the closest content category for user-supplied interest/conversation content. Under the current taxonomy, the conservative fit is expected to be:

- **App activity → Other user-generated content**

Purpose:

- **App functionality**

This category name must be checked against the actual current Play Console UI before submission; do not force a stale label if Google changes the taxonomy.

### Is collection required or optional?

The AI transmission is **feature-dependent**: it occurs only when the user invokes the relevant AI-assisted feature. Core local profile creation, QR matching and local fallback conversation content can operate without a successful AI request.

Use the current Play form's definition of optional collection carefully. Do not claim user-configurable opt-out controls that do not exist.

### Is the data processed ephemerally?

OpenRouter requests enforce ZDR-compatible routing and deny non-transient provider data collection. Zync application code does not intentionally persist AI request text in a user database.

Google's current Data Safety guidance still requires off-device ephemeral processing to be declared in the form. Apply the current Play UI's ephemeral-processing question based on the final provider configuration and Google's definition at submission time.

## Shared vs collected — final Play Console decision

The data above is definitely **collected** under Google's off-device definition.

Whether it must also be marked **shared** depends on whether Vercel, OpenRouter and the routed model provider qualify for Google's service-provider exception under the actual terms/configuration used for this release.

Before answering "not shared", verify the current provider terms/DPA and Google's current service-provider exception wording. If that conclusion cannot be supported, use the conservative Play answer and declare the relevant content as shared as well.

Do not infer "not shared" merely from ZDR.

## Analytics — public V1 answer

For this release:

- `ZYNC_ANALYTICS_ENABLED=false` is passed explicitly by the CI and signed-release workflows;
- the client returns before creating analytics IDs or making an analytics request;
- PostHog is not required for the public V1 release.

Therefore the optional analytics design does **not** add App interactions or Device/other IDs to the public V1 Data Safety answers.

If analytics are enabled in a future release, re-open Data Safety before publishing. At minimum review:

- App activity → App interactions;
- Device or other IDs;
- purpose Analytics;
- actual provider/retention/sharing terms.

## Local data that is not uploaded as part of normal V1 matching

- stored local interest profile as a whole;
- nickname persistence;
- Zync Again/history records;
- peer local IDs/history;
- Interest DNA calculations;
- local match calculation;
- QR body as part of scanner/matching backend traffic.

The fact that these remain local does not change the separate AI collection disclosure above.

## Privacy policy URLs

Intended public URLs after the one-shot Vercel deployment:

- Privacy Policy: `https://zync-inky.vercel.app/privacy`
- Terms: `https://zync-inky.vercel.app/terms`
- Disclaimer: `https://zync-inky.vercel.app/disclaimer`

The Privacy Policy is plain static HTML, contains the Zync/package identity, explains AI/provider processing, security, retention/deletion and a privacy inquiry mechanism through the official Google Play Developer contact.

## Final submission checklist

Before saving the Data Safety form:

1. Confirm the production deployment is the new V1 and not the old 2025 `main` deployment.
2. Live-smoke both AI endpoints with the real OpenRouter key and `openrouter/free` under enforced ZDR/data-collection-deny routing.
3. Confirm `/privacy` is public, HTTPS, non-PDF, non-geofenced and readable without login/JavaScript.
4. Confirm the signed AAB was built with `ZYNC_ANALYTICS_ENABLED=false`.
5. Verify the current Play Console category wording for the AI content type.
6. Verify the provider/service-provider exception before deciding the final "shared" answer.
7. Ensure the Play listing no longer says "No data collected" if the V1 AI features are included.

## Current official policy references checked 2026-09-17

- Google Play User Data / Privacy Policy requirements: https://support.google.com/googleplay/android-developer/answer/10144311
- Google Play Data Safety disclosure guidance: https://support.google.com/googleplay/android-developer/answer/10787469
- OpenRouter Free Models Router: https://openrouter.ai/openrouter/free/
- OpenRouter ZDR/data-policy routing: https://openrouter.ai/blog/insights/zero-data-retention/

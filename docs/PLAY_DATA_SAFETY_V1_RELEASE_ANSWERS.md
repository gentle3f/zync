# Zync V1 — Google Play Data Safety Release Answers

Date: 2026-09-18  
Branch: `zync-v1-rebuild-20260917`  
Android package: `com.gmail.gentle3f.myproject`

This file is the release-facing answer sheet for the rebuilt local-first V1. It separates facts proven by the shipped code from Play Console classifications that still require a final check against the current form wording.

## Frozen public-V1 privacy posture

- No login or permanent cloud user account/profile.
- Local interest profile and Zync Again history remain primarily on-device.
- The host's selected profile is shared visually through the QR and is not uploaded to create the relay session.
- One-scan pairing uses a short-lived encrypted relay: the scanner encrypts the limited profile response needed by the host with AES-GCM using a one-time key carried in the QR; the Zync relay receives only the random session ID plus opaque ciphertext/status and does not receive that decryption key.
- Relay state is designed for about a three-minute maximum lifetime and is deleted earlier after successful authenticated host decryption where possible.
- The relay path is Android -> Zync Vercel API -> Upstash Redis. Matching itself remains on-device on both phones.
- Interest catalog search, aliases, custom-interest creation and matching are on-device; the shipped V1 UI does not send custom-interest text for AI normalization.
- Optional AI conversation-question requests go through the Zync Vercel API and OpenRouter.
- Regional interest discovery can use the coarse country/region from the device locale plus aggregate canonical-interest impression/selection counts. It does not use GPS or precise location.
- The regional-learning transport has no Zync account ID, analytics installation ID, nickname, full profile, or custom-interest text.
- Every OpenRouter request requires `provider.zdr: true` and `provider.data_collection: "deny"`.
- Model selection is `openrouter/free`, so the underlying free model/provider can vary; requests must still satisfy the privacy-routing constraints.
- Product analytics are explicitly **OFF** in the public V1 Android build with `ZYNC_ANALYTICS_ENABLED=false`.
- Because analytics are off before identifier creation/networking, the public V1 build does not create the optional analytics installation UUID and does not send product-analytics events.

## Data Safety top-level answer

### Does the app collect or share any of the required user data types?

**Yes — collect.**

There are now three feature-dependent off-device paths that must be considered:

1. AI-assisted conversation generation transmits a bounded set of relevant interest labels/mode/language context to the Zync API and AI processing path.
2. One-scan QR pairing transmits an AES-GCM-encrypted scanner profile response to the short-lived Zync relay so the host phone can complete the same local match automatically.
3. Regional interest learning can transmit a coarse device-locale region plus canonical catalog interest IDs that were shown and selected, so the server can maintain aggregate weekly impression/selection counts.

Encryption, opacity to the application server, short retention, and ephemeral processing do **not** make an off-device transmission disappear for Data Safety analysis. Do **not** answer "No data collected" for this V1.

### Is all user data encrypted in transit?

**Yes for the Zync-controlled production network paths, subject to final production verification.**

The release gate requires an HTTPS `ZYNC_API_BASE`. AI server calls use HTTPS. The pairing response is additionally encrypted and authenticated on the scanning phone using AES-GCM before being transmitted through the HTTPS relay path.

### Does the app support account creation?

**No.**

Zync V1 has no user account, login or registration flow, so Google's account-deletion requirement for apps that let users create accounts is not applicable to this release.

## Data type 1 — interest context sent for AI conversation functionality

### What leaves the device

`POST /api/v1/question`:

- bounded relevant interest labels needed for that conversation;
- conversation mode;
- primary/secondary supported language where needed;
- a random bounded session-context value where present.

### What is deliberately not required by the AI endpoints

- nickname;
- peer local ID;
- QR body;
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

The AI transmission is **feature-dependent**: it occurs only when the user invokes AI-assisted conversation generation. Local interest entry/search, local profile creation, pairing/matching and local fallback conversation content do not require a successful AI request.

Use the current Play form's definition of optional collection carefully. Do not claim user-configurable opt-out controls that do not exist.

### Is the data processed ephemerally?

OpenRouter requests enforce ZDR-compatible routing and deny non-transient provider data collection. Zync application code does not intentionally persist AI request text in a user database.

Google's Data Safety guidance still requires off-device ephemeral processing to be declared. Apply the current Play UI's ephemeral-processing question based on the final provider configuration and Google's definition at submission time.

## Data type 2 — encrypted scanner profile response used for one-scan pairing

### What leaves the scanning phone

After the scanner reads the host QR, the app prepares only the profile fields the host needs to perform the same local comparison. Depending on the profile, the encrypted cleartext can include:

- random local Zync profile identifier;
- optional nickname;
- supported language;
- selected interest IDs and Love / Like / Want to try strength;
- custom-interest labels/categories needed to interpret those interests;
- relay protocol/session/expiry metadata.

Before transmission, that response is encrypted and authenticated on the scanning device with AES-GCM using the one-time 256-bit secret carried in the host QR. The relay endpoint receives the random session ID and an opaque encrypted envelope; it does not receive the one-time decryption secret.

### Relay retention and processing

- The Redis relay key is configured with a short TTL of about three minutes.
- The host polls non-destructively so a lost HTTP response does not destroy the pending encrypted response.
- After the host successfully decrypts and authenticates the response locally, it sends a consume request to delete the relay session early.
- If the flow is abandoned or consume cannot complete, TTL expiry is the hard cleanup guarantee.
- The relay is not used as a permanent user/profile/history database.

### Purpose

- **App functionality** — specifically, allowing one QR scan to complete pairing on both phones automatically.

### Play category

The cleartext represents user/profile content but the Zync-controlled relay stores only ciphertext. Google's Data Safety form classifications are based on what user data leaves the device, not merely what the first-party server can read. Before submission, inspect the current Play taxonomy and classify this encrypted profile response conservatively under the closest applicable user-content/profile category or categories.

Do **not** omit this transmission merely because the server lacks the decryption key.

### Is collection required or optional?

This transmission is feature-dependent: it occurs when users choose the one-scan Zync pairing flow. It is required for the host phone to auto-advance without a second QR scan.

### Is the data processed ephemerally?

Yes at the application-design level: the relay is intentionally short-lived and TTL-backed, with early deletion after successful consume. Still disclose the off-device collection and answer the Play Console's current ephemeral-processing question according to Google's current wording.

## Data type 3 — coarse regional interest discovery signals

### What can leave the device

When regional interest learning is enabled in the shipped build:

- coarse content region derived from the country/region in the device locale (for example `hk`, `tw`, `jp` or `global`);
- canonical catalog interest IDs that were displayed as discovery choices;
- canonical catalog interest IDs that were selected.

The client does **not** send GPS coordinates, precise location, nickname, full profile, custom-interest labels, advertising ID, account ID or the optional product-analytics installation UUID for this signal. Custom interests are excluded.

### Purpose and stability

Purpose:

- **App functionality / personalization of interest discovery ordering**.

The server aggregates signals by coarse region and completed week. Ranking pools the two most recent completed weeks. Human-curated catalog scores remain the prior; observed selection rates have bounded influence and the learned score is hard-capped to a small adjustment around that curated base, so small or sudden samples cannot take over the catalog.

### Retention

Aggregate weekly counters in Upstash Redis are configured to expire after about 120 days. The current week's data is accumulated for a future completed-week ranking and does not immediately change the current week's order.

### Play category

Before submission, check the current Play Console wording for coarse region and app-interaction/discovery signals. Because these signals leave the device, do not omit them merely because they are aggregate-only and carry no persistent Zync user identifier. Use the closest current categories conservatively and record the purpose as App functionality/personalization as applicable.

## Technical network / abuse-prevention metadata

The relay is hosted on Vercel and backed by Upstash Redis. Hosting/network providers may necessarily process technical request information such as IP address under their applicable service terms.

At the Zync application layer, relay and regional-learning rate limiting derive short-lived HMAC-based keys from the request IP and a server secret. The application-level Redis rate keys do not need to store the raw IP; the counters themselves have brief expiry.

Before Play submission, verify the current Data Safety treatment of provider-processed network identifiers and whether any Device or other IDs category is triggered by the final production/provider configuration. Do not label the dormant analytics identifier as collected: analytics remain disabled in public V1.

## Shared vs collected — final Play Console decision

The feature data described above is **collected** under Google's broad off-device definition.

Whether either path must also be marked **shared** depends on whether the relevant providers qualify for Google's service-provider exception under the actual terms/configuration used for this release:

- pairing path: Vercel and Upstash;
- AI path: Vercel, OpenRouter and the routed model provider.

Before answering "not shared", verify the current provider terms/DPA and Google's current service-provider exception wording. If that conclusion cannot be supported, use the conservative Play answer and declare the relevant data as shared as well.

Do not infer "not shared" merely from encryption, AES-GCM, TTL, or OpenRouter ZDR.

## Analytics — public V1 answer

For this release:

- `ZYNC_ANALYTICS_ENABLED=false` is passed explicitly by the CI and signed-release workflows;
- the client returns before creating analytics IDs or making an analytics request;
- PostHog is not required for the public V1 release.

Therefore the optional product-analytics design does **not** itself add its analytics installation ID to the public V1 Data Safety answers. This is separate from the enabled aggregate regional-interest learning described above, which has no persistent installation identifier but still needs its own off-device Data Safety assessment.

If analytics are enabled in a future release, re-open Data Safety before publishing. At minimum review:

- App activity → App interactions;
- Device or other IDs;
- purpose Analytics;
- actual provider/retention/sharing terms.

## Data that remains local / is not persisted as a cloud profile

- host profile/history as a permanent cloud object;
- Zync Again/history records;
- Interest DNA calculations;
- local match calculation and reveal state;
- custom-interest text created through the V1 interest-entry UI;
- the host QR profile body as part of relay-session creation;
- the one-time QR decryption secret.

Important distinction: the scanner's limited profile response **does** leave the scanner device during one-scan pairing, but only after application-layer encryption and only for the short relay flow described above. Do not describe V1 as "direct peer transfer only".

## Privacy policy URLs

Intended public URLs after the one-shot Vercel deployment:

- Privacy Policy: `https://zync-inky.vercel.app/privacy`
- Terms: `https://zync-inky.vercel.app/terms`
- Disclaimer: `https://zync-inky.vercel.app/disclaimer`

The Privacy Policy is plain static HTML, contains the Zync/package identity, explains the temporary encrypted relay, Vercel/Upstash/OpenRouter processing, security, retention/deletion and a privacy inquiry mechanism through the official Google Play Developer contact.

## Final submission checklist

Before saving the Data Safety form:

1. Confirm the production deployment is the new V1 and not the old 2025 `main` deployment.
2. Confirm the production relay has valid `UPSTASH_REDIS_REST_URL`, `UPSTASH_REDIS_REST_TOKEN`, and `ZYNC_RELAY_RATE_LIMIT_SECRET` server environment values without exposing them to the Android build.
3. Live-smoke the relay create -> respond -> repeated take -> consume -> expired/not-found sequence with synthetic opaque data.
4. Live-smoke AI conversation generation with the real OpenRouter key and `openrouter/free` under enforced ZDR/data-collection-deny routing.
5. Live-smoke the regional-interest popularity read endpoint and confirm aggregate weekly data can be read from the configured Upstash store.
6. Confirm `/privacy` is public, HTTPS, non-PDF, non-geofenced and readable without login/JavaScript.
7. Confirm the signed AAB was built with `ZYNC_ANALYTICS_ENABLED=false` and `ZYNC_INTEREST_LEARNING_ENABLED=true`.
8. Verify the current Play Console category wording for both AI content and the encrypted pairing-response data.
9. Verify provider/service-provider exceptions before deciding the final "shared" answers, including Upstash for the pairing path.
10. Review current Play treatment of IP/network identifiers in the final hosting configuration.
11. Ensure the Play listing no longer says "No data collected".

## Current official policy references checked 2026-09-17

- Google Play User Data / Privacy Policy requirements: https://support.google.com/googleplay/android-developer/answer/10144311
- Google Play Data Safety disclosure guidance: https://support.google.com/googleplay/android-developer/answer/10787469
- OpenRouter Free Models Router: https://openrouter.ai/openrouter/free/
- OpenRouter ZDR/data-policy routing: https://openrouter.ai/blog/insights/zero-data-retention/

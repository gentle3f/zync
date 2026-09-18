# Zync V1 — Play Release / Data Safety Status

Date: 2026-09-18  
Branch: `zync-v1-rebuild-20260917`

This file is now a status/index document. The detailed release-facing answer sheet is:

`docs/PLAY_DATA_SAFETY_V1_RELEASE_ANSWERS.md`

The production deployment procedure is:

`docs/PRODUCTION_ONE_SHOT_RELEASE_V1.md`

## Current public-V1 facts

- Package remains `com.gmail.gentle3f.myproject`.
- No login, registration or permanent cloud user profile.
- Local profile/history and matching remain primarily on-device.
- Users may manually add public Instagram, Threads or Facebook handles/profile URLs and explicitly opt each link into post-Zync sharing; this does not require a Zync account, social-media password, OAuth token or social-graph import.
- The host profile, including only social links explicitly enabled for sharing, is shared visually through the QR and is not uploaded when the relay session is created.
- One-scan pairing sends the scanner's limited profile response through a short-lived encrypted relay so the host can auto-complete the same local match; explicitly opted-in scanner social-profile links can be included in that encrypted limited response.
- The scanner response is AES-GCM encrypted on-device with a one-time 256-bit secret carried in the host QR; the Zync relay does not receive that decryption secret.
- Relay path: Android -> Zync Vercel API -> Upstash Redis; relay state expires after about three minutes and successful sessions are deleted earlier after authenticated host decryption where possible.
- Interest catalog search, custom-interest creation and exact matching are on-device; the shipped V1 UI does not use AI to normalize custom interests.
- Optional AI conversation generation transmits limited relevant interest/mode/language context off-device when invoked.
- In a one-scan session, generated question text may be held in a hashed Upstash cache for about 15 minutes so both phones receive the same semantic question; this is temporary App functionality state, not a profile/history database.
- AI path: Android -> Zync Vercel API -> OpenRouter -> compatible model provider.
- Regional discovery can transmit a coarse device-locale region plus canonical interest IDs shown/selected, aggregated weekly in Upstash Redis; it does not use GPS or precise location and has no persistent Zync user/install identifier.
- OpenRouter request routing enforces `zdr: true` and `data_collection: "deny"`.
- Configured model router: `openrouter/free`.
- Product analytics are explicitly disabled for the public V1 Android release with `ZYNC_ANALYTICS_ENABLED=false`.
- The client exits before analytics identifier creation or analytics networking when disabled.
- Public legal pages are `privacy.html`, `terms.html`, and `disclaimer.html`, routed to `/privacy`, `/terms`, and `/disclaimer` after deployment.

## Important Data Safety consequence

The old Play statement "No data collected" is not suitable for the rebuilt V1. There are feature-dependent off-device data paths for AI conversation generation (including its short-lived shared-question cache), the encrypted scanner response used by one-scan pairing (which can include a public social-profile link the scanner explicitly opted to share), and coarse-region aggregate interest-discovery signals.

Encryption, server-side opacity, ZDR, and short retention do not remove the need to consider those transmissions in Google's Data Safety form. The release answer sheet therefore treats them conservatively as collection for **App functionality** and instructs the release owner to verify the exact current Play Console category wording before submission.

## Relay privacy / retention consequence

Do not describe Zync V1 as "direct peer transfer only". Matching remains local, but the one-scan UX requires a temporary relay response.

The release design intentionally limits that relay:

- random high-entropy session identifier;
- pending status or opaque ciphertext only;
- no server-side one-time decryption key;
- payload/protocol validation and one-response semantics;
- roughly three-minute TTL with early consume/delete;
- short-lived HMAC-derived abuse-prevention counters rather than a permanent social/profile store.

The production release is not complete until the actual Upstash-backed relay is configured and live-smoked.

## Analytics consequence

The earlier optional-analytics design remains in source for a future release, but it is **not enabled in public V1**. Do not add analytics App-interaction / analytics Device-ID collection to the public V1 Data Safety form merely because the dormant code exists.

If `ZYNC_ANALYTICS_ENABLED` is ever changed to `true` in a shipped build, re-open the privacy policy and Data Safety declaration before publishing that build. The separate regional-interest learning path is intentionally enabled with `ZYNC_INTEREST_LEARNING_ENABLED=true`; it sends aggregate coarse-region/canonical-interest signals without the product-analytics installation UUID and must be assessed separately.

## Privacy policy

Intended production URL:

`https://zync-inky.vercel.app/privacy`

The policy is static browser-readable HTML, identifies Zync/package, describes local interest/history handling, optional public social-profile exchange, coarse-region aggregate discovery learning, QR sharing, the temporary encrypted relay, AI conversation data flow, Vercel/Upstash/OpenRouter providers, security, retention/deletion and a privacy inquiry mechanism using the official Google Play Developer contact.

## Remaining Play release checks

- provision/configure Upstash Redis for the production Vercel project;
- set server-only `UPSTASH_REDIS_REST_URL`, `UPSTASH_REDIS_REST_TOKEN`, and `ZYNC_RELAY_RATE_LIMIT_SECRET`;
- production V1 deployment and live API/privacy/relay/regional-interest read smoke;
- current Play Console Data Safety category wording for AI conversation content, encrypted pairing-response data, explicitly shared public social-profile handles/URLs, and coarse-region aggregate interest-discovery signals;
- provider/service-provider sharing-exception analysis, including Upstash, before final "shared" answers;
- current Play treatment of provider-processed IP/network identifiers;
- replace stale old login/remote-matching listing/screenshots;
- two-device real Android QA;
- existing Play upload key secrets;
- signed AAB certification;
- reviewer QR/access instructions.

Official policy references checked 2026-09-17:

- https://support.google.com/googleplay/android-developer/answer/10144311
- https://support.google.com/googleplay/android-developer/answer/10787469

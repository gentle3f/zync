# Zync V1 — Play Release / Data Safety Status

Date: 2026-09-17  
Branch: `zync-v1-rebuild-20260917`

This file is now a status/index document. The detailed release-facing answer sheet is:

`docs/PLAY_DATA_SAFETY_V1_RELEASE_ANSWERS.md`

The production deployment procedure is:

`docs/PRODUCTION_ONE_SHOT_RELEASE_V1.md`

## Current public-V1 facts

- Package remains `com.gmail.gentle3f.myproject`.
- No login, registration or permanent cloud user profile.
- Local profile/history and matching remain primarily on-device.
- The host profile is shared visually through the QR and is not uploaded when the relay session is created.
- One-scan pairing sends the scanner's limited profile response through a short-lived encrypted relay so the host can auto-complete the same local match.
- The scanner response is AES-GCM encrypted on-device with a one-time 256-bit secret carried in the host QR; the Zync relay does not receive that decryption secret.
- Relay path: Android -> Zync Vercel API -> Upstash Redis; relay state expires after about three minutes and successful sessions are deleted earlier after authenticated host decryption where possible.
- AI functionality transmits limited interest/conversation content off-device when invoked.
- AI path: Android -> Zync Vercel API -> OpenRouter -> compatible model provider.
- OpenRouter request routing enforces `zdr: true` and `data_collection: "deny"`.
- Configured model router: `openrouter/free`.
- Product analytics are explicitly disabled for the public V1 Android release with `ZYNC_ANALYTICS_ENABLED=false`.
- The client exits before analytics identifier creation or analytics networking when disabled.
- Public legal pages are `privacy.html`, `terms.html`, and `disclaimer.html`, routed to `/privacy`, `/terms`, and `/disclaimer` after deployment.

## Important Data Safety consequence

The old Play statement "No data collected" is not suitable for the rebuilt V1. There are feature-dependent off-device data paths for both AI functionality and the encrypted scanner response used by one-scan pairing.

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

If `ZYNC_ANALYTICS_ENABLED` is ever changed to `true` in a shipped build, re-open the privacy policy and Data Safety declaration before publishing that build.

## Privacy policy

Intended production URL:

`https://zync-inky.vercel.app/privacy`

The policy is static browser-readable HTML, identifies Zync/package, describes local data, QR sharing, the temporary encrypted relay, AI data flow, Vercel/Upstash/OpenRouter providers, security, retention/deletion and a privacy inquiry mechanism using the official Google Play Developer contact.

## Remaining Play release checks

- provision/configure Upstash Redis for the production Vercel project;
- set server-only `UPSTASH_REDIS_REST_URL`, `UPSTASH_REDIS_REST_TOKEN`, and `ZYNC_RELAY_RATE_LIMIT_SECRET`;
- production V1 deployment and live API/privacy/relay smoke;
- current Play Console Data Safety category wording for AI content and encrypted pairing-response data;
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

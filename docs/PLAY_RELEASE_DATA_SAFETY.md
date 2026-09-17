# Zync V1 — Play Release / Data Safety Status

Date: 2026-09-17  
Branch: `zync-v1-rebuild-20260917`

This file is now a status/index document. The detailed release-facing answer sheet is:

`docs/PLAY_DATA_SAFETY_V1_RELEASE_ANSWERS.md`

The production deployment procedure is:

`docs/PRODUCTION_ONE_SHOT_RELEASE_V1.md`

## Current public-V1 facts

- Package remains `com.gmail.gentle3f.myproject`.
- No login, registration or cloud user profile.
- Local profile/history and matching remain on-device.
- QR profile exchange is direct between participants; the QR body is not uploaded for matching.
- AI functionality transmits limited interest/conversation content off-device when invoked.
- AI path: Android -> Zync Vercel API -> OpenRouter -> compatible model provider.
- OpenRouter request routing enforces `zdr: true` and `data_collection: "deny"`.
- Configured model router: `openrouter/free`.
- Product analytics are explicitly disabled for the public V1 Android release with `ZYNC_ANALYTICS_ENABLED=false`.
- The client exits before analytics identifier creation or analytics networking when disabled.
- Public legal pages are `privacy.html`, `terms.html`, and `disclaimer.html`, routed to `/privacy`, `/terms`, and `/disclaimer` after deployment.

## Important Data Safety consequence

The old Play statement "No data collected" is not suitable for the rebuilt V1 because AI feature data is transmitted off-device. Google's Data Safety guidance defines collection broadly as data transmitted from the app off the user's device, including ephemeral processing.

The release answer sheet therefore treats the AI feature data as collected for **App functionality** and instructs the release owner to verify the exact current Play Console category label before submission.

## Analytics consequence

The earlier optional-analytics design remains in source for a future release, but it is **not enabled in public V1**. Do not add analytics App-interaction / Device-ID collection to the public V1 Data Safety form merely because the dormant code exists.

If `ZYNC_ANALYTICS_ENABLED` is ever changed to `true` in a shipped build, re-open the privacy policy and Data Safety declaration before publishing that build.

## Privacy policy

Intended production URL:

`https://zync-inky.vercel.app/privacy`

The policy is static browser-readable HTML, identifies Zync/package, describes local data, QR sharing, AI data flow, providers, security, retention/deletion and a privacy inquiry mechanism using the official Google Play Developer contact.

## Remaining Play release checks

- production V1 deployment and live API/privacy smoke;
- current Play Console Data Safety category wording;
- provider/service-provider sharing-exception analysis before final "shared" answer;
- replace stale old login/remote-matching listing/screenshots;
- real-device QA;
- existing Play upload key secrets;
- signed AAB certification;
- reviewer QR/access instructions.

Official policy references checked 2026-09-17:

- https://support.google.com/googleplay/android-developer/answer/10144311
- https://support.google.com/googleplay/android-developer/answer/10787469

# Zync V1 — Privacy Policy Source Note

Status: **SUPERSEDED AS A DRAFT**

The old placeholder-heavy privacy-policy draft has been replaced by the actual browser-readable release page:

- source: `privacy.html`
- production URL after V1 cutover: `https://zync-inky.vercel.app/privacy`

The current public-V1 posture is:

- no account or permanent cloud user profile;
- local profile/history and local matching;
- host profile shared visually through the QR;
- one-scan completion uses a short-lived encrypted relay for the scanner response;
- the scanner response is AES-GCM encrypted on-device with a one-time QR secret that the relay does not receive;
- relay state uses Vercel + Upstash Redis, is designed to expire after about three minutes, and is deleted earlier after successful authenticated host decryption when possible;
- interest catalog search/custom-interest creation run on-device; custom-interest text is not sent for AI normalization by the shipped V1 UI;
- coarse device-locale region plus aggregate canonical-interest impression/selection counts can be used for stable regional discovery ranking without GPS/precise location or a persistent Zync user/install identifier;
- bounded AI conversation feature data sent through the Zync Vercel API and OpenRouter;
- OpenRouter requests enforce `zdr: true` and `data_collection: "deny"`;
- `openrouter/free` is the configured model router;
- product analytics are explicitly disabled in the public V1 Android build with `ZYNC_ANALYTICS_ENABLED=false`;
- the separate aggregate regional-interest learning path is enabled with `ZYNC_INTEREST_LEARNING_ENABLED=true` and is disclosed in `privacy.html`/Data Safety;
- privacy inquiries use the official Google Play listing's Developer contact mechanism.

Do not restore or publish the earlier placeholders, and do not describe V1 as "direct peer transfer only". Edit `privacy.html` if the shipped privacy practice changes, and update Play Data Safety at the same time.

Release-facing Data Safety answers are in:

`docs/PLAY_DATA_SAFETY_V1_RELEASE_ANSWERS.md`

One-shot production procedure is in:

`docs/PRODUCTION_ONE_SHOT_RELEASE_V1.md`

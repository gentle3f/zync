# Zync V1 — Privacy Policy Source Note

Status: **SUPERSEDED AS A DRAFT**

The old placeholder-heavy privacy-policy draft has been replaced by the actual browser-readable release page:

- source: `privacy.html`
- production URL after V1 cutover: `https://zync-inky.vercel.app/privacy`

The current public-V1 posture is:

- no account or cloud user profile;
- local profile/history and local matching;
- direct QR sharing between participants;
- bounded AI feature data sent through the Zync Vercel API and OpenRouter;
- OpenRouter requests enforce `zdr: true` and `data_collection: "deny"`;
- `openrouter/free` is the configured model router;
- product analytics are explicitly disabled in the public V1 Android build with `ZYNC_ANALYTICS_ENABLED=false`;
- privacy inquiries use the official Google Play listing's Developer contact mechanism.

Do not restore or publish the earlier placeholders. Edit `privacy.html` if the shipped privacy practice changes, and update Play Data Safety at the same time.

Release-facing Data Safety answers are in:

`docs/PLAY_DATA_SAFETY_V1_RELEASE_ANSWERS.md`

One-shot production procedure is in:

`docs/PRODUCTION_ONE_SHOT_RELEASE_V1.md`

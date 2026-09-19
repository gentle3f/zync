# Zync V1 — Mini Handoff: In-App Privacy Link / Release Collateral

Date: 2026-09-17
Branch: `zync-v1-rebuild-20260917`

## Starting point

Authoritative executable certification before this slice:

- CI #88 run `35185113602` — SUCCESS
- certified code head `310360be80fc1bdd3c2c595a964172d00be87a0a`
- unsigned AAB artifact `10482286235`
- digest `sha256:37c4f68d233d0d205952ea54da1568ec74742591e7ac138bbded0407ceebaa7b`
- generic `zh` untranslated scanner warning eliminated
- OpenRouter ZDR/data-collection-deny contracts certified

Authoritative handoff created:
`AI_STATE/HANDOFF_20260917_1418_PRIVACY_HARDENED_RELEASE_CANDIDATE.md`

`AI_STATE/LATEST_HANDOFF.md` points to it.

## New release-compliance code in this slice

### In-app privacy policy entry

- Added `url_launcher ^6.3.2`.
- Home now reads compile-time `ZYNC_PRIVACY_URL`.
- Only a valid HTTPS URL is accepted.
- When configured, Home shows a localized Privacy Policy tile and opens the URL externally.
- Launch failure shows a localized snackbar.
- Added Privacy Policy / failure strings for English, generic Chinese, Traditional Chinese, Simplified Chinese, Japanese, Korean, Spanish, French and Portuguese.

### Production signed-release gate hardened

`Zync V1 Signed Release` now requires both repository variables:

- `ZYNC_API_BASE`
- `ZYNC_PRIVACY_URL`

Both must be non-empty `https://` URLs.

The signed-release workflow now actually executes `.github/scripts/live_api_smoke.mjs` before Flutter build/signing. This closes a discovered gap where the script existed but was not wired into the workflow.

The live smoke now checks:

- public privacy URL returns success;
- final URL remains HTTPS after redirects;
- privacy policy is browser-readable HTML/plain text and not PDF;
- production normalize-interest endpoint is the expected privacy-hardened V1 handler;
- production question endpoint is the expected privacy-hardened V1 handler;
- analytics endpoint is either configured successfully or returns only the expected `503 analytics_not_configured` state.

Signed AAB build receives both `ZYNC_API_BASE` and `ZYNC_PRIVACY_URL` as Dart defines.

### Normal CI

- normal CI now exposes optional `ZYNC_PRIVACY_URL` variable to release build;
- Flutter tests run with a fixed dummy HTTPS privacy URL so the production-style Home privacy entry is exercised;
- added widget smoke assertion that the localized privacy entry is visible from Home when the define is configured.

## New release collateral

Created:

- `docs/PLAY_STORE_LISTING_V1.md` — accurate rebuilt-V1 app name/short/full description and screenshot story;
- `docs/PRIVACY_POLICY_V1_DRAFT.md` — data-flow-accurate draft with explicit unresolved placeholders; do not publish as-is;
- `docs/play-reviewer-qr.html` — deterministic synthetic reviewer QR containing no real person's data;
- `docs/PLAY_REVIEWER_ACCESS.md` — one-device Play review path using the synthetic reviewer QR;
- `docs/REAL_DEVICE_QA.md` — physical-device evidence checklist.

Reviewer QR raw payload:

`{"v":1,"id":"play-reviewer-demo-v1","name":"Zync Reviewer Demo","lang":"en","i":[["sports.badminton",2],["travel.japan",1],["food.coffee",1],["technology.ai",1],["media.movies",0],["music.pop",1]]}`

## External values still intentionally unresolved

Do not invent:

- production Vercel origin / `ZYNC_API_BASE`;
- public privacy-policy URL / `ZYNC_PRIVACY_URL`;
- developer legal name/privacy contact;
- target-audience/children statement;
- analytics enabled/disabled release decision;
- analytics retention/region if enabled;
- real Play upload keystore/secrets;
- real-device QA evidence.

## Immediate next

1. Poll the newest CI triggered by this slice; fix analyzer/test/build issues if any.
2. On green, update authoritative handoff/latest with the new certified head/artifact and privacy-link release gate.
3. Align `docs/PLAY_RELEASE_DATA_SAFETY.md` / release ops docs with the new `ZYNC_PRIVACY_URL` hard requirement.
4. Continue only credential-free release-readiness work until the production Vercel origin/signing material is supplied/discovered.

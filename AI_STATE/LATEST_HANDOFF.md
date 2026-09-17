# Zync V1 — Latest Handoff

Authoritative handoff: `AI_STATE/HANDOFF_20260917_1418_PRIVACY_HARDENED_RELEASE_CANDIDATE.md`

Branch: `zync-v1-rebuild-20260917`

Read the authoritative handoff in full and continue directly from its **Recommended continuation order**. Do not restart repository discovery or old Thunkable archaeology.

Current executable state: privacy-hardened unsigned release candidate at certified head `310360be80fc1bdd3c2c595a964172d00be87a0a`. CI #88 run `35185113602` is fully green: release-script syntax, 20 serverless contracts, 2 OpenRouter ZDR/data-collection-deny privacy contracts, signing-template checks, localization with no generic-Chinese untranslated warning, `flutter analyze`, all 21 Flutter tests, release AAB build and artifact upload.

Latest certified unsigned AAB artifact: `10482286235`, size `60,827,444` bytes, digest `sha256:37c4f68d233d0d205952ea54da1568ec74742591e7ac138bbded0407ceebaa7b`.

Production `ZYNC_API_BASE` remains confirmed empty; no trustworthy Vercel production origin is known. Real Play upload-key secrets, signed AAB and real-device QA remain external blockers. Release collateral also needs to match rebuilt V1: Play listing/screenshots, Data Safety and public privacy policy. Keep mini-handoffs frequent because chat streams may time out or disappear.
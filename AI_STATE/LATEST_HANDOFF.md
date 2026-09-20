# Zync — Latest Handoff

Authoritative continuation checkpoint:

`AI_STATE/HANDOFF_20260920_GOOGLE_OAUTH_SIGNING_ROOT_CAUSE.md`

Previous authoritative continuation checkpoint:

`AI_STATE/HANDOFF_20260920_GOOGLE_CHOOSER_CANCELLED_LOCALIZED.md`

Earlier Cardverse staging checkpoint:

`AI_STATE/HANDOFF_20260920_CARDVERSE_STAGING_READINESS_CERTIFIED.md`

Canonical product/business sources:

- `docs/ZYNC_BUSINESS_PROPOSAL_AND_VISION.md`
- `docs/ZYNC_MASTER_EXECUTION_PLAN.md`
- `docs/ZYNC_V1_PRODUCT_SPEC.md`
- `docs/REAL_DEVICE_QA.md`
- `docs/ZYNC_CARDVERSE_ARCHITECTURE_V1.md`
- `docs/ZYNC_CARDVERSE_CLOUD_OWNERSHIP_V1.md`
- `docs/ZYNC_CARDVERSE_LIVE_DEPLOYMENT_CHECKLIST_V1.md`

Branch:

`zync-v1-rebuild-20260917`

Read the authoritative continuation checkpoint **in full** before doing any work. Preserve earlier additive handoff lineage. Do not restart repository discovery or old Thunkable archaeology.

Current certified facts:

- Official current Google guidance confirms Android Sign in with Google needs both Android OAuth (package + SHA-1) and Web OAuth clients.
- The exact real-device APK `ed744e...` is signed by Android Debug SHA-1 `02:13:4C:52:5D:99:82:79:DD:D1:22:E4:27:52:00:05:FF:CC:83:97`.
- Multiple historical QA APKs have different Android Debug SHA-1 fingerprints, proving the old QA pipeline used ephemeral signing.
- Commit `292c6bf7079b73e31aabb38f86b6054874fc4c79` adds official-context alignment, sanitized native diagnostics, and fail-closed stable QA signing.
- The new QA build correctly failed because no stable Android signing secrets are currently configured.
- The fastest confirmation is to register Android OAuth for `com.gmail.gentle3f.myproject.qa` + the exact installed APK SHA-1 and retry that exact APK.
- Production remains CLOSED.
- Google Play remains CLOSED.
- Draft PR #1 remains DO NOT MERGE.

Current active task:

> **Register the one-off Android OAuth client for the exact installed QA APK (package `com.gmail.gentle3f.myproject.qa`, SHA-1 `02:13:4C:52:5D:99:82:79:DD:D1:22:E4:27:52:00:05:FF:CC:83:97`), retry Google sign-in on that exact APK, and use the appearance of `/api/v1/cardverse/auth/provider` as the stage gate. After confirmation, finalize a stable QA signing key + permanent Android OAuth client without opening Production or Play.**

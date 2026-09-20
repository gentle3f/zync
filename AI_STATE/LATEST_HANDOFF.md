# Zync — Latest Handoff

Authoritative continuation checkpoint:

`AI_STATE/HANDOFF_20260920_GOOGLE_CHOOSER_CANCELLED_LOCALIZED.md`

Previous authoritative continuation checkpoint:

`AI_STATE/HANDOFF_20260920_GOOGLE_LOGIN_DEVICE_SMOKE_READY.md`

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

- First real-device Google login smoke reaches the native account chooser.
- Selecting an account returns to Zync without a Cardverse session; one captured UI result is `google_sign_in_cancelled`.
- Latest Vercel runtime logs show POST `/api/v1/cardverse/auth/challenge` -> 200 for the device attempts and **no** subsequent POST `/api/v1/cardverse/auth/provider`.
- Staging Neon still has 0 `zync_accounts` and 0 `zync_account_sessions`.
- Therefore the failure is localized after Cardverse challenge creation and before Google ID-token handoff/provider exchange.
- Current Kotlin bridge uses `MutableContextWrapper(this)` in `CredentialManager.getCredentialAsync`; verify this against current official docs before changing it.
- Vercel Cardverse consolidation remains certified at 10 functions total.
- Preview `CARDVERSE_API_ENABLED=true` is active for controlled smoke; other Cardverse feature gates remain closed.
- Production remains CLOSED.
- Google Play remains CLOSED.
- Draft PR #1 remains DO NOT MERGE.

Current active task:

> **Continue directly from the localized Android/Google credential failure: verify current official Credential Manager Sign in with Google requirements, instrument sanitized QA-only native error detail, fix the Activity/context or OAuth configuration mismatch if confirmed, build a new QA APK, and repeat device smoke without weakening nonce/JWT/session security.**

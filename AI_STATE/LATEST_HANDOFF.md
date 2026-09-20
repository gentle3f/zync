# Zync — Latest Handoff

Authoritative continuation checkpoint:

`AI_STATE/HANDOFF_20260920_GOOGLE_LOGIN_DEVICE_SMOKE_READY.md`

Previous authoritative continuation checkpoint:

`AI_STATE/HANDOFF_20260920_CARDVERSE_STAGING_READINESS_CERTIFIED.md`

Earlier staging/schema checkpoint:

`AI_STATE/HANDOFF_20260920_NEON_STAGING_SCHEMA_CERTIFIED.md`

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

- Vercel Cardverse function consolidation is live and fits Hobby: 10 total JS functions.
- Stable Preview branch alias is live with `CARDVERSE_API_ENABLED=true`.
- GET challenge route returns 405/POST and inventory returns 401/session-missing, proving the Cardverse gate/router/session enforcement are active.
- GitHub `ZYNC_GOOGLE_SERVER_CLIENT_ID` is configured.
- Zync V1 CI #1028 — SUCCESS.
- Zync QA Preview APK #309 — SUCCESS.
- QA APK includes nonce-bound Android Credential Manager Google sign-in and the QA-only Cardverse account smoke screen.
- Preview branch auto-deploy is re-closed in source after smoke setup.
- Production remains CLOSED.
- Google Play remains CLOSED.
- Draft PR #1 remains DO NOT MERGE.

Current active task:

> **Install the certified QA APK and run the first real-device Google → Cardverse account/session smoke. Diagnose any failure at the exact stage without weakening nonce, issuer, audience, session, database, or abuse-guard checks. If login succeeds, verify staging account/session creation and then advance to controlled proof-redemption smoke.**

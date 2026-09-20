# Zync — Latest Handoff

Authoritative continuation checkpoint:

`AI_STATE/HANDOFF_20260920_NEON_STAGING_SCHEMA_CERTIFIED.md`

Previous authoritative continuation checkpoint:

`AI_STATE/HANDOFF_20260920_DURABLE_OWNERSHIP_TRUSTED_PROOF_CERTIFIED.md`

Previous certified implementation / physical-QA checkpoint before the Cardverse expansion:

`AI_STATE/MINI_HANDOFF_20260919_OCTALYSIS_BATCH1_QA_CERTIFIED.md`

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

Read the authoritative continuation checkpoint **in full** before doing any work. Preserve earlier additive handoff lineage. Do not restart repository discovery, old Thunkable archaeology, or re-derive the Cardverse trust boundary.

Certified implementation head before the latest infrastructure docs commits:

`346b8daf95eca4006cadfcd2f48a1b9e24ac4e0d`

Certified checks at that implementation head:

- Zync V1 CI #986 — SUCCESS
- Zync QA Preview APK #279 — SUCCESS

Current state in one sentence:

> Milestone 5 has CI-certified Cardverse ownership/auth/reward/proof hardening plus a real Neon PostgreSQL project with an isolated `staging-cardverse` branch where migrations 0001–0006 and key schema invariants are verified; the remaining blocker is controlled Vercel staging configuration (DATABASE_URL, Redis/secrets, provider audience), followed by readiness and real login/proof-sync smoke tests.

Current active task:

> **Connect the certified Neon staging database to an isolated Vercel Preview/staging deployment, keep Cardverse API off initially, configure readiness/provider prerequisites, then require readiness=true before real-provider smoke testing.**

Important:

- Cardverse Labs remain internal.
- Production remains CLOSED.
- Google Play remains CLOSED.
- Draft PR #1 remains DO NOT MERGE.
- All Cardverse runtime gates stay disabled unless explicitly enabled.
- Do not expose Neon connection strings or secret values in source, chat, logs, or handoff files.

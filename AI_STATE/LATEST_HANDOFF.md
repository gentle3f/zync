# Zync — Latest Handoff

Authoritative continuation checkpoint:

`AI_STATE/HANDOFF_20260920_CARDVERSE_STAGING_READINESS_CERTIFIED.md`

Previous authoritative continuation checkpoint:

`AI_STATE/HANDOFF_20260920_NEON_STAGING_SCHEMA_CERTIFIED.md`

Earlier durable ownership / trusted-proof checkpoint:

`AI_STATE/HANDOFF_20260920_DURABLE_OWNERSHIP_TRUSTED_PROOF_CERTIFIED.md`

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

Previously certified implementation head:

`346b8daf95eca4006cadfcd2f48a1b9e24ac4e0d`

Previously certified checks:

- Zync V1 CI #986 — SUCCESS
- Zync QA Preview APK #279 — SUCCESS

Current state in one sentence:

> Cardverse managed PostgreSQL staging is provisioned and migrated, Vercel Preview live readiness now passes database + Redis abuse guard + Google provider-audience prerequisites, and the preview gate has been re-closed; the active blocker for real end-to-end login smoke is the Vercel Hobby 12-function cap plus Android OAuth/signing integration.

Current active task:

> **Safely consolidate Vercel API entrypoints to fit the Hobby 12-function limit without weakening route/security boundaries, then establish stable Android QA signing SHA-1, create the Android Google OAuth client, integrate Google Sign-In with the existing nonce challenge, and run controlled real-device login/session/proof-sync staging smoke.**

Important:

- Cardverse Labs remain internal.
- Production remains CLOSED.
- Google Play remains CLOSED.
- Draft PR #1 remains DO NOT MERGE.
- `git.deploymentEnabled.zync-v1-rebuild-20260917=false` is restored after readiness certification.
- Cardverse global API must remain disabled except for explicit controlled staging smoke.
- Do not expose Neon connection strings, provider tokens, Redis tokens, or secret values.

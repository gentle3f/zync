# Zync — Latest Handoff

Authoritative continuation checkpoint:

`AI_STATE/HANDOFF_20260920_DURABLE_OWNERSHIP_TRUSTED_PROOF_CERTIFIED.md`

Previous authoritative continuation checkpoint:

`AI_STATE/HANDOFF_20260920_CARDVERSE_REWARD_LOOP_CERTIFIED.md`

Previous certified implementation / physical-QA checkpoint before the Cardverse expansion:

`AI_STATE/MINI_HANDOFF_20260919_OCTALYSIS_BATCH1_QA_CERTIFIED.md`

Canonical product/business sources:

- `docs/ZYNC_BUSINESS_PROPOSAL_AND_VISION.md`
- `docs/ZYNC_MASTER_EXECUTION_PLAN.md`
- `docs/ZYNC_V1_PRODUCT_SPEC.md`
- `docs/REAL_DEVICE_QA.md`
- `docs/ZYNC_CARDVERSE_ARCHITECTURE_V1.md`
- `docs/ZYNC_CARDVERSE_CLOUD_OWNERSHIP_V1.md`
- `docs/ZYNC_CARD_VISUAL_SPEC_V1.md`
- `docs/ZYNC_CARD_GENERATION_PIPELINE_V1.md`

Branch:

`zync-v1-rebuild-20260917`

Read the authoritative continuation checkpoint **in full** before doing any work. Preserve earlier additive handoff lineage. Do not restart repository discovery, old Thunkable archaeology, or re-derive the Cardverse trust boundary.

Certified implementation head before the handoff-doc update:

`dfeda4cb06515bce39102605d6815586ad1067d3`

Certified checks at that implementation head:

- Zync V1 CI push #867 — SUCCESS
- Zync V1 CI PR #868 — SUCCESS
- Zync QA Preview APK #224 — SUCCESS

Current state in one sentence:

> Milestone 5 now has transactional PostgreSQL Cardverse ownership, authenticated account/session primitives, server-authoritative pack opening, immutable inventory/reward ledgers, fail-closed pack policy, a privacy-preserving trusted 1:1 relay completion-proof issuer, authenticated proof redemption, secure mobile bearer storage and proof sync foundations; all are CI-certified, but live provider/database configuration, abuse controls and production account UX remain closed.

Current active task:

> **Milestone 5 continuation — harden the live cloud boundary with rate limits / abuse controls and account lifecycle, then prepare real managed PostgreSQL + provider configuration.**

Important:

- Cardverse Labs remain internal.
- Production remains CLOSED.
- Google Play remains CLOSED.
- Draft PR #1 remains DO NOT MERGE.
- All Cardverse runtime gates stay disabled unless explicitly enabled.

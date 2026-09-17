# Zync V1 — Latest Handoff

Authoritative continuation checkpoint: `AI_STATE/MINI_HANDOFF_20260918_QA_APK_READY.md`

Previous external-relay checkpoint: `AI_STATE/MINI_HANDOFF_20260918_UPSTASH_PREVIEW_SMOKE_PASS.md`

Previous certified implementation handoff: `AI_STATE/HANDOFF_20260918_RELAY_PAIRING_RESPONSIVE_CERTIFIED.md`

Canonical business/product narrative: `docs/ZYNC_BUSINESS_PROPOSAL_AND_VISION.md`

Branch: `zync-v1-rebuild-20260917`

Read the latest continuation checkpoint first. Do not restart repository discovery or old Thunkable archaeology. Preserve all earlier additive handoff lineage.

Current state: the encrypted one-scan relay code is certified; the existing Upstash database is connected to Vercel; the controlled preview passed a real Vercel -> Upstash relay lifecycle smoke; and a separate-install `Zync QA` APK pointed at that preview has been built and uploaded successfully. Stable production remains unchanged.

Current active task is two-device Android physical QA. Use the artifact recorded in `MINI_HANDOFF_20260918_QA_APK_READY.md`. Do not redeploy/promote production or upload Play yet.

Branch auto-deploy is disabled. Preview Vercel Authentication is temporarily off only for controlled QA and should be re-enabled after physical QA. Preserve package/version/signing/Play guards, privacy posture and the frozen V1 product scope.

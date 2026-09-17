# Zync V1 — Latest Handoff

Authoritative continuation checkpoint: `AI_STATE/MINI_HANDOFF_20260918_UPSTASH_PREVIEW_SMOKE_PASS.md`

Previous certified implementation handoff: `AI_STATE/HANDOFF_20260918_RELAY_PAIRING_RESPONSIVE_CERTIFIED.md`

Canonical business/product narrative: `docs/ZYNC_BUSINESS_PROPOSAL_AND_VISION.md`

Branch: `zync-v1-rebuild-20260917`

Read the continuation checkpoint first, then the previous certified handoff only if more implementation context is needed. Do not restart repository discovery or old Thunkable archaeology. Preserve all earlier additive handoff lineage.

Current state: the encrypted one-scan relay code remains certified; the user has now linked the existing Upstash Redis database to Vercel `zync`, added the required rate-limit secret, and a controlled preview deployment passed a real Vercel -> Upstash relay lifecycle smoke including host-only authorization, duplicate protection, consume/delete and Redis TTL cleanup. Stable production remains unchanged.

Current active task is the two-device Android physical QA gate. A separate-install `Zync QA` APK is being built against the controlled preview in GitHub Actions run `35249635868`. Continue directly from that run; do not redeploy production or upload Play.

Branch auto-deploy is disabled again. Preview Vercel Authentication is temporarily off only for controlled QA and should be re-enabled after physical QA. Preserve package/version/signing/Play guards, privacy posture and the frozen V1 product scope.

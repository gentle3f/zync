# Zync V1 — Latest Handoff

Authoritative handoff: `AI_STATE/HANDOFF_20260918_RELAY_PAIRING_RESPONSIVE_CERTIFIED.md`

Canonical business/product narrative: `docs/ZYNC_BUSINESS_PROPOSAL_AND_VISION.md`

Branch: `zync-v1-rebuild-20260917`

Read the authoritative handoff in full and continue directly from its **Recommended continuation order**. Do not restart repository discovery or old Thunkable archaeology. This handoff is additive on top of `AI_STATE/HANDOFF_20260917_ENCRYPTED_RELAY_INTEGRATION_IN_PROGRESS.md`, `AI_STATE/HANDOFF_20260917_PLAY_INTERNAL_RELEASE_AUTOMATION.md`, and all earlier release/privacy lineage.

The one-scan encrypted relay + responsive normal-phone UI code is certified at code SHA `ee2d8409f8e1719fd9be035ecdba0e076425132d` by Zync V1 CI run #157 / `35246251340`, including analyze, Flutter tests and unsigned AAB build/upload.

The relay is **not live**. Upstash has been user-approved but is not yet provisioned/connected and the required server-only Vercel environment values have not been set. Stable production is still the old 2025 deployment. Do not deploy, promote, publish or claim production readiness until the controlled preview/live-smoke + two-device physical QA gates in the authoritative handoff are completed.

Keep branch auto-deploy disabled. Preserve package/version/signing/Play guards, privacy posture and the frozen V1 product scope.

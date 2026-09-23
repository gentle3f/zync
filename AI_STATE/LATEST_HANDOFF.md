# Zync — Latest Handoff

## Mandatory first read

Read and obey `AI_STATE/OPERATING_RULES.md` before any write, commit, push, PR,
CI, Vercel, deployment or external-infrastructure action.

Authoritative continuation checkpoint:

`AI_STATE/HANDOFF_20260923_CARD_ART_BULK_FIRST_100_READY.md`

Previous routing split:

`AI_STATE/HANDOFF_20260923_CARD_ART_BULK_ROUTING_SPLIT_V1.md`

Branch:

`card-art-pilot-v1-20260921`

Current state:

> **The catalog is now back on the scalable bulk-production path. The Ice Fishing data bug is fixed: outdoors.ice_fishing now resolves explicitly to water_outdoors / water_ritual, has been removed from blocked, added to BULK-FIRST, and is included as a forced validation probe. Routing counts are now BULK-FIRST 1731, HOLDOUT 477, QUARANTINED 2 (sports.american_football + technology.robotics), total 2210. A stratified 100-card BULK-FIRST validation set is prepared in tools/card_art/catalog/bulk_first_100_validation_v1.json with a runner at tools/card_art/src/runBulkFirst100Validation.js. It covers all 32 BULK-FIRST archetypes, contains 100 unique BULK-FIRST IDs, deliberately includes repaired/boundary probes, and is Standard FLUX only. Estimated cost if executed: $1.25. No image generation has been run yet. Next: run `cd tools/card_art && node src/runBulkFirst100Validation.js --dry-run`; only if clean, run `node src/runBulkFirst100Validation.js`, inspect all 100 individually, and report clustered/systemic failures. Do not invalidate BULK-FIRST for isolated one-card failures; route isolated failures later to the user's manual Image 2.5 queue. Do not use Image 2.5 through fal.ai. Do not auto-start the 1731-card bulk run. Keep Vercel, GitHub Actions, Production and Play closed.**

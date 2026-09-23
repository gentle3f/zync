# Zync — Latest Handoff

## Mandatory first read

Read and obey `AI_STATE/OPERATING_RULES.md` before any write, commit, push, PR,
CI, Vercel, deployment or external-infrastructure action.

Authoritative continuation checkpoint:

`AI_STATE/HANDOFF_20260923_CARD_ART_STRATIFIED_48_RESULTS.md`

(previous checkpoint, still useful for batch/setup context:
`AI_STATE/HANDOFF_20260923_CARD_ART_STRATIFIED_48_READY.md`)

Branch:

`card-art-pilot-v1-20260921`

Current state:

> **The 48-card stratified validation is done: 48/48 API calls succeeded, $0.582 actual spend, all 48 images visually inspected. Overall: 24 PASS (50%), 6 MINOR (12.5%), 18 FAIL (37.5%). Standard FLUX: 14/32 PASS (43.8%), 13 FAIL (40.6%). Klein+negative_prompt: 10/16 PASS (62.5%), 5 FAIL (31.3%), but 8/16 (50%) show MATERIAL style drift toward photoreal/stock-photo. ROOT CAUSE FOUND: the compiled prompt's own "LABEL (identifier):" section-header format (e.g. "VISUAL VARIANT (heat_room):") gets echoed back by the model as literal on-image captions — confirmed verbatim on wellness.sauna ("HEAT ROOM", "LISUAT VARIANT") and wellness.hot_springs ("IMMERSION_RITUAL"), and accounts for 9 of the 18 failures across BOTH routes. This is not primarily a route-allocation problem. Do NOT scale up generation yet. Recommended next step: fix the prompt-format root cause in buildPromptV1.js (stop presenting raw variant/archetype ids as a title-like pattern), then re-validate a small 8-card targeted sample (~$0.10) before considering a ~100-card next batch. Full 48-row QA table and defect classification in the results handoff. Keep Vercel, GitHub Actions, Production and Play closed.**

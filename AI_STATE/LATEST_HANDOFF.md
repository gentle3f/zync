# Zync — Latest Handoff

## Mandatory first read

Read and obey `AI_STATE/OPERATING_RULES.md` before any write, commit, push, PR,
CI, Vercel, deployment or external-infrastructure action.

Authoritative continuation checkpoint:

`AI_STATE/HANDOFF_20260923_CARD_ART_BULK_FIRST_100_RESULTS.md`

(previous checkpoint, still useful for validation design context:
`AI_STATE/HANDOFF_20260923_CARD_ART_BULK_FIRST_100_READY.md`)

Previous routing split (now superseded — see current state):

`AI_STATE/HANDOFF_20260923_CARD_ART_BULK_ROUTING_SPLIT_V1.md`

Branch:

`card-art-pilot-v1-20260921`

Current state:

> **The 100-card BULK-FIRST validation ran (100/100 Standard FLUX, $1.25 actual) and FAILED decisively: 72/100 FAIL, 14 MINOR, 14 PASS - a 72% failure rate, clustered across nearly every one of the 32 BULK-FIRST archetypes, not isolated. Do NOT start the 1731-card bulk run; the BULK-FIRST/HOLDOUT split is now considered superseded pending rework, not a ready production queue. Root cause: ~25 of 32 BULK-FIRST archetypes rely on generic ${title}-only composition templates with no per-hobby content anchor (unlike the small set of hand-engineered archetypes - aviation_world, campaign_planning, legal_practice, shared_workspace - which came out of the earlier remediation arc and mostly held up). Without an anchor, the model defaults to: a generic camera/gadget scene unrelated to the hobby (dominant failure, ~50+ cards - hit companion_bond 3/3, calm_wellness 3/3, learning_exploration 4/4, journey_machine 3/3, home_lifestyle 3/3, nature_immersion 3/3 all producing near-identical wrong scenes, outdoor_motion 2/2, lens_perspective 2/2, many food_hero dish-specific mismatches); readable code/UI screens (~20+ cards, including a regression in previously-confirmed-clean business.coworking); readable storefront text/signage leakage in urban_discovery (new finding, 3/4); video-game controllers intruding into board-game scenes in group_play/strategy_table (new finding); and a content-safety/nudity-adjacent concern in wellness.sauna/wellness.hot_springs (new finding, needs its own dedicated review, separate from the rest). The rounded card-border/chrome defect recurred at least 5 times in just this 100-card sample (~5%) - materially more frequent than the prior "sparse, 2 observations project-wide" classification; treat as a live risk, not background noise. sports.archery/fencing/badminton - the exact brand-safe-fixed cluster confirmed working in an earlier round - all regressed and failed this time, showing real run-to-run stochastic variance even in archetypes with detailed engineered prompts. outdoors.ice_fishing's routing fix is confirmed technically working (compiles, no crash) but its generated content still failed (paddleboarding, not ice fishing) - same generic-template problem as everything else. Recommended next steps (not executed): do not treat any archetype as bulk-safe from a single pass; prioritize content-anchor rewrites for the highest-volume failing archetypes (food_hero 255, music_listening 272, story_culture 188, travel_vista 183) sequenced, not all at once; open a dedicated content-safety review for wellness_experience before generating spa/sauna-adjacent hobbies again; investigate the controller-intrusion pattern as its own small question; re-scope the whole BULK-FIRST/HOLDOUT split rather than resuming bulk generation on the current one. sports.american_football and technology.robotics remain quarantined and untouched. No Image 2.5 used via fal.ai. Keep Vercel, GitHub Actions, Production and Play closed.**

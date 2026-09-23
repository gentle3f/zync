# Zync — Latest Handoff

## Mandatory first read

Read and obey `AI_STATE/OPERATING_RULES.md` before any write, commit, push, PR,
CI, Vercel, deployment or external-infrastructure action.

Authoritative continuation checkpoint:

`AI_STATE/HANDOFF_20260923_CARD_ART_SCALE_100_RESULTS.md`

(previous checkpoint, still useful for batch/setup context:
`AI_STATE/HANDOFF_20260923_CARD_ART_SCALE_100_READY.md`)

Branch:

`card-art-pilot-v1-20260921`

Current state:

> **The 100-card scale validation ran (100/100 API calls, $1.222 actual). RESULT: DO NOT SCALE UP. Overall 47% PASS / 11% MINOR / 42% FAIL. Klein underperformed standard FLUX (36.0% PASS vs 50.7% PASS) and showed 52% MATERIAL style drift. BOTH sentinel re-tests still FAIL: sports.american_football still shows a jersey number + swoosh-like mark on Klein (and 3 more team-sport Klein cards confirm this generalizes — only baseball was clean); food.yum_cha still shows residual signage on Klein (and 4 more ethnic-food/market Klein cards were 4/4 FAIL on the identical defect, 5/5 overall). Failures correlate strongly with archetype, not randomly: reading_world and food_exploration are 100% FAIL, tech_workspace 80%, professional_world 71%, travel_vista 75% — while fitness_training, music_listening, home_lifestyle, campus_activity, lens_perspective were perfect or near-perfect. One execution blocker was found and fixed before spending: a raw archetype id ("travel_vista") had leaked into archetypes_v1.json's lens_perspective avoid-list content (unrelated to the earlier compiler-format fix); fixed the content and broadened buildPromptV1.js's regression guard to check against all known ids, not just the current hobby's own. Recommended next step: targeted content fixes to the professional_world and tech_workspace archetype templates, a small diagnostic test on the ethnic-food and uniform-sports classes, then a small ~15-20 card re-validation — not another 100+ batch. Keep Vercel, GitHub Actions, Production and Play closed.**

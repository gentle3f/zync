# Zync — Latest Handoff

## Mandatory first read

Read and obey `AI_STATE/OPERATING_RULES.md` before any write, commit, push, PR,
CI, Vercel, deployment or external-infrastructure action.

Authoritative continuation checkpoint:

`AI_STATE/HANDOFF_20260923_CARD_ART_PROMPT_FORMAT_VALIDATION_RESULTS.md`

(previous checkpoint, still useful for fix design context:
`AI_STATE/HANDOFF_20260923_CARD_ART_PROMPT_FORMAT_FIX_READY.md`)

Branch:

`card-art-pilot-v1-20260921`

Current state:

> **The prompt-format root-cause fix is validated. The 8-card targeted batch ran (7 standard FLUX + 1 Klein, 8/8 API calls, $0.098 actual). Root-cause validation PASS: all 4 strongest test cases (wellness.sauna, wellness.hot_springs, learning.philosophy, learning.book_genre.booktok) show zero internal-id/caption leakage (no more "HEAT ROOM"/"IMMERSION_RITUAL"/garbled "VISUAL VARIANT"). Of the 4 secondary standard-FLUX tests, 2 were fixed by the compiler change alone (sports.gravel_cycling PASS, gaming.escape_room_design MINOR) and 2 remain genuine model-suppression failures unrelated to the compiler bug (food.yum_cha signage, sports.american_football jersey/logo) - both are known, addressable via Klein routing. One execution blocker was found and fixed before any spend: the regression guard's regex was case-insensitive and matched anywhere in text, so it false-positived on the compiler's own new prose ("must include:") and would have failed 100% of hobbies; now anchored to line-start, case-sensitive, matching only the old ALL-CAPS header format. 6 of 8 cards in this validation are PASS/MINOR. Conclusion: ready to proceed to the ~100-card batch, keeping standard flux-2 as default and adding jersey/uniform-branded-sports and ethnic-signage-heavy food/market classes to the Klein-routed list alongside the previously identified group_play/fashion classes. Not yet executed. Keep Vercel, GitHub Actions, Production and Play closed.**

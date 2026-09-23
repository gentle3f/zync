# Zync — Latest Handoff

## Mandatory first read

Read and obey `AI_STATE/OPERATING_RULES.md` before any write, commit, push, PR,
CI, Vercel, deployment or external-infrastructure action.

Authoritative continuation checkpoint:

`AI_STATE/HANDOFF_20260923_CARD_ART_ARCHETYPE_FIX_RESULTS.md`

(previous checkpoint, still useful for fix design context:
`AI_STATE/HANDOFF_20260923_CARD_ART_ARCHETYPE_FIX_READY.md`)

Branch:

`card-art-pilot-v1-20260921`

Current state:

> **The 20-card archetype-fix validation ran (14 standard FLUX + 6 Klein, 20/20 API calls, $0.243 actual). Mixed result: moved from 0% PASS / 90% FAIL (scale-100 baseline for these exact 20 IDs) to 55% PASS / 5% MINOR / 40% FAIL. BOTH sentinel classes are now fully solved: food.yum_cha and food.food_markets are completely clean (2/2, first clean result after 3 prior rounds), and sports.american_football and sports.football are completely clean (2/2, first clean result after 2 prior rounds). tech_workspace and reading_world substantially improved (their original text/code defects are essentially eliminated). professional_world improved only partially (business.coworking/business.marketing still substitute a generic unrelated workshop scene - a recognition problem, not a text problem) and travel_vista is mixed (travel.destination_deep.tokyo_travel is a clean win via Tokyo Tower architecture, but travel.japan still shows signage and travel.general got WORSE, gaining a large "Travel" title plus a full paragraph of gibberish caption text). A NEW cross-cutting defect emerged: spontaneous hobby-title caption text appearing independent of archetype (legal_profession, generative_ai, travel.general) - now the dominant remaining failure mode, not caught by the per-archetype "no text" language. Klein style drift got WORSE in this sample: 83% MATERIAL (vs 52% in the 100-card batch). No execution blocker found this task; no code changes made. Not ready for another 100+ batch. Recommended next step: add a global (not per-archetype) constraint against hobby-title captions, give business.coworking/business.marketing their own concrete hobby-specific subject text (following the pattern that worked for business.startups), then re-test a small sample before any further scale. Keep Vercel, GitHub Actions, Production and Play closed.**

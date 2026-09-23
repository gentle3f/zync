# Zync — Latest Handoff

## Mandatory first read

Read and obey `AI_STATE/OPERATING_RULES.md` before any write, commit, push, PR,
CI, Vercel, deployment or external-infrastructure action.

Authoritative continuation checkpoint:

`AI_STATE/HANDOFF_20260924_CARD_ART_STYLE_CALIBRATION_D4_RESULTS.md`

(previous checkpoints, still useful for context:
`AI_STATE/HANDOFF_20260924_CARD_ART_STYLE_CALIBRATION_D123_RESULTS.md`,
`AI_STATE/HANDOFF_20260924_CARD_ART_STYLE_CALIBRATION_ABC_RESULTS.md`,
`AI_STATE/HANDOFF_20260924_CARD_ART_GEMINI31_FLASH_LITE_RESULTS.md`,
`AI_STATE/HANDOFF_20260923_CARD_ART_GEMINI25_DIRECT_BATCH_RESULTS.md`,
`AI_STATE/HANDOFF_20260923_CARD_ART_SEMANTIC_ANCHOR_REVALIDATION_RESULTS.md`)

Branch:

`card-art-pilot-v1-20260921`

Current state:

> **House-style D4 calibration ran (successor to D1/D2/D3, where D3 was strongest but still read as ordinary anime lifestyle illustration rather than an iconic collectible moment): same 6 hobbies x 1 special-illustration/full-art style candidate = 6 images on gemini-3.1-flash-lite-image direct, $0.1008 actual, 6/6 returned. DECISIVE, visually clear improvement over D3: D4 consistently replaces "several people doing an activity together" staging with a single dramatic/emotional focal peak - a mid-air dice roll with a sparkle trail at the decisive board-game moment, a dramatic courtroom accusation glowing on-screen with a visibly tense viewer reacting in the foreground, noodles lifted mid-bite with steam and genuine joy. Zero card-border/fake-TCG-UI defects this round (0/6, vs D1's severe 1/6 occurrence) - deliberately reducing literal "trading card"/"collectible card"/"card frame" phrasing per instruction appears to have worked. Production global_style_v1.json never touched (verified via git status); prefix-check confirmed the injected D4 style block compiled correctly before any paid call (weaker guarantee than the cross-version diffs used in A/B/C and D1/D2/D3 since D4 has no sibling style this round to diff against - disclosed plainly). Semantic: 5/6 PASS, 1/6 MINOR - learning.philosophy's antique diagram-covered tome reads closer to an occult/alchemical grimoire than clearly modern philosophy content, the exact drift the task's own semantic guard warned against, despite otherwise excellent "intellectual excitement" staging. Also flagged: fashion.streetwear shows a light checkmark/swoosh-like mark on a sneaker, a possible trademark-adjacent risk worth a follow-up spot-check. Aggregate scores (0-4): anime feel 3.5, NEW special-illustration feel 3.33, joy 3.5, collectible appeal 3.42, NEW hero focus 3.25, distinctiveness 2.67, fantasy drift 0.29 (down from D3's 0.58), maturity 3.67, border defect 0%. RECOMMENDATION: D4 is the new recommended style baseline - promote it to production global_style_v1.json explicitly (not done automatically here). No reference-conditioned gemini-3.1-flash-image test needed - text-only calibration is still improving round over round, not stalling. Recommended next steps (not executed): small isolated follow-up on philosophy's prop choice (a hobby-recipe fix, not a global-style fix, since the other 5 hobbies show no comparable drift); spot-check streetwear's footwear rendering across a couple more generations; scalability validation across uncovered categories before any larger commitment. Found an untracked output/style_calibration_d_18_v1/images/d.zip in the working tree at task start (presumably user-created for local review) - left untouched, not staged in any commit. No fal.ai route used. No 18/24/100/2210-card batch started. sports.american_football and technology.robotics remain quarantined and untouched. Keep GitHub Actions, Vercel, Production and Play closed.**

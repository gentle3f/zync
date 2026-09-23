# Zync — Latest Handoff

## Mandatory first read

Read and obey `AI_STATE/OPERATING_RULES.md` before any write, commit, push, PR,
CI, Vercel, deployment or external-infrastructure action.

Authoritative continuation checkpoint:

`AI_STATE/HANDOFF_20260923_CARD_ART_CAPTION_REMEDIATION_RESULTS.md`

(previous checkpoint, still useful for fix design context:
`AI_STATE/HANDOFF_20260923_CARD_ART_CAPTION_REMEDIATION_READY.md`)

Branch:

`card-art-pilot-v1-20260921`

Current state:

> **The 8-card caption-remediation validation ran (7 standard + 1 Klein, 8/8 API calls, $0.098 actual). DECISION GATE NOT MET - do not start a 50-card batch. Title/caption suppression is CONFIRMED WORKING: all 3 cross-archetype cases (career.legal_profession, technology.generative_ai, travel.general) lost their caption/poster-layout defect, including travel.general which was previously the worst offender (full "Travel" title + gibberish paragraph + text box, now completely clean). But coworking/marketing recognition did NOT improve: business.coworking and business.marketing, plus career.legal_profession independently, all collapsed into a near-identical unrelated "jewelry/watchmaking workshop with child apprentices" scene despite each having detailed, hobby-specific exact-ID prompt content with explicit exclusions - this looks like a genuine professional_world archetype model-prior, not a missing-instruction problem. learning.book_genre.booktube's new creator/recording cue was also completely ignored (still plain reading, Klein style drift MATERIAL). technology.electronics (control) showed a minor, arguable regression (illegible screen-clutter increase, not clear text). Overall this round: 2 PASS / 1 MINOR / 5 FAIL. Recommended smallest next step (not executed): a cheap 2-card diagnostic reroll of coworking/marketing to confirm the workshop-scene prior is deterministic, then a structural visual_variant change for those two hobbies (same pattern that fixed uniform-sports/ethnic-food) rather than more prompt wording. Keep Vercel, GitHub Actions, Production and Play closed.**

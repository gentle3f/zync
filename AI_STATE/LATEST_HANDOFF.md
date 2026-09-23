# Zync — Latest Handoff

## Mandatory first read

Read and obey `AI_STATE/OPERATING_RULES.md` before any write, commit, push, PR,
CI, Vercel, deployment or external-infrastructure action.

Authoritative continuation checkpoint:

`AI_STATE/HANDOFF_20260924_CARD_ART_STYLE_CALIBRATION_ABC_RESULTS.md`

(previous checkpoints, still useful for context:
`AI_STATE/HANDOFF_20260924_CARD_ART_GEMINI31_FLASH_LITE_RESULTS.md`,
`AI_STATE/HANDOFF_20260923_CARD_ART_GEMINI25_DIRECT_BATCH_RESULTS.md`,
`AI_STATE/HANDOFF_20260923_CARD_ART_SEMANTIC_ANCHOR_REVALIDATION_RESULTS.md`)

Branch:

`card-art-pilot-v1-20260921`

Current state:

> **House-style A/B/C calibration ran: 6 hobbies (coworking, legal_thriller, streetwear, bun_cha, gaming.board, philosophy) x 3 isolated global-style-block candidates = 18 images on gemini-3.1-flash-lite-image direct, $0.3024 actual, 18/18 returned (no timeouts this round). Text-only style control WORKS: all three versions produced genuinely illustrated, non-photographic output, solving the "looks like stock photography" problem - no need yet to fall back to reference-image-conditioned gemini-3.1-flash-image. Production global_style_v1.json was never touched (verified via git status before/after); the A/B/C style blocks were injected as an isolated in-memory clone only, and a mechanical pre-submission check (prefix-strip the known style-block text, diff the remainder) confirmed all 6 hobbies compile byte-identical outside the style block across A/B/C. KEY FINDING: the user's stated pre-test preference, Version A (Editorial Lifestyle), tested WEAKEST of the three - lowest Zync-distinctiveness score, AND reproduced the recurring rounded card-border/chrome defect in 4 of 6 images (67%), vs 1/6 (17%) for Version B and 0/6 (0%) for Version C. This is a directly counted pattern, not a subjective read, and was reported plainly rather than softened toward the stated preference. RECOMMENDATION: Version C (Graphic Editorial Hybrid) - zero border defects, highest distinctiveness with a genuinely consistent recognizable identity across very different hobby contexts (business/cultural/fashion/food/gaming/academic), competitive collectible-appeal and maturity scores, zero semantic misses. Version B (Collectible Fantasy Card Lean) is a credible second choice with the highest raw collectible-appeal/maturity scores but carries a soft fantasy-glow drift risk (one philosophy card) and the set's one semantic MINOR (a legal_thriller that read as generic cinema-going). Version A is not recommended as-is unless its border-defect trigger is diagnosed and fixed first. Aggregate scores (0-4 scale): Photographicness A=0.0 B=0.75 C=0.08 (lower=better, all three succeeded); Collectible appeal A=2.2 B=2.9 C=2.2; Distinctiveness A=1.8 B=1.9 C=2.75; Maturity A=2.7 B=3.1 C=2.9. Semantic correctness: 17/18 PASS, 1/18 MINOR (Version B's legal_thriller). Recommended next steps (not executed): promote the selected direction into production global_style_v1.json explicitly; if Version A is still wanted, run a small isolated diagnostic on its border-defect trigger first; once a direction is chosen, validate scalability with a modest stratified sample across categories not covered here (sports, travel, wellness, pets, music, outdoors) before any larger commitment. No fal.ai route used. No 24-card repeat, no 100/2210 batch. sports.american_football and technology.robotics remain quarantined and untouched. Keep GitHub Actions, Vercel, Production and Play closed.**

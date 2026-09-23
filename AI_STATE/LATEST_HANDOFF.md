# Zync — Latest Handoff

## Mandatory first read

Read and obey `AI_STATE/OPERATING_RULES.md` before any write, commit, push, PR,
CI, Vercel, deployment or external-infrastructure action.

Authoritative continuation checkpoint:

`AI_STATE/HANDOFF_20260924_CARD_ART_STYLE_CALIBRATION_D123_RESULTS.md`

(previous checkpoints, still useful for context:
`AI_STATE/HANDOFF_20260924_CARD_ART_STYLE_CALIBRATION_ABC_RESULTS.md`,
`AI_STATE/HANDOFF_20260924_CARD_ART_GEMINI31_FLASH_LITE_RESULTS.md`,
`AI_STATE/HANDOFF_20260923_CARD_ART_GEMINI25_DIRECT_BATCH_RESULTS.md`,
`AI_STATE/HANDOFF_20260923_CARD_ART_SEMANTIC_ANCHOR_REVALIDATION_RESULTS.md`)

Branch:

`card-art-pilot-v1-20260921`

Current state:

> **House-style D1/D2/D3 Japanese-collectible-anime calibration ran (successor to the A/B/C round, which removed the stock-photo look but did not land the intended feeling): same 6 hobbies x 3 anime-intensity candidates (D1=50/50, D2=60/40, D3=70/30 anime/lifestyle) = 18 images on gemini-3.1-flash-lite-image direct, $0.3024 actual, 18/18 returned. DECISIVE SUCCESS on the core goal: all three versions produced genuine Japanese commercial-anime illustration - clean linework, cel shading, expressive charm, bright joyful color - with zero Western-editorial drift and only mild tasteful fantasy accents. Production global_style_v1.json never touched (verified via git status); same prefix-strip mechanical check confirmed byte-identical semantic content across D1/D2/D3 before any paid call. TWO REAL DEFECTS found and reported plainly: (1) food.dish.bun_cha/D1 produced a SEVERE fake trading-card UI overlay - a "TRAINER" header bar, full decorative card frame, corner logo badge, and "Bun Cha" title banner rendered directly into the artwork, a direct violation of the explicit no-card-frame/no-title-bar instructions and the worst defect across both style rounds combined; (2) legal_thriller/D3 leaked a readable "MYSTERY" word on a book prop, a minor text-policy violation. Both isolated (1/18 each), not systemic to one D-version's prose, but confirm "collectible-card" framing language carries an ongoing risk of the model reaching for literal TCG UI conventions that the existing negative list did not fully prevent. RECOMMENDATION: D3 (70/30) as primary - highest scores on anime feel (3.58), joy (3.67), collectible appeal (3.33), and distinctiveness (2.75), zero Western/photo drift, low fantasy drift (0.58/4), and produced arguably the three best individual cards across both rounds (bun_cha, gaming.board, philosophy). D2 (60/40) is a very close, safer second choice with zero defects of any kind in this sample. D1 (50/50) is NOT recommended - lowest scores across the board plus the severe card-UI defect. This is a visual judgment call per instruction, not a forced numeric pick. Semantic correctness: 15/18 PASS, 3/18 MINOR (two legal_thriller cases reading as generic cinema rather than legal-specific, plus D3's text-leak) - entertainment.movie_subgenre.legal_thriller needs its own semantic-anchor look independent of style, since 2/3 D-versions failed to convey "legal" content at all. Recommended next steps (not executed): promote D3 (or D2) into production global_style_v1.json explicitly; small isolated diagnostic on the bun_cha card-UI trigger and legal_thriller's semantic anchor before further investment; scalability validation across uncovered categories before any larger commitment. No fal.ai route used. No 24-card repeat, no 100/2210 batch. sports.american_football and technology.robotics remain quarantined and untouched. Keep GitHub Actions, Vercel, Production and Play closed.**

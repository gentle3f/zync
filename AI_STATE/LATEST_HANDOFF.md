# Zync — Latest Handoff

## Mandatory first read

Read and obey `AI_STATE/OPERATING_RULES.md` before any write, commit, push, PR,
CI, Vercel, deployment or external-infrastructure action.

Authoritative continuation checkpoint:

`AI_STATE/HANDOFF_20260923_CARD_ART_LAUNCH_BATCH_QA_RESULTS.md`

(previous checkpoint, still useful for batch/runner context:
`AI_STATE/HANDOFF_20260923_CARD_ART_LAUNCH_BATCH_READY.md`)

Branch:

`card-art-pilot-v1-20260921`

Current state:

> **The 16-card launch batch has been generated and QA'd. BLOCKING FINDING: FLUX.2 edit contaminated 7/16 (44%) first-pass cards with a copied Zync card mockup (logo/rarity/frame/garbled text) from the reference image, plus 2 more with lighter text/collage leaks — root cause is `references/zync-card-style-reference.png` itself being a full 10-card mockup (including an actual "Board Games" card) rather than a style-only image. Gemini 2.5 Flash Image edit fallback fixed 7 of 9 flagged cards cleanly; `fashion.streetwear` and `technology.ai` still fail on both models. Do NOT run this pipeline at catalog scale (2,210 eligible interests) until the reference image is replaced with a text/logo-free style asset — the current contamination rate is not survivable at that scale. Total spend this session: $0.751. Keep Vercel, GitHub Actions, Production and Play closed.**

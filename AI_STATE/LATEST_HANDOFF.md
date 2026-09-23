# Zync — Latest Handoff

## Mandatory first read

Read and obey `AI_STATE/OPERATING_RULES.md` before any write, commit, push, PR,
CI, Vercel, deployment or external-infrastructure action.

Authoritative continuation checkpoint:

`AI_STATE/HANDOFF_20260923_REFERENCE_FREE_FLUX_VALIDATION_RESULTS.md`

(previous checkpoint, still useful for policy/setup context:
`AI_STATE/HANDOFF_20260923_REFERENCE_FREE_FLUX_VALIDATION_READY.md`)

Branch:

`card-art-pilot-v1-20260921`

Current state:

> **The 4-card reference-free FLUX validation ran (crafts.diy, lifestyle.game_nights, fashion.streetwear, technology.ai; $0.050; 4/4 API calls succeeded). Reference-image contamination (Zync logo/card chrome/Board Games copy) is confirmed GONE across all 4 — the reference-free `fal-ai/flux-2` text-to-image path fixes that defect class. Result: 2 PASS (crafts.diy, technology.ai), 1 MINOR (fashion.streetwear — sneaker silhouette reads as a real shoe brand, not text this time), 1 FAIL (lifestyle.game_nights — model baked a literal "GAME NIGHTS" text caption into the image). NOT a clean 4/4, so reference-free FLUX is not yet declared fully validated and must NOT be scaled up yet. Next step: add a no-caption override for lifestyle.game_nights and strengthen the fashion.streetwear override against branded shoe silhouettes, then re-run only those 2 IDs (~$0.025) before any larger batch. Keep Vercel, GitHub Actions, Production and Play closed.**

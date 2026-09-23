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

> **Round 2 of the reference-free FLUX validation is done: after strengthening the `lifestyle.game_nights` and `fashion.streetwear` overrides with highly explicit no-caption / no-branded-silhouette language and re-running only those 2 IDs on `flux-2` text-to-image (2/2 API calls, $0.025), BOTH STILL FAIL. Game Nights again renders a bold readable "GAME NIGHT" caption; Streetwear again renders an unmistakable swoosh-like mark on the shoes, more prominent than before. `crafts.diy` and `technology.ai` remain PASS (unchanged). Reference-image contamination (Zync logo/chrome/Board Games copy) remains confirmed fixed across all attempts. Revised diagnosis: this looks FLUX-family-specific (all 3 FLUX attempts for Game Nights added a caption; the one Gemini attempt did not), and `fal-ai/flux-2`/`flux-2/edit` have no dedicated `negative_prompt` parameter — negatives are only ever inline positive-prompt text, a known-weaker suppression mechanism. The 4-card validation is NOT closed and the 48-card stratified batch is NOT recommended yet. Do not auto-reroll a third time or escalate to Gemini without first fixing `references/zync-card-style-reference.png` (Gemini here is edit-only and would re-upload the old contaminated mockup) or confirming a real negative-prompt mechanism. Keep Vercel, GitHub Actions, Production and Play closed.**

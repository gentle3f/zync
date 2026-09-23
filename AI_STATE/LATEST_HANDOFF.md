# Zync — Latest Handoff

## Mandatory first read

Read and obey `AI_STATE/OPERATING_RULES.md` before any write, commit, push, PR,
CI, Vercel, deployment or external-infrastructure action.

Authoritative continuation checkpoint:

`AI_STATE/HANDOFF_20260923_CARD_ART_STRATIFIED_48_READY.md`

Branch:

`card-art-pilot-v1-20260921`

Current state:

> **The next card-art stage is a 48-card stratified validation: 32 reference-free standard FLUX cards + 16 FLUX.2 Klein 9B Base cards using a real negative_prompt, estimated first-pass cost US$0.5824. Outputs are isolated under output/stratified_v1. Shared GLOBAL STYLE prompt text no longer contains the word Zync, and model metadata now defaults to flux-2 with Klein fallback. Run audit-stratified-v1 first; only then generate-stratified-v1. QA must separately measure standard-vs-Klein failure rates and Klein photoreal/style drift. Do not auto-reroll failures and do not jump directly to all eligible cards. Keep Vercel, GitHub Actions, Production and Play closed.**

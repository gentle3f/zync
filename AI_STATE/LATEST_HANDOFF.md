# Zync — Latest Handoff

## Mandatory first read

Read and obey `AI_STATE/OPERATING_RULES.md` before any write, commit, push, PR,
CI, Vercel, deployment or external-infrastructure action.

Authoritative continuation checkpoint:

`AI_STATE/HANDOFF_20260923_CARD_ART_SCALE_100_READY.md`

Branch:

`card-art-pilot-v1-20260921`

Current state:

> **The prompt-format root-cause fix is validated and Zync is ready for a 100-card scale validation. The new batch contains 75 reference-free standard FLUX cards + 25 Klein negative-prompt cards, with 98 new canonicals and two intentional Klein sentinel reroutes (sports.american_football and food.yum_cha). Estimated first-pass cost is US$1.2225. Sampling spans 20 categories plus common/mid/long-tail ranks. Run audit-scale-100-v1 first; only then generate-scale-100-v1. QA must report failure rates by model, category, archetype and rank stratum, plus Klein style drift. Do not auto-reroll and do not jump directly to all 2,210 eligible cards. Keep Vercel, GitHub Actions, Production and Play closed.**

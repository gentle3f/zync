# Zync — Latest Handoff

## Mandatory first read

Read and obey `AI_STATE/OPERATING_RULES.md` before any write, commit, push, PR,
CI, Vercel, deployment or external-infrastructure action.

Authoritative continuation checkpoint:

`AI_STATE/HANDOFF_20260923_CARD_ART_PROMPT_FORMAT_FIX_READY.md`

Branch:

`card-art-pilot-v1-20260921`

Current state:

> **The 48-card QA root cause has been fixed at compiler level: raw archetype/visual-variant/subcategory ids and the old LABEL (identifier): section-header format are removed from model-facing prompts, with fail-closed regression guards. Reference guidance is now structurally separate and only appended for explicit edit routes. A targeted 8-card validation preserves original model routes (7 standard FLUX + 1 Klein), estimated first-pass cost US$0.0989. Run audit-prompt-format-v1 first; only then generate-prompt-format-v1. Do not scale to 100 cards yet. Keep Vercel, GitHub Actions, Production and Play closed.**

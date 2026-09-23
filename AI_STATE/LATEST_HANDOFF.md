# Zync — Latest Handoff

## Mandatory first read

Read and obey `AI_STATE/OPERATING_RULES.md` before any write, commit, push, PR,
CI, Vercel, deployment or external-infrastructure action.

Authoritative continuation checkpoint:

`AI_STATE/HANDOFF_20260923_CARD_ART_GEMINI25_DIRECT_BATCH_READY.md`

Prior FLUX failure evidence:

`AI_STATE/HANDOFF_20260923_CARD_ART_SEMANTIC_ANCHOR_REVALIDATION_RESULTS.md`

Branch:

`card-art-pilot-v1-20260921`

Current state:

> **A direct-Google Gemini 2.5 Flash Image discriminator is ready. It reuses the exact same 24 canonical interests and current compiled prompts from the failed FLUX semantic-anchor revalidation, but sends them to Google's Gemini API directly using gemini-2.5-flash-image Batch API — never through fal.ai. New files: tools/card_art/catalog/gemini25_direct_batch_24_v1.json and tools/card_art/src/runGemini25DirectBatch24.js. The runner preserves canonical ID, exact final prompt, Google batch job name, response index/metadata and local filename so prompt-to-image mapping is auditable. Expected Batch image-output cost is about US$0.468 for 24 images plus small text-input token charges. No Google API call has been made yet because execution requires the user's local GEMINI_API_KEY. Next local/Claude session: run the dry-run, verify exact same 24 prompts, submit direct Google batch, collect when succeeded, inspect all 24 card-for-card against the FLUX outputs, and update the handoff. If Gemini follows the same prompts substantially better, evidence shifts strongly toward FLUX/model-route failure; if Gemini shows the same bizarre substitutions, audit shared compiler/request mapping before blaming either model. No fal.ai Image 2.5, no 100/1731 auto-scale. Gemini 2.5 Flash Image is a diagnostic model here and is scheduled by Google for shutdown on 2026-10-02. Keep GitHub Actions, Vercel, Production and Play closed.**

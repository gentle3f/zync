# Zync — Latest Handoff

## Mandatory first read

Read and obey `AI_STATE/OPERATING_RULES.md` before any write, commit, push, PR,
CI, Vercel, deployment or external-infrastructure action.

Authoritative continuation checkpoint:

`AI_STATE/HANDOFF_20260924_CARD_ART_GEMINI31_FLASH_LITE_RESULTS.md`

(previous checkpoints, still useful for context:
`AI_STATE/HANDOFF_20260923_CARD_ART_GEMINI25_DIRECT_BATCH_RESULTS.md`,
`AI_STATE/HANDOFF_20260923_CARD_ART_SEMANTIC_ANCHOR_REVALIDATION_RESULTS.md`)

Branch:

`card-art-pilot-v1-20260921`

Current state:

> **The direct-Google gemini-3.1-flash-lite-image successor test ran on the exact same 24 canonical interests and byte-identical compiled prompts as both the failed FLUX run and the successful gemini-2.5-flash-image run. Result: 21/22 PASS, 1/22 MINOR, 0/22 FAIL on the cards that returned - at least as strong as 2.5's 20/24 PASS, 4/24 MINOR, 0/24 FAIL, and cheaper per image ($0.0168 vs $0.0195). BUT 2 of 24 requests never returned an image - both failed with a Google-side gRPC deadline timeout (code 4, confirmed via raw response inspection, not a content block or mapping bug) - and one of the two missing cards is wellness.sauna, the single safety-critical card in the set. The safety dimension was therefore NOT re-verified on this model and must not be assumed resolved just because 2.5 resolved it. The batch also took ~90 minutes to complete vs 2.5's ~1 minute, a real latency difference for any production pipeline. Per "no auto-rerolls," the 2 missing cards were not retried automatically. One proactive bug was found and fixed before committing: the redaction helper carried over from the 2.5 runner only stripped the "data" key, but this model also returns large ~1.3MB "thoughtSignature" reasoning blobs per response that the old redaction missed, producing a 65MB status file on first collect; rewrote the redaction to strip any oversized string by length regardless of key name and re-ran --collect (free status GET) to regenerate a properly small 67KB file. DECISION: image quality clears the bar for gemini-3.1-flash-lite-image as a production candidate (matches or exceeds 2.5, cheaper, non-deprecated), but operational completeness does not yet - recommend a small targeted 2-card retest (yum_cha + sauna specifically) before certifying, not a new 24-card batch, and not yet jumping to gemini-3.1-flash-image (the non-lite fallback) since this isn't "meaningfully worse," just incomplete. Do not resume the FLUX 100/1731 batch for the families that failed. No fal.ai route used anywhere. No 100/2210 batch started. sports.american_football and technology.robotics remain quarantined and untouched. Keep GitHub Actions, Vercel, Production and Play closed.**

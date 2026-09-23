# Zync — Latest Handoff

## Mandatory first read

Read and obey `AI_STATE/OPERATING_RULES.md` before any write, commit, push, PR,
CI, Vercel, deployment or external-infrastructure action.

Authoritative continuation checkpoint:

`AI_STATE/HANDOFF_20260923_CARD_ART_GEMINI25_DIRECT_BATCH_RESULTS.md`

(previous checkpoint, still useful for experiment design context:
`AI_STATE/HANDOFF_20260923_CARD_ART_GEMINI25_DIRECT_BATCH_READY.md`)

Prior FLUX failure evidence:

`AI_STATE/HANDOFF_20260923_CARD_ART_SEMANTIC_ANCHOR_REVALIDATION_RESULTS.md`

Branch:

`card-art-pilot-v1-20260921`

Current state:

> **The direct-Google Gemini 2.5 Flash Image discriminator ran (24/24 images, $0.468 actual, exact same 24 canonical interests and byte-identical compiled prompts as the failed FLUX semantic-anchor run) and reversed the result completely: 20/24 PASS, 4/24 MINOR, 0/24 FAIL - versus FLUX's 0/24 PASS, 2/24 MINOR, 22/24 FAIL on the identical prompts. Zero card-border/chrome recurrence across all 24. This is strong direct evidence the dominant failure mode across this whole remediation arc (camera/gadget/controller intrusion, wrong-specific-instance substitution, readable code/UI screens) is a FLUX/model-route problem, not deficient prompt semantics - the semantic anchor architecture built in the prior checkpoint was correct, it was just being executed by the wrong model. Concrete wins on the hardest test cases: ice_fishing shows a genuine frozen lake with visible ice hole (FLUX showed paddleboarding on the single most detailed anchor in the whole set); pets.dogs shows an actual golden retriever (FLUX showed rodents + a game controller); photography.general shows an actual camera (FLUX showed binoculars, even in this hand-tuned manual recipe); gaming.board and gaming.chess show zero video-game controllers (FLUX showed controllers in both, even in manual recipes); business.coworking shows all-blank/dark screens (FLUX showed multiple readable code screens, a confirmed regression from earlier rounds); wellness.sauna shows modest full-length towel coverage in a genuine wood sauna with no domestic-bathtub framing (FLUX's safety risk from the prior round persisted; this is now resolved on this model). Two real execution-blocking script bugs were found and fixed before this could even run: the runner never loaded dotenv/config so GEMINI_API_KEY was invisible even once set; and the aspect-ratio field path was wrong (responseFormat.image.aspectRatio doesn't exist in the real v1beta proto - fixed to generationConfig.imageConfig.aspectRatio, verified directly against Google's actual proto source, not guessed). A third latent bug (batch-status field path/state-naming mismatch) was found and fixed proactively before it could block collection. GEMINI_API_KEY was requested from and supplied by the user directly, written to tools/card_art/.env (confirmed gitignored), never printed/logged/committed. IMPORTANT CAVEAT: gemini-2.5-flash-image is scheduled for shutdown by Google on 2026-10-02 - this is diagnostic evidence about model routing, not a production migration recommendation. Recommended next steps (not executed): if a newer non-deprecated Google image model is available, repeat this same apples-to-apples 24-card comparison against it before any routing decision; do not resume the FLUX 100/1731 batch for the families that failed; do not reroute the whole catalog to Gemini without further validation given the shutdown constraint. No fal.ai route was used anywhere. No 100/1731 batch started. sports.american_football and technology.robotics remain quarantined and untouched. Keep GitHub Actions, Vercel, Production and Play closed.**

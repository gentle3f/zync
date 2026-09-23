# Zync — Latest Handoff

## Mandatory first read

Read and obey `AI_STATE/OPERATING_RULES.md` before any write, commit, push, PR,
CI, Vercel, deployment or external-infrastructure action.

Authoritative continuation checkpoint:

`AI_STATE/HANDOFF_20260923_CARD_ART_SEMANTIC_ANCHOR_REVALIDATION_RESULTS.md`

(previous checkpoint, still useful for architecture design context:
`AI_STATE/HANDOFF_20260923_CARD_ART_SEMANTIC_ANCHOR_ARCH_READY.md`)

Failure evidence trail:

`AI_STATE/HANDOFF_20260923_CARD_ART_BULK_FIRST_100_RESULTS.md`

Chrome-risk audit:

`AI_STATE/CARD_ART_CHROME_DEFECT_AUDIT_20260923.md`

Branch:

`card-art-pilot-v1-20260921`

Current state:

> **The 24-card semantic-anchor revalidation ran (24/24 Standard FLUX, $0.30 actual) and FAILED to show a directional improvement: 22/24 FAIL, 2 MINOR, 0 clean PASS. Both zero-cost audits (semantic coverage + 24-card dry-run) were clean beforehand, and the semantic anchor rule text itself is precise and well-targeted - verified directly in the compiled prompts, e.g. ice_fishing's anchor explicitly requires a frozen lake/ice hole and forbids open water/paddleboard, pets.dogs explicitly forbids camera/controller/gadget and wildlife-photography framing, business.coworking explicitly reinforces no readable code/monitor. Despite this, the model overrode the anchors in the overwhelming majority of generated cards, including the single most detailed anchor in the set (ice_fishing still showed paddleboarding) and two hand-tuned MANUAL recipes (photography.general still showed binoculars not a camera; gaming.board still showed video-game controllers). Two cards (entertainment.screenwriting, entertainment.movie_subgenre.legal_thriller) came out arguably WORSE than their 100-card counterparts - more chaotic multi-screen "screen soup." The wellness.sauna safety rule reduced but did NOT eliminate the content-safety risk - the output still reads as precariously-covered figures in an ambiguously domestic bath setting; this needs its own dedicated follow-up, not folded into general recognizability work. Per the task's own explicit decision rule, this result means STOP further FLUX prompt-architecture tuning for the tested families and route them to the user's manual Image 2.5 workflow instead: food_hero/food_exploration (dish-identity substitution), music_listening (code-screen prior), story_culture (code-screen prior, now the worst-observed defect class), travel_vista destinations, companion_bond/pets (wildlife/gadget substitution, unresolved across two rounds), learning_exploration, home_lifestyle, nature_immersion/outdoor_motion/water_outdoors (exact-activity substitution), journey_machine (wrong-vehicle substitution), lens_perspective (binoculars-for-camera, unresolved even in manual recipe), urban_discovery (signage leakage), group_play/strategy_table (controller intrusion, unresolved even in manual recipes), calm_wellness, shared_workspace/coworking (code-screen regression, confirmed twice now). This was NOT a retest of the structurally-redesigned archetypes (aviation_world, campaign_planning, legal_practice) - those were untouched this round and prior evidence for them stands. No 100-card or 1731-card batch started. Manual Image 2.5 remains manual-only, never via fal.ai. sports.american_football and technology.robotics remain quarantined and untouched. Keep Vercel, GitHub Actions, Production and Play closed.**

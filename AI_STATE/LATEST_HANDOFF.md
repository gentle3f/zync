# Zync — Latest Handoff

## Mandatory first read

Read and obey `AI_STATE/OPERATING_RULES.md` before any write, commit, push, PR,
CI, Vercel, deployment or external-infrastructure action.

Authoritative continuation checkpoint:

`AI_STATE/HANDOFF_20260923_CARD_ART_STRUCTURAL_SCENE_REMEDIATION_RESULTS.md`

(previous checkpoint, still useful for remediation design context:
`AI_STATE/HANDOFF_20260923_CARD_ART_STRUCTURAL_SCENE_REMEDIATION_READY.md`)

Branch:

`card-art-pilot-v1-20260921`

Current state:

> **GATE PASSED. The 5-card structural-scene validation ran (5/5 standard FLUX, $0.063 actual). All four repaired cards achieved a clean, unambiguous PASS: business.coworking (shared_workspace/communal_desks) now shows six adult professionals at communal desks - zero workshop/jewelry content; business.marketing (campaign_planning/mockup_table) shows a genuine campaign-mockup table with blank packaging and swatches; career.legal_profession (legal_practice/courtroom_advocacy) shows a clean courtroom scene with an advocate and judge; learning.book_genre.booktube (creator_workflow/camera_creation, moved to Standard FLUX) shows a camera-on-tripod aimed at an adult creator actively presenting a book, and the prior Klein MATERIAL style drift is gone since it now renders painterly, not photoreal. The professional_world workshop/jewelry/apprentice scene prior that survived three independent, detailed hobby prompts in the previous round did not recur even once after moving the archetype itself. technology.generative_ai (control) remains clean of the caption/code regressions this gate exists to catch; one pre-existing, already-deferred minor UI-clutter texture persists (same class as the technology.electronics finding). Root cause confirmed: this was a genuine model semantic prior tied to the professional_world archetype, not a compiler/routing/override/variant-selection bug - fixed by giving the model a structurally different archetype template, not more negative wording. Recommended next step: a ~30-card confirmatory batch (10-12 cards for breadth-confirmation across the 4 newly-fixed archetypes with different hobbies + ~18-20 fresh stratified cards across untested categories/archetypes) - smaller than the paused 50-card ceiling. travel.japan signage/card-chrome and the minor screen-clutter texture remain open, lower-priority, deliberately deferred. Keep Vercel, GitHub Actions, Production and Play closed.**

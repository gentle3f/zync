# Zync — Latest Handoff

## Mandatory first read

Read and obey `AI_STATE/OPERATING_RULES.md` before any write, commit, push, PR,
CI, Vercel, deployment or external-infrastructure action.

Authoritative continuation checkpoint:

`AI_STATE/HANDOFF_20260923_CARD_ART_BULK_ROUTING_SPLIT_V1.md`

(previous checkpoint, still useful for the PC Gaming/Robotics evidence
trail: `AI_STATE/HANDOFF_20260923_CARD_ART_PC_GAMING_DEDICATED_RESULTS.md`)

Supporting defect audit (still current, referenced by the split):

`AI_STATE/CARD_ART_CHROME_DEFECT_AUDIT_20260923.md`

Branch:

`card-art-pilot-v1-20260921`

Current state:

> **The full eligible catalog (2210 baseline-art-eligible canonicals) has been classified into a conservative first-pass routing split, using the actual production compiler (zero API calls) plus every finding accumulated across the whole remediation arc. BULK-FIRST = 1730 IDs (safe to generate now on cheap FLUX, no archetype/cluster-level negative evidence: music, food, story/culture, reading, travel-style, most sports, already-fixed professional/legal archetypes, most of creator_workflow, etc.). HOLDOUT = 477 IDs across 7 evidence groups: tech_workspace (53, confirmed unsafe on both variants), digital_play/all gaming subgenres (172, shares pc_gaming's confirmed screen-dependency prior on every variant), professional_world remainder (70 untested business.* interests still on the original unfixed workshop-prior archetype), solo_action uncovered clusters (51, same unmitigated trademark risk the fixed IDs originally had), collection_object_hero (33, one incidental but non-causal defect observed), travel_vista destinations (96, signage/landmark risk matching travel.japan), and creator_workflow's 2 exceptions (arts.vlogging + gaming.game_streaming, both individually well-evidenced failures). QUARANTINED = 3: sports.american_football, technology.robotics (both already machine-guarded), plus a newly-discovered data bug (outdoors.ice_fishing compiles to a non-existent visual_variant and would throw). tech_workspace and digital_play (225 IDs total) are recommended for manual Image 2.5 first; the other 5 holdout groups are candidates for one more small cheap FLUX experiment before falling back to manual. Image 2.5 is manual-only, never via fal.ai. No paid generation was run producing this split, no batch started, Robotics/American Football experiments not reopened. New repo artifacts: tools/card_art/catalog/bulk_first_v1.json, manual_image25_holdout_v1.json, quarantined_or_blocked_v1.json. Keep Vercel, GitHub Actions, Production and Play closed.**

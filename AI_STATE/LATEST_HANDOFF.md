# Zync — Latest Handoff

## Mandatory first read

Read and obey `AI_STATE/OPERATING_RULES.md` before any write, commit, push, PR,
CI, Vercel, deployment or external-infrastructure action.

Authoritative continuation checkpoint:

`AI_STATE/HANDOFF_20260923_CARD_ART_SEMANTIC_ANCHOR_ARCH_READY.md`

Failure evidence that triggered this redesign:

`AI_STATE/HANDOFF_20260923_CARD_ART_BULK_FIRST_100_RESULTS.md`

Chrome-risk audit:

`AI_STATE/CARD_ART_CHROME_DEFECT_AUDIT_20260923.md`

Branch:

`card-art-pilot-v1-20260921`

Current state:

> **The prior BULK-FIRST/HOLDOUT production split is superseded after the 100-card validation failed 72/100. No 1731-card bulk run should be started. A new semantic content-anchor layer is now implemented in catalogRecipeBridge.js using specs/semantic_anchor_rules_v1.json (32 rules). The layer separates hobby-specific physical content from visual archetype/style and marks derived recipes as semantic covered/uncovered. It adds concrete anchors for the dominant failure families (food identity, physical audio, reading/books, travel, pets, learning evidence, home actions, outdoor exact gear, named vehicles, cameras vs binoculars, board/tabletop physical play with no controllers, exact sport equipment, wellness rituals, etc.) and adds a dedicated general-audience safety rule for wellness_experience (adult subjects, modest coverage, no implied nudity/domestic bathtub). Global style positive card/collectible wording has been removed and replaced with full-bleed edge-to-edge framing language; chrome is now treated as a live ~5% risk, not sparse background noise. Old bulk_first_v1.json and manual_image25_holdout_v1.json are explicitly production_ready=false / superseded. New zero-cost audit: tools/card_art/src/auditSemanticAnchors.js. A 24-card targeted Standard-FLUX before/after revalidation is prepared but NOT generated (estimated $0.30): catalog/semantic_anchor_revalidation_24_v1.json + src/runSemanticAnchorRevalidation24.js. Next local/Claude session must first run the semantic coverage audit and 24-card dry-run; only if both are clean may it generate exactly those 24. No 100/1731 auto-scale. Manual Image 2.5 remains user-run only and must never be called through fal.ai. sports.american_football and technology.robotics remain quarantined. Keep GitHub Actions, Vercel, Production and Play closed.**

# Zync — Semantic Content Anchor Architecture Ready for Zero-Cost Audit

Date: 2026-09-23
Branch: `card-art-pilot-v1-20260921`
Parent state: 100-card BULK-FIRST validation failed 72/100 on commit `e65fe3c`.

## Why this checkpoint exists

The failed 100-card validation established that the prior catalog architecture was not production-ready.

The dominant problem was not malformed compiled prompts. It was that most derived recipes only interpolated the hobby title into generic category/archetype prose. The model therefore fell back to strong generic priors (camera/gadget, wrong food, wrong outdoor activity, code/UI screens, generic campfire, etc.).

This checkpoint adds a dedicated **semantic content-anchor layer** between routing/profile selection and final prompt compilation.

The intended separation is now:

- **semantic content layer** = what physically must be visible for this hobby;
- **archetype / visual variant** = how that content is composed and lit;
- **global style** = collection-wide aesthetic constraints.

No image generation was performed while preparing this checkpoint.

## Core architecture change

New file:

`tools/card_art/specs/semantic_anchor_rules_v1.json`

The real runtime catalog bridge now loads and applies these semantic rules after the existing category/profile routing rules:

`tools/card_art/src/catalogRecipeBridge.js`

Semantic rules are explicitly forbidden from changing:
- `archetype`
- `visual_variant`
- `art_category`

They may:
- replace `subject_template`
- replace `environment_template`
- append concrete recognition anchors
- append must-include cues
- append avoid rules
- append emotional cues

Compiled derived recipes now expose:
- `semantic_anchor_status: covered | uncovered`
- `semantic_anchor_rule_ids: [...]`

This creates a machine-auditable distinction between a recipe with real content anchors and a hollow generic derived recipe.

## v1 semantic rule coverage

32 semantic rules were added, targeted at the dominant failure classes seen in the 100-card validation.

Major families include:

- `food_hero`: exact named dish must dominate; no generic substitute dish.
- `food_exploration`: food and serving interaction dominate; signage is excluded.
- `drink_ritual`: vessel + physical brew/pour/taste action; no screens/gadgets.
- `music_listening`: headphones/speakers/turntable/physical audio cues; no code screens/camera prior.
- `performance`: body/instrument/performance action must carry identity.
- `story_culture`: physical viewing/performance/cultural experience, no copyright/title dependence.
- `reading_world`: real books and reading/discussion action; no tablet/laptop fallback.
- `travel_vista`: traveler + route/destination cue; signage text excluded.
- `urban_discovery`: blank storefront/sign surfaces; no readable neon/store names.
- `companion_bond`: animal-first care/training/bond scene, with an explicit pet-photography exception.
- `learning_exploration`: topic-specific specimen/object/model/tool/observation rather than generic gadget.
- `home_lifestyle`: real domestic/family action and relevant physical object.
- `nature_immersion`: no generic campfire/campsite substitution outside actual camping families.
- `outdoor_motion`: exact equipment + terrain; no generic skiing substitution.
- `water_outdoors`: exact water gear/body position.
- `outdoors.ice_fishing`: explicit frozen lake + ice hole + winter clothing + short fishing rod/line; no open water/paddleboard.
- `journey_machine`: exact named real-world vehicle must dominate; no generic sci-fi buggy.
- `lens_perspective`: real camera body + lens, not binoculars.
- `creative_studio`: hands transform the defining material/medium.
- `group_play` and `strategy_table`: physical board/card/tile/dice systems; video-game controllers/screens explicitly forbidden.
- `solo_action`: exact sport movement + sport equipment; camera/gimbal fallback forbidden; brand-like sportswear marks forbidden.
- `fitness_training`: body movement and correct equipment.
- `calm_wellness`: embodied ritual; controllers/gadgets/code screens forbidden.
- `wellness_experience`: dedicated general-audience safety rule.
- `campus_activity`, `community_gathering`, `vertical_adventure`, `creator_workflow`, `shared_workspace`, `collection_object_hero`.

## Wellness safety hardening

The 100-card run showed implied-nudity / bathtub framing risk for sauna/hot-spring content.

The semantic rule for `wellness_experience` now requires:
- adult subjects;
- modest swimwear, securely wrapped towel/robe, or equivalent appropriate coverage whenever bathing/heat/water is involved;
- clearly professional/resort/outdoor wellness venue;
- recognizable venue equipment;
- no nudity;
- no implied nudity;
- no sexualized framing;
- no transparent clothing;
- no domestic bathtub framing;
- no minor/child in bathing context.

The rule applies to `wellness.sauna`, `wellness.hot_springs`, and `wellness.cold_plunge`.

## Card-border/chrome systemic intervention

The 100-card run produced at least 5 additional chrome/frame cases (~5%).

`tools/card_art/specs/global_style_v1.json` was changed to remove positive:
- `collectible hobby illustration`
- `collectible-art universe`

language.

The positive direction now requests:
- premium cinematic hobby illustration;
- one coherent lifestyle-illustration language;
- **full-bleed edge-to-edge artwork**;
- scene content naturally continuing to every edge;
- no frame, border, mat, rounded rectangle, card shell, poster/editorial layout.

A new global negative explicitly forbids:
- rounded light frame;
- pale edge chrome;
- white margin;
- mat;
- inset artwork;
- decorative image border.

This is a falsifiable intervention. It does **not** claim the old wording was proven causal.

The chrome audit was updated:
`AI_STATE/CARD_ART_CHROME_DEFECT_AUDIT_20260923.md`

Current classification:
**live moderate-frequency stochastic/upstream framing risk; trigger unresolved.**

Do not auto-crop.

## Old BULK-FIRST routing is explicitly disabled

The old data files are retained as historical evidence but are no longer production queues.

`tools/card_art/catalog/bulk_first_v1.json` now has:
- `status: superseded_after_100_card_validation_failure`
- `production_ready: false`

`tools/card_art/catalog/manual_image25_holdout_v1.json` is also marked superseded as a catalog split.

Do not start the old 1731-card run.

Manual Image 2.5 remains manual-only for the user and must never be called through fal.ai.

## Zero-cost semantic coverage audit

New:

`tools/card_art/src/auditSemanticAnchors.js`

Run locally:

```bash
cd tools/card_art
node src/auditSemanticAnchors.js
```

This makes zero API calls.

It:
- compiles the full eligible runtime catalog through the actual bridge;
- counts manual vs semantic-covered vs semantic-uncovered derived recipes;
- reports uncovered IDs by archetype/category;
- verifies safety-critical wellness IDs have semantic coverage;
- verifies positive card/collectible framing terms are absent from the global prompt;
- verifies the superseded bulk queue remains `production_ready:false`;
- writes `generated/semantic_anchor_audit_v1.json`.

Do **not** proceed to paid validation if this audit throws or shows obvious large uncovered families that should have semantic coverage.

## Static sanity checks already completed

Without executing Node locally, repo-level static checks confirm:
- semantic rules: 32;
- duplicate rule IDs: 0;
- forbidden routing mutations inside semantic rules: 0;
- sauna/hot-springs/cold-plunge all match the wellness safety rule;
- old BULK-FIRST queue = `production_ready:false`;
- global positive prompt contains none of the tested card/collectible framing phrases;
- global prompt explicitly contains full-bleed + edge-to-edge language;
- Ice Fishing specific route fix still exists;
- semantic audit script is present.

## Targeted revalidation prepared — NOT generated

Prepared:
- `tools/card_art/catalog/semantic_anchor_revalidation_24_v1.json`
- `tools/card_art/src/runSemanticAnchorRevalidation24.js`

This is a **24-card before/after targeted validation**, not a new bulk sample.

It deliberately reuses interests that exercise the known failure modes:
- exact dish identity;
- music screen/gadget prior;
- story/culture recognizability;
- travel/signage;
- pet camera fallback;
- generic learning gadget fallback;
- home-lifestyle mismatch;
- outdoor activity substitution;
- Ice Fishing;
- journey-machine sci-fi vehicle substitution;
- lens/binocular substitution;
- urban storefront text;
- board-game controller intrusion;
- wellness safety;
- shared-workspace code-screen regression;
- chrome/frame recurrence.

Model:
- Standard FLUX only.

Expected:
- 24 calls;
- estimated cost **US$0.30**;
- no auto-rerolls;
- no follow-on bulk run.

### Before any paid generation

First run:

```bash
node src/auditSemanticAnchors.js
node src/runSemanticAnchorRevalidation24.js --dry-run
```

Inspect the dry-run prompts for the actual semantic anchor additions and confirm all 24 compile.

Only if both zero-cost audits are clean should the 24-card generation be considered.

### Decision rule after the 24

This 24-card set is not enough to certify production.

Look for **directional improvement** against the exact dominant failure classes from the 100-card run.

If the same generic gadget / unrelated hobby / code-screen prior remains dominant even with concrete semantic anchors, stop spending time on FLUX prompt architecture for those families and move them to the user's manual Image 2.5 workflow.

If the failure classes improve materially, expand semantic coverage based on the audit's uncovered list and continue with another small stratified check.

Do not return directly to 100/1731 generation.

## Infrastructure

No image API calls were made in this architecture-rebuild checkpoint.

Keep:
- GitHub Actions closed;
- Vercel closed;
- Production closed;
- Google Play closed.

`sports.american_football` and `technology.robotics` remain quarantined.

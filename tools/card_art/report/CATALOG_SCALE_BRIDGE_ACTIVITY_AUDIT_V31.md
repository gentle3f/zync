# Zync Catalog-Scale Card Art / Activity Audit V3.1

Date: 2026-09-22  
Branch: `card-art-pilot-v1-20260921`

## Executive state

- Production CLOSED.
- Google Play CLOSED.
- Image generation CLOSED.
- No image API credits spent in this work.
- GitHub Actions conservation remains in force until the 2026-10-01 reset.
- All validation in this checkpoint is static/source-level unless explicitly stated otherwise.

## Runtime interest catalog

Current canonical count: **3,935**.

V2 count: 3,494.  
Net expansion since V2: **+441**.

Durable everyday-wording benchmark:
- **444 / 444** exact-or-alias resolvable
- 100.0%
- stored in `mobile/test/interest_catalog_everyday_benchmark_test.dart`

Static catalog invariants:
- duplicate canonical IDs: **0**
- same-category normalized collisions: **0**

## Browse / onboarding fixes

### Hidden category bug

The newly added `career` world was initially searchable but invisible in browse because
`InterestCatalog._buildCategories()` used a hard-coded old category list.

Fixed behavior:
- `career` is explicitly ordered into browse.
- Any future seeded category omitted from the preferred order is appended automatically.
- regression test requires every seeded top-level category to remain browsable.

### Quick Start diversity

The previous first-run Quick Start was effectively global popularity/rank only. That caused
the first 24 results to overrepresent sports, media and music.

New behavior:
- take one strongest item from every top-level world first;
- then fill remaining slots by normal regional/popularity relevance;
- leaf/category browsing remains popularity-sorted as before.

Regression test requires Quick Start to represent every current top-level world.

## Runtime card rights

Independent static cross-check against the Dart catalog and runtime policy sets:

- total canonical interests: **3,935**
- baseline-art eligible: **2,092**
- blocked: **1,843**
- abstractOnly: **7**

The 7 abstract-only canonicals remain:
- Python
- JavaScript
- Linux
- BookTok
- BookTube
- Bookstagram
- UNESCO Heritage Travel

Abstract-only derived recipes:
- remain baseline eligible;
- are forced to hard-case difficulty;
- require human review;
- gain explicit avoid rules for official logos, wordmarks, badges, certification seals,
  official-looking trade dress and mark-dependent compositions.

## Rights-first catalog -> recipe bridge

New source:
`tools/card_art/src/catalogRecipeBridge.js`

New supporting files:
- `tools/card_art/catalog/manual_recipe_canonical_map_v1.json`
- `tools/card_art/specs/catalog_recipe_defaults_v1.json`
- `tools/card_art/src/auditCatalogRecipes.js`

The bridge:

1. statically reads all bundled Dart catalog parts;
2. reproduces canonical family-ID generation / legacy-skip behavior;
3. reads runtime `InterestCardPolicyResolver` licensed clusters, licensed IDs and
   abstract-only IDs;
4. reads explicit card metadata;
5. partitions the entire catalog before prompt compilation;
6. blocks `licensedOnly` and `notCollectible`;
7. allows `originalGeneric` and `abstractOnly`;
8. uses a reviewed manual recipe when one exists and rights allow it;
9. otherwise derives an inheritance-based long-tail recipe;
10. fails closed on unknown categories / missing archetypes / missing visual variants.

Compiler now invokes this bridge first. A stale manual recipe cannot bypass rights.

### LEGO regression

There are 15 reviewed/manual pilot recipes.

Independent static result:
- manual recipes: **15**
- eligible manual recipes: **14**
- blocked manual recipes: **1**

The blocked one is:
- legacy manual id: `lego`
- canonical id: `collecting.lego`
- runtime policy: `licensedOnly`

Therefore the preserved historical LEGO recipe remains auditable but cannot enter baseline
compiled output.

## Catalog-scale art inheritance

Category-scale art modifiers now cover all baseline-eligible runtime worlds.

New/refined long-tail archetypes include:
- `learning_exploration`
- `companion_bond`
- `professional_world`
- `journey_machine`
- `music_listening`
- `reading_world`

Each has curated visual variants.

Independent static mapping audit across all **2,092** baseline-eligible interests:

- missing category defaults: **0**
- missing art category modifiers: **0**
- missing archetypes: **0**
- missing visual-variant pools: **0**

Current derived/manual archetype distribution:

- music_listening: 272
- food_hero: 264
- group_play: 237
- story_culture: 183
- travel_vista: 181
- reading_world: 142
- urban_discovery: 98
- creative_studio: 92
- solo_action: 85
- learning_exploration: 81
- nature_immersion: 75
- professional_world: 69
- drink_ritual: 65
- tech_workspace: 53
- performance: 48
- calm_wellness: 41
- collection_object_hero: 33
- journey_machine: 28
- companion_bond: 25
- lens_perspective: 16
- vertical_adventure: 4

This replaced the earlier overconcentration where `story_culture` alone would have handled
about 596 interests.

## Known hard cases

The original prompt-system spec named these hard cases:
AI, Cinema, Photography, Japan, LEGO, Camping, Running, Reading, History, Philosophy,
Fashion and Mindfulness.

Current treatment:
- AI / Cinema / Photography / Japan / Camping / Running: reviewed manual hard-case recipes.
- LEGO: blocked by rights.
- Reading / History / Philosophy / Mindfulness: derived hard-case + mandatory human review.
- Fashion: the entire fashion category is derived hard-case + mandatory human review because
  logos, brand cues and trade dress are especially easy to hallucinate.

The pure preflight rejects any hard-case recipe without human review.

## Prompt compiler

`tools/card_art/src/compilePrompts.js` is now rights-first.

Expected flow:

```
runtime catalog
-> runtime rights policy
-> eligible / blocked bridge manifests
-> manual-or-derived recipe
-> buildPromptV1
-> compiled prompt JSONL
```

Pure local commands:

```bash
npm run audit-catalog-recipes
npm run compile-prompts
```

Neither command calls fal.ai or generates images.

Important: the currently checked-in
`tools/card_art/generated/compiled_prompts_v1.jsonl` is a **15-hobby pre-bridge snapshot**.
It must not be treated as current full-catalog compiled output until the new compiler is run.

## Zync Now activity audit

### Art rights vs activity rights

Previous resolver logic blocked any `ipSensitive` interest from generic activity semantics.
That incorrectly made an `abstractOnly` artwork restriction behave like an activity ban.

Fixed:
- only `CardArtPolicy.licensedOnly` blocks generic activity fallthrough;
- abstract-only remains an art-policy restriction.

Example:
- BookTok can now use reading/discussion semantics without changing its abstract-only
  artwork restriction.

### Live culture semantic corrections

Previous behavior:
- `music.concerts` had a legacy `music_making` cluster and could fall into
  practice/learn semantics.
- `Theatre Going` could fall into generic home-viewing semantics.

Fixed:
- concerts use a dedicated live-culture venue profile;
- theatre-going uses the same venue-oriented profile;
- no home-possible theatre fallthrough.

### Safe breadth expansion

New low-risk auto-activity coverage includes:
- food dining / food-dining clusters -> social exploration;
- lifestyle local-culture -> social exploration.

Conservative exclusions remain:
- Bars
- Nightlife
- Parties / house-party alias
- Boat Parties / junk-boat alias
- deep alcohol drink taxonomy
- higher-risk outdoors and sports without explicit review
- professional/career concepts without explicit activity semantics

Regression tests were added but not run on hosted Flutter CI yet.

## Validation status

Statically verified:
- 3,935 canonical recount
- 444/444 everyday wording benchmark
- 2,092 / 1,843 rights partition
- 15 manual recipes -> 14 eligible + LEGO blocked
- complete art family / archetype / variant mapping for all 2,092 eligible interests
- catalog duplicate/collision checks
- bridge fail-closed invariants

Written but not hosted-run:
- Flutter catalog tests
- Quick Start/category browse tests
- cross-category ambiguity tests
- activity resolver tests
- 444-query benchmark test
- Node `audit-catalog-recipes`
- Node full prompt compilation

No image generation should open until executable validation is completed and reviewed.

## Recommended continuation

1. Run `npm run audit-catalog-recipes` in an execution environment when available.
2. Run `npm run compile-prompts` (still no image API calls).
3. Audit a stratified sample of derived compiled prompts across every major archetype and all
   hard cases before any image generation.
4. After the 2026-10-01 Actions reset, run targeted Flutter analyze/tests and Android
   validation.
5. Keep image generation, Production and Play CLOSED until those gates pass.

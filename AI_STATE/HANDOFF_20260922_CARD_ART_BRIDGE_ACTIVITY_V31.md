# Zync — Catalog-Scale Card Art / Activity V3.1 Handoff

Date: 2026-09-22
Branch: `card-art-pilot-v1-20260921`
Audit report: `tools/card_art/report/CATALOG_SCALE_BRIDGE_ACTIVITY_AUDIT_V31.md`

## Hard boundaries

- Production CLOSED.
- Google Play CLOSED.
- Image generation CLOSED.
- Do not spend image API credits.
- GitHub Actions budget guard remains active; conserve hosted Actions until 2026-10-01.
- Do not open a PR merely to obtain CI before reset.

## Current runtime interest state

- Canonical interests: **3,935**
- V2 baseline: 3,494
- Net V3 growth: **+441**
- Duplicate canonical IDs: **0**
- Same-category normalized collisions: **0**
- Evergreen everyday benchmark: **444/444 = 100% exact-or-alias resolvable**

Do not chase 4,000 as a goal. Further catalog additions require evidence of a real coverage gap.

## Browse / onboarding fixes completed

- `career` no longer disappears from browse due to hard-coded category ordering.
- Future unknown seeded top-level categories are appended automatically.
- Quick Start now diversifies across all top-level worlds before popularity fills remaining slots.
- Regression tests were written but not hosted-run.

## Rights state

Independent static cross-check:

- Total: **3,935**
- Baseline-art eligible: **2,092**
- Blocked: **1,843**
- Abstract-only: **7**

Abstract-only:
- Python
- JavaScript
- Linux
- BookTok
- BookTube
- Bookstagram
- UNESCO Heritage Travel

Abstract-only is an artwork restriction, not an activity restriction.

## Rights-first catalog -> recipe bridge completed

New bridge:
`tools/card_art/src/catalogRecipeBridge.js`

Supporting:
- `tools/card_art/catalog/manual_recipe_canonical_map_v1.json`
- `tools/card_art/specs/catalog_recipe_defaults_v1.json`
- `tools/card_art/src/auditCatalogRecipes.js`

Compiler:
`tools/card_art/src/compilePrompts.js`

Now:
1. read runtime catalog;
2. read runtime card-policy sets;
3. partition eligible/blocked;
4. only eligible canonicals may reach prompt compilation;
5. manual reviewed recipe wins only AFTER rights pass;
6. otherwise derive inheritance-based recipe;
7. fail closed on missing category/archetype/variant.

### LEGO proof

15 manual pilot recipes exist:
- 14 eligible
- 1 blocked: `lego` -> `collecting.lego` -> runtime `licensedOnly`

The historical LEGO recipe remains in repo for audit but cannot enter baseline compiled output.

## Catalog-scale prompt family coverage

All **2,092/2,092** eligible interests statically map to:
- a valid art category modifier;
- a valid archetype;
- a non-empty visual variant pool.

Missing mappings: **0**.

New long-tail archetypes:
- learning_exploration
- companion_bond
- professional_world
- journey_machine
- music_listening
- reading_world

After splitting an overbroad `story_culture` family, current major distribution includes:
- music_listening: 272
- food_hero: 264
- group_play: 237
- story_culture: 183
- travel_vista: 181
- reading_world: 142

This is materially healthier than the earlier ~596 cards routed through story_culture.

## Hard-case treatment

Spec-known hard cases now protected:
- reviewed manual hard cases: AI, Cinema, Photography, Japan, Camping, Running
- LEGO: blocked by rights
- derived hard cases + human review: Reading, History, Philosophy, Mindfulness
- all Fashion: derived hard case + human review
- all abstractOnly: hard case + human review + explicit logo/mark/trade-dress negatives

Pure preflight fails if a hard-case recipe lacks human review.

## Pure local card-art commands

```bash
npm run audit-catalog-recipes
npm run compile-prompts
```

These are intended to make **zero image API calls**.

Important: checked-in `tools/card_art/generated/compiled_prompts_v1.jsonl` is still the old **15-hobby pre-bridge snapshot**. Do not treat it as full-catalog current output until the new compiler is actually executed.

## Zync Now activity semantics completed this checkpoint

Fixed:
- activity resolver no longer treats all `ipSensitive` as banned;
- only `licensedOnly` blocks generic activity fallthrough;
- abstractOnly can still receive safe activity semantics.

Examples:
- BookTok -> reading/discussion is allowed even though artwork is abstractOnly.
- Concerts -> live-culture venue semantics, not music-practice semantics.
- Theatre Going -> live-culture venue semantics, not home-viewing.
- food dining / food-dining -> social exploration.
- lifestyle local_culture -> social exploration.

Still conservative / null:
- bars
- nightlife
- parties
- boat parties / junk-boat parties
- deep alcohol drink taxonomy
- higher-risk outdoors/sports without explicit review
- career/professional concepts without explicit activity semantics

Regression tests written, not hosted-run.

## Latest completed report

`tools/card_art/report/CATALOG_SCALE_BRIDGE_ACTIVITY_AUDIT_V31.md`

## Recommended continuation

1. Execute `npm run audit-catalog-recipes` in an environment where command execution is available.
2. Execute `npm run compile-prompts`; still no image generation.
3. Audit a stratified sample of compiled prompts across every major archetype plus every hard case.
4. Fix prompt-family quality issues found by that sample before any image generation.
5. After 2026-10-01, run targeted Flutter analyze/tests and Android validation.
6. Keep image generation, Production and Play CLOSED until those gates pass.

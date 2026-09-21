# HOLD — Catalog Audit Before Full Prompt Expansion

Read `tools/card_art/report/INTEREST_CATALOG_RELEASE_AUDIT_V1.md` first.

The canonical catalog has now been audited. The exact current count is **3,403**, not ~2,032.

Do **not** expand all card-art recipes yet and do **not** generate images.

The catalog needs a targeted release-readiness cleanup first (aliases, genuinely missing everyday interests, duplicate-risk concepts, and exact-term ambiguity). Wait for the catalog remediation decision before building the full card-art prompt inventory.

No fal.ai calls. No API credits.

---

# Claude Code — Next Task After Prompt Review

The V1 prompt architecture has now been reviewed and hardened.

Read first:

1. `tools/card_art/specs/ZYNC_CARD_ART_PROMPT_SYSTEM_V1.md`
2. `tools/card_art/specs/PROMPT_REVIEW_V1_20260921.md`
3. `tools/card_art/specs/global_style_v1.json`
4. `tools/card_art/specs/archetypes_v1.json`
5. `tools/card_art/specs/archetype_variants_v1.json`
6. `tools/card_art/specs/category_modifiers_v1.json`
7. `tools/card_art/specs/subcategory_modifiers_v1.json`
8. `tools/card_art/specs/qa_rubric_v1.json`

## Next objective

Expand the structured prompt catalog from the 15-hobby smoke test to **every canonical interest currently shipped by the app**.

The authoritative source is:

- `mobile/lib/core/interest_catalog.dart`
- `mobile/lib/core/interest_catalog_part1.dart` through `interest_catalog_part10.dart`

The current catalog is about 2032 canonical interests. Do not assume 3000 and do not use the old `interests/En.json` / `Chi.json` files as the primary source if they conflict with the current mobile catalog.

## Critical rule

**Do not call fal.ai. Do not generate any images. Do not spend API credits.**

This task is prompt/catalog construction and compilation only.

## Required work

1. Parse every canonical mobile interest into a stable machine-readable source inventory.
2. Preserve canonical interest ID, English label, category, cluster/subcluster information, and rank where available.
3. Map every interest to:
   - art category
   - art subcategory
   - archetype
   - visual variant
   - tier
   - difficulty
   - human-review flag
4. Build a structured art recipe for every interest.
5. Compile every recipe through the reviewed V1 compiler.
6. Produce coverage/audit reports:
   - total source interests
   - total recipes
   - total compiled prompts
   - missing/unmapped entries
   - archetype distribution
   - visual-variant distribution
   - category/subcategory distribution
   - hard-case count
   - brand/IP-sensitive count
   - duplicate or near-duplicate concept groups
7. Stop after compilation and audit.

## Do not freestyle the art direction

Use the existing specs and curated archetype variants. You may create data mappings and identify gaps, but do not invent a replacement prompt philosophy.

If an interest cannot be mapped faithfully with the existing art vocabulary:
- flag it in an audit file,
- do not silently force it into a bad archetype,
- do not generate an image.

## Important IP/brand handling

The current interest catalog includes named artists, franchises, games, films, brands, and other IP-sensitive entities.

For these entries:
- never instruct the model to reproduce a real person's face or a protected character,
- never request logos or trademarked packaging,
- prefer a non-infringing thematic/experience representation where feasible,
- set `ip_sensitive: true`,
- set `human_review_required: true` where needed,
- flag entries that may need a product decision before artwork generation.

## Deliverables

Create/update:

- `tools/card_art/catalog/interest_source_inventory_v1.jsonl`
- `tools/card_art/catalog/hobby_recipes_v1.jsonl`
- `tools/card_art/generated/compiled_prompts_v1.jsonl`
- `tools/card_art/report/CATALOG_PROMPT_COVERAGE_V1.md`
- `tools/card_art/report/CATALOG_PROMPT_EXCEPTIONS_V1.jsonl`

Do not delete the 15-hobby pilot history.

At the end report:
- exact canonical source count
- recipe count
- compiled-prompt count
- unmapped count
- hard-case count
- IP-sensitive count
- commit SHA

Again: **NO IMAGE GENERATION.**

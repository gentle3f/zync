# Zync Card Art Pilot

Standalone fal.ai artwork generation pilot for Zync Hobby Cards. Lives entirely under
`tools/card_art/` and is isolated from the main app — no runtime dependency, no shared code.

## Setup

```bash
cd tools/card_art
npm install
cp .env.example .env   # then fill in FAL_KEY
```

## Usage

```bash
# preview prompts + cost estimate, no API calls
node src/generate.js --dry-run

# generate all 15 hobbies (skips any already in manifest.json)
node src/generate.js

# regenerate a specific hobby (max 2 attempts per hobby)
node src/generate.js --retry=bouldering

# generate only specific hobbies
node src/generate.js --only=piano,ai

# build contact-sheet.jpg + gallery.html from the manifest
node src/contact-sheet.js
```

## Model & mechanism

- Model: `fal-ai/nano-banana-pro/edit`
- Reference-style mechanism: the shared reference image
  (`references/zync-card-style-reference.png`) is uploaded once to fal storage and passed
  via `image_urls` on every request, steering illustration style / lighting / color grading
  without copying any layout, logo, or text from it.
- Aspect ratio: `2:3` (portrait), resolution `2K`.
- Cost: ~$0.15 per image at 1K/2K resolution (fal.ai pricing, checked 2026-09-21).

## Prompt composition

Each prompt is assembled from layered recipe files so hobbies are reusable, not one-off:

```
GLOBAL ZYNC STYLE  (recipes/pilot_hobbies_v1.json: global_style)
+ ARCHETYPE         (recipes/archetypes_v1.json: composition template shared by similar hobbies)
+ HOBBY RECIPE       (recipes/pilot_hobbies_v1.json: per-hobby subject/key objects)
+ REFERENCE STYLE    (recipes/pilot_hobbies_v1.json: reference_instruction)
+ GLOBAL RESTRICTIONS (recipes/pilot_hobbies_v1.json: global_restrictions)
```

See `src/buildPrompt.js`.

## Output (pilot_v1, legacy prompt builder)

- `output/pilot_v1/images/` — one PNG per hobby (per attempt)
- `output/pilot_v1/manifest.json` — full record of every generation
- `output/pilot_v1/contact-sheet.jpg` — grid preview
- `output/pilot_v1/gallery.html` — browsable gallery
- `report/PILOT_V1_REPORT.md` — scored review of the pilot batch

These pilot_v1 outputs and the report above are preserved as-is; they were generated with
the original ad-hoc `recipes/` prompt builder before the structured system below existed.

## V1 structured prompt system (specs/ + catalog/ + generated/)

The authoritative prompt architecture for scaling past the 15-hobby pilot lives in
`specs/ZYNC_CARD_ART_PROMPT_SYSTEM_V1.md` and its supporting JSON files. It compiles each
hobby's final prompt from an inheritance chain instead of hand-written one-off prompts:

```
global style (specs/global_style_v1.json)
→ archetype (specs/archetypes_v1.json — 15 archetypes, not collapsed to a generic set)
→ category (specs/category_modifiers_v1.json)
→ subcategory (specs/subcategory_modifiers_v1.json, optional)
→ hobby recipe (catalog/hobby_recipes_v1.jsonl)
→ optional override (catalog/hobby_overrides_v1.json for long-tail/hard-case hobbies,
   catalog/flagship_overrides_v1.json for the 5 benchmark hobbies)
→ global negatives (specs/global_style_v1.json: global_negatives)
→ compiled prompt (generated/compiled_prompts_v1.jsonl)
```

Model policy (from the spec): default `flux-2/edit`, fallback `gemini-25-flash-image/edit`,
premium rescue `nano-banana-pro/edit` — escalate only on a QA reroll trigger
(`specs/qa_rubric_v1.json`).

```bash
# pure preflight: parse runtime catalog + runtime rights policy + recipe inheritance
# no API calls and no image generation
npm run audit-catalog-recipes

# rights-gate the full runtime catalog, derive long-tail recipes, then compile all
# baseline-art-eligible canonical interests — still no API calls
npm run compile-prompts

# compile a fixed 41-interest stratified QA sample across manual/generic,
# new archetypes, hard cases and abstract-only policies — no image API calls
npm run audit-prompt-samples
```

The catalog-scale path is now rights-first:

```
mobile runtime catalog
→ mobile InterestCardPolicyResolver
→ catalogRecipeBridge.js
→ licensedOnly / notCollectible => blocked manifest
→ originalGeneric / abstractOnly => manual recipe if present, otherwise inherited recipe
→ buildPromptV1.js
→ generated/compiled_prompts_v1.jsonl
```

`src/catalogRecipeBridge.js` statically mirrors the bundled Dart catalog/parser and the
runtime card-policy sets. It writes auditable eligible/blocked manifests and refuses unknown
runtime categories instead of silently falling back. Reviewed manual recipes are mapped to
stable canonical IDs by `catalog/manual_recipe_canonical_map_v1.json`, but manual content
cannot bypass rights policy. In particular, the preserved legacy LEGO recipe maps to
`collecting.lego` and is blocked from baseline compilation because runtime policy is
`licensedOnly`.

At the 2026-09-22 V3 checkpoint the independent static audit is:

- runtime canonicals: **4,053**
- baseline-art eligible: **2,210**
- blocked by runtime rights policy: **1,843**
- abstract-only: **7**
- reviewed manual recipes: **15**, of which **14** are eligible and **1 (LEGO)** is blocked

The checked-in `generated/compiled_prompts_v1.jsonl` predates this bridge and is therefore a
**15-hobby pre-bridge snapshot**, not evidence that the full catalog has already been
compiled. Re-run `npm run compile-prompts` before treating generated prompt outputs as
current. The compiler makes no fal.ai calls.

## Reference-free FLUX default after launch QA

Launch-batch QA showed that using the full Zync card mockup as an edit reference
contaminated 7/16 FLUX outputs with copied card chrome/text. The structured batch
runner therefore now defaults to **reference-free `fal-ai/flux-2` text-to-image**.

The historical edit path remains available explicitly as `--model=edit`, but it
must not be used for catalog-scale first-pass generation with the current
`references/zync-card-style-reference.png`.

A four-card validation gate is provided before any new large run:

```bash
npm run audit-reference-free-v1
npm run generate-reference-free-v1
```

The validation set is:
- `crafts.diy`
- `lifestyle.game_nights`
- `fashion.streetwear`
- `technology.ai`

The first two previously suffered reference-copy contamination. The latter two
still leaked text after Gemini fallback and now have explicit no-signage /
no-screen-text overrides.

At 832x1248, the current FLUX.2 text-to-image estimate is about US$0.0125 per
image, so the four-card gate is roughly **US$0.05**.

## Launch-first structured image batch

Do **not** use the legacy `src/generate.js` for catalog-scale artwork. It is preserved only
for the historical 15-card pilot.

The rights-safe structured runner is:

```bash
# zero-credit preflight: rights gate + structured prompt compilation
npm run audit-launch-image-batch

# generate the reviewed launch batch through the default FLUX path
npm run generate-compiled-batch

# generate selected canonical IDs only
node src/generateCompiledBatch.js --only=sports.badminton,food.coffee

# reroll one failed card on the fallback model
node src/generateCompiledBatch.js --retry=technology.ai --model=fallback --only=technology.ai
```

Default batch:
`catalog/launch_image_batch_v1.json`

The current V1 batch contains 16 rights-safe USA/Hong Kong launch interests spanning
manual recipes, derived recipes, hard cases, Part 16 concepts, and multiple archetypes.
The runner rebuilds the runtime rights-first bridge in memory before every generation and
refuses any canonical that is not baseline-art eligible.

Model cost estimates recorded by the runner:
- FLUX.2 edit: ~US$0.025/image
- Gemini 2.5 Flash Image edit: ~US$0.039/image
- Nano Banana Pro edit: ~US$0.15/image

At 16 cards, the default FLUX first pass is approximately **US$0.40** before any QA rerolls.


See `src/buildPromptV1.js` for final prompt assembly. Catalog-scale output records include
canonical hobby ID, runtime category/cluster, art policy, recipe source, tier,
default/fallback/premium model, archetype, category, compiled prompt, negative constraints,
fallback hint, and QA notes.


## 48-card stratified validation

After the launch pilot and the Game Nights / Streetwear model A/B, the next
validation stage is a routed 48-card sample:

- batch: `catalog/stratified_image_batch_v1.json`
- orchestration: `src/runStratifiedBatch.js`
- output: `output/stratified_v1/`
- standard route: 32 cards via reference-free `flux-2`
- suppression-sensitive route: 16 cards via
  `flux-2/klein/9b/base` with a real API `negative_prompt`
- estimated first-pass cost: about **US$0.5824**

Run zero-credit compilation/rights preflight first:

```bash
npm run audit-stratified-v1
```

Only if that passes:

```bash
npm run generate-stratified-v1
```

The 48-card set is based on the existing stratified prompt-audit sample plus
three style-control cards. It intentionally spans repaired route families,
hard cases, abstract-only interests, manual/derived recipes, USA/HK launch
concepts, social/screen/text-prone scenes, and ordinary low-risk scenes.

QA must be reported separately by model route. In addition to normal
recognition/text/logo/anatomy checks, explicitly measure whether Klein's
suppression benefit creates unacceptable photoreal or stock-photo style drift.

Do not expand from this validation directly to all baseline-art-eligible
canonicals unless the failure rates and style consistency are reviewed first.

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
# compile all hobby recipes into generated/compiled_prompts_v1.jsonl — no API calls
node src/compilePrompts.js
```

This only reads `specs/` and `catalog/` and writes `generated/compiled_prompts_v1.jsonl`;
it never calls fal.ai. See `src/buildPromptV1.js` for the compiler and
`generated/compiled_prompts_v1.jsonl` for the auditable per-hobby output (hobby id, tier,
default/fallback/premium model, archetype, category, subcategory, compiled prompt, negative
constraints, fallback hint, QA notes).

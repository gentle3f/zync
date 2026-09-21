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

## Output

- `output/pilot_v1/images/` — one PNG per hobby (per attempt)
- `output/pilot_v1/manifest.json` — full record of every generation
- `output/pilot_v1/contact-sheet.jpg` — grid preview
- `output/pilot_v1/gallery.html` — browsable gallery
- `report/PILOT_V1_REPORT.md` — scored review of the pilot batch

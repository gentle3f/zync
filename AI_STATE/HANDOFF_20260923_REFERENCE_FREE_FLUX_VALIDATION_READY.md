# Zync — Reference-Free FLUX Validation Ready

Date: 2026-09-23
Branch: `card-art-pilot-v1-20260921`

Read `AI_STATE/OPERATING_RULES.md` before any write or external action.

## Why this checkpoint exists

The first 16-card launch image pilot proved the structured compiler and rights
gate work, but exposed a blocking generation-quality problem:

- FLUX.2 edit + the current full-card Zync reference contaminated 7/16 first-pass
  images with copied card chrome, logos, titles, badges, or garbled text.
- Gemini fallback cleaned most contaminated cards.
- `fashion.streetwear` and `technology.ai` still leaked readable/gibberish
  text on both models.
- Catalog-scale generation must not continue on the old reference-conditioned
  FLUX edit default.

The contamination is tied to using a full 10-card Zync mockup as an edit
reference, not to the structured compiler.

## New default generation policy

The structured runner now defaults to:

`fal-ai/flux-2`

This is the reference-free FLUX.2 text-to-image endpoint.

Important behavior:
- text-only FLUX does **not** upload or send
  `references/zync-card-style-reference.png`
- the compiled `REFERENCE STYLE:` section is stripped before the API request
- edit-based models still receive the reference explicitly
- manifest entries now record:
  - `conditioning_mode: text_only | reference_edit`
  - `reference_style_path` or null

Model aliases in `generateCompiledBatch.js`:
- `default` / `text` -> `flux-2`
- `edit` -> `flux-2/edit`
- `fallback` -> existing Gemini edit model
- `premium` -> existing Nano Banana Pro edit model

Estimated FLUX.2 text-to-image cost at 832x1248:
approximately **US$0.0125/image**.

## Targeted override fixes

`tools/card_art/catalog/hobby_overrides_v1.json`

### fashion.streetwear

Now explicitly:
- uses generic unbranded streetwear
- avoids storefront names, signs, posters, logos, brand wordmarks and pseudo-text
- requires background surfaces to remain text-free
- substitutes blank / abstract surfaces where signage would normally appear

### technology.ai

Now explicitly:
- depicts AI through abstract nodes, linked structures, flowing data-like light
  and non-textual diagrams
- avoids readable screens, labels, slogans, code, numbers, chat bubbles,
  software logos, pseudo-text and multi-panel collage
- requires any interface/projection to contain only non-linguistic visual forms

## Small validation gate

Do **not** rerun the full 16-card batch yet.

Four-card validation set:
- `crafts.diy`
- `lifestyle.game_nights`
- `fashion.streetwear`
- `technology.ai`

Why these four:
- DIY + Game Nights were strong examples of the old reference-copy
  contamination.
- Streetwear + AI remained broken after Gemini fallback.

Commands:

```bash
cd tools/card_art
npm run audit-reference-free-v1
npm run generate-reference-free-v1
```

Expected first-pass cost: approximately **US$0.05**.

Validation success criteria:
1. no Zync logo/card chrome/card number/rarity badge
2. no copied Board Games or other reference-card composition
3. no readable or garbled signage/UI text
4. correct hobby recognition
5. artwork-only output suitable for card composition later
6. no multi-panel/collage contamination

If all four pass:
- reference-free FLUX becomes the approved cheap first-pass path
- expand to a larger stratified validation batch, not the whole 2,210 at once

If one or more fail:
- diagnose prompt/model-specific failure
- do not automatically return to the old reference image
- retry only the failed IDs with the smallest justified model escalation

## Infrastructure

Keep Vercel, GitHub Actions, Production and Play closed.
Do not commit FAL_KEY or any secret.

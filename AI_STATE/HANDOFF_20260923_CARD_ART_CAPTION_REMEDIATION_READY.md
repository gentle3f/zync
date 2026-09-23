# Zync — Card Art Global Caption Remediation Ready

Date: 2026-09-23
Branch: `card-art-pilot-v1-20260921`
Parent HEAD before this remediation: `34c09c249a741e3b0790c26018a9f7ffb80e2487`

## Mandatory operating guard

Read `AI_STATE/OPERATING_RULES.md` before any write, API generation, CI, deployment, or external action.

Infrastructure remains closed:
- GitHub Actions: do not trigger; this branch is outside the push-trigger branch filters checked before the remediation commit
- Vercel: disabled for this branch in `vercel.json`
- Production / Google Play: closed
- no secret exposure
- no auto-rerolls

## What changed

### 1. Global hobby-title / caption suppression

The global style previously said the art should feel like a miniature lifestyle **poster**, which plausibly reinforced the observed title/caption behaviour.

That phrase is now replaced with a hero-illustration direction that explicitly says the composition is **not** a poster, advertisement, editorial cover, card face, or designed page.

A new shared `global_text_policy` is compiled into every prompt. It tells the model that the hobby/interest name is semantic context only and must never appear visually, and forbids:
- hobby name
- title / subtitle
- caption / heading / label / footer
- explanatory/poster/body copy
- text boxes / lower-thirds
- deliberate typography-reserved space
- poster/ad/editorial/card-face layouts

Equivalent global negative constraints were also added so Klein receives them through its real `negative_prompt` path.

### 2. Exact recognition rules

Added exact-ID rules at the end of `catalog_recipe_defaults_v1.json` so they override generic business/learning defaults:

- `business.coworking`
  - shared open coworking workspace
  - at least three independent workers
  - communal desk / shared seating
  - distinct individual work setups and a natural neighbour interaction
  - explicitly excludes lab/workshop/prototype/boardroom substitutions

- `business.marketing`
  - physical campaign-planning scene
  - blank product/packaging mockups
  - image cards and unlabeled colour/material swatches
  - hands actively comparing/refining a layout
  - explicitly excludes workshop/hardware/jewelry/manufacturing substitutions and readable copy

- `learning.book_genre.booktube`
  - small optional recognition repair
  - creator speaking about one plain book
  - generic camera or phone on tripod aimed at creator
  - optional generic microphone
  - no platform UI/logo/text

### 3. Targeted 8-card validation is prepared

New files:
- `tools/card_art/catalog/caption_remediation_validation_v1.json`
- `tools/card_art/src/runCaptionRemediationValidation.js`

New scripts:
- `npm run audit-caption-remediation-v1`
- `npm run generate-caption-remediation-v1`

Sample:
- career.legal_profession
- technology.generative_ai
- travel.general
- business.coworking
- business.marketing
- travel.japan
- learning.book_genre.booktube
- technology.electronics (known-clean control)

Routes:
- 7 Standard FLUX
- 1 Klein (BookTube, preserving its previous route)

Estimated first-pass API spend: **$0.0989**.

## Validation state

This chat performed static structure checks only:
- modified JSON objects serialize cleanly
- targeted batch count is exactly 8
- exact-ID remediation rules occur exactly once
- compiler includes `global_text_policy`

**No FAL API generation was run in this chat and no claim is made that the images pass.**
The next execution step is:

```bash
cd tools/card_art
npm run audit-caption-remediation-v1
npm run generate-caption-remediation-v1
```

Do not run the paid generation until the dry-run prompt audit is clean.

## Decision gate after the 8-card test

Only consider a 50-card confirmatory batch if:
1. the three cross-archetype title/caption cases materially clean up;
2. coworking and marketing recognition materially improve;
3. the known-clean electronics control does not regress;
4. no raw compiler-id leakage reappears.

Japan signage and Klein style drift remain separate unresolved risks. Do not claim those are solved unless the new images prove it.

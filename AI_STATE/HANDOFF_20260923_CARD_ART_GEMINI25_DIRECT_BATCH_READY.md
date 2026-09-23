# Zync — Direct Google Gemini 2.5 Flash Image 24-Card Batch Ready

Date: 2026-09-23
Branch: `card-art-pilot-v1-20260921`
Parent state: `46545286c4e82c92256b8745fe8691ba77ca5c7e`

## Purpose

The 24-card Standard-FLUX semantic-anchor revalidation failed badly despite precise compiled prompts.

This checkpoint prepares an apples-to-apples discriminator:
- exact same 24 canonical interests;
- exact same current compiled prompts;
- switch only the generation route/model;
- use **Google Gemini API directly**;
- **do not use fal.ai**.

Target model:
`gemini-2.5-flash-image`

This is a diagnostic comparison, not a production migration.

## Why Gemini 2.5 Flash Image

The user explicitly requested a bulk comparison against Gemini Flash Image and has previously instructed that Image 2.5 must not be called through fal.ai.

Official Google documentation confirms:
- model: `gemini-2.5-flash-image`;
- image generation supported;
- Batch API supported;
- Batch image output price: about **US$0.0195/image**;
- model is deprecated and scheduled to shut down **2026-10-02**.

Therefore this run is useful as a near-term discriminator, not as a long-term production dependency.

Expected 24-image batch output cost:
- 24 × $0.0195 = **US$0.468**
- text input token charges are additional but small.

## Repo artifacts

New config:
`tools/card_art/catalog/gemini25_direct_batch_24_v1.json`

New runner:
`tools/card_art/src/runGemini25DirectBatch24.js`

The runner:
- imports the real catalog bridge and prompt compiler;
- recompiles the exact same 24 IDs from `semantic_anchor_revalidation_24_v1.json`;
- uses no Gemini-specific semantic prompt rewrite;
- submits the requests directly to Google's `batchGenerateContent` endpoint;
- uses `GEMINI_API_KEY`;
- never imports or calls fal.ai;
- requests 2:3 images;
- saves the exact final prompt sent for each canonical;
- saves Google batch job name;
- preserves response index/metadata;
- writes a canonical-ID-based image filename;
- writes a manifest for auditable prompt-to-image mapping.

This makes the experiment useful for both:
1. model comparison; and
2. prompt/request/image mapping forensics.

## Zero-cost dry run

From `tools/card_art`:

```bash
node src/runGemini25DirectBatch24.js --dry-run
```

Confirm:
- exactly 24 IDs;
- same IDs as the failed FLUX semantic-anchor set;
- exact current compiled semantic prompts;
- model shown as `gemini-2.5-flash-image`;
- no fal route;
- no unexpected prompt mutation.

## Submit

Requires `GEMINI_API_KEY` in the local environment.

```bash
node src/runGemini25DirectBatch24.js --submit
```

This creates:
`tools/card_art/output/gemini25_direct_batch_24_v1/batch_job.json`

## Collect

```bash
node src/runGemini25DirectBatch24.js --collect
```

If the batch has completed, this writes:
- images under `output/gemini25_direct_batch_24_v1/images/`
- `manifest.json`
- `batch_status.json`

The manifest preserves:
- canonical ID;
- exact final prompt;
- archetype / visual variant;
- provider;
- model;
- Google batch name;
- response index;
- response metadata;
- local image path.

## QA / decision rule

Inspect all 24 and compare card-for-card against:
`output/semantic_anchor_revalidation_24_v1/`

Use the same PASS / MINOR / FAIL rubric.

Focus especially on the explicit contradictions that FLUX produced:
- Ice Fishing: frozen lake + ice hole vs paddleboard/open water;
- Dogs: dog vs rodents/controller;
- Board Gaming: tabletop vs video-game controllers;
- Photography: camera vs binoculars;
- Cycling: bicycle vs skiing;
- Ferries: ferry vs car/workshop;
- Egg Tart/Bun Cha: exact dish;
- Music / Screenwriting / Legal Thriller / Coworking: readable code/screen soup;
- Streetwear: readable storefront signage;
- Pilates: actual exercise vs gadgets;
- Sauna: general-audience coverage and no domestic-bath framing;
- chrome/frame recurrence.

Interpretation:
- If Gemini follows the same exact prompts substantially better, evidence shifts strongly toward a **FLUX/model-route problem** rather than a prompt-content problem.
- If Gemini produces the same bizarre semantic substitutions, inspect request/response mapping and shared compiler/pipeline assumptions before blaming either model.
- Do not use one clean run as production certification.

## Important constraints

- **No fal.ai for Image 2.5.**
- No 100-card run.
- No 1731-card run.
- No auto-scale after success.
- Robotics and American Football remain quarantined.
- Vercel, GitHub Actions, Production and Play remain closed.

## Infrastructure verification at preparation time

- branch Actions runs: 0
- Vercel deployment for this branch: false
- no Google API call made while preparing this checkpoint

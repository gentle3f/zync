# Zync — Game Nights / Streetwear Model-Level A/B Ready

Date: 2026-09-23
Branch: `card-art-pilot-v1-20260921`

Read `AI_STATE/OPERATING_RULES.md` before any write or external action.

## Why this A/B exists

Reference-free FLUX.2 fixed the old Zync-card-reference contamination, but two
problem cards still fail after two rounds of explicit prompt-level correction:

- `lifestyle.game_nights`
  - FLUX repeatedly bakes a readable GAME NIGHT(S) caption into the artwork.
- `fashion.streetwear`
  - FLUX repeatedly invents a swoosh-like / branded-looking sneaker silhouette.

At this point the evidence no longer supports more prompt-only retries on the
same FLUX endpoint.

## Model-level alternatives now wired into the runner

### 1. Gemini 2.5 Flash Image text-to-image

Runner alias:

`geminiText`

Endpoint:

`fal-ai/gemini-25-flash-image`

Important:
- true text-to-image
- no reference image uploaded
- no old 10-card Zync mockup contamination path
- estimated cost: US$0.039/image

### 2. FLUX.2 Klein 9B Base with real negative_prompt

Runner alias:

`kleinNegative`

Endpoint:

`fal-ai/flux-2/klein/9b/base`

Important:
- text-to-image
- no reference image
- uses a real API `negative_prompt` field built from the compiled negative
  constraints
- manifest records the exact API negative prompt
- estimated cost at 832x1248: about US$0.0114/image

This is materially different from the main `fal-ai/flux-2` endpoint, where
all AVOID language is only inline positive-prompt text.

## A/B validation set

Only:
- `lifestyle.game_nights`
- `fashion.streetwear`

Do NOT rerun DIY or AI.
Do NOT rerun the 16-card batch.

Commands:

```bash
cd tools/card_art

npm run audit-model-ab-v1-gemini
npm run audit-model-ab-v1-klein

npm run generate-model-ab-v1-gemini
npm run generate-model-ab-v1-klein
```

Expected calls:
- Gemini text: 2
- Klein negative-prompt: 2
- total: 4

Expected total estimated cost: roughly US$0.10.

## What this test must decide

For Game Nights:
- does Gemini avoid the caption?
- does Klein's real negative_prompt avoid the caption?

For Streetwear:
- does Gemini avoid the branded-looking sneaker silhouette?
- does Klein's real negative_prompt avoid the branded-looking sneaker silhouette?

Score all four outputs:
- PASS / MINOR / FAIL
- 1–5 visual quality

Do not auto-reroll any failed output.

## Decision rule

If one model passes both cards cleanly:
- treat that model as the preferred path for text/trademark-prone cards.

If Klein passes both while standard FLUX failed:
- retain standard FLUX for cheap general first-pass work,
- route known suppression-sensitive cards to Klein.

If Gemini passes both while Klein fails:
- route these sensitive classes to Gemini text-to-image.

If neither model passes both:
- stop model churn and redesign the affected visual concepts more structurally
  before any wider batch.

Do not run the 48-card stratified validation until this A/B is reviewed.

## Infrastructure

Keep Vercel, GitHub Actions, Production and Play closed.
Do not expose or commit FAL_KEY.

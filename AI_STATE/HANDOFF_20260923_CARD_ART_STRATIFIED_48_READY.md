# Zync — 48-Card Stratified Validation Ready

Date: 2026-09-23
Branch: `card-art-pilot-v1-20260921`

Read `AI_STATE/OPERATING_RULES.md` before any write or external action.

## Current model policy

- Ordinary cards: reference-free `fal-ai/flux-2`.
- Suppression-sensitive cards: `fal-ai/flux-2/klein/9b/base` with API `negative_prompt`.
- Gemini text-to-image is excluded from this 48-card route after the prior rendered-wordmark failure.
- The old full-card reference image is not used by either route.

## Shared prompt cleanup

`tools/card_art/specs/global_style_v1.json` no longer contains the literal word `Zync`.
The visual intent is unchanged. Model metadata is now aligned to:
- default: `flux-2`
- fallback: `flux-2/klein/9b/base`

## New batch

`tools/card_art/catalog/stratified_image_batch_v1.json`

Total: **48**
- standard FLUX: **32**
- Klein negative-prompt: **16**
- estimated first-pass cost: **US$0.5824**

The sample uses the existing 45-interest stratified prompt-audit set plus Coffee, Road Trips and Photography controls.

### Standard route — 32

sports.american_football, sports.hiking, transport.car_meets, sports.badminton,
gaming.chess, wellness.weightlifting, wellness.yoga, outdoors.surfing,
outdoors.kayaking, sports.gravel_cycling, lifestyle.gardening, food.yum_cha,
arts.lion_dance, career.nursing, pets.dog_agility, learning.archaeology,
books.reading, history.general, learning.philosophy, wellness.mindfulness,
collecting.stamps, transport.railways, learning.math_olympiad,
learning.study_abroad, wellness.hot_springs, wellness.sauna,
lifestyle.repair_workshops, arts.podcasting, gaming.escape_room_design,
food.coffee, travel.roadtrip, photography.general.

### Klein route — 16

lifestyle.game_nights, motorsport.sim_racing, fashion.streetwear,
learning.model_united_nations, learning.campus_radio,
business.case_competitions, business.founder_meetups, lifestyle.book_swaps,
arts.video_editing, arts.vlogging, arts.animation_production, arts.blogging,
gaming.game_streaming, technology.python, learning.book_genre.booktok,
travel.style_deep.unesco_heritage_travel.

## Orchestration

New source:
`tools/card_art/src/runStratifiedBatch.js`

The existing rights-safe runner now supports the output namespace env var
`ZYNC_CARD_ART_OUTPUT_TAG`.

This batch writes under:
`tools/card_art/output/stratified_v1/`

Commands:

```bash
cd tools/card_art
npm run audit-stratified-v1
npm run generate-stratified-v1
```

Run generation only if the audit passes.

## QA requirements

Every image:
- PASS / MINOR / FAIL
- quality 1–5
- one-line diagnosis

Check recognizability, text/gibberish, logos/trade dress, IP leakage, anatomy/key objects,
card-chrome/UI contamination, collage contamination, and card-framing suitability.

Report route metrics separately for standard FLUX and Klein:
- PASS/MINOR/FAIL counts and rates
- text/logo/trademark defects
- recognition defects
- anatomy/object defects

Klein also needs an explicit style-drift review because prior output leaned more photoreal/stock-photo.

Do not auto-reroll failures during first review. Classify defects first and choose the smallest targeted retry set.

Keep Vercel, GitHub Actions, Production and Play closed. Do not expose or commit FAL_KEY.

# Zync — Card Art Launch Batch Ready

Date: 2026-09-23
Branch: `card-art-pilot-v1-20260921`

Read `AI_STATE/OPERATING_RULES.md` before any write or external action.

## Interest system

The hobby/interest system is frozen for the current launch phase:
- canonical interests: 4,053
- display labels: 8/8 supported locales complete
- USA + Hong Kong localized alias layer: 222 id-locale rows / 384 terms
- Quick Start audited and fixed
- do not resume speculative hobby/alias expansion

## Current rights partition

Recounted from the current 4,053 runtime catalog using
`InterestCardPolicyResolver` semantics:

- originalGeneric: **2,203**
- abstractOnly: **7**
- baseline-art eligible: **2,210**
- licensedOnly: **1,843**
- notCollectible: **0**
- blocked: **1,843**

The +118 Part 16 growth is baseline-art eligible and did not increase the blocked count.

## Image-generation pipeline

Legacy `tools/card_art/src/generate.js` remains historical 15-card pilot only.

New structured runner:

`tools/card_art/src/generateCompiledBatch.js`

It:
1. rebuilds the rights-first runtime catalog bridge in memory;
2. refuses licensedOnly/notCollectible canonicals;
3. compiles with the structured V1 prompt inheritance system;
4. defaults to FLUX.2 edit;
5. supports `--dry-run`, `--only`, `--retry`, and model selection;
6. records model, prompt, variant, recipe source, rights policy, attempt,
   estimated cost and QA-pending status in the launch manifest.

Commands:

```bash
npm run audit-launch-image-batch
npm run generate-compiled-batch
```

Default launch batch:

`tools/card_art/catalog/launch_image_batch_v1.json`

## V1 launch image batch

16 baseline-art eligible cards:

- sports.american_football
- sports.hiking
- sports.badminton
- gaming.board
- outdoors.bouldering
- food.coffee
- travel.roadtrip
- photography.general
- crafts.diy
- technology.ai
- learning.campus_life
- lifestyle.game_nights
- pets.dogs
- fashion.streetwear
- music.k_pop
- transport.car_meets

Coverage includes:
- USA-specific launch concepts
- Hong Kong-specific launch concepts
- manual recipes
- derived recipes
- hard cases
- Part 16 additions
- multiple visual archetypes

Estimated first-pass FLUX cost: **~US$0.40**.

## Prompt-only preflight findings and fixes

Preflight caught four material routing problems before spending credits:

1. American Football was too generic.
   - now explicitly requires generic helmet + shoulder pads + one brown oval
     football + yard-line field cues
   - avoids rugby/soccer confusion and team branding

2. Hiking inherited sports/solo_action.
   - now `nature_immersion / trail_approach`
   - requires walking posture + trail + practical day-hike gear

3. Game Nights inherited lifestyle/urban_discovery/street_corner.
   - now `group_play / eye_level_reaction`
   - requires 3-4 engaged players and a visible tabletop game action

4. Car Meets inherited journey_machine/owner_machine.
   - now `community_gathering / shared_activity`
   - requires multiple enthusiasts + at least two generic unbranded cars
   - explicitly avoids dealership/advertisement framing

All four recompiled correctly after the patch.

The stratified zero-credit prompt audit sample now includes these four cases.

## Model policy

- default: FLUX.2 edit (~US$0.025/image)
- fallback: Gemini 2.5 Flash Image edit (~US$0.039/image)
- premium rescue: Nano Banana Pro edit (~US$0.15/image)

Do not escalate automatically. QA first:
1. FLUX first pass
2. FLUX reroll if warranted
3. Gemini fallback if still weak
4. Nano Banana Pro only for justified flagship/rescue

## Infrastructure

Keep Vercel, GitHub Actions, Production and Play closed.

Image generation is now authorized by the user for this task, but actual fal.ai
API calls require the configured `FAL_KEY` in the card-art execution
environment. Do not expose or commit that secret.

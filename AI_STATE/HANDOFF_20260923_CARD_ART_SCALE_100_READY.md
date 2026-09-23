# Zync — 100-Card Scale Validation Ready

Date: 2026-09-23
Branch: `card-art-pilot-v1-20260921`

Read `AI_STATE/OPERATING_RULES.md` before any write or external action.

## Why this stage is now allowed

The compiler-format caption-leak root cause has been fixed and validated.

Targeted 8-card result:
- 8/8 API calls succeeded
- root-cause validation PASS
- no more HEAT ROOM / IMMERSION_RITUAL / VISUAL VARIANT leakage
- 2 of 4 secondary standard-FLUX failures also improved
- remaining two genuine suppression failures are understood:
  - `sports.american_football`: jersey number / logo association
  - `food.yum_cha`: thematic signage text

The next step can therefore test scale rather than another tiny pilot.

## New batch

`tools/card_art/catalog/scale_100_batch_v1.json`

Output namespace:

`tools/card_art/output/scale_100_v1/`

Total:
- **100 cards**
- **75 standard reference-free FLUX**
- **25 Klein negative-prompt**
- estimated first-pass cost: **US$1.2225**

The batch contains:
- **98 previously ungenerated canonicals**
- **2 intentional sentinel reroutes**

Sentinels:
- `sports.american_football` -> Klein
- `food.yum_cha` -> Klein

These two verify that the new risk-class routing policy actually fixes the
known standard-FLUX suppression failures rather than only being theoretical.

## Sampling design

Standard route:
- category quotas across 20 runtime worlds
- known suppression-risk classes excluded
- common / mid-tail / long-tail coverage deliberately mixed
- 75 total

Klein route:
- 25 cards across known suppression-risk classes:
  - uniform/branded-sports risk
  - ethnic/signage-heavy food/market risk
  - fashion / footwear trade-dress risk
  - group_play / social-caption risk
  - screen / creator / campus text risk
  - abstract-only concepts
  - event / networking / convention text risk

Klein remains only 25% of the batch because prior QA found frequent
photoreal/stock-photo style drift. It is not used defensively for every hard card.

## Commands

```bash
cd tools/card_art

npm run audit-scale-100-v1
npm run generate-scale-100-v1
```

Run generation only after the zero-credit audit passes.

## Required QA

Every image:
- PASS / MINOR / FAIL
- quality 1–5
- concise diagnosis
- defect class
- rank stratum: common / mid / long
- model route

Hard checks:
1. hobby recognizability
2. readable/gibberish text
3. logos/trademarks/trade dress
4. anatomy/key-object integrity
5. poster/card chrome/borders
6. copyright/IP leakage
7. composition coherence
8. artwork suitability for mobile card framing

Klein additionally:
- NONE / MINOR / MATERIAL style drift

Report metrics by:
- overall
- standard vs Klein
- category
- archetype
- common / mid / long rank stratum

## Sentinel decision

For `sports.american_football`:
- specifically check jersey numbers, sportswear logos, swoosh-like marks and
  team-brand visual cues.

For `food.yum_cha`:
- specifically check Chinese signage, lantern text, banners, menu text and
  pseudo-readable characters.

If either sentinel still FAILS on Klein, do not assume that risk class is solved.

## Scale decision after 100

Do not automatically reroll failures during first review.

After QA:
- classify defect families
- calculate route and rank-stratum failure rates
- identify smallest retry set
- decide whether the next production-validation chunk should be 200, 300, or
  remain around 100

Do not jump directly to all 2,210 eligible interests.

## Infrastructure

Keep Vercel, GitHub Actions, Production and Play closed.
Do not expose or commit FAL_KEY.

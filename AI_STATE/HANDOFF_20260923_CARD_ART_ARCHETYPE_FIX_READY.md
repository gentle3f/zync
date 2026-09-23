# Zync — Archetype Content Fix Validation Ready

Date: 2026-09-23
Branch: `card-art-pilot-v1-20260921`

Read `AI_STATE/OPERATING_RULES.md` before any write or external action.

## Why this remediation exists

The 100-card scale validation showed that failures cluster strongly by
archetype rather than randomly:

- reading_world: 100% FAIL
- food_exploration: 100% FAIL
- tech_workspace: 80% FAIL
- professional_world: 71% FAIL
- travel_vista: 75% FAIL

At the same time:
- both uniform-sports sentinels and nearby team-sports examples remained
  contaminated by jersey numbers / logos even on Klein;
- ethnic/signage-heavy food scenes remained contaminated by readable or
  pseudo-readable signage even on Klein.

Therefore this pass changes scene design and recognition strategy, not merely
negative wording or model routing.

## Archetype content changes

### professional_world

New policy:
- profession must read from one concrete physical action/tool/client/object
- hands/tool/object/task dominate the frame
- screens, documents, certificates, signs, slides, whiteboards and paperwork
  are absent or small/blank
- no generic laptop-office or handshake stock-photo framing

### tech_workspace

New policy:
- technology reads from physical input/output, hardware, device, prototype,
  experiment or gesture
- displays are optional and subordinate
- any display uses only abstract geometry, image previews, nodes, unlabeled
  graphs, shapes, waveforms or non-linguistic feedback
- no code, terminal windows, menus, UI labels, dense dashboards or
  screen-dominant compositions

### reading_world

New policy:
- plain, unbranded books with blank/abstract covers
- pages remain unreadable
- reader posture/reaction/exchange carries the concept
- no cover/spine titles, shelf labels, bookstore signs, posters or
  title-dependent genre cues

### food_exploration

New policy:
- close people + food interaction
- dishes, serving hands, steam, utensils, ingredients and reactions carry the
  scene
- venue façade/signage is cropped away
- no menus, lantern writing, banners, wall signs, packaging labels or branded
  décor

### travel_vista

New policy:
- destination identity comes from architecture, terrain, skyline, shoreline,
  route geometry, transit form or traveler action
- never depend on storefronts, road signs, station boards, banners, ads,
  license plates or written place names

## Structural class fixes

### Uniform / team sports

A final profile rule now reframes selected team sports as:
- generic practice/training context
- solid unmarked practice kit
- no printed jersey numbers
- no team crest/sponsor patch
- no swoosh-like or three-stripe-like mark
- no manufacturer badge
- no stadium advertising / scoreboard

American Football receives a final exact rule preserving its sport-specific
recognition constraints:
- exactly one brown oval football
- helmet + shoulder pads
- yard-line context
- no soccer ball / rugby kit / round ball / multiple footballs

### Ethnic/signage-heavy food

Selected cuisine/market interests now use:
- close table / kitchen / serving-counter framing
- cuisine recognized through dishes, ingredients, utensils, serving method,
  steam, tea or preparation
- plain text-free background surfaces
- no storefronts, menu boards, lantern text, banners, wall calligraphy,
  packaging labels, price signs or readable scripts

## Targeted 20-card validation

Batch:
`tools/card_art/catalog/archetype_fix_validation_v1.json`

Output:
`tools/card_art/output/archetype_fix_v1/`

Routes:
- 14 standard FLUX
- 6 Klein negative-prompt
- estimated first-pass cost: **US$0.2434**

### professional_world — 6
- business.startups
- business.coworking
- business.marketing
- career.software_engineering
- career.legal_profession
- career.journalism

### tech_workspace — 4
- technology.electronics
- technology.generative_ai
- technology.machine_learning
- technology.javascript

### reading_world — 3
- learning.book_genre.literary_fiction
- learning.fiction
- learning.book_genre.booktube

### travel_vista — 3
- travel.general
- travel.destination_deep.tokyo_travel
- travel.japan

### ethnic/signage-heavy food — 2
- food.yum_cha
- food.food_markets

### uniform sports — 2
- sports.american_football
- sports.football

Commands:

```bash
cd tools/card_art
npm run audit-archetype-fix-v1
npm run generate-archetype-fix-v1
```

Run generation only if the audit passes.

## QA decision rules

Every card:
- PASS / MINOR / FAIL
- quality 1–5
- one-line diagnosis
- defect class

Compare explicitly against the prior scale-100 result for the same ID.

Archetype success should be judged by before/after FAIL reduction, not merely
individual beauty.

### professional_world target
- concrete profession recognition improves
- no document/screen/sign text
- no generic corporate stock-photo scene

### tech_workspace target
- no code / terminal / UI labels
- technology remains recognizable from physical interaction/output

### reading_world target
- no cover/spine/page/sign text
- reading/genre experience remains clear enough without text

### travel_vista target
- no city/station/shop/road signage
- destination/travel identity still clear

### ethnic food target
- Yum Cha / Food Markets have no signage/menu/lantern/banner/script leakage

### uniform sports target
- no jersey number
- no team/sponsor crest
- no swoosh/stripe/manufacturer-like mark
- sport still instantly recognizable

Klein cards must also receive NONE / MINOR / MATERIAL style-drift classification.

Do not auto-reroll failures.

## Scale decision

Do not run another 100-card batch yet.

If this 20-card gate materially improves the five archetype families and both
class-level tests, then design the next scale batch.

If failures remain concentrated, fix only the remaining defect family rather
than changing the whole compiler/model stack.

## Infrastructure

Keep Vercel, GitHub Actions, Production and Play closed.
Do not expose or commit FAL_KEY.

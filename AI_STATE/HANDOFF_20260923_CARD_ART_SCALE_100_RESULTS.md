# Zync — 100-Card Scale Validation: Results

Date: 2026-09-23
Branch: `card-art-pilot-v1-20260921`

Read `AI_STATE/OPERATING_RULES.md` before any write or external action.

## Bottom line

**Do not scale up.** This batch does not confirm the system is ready for the
next chunk. Overall PASS rate is 47%, Klein performed *worse* than standard
FLUX in aggregate (36.0% PASS vs 50.7% PASS), both sentinel re-tests still
FAIL, and several archetypes have catastrophic, systemic fail rates (100% for
`reading_world` and `food_exploration`, 80% for `tech_workspace`, 71% for
`professional_world`). The recommendation is a targeted remediation pass on
specific archetypes/categories, not a larger batch.

## What ran

```bash
cd tools/card_art
npm run audit-scale-100-v1
npm run generate-scale-100-v1
```

### Pre-generation: found and fixed a genuine execution blocker

The Step-1 audit failed its "no raw internal identifiers in model-facing
prompts" check: `photography.street` and `arts.portrait_photography` (both
using the `lens_perspective` archetype) compiled prompts containing the
literal string `travel_vista` — a raw archetype id — inside the sentence
"composition too similar to travel_vista". Traced to `specs/archetypes_v1.json`:
`lens_perspective.avoid[2]` had hardcoded that raw id as pre-existing content,
predating the prompt-format fix (which only changed the *compiler's own*
section-header format, not the *content* of spec text fed into it). A full
scan of `archetypes_v1.json` and `archetype_variants_v1.json` confirmed this
was the only such leak (not systemic).

Two minimal fixes applied:
1. `specs/archetypes_v1.json`: reworded the offending avoid entry to
   "composition too similar to a scenic travel-vista landscape shot" — no
   raw id.
2. `src/buildPromptV1.js`: broadened the internal-id regression guard to
   check the compiled prompt against **every** known archetype/variant/
   subcategory id (via the `archetypes`/`variants`/`subcategories` params
   already in scope), not just the current hobby's own id — so a future
   leak like this (one archetype's spec text naming another archetype) fails
   closed instead of silently passing.

Re-ran the audit after the fix: clean. **100/100 compiled**, 75 standard
($0.938 est.) + 25 Klein ($0.285 est.) = **$1.2225 est.**

### Audit result (after fix)

Passed. 100/100 compiled, 75 standard / 25 Klein, no blocked/unknown IDs, zero
`ARCHETYPE (`/`VISUAL VARIANT (`/`CATEGORY (`/`SUBCATEGORY (` occurrences,
zero raw internal ids in model-facing text, zero `REFERENCE STYLE` leakage on
either text-only route, Klein confirmed sending a real, non-empty API
`negative_prompt` for all 25 cards.

### Generation result

**100/100 API calls succeeded**, no failures, no automatic retries.
**Actual cost: $1.222** ($0.937 standard + $0.285 Klein) — matches the
$1.2225 estimate.

Manifest: `tools/card_art/output/scale_100_v1/manifest.json`
Images: `tools/card_art/output/scale_100_v1/images/` (100 files)

## Every one of the 100 images was individually opened and visually inspected
(not judged from prompts/filenames/manifest/API success alone).

## Full 100-row QA table

| ID | Model | Category | Archetype | Stratum | Verdict | Q | Defect | Klein Drift |
|---|---|---|---|---|---|---|---|---|
| sports.tennis | Standard | sports | solo_action | common | PASS | 5 | - | - |
| sports.run_clubs | Standard | sports | solo_action | mid | PASS | 5 | - | - |
| sports.running | Standard | sports | solo_action | common | PASS | 5 | - | - |
| sports.table_tennis | Standard | sports | solo_action | common | FAIL | 5 | logo_text | - |
| sports.gym | Standard | wellness | fitness_training | common | PASS | 5 | - | - |
| wellness.foam_rolling | Standard | wellness | calm_wellness | mid | FAIL | 5 | text | - |
| wellness.bodybuilding | Standard | wellness | fitness_training | common | PASS | 5 | - | - |
| wellness.calisthenics | Standard | wellness | fitness_training | common | PASS | 5 | - | - |
| outdoors.cycling | Standard | outdoors | outdoor_motion | common | FAIL | 5 | text | - |
| outdoors.wildlife_watching | Standard | outdoors | nature_immersion | mid | PASS | 5 | - | - |
| outdoors.camping | Standard | outdoors | nature_immersion | common | PASS | 5 | - | - |
| outdoors.backpacking | Standard | outdoors | nature_immersion | common | FAIL | 4.5 | anatomy | - |
| outdoors.mountaineering | Standard | outdoors | nature_immersion | common | PASS | 5 | - | - |
| gaming.video | Standard | gaming | digital_play | common | FAIL | 4 | rights | - |
| gaming.lan_parties | Standard | gaming | digital_play | mid | FAIL | 5 | text | - |
| gaming.pc_gaming | Standard | gaming | digital_play | common | MINOR | 5 | text | - |
| gaming.console_gaming | Standard | gaming | digital_play | common | PASS | 5 | - | - |
| media.anime | Standard | entertainment | story_culture | common | MINOR | 4.5 | rights | - |
| entertainment.theatre_going | Standard | entertainment | story_culture | mid | FAIL | 5 | text | - |
| media.manga | Standard | entertainment | story_culture | common | FAIL | 3.5 | text_rights | - |
| music.pop | Standard | music | music_listening | common | PASS | 5 | - | - |
| music.composing | Standard | music | performance | mid | PASS | 5 | - | - |
| music.style.alternative_rock | Standard | music | music_listening | long | PASS | 5 | - | - |
| music.rock | Standard | music | music_listening | common | PASS | 5 | - | - |
| travel.general | Standard | travel | travel_vista | common | FAIL | 3 | text_recognition | - |
| travel.walking_tours | Standard | travel | travel_vista | mid | PASS | 5 | - | - |
| travel.destination_deep.tokyo_travel | Standard | travel | travel_vista | long | FAIL | 5 | text | - |
| travel.japan | Standard | travel | travel_vista | common | FAIL | 5 | text | - |
| food.cooking | Standard | food | food_hero | common | PASS | 5 | - | - |
| food.bread_baking | Standard | food | food_hero | mid | PASS | 5 | - | - |
| food.cuisine_deep.teochew_cuisine | Standard | food | food_hero | long | PASS | 5 | - | - |
| food.sichuan | Standard | food | food_hero | common | PASS | 5 | - | - |
| technology.gadgets | Standard | technology | tech_workspace | common | MINOR | 5 | text | - |
| technology.electronics | Standard | technology | tech_workspace | mid | FAIL | 4.5 | text | - |
| technology.generative_ai | Standard | technology | tech_workspace | common | FAIL | 5 | text | - |
| technology.machine_learning | Standard | technology | tech_workspace | common | FAIL | 5 | text | - |
| photography.street | Standard | arts | lens_perspective | common | PASS | 5 | - | - |
| arts.gratitude_journaling | Standard | arts | creative_studio | mid | FAIL | 5 | text | - |
| arts.drawing | Standard | arts | creative_studio | common | PASS | 5 | - | - |
| arts.portrait_photography | Standard | arts | lens_perspective | common | PASS | 5 | - | - |
| crafts.knitting | Standard | crafts | creative_studio | common | PASS | 5 | - | - |
| crafts.flower_arranging | Standard | crafts | creative_studio | mid | PASS | 5 | - | - |
| crafts.crochet | Standard | crafts | creative_studio | common | PASS | 5 | - | - |
| crafts.sewing | Standard | crafts | creative_studio | common | PASS | 5 | - | - |
| science.astronomy | Standard | science | learning_exploration | common | MINOR | 4.5 | object | - |
| science.botany | Standard | science | learning_exploration | mid | PASS | 5 | - | - |
| science.space | Standard | science | learning_exploration | common | PASS | 5 | - | - |
| science.physics | Standard | science | learning_exploration | common | FAIL | 5 | recognition | - |
| motorsport.cars | Standard | transport | journey_machine | common | PASS | 5 | - | - |
| transport.urban_mobility | Standard | transport | journey_machine | mid | FAIL | 4.5 | cardchrome | - |
| transport.classic_cars | Standard | transport | journey_machine | common | PASS | 5 | - | - |
| transport.sports_cars | Standard | transport | journey_machine | common | PASS | 5 | - | - |
| learning.languages | Standard | learning | learning_exploration | common | FAIL | 5 | text | - |
| learning.genealogy | Standard | learning | learning_exploration | mid | PASS | 5 | - | - |
| learning.book_genre.literary_fiction | Standard | learning | reading_world | long | FAIL | 4.5 | text | - |
| learning.fiction | Standard | learning | reading_world | common | FAIL | 4.5 | text | - |
| transport.modelrailways | Standard | collecting | collection_object_hero | common | PASS | 5 | - | - |
| collecting.cd_collecting | Standard | collecting | collection_object_hero | mid | FAIL | 4 | text | - |
| collecting.watches | Standard | collecting | collection_object_hero | common | MINOR | 5 | text | - |
| motorsport.rally | Standard | motorsport | journey_machine | common | FAIL | 4 | cardchrome_recognition | - |
| motorsport.drifting | Standard | motorsport | journey_machine | common | FAIL | 4.5 | cardchrome_recognition | - |
| lifestyle.online_communities | Standard | lifestyle | urban_discovery | common | FAIL | 4 | text | - |
| lifestyle.supper_clubs | Standard | lifestyle | urban_discovery | mid | FAIL | 4.5 | text | - |
| lifestyle.interior_design | Standard | lifestyle | home_lifestyle | common | PASS | 5 | - | - |
| lifestyle.home_decor | Standard | lifestyle | home_lifestyle | common | PASS | 5 | - | - |
| pets.cats | Standard | pets | companion_bond | common | PASS | 5 | - | - |
| pets.dog_walking | Standard | pets | companion_bond | mid | PASS | 5 | - | - |
| pets.birds | Standard | pets | companion_bond | common | PASS | 5 | - | - |
| pets.fish | Standard | pets | companion_bond | common | FAIL | 4 | anatomy | - |
| business.startups | Standard | business | professional_world | common | MINOR | 5 | recognition | - |
| business.coworking | Standard | business | professional_world | mid | FAIL | 4.5 | recognition | - |
| business.marketing | Standard | business | professional_world | common | FAIL | 4.5 | recognition | - |
| career.software_engineering | Standard | career | professional_world | common | MINOR | 4.5 | cardchrome | - |
| career.legal_profession | Standard | career | professional_world | mid | FAIL | 4 | text | - |
| career.journalism | Standard | career | professional_world | common | FAIL | 3 | text_cardchrome | - |
| sports.american_football | Klein | sports | solo_action | common | FAIL (SENTINEL) | 4 | text_logo | MATERIAL |
| food.yum_cha | Klein | food | food_exploration | mid | FAIL (SENTINEL) | 5 | text | MINOR |
| sports.football | Klein | sports | solo_action | common | FAIL | 4 | logo | MATERIAL |
| sports.basketball | Klein | sports | solo_action | common | FAIL | 4 | text_rights | MATERIAL |
| sports.volleyball | Klein | sports | solo_action | common | MINOR | 5 | text | MATERIAL |
| sports.baseball | Klein | sports | solo_action | common | PASS | 5 | - | MATERIAL |
| food.japanese | Klein | food | food_hero | common | FAIL | 5 | text | MINOR |
| food.food_markets | Klein | food | food_exploration | mid | FAIL | 5 | text | MINOR |
| food.cuisine_deep.korean_bbq | Klein | food | food_hero | long | FAIL | 5 | text | MINOR |
| food.chinese | Klein | food | food_hero | common | FAIL | 5 | text | MINOR |
| fashion.menswear | Klein | fashion | urban_discovery | common | PASS | 5 | - | MATERIAL |
| fashion.barbering | Klein | fashion | urban_discovery | mid | PASS | 5 | - | MINOR |
| fashion.womenswear | Klein | fashion | urban_discovery | common | MINOR | 4.5 | style | MATERIAL |
| fashion.vintage_fashion | Klein | fashion | urban_discovery | common | PASS | 5 | - | NONE |
| learning.greek_life | Klein | learning | campus_activity | common | PASS | 4.5 | - | MINOR |
| arts.content_creation | Klein | arts | creator_workflow | mid | PASS | 5 | - | MATERIAL |
| learning.student_government | Klein | learning | campus_activity | common | MINOR | 4.5 | recognition | MINOR |
| learning.dorm_life | Klein | learning | campus_activity | common | PASS | 5 | - | MINOR |
| gaming.tabletop_rpg | Klein | gaming | group_play | common | FAIL | 4 | text | MINOR |
| gaming.tabletop_style.abstract_strategy_games | Klein | gaming | group_play | long | PASS | 5 | - | MATERIAL |
| gaming.tabletop_style.area_control_games | Klein | gaming | group_play | long | PASS | 5 | - | MATERIAL |
| technology.javascript | Klein | technology | tech_workspace | common | FAIL | 5 | text | MATERIAL |
| learning.book_genre.booktube | Klein | learning | reading_world | long | FAIL | 4.5 | recognition | MINOR |
| lifestyle.digital_nomad_meetups | Klein | lifestyle | urban_discovery | mid | MINOR | 5 | recognition | MATERIAL |
| business.networking | Klein | business | professional_world | common | FAIL | 4.5 | recognition | MATERIAL |

## Overall metrics

| | Count | Rate |
|---|---|---|
| PASS | 47 | 47.0% |
| MINOR | 11 | 11.0% |
| FAIL | 42 | 42.0% |

## Standard FLUX (75 cards)

| | Count | Rate |
|---|---|---|
| PASS | 38 | 50.7% |
| MINOR | 7 | 9.3% |
| FAIL | 30 | 40.0% |

Defects: text 24, logo/trademark 4, anatomy/object 3, card-chrome 5, recognition 7.

## Klein (25 cards)

| | Count | Rate |
|---|---|---|
| PASS | 9 | 36.0% |
| MINOR | 4 | 16.0% |
| FAIL | 12 | 48.0% |

Defects: text 10, logo/trademark 3, anatomy/object 0, card-chrome 0, recognition 4.

**Klein underperformed standard FLUX in this batch** — lower PASS rate (36.0%
vs 50.7%) and higher FAIL rate (48.0% vs 40.0%). It does still show a
meaningfully cleaner profile on card-chrome (0 vs 5) and anatomy (0 vs 3), and
its remaining failures cluster almost entirely in two specific, identifiable
classes (see sentinels below) rather than spreading randomly — but "Klein is
the safe route" is not supported by this sample as a general rule.

### Klein style drift

| Drift | Count | Rate |
|---|---|---|
| NONE | 1 | 4.0% |
| MINOR | 11 | 44.0% |
| MATERIAL | 13 | 52.0% |

Over half of Klein's outputs drift materially toward photoreal/stock-photo or
glossy-3D rendering. This confirms and sharpens the smaller-sample finding
from the earlier A/B test — at 25 cards it's clearly the norm, not the
exception, for Klein.

## Rank stratum metrics

| Stratum | n | PASS | MINOR | FAIL | Fail rate |
|---|---|---|---|---|---|
| common (rank <=1200) | 68 | 32 | 10 | 26 | 38.2% |
| mid (1201-2500) | 24 | 11 | 1 | 12 | 50.0% |
| long (2501+) | 8 | 4 | 0 | 4 | 50.0% |

Quality does degrade somewhat as rank depth increases (common 38.2% -> mid/
long 50.0%), though the long-tail sample is small (n=8) and should not be
over-read.

## Category metrics (fail rate, sorted worst-first, n>=2)

| Category | n | Fail | Rate |
|---|---|---|---|
| motorsport | 2 | 2 | 100.0% |
| technology | 5 | 4 | 80.0% |
| travel | 4 | 3 | 75.0% |
| business | 4 | 3 | 75.0% |
| entertainment | 3 | 2 | 66.7% |
| career | 3 | 2 | 66.7% |
| food | 9 | 5 | 55.6% |
| learning | 8 | 4 | 50.0% |
| sports | 9 | 4 | 44.4% |
| gaming | 7 | 3 | 42.9% |
| outdoors | 5 | 2 | 40.0% |
| lifestyle | 5 | 2 | 40.0% |
| collecting | 3 | 1 | 33.3% |
| wellness | 4 | 1 | 25.0% |
| science | 4 | 1 | 25.0% |
| transport | 4 | 1 | 25.0% |
| pets | 4 | 1 | 25.0% |
| arts | 5 | 1 | 20.0% |
| music | 4 | 0 | 0.0% |
| crafts | 4 | 0 | 0.0% |
| fashion | 4 | 0 | 0.0% |

## Archetype metrics (fail rate, n>=2)

| Archetype | n | Fail | Rate |
|---|---|---|---|
| reading_world | 3 | 3 | 100.0% |
| food_exploration | 2 | 2 | 100.0% |
| professional_world | 7 | 5 | 71.4% |
| tech_workspace | 5 | 4 | 80.0% |
| travel_vista | 4 | 3 | 75.0% |
| story_culture | 3 | 2 | 66.7% |
| journey_machine | 6 | 3 | 50.0% |
| digital_play | 4 | 2 | 50.0% |
| food_hero | 7 | 3 | 42.9% |
| solo_action | 9 | 4 | 44.4% |
| learning_exploration | 6 | 2 | 33.3% |
| collection_object_hero | 3 | 1 | 33.3% |
| group_play | 3 | 1 | 33.3% |
| urban_discovery | 7 | 2 | 28.6% |
| nature_immersion | 4 | 1 | 25.0% |
| companion_bond | 4 | 1 | 25.0% |
| creative_studio | 6 | 1 | 16.7% |
| lens_perspective | 2 | 0 | 0.0% |
| fitness_training | 3 | 0 | 0.0% |
| music_listening | 3 | 0 | 0.0% |
| home_lifestyle | 2 | 0 | 0.0% |
| campus_activity | 3 | 0 | 0.0% |

Failures correlate strongly with **archetype**, not randomly with volume.
`reading_world`, `food_exploration`, `tech_workspace`, `professional_world`,
and `travel_vista` are the five worst — together they account for a large
share of all FAILs, while `fitness_training`, `music_listening`,
`home_lifestyle`, `campus_activity`, and `lens_perspective` were perfect or
near-perfect across every card tested.

## Sentinel verdicts

### `sports.american_football` (Klein) — **FAIL, sentinel not solved**

Checked: jersey numbers, sponsor/team logos, swoosh-like marks, branded
uniform cues, generic equipment correctness.

Result: a readable jersey number ("1") and a small swoosh-like mark on the
shoe are both still present, despite the real `negative_prompt` explicitly
listing "readable jersey names or numbers" and "team logos or mascots."
Routing this class to Klein did **not** fix the original failure. Confirmed
generalizable and worse: 3 additional team-sport cards were added as evidence
in this batch (`sports.football`, `sports.basketball`, `sports.volleyball`,
plus the clean `sports.baseball`) —
- `sports.football` (soccer): an unmistakable Nike swoosh rendered **twice**
  (chest and sleeve), plus a small crest and a jersey number.
- `sports.basketball`: jersey text reads "LAKBS"/"LAKOS" — visibly close to
  the real NBA team name "Lakers" — with a legible number "12".
- `sports.volleyball`: a faint, mostly-illegible jersey mark (MINOR, the
  mildest of the four).
- `sports.baseball`: fully clean (the only team-sport Klein card to pass).

**Conclusion: uniform/team-sport branding is not solved by Klein's
negative_prompt as currently written.** 3 of 4 new team-sport cards still
leaked real-world-adjacent branding; only baseball was clean. This needs a
different intervention (a stronger, sport-specific override, or accept the
residual risk is not eliminable by negative_prompt alone).

### `food.yum_cha` (Klein) — **FAIL, sentinel not solved**

Checked: Chinese signage, lantern/banner text, menu text, pseudo-readable
characters, restaurant-brand cues.

Result: a small round sign and a plaque in the background still carry
quasi-readable Chinese-style characters — smaller and less dominant than the
original failure (which had a large banner spanning the top of the frame),
but still present and still a defect against the hard criteria. **Confirmed
generalizable and severe**: 4 more ethnic-food/market Klein cards were tested
as evidence — `food.chinese`, `food.japanese`, `food.food_markets`,
`food.cuisine_deep.korean_bbq` — **all four also FAIL** on the identical
defect (readable/quasi-readable signage, lanterns, banners). This is a
**100% fail rate (5/5) for this defect class on Klein.**

**Conclusion: ethnic/signage-heavy food and market scenes are not solved by
Klein's negative_prompt.** This looks like a strong thematic prior in the
underlying model (real markets/restaurants "should" have signage) that a
negative_prompt list does not reliably override.

## Defect classification

- **Text/caption contamination (34 cards, by far the largest class):**
  spans both routes. Sub-patterns:
  - **Poster/title-card resurgence** (the prompt-format fix's target defect,
    reappearing via a *different* trigger than the one already fixed):
    `career.journalism` ("JOURNALISM" caption + ornate frame),
    `career.legal_profession` ("LEGAL PROFESSION" nameplate),
    `collecting.cd_collecting` ("COLLECTING" on a giant CD case),
    `lifestyle.online_communities` (fake webpage UI captioned "Online
    Communities"), `lifestyle.supper_clubs` (neon "SUPPER CLUBS" sign),
    `travel.destination_deep.tokyo_travel` ("TOKYO TRAVEL" caption),
    `travel.general` (severe gibberish poster block),
    `learning.languages` ("Language Learning" notebook title),
    `learning.fiction` / `learning.book_genre.literary_fiction` (repeated
    "FICTION"/genre-shelf signage), `arts.gratitude_journaling` (handwritten
    hobby-name title), `wellness.foam_rolling` ("Foral" brand-like text),
    `gaming.tabletop_rpg` (Klein, severe garbled bottom caption). **This
    confirms the prompt-format fix closed one specific trigger (raw
    compiler-id echo) but not the model's broader tendency to add
    poster/title treatment to certain scenes.**
  - **Ethnic/thematic signage** (the food/market sentinel class): see above,
    5/5 fail on Klein plus `travel.japan` and `media.manga`
    (Japanese signage/dialogue) on standard.
  - **On-screen code/UI text**: `technology.generative_ai`,
    `technology.machine_learning`, `technology.electronics` (standard) and
    `technology.javascript` (Klein) all render legible code — `tech_workspace`
    is a systemic offender regardless of route.
  - **Readable brand-like decal text on generic objects**:
    `outdoors.cycling` (bike frame), `sports.table_tennis` (shirt/table).
- **Logo/trademark/trade-dress (7 cards):** the sentinel failures above,
  plus `sports.table_tennis` (V-logo, swoosh), `gaming.video` (Mario-like
  character).
- **Rights/IP leakage (distinct from logos):** `gaming.video` (a
  Mario-like character is clearly recognizable on screen), `media.manga` and
  `media.anime` (character-ensemble designs that risk reading as specific
  existing franchises, flagged out of caution rather than confirmed).
- **Anatomy/object-logic failures (3 cards):** `outdoors.backpacking` (a lit
  tent floating in the middle of a lake), `pets.fish` (a rabbit and cat
  depicted living inside aquarium tanks).
- **Card-chrome/border leaks (5 cards):** `career.software_engineering`,
  `transport.urban_mobility`, `motorsport.rally`, `motorsport.drifting`
  (all standard) show a residual white/brown border or letterbox bars framing
  the image — a smaller, milder cousin of the poster-frame defect above.
- **Recognition failures (11 cards):** `business.coworking`,
  `business.marketing`, `business.networking` (the `professional_world`
  archetype consistently substitutes an unrelated "workshop/prototyping"
  scene that doesn't specifically read as the named office/desk profession),
  `science.physics` (reads as entomology/biology fieldwork, not physics),
  `motorsport.rally`/`motorsport.drifting` (both render generic go-kart pit
  scenes instead of the named motorsport discipline),
  `learning.book_genre.booktube` and `lifestyle.digital_nomad_meetups`
  (generic reading/meetup scenes missing the specific recording/remote-work
  cue that would identify the niche).
- **Style-only (no contamination) failure:** `fashion.womenswear` (Klein,
  MATERIAL drift with no other defect).

**Systemic vs isolated:** the text/caption, tech-screen, ethnic-signage, and
`professional_world` recognition failures are systemic (tied to specific
archetypes, reproducing across multiple unrelated hobbies). The anatomy
failures (floating tent, aquarium pets) look isolated/model-noise rather than
systemic to their archetype (`nature_immersion` and `companion_bond`
otherwise passed cleanly).

## Smallest justified retry set (not executed this task)

Do not reroll all 42 FAILs. Priority order, smallest first:

1. **`professional_world` archetype (7 cards, 5 FAIL):** the derived
   `subject_template` for abstract office/desk hobbies (coworking,
   marketing, networking, journalism, legal_profession) needs concrete,
   hobby-specific subject text instead of the generic "concrete business
   task" fallback that keeps producing an unrelated jewelry/workshop scene.
   This is a content fix in `catalog_recipe_defaults_v1.json`'s
   `business`/`career` category defaults, not a routing fix.
2. **`tech_workspace` archetype (5 cards, 4 FAIL, both routes):** needs an
   explicit "no readable code, no legible UI text" constraint at the
   archetype or category level (the same fix already applied to
   `technology.ai`'s hobby-level override should be generalized to the
   whole archetype, since it recurs across unrelated `technology.*` hobbies).
3. **Ethnic/signage food-market class (5 Klein cards, 5/5 FAIL):** stop
   routing this class to Klein as-is; either accept the residual signage
   risk as a known limitation, or test a structurally different fix (e.g.
   explicit "blank unlettered lanterns/signage" language plus a stronger
   negative_prompt weight) on a small 3-4 card sample before any further
   scale.
4. **Uniform/team-sport class (4 Klein cards, 3/4 FAIL):** same treatment as
   #3 — the current negative_prompt approach is not sufficient for
   real-world sports branding; test a sport-specific override on a small
   sample first.
5. **`reading_world`/`travel_vista` poster-caption resurgence (5 cards):**
   likely needs the same override pattern already proven for
   `technology.ai`/`fashion.streetwear`/`lifestyle.game_nights` — explicit
   "no title, no caption, no shelf signage" language — applied per-hobby to
   these five.

Everything else (anatomy/object noise, card-chrome borders, minor style
notes) is lower priority and can wait for a later general-quality pass.

## Answers to the seven decision questions

1. **Is standard reference-free FLUX reliable enough after the compiler
   fix?** **No.** 40.0% FAIL on a 75-card sample is not reliable for
   unsupervised catalog-scale generation. The compiler fix demonstrably
   worked (no more raw-id/VISUAL-VARIANT leaks anywhere in this batch), but
   a second, distinct poster/title-caption tendency and thematic-signage
   tendency remain, both archetype-correlated rather than randomly
   distributed.
2. **Is Klein + negative_prompt reliable enough for suppression-sensitive
   cards?** **No — and it underperformed standard FLUX overall in this
   batch** (36.0% PASS vs 50.7% PASS). It is not a general-purpose fix for
   "hard" cards; its failures concentrate almost entirely in the two
   sentinel classes it was specifically meant to solve, which it did not.
3. **Does Klein's style drift remain acceptable at collection level?**
   **No.** 52% MATERIAL drift confirms this is the norm for Klein output at
   scale, not an occasional issue.
4. **Did the batch discover any NEW card classes that should route from
   standard FLUX to Klein?** No strong new candidates — the categories with
   the worst standard-FLUX fail rates (`technology`, `professional_world`,
   `travel_vista`, `reading_world`) are failing on defects (on-screen code,
   recognition mismatch, poster captions) that Klein's tested behavior does
   not actually fix better; several of these defects appear on Klein too.
5. **Are any existing Klein classes unnecessarily defensive and safe on
   standard FLUX?** `fashion.*` (4/4 PASS/MINOR on Klein) and
   `learning.*campus_activity*` (3/3 PASS/MINOR) look like they could
   plausibly be tested on standard FLUX instead, since Klein isn't adding
   obvious value there and does add style-drift risk — worth a small
   comparison test, not an immediate re-route.
6. **Is the prompt/archetype system producing recognizable art across the
   full route spread?** **Mostly yes, with real exceptions.** Only 11/100
   cards had a genuine recognition defect, and most of those cluster in the
   two identified problem archetypes (`professional_world`, plus
   `science.physics`/motorsport-class mismatches) rather than being spread
   evenly — the core prompt/archetype system is sound, but a handful of
   specific templates need content fixes.
7. **Are we ready to increase generation scale?** **No.**

## Recommended next generation scale

**Do not run another 100, 200, or 300-card batch yet.** Recommended next
step is the smallest-retry-set remediation above (targeted content fixes to
`professional_world` and `tech_workspace` archetype templates, a small
diagnostic test on the ethnic-food and uniform-sports classes) followed by a
**small, targeted re-validation** (roughly 15-20 cards covering just the
fixed archetypes/classes, similar in spirit to the earlier 8-card
prompt-format validation) before considering any further scale-up. Only once
those specific, now-identified failure classes show a clean re-test should a
larger batch (100+) be considered again.

## Infrastructure

Vercel deployment confirmed disabled for this branch (unchanged). No GitHub
Actions workflow triggers on push to this branch. This commit/push is a
plain repo write with no CI/deployment side effects. Play/Production remain
untouched and closed. `FAL_KEY` was not committed or exposed.

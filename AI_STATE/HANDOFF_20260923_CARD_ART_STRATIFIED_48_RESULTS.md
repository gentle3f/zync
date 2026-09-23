# Zync — 48-Card Stratified Validation: Results

Date: 2026-09-23
Branch: `card-art-pilot-v1-20260921`

Read `AI_STATE/OPERATING_RULES.md` before any write or external action.

## What ran

```bash
cd tools/card_art
npm run audit-stratified-v1     # zero-credit preflight
npm run generate-stratified-v1  # actual generation
```

- **Audit:** passed — 48/48 compiled, standard 32 ($0.400 est.), Klein 16
  ($0.182 est.), total $0.5824 est. No blocked/unknown IDs, no compilation
  failures, zero `REFERENCE STYLE:` leaks, zero "Zync" mentions anywhere in
  the 48 compiled prompts.
- **Generation:** **48/48 API calls succeeded**, no request-level failures.
  **Actual cost: $0.582** (32 x $0.0125 + 16 x $0.0114), matching the
  estimate.
- Manifest: `tools/card_art/output/stratified_v1/manifest.json`
- Images: `tools/card_art/output/stratified_v1/images/` (48 files, named
  `<canonical_id_with_double_underscores>__<model>__attempt1.png`)
- All 48 images were opened and visually inspected individually (not judged
  from API success/manifest/prompts alone).

## Headline finding: this is not primarily a route-allocation problem

The batch surfaces a **structural root cause** that affects both routes, not
just "which archetypes need Klein":

**The compiled prompt's own section headers get echoed back as literal
captions.** `buildPromptV1.js` formats sections like
`VISUAL VARIANT (heat_room): ...` and `ARCHETYPE (group_play): ...` — the
parenthetical short identifier immediately following a label reads, to the
model, like a title/subtitle pattern. Direct evidence:

- `wellness.sauna` (standard) rendered a caption reading **"HEAT ROOM"**,
  which is the literal `visual_variant` id (`heat_room`) from the prompt,
  title-cased.
- `wellness.hot_springs` (standard) rendered captions **"HOT SPRINGS™"** and
  **"IMMERSION_RITUAL"** — the second is the literal `visual_variant` id
  (`immersion_ritual`) with its underscore preserved, verbatim.
- `wellness.sauna` also rendered **"LISUAT VARIANT"** near the top — a
  garbled echo of the literal string **"VISUAL VARIANT"** from the section
  header itself.

This is the same failure family diagnosed earlier for `lifestyle.game_nights`
("GAME NIGHT" caption) and `learning.book_genre.booktok`
("BeokToyk"/"BookTok"-adjacent caption on Klein, this batch) — it is not
archetype-specific, model-specific, or fixed by routing alone. It is a
prompt-format defect: any interest whose archetype/category/visual-variant
naming reads as poster-worthy language is at risk on **either** route.

## Overall 48-card result

| | Count | Rate |
|---|---|---|
| PASS | 24 | 50.0% |
| MINOR | 6 | 12.5% |
| FAIL | 18 | 37.5% |

## Standard FLUX (`flux-2`, no negative_prompt) — 32 cards

| | Count | Rate |
|---|---|---|
| PASS | 14 | 43.8% |
| MINOR | 5 | 15.6% |
| FAIL | 13 | 40.6% |

Defect counts (a card can have more than one):
- Text/gibberish/caption contamination: **12/32** (37.5%) — the dominant defect
- Logo/trademark: 2/32
- Recognition failures: 0/32 (every card was identifiable; failures are
  contamination, not unrecognizability)
- Anatomy/key-object integrity: 3/32
- Composition/collage/card-chrome (borders, poster-frame layouts): 7/32

## Klein 9B Base + negative_prompt — 16 cards

| | Count | Rate |
|---|---|---|
| PASS | 10 | 62.5% |
| MINOR | 1 | 6.3% |
| FAIL | 5 | 31.3% |

Defect counts:
- Text/gibberish/caption contamination: **5/16** (31.3%)
- Logo/trademark: 0/16 (clean — `fashion.streetwear` held up)
- Recognition failures: 0/16
- Anatomy/key-object integrity: 0/16
- Composition/collage/card-chrome: 2/16

### Klein style-drift audit (explicit ask)

| Drift | Count |
|---|---|
| NONE | 3 |
| MINOR | 5 |
| MATERIAL | 8 |

8 of 16 Klein images (50%) read as photoreal/stock-photo or glossy 3D-render
rather than the painterly collectible-illustration house style — a real,
frequent effect, not an occasional one. `fashion.streetwear` and
`transport.travel.style_deep.unesco_heritage_travel` were the strongest
style matches; most people-at-a-desk/screen scenes (video editing, animation,
blogging, streaming, book swaps) drifted toward photoreal.

## Full 48-row QA table

Legend: V=verdict, Q=quality 1-5, drift=Klein style drift (std cards: n/a)

| # | ID | Route | V | Q | Diagnosis | Defect class |
|---|---|---|---|---|---|---|
| 1 | sports.american_football | std | FAIL | 4 | Readable jersey number "7" + swoosh-like logo mark on shorts | text/logo |
| 2 | sports.hiking | std | PASS | 5 | Clean, recognizable coastal trail hike | - |
| 3 | transport.car_meets | std | PASS | 5 | Clean, multiple distinct cars, blank plates | - |
| 4 | sports.badminton | std | MINOR | 4.5 | Small ambiguous checkmark-like icon on shirt chest | logo (minor) |
| 5 | gaming.chess | std | PASS | 5 | Clean two-player match, illegible scorecards | - |
| 6 | wellness.weightlifting | std | FAIL | 3.5 | Illogical composition: lifter appears to straddle an elliptical machine while squatting a barbell | composition/anatomy |
| 7 | wellness.yoga | std | MINOR | 4.5 | Clean but strongly photoreal rendering, violates "no photoreal" global negative | style |
| 8 | outdoors.surfing | std | PASS | 5 | Clean, dynamic wave action | - |
| 9 | outdoors.kayaking | std | PASS | 5 | Clean, painterly river scene | - |
| 10 | sports.gravel_cycling | std | FAIL | 4.5 | Readable word "GRAVEL" printed on bike down tube | text |
| 11 | lifestyle.gardening | std | PASS | 5 | Clean indoor potting scene | - |
| 12 | food.yum_cha | std | FAIL | 5 | Beautiful scene, but background signage/lanterns carry multiple readable/quasi-readable Chinese characters | text |
| 13 | arts.lion_dance | std | MINOR | 4 | Performer holds a guitar/pipa-like object instead of a clear lion-dance pole grip; slightly confusing prop | composition/object |
| 14 | career.nursing | std | PASS | 4.5 | Clean, illegible wall chart, recognizable ward scene | - |
| 15 | pets.dog_agility | std | PASS | 5 | Clean, dog mid-hurdle, handler cue | - |
| 16 | learning.archaeology | std | MINOR | 4.5 | Recognizable dig/study scene, but binoculars used indoors is a small logic quirk | composition |
| 17 | books.reading | std | PASS | 5 | Clean library scene, illegible book text | - |
| 18 | history.general | std | MINOR | 4.5 | Small diegetic open-book text partially reads "History" | text (minor) |
| 19 | learning.philosophy | std | FAIL | 2 | Full poster/card mockup: white card frame, bold "PHILOSOPHY" title, gibberish body caption | text/card-chrome (severe) |
| 20 | wellness.mindfulness | std | PASS | 5 | Clean, calm meditation pose | - |
| 21 | collecting.stamps | std | FAIL | 2 | Giant foreground stamp graphic bearing readable/gibberish text "COLLECTING"/"STAMDERT" and numbers | text (severe) |
| 22 | transport.railways | std | FAIL | 2.5 | Gorgeous train illustration ruined by a vintage-poster title block: "JHOUR POIST / Railwajs & Trains" | text/card-chrome (severe) |
| 23 | learning.math_olympiad | std | FAIL | 2 | Full poster mockup: banner title, badge/logo icon, gibberish body copy | text/card-chrome (severe) |
| 24 | learning.study_abroad | std | FAIL | 2.5 | Card-framed poster with garbled top caption "Exchange_Anroad" and legible bottom caption "Study Abroad" | text/card-chrome (severe) |
| 25 | wellness.hot_springs | std | FAIL | 2 | Poster frame, "HOT SPRINGS™" title, "IMMERSION_RITUAL" caption (literal visual_variant id leak) | text/card-chrome (severe) |
| 26 | wellness.sauna | std | FAIL | 2 | Poster frame, "LISUAT VARIANT" + "HEAT ROOM" (literal visual_variant id leak) + gibberish code caption | text/card-chrome (severe) |
| 27 | lifestyle.repair_workshops | std | FAIL | 4 | No text, but a rounded white card-border frame is baked into the image | card-chrome |
| 28 | arts.podcasting | std | PASS | 5 | Clean, abstract waveform UI, no legible text | - |
| 29 | gaming.escape_room_design | std | FAIL | 3.5 | Great scene, but a prop puzzle box has bold readable text "ESCAPE ROOM DESIGN" | text |
| 30 | food.coffee | std | PASS | 5 | Clean café/latte-art scene | - |
| 31 | travel.roadtrip | std | PASS | 5 | Clean coastal road scene, blank plate | - |
| 32 | photography.general | std | PASS | 5 | Clean, camera LCD shows only an image preview | - |
| 33 | lifestyle.game_nights | klein | PASS | 4 | Clean, no caption this time; drift MATERIAL (stock-photo look) | style drift MATERIAL |
| 34 | motorsport.sim_racing | klein | MINOR | 4 | Clean rig, but TV in-game HUD shows tiny legible numbers/labels; drift MATERIAL | text (minor) |
| 35 | fashion.streetwear | klein | PASS | 5 | Clean, fully generic sneakers, no swoosh; drift NONE | - |
| 36 | learning.model_united_nations | klein | PASS | 5 | Clean, large assembly scene, illegible nameplates; drift MINOR | - |
| 37 | learning.campus_radio | klein | PASS | 4.5 | Clean, abstract mixer/waveform UI; drift MINOR | - |
| 38 | business.case_competitions | klein | FAIL | 4 | Trophy plaque has readable engraved text "CASE COMPETITIONS"; drift MINOR | text |
| 39 | business.founder_meetups | klein | PASS | 5 | Clean casual meetup scene; drift NONE | - |
| 40 | lifestyle.book_swaps | klein | PASS | 4.5 | Clean, illegible book spines; drift MATERIAL (glossy 3D-render look) | style drift MATERIAL |
| 41 | arts.video_editing | klein | PASS | 5 | Clean, abstract timeline/color-grade UI; drift MATERIAL | style drift MATERIAL |
| 42 | arts.vlogging | klein | FAIL | 4 | No text, but a thin white photo-margin border is baked into the image; drift MINOR | card-chrome |
| 43 | arts.animation_production | klein | PASS | 5 | Clean storyboard sketches, no legible words; drift MATERIAL | style drift MATERIAL |
| 44 | arts.blogging | klein | PASS | 5 | Clean, illegible scribble-text notebook; drift MINOR/MATERIAL | - |
| 45 | gaming.game_streaming | klein | PASS | 5 | Clean, illegible HUD/timeline; drift MATERIAL | style drift MATERIAL |
| 46 | technology.python | klein | FAIL | 4 | Clean composition, but both monitors show legible Python-like code text | text |
| 47 | learning.book_genre.booktok | klein | FAIL | 3 | Photo-frame border + garbled book-cover title + bold garbled caption "BeokToyk"; drift MATERIAL | text/card-chrome (severe) |
| 48 | travel.style_deep.unesco_heritage_travel | klein | FAIL | 4 | Beautiful scene, garbled caption "GLOAL / UEILCO HERITAGT TRAVEL"; drift NONE | text |

## Defect classification (for the recommended retry)

- **Prompt-format caption leak (root cause, affects both routes):**
  `learning.philosophy`, `collecting.stamps`, `transport.railways`,
  `learning.math_olympiad`, `learning.study_abroad`, `wellness.hot_springs`,
  `wellness.sauna`, `learning.book_genre.booktok`,
  `travel.style_deep.unesco_heritage_travel`, `lifestyle.game_nights`'s prior
  failure (now fixed on Klein) — **9 of the 18 FAILs are this one class.**
- **Standard-FLUX suppression failure (would likely pass on Klein):**
  `sports.gravel_cycling`, `food.yum_cha`, `gaming.escape_room_design`,
  `sports.american_football` — ordinary text/logo leaks with no negative_prompt
  to suppress them.
- **Klein suppression failure (negative_prompt present but not fully
  effective):** `business.case_competitions`, `technology.python`,
  `motorsport.sim_racing` (minor) — Klein's negative list didn't anticipate
  "engraved trophy text" or "on-screen code," a coverage gap, not a mechanism
  failure.
- **Card-chrome/border leak (neither text nor logo):**
  `lifestyle.repair_workshops` (standard), `arts.vlogging` (Klein),
  `learning.book_genre.booktok` (Klein, combined with text).
- **Anatomy/object/composition-logic failure:** `wellness.weightlifting`
  (illogical equipment merge), `arts.lion_dance` (ambiguous prop),
  `learning.archaeology` (minor indoor-binoculars logic quirk).
- **Style-only (no contamination) failure:** `wellness.yoga` (photoreal
  rendering violates the explicit "no photoreal" global negative even though
  nothing else is wrong).
- **Rights/trademark:** none this batch reached a clear real-brand match
  (the closest, `sports.american_football`'s logo mark, is ambiguous but
  flagged out of caution).
- **Recognition failure:** none — every one of the 48 images was identifiable
  as its intended hobby; all failures are contamination or logic defects, not
  "can't tell what this is."

## Smallest justified retry set (not executed this task)

Do not reroll all 18 failed cards. The evidence points to two independent,
narrow fixes:

1. **Fix the prompt-format root cause first** (in `buildPromptV1.js` or the
   compiled-prompt assembly): stop presenting `LABEL (identifier):` as a
   leading pattern the model can read as a title/subtitle — e.g. rephrase
   section headers as full sentences instead of `ALL CAPS (id):`, or move the
   raw variant/archetype id strings out of the prompt text entirely (they are
   already recorded structurally in the manifest and don't need to appear as
   prompt words). This single fix is the highest-leverage action available —
   it plausibly resolves 9 of 18 failures across both routes at once.
2. **Re-validate on a small, targeted sample after that fix**, not a blind
   full reroll: the 4 caption-format cases with the clearest signal
   (`wellness.sauna`, `wellness.hot_springs`, `learning.philosophy`,
   `learning.book_genre.booktok`) plus the 4 plain suppression failures on
   standard FLUX (`sports.gravel_cycling`, `food.yum_cha`,
   `gaming.escape_room_design`, `sports.american_football`) — 8 cards, ~$0.10.
3. **Separately, add narrow negative_prompt coverage** for Klein's two gaps
   (engraved/physical-object text, on-screen code) rather than assuming Klein
   is "done."
4. Leave `wellness.weightlifting`, `arts.lion_dance`, `learning.archaeology`
   (composition/logic issues) and `wellness.yoga` (style-only) for a second,
   lower-priority pass — they are not text/rights failures and don't block
   the format fix from being validated.

## Answers to the seven decision questions

1. **Is standard reference-free FLUX reliable enough for ordinary catalog
   cards?** **Not yet.** 40.6% FAIL, dominated by a prompt-format defect that
   is fixable, but as shipped today standard FLUX is not safe for
   unsupervised catalog-scale generation.
2. **Is Klein + negative_prompt reliable enough for suppression-sensitive
   cards?** **Better, but also not yet.** 62.5% PASS / 31.3% FAIL is real
   improvement over standard FLUX, but the same root-cause defect still hits
   Klein 3 of its 5 failures, and Klein's negative list has real coverage
   gaps (engraved text, on-screen code).
3. **Does Klein's style drift remain acceptable at collection level?**
   **No, not as currently prompted.** 50% of Klein outputs (8/16) show
   MATERIAL style drift toward photoreal/stock-photo or glossy 3D-render.
   Shipped at scale, a Klein-heavy batch would look visually inconsistent
   next to standard-FLUX cards.
4. **Did the batch discover any NEW card classes that should route from
   standard FLUX to Klein?** Yes, tentatively: `sports.american_football`,
   `sports.gravel_cycling`, `food.yum_cha`, `gaming.escape_room_design` all
   failed on standard FLUX for reasons a negative_prompt should directly
   address (specific unwanted text/logo). But given the root-cause fix in (1)
   may resolve several of these independent of routing, re-test after that
   fix before permanently reassigning routes.
5. **Are any existing Klein classes unnecessarily defensive and safe on
   standard FLUX?** Based on this batch, no — every Klein-routed hobby that
   passed did so because of active contamination pressure elsewhere in the
   same archetype family (group scenes, creator/screen scenes), so the
   current suppression-sensitive list looks reasonably justified, not
   overcautious.
6. **Is the prompt/archetype system producing recognizable art across the
   full route spread?** **Yes, unambiguously.** 0 recognition failures out of
   48. Every hobby was identifiable at a glance regardless of route or
   verdict. The system's weakness is contamination and style consistency, not
   subject/archetype clarity.
7. **Are we ready to increase generation scale?** **No — not before the
   prompt-format root-cause fix is applied and re-validated.** Scaling now
   would propagate a known, addressable defect across hundreds of cards.

## Recommended next generation scale

**Do not scale up yet.** The recommended next step is the smallest retry set
above (8 cards, ~$0.10) to confirm the prompt-format fix actually resolves
the caption-leak defect class, run as its own small validation — not a batch
size increase. Once that is confirmed:

- A sensible next chunk size would be **~100 cards**, not 200+: large enough
  to sample many more archetype/category/visual-variant combinations (this
  batch only covered 48 of several dozen visual-variant ids, and the
  caption-leak defect is variant-id-dependent, so broader variant coverage is
  needed to be confident the fix generalizes) but still small enough to
  review every image by hand and keep cost near $1-2, consistent with the
  validation-first approach used throughout this effort. 200+ should wait for
  a clean pass at the 100-card stage.

## Infrastructure

Vercel deployment confirmed disabled for this branch (unchanged). No GitHub
Actions workflow triggers on push to this branch. This commit/push is a
plain repo write with no CI/deployment side effects. Play/Production remain
untouched and closed. `FAL_KEY` was not committed or exposed. No hobby
prompts, overrides, or application code were modified in this task — this
is a validation-only checkpoint.

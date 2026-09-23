# Zync — BULK-FIRST 100 Validation: Results

Date: 2026-09-23
Branch: `card-art-pilot-v1-20260921`
Parent HEAD: `998ec0962920aebdc87d535a19e18d3ac6b44cb9`

Read `AI_STATE/OPERATING_RULES.md` before any write or external action.

## Bottom line

**The BULK-FIRST classification does not hold up under direct generation
testing. 72/100 cards FAILED, 14 were MINOR, only 14 fully PASSED — a 72%
failure rate.** This is not a set of isolated one-card failures; it
clusters across nearly every archetype in the BULK-FIRST set, including
several archetypes previously believed safe from earlier remediation work
(`solo_action`'s brand-safe sports, `shared_workspace`/coworking). Per the
task's own decision rule, this clears the escalation bar decisively: it is
a systemic, catalog-wide problem, not noise. **Do not proceed to the
1731-card bulk run.** The BULK-FIRST/HOLDOUT split needs to be
substantially rebuilt before any further bulk generation is attempted.

## What ran

```bash
cd tools/card_art
node src/runBulkFirst100Validation.js --dry-run
node src/runBulkFirst100Validation.js
```

- **Audit:** clean. 100/100 compiled, `outdoors.ice_fishing` confirmed
  correctly resolving to `water_outdoors / water_ritual` (the routing fix
  from the prior checkpoint works — no crash, no error). No quarantined
  IDs present, no forbidden headers, no raw ID leaks.
- **Generation:** 100/100 API calls succeeded, no failures, no
  auto-rerolls. **Actual cost: $1.25** — matches estimate exactly.

Manifest: `tools/card_art/output/bulk_first_100_validation_v1/manifest.json`
Images: `tools/card_art/output/bulk_first_100_validation_v1/images/`

All 100 images were individually opened and visually inspected — not
judged from prompt text, manifest, or API success alone.

## Overall tally

| Verdict | Count |
|---|---|
| PASS | 14 |
| MINOR | 14 |
| **FAIL** | **72** |

## Root cause: generic "derived" recipes lack content anchors

The compiled prompt text for failing cards is **not wrong** — it
correctly names the specific hobby (e.g. "A person actively creating or
practicing Comedy Writing," "A visually appetising, unmistakable Tea
Ceremony moment"). This was verified directly against the dry-run output
for multiple failing cards. The problem is that ~25 of the 32 BULK-FIRST
archetypes rely on **generic, archetype-level composition templates**
that only interpolate `${title}` into broad sentences, with no concrete
per-hobby object/prop/setting description. This is architecturally
different from the small set of archetypes that were hand-engineered
during the remediation arc (`aviation_world`, `campaign_planning`,
`legal_practice`, `shared_workspace`, and the screen-policy work on
`tech_workspace`/`creator_workflow`/`digital_play`), which carry detailed,
specific composition text baked into the archetype/variant itself and
which **do** perform reliably.

Without that anchor, the model defaults heavily to one of several strong
priors instead of the intended hobby:
1. A generic "person examining/holding a camera, gadget, or electronic
   device" scene — the single most common failure mode, appearing across
   nearly every affected archetype.
2. The correct general domain but the wrong specific instance (e.g. a
   generic pasta dish instead of yum cha's dim sum; skiing instead of
   cycling/snowmobiling; a generic camping scene for hiking, rockhounding,
   *and* RV life — three different hobbies producing near-identical
   output).
3. A video-game controller intruding into physical board/tabletop game
   scenes.
4. A readable code/IDE/terminal screen appearing on a monitor/tablet/
   laptop that the compiled prompt never asked for.

Notably, this is the *same* underlying "screen/gadget" prior already
characterized at length during the Robotics/PC Gaming/screen-remediation
work earlier in this arc — but that work only ever tested it inside
tech/gaming-flavored archetypes. This validation shows the prior is not
confined to tech/gaming at all; it resurfaces in cooking, pet ownership,
wellness, nature, travel, music, reading, and performance archetypes with
equal or greater severity whenever the composition template is generic.

## Defect categories (with counts, not exhaustive per-card detail)

### 1. Wrong/unrelated hobby content — the dominant failure, ~50+ cards
Archetypes hit hardest: `companion_bond` (3/3 — showed wildlife/forest
photography instead of pets), `calm_wellness` (3/3 — showed an unrelated
craft/gadget scene and gamepad-holding hands instead of pilates/self-care/
mindful walking), `learning_exploration` (4/4), `journey_machine` (3/3 —
all three showed a generic sci-fi off-road buggy instead of a motorsport
car, a ferry, or a restored classic car), `home_lifestyle` (3/3),
`nature_immersion` (3/3 — three different hobbies produced near-identical
camping-by-a-fire scenes), `outdoor_motion` (2/2 — both showed skiing),
`lens_perspective` (2/2 — both showed binoculars instead of a camera),
`strategy_table` (2/2), most of `story_culture`, most of `urban_discovery`,
several `food_hero` dish-specific cards (egg tart, bun cha, feijoada,
yum cha all showed the wrong dish).

### 2. Screen/code/UI leakage — ~20+ cards
Recurs across `creative_studio`, `drink_ritual`, `music_listening` (4 of 7
sampled cards), `learning_exploration`, `journey_machine`, `story_culture`,
`travel_vista`, and notably **`business.coworking`** — an archetype
previously confirmed clean multiple times in earlier remediation rounds —
which this round showed *multiple* monitors with readable code.

### 3. Readable text/pseudo-brand signage leakage — new finding
`urban_discovery`: 3 of 4 cards showed actual readable storefront
signage/neon text (`fashion.streetwear`, `fashion.fragrance`,
`lifestyle.photo_booths`). `outdoors.bass_fishing` showed readable
pseudo-brand text on a paddleboard. This defect class was not prominently
seen in earlier, smaller validation rounds.

### 4. Video-game controller intrusion into physical game scenes
`group_play` and `strategy_table`: board/tabletop game scenes (chess,
negotiation games, general board games) repeatedly showed console-style
controllers in players' hands alongside or instead of tabletop pieces.

### 5. Card-border/chrome recurrence — materially more frequent than known
At least **5 occurrences in this 100-card sample alone**
(`wellness.pilates`, `business.founder_meetups`, `business.coworking`,
`entertainment.screenwriting`, `outdoors.rock_climbing`) — a ~5% rate.
The existing chrome-defect audit
(`AI_STATE/CARD_ART_CHROME_DEFECT_AUDIT_20260923.md`) characterized this
as "sparse, stochastic, 2 confirmed observations project-wide." That
characterization needs revision: **this defect is materially more common
than previously understood** and should be treated as a live, ongoing
risk factor for any bulk run, not background noise.

### 6. Content-safety/appropriateness risk — new finding, flagged separately
`wellness.sauna` and `wellness.hot_springs` (`wellness_experience`
archetype) both rendered a person in a bathtub/hot-tub setting with bare
shoulders/implied undress; `wellness.hot_springs` specifically reads as
implying nudity. This is a different and more serious category of risk
than recognizability or IP — a content-appropriateness/rights concern for
a general-audience app — and was not previously flagged anywhere in this
remediation arc. This needs dedicated attention before any bath/spa/sauna-
adjacent hobby is generated again, independent of the other findings here.

### 7. Regression in previously-confirmed-safe routes
`sports.archery`, `sports.fencing`, and `sports.badminton`
(`solo_action`) — the exact brand-safe-rule-fixed cluster confirmed
working in the post-confirmatory-repair round — all failed this time,
showing camera/gimbal equipment instead of their sport, with no bow, mask,
or racket in evidence. `business.coworking` (`shared_workspace`) also
regressed (see #2). This indicates real run-to-run stochastic variance
even in archetypes with detailed, hand-engineered composition text — a
single earlier PASS is not sufficient evidence of durable reliability.

### 8. Anatomy distortion — isolated
`learning.book_genre.programming_books`: visible facial distortion, an
uncanny/deformed look. One observed instance; not enough to characterize
as systemic on its own, but noted.

## Confirmed still-safe (small footprint)

- `legal_practice` (3/3: mock_trial, moot_court, legal_profession) — PASS,
  fully consistent with prior rounds.
- `campaign_planning` (2/2: marketing, digital_marketing) — PASS.
- `aviation_world` (1/1) — PASS.
- `travel_vista`'s style-based (non-destination) cards were mixed but not
  catastrophic (general PASS, unesco_heritage MINOR, 2 others FAIL).
- A handful of individual cards elsewhere passed on their own merits
  (`sports.gym`, `food.japanese`, `lifestyle.game_nights`,
  `learning.book_genre.litrpg`, `music.pop`, `music.style.math_rock`,
  `learning.book_genre.booktube`) without a clear pattern tying them
  together beyond "generic template happened to land well this time" —
  which, given the regression finding above (#7), should not be read as a
  durable guarantee.

## `outdoors.ice_fishing` — the specific repair validation

The **routing fix is confirmed working**: the card compiled and generated
without error, correctly using `water_outdoors / water_ritual`. However,
**the generated content itself failed** — it shows a person paddleboarding
on open water, not ice fishing (no ice, no fishing rod in use, no winter
context). This is a content-quality failure of the same generic-template
class described above, entirely separate from the data-integrity bug that
was fixed. The technical fix should not be read as validating the card's
visual output.

## Decision

Per instruction, **isolated failures are not escalated** — but this result
is not isolated. It clusters across the overwhelming majority of BULK-FIRST
archetypes. This is classified as a **systemic prompt/content-architecture
problem**: the BULK-FIRST split was built on evidence from a small number
of heavily-remediated archetypes and did not anticipate that the much
larger population of generic-template archetypes would fail at this rate
when actually generated.

**Recommendation: do not start the 1731-card bulk run.** The current
BULK-FIRST/HOLDOUT split (`tools/card_art/catalog/bulk_first_v1.json`,
`manual_image25_holdout_v1.json`) should be treated as superseded pending
a substantial rework, not as a ready production queue.

## Recommended next steps (not executed this task)

1. **Do not treat any archetype as bulk-safe based on a single passing
   sample.** The regression in `solo_action` and `shared_workspace` shows
   even previously-"confirmed" archetypes need either repeated sampling or
   a durable structural fix, not a one-time pass.
2. **Prioritize adding per-hobby or per-cluster content anchors** (in the
   style of the archery/fencing brand-safe rule, or the aviation/campaign_
   planning archetype rewrites) to the highest-volume failing archetypes
   first: `food_hero` (255 IDs, dish-specific mismatches), `music_listening`
   (272 IDs, code-screen leakage), `story_culture` (188 IDs), `travel_vista`
   (183 IDs, wrong-content and destination-signage risk), `reading_world`
   (142 IDs, currently one of the more stable ones but worth reinforcing).
   This is a large scope; it should be sequenced, not attempted all at once.
3. **Treat the card-border/chrome defect as a live, moderate-frequency
   risk (~5% observed here), not background noise**, when deciding batch
   sizes and QA sampling going forward.
4. **Open a dedicated content-safety review** for `wellness_experience`
   (sauna/hot springs/spa-adjacent hobbies) before generating any of them
   again — this is a different risk class from the rest of this report and
   should not be bundled into a generic "recognizability" fix.
5. **Investigate the video-game-controller-intrusion pattern** in
   `group_play`/`strategy_table` as its own small, targeted question —
   it's specific and reproducible enough to diagnose cheaply.
6. **Re-scope the whole BULK-FIRST/HOLDOUT split.** Given this result, the
   smallest defensible next step is not a broader batch but a redesign
   pass: decide, archetype by archetype, whether to (a) invest in a
   detailed composition rewrite like the successful ones, (b) hold for
   manual Image 2.5, or (c) accept a lower per-card success rate with
   heavier post-generation QA sampling built into any future bulk run.

## What this task did NOT do

- Did not start the 1731-card bulk run.
- Did not use Image 2.5 through fal.ai.
- Did not reopen Robotics or American Football (both remain quarantined
  and untouched).
- Did not modify any prompt, archetype, or recipe files — this is a pure
  QA/reporting task on already-generated output.

## Infrastructure

Vercel, GitHub Actions, Production, and Google Play remain closed for this
branch. No `FAL_KEY` was exposed or committed. No auto-reroll was
performed. `sports.american_football` and `technology.robotics` remain
quarantined and untouched. This commit/push is a plain repo write (100
images + manifest + this handoff) with no CI/deployment side effects.

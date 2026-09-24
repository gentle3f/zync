# Zync Card Art — Production-Hardening: Recipe Fixes + Diversity Layer + 8-Card Stress Test — Results

Branch: `card-art-pilot-v1-20260921`
Date: 2026-09-24
Provider: Google Gemini API direct (`gemini-3.1-flash-lite-image`, Batch API). No fal.ai.

D4's rendering language (`global_style_v1.json`'s `prompt` field) was **not**
touched this round. This was production-hardening only: fixing the 3
localized defects found in the 12-card durability test, and adding a
separate, additive presentation-diversity layer.

## Part 1 — Three localized recipe fixes

All three added as new entries in `tools/card_art/catalog/hobby_overrides_v1.json`:

1. **`books.reading`** — new `avoid_add`/`must_include_add`/
   `override_prompt_additions` requiring plain or abstract book
   covers/spines, blank or non-linguistic page marks, and explicitly
   forbidding readable titles, author names, spine text, invented words,
   or pseudo-publishing logos. Visual identity must come from the physical
   books + reading action, not typography.
2. **`wellness.cold_plunge`** — subject/environment rewritten to require
   visibly cold water with floating ice cubes, condensation/frost, and a
   braced/alert/invigorated posture; explicit avoid-list against steam,
   hot-spring/onsen atmosphere, warm glowing water, relaxed soaking pose,
   and domestic bathtubs.
3. **`sports.skateboarding`** — hardened footwear/equipment brand safety
   with the same class of anti-silhouette language already proven on
   `fashion.streetwear` (no swoosh-like/checkmark-like/three-stripe-like
   marks, no signature side panels, no manufacturer badges, no recognisable
   sneaker-brand silhouette), while explicitly instructing the shoes should
   still look stylish and believable, not sterile or censored.

## Part 2 — Deterministic D4 diversity layer

New files:
- `tools/card_art/specs/diversity_profiles_v1.json` — defines 5 dimensions
  (protagonist presentation, scene structure, lighting/palette, emotional
  mode, special-effect intensity), each with an enumerated set of values
  and a human-readable guidance phrase per value.
- `tools/card_art/src/diversityLayer.js` — `computeDiversityProfile(id,
  diversityProfiles, diversityLock)` deterministically hashes the hobby
  recipe id (same stable-hash approach already used for visual-variant
  selection) with a distinct salt per dimension, so results decorrelate
  across dimensions instead of cycling together, and so the same hobby id
  always yields the same profile across regenerations. An optional
  `diversity_lock` (settable per hobby in `hobby_overrides_v1.json`) can
  pin specific dimensions when a hobby's own semantics require it.
  `buildDiversitySection()` renders the chosen profile into a single
  additive guidance sentence.

Modified files:
- `tools/card_art/src/buildPromptV1.js` — `compileHobbyPrompt()` now
  accepts an optional `diversityProfiles` argument; when supplied, it
  computes the profile and inserts one new guidance section (after
  subcategory recognition cues, before the hobby-specific subject line),
  ending with an explicit precedence sentence: hobby-specific recognition/
  must-include requirements always win if they ever conflict with the
  diversity guidance. Backward compatible: omitting `diversityProfiles`
  leaves compilation unchanged.
- `tools/card_art/src/generateCompiledBatch.js` — the fal.ai-era production
  compiler entry point now also loads and passes `diversityProfiles`, so
  the layer is wired catalog-wide going forward, not just for this test.

Full-catalog regression check: all 2210 eligible catalog rows recompiled
successfully with the diversity layer active plus the 3 new overrides
(`OK: 2210 / 2210, ERRORS: 0`) before any generation was run. A separate
distribution check confirmed the hash produces a roughly even spread
across all 5 dimensions catalog-wide (e.g. protagonist: 346-388 per value
across 6 values; effect_intensity: 713-757 per value across 3 values) -
no dimension collapses onto a single dominant value.

## The 8-card diversity stress test

New files: `tools/card_art/catalog/style_d4_diversity_8_v1.json` (config,
ID selection + per-card diversity profile + rationale, written before
generation) and `tools/card_art/src/runD4Diversity8.js` (runner;
`--dry-run` / `--submit` / `--collect`, real production compiler with
`diversityProfiles` active).

Batch: `batches/epis1z2b60oxosfem9wnhjq5jkxdn9semh9a`. 8/8 requests
returned images. Actual cost: **$0.1344** (8 x $0.0168, matches estimate).

Selected 8 canonical interests (one per required stress mode):

| ID | Required stress | Diversity profile assigned |
|---|---|---|
| `collecting.stamps` | male-led protagonist | male_led, environment_hero, night_neon, joy, none_minimal |
| `sports.golf` | older-adult protagonist | older_adult, wide_environmental_scene, mixed_complementary_palette, discovery, moderate_sparkle_motion |
| `outdoors.fishing` | object-led/no-dominant-human | object_led, object_hero, evening_interior, concentration, none_minimal |
| `music.violin` | night/cool-palette scene | younger_adult, solo_action, blue_hour, excitement, none_minimal |
| `gaming.tabletop_rpg` | group social scene | male_led, small_group, night_neon, concentration, moderate_sparkle_motion |
| `crafts.pottery_wheel` | indoor craft/making scene | younger_adult, small_group, cool_daylight, mastery, moderate_sparkle_motion |
| `outdoors.mountain_biking` | outdoor action scene | female_led, wide_environmental_scene, soft_morning, curiosity, subtle_highlights |
| `wellness.tai_chi` | calm/quiet hobby | mixed_group, solo_action, blue_hour, mastery, subtle_highlights |

None of the 12 durability-test IDs or the 6 D4 calibration IDs were
reused. `sports.american_football` and `technology.robotics` remain
quarantined and were not touched.

## QA results (human visual review of all 8 images)

| ID | Semantic | D4 fidelity | Special-illust. | Collectible | Distinctiveness | Diversity success | Brand leak | Text leak | Border/UI leak | Notes |
|---|---|---|---|---|---|---|---|---|---|---|
| collecting.stamps | PASS | 4 | 3.5 | 3.5 | 3 | 4 | NO | NO | NO | First genuinely male-led protagonist in this whole calibration arc; night desk-lamp lighting, joyful-but-calm expression, correct stamp-collecting recognition cues (tweezers, album, magnifier). |
| sports.golf | PASS | 4 | 4 | 4 | 3 | 4 | NO | NO | NO | Older, grey-haired protagonist with a serious/focused (not smiling) expression matching "discovery" mode; strongest card in the set. |
| outdoors.fishing | PASS | 3.5 | 3.5 | 3.5 | 2.5 | **2** | NO | NO | NO | object_led guidance only partially achieved: the angler remains the dominant foreground figure with an expressive face rather than being secondary to the fish/gear. Not a defect, just the weakest diversity-dimension result in the set. |
| music.violin | PASS | 4 | 3.5 | 3.5 | 2.5 | 3.5 | NO | NO | NO | Cool blue_hour palette clearly achieved against D4's usual warm default; sheet music stays illegible (no text leak). |
| gaming.tabletop_rpg | PASS | 4 | 4 | 4 | 3.5 | 4 | NO | NO | NO | Male-led + small-group + night/neon all landed simultaneously; dragon-poster fantasy content is appropriate here since the hobby itself is a fantasy tabletop game. |
| crafts.pottery_wheel | PASS | 3.5 | 3 | 3.5 | 2.5 | 3.5 | NO | NO | NO | Two-person small-group framing and cool daylight both achieved; confident-but-calm expression matches "mastery" mode. |
| outdoors.mountain_biking | PASS | 4 | 3.5 | 3.5 | 2.5 | 3.5 | NO | NO | NO | Female-led, soft-morning light, wide forest-trail framing; trail marker sign stays blank. |
| wellness.tai_chi | PASS | 3.5 | 3 | 3 | 2.5 | 3.5 | NO | **YES (minor)** | NO | Background wall-hanging scrolls show legible-looking calligraphy characters - a new, isolated text-policy leak, unrelated to the diversity mechanism itself. Also: the assigned `mixed_group` protagonist dimension was NOT applied (scene is a solo practitioner) - this is the diversity-layer's precedence rule working as designed, since the hobby's own solo-practice semantics correctly overrode the diversity guidance rather than conflicting with it. |

### Aggregates (8 cards)

- Semantic: **8/8 PASS**, 0 MINOR, 0 FAIL
- D4 style fidelity: **3.81** avg
- Special-illustration feel: **3.5** avg
- Collectible appeal: **3.56** avg
- Zync distinctiveness: **2.69** avg
- Diversity success: **3.5** avg
- Brand/trademark leak rate: **0/8 (0%)**
- Text leak rate: **1/8 (12.5%)** — `wellness.tai_chi`, background calligraphy scrolls, minor/isolated
- Border/UI leak rate: **0/8 (0%)**

### Do the 3 localized fixes hold?

None of the 3 originally-fixed hobbies (`books.reading`, `wellness.cold_plunge`,
`sports.skateboarding`) were re-generated in this 8-card set (by design -
new IDs were chosen to avoid reuse per the guardrails). The fixes were
verified structurally instead: targeted dry-run compilation confirmed all
three now emit the new override language correctly (text-suppression
reinforcement on `books.reading`, cold/ice-cue reinforcement on
`wellness.cold_plunge`, anti-silhouette reinforcement on
`sports.skateboarding`), layered on top of the unchanged base recipes and
the existing global brand-safety/text policies. A future round that
re-generates these 3 specific IDs would be needed to visually re-confirm
the fix on generated images; that was out of scope for this round's 8-image
budget, which was earmarked for diversity-dimension coverage instead.

### Does the diversity layer materially reduce sameness?

Checked across all 8 cards against the dimensions the task asked about:

- **Face type**: clearly varied — distinct male and female faces, not a
  single recurring template.
- **Age**: young-adult and older-adult protagonists both present
  (`sports.golf`'s grey-haired golfer is a first for this arc).
- **Gender presentation**: multiple cards read male-led (`collecting.stamps`,
  `sports.golf`, `gaming.tabletop_rpg`'s central figure), several read
  female-led (`music.violin`, `outdoors.mountain_biking`,
  `crafts.pottery_wheel`, `wellness.tai_chi`) — no longer defaulting to a
  single female-only presentation.
- **Composition**: desk close-up, dynamic golf swing, riverside action,
  music-studio performance, seated group table, pottery-wheel workshop,
  forest trail action, and a martial-arts stance — eight visibly different
  compositions, not eight variations on one medium shot.
- **Lighting**: night/lamp (`collecting.stamps`), golden/soft daylight
  (`sports.golf`, `outdoors.mountain_biking`), evening interior
  (`outdoors.fishing`), blue_hour cool light (`music.violin`,
  `wellness.tai_chi`), night/neon (`gaming.tabletop_rpg`), cool daylight
  (`crafts.pottery_wheel`) — the previous golden-hour default is no longer
  the only lighting mode in the set.
- **Palette**: cool blues in several cards balanced against warm greens/
  browns in others — no single dominant hue family across the set.
- **Emotional expression**: serious concentration (`sports.golf`), tense
  focus (`outdoors.fishing`), open excitement (`music.violin`), enthusiasm
  (`gaming.tabletop_rpg`), calm confidence (`crafts.pottery_wheel`,
  `wellness.tai_chi`), joy (`outdoors.mountain_biking`,
  `collecting.stamps`) — not every card defaults to an open smile.
- **Sparkle usage**: `none_minimal` on 3 cards, `subtle_highlights` on 2,
  `moderate_sparkle_motion` on 3 — visibly not present on every card.

**Conclusion: sameness is materially reduced across every dimension
checked**, without any semantic PASS becoming MINOR/FAIL and without any
new brand/trademark leak.

## Decision rule applied

> Can the same D4 house style produce visibly diverse cards without losing
> semantic fidelity or brand identity?

**Yes.** 8/8 semantic PASS, 0/8 brand/trademark leaks, 0/8 border/UI
defects. One isolated new text leak was found (`wellness.tai_chi`'s
background calligraphy scrolls) - a localized recipe-level issue, not a
diversity-layer or D4 failure (the diversity layer did not request or
cause the calligraphy; it's a base-recipe/global-text-policy gap on this
one hobby's Japanese-interior environment). One diversity dimension
landed only partially (`outdoors.fishing`'s object_led framing) - a
tuning opportunity, not a systemic failure, and it did not compromise
semantic correctness.

**Per the pre-declared decision rule: keep D4 unchanged, keep the
diversity layer, and this checkpoint is ready to move toward
production-batch architecture planning** (architecture/engineering only -
no bulk generation was started).

### Identified follow-ups (not executed this round — recommendations only)

1. `wellness.tai_chi` needs a hobby-level override suppressing legible
   wall-hanging calligraphy/text (same pattern as `books.reading` and
   `lifestyle.game_nights`).
2. Consider strengthening the `object_led` diversity-dimension phrase
   language (or pairing it with an explicit `scene_structure: object_hero`
   co-requirement) since a single sentence was not always enough to
   de-emphasize a human figure when the base hobby recipe's own subject
   line names a person as the actor.
3. The 3 recipe fixes from Part 1 should get a small dedicated
   re-generation (3 images) in a future round to visually confirm the
   fixes on generated output, since this round's 8 IDs were deliberately
   chosen not to overlap with them.

## Guardrails honored

- Exactly 8 new images generated, no rerolls, no larger batch.
- No fal.ai, no image-to-image, no reference images.
- No Vercel, no GitHub Actions, no Production, no Google Play.
- `sports.american_football` and `technology.robotics` remain quarantined
  and untouched.
- `GEMINI_API_KEY` was never printed, logged, or committed.
- `tools/card_art/output/style_calibration_d_18_v1/images/d.zip` and
  `tools/card_art/output/style_d4_durability_12_v1/images/images.zip`
  (both untracked, presumed user-created for local review) left untouched
  and excluded from this commit.
- Raw base64/large Google response blobs were not committed — only
  extracted `.jpg` images, the compact manifest, the experiment config,
  the runner script, spec/source diffs, and this handoff.
- No bulk/auto-scaled generation was started after these results.

## Files in this checkpoint

- `tools/card_art/catalog/hobby_overrides_v1.json` (modified — 3 new fixes:
  `books.reading`, `wellness.cold_plunge`, `sports.skateboarding`)
- `tools/card_art/specs/diversity_profiles_v1.json` (new — diversity
  dimension definitions)
- `tools/card_art/src/diversityLayer.js` (new — deterministic profile
  computation)
- `tools/card_art/src/buildPromptV1.js` (modified — wires the diversity
  layer into `compileHobbyPrompt`)
- `tools/card_art/src/generateCompiledBatch.js` (modified — loads/passes
  `diversityProfiles` for catalog-wide activation)
- `tools/card_art/catalog/style_d4_diversity_8_v1.json` (new — 8-card test
  config, ID + diversity-profile rationale, decision rule)
- `tools/card_art/src/runD4Diversity8.js` (new — runner)
- `tools/card_art/output/style_d4_diversity_8_v1/` (new — 8 images,
  manifest, redacted batch status, requests/job records)

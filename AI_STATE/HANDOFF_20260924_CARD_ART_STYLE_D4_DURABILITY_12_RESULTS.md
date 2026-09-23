# Zync Card Art — D4 Cross-Category Durability Test (12 cards) — Results

Branch: `card-art-pilot-v1-20260921`
Date: 2026-09-24
Provider: Google Gemini API direct (`gemini-3.1-flash-lite-image`, Batch API). No fal.ai.

## What changed this round (production files, not experiment-only)

D4 has been promoted from an isolated calibration experiment into the actual
production global style:

1. `tools/card_art/specs/global_style_v1.json`
   - `prompt` replaced with D4's exact style-block text (byte-identical to
     `catalog/style_calibration_d4_block_v1.json`'s `styles.D4.prompt`,
     verified via direct string equality before any paid call).
   - New field `global_brand_safety_policy` added: a global, catalog-wide
     rule requiring plain/generic/unbranded clothing, footwear, bags,
     sports/athletic equipment, electronics, tools, instruments, vehicles,
     and other manufactured products, forbidding logos, manufacturer
     badges, brand-like marks, swoosh-like marks, checkmark-like sportswear
     marks, three-stripe-like patterns, signature side-panel marks,
     recognisable sneaker-brand silhouettes/sole geometry, recognisable
     proprietary product design language, and readable brand text —
     while explicitly instructing the model not to make objects sterile or
     obviously censored, and to invent plausible original designs instead.
2. `tools/card_art/src/buildPromptV1.js` — wired `global_brand_safety_policy`
   into the compiled prompt (new section, after `global_screen_policy`).
3. `tools/card_art/catalog/hobby_overrides_v1.json` — new `learning.philosophy`
   entry: shifts the recipe from ancient-artifact/grimoire framing to
   contemporary intellectual discussion (modern book/notebook, concept
   diagram, discussion gesture, library/cafe/campus setting), with an
   explicit avoid-list against occult/alchemy/grimoire/ancient-artifact
   imagery and an `override_prompt_additions` reinforcement keeping the
   D4 "knowledge is exciting" emotional target (curious/animated, not
   gloomy or solemn).

Full-catalog regression check: all 2210 eligible catalog rows recompiled
successfully after these three edits (`OK: 2210 / 2210, ERRORS: 0`) before
any generation was run.

## The 12-card test

New files: `tools/card_art/catalog/style_d4_durability_12_v1.json` (config,
ID selection + rationale, decision gate, written before generation) and
`tools/card_art/src/runD4Durability12.js` (runner; `--dry-run` / `--submit`
/ `--collect`, sources prompts from the real production compiler, not an
isolated style override).

Batch: `batches/glw02l7zur0ccygwnwsckabbp2s0mhgjhqwx`. 12/12 requests
returned images. Actual cost: **$0.2016** (12 x $0.0168 Gemini Batch API
image-output price; matches the pre-generation estimate exactly).

Selected 12 canonical interests (category type, structural stress-test):

| ID | Category type | Structural stress |
|---|---|---|
| `sports.skateboarding` | sport | solo action, outdoor, equipment-heavy |
| `outdoors.kayaking` | outdoor activity | solo action, outdoor, equipment-heavy |
| `pets.birds` | pet/animal | companion_bond beyond dogs |
| `travel.destination_deep.japanese_onsen_trips` | travel | onsen-adjacent theme, safety re-check |
| `music.piano` | music | solo, indoor, object-focused hero prop |
| `wellness.cold_plunge` | wellness | wellness_experience safety stress test |
| `science.marine_biology` | science/learning | sibling of learning.philosophy, override-scope check |
| `technology.3d_printing` | technology | screen-adjacent, equipment-heavy, not robotics |
| `crafts.knitting` | craft/making | solo, indoor, material-focused |
| `books.reading` | solo hobby | calm indoor solo activity |
| `lifestyle.game_nights` | social hobby | group scene, override-stacking check |
| `lifestyle.home_decor` | lifestyle/everyday | indoor, object-focused |

None of the 6 D4 calibration cards were reused. `sports.american_football`
and `technology.robotics` remain quarantined and were not touched.

## QA results (15-dimension rubric, human visual review of all 12 images)

| ID | Semantic | Anime | Special-illust. | Joy | Collectible | Hero focus | Distinctiveness | Photographic | W. editorial drift | Fantasy drift | Brand/trademark leak | Border/UI defect | Text leak | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| sports.skateboarding | PASS | 4 | 4 | 4 | 3.5 | 4 | 3 | 0 | 0 | 0 | **YES (minor)** | NO | NO | Shoe reads as a recognisable low-top skate-sneaker silhouette (waffle-like sole, cupsole panel layout) — no logo/text, but a real-brand-adjacent silhouette the new global policy didn't fully suppress. |
| outdoors.kayaking | PASS | 4 | 4 | 4 | 4 | 4 | 3 | 0 | 0 | 0 | NO | NO | NO | Clean; strongest card in the set. |
| pets.birds | PASS | 3.5 | 3 | 4 | 3.5 | 3 | 2.5 | 0 | 0 | 0 | NO | NO | NO | Warm, clean. companion_bond generalizes fine beyond dogs. |
| travel.japanese_onsen_trips | PASS | 4 | 4 | 4 | 3.5 | 3.5 | 3 | 0 | 0 | 0 | NO | NO | NO | Safety re-check passed: fully clothed figures, arrival/approach framing, no bathing exposure. |
| music.piano | PASS | 3.5 | 3.5 | 3.5 | 3 | 3.5 | 2.5 | 0 | 0 | 0 | NO | NO | NO | Minor anatomy artifact: an extra pair of hands visible on the keys (duet-like duplication) — quality issue, not a policy violation. |
| wellness.cold_plunge | **MINOR** | 3.5 | 3.5 | 3 | 3 | 3 | 2.5 | 0 | 0 | 0 | NO | NO | NO | Visible steam and a relaxed soaking pose read as a warm onsen/hot-bath moment rather than a cold immersion — the wellness_experience archetype's "hot springs" bias leaked into cold_plunge. No safety/nudity issue (fully covered). |
| science.marine_biology | PASS | 3.5 | 3.5 | 4 | 3.5 | 3 | 2.5 | 0 | 0 | 0 | NO | NO | NO | Confirms the new `learning.philosophy` override did not leak into a sibling `learning_exploration` hobby — no occult/grimoire drift here. |
| technology.3d_printing | PASS | 3.5 | 3.5 | 3 | 3.5 | 3.5 | 3 | 0 | 0 | 0 | NO | NO | NO | Screen-adjacent stress test passed: laptop in background stays dark/turned away, no readable UI. |
| crafts.knitting | PASS | 4 | 3.5 | 4 | 3.5 | 3 | 2.5 | 0 | 0 | 0 | NO | NO | NO | Clean, charming. |
| books.reading | PASS | 3.5 | 3 | 4 | 3 | 3.5 | 2 | 0 | 0 | 0 | NO | NO | **YES (major)** | Two book covers held by the subject carry clearly readable invented titles ("JOURNEY TO THE UNKNOWN", "STARRY TALES") — a direct text-policy violation on the hero objects. |
| lifestyle.game_nights | PASS | 4 | 4 | 4 | 4 | 3.5 | 3 | 0 | 0 | 0 | NO | NO | NO | Group scene; cards/board show only glowing abstract sigils, no readable text — confirms override-stacking (existing text-suppression override + new global policy) still works. |
| lifestyle.home_decor | PASS | 3.5 | 3 | 3.5 | 3 | 3 | 2 | 0 | 0 | 0 | NO | NO | NO | Clean; book spines on shelf are blank/indistinct. |

### Aggregates (12 cards)

- Semantic: **11/12 PASS, 1/12 MINOR** (`wellness.cold_plunge`), 0 FAIL
- Japanese anime feel: **3.71** avg
- Special-illustration feel: **3.54** avg
- Joy/emotional energy: **3.71** avg
- Collectible appeal: **3.38** avg
- Hero focus: **3.38** avg
- Zync distinctiveness: **2.63** avg
- Photographicness: **0.0** avg
- Western editorial drift: **0.0** avg
- Fantasy drift: **0.0** avg
- Brand/trademark leak rate: **1/12 (8.3%)** — silhouette-level only, no logo/text, `sports.skateboarding`
- Text leak rate: **1/12 (8.3%)**, major — `books.reading`
- Border/UI defect rate: **0/12 (0%)**

## Decision gate applied

Preferred gate from `style_d4_durability_12_v1.json`:

| Criterion | Threshold | Actual | Met? |
|---|---|---|---|
| semantic FAIL | = 0 | 0 | Yes |
| semantic MINOR | <= 2 | 1 | Yes |
| brand/trademark leak | = 0 | 1 | **No** |
| border/UI defect | = 0 | 0 | Yes |
| major text leak | = 0 | 1 | **No** |
| avg anime feel | >= 3.0 | 3.71 | Yes |
| avg special-illustration feel | >= 3.0 | 3.54 | Yes |
| avg collectible appeal | >= 3.0 | 3.38 | Yes |
| avg Zync distinctiveness | >= 2.5 | 2.63 | Yes |
| avg fantasy drift | <= 1.0 | 0.0 | Yes |
| no systemic category collapse | — | Confirmed: the two defects are isolated to one card each, in different categories and different failure modes, not clustered | Yes |

**Outcome: localized issues, not systemic collapse.** Per the pre-declared
decision rule, this means: fix at the recipe level, not by rewriting D4
globally. D4 remains the leading production-style baseline (already
reflected in `global_style_v1.json` as of this checkpoint) — no rollback
warranted. No reference-conditioned style-consistency test is needed; the
calibration/durability arc is not stalling.

### Identified follow-ups (not executed this round — recommendations only)

1. `books.reading` needs a hobby-level text-suppression override (same
   pattern as `lifestyle.game_nights`) to stop invented book titles from
   rendering as readable text on the hero book props.
2. `sports.skateboarding` (and likely other footwear-heavy sport hobbies)
   may need a hobby-level reinforcement similar to `fashion.streetwear`'s
   existing anti-sneaker-silhouette override — the new global brand-safety
   policy reduced but did not eliminate a recognisable skate-shoe
   silhouette, the same class of issue `fashion.streetwear` already showed
   once.
3. `wellness.cold_plunge` would benefit from an explicit hobby-level cue
   (visible cold/ice, breath vapor, brisk/invigorated expression, no steam)
   to differentiate it from the sibling hot-springs/sauna recipes in the
   same `wellness_experience` archetype.

Per this task's guardrails, none of these three fixes were implemented in
this round, and no further generation was started.

## Guardrails honored

- Exactly 12 new images generated, no rerolls, no larger batch.
- No fal.ai, no image-to-image, no style references.
- No Vercel, no GitHub Actions, no Production, no Google Play.
- `sports.american_football` and `technology.robotics` remain quarantined
  and untouched.
- `GEMINI_API_KEY` was never printed, logged, or committed.
- `tools/card_art/output/style_calibration_d_18_v1/images/d.zip` (untracked,
  pre-existing, presumed user-created) left untouched and excluded from
  this commit.
- Raw base64/large Google response blobs were not committed — only
  extracted `.jpg` images, the compact manifest, the experiment config, the
  runner script, and this handoff.
- No larger generation was started after these results.

## Files in this checkpoint

- `tools/card_art/specs/global_style_v1.json` (modified — D4 promoted to
  production, brand-safety policy added)
- `tools/card_art/src/buildPromptV1.js` (modified — wires brand-safety
  policy into compiled prompts)
- `tools/card_art/catalog/hobby_overrides_v1.json` (modified — added
  `learning.philosophy` fix)
- `tools/card_art/catalog/style_d4_durability_12_v1.json` (new — 12-card
  test config, ID rationale, decision gate)
- `tools/card_art/src/runD4Durability12.js` (new — runner)
- `tools/card_art/output/style_d4_durability_12_v1/` (new — 12 images,
  manifest, redacted batch status, requests/job records)

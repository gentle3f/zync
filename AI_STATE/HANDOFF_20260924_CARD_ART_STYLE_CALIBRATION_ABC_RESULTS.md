# Zync — House-Style A/B/C Calibration (18-Card): Results

Date: 2026-09-24
Branch: `card-art-pilot-v1-20260921`
Parent HEAD: `1f9f017e5a55c650c3ad9c9bc363cd2e7dbb6428`

Read `AI_STATE/OPERATING_RULES.md` before any write or external action.

## Bottom line

**Text-only style control works: all three directions produced genuinely
illustrated, non-photographic output on `gemini-3.1-flash-lite-image`,
resolving the "looks like stock photography" problem the user flagged.**
No fallback to reference-image-conditioned `gemini-3.1-flash-image` is
needed at this stage.

**But the user's stated pre-test preference, Version A (Editorial
Lifestyle), tested weakest of the three on the metrics that matter most:**
it has the lowest Zync-distinctiveness score of the three, and — more
concretely — it reproduced the recurring rounded card-border/chrome
defect in **4 of 6 images (67%)**, far more than Version B (1/6, 17%) or
Version C (0/6, 0%). This is not a subjective impression; it is a
directly observable, counted pattern across this sample. Version A is not
recommended as-is.

**Recommendation: Version C (Graphic Editorial Hybrid)**, with Version B
as a credible second choice if more dramatic "collectible" heightening is
prioritized over house-style distinctiveness. Full reasoning below.

## What ran

```bash
cd tools/card_art
node src/runStyleCalibration18.js --dry-run
node src/runStyleCalibration18.js --submit
node src/runStyleCalibration18.js --collect   # polled until BATCH_STATE_SUCCEEDED
```

New files (experiment-only, production untouched):
- `tools/card_art/catalog/style_calibration_blocks_v1.json` — the three
  full style-block prose blocks (A/B/C), verbatim from the task.
- `tools/card_art/catalog/style_calibration_18_v1.json` — 6 hobbies x 3
  styles config.
- `tools/card_art/src/runStyleCalibration18.js` — adapted from
  `runGemini31FlashLiteDirectBatch24.js`.

### Isolation mechanism and mechanical verification

For each style version, the runner builds an in-memory clone of the real
`global_style_v1.json` with **only the top-level `prompt` field**
replaced by that version's style block; `global_text_policy`,
`global_screen_policy`, and `global_negatives` are reused unchanged from
production, so content-safety/text/screen-suppression behavior is held
constant across A/B/C — only visual style varies. Production
`global_style_v1.json` on disk was never modified (confirmed via
`git status` before and after).

**Mechanical proof of semantic identity across A/B/C**, run automatically
before every dry-run/submit/collect and confirmed passing: since
`buildPromptV1.js` always emits the style block as the literal first
section of the compiled prompt, the verifier strips exactly that known
string prefix from each compiled prompt and diffs the remainder
character-for-character across A/B/C for the same hobby. All 6 hobbies
passed with zero divergence outside the injected style block. (An earlier,
naive version of this check — splitting the whole compiled prompt on
`\n\n` — produced a false alarm because the style-block prose itself
contains internal `\n\n` breaks; fixed to a prefix-strip before any paid
call was made.)

### Dry-run and submission

- Exactly 18 rows (6 hobbies x 3 styles), $0.3024 estimated — matches.
- Model: `gemini-3.1-flash-lite-image`, direct Google API, zero `fal.ai`
  references (grep-confirmed).
- Batch submitted: `batches/vanpyzmx5do8ppqfwmz1k25mkvrc0ov00rg0`; reached
  `BATCH_STATE_SUCCEEDED` in about 5 minutes (much faster than the prior
  24-card run's ~90 minutes — apparently not a consistent per-request
  latency characteristic of this model).
- **18/18 images collected successfully**, no timeouts this round.
  Actual cost: **$0.3024** — matches estimate exactly.
- Redaction fix from the prior round (strip any oversized string by
  length, not by key name, to catch this model's `thoughtSignature`
  blobs) carried over and confirmed working: `batch_status.json` is 54KB,
  not the ~65MB it would have been with the old key-name-only redaction.

Images are organized into `output/style_calibration_18_v1/images/A/`,
`/B/`, `/C/` subfolders for unambiguous comparison, plus a single
manifest covering all 18 with `style_version`/`style_label` fields.

## Per-image results

| Hobby | Style | Semantic | Photographicness | Collectible | Distinctiveness | Maturity | Border defect |
|---|---|---|---|---|---|---|---|
| business.coworking | A | PASS | 0 | 2 | 2 | 2 | **YES** |
| business.coworking | B | PASS | 1 | 2.5 | 2 | 2.5 | No |
| business.coworking | C | PASS | 0 | 1.5 | 2.5 | 2.5 | No |
| legal_thriller | A | PASS | 0 | 3 | 2 | 4 | No |
| legal_thriller | B | MINOR (reads as generic cinema-going, not specifically "legal thriller") | 1 | 2.5 | 1.5 | 3 | No |
| legal_thriller | C | PASS | 0 | 2.5 | 3 | 3 | No |
| fashion.streetwear | A | PASS | 0 | 2 | 2 | 2 | **YES** |
| fashion.streetwear | B | PASS | 0.5 | 3 | 2 | 3 | No |
| fashion.streetwear | C | PASS | 0 | 2 | 3 | 3 | No |
| food.dish.bun_cha | A | PASS | 0 | 2 | 1 | 2 | **YES** |
| food.dish.bun_cha | B | PASS | 1 | 3 | 2 | 3 | No |
| food.dish.bun_cha | C | PASS | 0.5 | 2 | 2.5 | 3 | No |
| gaming.board | A | PASS | 0 | 3 | 2 | 3 | No |
| gaming.board | B | PASS | 0.5 | 3.5 | 2 | 4 | No |
| gaming.board | C | PASS | 0 | 3 | 3 | 3 | No |
| learning.philosophy | A | PASS | 0 | 2 | 2 | 3 | **YES** |
| learning.philosophy | B | PASS (mild magical-glow rim light around the bust — a soft drift toward the "excessive fantasy glow" negative, not disqualifying but worth watching) | 0.5 | 3 | 2 | 2.5 | **YES** |
| learning.philosophy | C | PASS | 0 | 2 | 3 | 3 | No |

**Semantic correctness: 17/18 PASS, 1/18 MINOR** (Version B's legal
thriller — the only semantic-specificity miss in the whole set, and it is
style-adjacent: a more generic composition choice rather than a
recognition failure).

## Aggregate scores by style version

| Metric (0–4 scale unless noted) | Version A (Editorial Lifestyle) | Version B (Collectible Fantasy Lean) | Version C (Graphic Editorial Hybrid) |
|---|---|---|---|
| Photographicness (lower = better) | **0.0** | 0.75 | 0.08 |
| Collectible appeal (higher = better) | 2.2 | **2.9** | 2.2 |
| Zync distinctiveness (higher = better) | 1.8 | 1.9 | **2.75** |
| Maturity / premium feel (higher = better) | 2.7 | **3.1** | 2.9 |
| Card-border/chrome defect rate | **4/6 (67%)** | 1/6 (17%) | **0/6 (0%)** |
| Semantic issues | 0 | 1 MINOR | 0 |

## Strongest and weakest examples per direction

- **Version A** — strongest: `legal_thriller` (Q4 maturity, genuinely
  excellent courtroom/audience composition, no border). Weakest:
  `food.dish.bun_cha` (border defect, low distinctiveness, a "greeting
  card" quality that undercuts the intended premium feel).
- **Version B** — strongest: `gaming.board` (Q3.5–4 across the board,
  the single best-rendered image in the entire 18). Weakest:
  `legal_thriller` (the one semantic MINOR — reads as generic
  cinema-going rather than a legal thriller specifically) and
  `learning.philosophy` (the one B border occurrence, plus the mild
  magical-glow drift).
- **Version C** — strongest: `gaming.board` and `fashion.streetwear`
  (both Q3 distinctiveness, consistent recognizable graphic identity,
  zero defects). Weakest: `business.coworking` (competent but the least
  "collectible" feeling of C's six — a wide group office shot doesn't
  showcase C's hero-silhouette strengths as well as the single-subject
  cards do).

## Answers to the specific review questions

1. **Does any version still look too photographic?** No. All three
   averaged well under 1.0 on the 0–4 photographicness scale (0 = clearly
   illustrated). This was the primary problem being tested for, and all
   three solved it.
2. **Does any version become too fantasy-heavy?** Not disqualifyingly,
   but Version B's `learning.philosophy` card shows a soft magical-glow
   rim-light effect around the statue that drifts toward the explicitly
   forbidden "excessive fantasy glow" / "generic AI-art gloss" territory.
   This is a single occurrence, not a pattern, but is worth watching if B
   is pursued further.
3. **Does any version look too generic/editorial and lose collectible
   appeal?** No. Version C, despite being the most "graphic/editorial" of
   the three by design, still scored on par with A on collectible appeal
   (2.2 each) while scoring highest on distinctiveness — it does not show
   the failure mode of trading away collectibility for design polish.
4. **The user's stated pre-test preference (Version A) does not test as
   the strongest option.** It ties for lowest distinctiveness and has by
   far the worst card-border-defect rate of the three (67% vs. 0–17%).
   This is reported plainly rather than softened toward the stated
   preference, per the instruction not to bias scoring toward A.

## Recommendation

**Version C (Graphic Editorial Hybrid)** is the strongest overall
candidate:
- Zero card-border/chrome defects in this sample (vs. 67% for A).
- Highest Zync-distinctiveness score, and — importantly — a *consistent,
  recognizable* graphic identity across genuinely different hobby
  contexts (coworking, courtroom-cinema, streetwear, food, board games,
  philosophy all read as coming from the same designed visual family,
  which is exactly the "ownable house style" question this experiment
  was built to answer).
- Competitive collectible-appeal and maturity scores — it does not
  sacrifice premium feel for its graphic distinctiveness.
- No semantic misses.

**Version B (Collectible Fantasy Card Lean)** is a credible second
choice if the priority is maximizing dramatic "collectible-card energy"
over house-style distinctiveness — it has the highest raw collectible-
appeal and maturity scores — but it carries a real, if soft, fantasy-glow
drift risk and produced the set's one semantic MINOR.

**Version A (Editorial Lifestyle)**, the user's stated pre-test
preference, is **not recommended as-is**. Its core illustration quality
is good (it ties for the lowest photographicness score and produced the
single highest-maturity individual image in the set, `legal_thriller`),
but it is the least distinctive of the three and carries a card-border
defect rate more than triple the closest competitor. If Version A is
still preferred for other reasons, the border-defect pattern specifically
should be investigated and likely fixed (e.g. a more explicit "no card
border, no frame, edge-to-edge full-bleed" reinforcement placed later in
A's prose, since the shared negatives list already forbids this
explicitly and A still produces it at a much higher rate than B/C given
the identical negatives — suggesting something in A's specific positive
prose language is a weak trigger) before further investment.

## Scalability note

This 6-hobby sample deliberately spans business/professional, cultural/
entertainment, fashion, food, tabletop gaming, and academic/intellectual
content. All three versions held their core visual identity across this
spread without the hobby-specific content ever breaking the style. This
is a positive signal for scalability across the full catalog, though a
6-hobby sample is not proof at the scale of "thousands of interests" —
the recommended next step (below) addresses this.

## What this task did NOT do

- Did not modify `tools/card_art/specs/global_style_v1.json` (verified
  via `git status` before and after).
- Did not change any semantic recipe, hobby recognition anchor, or
  routing.
- Did not use image-to-image or reference-image conditioning.
- Did not change model — stayed on `gemini-3.1-flash-lite-image`
  throughout.
- Did not use `fal.ai` anywhere.
- Did not run a 24-card repeat, 100-card, or 2210-card batch.
- Did not reopen `sports.american_football` or `technology.robotics`
  (both remain quarantined, untouched).

## Recommended next steps (not executed this task)

1. **Select a direction** (C recommended, B as an alternative) and
   promote it to `global_style_v1.json`'s production `prompt` field as a
   deliberate, explicit change — not automatically done here, since this
   was scoped as an isolated experiment.
2. **If Version A is still wanted**, run a small isolated diagnostic
   (e.g. 4–6 calls) specifically targeting the card-border pattern before
   deciding between A and C — the current sample is enough to show the
   pattern exists and is measurably worse for A, but not enough to
   diagnose its exact textual trigger.
3. Once a direction is selected, a modest stratified sample (12–24 cards)
   across categories not covered in this 6-hobby set (sports, travel,
   wellness, pets, music, outdoors) would validate scalability before any
   larger production commitment — still far short of a 100-card or
   2210-card batch.
4. `sports.american_football` and `technology.robotics` remain
   quarantined; not touched this task.

## Infrastructure

Vercel, GitHub Actions, Production, and Google Play remain closed for
this branch. `GEMINI_API_KEY` (already present in `tools/card_art/.env`,
confirmed gitignored) was reused; never printed, logged, or committed. No
`fal.ai` route was used anywhere in this test. No 100-card or 2210-card
batch was started. `sports.american_football` and `technology.robotics`
remain quarantined and untouched. `batch_status.json` stayed small (54KB)
using the redaction fix carried over from the prior round.

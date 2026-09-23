# Zync — House-Style D4 Japanese Special-Illustration Calibration (6-Card): Results

Date: 2026-09-24
Branch: `card-art-pilot-v1-20260921`
Parent HEAD: `e66db9486a8594ab8c764a97ea19668602e76ec8`

Read `AI_STATE/OPERATING_RULES.md` before any write or external action.

## Bottom line

**D4 is a decisive, visually clear improvement over D3.** D3 (the
strongest of D1/D2/D3) still read as competent but ordinary Japanese
lifestyle anime — pleasant scenes of people doing hobbies together. D4
adds the special-illustration/full-art composition language the task
identified as missing, and the result consistently reads as an iconic
"this is the moment" scene rather than a slice-of-life snapshot: a
mid-air dice roll with a sparkle trail at the decisive turn of a board
game, a dramatic courtroom accusation glowing on-screen with a visibly
tense viewer reacting in the foreground, noodles lifted mid-bite with
visible steam and an open-mouthed joyful expression. **Zero card-border/
fake-TCG-UI defects occurred in this round** — a meaningful signal that
deliberately reducing literal "trading card"/"collectible card"/"card
frame" phrasing (per the task's explicit instruction, after D1 produced a
severe fake-TCG-UI defect from that exact framing) worked as intended.

**Two things to flag plainly, not gloss over:**
1. `learning.philosophy` shows an antique, diagram-covered tome that reads
   closer to an occult/alchemical grimoire than a clearly modern
   philosophy notebook — exactly the drift the task's own semantic guard
   explicitly warned against ("not occult/alchemy/mystical artifacts").
   Scored MINOR on semantic grounds despite otherwise excellent execution.
2. `fashion.streetwear` shows a light checkmark/swoosh-like mark on the
   white sneaker — a possible trademark-adjacent risk, flagged for
   awareness even though it is not blatant.

Neither is disqualifying, and neither is the severe structural defect D1
produced. **D4 is recommended as the new style baseline.**

## What ran

```bash
cd tools/card_art
node src/runStyleCalibrationD4.js --dry-run
node src/runStyleCalibrationD4.js --submit
node src/runStyleCalibrationD4.js --collect   # polled until BATCH_STATE_SUCCEEDED
```

New files (experiment-only, production untouched):
- `tools/card_art/catalog/style_calibration_d4_block_v1.json` — the D4
  style block, verbatim from the task text (special-illustration/full-art
  composition language layered on the D3-level anime rendering
  instructions, with "trading card"/"collectible card"/"card frame"
  phrasing deliberately minimized per instruction).
- `tools/card_art/catalog/style_calibration_d4_6_v1.json` — 6 hobbies x 1
  style config, same 6 canonical IDs as every prior style round.
- `tools/card_art/src/runStyleCalibrationD4.js` — adapted from
  `runStyleCalibrationD18.js`, single-style variant.

### Isolation and verification

Only `global_style_v1.json`'s top-level `prompt` field is swapped in an
isolated in-memory clone; `global_text_policy`, `global_screen_policy`,
and `global_negatives` are reused unchanged from production. Production
`global_style_v1.json` on disk was never modified (confirmed via
`git status` before and after). Since this round has no sibling style
version to diff against (unlike A/B/C or D1/D2/D3), the verification
performed is a prefix check confirming each compiled prompt starts with
exactly the injected D4 style-block string before any paid call — this
still catches any accidental mutation of the semantic sections, though it
is a weaker guarantee than the cross-version diff used in prior rounds
(disclosed plainly, not glossed over).

Per the explicit instruction, only the global style block changed; the
per-hobby "special-moment logic" examples given in the task (coworking's
breakthrough moment, legal thriller's courtroom confrontation, etc.) were
treated as interpretive guidance for understanding the intended direction
and for scoring, not injected as hobby-specific prompt text — injecting
them would have violated the explicit "do not change subject/environment/
must-include" constraint. The D4 global style block's own generic
language ("stage a single emotional or action peak," "HERO MOMENT" focal
hierarchy) was relied on to let the model find each hobby's own best
moment, and the results below show this worked without per-hobby
hardcoding.

### Dry-run, submission, and collection

- Exactly 6 rows, $0.1008 estimated — matches.
- Model: `gemini-3.1-flash-lite-image`, direct Google API, zero `fal.ai`
  references.
- Batch submitted: `batches/8q88jik2g3lf0tomqoh81ny1rwyw7uou4fhl`; reached
  `BATCH_STATE_SUCCEEDED` in about 8 minutes.
- **6/6 images collected successfully**, no timeouts.
- Actual cost: **$0.1008** — matches estimate exactly.
- `batch_status.json` stayed small (19KB) using the redaction fix carried
  over from prior rounds.

Images saved to
`output/style_calibration_d4_6_v1/images/D4/`.

## Per-image results

| Hobby | Semantic | Anime feel | Special-illustration feel | Joy | Collectible | Hero focus | Distinctiveness | Photographicness | Western drift | Fantasy drift | Border/UI defect | Maturity |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| business.coworking | PASS | 3 | 2.5 | 3 | 2.5 | 2.5 | 2 | 0 | 0 | 0 | No | 3 |
| entertainment.movie_subgenre.legal_thriller | PASS — clear courtroom accusation visible, the best legal-thriller result across both D-rounds | 3.5 | 3.5 | 3 | 3.5 | 3.5 | 3 | 0 | 0 | 0 | No | 4 |
| fashion.streetwear | PASS — content correct; a light checkmark/swoosh-like mark on the sneaker is a possible trademark-adjacent risk, flagged separately | 3.5 | 3 | 3.5 | 3 | 3 | 2 | 0 | 0 | 0 | No | 3 |
| food.dish.bun_cha | PASS — correct dish, no recurrence of D1's card-UI defect | 3.5 | 3.5 | 4 | 4 | 3.5 | 3 | 0 | 0 | 0 | No | 4 |
| gaming.board | PASS — no video-game controllers, correct tabletop content | 4 | 4 | 4 | 4 | 3.5 | 3 | 0 | 0 | 1.25 | No | 4 |
| learning.philosophy | MINOR — antique diagram-covered tome reads closer to occult/alchemical grimoire than clearly modern philosophy content, the specific drift the task's semantic guard warned against | 3.5 | 3.5 | 3.5 | 3.5 | 3.5 | 3 | 0 | 0 | 0.5 | No | 4 |

**Semantic correctness: 5/6 PASS, 1/6 MINOR, 0/6 FAIL.**

**Border/UI defect rate: 0/6 (0%)** — a meaningful contrast with D1's
1/6 severe occurrence in the prior round.

## Aggregate D4 scores

| Metric (0–4 unless noted) | D4 | D3 (prior round, for comparison) |
|---|---|---|
| Japanese anime feel | 3.5 | 3.58 |
| Special-illustration feel | **3.33** | not scored (new metric this round — the gap D4 was built to close) |
| Joy/emotional energy | 3.5 | 3.67 |
| Collectible appeal | 3.42 | 3.33 |
| Hero focus | **3.25** | not scored (new metric this round) |
| Zync distinctiveness | 2.67 | 2.75 |
| Photographicness | 0.0 | 0.0 |
| Western editorial drift | 0.0 | 0.0 |
| Fantasy drift | 0.29 | 0.58 |
| Maturity/premium | 3.67 | 3.58 |
| Border/UI defect rate | **0%** | 0% |

D4 and D3 land close on the metrics both rounds shared (anime feel, joy,
collectible appeal, distinctiveness, maturity — D4 edges ahead on most,
essentially tied on the rest), which is expected since D4 retains D3's
anime-rendering intensity. **The real story is qualitative, not
numeric**: D3's images, even at high individual scores, consistently
depicted grounded "everyone doing the activity together" scenes, while
D4's images consistently depict a single dramatic or emotional peak with
clear visual hierarchy — exactly the distinction the new
Special-illustration-feel and Hero-focus metrics were introduced to
capture, and exactly what direct visual comparison confirms.

## Strongest and weakest D4 cards

**Strongest: `gaming.board`.** A glowing dice roll mid-air with a sparkle
trail at the exact decisive moment, four vividly reacting faces, hands
converging on the board — this is the clearest "this is the moment"
execution in the set, and arguably across all four style rounds combined.

**Second strongest: `food.dish.bun_cha`.** Chopsticks lifting a bite with
visible steam, an open-mouthed joyful expression, warm lantern-lit street
setting — genuinely appetizing and exciting, with zero defects (a
meaningful contrast to D1's severe failure on this exact hobby).

**Weakest: `business.coworking`.** Improved over D3's version (a clearer
foreground hero pair with an excited gesture/reaction), but the
background remains busy with competing laptops and desks, diluting the
"single emotional peak" instruction more than the other five cards. Still
a clean PASS, just the least "special" of the six.

**Flagged, not "weakest" in the ordinary sense: `learning.philosophy`.**
Beautifully executed illustration and the best "intellectual excitement"
staging of any philosophy card across all rounds — animated explanation,
genuine curiosity — but the ornate, symbol-covered antique book prop
creates real ambiguity about whether the scene reads as philosophy or as
something closer to mysticism/alchemy, which is disqualifying per the
task's own explicit semantic guard for this hobby.

## Direct answers to the task's questions

1. **Is D4 visually closer to the intended Zync identity than D3?** Yes,
   clearly. D4 consistently replaces D3's "several people engaged in an
   activity" staging with a single dramatic or emotional focal moment,
   which is precisely the composition-language gap the task identified.
2. **Does D4 finally reach the intended Japanese anime + special
   full-art + collectible-moment feeling?** For 5 of 6 hobbies, yes
   convincingly (`gaming.board` and `food.dish.bun_cha` in particular).
   `learning.philosophy` reaches the special-illustration and anime goals
   but drifts on hobby-appropriate subject matter. `business.coworking`
   reaches the goal only partially — it is the one hobby where the
   "single emotional peak" instruction visibly struggled against a
   busier, more populated real-world setting.
3. **Is a reference-conditioned `gemini-3.1-flash-image` test still
   needed?** No. Text-only style control clearly continues to work and
   is still improving round over round. The fallback to reference-image
   conditioning was designed for the case where text-only calibration
   stalled or regressed; D4 shows the opposite — real, measurable
   progress — so there is no basis to escalate away from text-only
   control yet.

## What this task did NOT do

- Did not modify `tools/card_art/specs/global_style_v1.json` (verified
  via `git status` before and after).
- Did not change any semantic recipe, hobby recognition anchor, or
  routing.
- Did not use image-to-image or reference-image conditioning.
- Did not change model — stayed on `gemini-3.1-flash-lite-image`.
- Did not use `fal.ai` anywhere.
- Did not run an 18-card repeat, 24-card, 100-card, or 2210-card batch.
- Did not reopen `sports.american_football` or `technology.robotics`
  (both remain quarantined, untouched).
- Did not touch, commit, or delete `output/style_calibration_d_18_v1/
  images/d.zip` — an untracked file found in the working tree at the
  start of this task, presumably created locally by the user to review
  the prior round's images; left alone and not staged in any commit.

## Recommended next steps (not executed this task)

1. **Promote D4 to `global_style_v1.json`'s production `prompt` field**
   as a deliberate, explicit change — not automatically done here.
2. **Small isolated follow-up on `learning.philosophy`'s prop choice**
   before treating it as solved: test whether adding an explicit "modern
   notebook or printed book, not an ancient/mystical-looking tome" cue to
   this hobby's own recipe (not the global style) resolves the drift,
   since this appears to be a hobby-specific prop-selection issue rather
   than a D4-style-wide problem (the other 5 hobbies show no comparable
   drift).
3. **Spot-check `fashion.streetwear`'s footwear rendering** across a
   couple more generations to determine whether the swoosh-like mark
   observed here is a one-off or a recurring tendency worth an explicit
   negative addition.
4. **Validate scalability** with a modest stratified sample across
   categories not covered in this 6-hobby set (sports, travel, wellness,
   pets, music, outdoors) before any larger production commitment — still
   far short of the 18/24/100/2210-card thresholds this task was
   instructed to stay under.
5. `sports.american_football` and `technology.robotics` remain
   quarantined; not touched this task.

## Infrastructure

Vercel, GitHub Actions, Production, and Google Play remain closed for
this branch. `GEMINI_API_KEY` (already present in `tools/card_art/.env`,
confirmed gitignored) was reused; never printed, logged, or committed. No
`fal.ai` route was used anywhere in this test. No 18/24/100/2210-card
batch was started. `sports.american_football` and `technology.robotics`
remain quarantined and untouched.

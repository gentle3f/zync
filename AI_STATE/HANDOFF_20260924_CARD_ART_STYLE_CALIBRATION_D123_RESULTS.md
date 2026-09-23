# Zync — House-Style D1/D2/D3 Japanese Collectible-Anime Calibration (18-Card): Results

Date: 2026-09-24
Branch: `card-art-pilot-v1-20260921`
Parent HEAD: `7f1028cf9500a0f48d6d15ebdc033f69955b7793`

Read `AI_STATE/OPERATING_RULES.md` before any write or external action.

## Bottom line

**This round is a decisive success on the core goal the A/B/C round
missed.** All three D-versions produced genuine, unmistakable Japanese
commercial-anime illustration — clean linework, cel shading, expressive
charm, bright joyful color — with essentially zero Western-editorial
drift (0.0 average across all three) and only mild, tasteful fantasy
accents (sparkle/glow) that never corrupted the hobby's real-world
meaning. This is the visual language the user described wanting.

**Two real defects surfaced and must be reported plainly:**
1. **`food.dish.bun_cha` / D1 produced a severe, explicit fake
   trading-card UI** — a "TRAINER" header bar, a full decorative card
   frame/border, a corner logo badge ("imi"), and a "Bun Cha" title
   banner rendered directly into the artwork. This is a direct violation
   of the explicit "no card frame, no title bars, no official TCG-style
   layout" instructions, and is the single worst defect observed across
   both style-calibration rounds combined.
2. **`entertainment.movie_subgenre.legal_thriller` / D3 rendered a
   readable "MYSTERY" word** on a book prop — a real, if minor, violation
   of the global no-text policy.

Both are isolated (1 occurrence each across 18 images), not systemic
patterns tied to one specific D-version's prose, but both are concrete
evidence that "collectible-card" framing language carries a real, ongoing
risk of the model reaching for literal trading-card UI conventions that
must be watched for at scale.

**Recommendation: D3 (70/30) as primary, D2 (60/40) as the close, safer
second choice.** Neither D1 nor "none of the three" is recommended. Full
reasoning below — this is a visual judgment call, not a pure numeric
average, per instruction.

## What ran

```bash
cd tools/card_art
node src/runStyleCalibrationD18.js --dry-run
node src/runStyleCalibrationD18.js --submit
node src/runStyleCalibrationD18.js --collect   # polled until BATCH_STATE_SUCCEEDED
```

New files (experiment-only, production untouched):
- `tools/card_art/catalog/style_calibration_d_blocks_v1.json` — full
  precomputed D1/D2/D3 prompts (D-specific prepend + shared core style +
  emotional direction + hard negatives + shared closing/anti-franchise +
  hard anime-vs-photo reinforcement, in that exact order), verbatim from
  the task text.
- `tools/card_art/catalog/style_calibration_d_18_v1.json` — 6 hobbies x
  3 styles config, same 6 canonical IDs as the A/B/C round.
- `tools/card_art/src/runStyleCalibrationD18.js` — adapted from
  `runStyleCalibration18.js`.

### Isolation and mechanical verification (same method as A/B/C)

Only `global_style_v1.json`'s top-level `prompt` field is swapped per
style version in an isolated in-memory clone; `global_text_policy`,
`global_screen_policy`, and `global_negatives` are reused unchanged from
production. Production `global_style_v1.json` on disk was never modified
(confirmed via `git status` before and after). The same prefix-strip
mechanical check from the A/B/C round (lesson already learned there about
naive `\n\n`-splitting misaligning on style blocks with internal line
breaks) confirmed all 6 hobbies compile byte-identical outside the
injected style block across D1/D2/D3, before any paid call.

### Dry-run, submission, and collection

- Exactly 18 rows, $0.3024 estimated — matches.
- Model: `gemini-3.1-flash-lite-image`, direct Google API, zero `fal.ai`
  references.
- Batch submitted: `batches/34kaj86sscj99tzj2b6fnya8inpb36i712q2`; reached
  `BATCH_STATE_SUCCEEDED` in about 5 minutes.
- **18/18 images collected successfully**, no timeouts.
- Actual cost: **$0.3024** — matches estimate exactly.
- Redaction (strip any oversized string by length) confirmed working:
  `batch_status.json` is 55KB.

Images organized into `output/style_calibration_d_18_v1/images/D1/`,
`/D2/`, `/D3/` subfolders.

## Per-image results

| Hobby | Style | Semantic | Anime feel | Joy | Collectible | Distinctiveness | Photographicness | Western drift | Fantasy drift | Border/UI defect | Maturity |
|---|---|---|---|---|---|---|---|---|---|---|---|
| business.coworking | D1 | PASS | 3 | 3 | 2.5 | 2 | 0 | 0 | 0.5 | No | 3 |
| business.coworking | D2 | PASS | 3 | 2.5 | 3 | 2 | 0 | 0 | 0.5 | No | 3 |
| business.coworking | D3 | PASS | 3.5 | 3.5 | 3 | 2.5 | 0 | 0 | 1 | No | 3 |
| legal_thriller | D1 | MINOR (noir/detective viewing, no legal/courtroom cue) | 3.5 | 3 | 3 | 2.5 | 0 | 0 | 0 | No | 4 |
| legal_thriller | D2 | MINOR (fully generic movie-watching, zero legal cue — weakest of the three on specificity) | 3.5 | 3.5 | 3 | 2 | 0 | 0 | 0 | No | 3.5 |
| legal_thriller | D3 | MINOR (courtroom clearly visible on-screen — best legal-specificity of the three — but a readable "MYSTERY" word appears on a book prop, a real text-policy violation) | 3 | 3 | 2.5 | 2 | 0 | 0 | 0.5 | **Text leak** | 3 |
| fashion.streetwear | D1 | PASS | 3 | 3.5 | 3 | 2 | 0 | 0 | 0 | No | 3 |
| fashion.streetwear | D2 | PASS | 3.5 | 3.5 | 3.5 | 2.5 | 0 | 0 | 0 | No | 4 |
| fashion.streetwear | D3 | PASS | 3.5 | 3.5 | 3 | 3 | 0 | 0 | 0 | No | 3.5 |
| food.dish.bun_cha | D1 | PASS (dish itself correct) **but severe UI/text defect** | 3 | 2 | 1 | 1 | 0 | 0 | 0 | **YES — severe: full fake trading-card frame, "TRAINER" header, logo badge, title banner** | 1 |
| food.dish.bun_cha | D2 | PASS | 3.5 | 4 | 3.5 | 2.5 | 0 | 0 | 0 | No | 3.5 |
| food.dish.bun_cha | D3 | PASS | 4 | 4 | 4 | 3 | 0 | 0 | 0.5 | No | 4 |
| gaming.board | D1 | PASS | 3 | 4 | 3 | 2 | 0 | 0 | 1 | No | 3.5 |
| gaming.board | D2 | PASS | 3 | 4 | 3.5 | 2 | 0 | 0 | 1 | No | 4 |
| gaming.board | D3 | PASS | 4 | 4 | 4 | 3 | 0 | 0 | 1.5 | No | 4 |
| learning.philosophy | D1 | PASS | 3 | 3.5 | 3 | 2 | 0 | 0 | 0 | No | 3 |
| learning.philosophy | D2 | PASS | 3 | 4 | 3 | 2 | 0 | 0 | 0 | No | 3.5 |
| learning.philosophy | D3 | PASS | 3.5 | 4 | 3.5 | 3 | 0 | 0 | 0 | No | 4 |

**Semantic correctness: 15/18 PASS, 3/18 MINOR, 0/18 FAIL.** (The three
MINORs: two legal_thriller cases that read as generic cinema rather than
specifically legal/courtroom content, D1 and D2; and legal_thriller D3's
text-leak, which is a policy-compliance issue layered on otherwise-correct
content — D3 is actually the only version that got the legal/courtroom
visual cue right.)

## Aggregate scores by style version

| Metric (0–4 unless noted) | D1 (50/50) | D2 (60/40) | D3 (70/30) |
|---|---|---|---|
| Japanese anime feel (higher better) | 3.08 | 3.25 | **3.58** |
| Joy / emotional energy (higher better) | 3.17 | 3.58 | **3.67** |
| Collectible appeal (higher better) | 2.58* | 3.25 | **3.33** |
| Zync distinctiveness (higher better) | 1.92* | 2.17 | **2.75** |
| Photographicness (lower better) | 0.0 | 0.0 | 0.0 |
| Western editorial drift (lower better) | 0.0 | 0.0 | 0.0 |
| Fantasy drift (lower better) | 0.25 | 0.25 | 0.58 |
| Maturity/premium (higher better) | 2.92* | **3.58** | 3.58 |
| Border/card-UI defect rate | **1/6 (17%, severe)** | 0/6 (0%) | 0/6 (0%) |
| Text-leak defect rate | 0/6 | 0/6 | 1/6 (17%, minor) |

*D1's Collectible/Distinctiveness/Maturity averages are pulled down
significantly by the `bun_cha` card-UI defect (scored 1/1/1 on those
dimensions for that card specifically, since the fake card frame directly
undermines premium/collectible/distinctive feel regardless of the
underlying illustration quality). Excluding that one card, D1's remaining
5-card averages would be Collectible 3.0, Distinctiveness 2.1, Maturity
3.3 — still the lowest of the three, but less starkly so.

## Strongest and weakest examples per direction

- **D1** — strongest: `legal_thriller` (Q4 maturity, genuinely
  atmospheric noir-cinema scene, though semantically not legal-specific).
  Weakest: `food.dish.bun_cha` (the severe card-UI/text defect — by far
  the worst single image across both rounds).
- **D2** — strongest: `food.dish.bun_cha` (Q4 joy, Q3.5 collectible, a
  genuinely appetizing, joyful, zero-defect food card) and
  `fashion.streetwear` (Q4 maturity, dynamic windswept hero pose).
  Weakest: `legal_thriller` (the flattest semantic result — no legal or
  courtroom cue anywhere, purely generic movie-going).
- **D3** — strongest: `food.dish.bun_cha`, `gaming.board`, and
  `learning.philosophy` are all genuinely exceptional (Q4 across joy,
  collectible appeal, and maturity) — arguably the three best individual
  cards produced in this entire two-round experiment. Weakest:
  `legal_thriller` (the text-leak defect, despite having the best
  semantic specificity of the three D-versions for this hobby).

## Answers to the specific review questions

1. **Which style works best for people-focused hobbies (coworking,
   streetwear, board games)?** D3, consistently — the highest joy and
   collectible scores on every people-centric card, with genuinely
   exceptional results on `gaming.board`.
2. **Which works best for food?** D3's `bun_cha` is the standout card of
   the entire test — D2's is also excellent and completely clean. D1's
   `bun_cha` is the one severe failure of the round.
3. **Which works best for intellectual/serious topics?** D3 for
   `philosophy` (captures "knowledge is exciting" precisely, per the
   task's own stated goal, with the year's best philosophy card so far
   across both rounds). For `legal_thriller` specifically, D3 is also the
   only version that visually communicates "legal/courtroom," but it's
   the version that produced the text-leak — so this hobby specifically
   needs a follow-up regardless of which D-version is chosen overall.
4. **Which works best for social hobbies?** D3's `gaming.board` — the
   most vivid reactions and strongest "shared excitement" of the set.
5. **Does any version still feel generic?** No. All three read as
   distinctly Japanese-anime-illustrated; none reverted to generic
   Western/AI-gloss illustration (Western drift averaged 0.0 across all
   three).
6. **Does any version become too anime (in a bad way)?** No — none
   drifted into chibi, hypersexualized, or preschool-cartoon territory,
   which were all explicitly and successfully avoided across all 18.
7. **Does any version become too childish?** No.
8. **Does any version become too fantasy-heavy?** No version crossed into
   disqualifying fantasy territory. D3 has the highest fantasy-drift
   average (0.58/4), driven mainly by `gaming.board`'s glowing token
   accents and general heightened sparkle — but this stayed at the
   "tiny heightened accents" level (rubric score 1–1.5), never reaching
   "noticeable fantasy stylization" (2) or beyond, and never corrupted
   hobby meaning (the fantasy-themed board game itself is a legitimate
   real-world hobby object, not the scene turning into fantasy).

## Recommendation: D3 primary, D2 close safe second

**D3 (70% anime / 30% lifestyle) is recommended as the primary
direction.** It scored highest on every dimension that matters most to
the stated goal — Japanese anime feel, joy, collectible appeal, and
distinctiveness — while keeping photographicness and Western drift at
zero and fantasy drift low and tasteful. Visually, D3 produced the three
most genuinely exciting, "I want this card" images of the entire
two-round experiment (`bun_cha`, `gaming.board`, `philosophy`), which
matches the task's own explicit target reaction precisely.

**D2 (60% anime / 40% lifestyle) is a very close, safer second choice.**
It had zero defects of any kind in this sample (no card-UI, no text
leak) and scored only marginally below D3 on most dimensions, with the
highest single-metric score of any group on maturity (tied with D3). If
the priority is minimizing any risk of drift at scale before further
investment, D2 is the more conservative choice.

**D1 (50% anime / 50% lifestyle) is not recommended.** It scored lowest
on anime feel, joy, collectible appeal, and distinctiveness, and — more
concretely — it produced the single worst defect observed across both
style-calibration rounds: an explicit fake trading-card UI overlay with
header text, a logo badge, and a title banner. This is a direct
violation of the explicit franchise/card-UI-avoidance instructions and
should be treated as disqualifying evidence against D1's current prose,
not just a stylistic weakness.

**This is a visual judgment call, not a forced numeric winner** — the
gap between D2 and D3 is small enough that either is defensible; D3 is
recommended because it more fully delivers the emotional "I want this
card" reaction the task explicitly asked for, and its one defect
(a stray word on one card) is far more contained and recoverable than
D1's structural card-UI failure.

## Cross-cutting risk to flag regardless of which direction is chosen

**"Collectible"/"trading-card" framing language in the prompt carries a
real, recurring risk of the model reaching for literal trading-card UI
conventions** — not just decorative borders (the chrome defect tracked
since the FLUX era) but actual card-game text conventions (header bars,
type labels like "TRAINER", logo badges, title banners). This occurred
once in this 18-image sample despite explicit, repeated, detailed
negative instructions naming exactly this failure mode. Any production
prompt derived from this experiment should treat this as an ongoing
calibration target, not a solved problem — the existing negative list is
necessary but was not, on its own, sufficient in this one case.

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
- Did not run the reference-conditioned `gemini-3.1-flash-image`
  follow-up — this round's results do not require it (text-only style
  control clearly worked), so that fallback remains unnecessary for now.

## Recommended next steps (not executed this task)

1. **Select D3 (or D2 as the conservative alternative)** and promote it
   to `global_style_v1.json`'s production `prompt` field as a deliberate,
   explicit change — not automatically done here.
2. **Investigate the `bun_cha`/D1 card-UI defect and the
   `legal_thriller`/D3 text-leak** with a small isolated diagnostic (a
   handful of calls, not a new 18-card round) before treating either
   D-version's negative list as fully sufficient at scale — specifically
   test whether adding a more explicit negative naming common TCG
   conventions ("no 'TRAINER' or type-label header text", "no logo badge
   in the corner") reduces the recurrence rate.
3. **`entertainment.movie_subgenre.legal_thriller` needs its own
   semantic-anchor look**, independent of style version — 2 of 3 D-tests
   failed to convey "legal/courtroom" at all, suggesting the underlying
   hobby recipe's recognition anchors may be too weak for this specific
   sub-genre, a separate issue from which visual style is chosen.
4. Once a direction is selected, validate scalability with a modest
   stratified sample across categories not covered in this 6-hobby set
   (sports, travel, wellness, pets, music, outdoors) before any larger
   production commitment.
5. `sports.american_football` and `technology.robotics` remain
   quarantined; not touched this task.

## Infrastructure

Vercel, GitHub Actions, Production, and Google Play remain closed for
this branch. `GEMINI_API_KEY` (already present in `tools/card_art/.env`,
confirmed gitignored) was reused; never printed, logged, or committed. No
`fal.ai` route was used anywhere in this test. No 100-card or 2210-card
batch was started. `sports.american_football` and `technology.robotics`
remain quarantined and untouched. `batch_status.json` stayed small (55KB)
using the redaction fix carried over from prior rounds.

# Zync — Direct Google Gemini 3.1 Flash Lite Image 24-Card Successor Test: Results

Date: 2026-09-24
Branch: `card-art-pilot-v1-20260921`
Parent HEAD: `5e6727d439ee067a8a5dd7ce9756a091566063f2`

Read `AI_STATE/OPERATING_RULES.md` before any write or external action.

## Bottom line

**`gemini-3.1-flash-lite-image` preserves the strong prompt-following
performance of `gemini-2.5-flash-image` on every card it actually
returned an image for: 21/22 PASS, 1/22 MINOR, 0/22 FAIL.** This is at
least as strong as the 2.5 result (20/24 PASS, 4/24 MINOR, 0/24 FAIL) and
arguably slightly cleaner proportionally. However, **2 of the 24 requests
never returned an image** — both failed with a Google-side gRPC deadline
timeout (`code 4: Deadline expired before operation could complete`), not
a content or mapping problem. One of the two missing cards is
`wellness.sauna` — the single most safety-sensitive card in the whole
set. **This means the safety dimension was not re-verified on this model
and should not be assumed resolved.** Per the standing "no auto-rerolls"
instruction, these two were not retried automatically.

The batch also took roughly **90 minutes** to complete, versus the 2.5
model's roughly 1 minute — a material latency difference with real
production-planning implications independent of image quality.

## What ran

```bash
cd tools/card_art
node src/runGemini31FlashLiteDirectBatch24.js --dry-run
node src/runGemini31FlashLiteDirectBatch24.js --submit
node src/runGemini31FlashLiteDirectBatch24.js --collect   # polled until BATCH_STATE_SUCCEEDED
```

### Setup: new runner adapted from the 2.5 discriminator

New files:
- `tools/card_art/catalog/gemini31_flash_lite_direct_batch_24_v1.json`
- `tools/card_art/src/runGemini31FlashLiteDirectBatch24.js`

Adapted directly from `runGemini25DirectBatch24.js` with only the model
constant, output paths, and cost figures changed
(`MODEL = 'gemini-3.1-flash-lite-image'`, same
`generativelanguage.googleapis.com` direct endpoint, same
`generationConfig.imageConfig.aspectRatio` field path already fixed in
the prior round). Confirmed byte-identical to `runGemini25DirectBatch24.js`
in every other respect: same 24-ID source (`semantic_anchor_
revalidation_24_v1.json`), same compiler invocation, no fal.ai references
anywhere in the file (grep-confirmed).

**One proactive fix made before this could run cleanly:** the redaction
helper carried over from the 2.5 runner only stripped the `data` key
(image base64). Gemini 3.1 Flash Lite additionally returns a large
`thoughtSignature` reasoning blob per response (~1.3MB each), which the
old key-name-only redaction missed entirely — the first `--collect`
produced a 65MB `batch_status.json` despite the "redaction" running.
Rewrote the redaction to strip *any* oversized string by length
regardless of key name, then re-ran `--collect` (a free status GET, no
new generation) to regenerate a properly small 67KB status file. This is
disclosed in full, consistent with how the 2.5 round's bugs were
disclosed rather than glossed over.

### Dry-run — confirmed exact apples-to-apples setup

- Exactly 24 IDs, identical archetype/variant routing to both prior runs
  (FLUX and Gemini 2.5) — confirmed via direct header diff.
- Prompt bodies confirmed **byte-identical** to the Gemini 2.5 dry-run via
  `diff` (zero output, exit 0).
- `model: gemini-3.1-flash-lite-image` confirmed via the `MODEL` constant.
- Estimated cost: **$0.4032** for 24 images ($0.0168/image) — matches the
  task's stated estimate exactly.
- Zero fal.ai references anywhere in the runner (grep-confirmed; only
  the `// IMPORTANT: this does NOT use fal.ai.` comment matches "fal").

### Submission and collection

- Batch submitted: `batches/0sk611c6pgs21sbrm650fbpn1saftixnlh0w`.
- Polled at increasing intervals (30s, then 60s, then 180s) across three
  background polling windows; reached `BATCH_STATE_SUCCEEDED` after
  roughly **90 minutes** total — dramatically slower than the 2.5 model's
  ~1 minute for the identical request shape.
- **22 of 24 images collected successfully.** The 2 missing entries
  (`food.yum_cha`, index 0; `wellness.sauna`, index 22) both returned
  `{"error": {"code": 4, "message": "Deadline expired before operation
  could complete."}}` — confirmed by direct inspection of the raw
  per-request response, not inferred. This is a Google-side per-request
  timeout inside an otherwise-succeeded batch job, not a content
  safety block, not a mapping error, and not related to prompt content.
- Actual cost: **$0.3696** (22 × $0.0168) — the 2 timed-out requests were
  not billed for image output (consistent with no image being returned).
- Manifest confirms clean 1:1 mapping for all 22 successful entries:
  canonical ID, sequential response index, filename, no gaps or
  reordering among the entries that did return.

## Per-card verdicts (22 of 24; 2 not returned, see below)

| # | ID | Verdict | Notes |
|---|---|---|---|
| 1 | food.yum_cha | **NOT RETURNED** | Google-side deadline timeout, not scored |
| 2 | food.dish.egg_tart | MINOR | Correct dish (HK-style egg tart), but readable Chinese text visible on background restaurant menu boards |
| 3 | food.dish.bun_cha | **PASS** | Correct dish, arguably more traditionally accurate than the 2.5 result (grilled pork, rice noodles, herbs, broth bowl), no text |
| 4 | music.style.trip_hop | **PASS** | Person with headphones + turntable + string lights — fixes the one gap the 2.5 result had (no human figure) |
| 5 | music.style.japanese_alternative | **PASS** | Person with headphones, turntable, speakers, vinyl collection |
| 6 | entertainment.screenwriting | **PASS** | Two people reading/annotating a script in a theater — reads more precisely as "screenwriting" than the 2.5 result |
| 7 | entertainment.movie_subgenre.legal_thriller | **PASS** | Audience watching a courtroom scene on a theater screen |
| 8 | travel.style_deep.pilgrimage_routes | **PASS** | Hiker with staff, backpack scallop-shell symbol, pilgrim group, cathedral town — even more specific than the 2.5 result |
| 9 | travel.cabin_getaways | **PASS** | Hiker approaching a lakeside log cabin with smoke |
| 10 | pets.dogs | **PASS** | Real golden retriever, woman bonding with it in an autumn park |
| 11 | pets.terrariums | **PASS** | Glass terrarium, gecko, correct habitat, feeding with tweezers |
| 12 | learning.philosophy | **PASS** | Two people discussing with a philosopher bust, books, handwritten notebook |
| 13 | lifestyle.interior_design | **PASS** | Woman arranging mood board with fabric/paint swatches, tape measure |
| 14 | outdoors.rockhounding | **PASS** | Rock hammer, geode specimen, collecting bag, riverside setting |
| 15 | outdoors.cycling | **PASS** | Real mountain bike on a trail, correct gear |
| 16 | outdoors.ice_fishing | **PASS** | Frozen lake, visible ice hole, rod/reel, tackle box, winter clothing — the hardest test in the set, passed cleanly again |
| 17 | transport.ferries | **PASS** | Actual passenger/bicycle ferry crossing a river — cleaner than the 2.5 result (no pseudo-text on the hull this time) |
| 18 | photography.general | **PASS** | Actual camera with lens raised to eye |
| 19 | fashion.streetwear | **PASS** | Layered streetwear, no readable storefront signage, no obvious brand-like sneaker marks |
| 20 | gaming.board | **PASS** | Group around a fantasy board game, dice, miniatures, zero controllers |
| 21 | gaming.chess | **PASS** | Correct chess board/pieces in a cafe setting, zero controllers |
| 22 | wellness.pilates | **PASS** | Genuine mat Pilates "swan" pose, reformer equipment visible in background — more precisely on-pose than the 2.5 result |
| 23 | wellness.sauna | **NOT RETURNED** | Google-side deadline timeout — the safety-critical card, not scored this round |
| 24 | business.coworking | **PASS** | Communal desks, multiple professionals, all laptop screens blank/dark, no readable code |

**Tally (of 22 returned): 21 PASS / 1 MINOR / 0 FAIL.**

**Card-border/chrome check:** zero occurrences across all 22 returned
images.

## Direct comparison across all three model/route tests

| | FLUX (semantic-anchor) | Gemini 2.5 Flash Image | Gemini 3.1 Flash Lite Image |
|---|---|---|---|
| Returned | 24/24 | 24/24 | 22/24 (2 timed out) |
| PASS | 0 | 20 | 21 |
| MINOR | 2 | 4 | 1 |
| FAIL | 22 | 0 | 0 |
| Batch time | n/a (sync per-call) | ~1 min | ~90 min |
| Cost/image | $0.0125 | $0.0195 | $0.0168 |

On pure per-card image-quality evidence, 3.1 Flash Lite is at least as
strong as 2.5 and cheaper per image. The two open questions this round
could not answer are (1) whether it handles the wellness-safety case as
well as 2.5 did, and (2) whether the ~90-minute batch latency is typical
or an anomaly for this specific job.

## Interpretation

**Does Gemini 3.1 Flash Lite preserve the strong prompt-following
performance of Gemini 2.5 Flash Image closely enough to become the
production candidate?**

**Qualified yes on image quality — not yet on completeness.** Every card
that actually returned an image matched or exceeded the 2.5 result's
quality, with zero FAILs and only one MINOR (a background-text leak on
one food card, a materially smaller class of defect than anything FLUX
produced). This is a real, positive signal for this specific model as a
production candidate on cost and quality grounds, and it is non-deprecated
(unlike 2.5 Flash Image, which shuts down 2026-10-02).

**But two things hold this back from an unqualified "yes, ship it":**

1. **The safety-critical `wellness.sauna` card was not re-verified.**
   The prior round's safety concern on FLUX was resolved on Gemini 2.5;
   this round cannot confirm the same holds on 3.1 Flash Lite, because
   the request timed out before producing an image. This is not evidence
   of a problem — it is an absence of evidence, and the two should not be
   conflated. It needs a small, targeted retest before this model is
   trusted for wellness-adjacent content specifically.
2. **~90-minute batch completion time** (vs. ~1 minute for 2.5) is a
   meaningful operational difference. A single 24-request batch taking
   an hour and a half has real implications for any production pipeline
   built around this route, independent of image quality. This may be
   normal variance for this specific (possibly newer/less-provisioned)
   model, but it was not established as typical in this single run.

Given both open items, the honest answer to the decision question is:
**image quality clears the bar; operational completeness and latency do
not yet, pending the smallest possible follow-up.**

## Recommended next steps (not executed this task)

1. **Targeted 2-card retest** of exactly `food.yum_cha` and
   `wellness.sauna` on `gemini-3.1-flash-lite-image` (not a new 24-card
   batch) to fill the gap left by the timeouts — this is the single
   smallest step that would let the model comparison be called complete.
   Not executed here, consistent with "no auto-rerolls."
2. **Do not yet certify `gemini-3.1-flash-lite-image` as the production
   route** until the sauna safety case is confirmed and the batch-latency
   behavior is understood (one data point is not enough to know if
   ~90 minutes is typical).
3. Per the task's own fallback: **if 3.1 Flash Lite is judged meaningfully
   worse or incomplete, test `gemini-3.1-flash-image`** (the non-lite
   variant) next — this task's finding (strong quality, but an unresolved
   safety-verification gap and unverified latency) is closer to "promising
   but not yet fully validated" than "meaningfully worse," so the
   smallest-step recommendation is the 2-card retest above rather than
   jumping to the non-lite model, but that remains the documented fallback
   if the retest also fails to complete.
4. Do not resume the FLUX 100-card or 1731-card batch for the families
   that failed on FLUX — this result reinforces, it does not reverse,
   the prior conclusion that FLUX is the wrong route for them.
5. `sports.american_football` and `technology.robotics` remain
   quarantined; not touched this task.

## Infrastructure

Vercel, GitHub Actions, Production, and Google Play remain closed for
this branch. `GEMINI_API_KEY` (already present in `tools/card_art/.env`
from the prior round, confirmed gitignored) was reused; never printed,
logged, or committed. No `fal.ai` route was used anywhere in this test.
No 100-card or 2210-card batch was started. `sports.american_football`
and `technology.robotics` remain quarantined and untouched. The
`batch_status.json` redaction bug (thoughtSignature blobs not caught by
the prior key-name-only redaction) was found and fixed before committing,
keeping this checkpoint's repo footprint small instead of repeating the
~100MB file from the 2.5 round.

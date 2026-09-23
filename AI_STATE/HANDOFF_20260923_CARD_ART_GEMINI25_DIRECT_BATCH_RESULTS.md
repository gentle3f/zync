# Zync — Direct Google Gemini 2.5 Flash Image 24-Card Discriminator: Results

Date: 2026-09-23
Branch: `card-art-pilot-v1-20260921`
Parent HEAD: `4a211c10882456469845506a7ec39e8af5225e14`

Read `AI_STATE/OPERATING_RULES.md` before any write or external action.

## Bottom line

**Gemini follows the exact same prompts that failed on FLUX substantially
better. 20/24 PASS, 4/24 MINOR, 0/24 FAIL** — a complete reversal of the
FLUX semantic-anchor run's 0/24 PASS, 2/24 MINOR, 22/24 FAIL on the
identical 24 canonical interests and identical compiled prompts. This is
strong, direct evidence that the dominant failure mode characterized
across this whole remediation arc (camera/gadget/controller intrusion,
wrong-specific-instance substitution, readable code/UI screens) is a
**FLUX/model-route problem, not a prompt-content problem.** The semantic
anchor architecture built in the prior checkpoint was correct; it was
being executed by the wrong model.

Two real script bugs were found and fixed before this test could run at
all (see below) — this was a genuine execution blocker, not a design
choice, and is disclosed in full per the audit protocol.

## What ran

```bash
cd tools/card_art
node src/runGemini25DirectBatch24.js --dry-run
node src/runGemini25DirectBatch24.js --submit
node src/runGemini25DirectBatch24.js --collect   # polled until BATCH_STATE_SUCCEEDED
```

### GEMINI_API_KEY

Not present locally (neither shell env nor `tools/card_art/.env`, which
only had `FAL_KEY`). Per instruction, asked the user directly rather than
guessing or proceeding without it. The user supplied the key; it was
written to `tools/card_art/.env` (confirmed gitignored before and after)
and never printed, logged, or echoed at any point in this session.

### Two execution-blocking bugs found and fixed

1. **Missing `dotenv/config` import.** The runner never loaded `.env` at
   all (unlike the existing FLUX runner `generateCompiledBatch.js`, which
   does), so `GEMINI_API_KEY` was invisible even once set correctly.
   Fixed by adding the same `import 'dotenv/config';` line used
   elsewhere in this codebase.
2. **Wrong request field path for `aspectRatio`.** The script sent
   `generationConfig.responseFormat.image.aspectRatio`, which the
   Gemini API rejected with `HTTP 400` on all 24 requests
   (`Invalid value ... ImageResponseFormat.AspectRatio ... "2:3"`).
   Investigated the actual `google.ai.generativelanguage.v1beta` proto
   directly (not guessed): there is no `ImageResponseFormat` message in
   the real schema at all. The correct field is
   `generationConfig.imageConfig.aspectRatio` (a plain string, and
   `"2:3"` is explicitly documented as a supported value there). Fixed
   the field path accordingly; the corrected dry-run and submission both
   succeeded immediately.
3. **Batch-status field/state-name mismatch** (found and fixed
   proactively before the job could complete, not from a failure): the
   collector checked `status.state`/`status.batch.state` for
   `JOB_STATE_SUCCEEDED`, but the actual response nests state under
   `status.metadata.state` and uses `BATCH_STATE_*` naming
   (`BATCH_STATE_RUNNING` → `BATCH_STATE_SUCCEEDED`), confirmed directly
   from the real API response. Fixed the state check to look in both
   places and accept both naming conventions, and added a defensive
   `status.response...` fallback path to `findInlineResponses()` (the
   `metadata`/`response` nesting pattern strongly suggested the
   completed payload would land there) — this fallback path was not
   exercised in practice since `status.dest.inlinedResponses` (one of
   the pre-existing paths) turned out to be where the real response
   landed, but it is a safe, non-breaking addition.

None of these fixes touched prompt content, model choice, or routing —
strictly plumbing/schema-compatibility fixes required to make the
already-correct experiment design actually run.

### Dry-run — confirmed exact apples-to-apples setup

- Exactly 24 IDs, identical to `semantic_anchor_revalidation_24_v1.json`
  (the failed FLUX set) — confirmed by direct diff of headers.
- Compiled prompt text confirmed byte-identical to the FLUX run's
  prompts (same compiler, same specs, same repo state — only the
  destination endpoint differs).
- `model: gemini-2.5-flash-image` confirmed via `const MODEL =
  'gemini-2.5-flash-image'` in the runner source.
- `provider: 'Google Gemini API direct'` explicitly labeled at every
  manifest-writing call site.
- Endpoint confirmed as `generativelanguage.googleapis.com` (direct
  Google) — zero `fal-ai`/`fal.ai` references anywhere in the runner
  file.

### Submission and collection

- Batch submitted: `batches/z8z1iuk17zqvkqm1mk15jdhcjjuxplovlr7e`.
- Polled every 30s in a background task; reached `BATCH_STATE_SUCCEEDED`
  after 2 polling attempts (well under a minute of actual processing
  time).
- Collected 24/24 images successfully, no missing responses, no
  extraction failures.
- Manifest confirms: 24 entries, all `image_written: true`, sequential
  `response_index` 0–23 matching submission order, filenames built from
  canonical ID, total estimated cost **$0.468** — matches the $0.0195 ×
  24 estimate exactly (input token charges not separately itemized but
  expected to be small per the original estimate).

### Prompt-to-image mapping verification

Cross-checked canonical ID, response index, and filename for all 24
manifest entries before opening any image — confirmed a clean 1:1
sequential mapping with no gaps, duplicates, or reordering. No mapping
forensics were needed; the mapping was correct from submission through
collection.

## Per-card verdicts (Gemini vs. FLUX, same prompt)

| # | ID | Gemini verdict | FLUX verdict (for reference) |
|---|---|---|---|
| 1 | food.yum_cha | **PASS** — real bamboo-steamer dim sum, chopsticks, teapot, correct dish family | MINOR (generic stir-fry, camera present) |
| 2 | food.dish.egg_tart | **PASS** — exact correct dish, correct texture/form | FAIL (wrong dish) |
| 3 | food.dish.bun_cha | MINOR — correct ingredients (grilled pork, rice noodles, herbs) in a bowl-soup presentation rather than classic dipping style | FAIL (wrong dish + controller) |
| 4 | music.style.trip_hop | MINOR — perfect physical-audio scene (turntable, speakers) but no human figure present | FAIL (code screen) |
| 5 | music.style.japanese_alternative | **PASS** — person with headphones, turntable, speakers, zero screens | FAIL (severe code screens) |
| 6 | entertainment.screenwriting | MINOR — excellent cinema/discussion scene, thematically adjacent rather than exact | FAIL (severe screen soup, worse than FLUX 100-card run) |
| 7 | entertainment.movie_subgenre.legal_thriller | **PASS** — courtroom-stage cultural viewing scene, scales-of-justice prop, zero screens | FAIL (worst screen soup in the whole set) |
| 8 | travel.style_deep.pilgrimage_routes | **PASS** — hiker with staff and pilgrim group walking toward a cathedral town, exact concept match | MINOR (clean but generic travel photography) |
| 9 | travel.cabin_getaways | **PASS** — hiker approaching a lakeside cabin with smoke and dock | FAIL (wrong content, coastal city/train) |
| 10 | pets.dogs | **PASS** — real golden retriever puppy, woman with rope toy | FAIL (rodents/rabbits + game controller) |
| 11 | pets.terrariums | **PASS** — glass terrarium, tree frog, moss/ferns, correct habitat | FAIL (wildlife forest scene + gadgets) |
| 12 | learning.philosophy | **PASS** — two people discussing with a philosopher bust, books, scale, abacus | FAIL (laptop with code + controller) |
| 13 | lifestyle.interior_design | **PASS** — family measuring/decorating a living room, tape measure, swatches, ladder | FAIL (controller + code laptop) |
| 14 | outdoors.rockhounding | **PASS** — person examining mineral specimens with tools at a canyon | FAIL (campfire/tent scene) |
| 15 | outdoors.cycling | **PASS** — real mountain bike on a forest trail | FAIL (skis, no bike) |
| 16 | outdoors.ice_fishing | **PASS** — frozen lake, visible ice hole, winter gear, no open water | FAIL (paddleboarding, the most detailed anchor in the set) |
| 17 | transport.ferries | MINOR — correct ferry vessel with loaded cars, but faint illegible pseudo-text on the hull | FAIL (car in a workshop) |
| 18 | photography.general | **PASS** — actual camera with lens, hands composing a shot | FAIL (binoculars, even in this manual recipe) |
| 19 | fashion.streetwear | **PASS** — layered streetwear, generic sneakers, no readable signage | FAIL (readable neon storefront text) |
| 20 | gaming.board | **PASS** — group around a fantasy board game, dice, miniatures, zero controllers | FAIL (video-game controllers, even in this manual recipe) |
| 21 | gaming.chess | **PASS** — correct chess board and pieces, zero controllers/cameras | FAIL (wrong game + controller/camera present) |
| 22 | wellness.pilates | **PASS** — genuine standing exercise pose, reformer equipment visible in background | FAIL (gadgets/code, no exercise at all) |
| 23 | wellness.sauna | **PASS — safety confirmed** — modest full-length towel wrap, genuine wood-paneled sauna with heater/coals, snowy outdoor view, no domestic-bathtub framing | FAIL — safety risk (bare-shoulder bathtub-adjacent framing) |
| 24 | business.coworking | **PASS** — communal desks, multiple professionals, all screens blank/dark/unreadable | FAIL (multiple readable code screens) |

**Tally: 20 PASS / 4 MINOR / 0 FAIL.**

**Card-border/chrome check:** zero occurrences across all 24 images —
every card is full-bleed with no rounded frame, white margin, or mat.

## Interpretation

Per the task's own decision rule: **Gemini follows these exact prompts
substantially better than FLUX. This shifts the evidence strongly toward
a FLUX/model-route problem rather than deficient prompt semantics.**

This is not a case requiring the "audit shared compiler/request mapping"
branch of the decision rule — Gemini did *not* reproduce the same bizarre
substitutions. The prompt-to-image mapping was independently verified
clean before any visual inspection, and the same compiled prompt text
that produced 22 FAILs on FLUX produced 0 FAILs on Gemini. The two script
bugs found and fixed were pure API-schema plumbing issues (wrong field
path, wrong status field), entirely unrelated to content generation or
prompt semantics, and are fully disclosed above rather than glossed over.

The four MINOR results are genuinely minor and of a completely different
character than FLUX's failures: a missing human figure in an otherwise
perfect physical-audio scene, a non-traditional-but-ingredient-correct
dish presentation, a thematically-adjacent-but-clean cultural scene, and
faint illegible pseudo-text on a ship hull. None of these are the
"generic gadget / unrelated hobby / code-screen" failure class that
dominated the FLUX results.

## Important caveats

1. **`gemini-2.5-flash-image` is scheduled for shutdown by Google on
   2026-10-02.** This result is a strong diagnostic signal about model
   routing, not evidence that this specific model is a viable long-term
   production dependency. Any production decision needs to account for
   this model's imminent end-of-life.
2. **This is a 24-card sample, not production certification** — same
   caveat that applied to the FLUX semantic-anchor round. A single clean
   run should not be read as guaranteeing the same result at scale,
   though the contrast with FLUX's same-prompt failure is large enough
   to be a meaningful signal rather than noise.
3. **Cost and API shape differ from the FLUX pipeline** — Batch API
   image-output pricing ($0.0195/image) is roughly 56% higher than the
   FLUX Standard estimate ($0.0125/image) used throughout this arc, and
   the request/response schema is materially different (proto-backed
   Gemini API vs. FLUX's REST schema), which has integration implications
   independent of image quality.

## Recommended next steps (not executed this task)

1. **Do not treat this as production migration.** This is diagnostic
   evidence that the failure class is model-route-specific, not proof
   that Gemini 2.5 Flash Image should become the production pipeline —
   especially given its scheduled shutdown.
2. **If a newer, non-deprecated Gemini/Google image model is available
   for production use, that would be the natural next small experiment** —
   repeat this same 24-card apples-to-apples comparison against a
   production-viable Google model before making any routing decision.
3. **Do not run the semantic-anchor-covered 100-card or 1731-card FLUX
   batch** — this result does not rehabilitate FLUX for the families that
   failed; it points away from continuing to invest in FLUX for them.
4. **Do not immediately reroute the whole catalog to Gemini** without
   first confirming API cost/rate-limit/production-suitability
   characteristics at a larger sample size, and without resolving the
   shutdown-date constraint.
5. `sports.american_football` and `technology.robotics` remain
   quarantined; not touched this task (this test only used the 24
   non-quarantined IDs already in the semantic-anchor set).

## Infrastructure

Vercel, GitHub Actions, Production, and Google Play remain closed for
this branch. `GEMINI_API_KEY` was added to `tools/card_art/.env`
(confirmed gitignored) and never printed, logged, or committed. No
`fal.ai` route was used for this Image 2.5-adjacent test, per instruction.
No 100-card or 1731-card batch was started. `sports.american_football`
and `technology.robotics` remain quarantined and untouched.

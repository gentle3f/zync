# Zync Card Art — Production Batch 1 of 19 — Results

Branch: `card-art-pilot-v1-20260921`
Date: 2026-09-24
Provider: Google Gemini API direct (`gemini-3.1-flash-lite-image`, Batch API). No fal.ai.

**This was the first real, explicitly user-authorized production batch.**
Exactly one batch (120 requests) was submitted. Batches 2–19 were NOT
submitted and remain locked out for this session (`runProductionBatch.js`
hard-fails on any `--batch` value other than `1`).

## Step 1 — Production runner

New file: `tools/card_art/src/runProductionBatch.js` (`--dry-run` /
`--submit` / `--collect`, `--batch=N` required, hard-authorization-locked
to `AUTHORIZED_BATCH_NUMBERS = new Set([1])`). It reads
`catalog/production_queue_v1.json` and `catalog/production_batch_plan_v1.json`
rather than building an ad-hoc selection, recompiles each prompt with the
real production compiler, and cross-checks the recompiled `prompt_sha256`
against the committed queue's fingerprint before submitting - refusing to
proceed if the queue is stale relative to current specs/overrides.

### Engineering fix required mid-task: oversized batch-status response

The first `--collect` attempt crashed with `RangeError [ERR_STRING_TOO_LONG]:
Cannot create a string longer than 0x1fffffe8 characters`. Root cause: a
120-request batch status response is large enough (inline base64 image +
thoughtSignature data for every request, duplicated by Google under both
`metadata.output.inlinedResponses` and `response.inlinedResponses`) to
exceed Node/V8's ~512MB max string length when read via `res.text()` -
this had not been hit at 8/12-image scale in prior rounds.

Fix: added `stream-json`/`stream-chain` as a local dependency of
`tools/card_art` (`package.json`/`package-lock.json` updated; `npm audit`
shows one pre-existing high-severity advisory in `sharp`, unrelated to
this change and not touched). The response body is now streamed straight
to a scratch file in the OS temp directory (never materialized as one JS
string), then processed in two token-streaming passes: one that strips
every `inlinedResponses` subtree entirely (yielding a small metadata-only
summary - exactly what gets persisted as `batch_status.json`, so no raw
base64/thoughtSignature ever touches a committed file), and one that
streams `response.inlinedResponses.inlinedResponses` items one at a time
so memory stays bounded to a single request's payload rather than all 120
at once. Verified against a synthetic ~458MB mock status file before
touching the real API (120 items streamed correctly, peak RSS ~166MB).
This fix is permanent in the runner and will be needed for every future
batch of this size.

## Step 2 — Dry-run evidence (zero cost)

```
Dry run: production batch 1 (zync-prod-batch-001), 120 entries.
Estimated image-output cost: $2.0160 (plus small input-token charges).
Unique ids: OK (no duplicates)
```

Additional programmatic checks (all passed before any submission):
all 120 ids are non-quarantined and `status=pending` for `batch_number=1`
in the queue; zero quarantined ids present; all 120 `output_filename`s
unique; estimated cost `$2.0160` = 120 × $0.0168.

## Step 3 — Submission and collection

Batch: `batches/j8lhmaml202kkcizp9t7z0nz7176nf1yklf8`. **120/120 succeeded,
0 failed_transient, 0 failed_content.** Actual cost: **$2.016** (120 ×
$0.0168, Batch API image-output pricing; Google's batch status response
did not expose a separate actual-billing field beyond `batchStats`, so
this is the pricing-based actual cost, consistent with every prior round).

No retries were needed - there is no failure-only retry list to report
for this batch.

## Step 4 — Layer-1 automated QA

`tools/card_art/src/qaLayer1ProductionBatch.js --batch=1` -
`tools/card_art/output/production_batch_001_v1/qa_layer1_automated_v1.json`:

```
[PASS] manifest_expected_entries_matches_batch_plan_size - entries=120
[PASS] no_missing_images_for_succeeded_entries - checked=120
[PASS] no_suspiciously_tiny_or_corrupt_files - min_bytes_floor=20000
[PASS] no_duplicate_file_hashes - unique_hashes=120
[PASS] expected_2_3_aspect_ratio - checked=120 distinct_dimensions=848x1264
[PASS] manifest_id_prompt_filename_mapping_matches_queue - checked=120
[PASS] output_filenames_unique_on_disk - files=120
[PASS] no_quarantined_interests_in_batch - clean
[PASS] cost_accounting_consistent - succeeded=120 estimated_cost_usd=$2.016
[PASS] success_failure_counts_reported - succeeded=120 failed_transient=0 failed_content=0

10/10 checks passed
```

## Step 5 — Full human QA of all 120 images (no sampling)

Full results: `tools/card_art/output/production_batch_001_v1/qa_layer2_human_review_v1.json`.

**Semantic correctness: 120/120 PASS.** Zero wrong-hobby substitutions,
zero semantic FAILs, zero MINORs. **Border/UI leak: 0/120. Safety
concern: 0/120.** D4 style fidelity and special-illustration quality were
consistently strong across the batch - the house style holds up at
production scale.

### Aggregate defect counts (120 images)

| Dimension | Count | Rate |
|---|---|---|
| Brand/trademark leak | 8 | 6.7% |
| Text leak | 29 | 24.2% |
| Screen-policy leak | 6 | 5.0% |
| Border/UI leak | 0 | 0% |
| Safety concern | 0 | 0% |
| Anatomy/object corruption | 1 | 0.8% |

### The dominant finding: business category text leak (systemic cluster)

**15 of 30 `business.*` cards (50.0%) render clearly readable
diagram/whiteboard/kanban/flip-chart text**, e.g. `business.career_development`
("SKILL DEVELOPMENT", "GOAL"), `business.career_switching` ("SKILLS" x4,
"COMPANY", "BUSINESS"), `business.design_thinking` ("Empathy Map",
"Ideation Cluster"), `business.financial_independence` ("BUSINESS GROWTH
MILESTONES", "REVENUE STREAMS"), `business.product_management` ("Backlog",
"Doing", "Validation", "Done"), `business.project_management`
("INITIATION", "PLANNING", "EXECUTION", "MONITORING"), and
`business.index_investing` (the real trademarked term **"S&P 500"** -
simultaneously a text leak and a trademark leak). This is narrowly scoped
to one `runtime_category` with a clear, singular likely cause: the
business category's "concept diagram / kanban board / planning board"
recognition-anchor language leads the model to add literal English labels
instead of abstract non-linguistic diagram marks - the same class of gap
already fixed at the individual-hobby level for `lifestyle.game_nights`
and `learning.philosophy`, but never addressed at the category level.
By contrast, the `arts` category shows a text-leak rate of 15.7% (14/89),
concentrated in three distinct sub-causes (calligraphy-family background
scrolls, urban-night-scene signage, creator-tool screen UI chrome) rather
than one dominant pattern, and `books.reading` (fixed last round) was
**completely clean**, confirming that fix holds in real production output.

### Second finding: device-logo brand leak (Apple)

Two images (`business.coworking`, `business.no_code`) show a **clearly
recognizable real Apple logo** on a laptop/tablet lid - an unambiguous
trademark leak, more severe than any silhouette-level residual risk seen
before. `global_brand_safety_policy` already explicitly names "consumer
electronics and devices" as required to be unbranded; this confirms the
policy text alone is not reliably followed by the model for this specific
device-logo case, the same lesson already learned once for footwear
silhouettes (`fashion.streetwear`, `sports.skateboarding`). One more
footwear-silhouette echo was found outside those two fixed hobbies
(`arts.kpop_dance`), plus two design-tool-brand echoes (`arts.graphic_design`'s
Pantone-style swatch book, `arts.urban_sketching`'s branded marker labels).

### Third, minor finding: repeated protagonist face

A specific "long dark-haired, angular-jawed, serious male" presentation
recurs across roughly 7 male-led/object-led cards (e.g.
`arts.newsletter_writing`, `arts.podcasting`, `books.reading`,
`business.consulting`, `business.finance`, `business.remote_work`) despite
the deterministic diversity layer assigning genuinely different age/hair/
build dimensions to each of these hobbies (confirmed via the catalog-wide
distribution check in the prior round). This indicates the underlying
model has a rendering prior toward one archetype that current diversity
phrasing doesn't fully override for that specific combination - a tuning
opportunity, not a defect in the deterministic assignment mechanism
itself, and the batch overall shows clearly successful diversity elsewhere
(grey/silver hair, curly/coily hair and darker skin tones, broader/sturdier
builds without caricature, buzzed cuts across genders, older-adult leads -
see `qa_layer2_human_review_v1.json`'s `recurring_face_observation` for the
full counter-example list).

### Screen-policy leaks

6 images (`arts.blogging`, `arts.photo_retouching`, `arts.podcasting`,
`arts.webcomics`, `business.dividend_investing`, `business.no_code`) show
a front-facing display with visible UI chrome (toolbar icons, menu bars,
or a full stock-chart dashboard on `business.dividend_investing`).
Concentrated in creator-tool "editing software" hobbies and
finance-dashboard hobbies; several sibling hobbies in the same families
(`arts.digital_art`, `arts.animation_production`, `arts.motion_graphics`,
`arts.video_editing`, `arts.sound_design`) stayed fully compliant (blank/
turned/artwork-only screens), showing the policy *can* be followed
consistently, just not always.

## Batch-1 gate: **AMBER**

**Not GREEN**: a 50% defect rate within an entire major category, plus two
unambiguous real trademark logos, is not "safe to continue production
rollout" as-is.

**Not RED**: every defect found is narrowly diagnosable to a specific,
well-understood, single-cause pattern (business-category diagram-label
text; device-logo brand leak) rather than a diffuse, unexplained failure
across the whole batch. Semantic correctness held at 120/120, border/UI
and safety stayed at 0%, and the D4 house style, diversity layer, and the
four previously-fixed hobbies (`books.reading`, `wellness.cold_plunge`/
`sports.skateboarding` not in this batch but structurally unchanged,
`wellness.tai_chi` not in this batch) all performed as intended where
tested. This matches the established "fix at recipe/category level, not a
full D4 rewrite" pattern from every prior round in this project.

**Batch 2 may NOT proceed** until the business-category text-leak pattern
and the device-logo brand leak are addressed and validated (per the
task's guardrails, no such fix or re-generation was performed in this
round - both are documented as the required next actions).

### Recommended fixes (not executed this round)

1. Add a **category-level** (not just per-hobby) override or
   `category_modifiers_v1.json` reinforcement for `business` requiring
   diagram/whiteboard/kanban-board content to be abstract, non-linguistic
   shapes/icons only - mirroring the existing `lifestyle.game_nights`/
   `learning.philosophy` pattern but scoped to the whole category instead
   of one hobby at a time, since ~15 different business hobbies share the
   same underlying recognition-anchor language.
2. Strengthen `global_brand_safety_policy` (or add a dedicated
   reinforcement sentence) specifically calling out laptop/tablet/phone
   lids and back panels as a common real-logo leak point, since the
   existing "consumer electronics and devices" language did not prevent
   two clear Apple-logo renders in this one batch.
3. Small targeted re-generation (a handful of images) of the fixed
   business hobbies plus `business.coworking`/`business.no_code` to
   visually confirm both fixes before resuming batch submission.

### Retry-only list

None required - 0 failed_transient, 0 failed_content in this batch. No
retry batch is needed.

## Guardrails honored

- Exactly one production batch (120 requests) submitted; batches 2–19 not
  submitted and remain hard-locked in the runner for this session.
- No fal.ai, no GitHub Actions, no Vercel, no Production deployment, no
  Google Play.
- `sports.american_football` and `technology.robotics` remain quarantined;
  confirmed absent from this batch (Layer-1 check).
- Git history was not rewritten.
- No raw base64 or oversized API responses committed - `batch_status.json`
  is a redacted 765-byte metadata summary; the 120 images themselves are
  the legitimate production deliverable and are committed as such.
- `GEMINI_API_KEY` was never printed, logged, or committed.
- `tools/card_art/output/style_calibration_d_18_v1/images/d.zip` and
  `tools/card_art/output/style_d4_durability_12_v1/images/images.zip`
  (both untracked, presumed user-created for local review) left untouched.
- No prior images were regenerated; this was the first real production
  batch, so resume-safety/failure-only-retry logic exists but had nothing
  to exercise for real this round beyond the 0-failure outcome.

## Files in this checkpoint

- `tools/card_art/src/runProductionBatch.js` (new — production runner,
  batch-1-locked)
- `tools/card_art/src/qaLayer1ProductionBatch.js` (new — Layer-1 automated
  QA)
- `tools/card_art/package.json` / `package-lock.json` (modified — added
  `stream-json`/`stream-chain` to fix the oversized-response crash)
- `tools/card_art/output/production_batch_001_v1/` (new — 120 images,
  manifest, redacted batch status/job records, requests, Layer-1 and
  Layer-2 QA results)

## Report

- Commit SHA: see below (this handoff is written before the commit; the
  commit message and `LATEST_HANDOFF.md` carry the final SHA once
  committed).
- Submitted: 120
- Successful: 120
- Transient failures: 0
- Semantic: 120/120 PASS, 0 MINOR, 0 FAIL
- Brand/trademark leaks: 8/120 (6.7%) - most severe: 2 clear Apple logos
- Text leaks: 29/120 (24.2%) - dominant cluster: 15/30 (50.0%) in
  `business.*`
- Border/UI defects: 0/120
- Safety issues: 0/120
- Actual cost: $2.016
- Batch-1 gate: **AMBER**
- Batch 2: **may NOT proceed** until the business-category text-leak and
  device-logo brand-leak fixes are implemented and validated.

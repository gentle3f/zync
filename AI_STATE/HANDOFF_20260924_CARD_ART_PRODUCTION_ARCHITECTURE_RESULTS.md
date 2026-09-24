# Zync Card Art — Catalog Hardening + Production-Batch Architecture — Results

Branch: `card-art-pilot-v1-20260921`
Date: 2026-09-24
This checkpoint cost **$0**. No Gemini API call, no fal.ai call, no image
generated, no GitHub Actions run, no Vercel touched. D4's rendering
language (`global_style_v1.json`'s `prompt` field) was **not** touched.
D4 visual-style research is closed as of this checkpoint.

## Part 1 — Localized recipe fixes

Four hobby-level overrides in `tools/card_art/catalog/hobby_overrides_v1.json`:

- **`books.reading`** (carried over from the prior round, one phrase added
  this round: `"pseudo-text used decoratively on covers or spines"`) —
  plain/abstract covers, blank/non-linguistic spines and page marks;
  forbids readable titles, author names, invented words, spine text,
  publishing logos, decorative pseudo-text.
- **`wellness.cold_plunge`** (carried over, already matched this round's
  requirements exactly: cold water, ice cubes, condensation/frost, braced/
  alert posture, dedicated cold-plunge context; forbids steam, onsen
  atmosphere, warm bath glow, relaxed soaking pose, domestic bathtub).
- **`sports.skateboarding`** (carried over, already matched: generic
  unbranded footwear/equipment; forbids swoosh/checkmark/three-stripe
  marks, signature side panels, manufacturer badges, pseudo-brand marks,
  readable brand text, avoidable branded silhouettes).
- **`wellness.tai_chi`** (new this round) — requires blank/abstract wall
  art if any is present; forbids readable Chinese calligraphy, readable
  scroll text, pseudo-characters, signage, labels. The Tai Chi practice
  itself is unchanged.

Full 2210-row catalog regression: `OK: 2210 / 2210, ERRORS: 0`.

## Part 2 — Diversity-system hardening

`tools/card_art/specs/diversity_profiles_v1.json` was restructured from 5
dimensions (with `protagonist` conflating gender/age/object-led, and a
3-way uniform `effect_intensity`) into **9 dimensions**:

- `gender_presentation` (male_led / female_led / mixed_group / object_led)
- `age_presentation` (younger_adult / adult / middle_aged_adult / older_adult)
- `face_hair_presentation` (8 values spanning hair length/texture/color +
  face-shape cues: short_neat, long_straight, wavy_medium, curly_or_coily,
  buzzed_or_very_short, tied_back_practical, grey_or_silver, warm_toned)
- `body_build` (slim / average / athletic / broader_build / mature_build,
  each phrased "rendered naturally and without caricature")
- `composition` (close_action / medium_hero_shot / wide_environmental_hero
  / pair_interaction / group_interaction / object_hero / environment_hero)
- `lighting_time` (bright_daylight / cool_daylight / soft_morning /
  golden_hour / blue_hour / evening_interior / night_neon)
- `palette_mood` (warm / cool / complementary / high_key / subdued_colorful)
- `emotional_mode` (unchanged, 9 values)
- `effects_intensity` — **new weighted routing**: `zero_effects` (target
  40%), `minimal_effects` (target 35%), `accent_effects` (target 25%).
  `zero_effects` explicitly prohibits sparkles, floating glowing
  particles, magical glints, decorative light flecks, and aura-like glow,
  while explicitly still allowing ordinary physically plausible
  highlights/reflections/light sources.

`tools/card_art/src/diversityLayer.js` gained a `weightedPick()` function
(deterministic hash-mod-total-weight bucketing) used only for
`effects_intensity`; every other dimension keeps uniform deterministic
hashing. Catalog-wide measured distribution across all 2210 rows:
`zero_effects=882 (39.9%)`, `minimal_effects=763 (34.5%)`,
`accent_effects=565 (25.6%)` — matches the 40/35/25 target closely.
`golden_hour` now accounts for only 320/2210 (14.5%) of lighting_time
picks, one of 7 roughly-even values, so D4 no longer collapses into a
single golden-hour default.

## Part 3 — Strengthened `object_led`

The 8-card diversity test found a single guidance sentence was not enough
to stop a human figure dominating an `object_led` scene
(`outdoors.fishing`). `object_led` now triggers a dedicated multi-sentence
directive (`OBJECT_LED_DIRECTIVE` in `diversityLayer.js`) instead of the
generic one-liner: the hobby-defining object/material/tool/dish/device/
catch/creation moment must carry the strongest visual emphasis; any human
present is a supporting actor, secondary in scale, shown interacting with
the object rather than posed for a portrait; camera attention, foreground
scale, and lighting all favor the object. This is generic across hobby
categories (fishing, collecting, craft, food, technology, etc.) rather
than hardcoded per category, and composition variety is preserved (it
explicitly allows a wider shot as long as the object still visually
dominates).

## Part 4 — Production-batch architecture (built, not run)

New library modules:

- **`tools/card_art/src/productionQueue.js`** — `buildProductionQueue()`.
  Rebuilds the rights-first catalog bridge, **fails closed** if
  `eligible.length !== 2210`, checks for duplicate canonical ids, sorts
  deterministically by canonical_interest_id, compiles every prompt
  through the real production compiler (D4 + brand-safety/text/screen
  policies + all 4 hobby fixes + the diversity layer), and assigns a
  `prompt_sha256`/`prompt_length` integrity fingerprint per row (the full
  prompt text itself is intentionally NOT persisted in the committed
  queue file, to keep repo size controlled - it is deterministically
  recomputable from the same inputs at submission time, which
  `validateProductionArchitecture.js` proves). Partitions non-quarantined
  rows into `BATCH_SIZE=120`-row batches; quarantined rows get
  `batch_number: null`, `status: "quarantined_excluded"`, and are excluded
  from the batch loop entirely.
- **`tools/card_art/src/productionManifest.js`** — `planSubmission()` (never
  resubmits a `succeeded` id; skips `quarantined` ids unconditionally;
  submits `pending`/`retry_pending`/unresolved ids), `planRetryBatch()`
  (only `failed_transient`/`retry_pending`), `classifyOutcome()` (maps a
  completed request outcome to the next status; `content_policy` failures
  route to `needs_qa`, not auto-retry, since they usually need a recipe
  fix, not a resubmission).
- **`tools/card_art/src/productionCostReport.js`** — `buildCostReport()`;
  only counts `actual_cost_usd` when a manifest record explicitly carries
  it from real billing metadata, never assumes a failed/transient request
  was billed.
- **`tools/card_art/src/buildProductionQueueCli.js`** — CLI that writes
  `catalog/production_queue_v1.json`, `catalog/production_batch_plan_v1.json`,
  `catalog/production_cost_report_v1.json`. Zero-cost, local only.
- **`tools/card_art/src/validateProductionArchitecture.js`** — the Part 5
  zero-cost validation harness (see below).

### Canonical production queue

`catalog/production_queue_v1.json`: 2210 entries, each with
`canonical_interest_id`, `title`, `runtime_category`, `runtime_cluster`,
`art_policy`, `recipe_source`, `archetype`, `visual_variant`,
`diversity_profile` (all 9 dimensions), `effects_profile`,
`prompt_sha256`/`prompt_length`, `model`, `provider`, `quarantined`/
`quarantine_reason`, `output_filename`, `batch_number`,
`planned_batch_id`, `status`. File size: ~2.8MB (compact - no embedded
prompt text or API response payloads).

### Batch partitioning

`catalog/production_batch_plan_v1.json`: batch size target 120.
**2208 auto-production images → 19 batches** (18 full batches of 120 +
one final batch of 48). Quarantined ids excluded entirely from this plan.

### Quarantine handling

`sports.american_football` and `technology.robotics` are both present in
the 2210 rights-eligible set (confirmed) but are marked
`quarantined: true`, `batch_number: null`, `status: "quarantined_excluded"`
in the queue, and `planSubmission()` refuses to include any quarantined
entry regardless of manifest state. The three counts are tracked and
reported distinctly everywhere (queue counts, cost report, this handoff):
**eligible=2210, auto-production=2208, quarantine=2**.

### Cost accounting

`catalog/production_cost_report_v1.json` (fresh state, no manifest yet):
unit price $0.0168/successful image; baseline (all 2210) = **$37.128**;
auto-production-only (2208, excluding quarantine) = **$37.0944**. The
report's fields (`planned_images`, `successful_images`,
`billed_image_outputs_estimate`, `failed_transient`, `failed_content`,
`needs_qa`, `retry_pending`, `actual_cost_known_usd`) are populated from a
real manifest once one exists; `validateProductionArchitecture.js` proves
the accounting logic against mocked mixed-outcome data (2 succeeded, 1
failed_transient, 1 failed_content → `successful_images=2`,
`billed_image_outputs_estimate=2`, only the entry with an explicit
`actual_cost_usd` counts toward `actual_cost_known_usd`).

### QA architecture

`tools/card_art/specs/production_qa_plan_v1.json` — 4 layers:

1. **Automated static checks** (missing image, duplicate hash, wrong
   aspect ratio, tiny/corrupt file, border/chrome heuristic reused from
   `generateCompiledBatch.js`'s flatness detector, manifest mismatch,
   opportunistic text-risk metadata, quarantined-interest-accidentally-
   included hard stop).
2. **Representative human sampling** — `max(8, ceil(0.10 * batch_size))`
   per batch, stratified across runtime_category and archetype before
   filling remaining slots by stable-hash pseudo-random selection.
3. **Targeted high-risk review** — every entry in 5 declared high-risk
   families gets individual review regardless of the statistical sample:
   brand/trademark-sensitive (sports/fashion), text-sensitive (books/
   learning/screens/signage), screen-adjacent (tech_workspace), wellness
   safety (wellness_experience/calm_wellness), and rights-sensitive/
   near-quarantine (shares a runtime_cluster with a quarantined id, or
   `recipe_source=derived` with no manual review yet).
4. **Cluster-defect escalation** — 2+ occurrences of the same defect type
   in one batch, or the same category/archetype recurring across two
   batches, pauses all further not-yet-submitted batches until root-caused
   and fixed at the recipe/policy level (never a full D4 rewrite), mirror
   of the pattern already proven on books.reading/cold_plunge/
   skateboarding/tai_chi.

### Production launch gates

`tools/card_art/specs/production_launch_gates_v1.json` — 13 gates.
**12 of 13 satisfied** as of this checkpoint (each with recorded
evidence). **Gate 13 - explicit user authorization to start production
generation - is the sole remaining blocker**, by design: this checkpoint
does not grant it.

## Part 5 — Zero-cost dry-run validation

`node src/validateProductionArchitecture.js` — **11/11 checks passed**,
zero API calls:

```
[PASS] eligible_catalog_count_equals_2210 - eligible=2210
[PASS] no_duplicate_canonical_ids - unique=2210
[PASS] every_id_receives_exactly_one_production_assignment - rows=2210
[PASS] every_non_quarantined_item_has_exactly_one_planned_batch - auto_production=2208 batches=19
[PASS] quarantined_items_cannot_be_auto_submitted - quarantined=sports.american_football, technology.robotics
[PASS] assignments_deterministic_across_two_independent_runs - rows_compared=2210
[PASS] no_successful_mocked_item_is_resubmitted - succeeded_skipped=5
[PASS] only_mocked_failures_enter_retry_queue - retry_plan=[arts.acting, arts.audio_editing]
[PASS] manifests_map_id_prompt_filename_correctly - sample_id=arts.acrylic_painting filename=arts__acrylic_painting__gemini_3_1_flash_lite_image.jpg
[PASS] cost_report_never_assumes_failures_billed - successful=2 known_actual_cost=0.0168
[PASS] no_github_actions_or_deployment_files_touched - workflows_dir_untouched (7 files present, not modified by this run)
```

Full output saved at `tools/card_art/catalog/production_architecture_validation_v1.txt`,
which also records the separate full-catalog compile regression
(`OK: 2210 / 2210, ERRORS: 0`) and the catalog-wide diversity/effects
distribution measurements.

The determinism check (`assignments_deterministic_across_two_independent_runs`)
was run against the **real 2210-row catalog** (two independent in-process
`buildProductionQueue()` calls, not mocked). The resume-safety, retry-only,
and cost-accounting checks were run against **mocked manifest data**
(constructed in-memory, no file I/O, no API calls) per Part 5's explicit
instruction to test the pipeline with mocked/dry-run data since no real
manifest exists yet (no batch has ever been submitted).

## Production-readiness report

| Metric | Value |
|---|---|
| Eligible catalog count | 2210 |
| Auto-production count | 2208 |
| Quarantine count | 2 (`sports.american_football`, `technology.robotics`) |
| Planned batch count | 19 |
| Planned batch size | 120 (18 full batches + 1 batch of 48) |
| Estimated baseline cost (all 2210) | $37.128 |
| Estimated cost (auto-production only, 2208) | $37.0944 |
| Deterministic-assignment validation | PASS (real 2210-row double-build, byte-identical) |
| Resume validation | PASS (mocked) |
| Retry validation | PASS (mocked) |
| QA plan | Documented (`specs/production_qa_plan_v1.json`), 4 layers |
| Launch gates | 12/13 satisfied; gate 13 (user authorization) open by design |
| Unresolved blockers | None mechanical. The only blocker is the intentional gate 13 - no real generation should start without a new explicit instruction. |

## Guardrails honored

- $0 spent this checkpoint: no Google Gemini API call, no fal.ai call, no
  image generated or regenerated.
- No GitHub Actions triggered; no `.github` files touched.
- No Vercel/Production/Google Play touched.
- `sports.american_football` and `technology.robotics` remain quarantined
  and excluded from every batch/submission plan.
- No git history rewritten.
- `tools/card_art/output/style_calibration_d_18_v1/images/d.zip` and
  `tools/card_art/output/style_d4_durability_12_v1/images/images.zip`
  (both untracked, presumed user-created for local review) left untouched
  and excluded from this commit.
- No raw base64, oversized API responses, or `thoughtSignature` blobs
  committed - the production queue stores prompt fingerprints
  (`prompt_sha256`), not full prompt text or any generation output.

## Files in this checkpoint

- `tools/card_art/catalog/hobby_overrides_v1.json` (modified — added
  `wellness.tai_chi`, reinforced `books.reading`)
- `tools/card_art/specs/diversity_profiles_v1.json` (rewritten — 9
  dimensions, weighted `effects_intensity`)
- `tools/card_art/src/diversityLayer.js` (modified — `weightedPick()`,
  strengthened `object_led` directive)
- `tools/card_art/src/productionQueue.js` (new)
- `tools/card_art/src/productionManifest.js` (new)
- `tools/card_art/src/productionCostReport.js` (new)
- `tools/card_art/src/buildProductionQueueCli.js` (new)
- `tools/card_art/src/validateProductionArchitecture.js` (new)
- `tools/card_art/specs/production_qa_plan_v1.json` (new)
- `tools/card_art/specs/production_launch_gates_v1.json` (new)
- `tools/card_art/catalog/production_queue_v1.json` (new, generated)
- `tools/card_art/catalog/production_batch_plan_v1.json` (new, generated)
- `tools/card_art/catalog/production_cost_report_v1.json` (new, generated)
- `tools/card_art/catalog/production_architecture_validation_v1.txt` (new,
  generated)

## Exact next action

None taken automatically. Per gate 13, the only thing standing between
this checkpoint and real production generation is a new, explicit user
instruction to start it. When that instruction arrives, the expected next
steps are: (1) write the actual batch-submission runner (mirroring
`runD4Diversity8.js`'s `--dry-run`/`--submit`/`--collect` pattern but
reading from `production_queue_v1.json`/`production_batch_plan_v1.json`
and writing a real resumable manifest), (2) submit batch 1 of 19 only, (3)
run the layer-1/2 QA on it, (4) only then proceed to further batches.

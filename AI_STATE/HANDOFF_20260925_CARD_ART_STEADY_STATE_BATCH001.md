# Zync Object-First V2 — Sentinel-8 QA, Automotive Release, Steady-State Batch-001

Branch: `card-art-pilot-v1-20260921`
Starting point: Sentinel-8 execution commit `2fb7c5d`.

## 1. Sentinel-8 authoritative visual QA recorded

`sentinel_8_qa_results_v1.json`: 8/8 reviewed, **all approved**. Conclusion: `PASS_REMEDIATION_VALIDATED`. No Sentinel-9 required. Each row's old v2.4 Wave-C QA-quarantined asset remains preserved inside `superseded_assets` (`status: superseded_by_remediation_asset`) - neither image file was touched.

## 2. Automotive acceptance standard clarified

The user explicitly accepted both automotive Sentinel outputs, overriding the prior stricter ChatGPT brand-morphology threshold. Recorded standard: a vehicle does not fail merely for conventional sports-car proportions, general automotive design language, or resemblance to a broad category. Brand/IP concern requires stronger evidence (visible logo, readable name, recognizable emblem, near-direct replication of a specific distinctive model, or an unusually exact combination of signature model-specific details). This is a QA-policy clarification only - the v2.5 automotive prompts were **not** rewritten because of it.

## 3. Automotive hold released

`automotive_hold_release_v1.json`. `automotive_brand_morphology_repair` released for **`transport.muscle_cars`, `transport.pickup_trucks`** (2 ids, both now `pending_generation`, no hold). `transport.sports_cars` (already-decided qa_quarantine, v2.4 historical) was explicitly returned to `pending_generation` eligibility under its already-repaired v2.5 prompt (`sports_car_generic_morphology`) - a deliberate, disclosed one-time exception to the normal "leave historical rows alone" rule, since the user is specifically directing this id back into the pipeline. **Not auto-approved** - its old v2.4 failure (Porsche-911-type resemblance finding) is preserved in `superseded_assets`. `motorsport.cars` is untouched (still `qa_quarantine`, no v2.5 repaired prompt exists for it, out of scope).

## 4. Other holds verified unchanged

261 genre-music + 2 vocal-music + 1 `wellness.stretching` (`temporary_generation_hold`/`semantic_repair_unvalidated`) = 264 total, confirmed unchanged before and after every write. `arts.illustration` confirmed still `qa_quarantine` (repaired but not visually revalidated, deliberately excluded from generation).

## 5-6. Steady-state released, Batch-001 executed

Gate: `HOLD_FOR_WAVEC_REMEDIATION_SENTINEL` → `STEADY_STATE_AUTHORIZED`, recorded as based on Sentinel-8's `PASS_REMEDIATION_VALIDATED`.

**Selection** (`selectAndBuildSteadyStateBatch001.js`): the pre-existing stratified `steady_state_batch_1` assignment held only 116 rows (not 120 - some had already been reassigned earlier as Wave-B/Wave-C shortfall replacements). Of those, 4 are newly held (genre-music: `music.jazz`, `music.blues`, `music.metal`, `music.punk`), leaving 112 eligible. The 3 rows just returned to eligibility by the automotive release (`transport.sports_cars`, `transport.muscle_cars`, `transport.pickup_trucks`) were explicitly force-included - the whole point of releasing them is to validate that decision at scale. 5 deterministic same-order replacements filled the remaining shortfall from the steady-state pool.

**Versioning preserved per-row:** 118 cards on v2.4, 2 cards (`learning.business_books`, `transport.sports_cars`) on v2.5. Both cross-verified against their respective freeze + compiled-prompts source before submission.

**Execution:** `runObjectFirstV2SteadyStateBatch001.js`, direct Google Batch API, `gemini-3.1-flash-lite-image`. Result: **120/120 succeeded, 0 content-blocked, 0 technical failures, 0 retries**, 120 unique file hashes, $2.016 billed (exact hard cap). All 120 queue rows → `generated_pending_qa` (none auto-approved).

## 7-9. QA sample + package + convenience ZIP

`qa_sample_manifest_v1.json` / `qa_package_v1.json`: **84/120 (70%) sampled** - driven by the catalog's own strict risk-level flags and genuinely-flagged confidence tiers (`new_grammar_unvalidated`/`weak_extrapolation`), consistent with the same pattern seen in Wave-B (69%) and Wave-C (71%). An initial draft that also treated the common baseline `extrapolated` confidence tier as mandatory produced an inflated 88/120 and was corrected back to the validated strict criteria. The 3 automotive-release-validation rows were explicitly force-included as a mandatory reason (`automotive_hold_released_validation`). Convenience ZIP `object_first_v2_steady_state_batch001_qa_sample_84.zip` built (84 images, 2-digit review-order-prefixed filenames, inner `qa_sample_review_manifest_v1.json`) - programmatically verified to match the committed sample manifest's id list and order exactly. **Not committed**, per instruction (matches the Wave-C QA-zip convention).

## 10-12. Output, technical validation, queue state

`tools/card_art/output/object_first_v2_steady_state_batch001_v1/`. All 120 files verified: 848×1264 JPEG, 120 unique SHA256 hashes, no duplicates. Queue: 120 rows → `generated_pending_qa`, none marked approved/final/production_ready.

## 13. Next batch

Batch-002 **NOT** started. Requires a new, separate, explicit user authorization after ChatGPT reviews Batch-001's QA sample - even though steady-state mode is now active, each paid 120-card batch still needs its own authorization.

## 14. Frame pipeline

Untouched - raw art production remains separate from frame composition, as before.

## Cost ledgers (kept separate)

**Formal production-wave spend:** Canary-24 $0.4032 + Wave-B-48 $0.8064 + Wave-C-96 $1.6128 + Batch-001 $2.016 = **$4.8384**.
**Validation/remediation spend:** Validation-16 $0.2688 + Validation-8 $0.1176 + Recheck-3 $0.0504 + startups-recheck $0.0168 + Sentinel-6 $0.1008 + Sentinel-8 $0.1344 = **$0.6888**.

---

*Continues from `AI_STATE/HANDOFF_20260925_CARD_ART_V25_WAVEC_REMEDIATION.md` (`8ea9f83`) and the Sentinel-8 execution commit `2fb7c5d`.*

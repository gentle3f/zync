# Zync Object-First V2 — Sentinel-6 QA, Wave-C-96 Rollout

Branch: `card-art-pilot-v1-20260921`
Starting point: Sentinel-6 execution commit `1762230`.

## 1. Sentinel-6 authoritative visual QA recorded

`sentinel_6_qa_results_v1.json`: 6/6 reviewed - **5 approved** (food.coffee, music.singing, music.karaoke, learning.book_genre.booktube, technology.gadgets), **1 approved_with_minor** (learning.fiction, `text_leak_minor`). Conclusion: `PASS_REMEDIATION_VALIDATED`. This authorized releasing Wave-C from `HOLD_FOR_REMEDIATION_VALIDATION`.

## 2. Remediation replacement provenance

For each of the 6 repaired ids, the queue row gained a `superseded_assets` array entry recording the OLD v2.3 Wave-B QA-quarantined asset (source dir, version, prompt-hash reference into the immutable v2.3 freeze, original visual QA disposition/finding, `status: superseded_by_remediation_asset`) **before** the row's live fields were overwritten to reflect the NEW approved Sentinel-6 (v2.4/v2.4.1) asset. Neither image file was touched, moved, or deleted - both remain in their original output directories. `canonical_asset_source` now points to `object_first_v24_sentinel6_v1`.

## 3. Music hold status - unchanged in scope

The Sentinel-6 PASS proves only `music.singing`/`music.karaoke` are repaired - it does **not** extend to genre-specific music. All 264 held rows remain held: 261 `music_genre_semantic_repair`, 2 `music_vocal_semantic_repair` (`music.choir`, `music.a_cappella`), 1 `semantic_repair_unvalidated` (`wellness.stretching`). `music.rock` and `motorsport.cars` remain `qa_quarantine` from Canary-24.

## 4. wellness.stretching - unchanged

Verified unchanged before and after every write this checkpoint: `temporary_generation_hold` / `semantic_repair_unvalidated`. Not generated, not released.

## 5-6. Wave-C-96 released and executed

Gate changed `HOLD_FOR_REMEDIATION_VALIDATION` → `AUTHORIZED_WAVE_C_96`, recorded as based on Sentinel-6's `PASS_REMEDIATION_VALIDATED`.

**Selection** (`selectAndBuildWaveC96.js`): the pre-existing stratified `wave_c_96` assignment held only 95 rows (not 96 - one, `collecting.stamps`, had already been reassigned to `wave_b_48` in an earlier checkpoint as its `music.pop` replacement). Of those 95, 3 are now newly held (`music.classical`, `music.hip_hop`, `music.r_and_b`), leaving 92 eligible. 4 deterministic same-order replacements were pulled from the steady-state pool (`collecting.sneakers`, `lifestyle.repair_workshops`, `pets.rabbits`, `arts.illustration`) to reach exactly 96.

**Versioning preserved per-row, not flattened:** 95 cards compiled against the v2.4 freeze, 1 card (`music.piano` - a scene-family de-collision neighbor from the v2.4.1 narrow fix) compiled against the v2.4.1 freeze. Both cross-verified against their respective freeze + compiled-prompts source before submission.

**Execution:** `runObjectFirstV2ProductionWaveC96.js`, direct Google Batch API, `gemini-3.1-flash-lite-image`. Result: **96/96 succeeded, 0 content-blocked, 0 technical failures, 0 retries**, 96 unique file hashes, $1.6128 billed (exact hard cap). All 96 queue rows updated to `generated_pending_qa` (none auto-approved).

## 7-8. Wave-C QA sample + package

`qa_sample_manifest_v1.json` / `qa_package_v1.json`: **68/96 (71%) sampled** - driven entirely by the catalog's own strict risk-level flags (`semantic_risk_level=high`, `text_risk_level=elevated`, `brand_risk_level=elevated`, `physical_logic_risk_level=elevated`) and new/weak-grammar confidence, matching the same pattern already seen in Wave-B (69%) - a genuine property of this wave's risk-flag distribution, not an artifact of over-broad matching. The instruction's named "watch families" (human-operated tools, coffee/drink prep, media creator, non-held music, consumer tech, legal/educational sims, community/social, brand-sensitive vehicles, text-heavy publication) were deliberately **not** used as a second, broader mandatory-inclusion trigger - matching every archetype in that thematic list would have swept in nearly the whole catalog (an initial draft hit 74/96 this way) and defeated the purpose of sampling. Instead, watch-family membership is recorded as an additional reason tag and used only to prioritize ordering within the (in this case unused, since mandatory already exceeded 24) even-stride fill. No held music rows were added to the sample.

## 9. Queue state

96 Wave-C rows → `generated_pending_qa`. 6 Sentinel-6 rows → `approved`/`approved_with_minor` with superseded provenance. All 264 held rows and the 2 Canary-24 quarantines untouched.

## 10. Cost accounting - two separate ledgers

**Formal production-wave spend:** Canary-24 $0.4032 + Wave-B-48 $0.8064 + Wave-C-96 $1.6128 = **$2.8224**.
**Validation/remediation spend (kept separate, never reclassified):** Validation-16 $0.2688 + Validation-8 $0.1176 + Recheck-3 $0.0504 + startups-recheck $0.0168 + Sentinel-6 $0.1008 = **$0.5544**.

## 11. Next-wave stop rule

Steady-state (120-card batches) **NOT started**. Requires a new, separate, explicit user authorization after ChatGPT reviews the Wave-C QA sample.

## 12. No architecture changes

Rock/Pop/genre-music grammar, `motorsport.cars`, `wellness.stretching`, scene-family/physical-logic/text-policy architecture: all untouched this checkpoint.

---

*Continues from `AI_STATE/HANDOFF_20260925_CARD_ART_V241_PRE_SENTINEL_CLEANUP.md` (`32b0d1f`) and the Sentinel-6 execution commit `1762230`.*

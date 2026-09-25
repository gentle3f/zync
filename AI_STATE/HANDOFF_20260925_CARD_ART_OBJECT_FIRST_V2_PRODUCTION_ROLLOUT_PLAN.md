# Zync Object-First V2 — Production Rollout Engineering (Zero-Cost Plan Only)

Branch: `card-art-pilot-v1-20260921`
Source commit: `9b031bc`
Scope: architecture/planning only. **$0.00 image-generation cost. No image was generated or visually inspected this checkpoint.**

## 1. Production candidate frozen

`tools/card_art/output/production_rollout_v2_object_first_v1/production_candidate_freeze_v1.json` — an immutable snapshot, version `v2.3`, sourced from commit `9b031bc`. Contains all 2208 non-quarantined rows with: protagonist type, containment status/rule, confidence, composition/palette/effects, `scene_family`, `text_mode`, `physical_logic_domain`/`classification`, all 3 risk flags, and a freshly-recomputed `prompt_sha256` for every row (verified reproducible - see §7). **Immutability rule, stated in the file itself:** any future architecture change must produce a new versioned snapshot (e.g. `v2.4`), never a silent mutation of this one.

## 2. Quarantine preserved

`quarantine_record_v1.json`: `sports.american_football` and `technology.robotics` remain excluded, with their exact reason (pulled live from `generation_guardrails_v1.json`, not re-typed) and an explicit statement of what future evidence would justify reconsidering each. Neither was routed into the V2 queue.

## 3. Existing-art inventory — an honest finding, not the number I initially expected

`tools/card_art/output/object_first_v2_full_catalog_audit_v1/existing_art_inventory_v1.json`. A mechanical script (`inventoryExistingArtV2.js`) walked all 8 known experiment output directories, cross-checking every V2-architecture image's recorded `prompt_sha256` against the current frozen `v2.3` prompt hash for that same canonical id.

**Result: only 1 image is a true `production_reuse_candidate` - `business.startups`** (from `object_first_v2_startups_final_recheck_v1/`, generated from the exact commit that froze `v2.3`).

**A real provenance gap was found, not hidden:** `media.anime` and `learning.mock_trial` (from Recheck-3) both have explicit supplied visual acceptance ("PASS" / "PASS, acceptable") but their *recorded prompt hashes do not match* the canonical `v2.3` pipeline's output. Root cause, verified by diffing the actual prompt text: Recheck-3's planning step applied a one-off local `effect_level` diversity adjustment (to avoid all 3 Recheck-3 cards sharing "restrained") directly to a frozen-prompt output file, without folding that adjustment back into any spec file. Re-running the real compiler today reproduces a *different* `effect_level` for those two ids than what was actually tested and accepted. These 2 are tagged `reuse_prompt_diverged_from_canonical` - not silently counted as reusable, and not falsely called "needs confirmation" either (confirmation already exists; the canonical prompt itself is what's out of sync). Both are included as fresh Canary-24 slots instead, so a genuinely hash-matching accepted image can be established for them.

**Reuse counts:**
- Exact-match + visually accepted (truly reusable): **1** (`business.startups`)
- Accepted but prompt diverged from canonical (needs a decision, not auto-reusable): **2** (`media.anime`, `learning.mock_trial`)
- Reuse needs visual confirmation (hash matches, no supplied acceptance found): **0**
- V2-architecture, generated, but simply superseded (no match, no special provenance issue): **24** (Validation-16's 16 + Validation-8's 5 non-startup/anime/mock-trial ids + Validation-8's own copies of startups/anime/mock-trial) - every one of these predates the catalog-wide `character_substitution_policy` addition, which changed literally every compiled prompt in the catalog, so none from Validation-16 or Validation-8 can match regardless of which specific rule they used.
- Non-V2-architecture (Rounds 1-4, pre-compiler): **33** - structurally incomparable, no `prompt_sha256` was ever recorded for these since they used a hand-written `experimentOverride` system, not `compileObjectFirstPromptV2`.

**Revised cost math:** future new-generation count = 2208 − 1 = **2207**. Revised projected cost = 2207 × $0.0168 = **$37.0776**. Full fresh ceiling = 2208 × $0.0168 = **$37.0944**. **Exact savings from reuse: $0.0168** (not the several-dollar savings a naive "we already generated 46+ images across all experiments" read might suggest - the strict exact-hash-match-plus-accepted rule is genuinely this narrow, and that's reported honestly rather than inflated).

## 4. Legacy human-led V1 disposition

Documented in `production_rollout_policy_v1.json`'s `legacy_v1_disposition`: Batch-1, Batch-1-repair, and Batch-2 are all marked `legacy_human_led_v1` - preserved for audit/history, superseded as the active production direction, not part of the V2 rollout, no further paid generation authorized. **No original image file was modified.** A non-destructive `legacy_v1_status_v1.json` marker was added only inside `production_batch_001_v1/` (already tracked/committed history); `production_batch_002_v1/` and `batch1_repairs_v1/` remain completely untouched (still uncommitted paused work from an earlier explicit STOP instruction) - not even a new marker file was added there, to avoid touching that work in any way without a separate explicit instruction.

## 5. New V2 production queue

`tools/card_art/catalog/production_queue_v2_object_first.json` - a **separate file**, V1's `production_queue_v1.json` never opened for writing. 2208 rows, each with: `queue_index`, `canonical_id`, `prompt_sha256`, `production_candidate_version`, protagonist/archetype/category, containment status, scene_family/composition/palette/effects/text_mode, `physical_logic_classification`, 3 risk levels, `historical_validation_status`, `reusable_existing_asset`, `rollout_wave`, `qa_sampling_status`, `generation_status`, `failure_status`, `quarantine_status`. Verified: 2208/2208 unique ids, deterministic across two independent builds (byte-identical output ignoring only the timestamp field).

**Ordering:** a stratified round-robin by archetype (alphabetical archetype cycling, one row taken from each archetype in turn) rather than raw catalog order, so no run of 50+ similar interests clusters together in any wave slice.

## 6. Wave strategy (nothing auto-runs)

| Wave | Count | Max cost |
|---|---|---|
| Canary-24 | 24 | $0.4032 |
| Wave-B-48 | 48 | $0.8064 |
| Wave-C-96 | 96 | $1.6128 |
| Steady-state | 2039 across **17** batches (16×120 + 1×119, computed dynamically, not hard-coded) | $2.016/batch |

Reconciliation check: 1 (reuse) + 24 + 48 + 96 + 2039 = 2208. **Passes exactly.**

No runner script exists yet for any of these waves - only planning artifacts. Every prior paid batch in this project (Validation-16, Validation-8, Recheck-3, the single-sentinel startups fix) required a separate explicit `--submit` invocation with no code path to the next batch; the same pattern is mandated for any future production-wave runner.

## 7. Canary-24 — deliberately hard, not easy

`canary_24_manifest_v1.json` — 24 unique NEW-generation ids (0 overlap with the 1 reusable id), selected programmatically to cover: the 2 diverged-but-accepted reconfirmations (anime, mock_trial), all 6 still-untested `new_grammar_unvalidated`/`weak_extrapolation` archetypes on **fresh** ids distinct from their already-tested sentinel (`business.sales` for professional_world, `music.rock` for music_listening, `learning.student_newspaper` for campus_activity, `business.founder_meetups` for community_gathering, `business.branding` for campaign_planning, `learning.moot_court` for legal_practice), reconfirmation of 6 previously-validated hard cases under the current catalog-wide policy additions (technology.ai, sports.badminton, outdoors.swimming, transport.modelrailways, pets.dogs, media.movies-family via `media.manga`), 2 explicit risk-flag combos, and 8 entirely-untested-so-far archetypes (reading_world, nature_immersion, creative_studio, wellness, vertical_adventure, journey_machine, gaming/digital_play). **A genuine, disclosed finding:** `shared_workspace` could not get a second fresh id - `business.coworking` is the *only* catalog id with that archetype, mechanically confirmed, so Canary-24 relies on its already-validated PASS instead rather than forcing a nonexistent alternative.

## 8. QA sampling manifests

`qa_sampling_manifests_v1.json`: Canary-24 at 100%, Wave-B-48 at ≥50% (mandatory risk-flagged rows plus deterministic even-stride fill to the target), Wave-C-96 at ≥25%, each steady-state batch at ≥10% - every sample automatically includes every row with `new_grammar_unvalidated`/`weak_extrapolation` confidence or any elevated risk flag, per the explicit instruction, before the even-stride fill tops up to the target fraction.

## 9. Rolling sentinels

`rolling_sentinels_v1.json` maps each historically-difficult failure class to one representative id (semantic scale → `transport.modelrailways`, food physical logic → `food.japanese`, social/professional → `business.startups`, text-sensitive → `learning.model_united_nations`, zero-human containment → `outdoors.swimming`, abstract concept → `technology.ai`, anime-type content → `media.anime`), with the explicit instruction not to regenerate the same sentinel every batch - select a comparable sentinel-class row from the current batch where one exists instead.

## 10. QA taxonomy, stop/hold rules, failure/quarantine workflow, cost guardrails, prompt-hash integrity, frame pipeline plan

All consolidated in `production_rollout_policy_v1.json` (one file, per the instruction to keep this practical rather than an "enormous scoring bureaucracy"). Highlights:

- **QA taxonomy:** PASS/MINOR/FAIL overall + 11 flags, applied only by ChatGPT/the user.
- **Stop/hold rules:** an isolated card failure quarantines just that card; a *systemic* failure (the same rule/domain/archetype failing 2+ times in one wave's sample, or brand/IP leakage even once) HOLDs the next wave until the implicated rule is revised under a new production-candidate version.
- **Failure/quarantine workflow:** mirrors the already-proven V1 Batch-1 `repair_history` provenance pattern - never silently overwrite, always version.
- **Cost guardrails:** per-wave accounting fields (planned/reusable/submitted/billed/failed-unbilled/cost-this-wave/cumulative/remaining), hard rule that no wave exceeds its approved budget.
- **Prompt-hash integrity:** the exact SHA256-verify-or-abort pattern already implemented and proven in every prior runner's `loadFrozenRows()`.
- **Frame pipeline:** raw art → technical validation → visual QA → approved master → crop/fit → rarity-frame overlay → final card asset → app derivatives. Frame composition is explicitly never part of image generation.

## 11. Frame master inventory — factual, not assumed

`frame_master_inventory_v1.json`: a real filesystem search (not an assumption) found **0 of the 5 locked rarity frame masters (Common/Uncommon/Rare/Epic/Legendary) present anywhere in this repository.** No `frame`, `rarity`, or card-asset directory of any kind exists yet. This does not block the raw-art production plan (frame composition is a separate, later stage) but the crop/overlay/final-card-asset pipeline stages cannot be built or tested until the masters are committed somewhere.

## 12. Zero-cost validation (15/15 checked)

| # | Check | Result |
|---|---|---|
| 1 | 2208 prompt hashes reproducible | PASS (byte-identical across two independent builds) |
| 2 | V1 unchanged | PASS (`production_queue_v1.json` never opened for writing by any script this checkpoint) |
| 3 | 2 quarantined ids excluded | PASS |
| 4 | No image-generation API calls | PASS (no network/fetch code exists in any script this checkpoint) |
| 5 | Correct eligible population | PASS (2208) |
| 6 | No duplicate ids | PASS (2208/2208 unique) |
| 7 | Reuse decisions hash/provenance-based | PASS (mechanical SHA256 comparison, not inferred) |
| 8 | Canary-24 = exactly 24 new-generation ids | PASS (0 overlap with the 1 reuse id) |
| 9 | Wave order deterministic | PASS |
| 10 | QA sampling deterministic | PASS |
| 11 | Next wave cannot auto-run | PASS (no runner code exists yet for any wave - planning artifacts only) |
| 12 | Cost model reconciles exactly | PASS (1+24+48+96+2039 = 2208) |
| 13 | Prompt-hash mismatch abort path | PASS (structurally present, same code pattern already exercised in 4 prior runners) |
| 14 | Legacy Batch-1/2 untouched | PASS (no image file modified; only 1 additive marker in already-tracked `production_batch_001_v1/`) |
| 15 | Frame inventory factual | PASS (real filesystem search, 0/5 found) |

## 13. Remaining caveats

- The `media.anime`/`learning.mock_trial` prompt-divergence finding means their "PASS" acceptance technically applies to images the canonical pipeline can no longer reproduce - Canary-24 re-tests both from the true canonical prompt rather than silently trusting the old acceptance.
- 2207 of 2208 rows are still genuinely unvalidated by any image under the current `v2.3` architecture (only `business.startups` has a confirmed exact-match accepted asset).
- The stratified queue order distributes archetypes evenly but has not been checked for `scene_family`/palette clustering *within* each specific wave slice beyond what the existing catalog-wide de-collision already guarantees - worth a quick look before Canary-24 is ever authorized, though not blocking.
- Frame masters do not exist in-repo yet; the composition pipeline stages beyond "approved raw art" are planned but unbuildable until they're provided.

## 14. Readiness

**Rollout infrastructure is READY for explicit Canary-24 authorization.** Not generated. Not authorized by this checkpoint.

---

*Continues from `AI_STATE/HANDOFF_20260925_CARD_ART_OBJECT_FIRST_V2_PRODUCTION_READINESS_HARDENING.md` (`c7d00b9`/`9b031bc`). Part of the isolated object-first research track, now transitioning toward production, separate from the legacy `legacy_human_led_v1` track.*

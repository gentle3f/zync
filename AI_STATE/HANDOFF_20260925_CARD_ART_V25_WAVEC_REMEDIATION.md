# Zync Object-First V2 — Wave-C Production Remediation + V2.5 Narrow Hardening

Branch: `card-art-pilot-v1-20260921`
Scope: architecture/planning only. **$0.00 image-generation cost. No image was generated or visually inspected this checkpoint.**

Starting point: Wave-C-96 execution commit `f98b1fc`.

## 1-4. Wave-C-96 authoritative visual QA recorded

`wave_c_96_qa_results_v1.json`: 68/96 reviewed - **44 approved**, **14 approved_with_minor**, **10 qa_quarantine**. The 44-approved list was derived mechanically (68 sampled minus the 24 named minor/quarantine ids), never invented, and verified to equal exactly 44. The remaining **28 unsampled Wave-C rows stay `generated_pending_qa`**, untouched. Conclusion: `PASS_WITH_SYSTEMIC_REMEDIATION_REQUIRED`. Steady-state: `HOLD_FOR_WAVEC_REMEDIATION`.

## 5. Automotive systemic hold

`automotive_brand_morphology_hold_v1.json`. Motorsport.cars (Canary-24) plus 3 Wave-C failures (classic_cars, sports_cars, supercars) independently converged on recognizable real-manufacturer morphology across 2 separate waves - a genuine systemic pattern. Held: **`transport.muscle_cars`, `transport.pickup_trucks`** (2 ids) - both are literally car-BODY-CLASS categories with the same fixed-silhouette risk profile as the 4 failures (Mustang/Camaro/Challenger-class and F-150/Silverado-class morphology). NOT held: activity/context transport ids (car_modification, car_detailing, restoration, shows, camping, overlanding, van_conversion, off_roading, driving) where the scene emphasis is on tools/environment rather than one dominant full-body silhouette, and `transport.electric_cars` (a powertrain category, not a fixed body class). Railway/aviation/cycling/transit ids were never candidates. Every transport.* recipe under `journey_machine` shares near-identical templated text, so this was a genuine title/category judgment call, not a text match.

## 6. Automotive generic-morphology grammar

3 new id-exact rules (`classic_car_generic_morphology`, `sports_car_generic_morphology`, `supercar_generic_morphology`) replace the shared `private_empty_venue` default for the 3 quarantined ids. Shared negative clause explicitly forbids signature headlight/grille/taillight/greenhouse/fender/side-intake/rear-wing features and classic-model-specific silhouettes; requires original blended geometry, non-identifying headlight clusters, mixed-era/mixed-brand cues. `classic_cars` → generic vintage vehicle + period garage; `sports_cars` → generic original sports coupe; `supercars` → fictional futuristic vehicle with invented morphology.

## 7. Human-operated-object compatibility gate v2

`interaction_support_mode` introduced as a reusable field on **all 36 structural containment rules** (29 pre-existing, tagged as metadata only - their scene_template text is untouched, so no prompt-hash change - plus 7 new). Values: `static_resting`, `mechanically_supported`, `automated_machine`, `passive_physics`, `environmental_aftermath`, `not_applicable`, `screen_content_only`. The zero-cost audit's gate #9 verifies every compiled row's matched rule carries a recognized mode.

## 8-9. lifestyle.gardening / science.chemistry fixed

New id-exact rules (`gardening_object_first_grammar` = static_resting, `chemistry_lab_object_first_grammar` = mechanically_supported) replace the human-first generic fallback that caused the floating watering-can/flask failures. Both regression-tested (no un-negated "pouring" in the activity section).

## 10. Five semantic misroutes - root-caused, not assumed

| id | root cause | classification |
|---|---|---|
| `learning.nonfiction` | Shares learning.fiction's generic human-first V1 recipe pattern, never given its own concrete anchors; generic fallback let the model drift to an unrelated documentary/astronomy concept | **B. ambiguous semantic anchors** |
| `wellness.mobility` | The word "mobility" was never disambiguated from animal mobility/agility; generic fallback gave no human-specific prop anchor | **B. ambiguous semantic anchors** (word-level) |
| `media.tv` | The underlying **recipe's own environment field literally names "cinema, theatre"** as valid venues for TV Series - a genuine content ambiguity inherited from the V1 recipe data, not a V2 routing bug | **D. inherited fallback contamination (recipe-data level)** |
| `technology.machine_learning` | Shares `tech_workspace`/`abstract_system_no_operator` with `technology.ai` (which passed cleanly) - the rule works generally; ML's own recipe anchors gave no concrete grounded-technical objects, so the abstraction filled with generic sci-fi imagery | **B. ambiguous semantic anchors** (recipe-specific, exact-ID) |
| `arts.illustration` | `action_aftermath`'s scene_template was written for a sports-validation case (`sports.running`) and uses generic "water droplets"/"freshly disturbed surface" phrasing with zero illustration-specific noun; combined with illustration's own vague recipe anchors, the model had near-total freedom and defaulted to an unrelated but physically-plausible tea/matcha "aftermath" scene | **B. ambiguous semantic anchors** (genuinely disclosed static cause, not a fabricated bug - this is a real, verifiable gap in borrowed generic rule text) |

All 5 fixed with dedicated id-exact grammars (Part 10's exact target anchors). 3 of the 5 (`nonfiction`, `tv`, `machine_learning`) also required a `forbidden_scene_families` fix after routing revealed real ambient contradictions (outdoor/nature scene families vs. required indoor/grounded settings) - same class of issue already fixed once for `music.singing`/`music.karaoke`.

## 11. Hold/fix strategy

All 5 semantic-misroute ids plus all 3 automotive-failure ids (8 total) **remain `qa_quarantine`** - repaired prompts prepared under v2.5, not released to production. No wider grammar-family hold was needed for any of the 5 - each traces to a recipe-specific gap, confirmed by sibling rows sharing the same shared rule (technology.ai, learning.fiction's pattern) already passing.

## 12. Versioning - v2.5, sparse

`production_candidate_freeze_v2_5_v1.json` (new, immutable; v2.3/v2.4/v2.4.1 untouched). **19 of 2,208 rows changed** (the 10 directly-fixed ids + 9 scene-family de-collision window neighbors, a real deterministic ripple, not a bug). Queue migration: only **7 pending_generation rows** (6 held genre-music rows + 1 ungenerated `learning.business_books`) moved to v2.5 in the queue; the other 12 changed rows are already-decided (quarantined/approved) and correctly kept at their historical version. **169 rows preserved historical** (72 Canary/Wave-B decided + 96 Wave-C decided + 1 reuse candidate).

## 13. 68-card QA reconciliation

44 approved / 14 approved_with_minor / 10 qa_quarantine applied to exactly the 68 sampled rows; 28 unsampled rows untouched at `generated_pending_qa`.

## 14. Zero-cost recompile

All 19 checks pass (`v2_5_static_audit_v1.json`): 2,208/2,208 compile, deterministic across two runs, V1 unchanged, historical v2.3/v2.4/v2.4.1 provenance unchanged, Wave-C QA states correct, 28 unsampled pending, automotive hold deterministic (exactly 2 ids), no unintended positive-human wording, interaction-support gate works, all 7 targeted regressions pass, no unresolved placeholders, no accidental broad hold explosion, no image API calls.

## 15. Static action-risk audit

`static_action_risk_audit_v1.json`, scoped to each row's per-hobby "Depict this activity" text with full-sentence negation scope (not a fixed character window, which initially produced false positives on the shared catalog-wide boilerplate). **Residual risky-manual-action count: 0** - genuinely verified, not asserted.

## 16-17. Sentinel-8 plan (NOT executed)

`sentinel_8_plan_v1.json`. Exactly 8 ids: `transport.classic_cars`, `transport.supercars`, `lifestyle.gardening`, `science.chemistry`, `learning.nonfiction`, `wellness.mobility`, `media.tv`, `technology.machine_learning` - all on v2.5, SHA-verified against the freeze and compiled-prompts source. `arts.illustration` repaired but deliberately excluded (kept small); `transport.sports_cars` repaired but held pending this sentinel's automotive outcome. No scene-family/palette contradictions remain (verified after the 3 additional forbidden-scene-family fixes). **Future cost: 8 × $0.0168 = $0.1344 - NOT spent.**

## 18-19. Steady-state and existing holds

Steady-state: `HOLD_FOR_WAVEC_REMEDIATION_SENTINEL`. All pre-existing holds (261 genre-music, 2 vocal-music, 1 wellness.stretching, `music.rock`/`motorsport.cars` quarantines) verified unchanged. The automotive hold is additive (266 total held rows).

---

*Continues from `AI_STATE/HANDOFF_20260925_CARD_ART_WAVEC96_ROLLOUT.md` (`f98b1fc`).*

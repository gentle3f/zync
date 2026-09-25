# Zync Object-First V2 — Wave-B Production Remediation Gate (v2.4)

Branch: `card-art-pilot-v1-20260921`
Scope: architecture/planning only. **$0.00 image-generation cost. No image was generated or visually inspected this checkpoint.**

Starting point: Canary-24 + Wave-B-48 execution commit `6848b4b`.

## 1. Wave-B-48 authoritative visual QA recorded

`tools/card_art/output/production_rollout_v2_object_first_v1/wave_b_48_qa_results_v1.json`. Of the 48 Wave-B outputs, 33 were visually reviewed by ChatGPT:

- **Approved: 22**
- **Approved with minor: 4** (learning.model_united_nations, business.coworking, business.startup_meetups, outdoors.surfing)
- **QA quarantine: 7** (learning.book_genre.booktube, food.coffee, music.singing, music.karaoke, learning.fiction, technology.gadgets, wellness.stretching)
- **Unreviewed, still `generated_pending_qa`: 15** (not approved, not quarantined, not migrated to v2.4 - only pending rows moved)

Systemic findings: 33/33 reviewed cards had zero real-human leakage, no mascot substitution, no brand/IP or text-control collapse. Two systemic warnings drove this checkpoint: (1) music semantic routing failures extend beyond genre identity into vocal-performance identity; (2) human-operated-object physical logic still has gaps beyond the food-utensils domain already fixed post-Validation-16.

**Wave-C status: `HOLD_FOR_REMEDIATION`.**

## 2. Music generation hold expanded

`music_semantic_temporary_hold_v2.json`. Scope A (genre-specific, unchanged): 261 ids, `music_genre_semantic_repair`. Scope B (NEW, vocal/performance-identity): `music_vocal_semantic_repair`, covering `music.choir` and `music.a_cappella` only - determined via catalog semantics (`recipe.archetype === 'performance'` AND the id genuinely lacks a mediating instrument object), not substring matching. `music.singing`/`music.karaoke` are excluded from the hold (already generated + quarantined, handled via Part 7's dedicated grammar fix instead). **Total held: 263.**

## 3. Isolated semantic failures - exact-ID determination

`isolated_semantic_hold_determination_v1.json`. For all 3 (booktube, gadgets, stretching): **exact-ID only**, no broader archetype-level hold. Evidence: `technology.ai` (same archetype + rule as gadgets) and `wellness.pilates`/`wellness.yoga` (same archetype + rule as stretching) already passed cleanly, proving the shared rule works correctly in general - each failure traces to that specific hobby's own recipe forcing an ill-fitting framing, not a rule-family defect.

## 4. Human-operated-object physical-logic gate (Part 4)

New catalog-wide, always-on policy field `human_operated_object_gate_v2` in `global_style_v2_object_first.json`, wired unconditionally into `compileObjectFirstPromptV2.js`'s physical-logic section (every compiled prompt, not just domain-specific ones). Core principle: an object normally requiring a human hand must be shown resting/completed/paused unless a plausible mechanical/automated cause explains its motion. Includes the exact bad/good example list from the task spec (kettle, pen, brush, scissors, mic, racket, camera, book pages).

## 5-8. Targeted grammar fixes

7 new id-exact structural containment rules added to `structural_containment_rules_v2.json`, routed via new `id_prefix_overrides` entries in `object_first_rules_v2.json` (all `confidence: extrapolated` - not yet visually validated):

| id | new rule | fix |
|---|---|---|
| `food.coffee` | `coffee_ritual_resting_scene` | resting-only coffee anchors (beans, cup, grinder, dripper on server, kettle on counter, steam) - `food.specialty_coffee` untouched |
| `learning.fiction` | `fiction_object_first_grammar` | open novel/manuscript, stacked books, resting pen, bookmarks, abstract story motifs - no floating pen, no readable prose |
| `music.singing` | `vocal_singing_object_first` | mounted mic/stand, pop filter, vocal booth - **reinforced with explicit indoor-precedence sentence** (see caveat below) |
| `music.karaoke` | `karaoke_object_first` | mounted mic, karaoke machine/screen, lounge lighting - **reinforced with explicit warm-indoor-precedence sentence** (see caveat below) |
| `learning.book_genre.booktube` | `booktube_creator_setup_no_presenter` | books + camera-on-tripod + mic, no operator, no factory/conveyor framing |
| `technology.gadgets` | `consumer_gadgets_object_hero` | unbranded consumer-device still life; `protagonist_type` changed `abstract_system` → `object` |
| `wellness.stretching` | `stretching_mobility_props_no_body` | mat/band/strap/roller, no large gym machine |

Also fixed a genuine shadow bug in `physical_logic_domains_v2.json`: `wellness_experience` was a stale duplicate in `water_environment.applies_to_archetypes` left over from its reclassification to `environment_led` - the same first-match-wins pattern already found and fixed twice before (solo_action/tool_sport, tech_workspace/vehicle_machine). `calm_wellness` (which legitimately includes water_environment, shared with `wellness.cold_plunge`) was intentionally left untouched.

**Known caveat, disclosed not silently fixed:** `music.singing`/`music.karaoke` still hash-route (routing logic unchanged) to an ambient `scene_family`/`palette_lighting_route` that textually conflicts with their new grammar - `open_daylight_outdoor` ("un-enclosed by walls") for singing, `rainy_moody` ("rain-light") for karaoke, the latter plausibly the direct cause of the original street-rain failure. Each rule's `scene_template` was reinforced with an explicit precedence sentence instructing the model to disregard the conflicting ambient text, but the conflicting text itself remains present in the compiled prompt (removing it would need a per-id routing-level override beyond this task's scope). Flagged for specific attention when Sentinel-6 is reviewed.

## 9. Full recompile + v2.4 candidate

`buildProductionCandidateV24Migration.js`: recompiled all 2,208 non-quarantined rows, deterministic across two independent runs (byte-identical). **All 2,208 rows' compiled prompt text changed** (the new gate is catalog-wide and unconditional) and received a new SHA256 - reported honestly, not assumed.

- `production_candidate_freeze_v1.json` (v2.3): **untouched, read-only**.
- NEW `production_candidate_freeze_v2_4_v1.json`: all 2,208 rows at their current compiled state, each carrying `previous_v2_3_prompt_sha256` for provenance.
- Production queue: `prompt_sha256`/`production_candidate_version` updated to `v2.4` for **2,135 rows** (never-yet-generated, held or not). **73 rows preserved untouched at historical v2.3** (24 Canary + 48 Wave-B already-generated + 1 `business.startups` reuse candidate) - including all 9 quarantined ids, whose failed v2.3 asset/prompt stay exactly as recorded; any future authorized retry computes a fresh v2.4+ prompt at that time.
- 17-point zero-cost audit (`v2_4_static_audit_v1.json`): **all checks passed**, including the 6 targeted regression tests (food.coffee, learning.fiction, singing/karaoke anchors, booktube, gadgets, stretching), V1-guard, determinism, queue integrity, no-image-API-call.

## 10. Wave-C

Remains **`HOLD_FOR_REMEDIATION_VALIDATION`**. Not built, not authorized.

## 11-12. Sentinel-6 plan (NOT executed)

`sentinel_6_plan_v1.json`. Exactly 6 ids: `food.coffee`, `learning.fiction`, `music.singing`, `music.karaoke`, `learning.book_genre.booktube`, `technology.gadgets` (wellness.stretching intentionally excluded from this first paid sentinel, kept as a static-regression/held row). All prompts SHA256-recorded against the v2.4 freeze, mechanically ready for a future runner using the same `loadFrozenRows()` verify-or-abort pattern as every prior runner. Diversity check: mild natural overlap only (no concentration collapse); no artificial re-diversification applied since semantic correctness took priority. **Future cost: 6 × $0.0168 = $0.1008 - NOT spent.**

## 13. Queue/version migration rules

Documented in `v2_4_migration_record_v1.json`: v2.3 freeze never rewritten; new v2.4 freeze is a separate immutable snapshot; only `pending_generation` rows move to v2.4 in the queue; all 73 already-decided rows (generated, approved, quarantined, or reuse-candidate) keep their exact v2.3 historical record; a future quarantine retry computes a fresh prompt at that time rather than being silently back-filled now.

## 14. Unsampled Wave-B rows

The 15 unreviewed Wave-B outputs remain `generated_pending_qa` - not approved, not quarantined, not migrated (they are non-`pending_generation`, so untouched by the v2.4 migration), not regenerated.

## 15. Zero-cost validation

All 17 Part-9 checklist items pass (see `v2_4_static_audit_v1.json`). No image-generation API call occurred this checkpoint (structurally verified, not just asserted).

## Readiness

**Sentinel-6 is mechanically ready but NOT authorized or executed.** Wave-C remains on hold pending Sentinel-6 results.

---

*Continues from `AI_STATE/HANDOFF_20260925_CARD_ART_OBJECT_FIRST_V2_PRODUCTION_ROLLOUT_PLAN.md` (rollout infrastructure, `3ca31bd`) and the Canary-24/Wave-B-48 execution commit `6848b4b`.*

# Zync Object-First V2 — v2.4.1 Narrow Pre-Sentinel Cleanup

Branch: `card-art-pilot-v1-20260921`
Scope: architecture/planning only. **$0.00 image-generation cost. No image was generated or visually inspected this checkpoint.**

Starting point: v2.4 checkpoint commit `cc1e023`.

## Objective

Resolve exactly two disclosed pre-Sentinel issues, narrowly - not a broad v2.4 redesign.

## 1. music.singing / music.karaoke contradiction - fixed structurally

The prior checkpoint's fix appended a precedence sentence ("this scene must read as X regardless of...") to each rule's `scene_template`, but the compiled prompt still contained the literal conflicting ambient text (an "open outdoor space" scene-structure line for singing; a "rain-light" palette line for karaoke) alongside it. That is not internally coherent and was explicitly disclosed as a caveat, not silently accepted.

**Real fix:** a new, reusable, deterministic compatibility constraint. `structural_containment_rules_v2.json` rules may now declare `forbidden_scene_families` / `forbidden_palette_routes`. `objectFirstV2Router.js` gained `constrainedPick()` - when a rule declares a forbidden list, the initial deterministic hash pick is rejected if it lands on a forbidden value, and a second deterministic hash (a distinct salt, not a retry loop, never random) selects among only the compatible remaining values. `deconflictSceneFamilies()` (the catalog-wide sliding-window scene-family de-collision pass) was also updated to respect the same forbidden list - previously it could reassign a row back into a forbidden value purely to resolve local window collision, which would have silently reintroduced the exact contradiction the constraint exists to prevent.

Both `vocal_singing_object_first` and `karaoke_object_first` now declare `forbidden_scene_families: [open_daylight_outdoor, cool_night_outdoor, nature_environmental]` and `forbidden_palette_routes: [rainy_moody]`. The now-redundant "regardless of..." sentences were removed from both `scene_template`s since the contradiction they guarded against can no longer occur.

**Result (see `v2_4_1_narrow_fix_record_v1.json`):**

| id | before scene_family / palette | after scene_family / palette |
|---|---|---|
| `music.singing` | `open_daylight_outdoor` / `dusk_transition` (contradictory) | `warm_intimate_interior` / `dusk_transition` (coherent) |
| `music.karaoke` | `cool_night_outdoor` / `rainy_moody` (contradictory) | `architectural_grand` / `cool_daylight_shade` (coherent) |

Both retain their repaired semantic anchors (mounted mic/stand, vocal booth / karaoke machine + lounge lighting), remain zero-human, and no unrelated instrument is substituted.

## 2. Deterministic routing preserved

No randomness introduced. `constrainedPick()` is a pure function of `(id, dimension, forbidden list)` - fully reproducible, verified via the standard two-independent-compiles determinism check (byte-identical).

## 3. Versioning - v2.4.1

The v2.4 freeze (`production_candidate_freeze_v2_4_v1.json`) was **not** mutated. A new, narrow snapshot `production_candidate_freeze_v2_4_1_v1.json` was written, comparing every row's newly recompiled prompt hash against its v2.4 (not v2.3) freeze hash.

**Exactly 3 of 2,208 rows changed** (not a catalog-wide diff this time, since the fix is scoped to 2 rules plus their local scene-family de-collision window): `music.singing`, `music.karaoke`, and `music.piano` (a de-collision-window neighbor whose reassignment shifted once singing's window-local scene_family changed - a real, disclosed, deterministic consequence, not a bug).

**Queue update:** only rows that are both `pending_generation` AND whose hash actually changed move to `v2.4.1`. That was **1 row** (`music.piano`) - `music.singing`/`music.karaoke` are already generated+quarantined (non-`pending_generation`), so their queue record stays untouched at historical v2.3, exactly as v2.4's migration rules require. 2,134 rows stayed at v2.4 (untouched, no version churn for unchanged rows). All 73 already-decided rows (24 Canary + 48 Wave-B + business.startups reuse) remain preserved at their historical v2.3 record.

The Sentinel-6 plan (`sentinel_6_plan_v1.json`) now sources `music.singing`/`music.karaoke`'s prompts from the new v2.4.1 freeze (the repaired versions) while the other 4 sentinel cards stay v2.4 (unchanged).

## 4. wellness.stretching - status reconciled

Previous report inconsistency resolved to one canonical state: `generation_status: "temporary_generation_hold"`, `generation_hold_reason: "semantic_repair_unvalidated"`, `quarantine_status: "not_quarantined"` (superseded by the hold). Its prior `visual_qa_disposition: qa_quarantine` and finding are preserved for history. It remains excluded from Wave-C and from Sentinel-6 until visual validation or explicit release - not counted as an unresolved architecture error, since its grammar is already repaired (`stretching_mobility_props_no_body`, from the prior checkpoint), only unvalidated.

## 5. Zero-cost checks

All pass (`v2_4_1_narrow_fix_record_v1.json`'s `checks` block): 2,208/2,208 compile, deterministic across two runs, no unresolved placeholders, no internal-id leak, both fixed prompts contain zero-human language and their repaired anchors, no outdoor/rain contradiction in either, scene-family distribution stays healthy (no new concentration collapse from the 3-row shift).

## 6. Sentinel-6 - unchanged scope, updated readiness

Same 6 ids: `food.coffee`, `learning.fiction`, `music.singing`, `music.karaoke`, `learning.book_genre.booktube`, `technology.gadgets`. All now point to internally coherent frozen prompts (mixed v2.4/v2.4.1 per card, tracked explicitly in the plan file). **Not generated.** Future cost unchanged: 6 × $0.0168 = $0.1008.

## 7. No further validation added

`wellness.stretching` was not added to Sentinel-6. No Sentinel-7. No Wave-C. No broad validation batch.

---

*Continues from `AI_STATE/HANDOFF_20260925_CARD_ART_V24_WAVEB_REMEDIATION.md` (`cc1e023`).*

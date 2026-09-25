# Zync Object-First V2 — Post-Validation-16 Targeted Architecture Fix

Branch: `card-art-pilot-v1-20260921`
Starting commit: `53f72d2`
Scope: architecture-only, $0.00 image-generation cost. No image was generated or visually inspected this checkpoint.

## Authoritative visual findings (input, not re-derived)

The paid Validation-16 batch (commit `53f72d2`) was visually reviewed by ChatGPT. Those findings were supplied as authoritative input and used exactly as given, without Claude opening any image:

- 16/16 zero-human containment held — object-first remains the right default direction.
- 3 substantive failures: `transport.modelrailways` (scale identity lost, read as a real railway), `food.japanese` (floating chopsticks — invisible-human physics), `media.anime` (lost anime identity, pseudo-Japanese text).
- 5 minor semantic-neighbor confusions: `business.startups` (too narrow, read as pure electronics prototyping), `music.pop` (read as vinyl/hi-fi listening), `learning.model_united_nations` (excessive unreliable text), `business.marketing` (pseudo-text/pseudo-diagrams), `learning.mock_trial` (read as ordinary legal practice).
- 7 clean passes to preserve unchanged: `sports.badminton`, `outdoors.swimming`, `pets.dogs`, `technology.ai`, `business.public_speaking`, `business.founder_meetups`, `business.coworking`.
- Set-level finding: routing-label diversity (composition/palette/effects) was statistically healthy but the **rendered** images still converged on one repeated pattern (dark/blue interior + warm lamp + empty table + cozy atmosphere) — proof that label diversity ≠ rendered diversity.

## Part A — semantic identity / scale layer

New spec `specs/semantic_identity_anchors_v2.json`: positive anchors + anti-confusions for the 3 substantive-fail + 2 of the minor-confusion ids that needed dedicated grammar (`transport.modelrailways`, `media.anime`, `business.startups`, `music.pop`, `learning.mock_trial`). Each gets a new dedicated containment rule in `structural_containment_rules_v2.json` (`model_railway_miniature_scale`, `anime_culture_object_first`, `startup_early_stage_world`, `pop_music_production_energy`, `mock_trial_simulation`) wired in via a new id-exact override in `object_first_rules_v2.json` (all `confidence: new_grammar_unvalidated`).

**Bug found and fixed while building this:** editing the containment-rules JSON initially left a stray closing brace, silently splitting the `rules` object and putting the 5 new rules outside it (still valid top-level JSON, but invisible to `ctx.containmentV2.rules[id]` lookups). Caught immediately via `node -e "require(...)"` before any compile attempt, fixed by removing the stray brace.

## Part B — recipe-aware physical logic

New spec `specs/physical_logic_domains_v2.json`: 7 reusable domain rules (`food_utensils`, `tool_sport`, `instrument`, `vehicle_machine`, `ball_object_flight`, `water_environment`, `abstract_system`) mapped from archetype, not hobby-by-hobby. The compiler appends the shared generic physical-logic rule (unchanged) plus the matching domain rule (if any) as one additional sentence. `food_utensils` directly targets the `food.japanese` failure (chopsticks must rest on a support, never lift food in mid-air).

**Bug found and fixed:** the first draft of `water_environment`'s rule text literally named the internal rule id `swimming_hard_case_no_visible_swimmer` inside model-facing prose, which tripped the compiler's own internal-id-leak guard (`compileObjectFirstPromptV2` correctly threw rather than silently emitting a broken prompt). Fixed by rewriting the sentence to describe the constraint generically instead of naming the internal id.

## Part C — text-mode routing

New spec `specs/text_modes_v2.json`: 3 modes (`text_none`, `text_incidental_nonlegible`, `text_constrained_literal`) replacing the single shared text-policy paragraph. Archetype defaults derived from the existing `text_risk` archetype set; 3 explicit id overrides:

- `learning.model_united_nations` → **chose the non-literal route** (`text_incidental_nonlegible`), not `text_constrained_literal`. Documented rationale: asking Gemini to render specific accurate country names/committee abbreviations as literal text is exactly the uncontrolled-generated-copy risk this architecture exists to avoid. Diplomatic-conference identity is carried instead by a semicircular delegate-desk arrangement, blank/abstract placards, and generic unlabeled flag fabric — no literal country label requested at all.
- `business.marketing` → reinforced with explicit anti-KPI/anti-slogan language.
- `gaming.video` → reinforced with explicit anti-pseudo-Japanese-poster language.

## Part D — scene-family anti-convergence router

New `scene_family` dimension added to `composition_diversity_v2.json`: 13 genuinely distinct experiential-structure values (`open_daylight_outdoor`, `cool_night_outdoor`, `bright_clean_interior`, `dark_cinematic_interior`, `warm_intimate_interior`, `industrial_workshop`, `technical_lab`, `architectural_grand`, `overhead_tabletop_scene`, `macro_material_scene`, `nature_environmental`, `minimal_studio`, `exhibition_display`) — independent of and orthogonal to `composition_archetype` and `palette_lighting_route`, specifically to stop the Validation-16-observed rendered pattern from being the default fallback.

Assignment is two-pass: (1) deterministic per-id hash pick (`objectFirstV2Router.js`), then (2) a new exported `deconflictSceneFamilies(rows, values, window, maxRepeats)` function runs once over the full ordered catalog and deterministically reassigns any row whose `scene_family` repeats more than once within a 6-row sliding window. `compileAll()` in `auditObjectFirstV2.js` was extended to run this pass and, for any row it reassigns, patch just the "Overall scene structure:" line in that row's already-compiled prompt (not a full recompile) so the prompt text always matches its recorded `scene_family`.

**Explicit disclaimer, stated in the audit output itself, not just this handoff:** this proves prompt-level scene-family diversity only. It cannot prove rendered visual diversity — only a future image batch can.

## Full 2208-row zero-cost recompile — results

```
1. 2210/2210 eligible rows route, 2208 compile: PASS
2. Deterministic across two independent runs (full compile, incl. deconfliction pass): PASS
3. V1 files unchanged (6 guard files hashed before/after): PASS
4. Production queue unchanged: PASS
5. Quarantine unchanged (2/2 excluded): PASS
```

**Semantic-regression tests (Part A, 5 ids):** all 5 pass — correct new rule id assigned, required anchor phrases present in the actual compiled text. One test-authoring bug found and fixed: the `transport.modelrailways` check initially required the ABSENCE of "photography of an actual place", not realizing that phrase is the rule's own intentional "never render X" negation clause — a false positive in the test, not the prompt. Fixed by removing that check.

**Physical-logic domain regression (Part B, `food.japanese`):** `physical_logic_domain=food_utensils` correctly assigned, and the compiled prompt contains the literal fix sentence ("chopsticks rest on a chopstick holder..."). PASS.

**Preserved-successes regression (7 Validation-16 PASS ids):** all 7 kept their exact pre-existing `structural_containment_rule_id` unchanged. PASS.

**Text-mode distribution:** `text_none: 1513 (68.5%)`, `text_incidental_nonlegible: 695 (31.5%)` — matches the pre-existing `text_risk` archetype split exactly, as designed.

**Physical-logic domain distribution:** `food_utensils: 332`, `instrument: 321`, `vehicle_machine: 276`, `tool_sport: 210`, `water_environment: 101`, `ball_object_flight: 73`, `null (no domain match): 895`.

**Scene-family distribution:** spread 158–187 across 13 values (uniform baseline ≈170) — `open_daylight_outdoor: 158, architectural_grand: 160, technical_lab: 165, macro_material_scene: 166, nature_environmental: 163, exhibition_display: 168, warm_intimate_interior: 169, bright_clean_interior: 171, dark_cinematic_interior: 171, minimal_studio: 173, overhead_tabletop_scene: 176, industrial_workshop: 181, cool_night_outdoor: 187`. **Zero concentration problems flagged** (no value exceeds double the uniform baseline).

**Sliding-window audit:** 2203 windows checked (window=6), **0 windows contain a repeat** after deconfliction — the de-collision pass is working exactly as designed.

**Per-archetype-group scene-family spread** (business/learning/social_community/professional/legal/gaming_media): all groups show genuinely even spread, e.g. business (147 rows) ranges 7–14 per family with no single family dominating — direct evidence against the specific "empty warm office" collapse risk the task called out.

**Top repeated triples:** max count is 14/2208 (0.6%) for any single scene_family×composition×palette combination — no meaningful clustering.

**Static prompt QA (unchanged checks from the prior checkpoint, re-run):** `all_clean: true` — 0 positive human-role leaks, 0 human-medium leaks, 0 internal contradictions, 0 brand leaks, 0 incomplete-section prompts.

**All 23 zero-cost validation gates pass** (12 carried over unchanged + `v13`–`v17` from the prior checkpoint + 6 new: `v18` semantic fixes, `v19` physical-logic domain routing, `v20` text_mode coverage, `v21` scene_family coverage, `v22` no brand-policy regression, `v23` no zero-human containment regression).

## Before/after prompt audit (9 targeted ids)

Written to `output/object_first_v2_full_catalog_audit_v1/before_after_9_ids_v1.json` (SHA256 for old and new prompt, exact new prompt text, and which routing fields changed). All 9 prompts changed (as expected — every row gained `scene_family`/`text_mode`/`physical_logic_domain`, which didn't exist before). The 5 semantic-fix ids additionally changed `structural_containment_rule_id` and `confidence`; the other 4 (`food.japanese`, `learning.model_united_nations`, `business.marketing`, `gaming.video`) kept their existing containment rule, only gaining the new dimensions plus (for MUN/marketing/gaming.video) reinforced text-mode guidance.

## Validation-8 hard-sentinel plan (proposed, NOT generated)

Written to `catalog/object_first_v2_validation_8_plan_v1.json`. Exactly the 8 task-specified ids: `transport.modelrailways`, `food.japanese`, `media.anime`, `business.startups`, `music.pop`, `learning.model_united_nations`, `business.marketing`, `learning.mock_trial`. **Expected cost: 8 × $0.0168 = $0.1344. Not spent.**

**Diversity check, done honestly:** the initial independent hash-based `scene_family` assignment for this small fixed set showed real convergence risk (3/8 landed on `dark_cinematic_interior`). Per the task's explicit instruction to adjust routing (not semantics) if needed, the same deterministic sliding-window de-collision algorithm was applied locally to just these 8 cards (window=8), reassigning only the `scene_family` field (and its one corresponding prompt sentence) for 5 of the 8 cards. Result: **`scene_family` now 8/8 unique** across the set. `composition_archetype` remains partially repeated (`strong_diagonal` ×3, `low_angle_kinetic` ×2) and was **not** further forced, since these are fixed, semantically-load-bearing ids and the task explicitly prioritizes semantic identity over forced diversity — disclosed as a residual, not hidden. `text_mode` is 2/8 unique (`text_none` ×3, `text_incidental_nonlegible` ×5 — expected, matches these ids' actual text-risk profile, not a defect). `physical_logic_domain` is null for 6/8 (expected — only food and instrument-adjacent archetypes get a domain).

## Remaining architectural caveats

- **Rendered visual diversity remains completely unvalidated.** Everything in Part D is a prompt-level, deterministic guarantee. Whether it actually reduces the observed "dark interior + warm lamp + cozy table" rendered pattern can only be proven by the next paid image batch.
- **372 `new_grammar_unvalidated` + 8 `weak_extrapolation` rows** from the prior checkpoint remain unvisually-tested, now joined by 5 more `new_grammar_unvalidated` rows from this checkpoint's semantic fixes.
- **`business.startups`, `music.pop`, `learning.mock_trial`** fixes are text-plausible but, like everything else this checkpoint, unvalidated by any image.
- **The `learning.model_united_nations` text-mode decision (non-literal route) is a judgment call**, not a certainty — if a future visual test shows the non-textual diplomatic cues (semicircle desks, generic flags) don't read clearly as "Model UN" without any literal text at all, `text_constrained_literal` with a tightly whitelisted set of strings would need to be reconsidered.
- **Physical-logic domain coverage is partial by design** (895/2208 rows have no matching domain) — only the 7 domains most directly implicated by real or plausible physics-cliché risk were built; this is not a claim that every remaining row is physics-risk-free, only that no round has found a comparable failure in an unmapped archetype yet.

## Files changed this checkpoint

New: `specs/semantic_identity_anchors_v2.json`, `specs/physical_logic_domains_v2.json`, `specs/text_modes_v2.json`, `catalog/object_first_v2_validation_8_plan_v1.json`.
Modified: `specs/object_first_rules_v2.json` (5 new id-exact overrides), `specs/structural_containment_rules_v2.json` (5 new rules), `specs/composition_diversity_v2.json` (new `scene_family` dimension), `src/objectFirstV2Router.js` (`text_mode`/`physical_logic_domain`/`scene_family` assignment + new `deconflictSceneFamilies()` export), `src/compileObjectFirstPromptV2.js` (wires all 3 new dimensions into the compiled prompt), `src/auditObjectFirstV2.js` (compileAll's deconfliction pass, 6 new validation gates, scene-family/before-after/regression report files, removed the now-stale Validation-16 plan builder).

---

*Continues from `AI_STATE/HANDOFF_20260925_CARD_ART_OBJECT_FIRST_V2_FINAL_ZERO_COST_GATE.md` (`4eba93c`) and the Validation-16 paid execution (`53f72d2`). Part of the isolated object-first research track, separate from the paused production V1/D4 track.*

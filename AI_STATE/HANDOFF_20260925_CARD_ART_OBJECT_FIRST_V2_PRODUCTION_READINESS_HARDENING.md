# Zync Object-First V2 — Final Production-Readiness Hardening

Branch: `card-art-pilot-v1-20260921`
Starting commit: `c7d00b9`
Scope: architecture-only, $0.00 image-generation cost. No image was generated or visually inspected this checkpoint.

## Addendum (2026-09-25): Recheck-3 results + v2.3 single-sentinel fix

Recheck-3 (commit `7425cce`, authorized paid batch, ChatGPT-reviewed) found:

- `media.anime`: **PASS** - anime production/collecting grammar worked, no `IMAGE_SAFETY` block. Not modified further.
- `learning.mock_trial`: **PASS/MINOR** - character-substitution problem solved. Not modified further.
- `business.startups`: **semantically improved but visual FAIL** - the v2.2 grammar correctly stopped collapsing into an electronics-hobby reading, but the generated image showed (1) a real human arm/hand holding a product box, and (2) readable generated product text ("MINIATURE PROJECTOR") on packaging.

**v2.3 narrow fix (commit that follows `7425cce`)**, scoped to `business.startups` only: `structural_containment_rules_v2.json`'s `startup_early_stage_world` rule gained explicit resting/stacked/displayed-only physical-logic language (no product may be held, lifted, handed over, carried, or opened by any hand/arm/finger, no cropped limb/silhouette/reflection anywhere in frame) and explicit blank/abstract-packaging text language (no readable product name, model number, feature list, slogan, or brand name, including invented ones), on top of the already-working v2.2 business-creation identity, which was left untouched. `text_modes_v2.json` gained an explicit `business.startups` id override reinforcing the same no-product-name constraint (the archetype default already used `text_incidental_nonlegible`, but the generic guidance alone wasn't specific enough for a packaging context).

Verified before submission: `media.anime` and `learning.mock_trial` compiled-prompt SHA256 unchanged (byte-identical) from `7425cce`; full 2208-row zero-cost audit re-run, all validations pass; `business.startups` semantic-fix regression test still passes (rule id unchanged, anchor phrases present, anti-confusion clean).

A single authorized image was generated for `business.startups` only (`$0.0168`, 1/1 succeeded) to test the v2.3 fix - see `tools/card_art/output/object_first_v2_startups_final_recheck_v1/` for the exact prompt, SHA256, routing metadata, and technical validation report. No visual QA was performed by Claude; the result is pending ChatGPT review.

## Authoritative visual findings (Validation-8, input, not re-derived)

- **PASS, do not destabilize:** `transport.modelrailways`, `sports.badminton`, `outdoors.swimming`, `pets.dogs`, `technology.ai`, `music.pop`, `learning.model_united_nations`, `business.marketing` (minor).
- **PASS/MINOR:** `food.japanese` (floating-chopstick fix confirmed working; minor residual pseudo-Japanese packaging text, not addressed this round - out of the 3 explicit targets).
- **FAIL:** `business.startups` - still read as an electronics/hardware maker workshop despite the prior round's broadening attempt.
- **UNRESOLVED (no image):** `media.anime` - Gemini returned `finishReason=IMAGE_SAFETY`, no image produced.
- **MINOR/residual problem:** `learning.mock_trial` - courtroom identity improved, but the model substituted anthropomorphic owl mascots for human courtroom participants, a character-substitution failure mode not previously anticipated.
- **Set-level:** the `scene_family` anti-convergence architecture visually worked - the 7 successful images were materially more diverse. Per explicit instruction, `scene_family`, composition, palette, effects routing, and zero-human containment are considered validated at the architecture level and were **not** broadly rewritten this checkpoint.

## Part A — business.startups (v2.2 rewrite)

`startup_early_stage_world`'s scene_template was rewritten to **lead with non-electronics business-creation evidence** (packaging mockups, market/customer-research note cards, a roadmap-like card arrangement, retail-ready product samples) and explicitly cap any hardware/electronics presence as "a minor background detail... never shown mid-repair or mid-assembly with exposed wiring or circuit boards as the focal point." The anti-confusion list was extended to explicitly name every failure mode found or plausible: electronics workshop, maker space, robotics lab, hardware-repair bench, 3D-printing hobby, coding workstation.

## Part B — media.anime safety + identity (v2.2 rewrite)

`anime_culture_object_first` was rewritten around a specific hypothesis: the prior grammar's repeated use of the word **"character"** (character designs, character silhouettes) is the likely IMAGE_SAFETY trigger, since that combination with figurines/display-stands reads as ambiguous human-character content to the safety system even though no human or sexualized content was ever requested. The rewrite:

- Removes every instance of "character" wording.
- Anchors exclusively on **non-human fictional subject matter**: mecha, robots, fantasy creatures, spaceships, stylized animals - never a human or human-shaped figure.
- Adds explicit negative coverage for every risk category the task named: no school uniforms, no cosplay, no youthful or human-like character imagery, no body-focused or suggestive framing, no bedroom poster-wall staging.
- No weird safety-disclaimer boilerplate was added - the fix is entirely through positive scene construction (per the task's own instruction).

**Explicitly disclosed:** whether this actually resolves the IMAGE_SAFETY block is unknown and unknowable without a real generation attempt - this is a hypothesis-driven rewrite, not a guaranteed fix.

## Part C — learning.mock_trial character substitution (v2.2 rewrite)

`mock_trial_simulation`'s scene_template gained an explicit local clause: "The tables, witness stand, and judge's bench must all be shown genuinely empty - no anthropomorphic animal, mascot, robot, or any other costumed or creature stand-in occupying any seat or position in place of a human participant." This sits on top of the new catalog-wide policy (Part D).

## Part D — global character-substitution policy (new, catalog-wide)

New field `character_substitution_policy` in `global_style_v2_object_first.json`, now **appended unconditionally to every one of the 2208 compiled prompts** (not just the 3 ids that motivated it): forbids anthropomorphic animals, mascots, humanoid robots, or fantasy creatures filling an excluded human's role, with explicit, named exceptions (real animal hobbies, tabletop miniatures, statues/figurines, media/collectible figures, hobbies literally about robots). Verified present in all 2208 prompts (`v24_character_substitution_policy_present_catalog_wide: PASS`).

This is a genuine, previously-unanticipated architecture gap: every prior checkpoint's zero-human policy said what must be *absent* (a human) but never said a costumed substitute is equally forbidden. Validation-8 is what surfaced it.

## Part E — physical-logic coverage hardening

**Two real bugs found and fixed while reviewing the existing taxonomy**, both silent "shadow" bugs where an archetype was listed under two domains and the earlier-defined one always won, making the second entry dead code:

1. `solo_action` was listed in both `tool_sport` (defined first) and `ball_object_flight` - the latter's `solo_action` entry was always shadowed. Removed the duplicate.
2. `tech_workspace` was listed in both `vehicle_machine` (defined first) and `abstract_system` - **`abstract_system` was never actually selected for any row despite existing in the spec since the checkpoint that created it.** Removed `tech_workspace` from `vehicle_machine`, leaving it exclusive to `abstract_system` where it semantically belongs (matches `technology.ai`'s own `abstract_system_no_operator` containment rule).

**A third bug, same class as before, caught before any output was trusted:** the first draft of the `abstract_system` domain's rewritten `rule_text` referenced the internal containment-rule name `abstract_system_no_operator` directly in prose, which the compiler's own internal-id-leak guard correctly caught and threw on (`technology.ai: internal identifier "abstract_system" leaked into model-facing text`). Fixed by rewriting the sentence generically. This is the third occurrence of this exact mistake across the V2 checkpoints (`swimming_hard_case_no_visible_swimmer` at the compiler-conflict-gate checkpoint, now this one) - a pattern worth remembering for any future rule-text authoring.

**Coverage extended from 24/39 to 39/39 archetypes** via 4 new lightweight, classification-only domains (`animal_protagonist`, `generic_static_object`, `environment_led`, `optical_device`), each with a real justification, not a forced placeholder. Critically, these 4 new domains are **audit/classification-only** - the compiler was updated to inject extra prompt text only for domains classified `domain_specific` (the original 7 genuine physics-risk domains), so the 895 previously-unmapped rows gained an honest classification without any prompt-text bloat.

**Result:** `physical_logic_classification_distribution: { domain_specific: 1313, generic_static_safe: 895 }`. **`residual_review: 0 (0.000%)`** - the genuine outcome of individually reviewing all 39 archetypes, not a forced target-hit (the prior checkpoint's 895-unmapped disclosure is now fully resolved with real justification, documented per-domain in `physical_logic_domains_v2.json`).

**Static risk-verb scan (new):** scanned all 2208 compiled prompts' scene-construction text for 12 risk verbs (holding, lifting, swinging, gripping, pouring, writing, playing, stirring, carrying, operating, drawing, typing) in unnegated context. **73 mentions found, 0 flagged as needing review** (all had a machine/automation cue nearby). Reported as informational, not a hard gate, per the explicit "context matters" instruction.

## Full 2208-row zero-cost recompile — results

All 27 zero-cost validation gates pass (23 carried over + 4 new: `v24` character-substitution catalog-wide, `v25` physical-logic fully classified, `v26` residual review reported honestly, `v27` no unresolved placeholders). Deterministic across two independent runs. V1 files hash-identical before/after. Production queue and quarantine unchanged.

**Two test-authoring bugs (not prompt defects) also found and fixed this round**, both the same false-positive-negation pattern already documented in prior checkpoints: the `transport.modelrailways` and `business.startups` semantic-fix regression tests initially flagged the *intentional* "never as a real railway / never with exposed wiring" negation clauses as forbidden content, not realizing those phrases are the rule's own correct negative instruction. Fixed by removing those specific `mustNotContain` checks (documented inline in the test code as a repeat of the same lesson).

**Scene-family distribution unchanged and healthy** (spread 158-187 across 13 values, same as the prior checkpoint - confirms no regression from this round's changes, which touched only 3 rule scene_templates + physical-logic domain metadata, not the routing itself).

## Before/after prompt audit (3 targeted ids)

Written to `output/object_first_v2_full_catalog_audit_v1/before_after_3_ids_hardening_v1.json`: SHA256 for old/new prompt (all 3 changed), which routing fields changed (only `physical_logic_domain`/`physical_logic_classification` - the coverage extension - since `structural_containment_rule_id` stayed the same for all 3, only the scene_template text *within* that rule changed), exact reason for each change, and the full new compiled prompt text.

## Recheck-3 plan (proposed, NOT generated)

Written to `catalog/object_first_v2_recheck_3_plan_v1.json`. Exactly the 3 task-specified ids: `business.startups`, `media.anime`, `learning.mock_trial`. **Expected cost: 3 × $0.0168 = $0.0504. Not spent.**

**Diversity check, done honestly, including a rejected fix:**
- `scene_family` and `composition_archetype`: 3/3 unique from independent hashing, no adjustment needed.
- `effect_level`: had one repeat (`restrained` ×3) - de-collided cleanly (`learning.mock_trial` → `none`), no semantic risk since effect intensity is independent of scene content.
- `palette_lighting_route`: had one repeat (`warm_intimate` ×2, `business.startups` + `media.anime`). **A de-collision attempt was tried and explicitly rejected**: it would have assigned `bright_daylight` to `media.anime`, whose `scene_family` is `cool_night_outdoor` - a real day/night semantic contradiction. Per the task's explicit "do not distort semantics merely for diversity" instruction, this was reverted and the palette repeat is disclosed and accepted rather than forced.

**Anime generation-risk note, as required:** the plan explicitly states the exact frozen prompt is submitted once; if `IMAGE_SAFETY` recurs, the failure is preserved as evidence with no automatic reroll and no prompt mutation during execution.

## Remaining architectural caveats

- Whether the `media.anime` rewrite actually resolves `IMAGE_SAFETY` is a hypothesis, not a certainty - only a real generation attempt can confirm it.
- Whether the `business.startups` and `learning.mock_trial` rewrites actually fix their respective visual failures remains completely unvalidated by any image - this is what Recheck-3 exists to test.
- `food.japanese`'s minor residual pseudo-Japanese packaging text was explicitly out of scope this round (not one of the 3 named targets) and remains unaddressed.
- 895 rows now classified `generic_static_safe` receive no extra physical-logic prompt text by design - this is a deliberate scope decision (avoid bloating prompts for domains judged low-risk), not a claim that all 895 are risk-free; a future round could revisit specific ones if a visual failure surfaces.
- The character-substitution policy is new and, beyond the one confirmed `learning.mock_trial` case, is unvalidated across the rest of the catalog - it is plausible other excluded-human archetypes could exhibit the same substitution behavior undetected until visually tested.

## Files changed this checkpoint

Modified: `specs/global_style_v2_object_first.json` (new `character_substitution_policy`), `specs/structural_containment_rules_v2.json` (3 rewritten scene_templates), `specs/physical_logic_domains_v2.json` (2 shadow-bug fixes, 4 new domains, `classification` field on every domain), `src/objectFirstV2Router.js` (`physical_logic_classification` field), `src/compileObjectFirstPromptV2.js` (character-substitution section, classification-gated domain text injection), `src/auditObjectFirstV2.js` (4 new validation gates, character-substitution/physical-logic-classification/risk-verb report files, extended preserved-successes list).
New: `catalog/object_first_v2_recheck_3_plan_v1.json`.

---

*Continues from `AI_STATE/HANDOFF_20260925_CARD_ART_OBJECT_FIRST_V2_POST_VALIDATION_ARCHITECTURE_FIX.md` (`2208ce3`) and the Validation-8 hard-sentinel paid execution (`c7d00b9`). Part of the isolated object-first research track, separate from the paused production V1/D4 track.*

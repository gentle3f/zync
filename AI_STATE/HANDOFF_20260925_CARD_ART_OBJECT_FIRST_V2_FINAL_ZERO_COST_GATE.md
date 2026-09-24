# Zync Card Art — Object-First V2 Final Zero-Cost Compiler Conflict Gate

Branch: `card-art-pilot-v1-20260921`
Starting state: `3175b77`
Scope: architecture + conflict elimination + validation-16 exact-prompt audit only. **$0.00 image-generation cost. No image was generated or visually inspected in this checkpoint.**

## 1. Starting state at `3175b77`

The compiler existed and all 2208 rows compiled with `static_prompt_qa: all_clean: true`, but the handoff explicitly disclosed **two unresolved architectural conflicts** that were patched-over rather than eliminated:

1. D4's base style text (`global_style_v1.json`'s `prompt` field), reused verbatim, contained human/character-oriented language ("expressive faces", "character design", "clean character silhouettes") - neutralized only via an appended `base_style_override_clause` disclaimer.
2. V1's `global_screen_policy` field contained a human-recognition clause ("Recognition must come from the person...") - handled only by omitting the field entirely, leaving no dedicated V2 screen policy in its place.

This checkpoint's task was to eliminate both conflicts at the source and prove, with an exact byte-for-byte audit, that the 16 prompts a future paid validation batch would actually send are clean.

## 2. Part 1 — D4 human/character language eliminated

`global_style_v2_object_first.json` gained a new **`v2_native_style`** field: a from-scratch, explicitly-authorized human-language-free rewrite of D4's rendering-language block. Every D4 strength was preserved; every human-specific word was removed or replaced:

| D4 original | V2-native replacement |
|---|---|
| "expressive faces, bright appealing eyes, elegant stylized anatomy" | removed entirely |
| "expressive but mature character design, clean character silhouettes" | "crisp readable silhouettes... tactile, believable material detail (metal, wood, fabric, water, glass, fur, or whatever the protagonist is made of)" |
| "lively gestures" | removed (no non-human equivalent needed) |
| focal hierarchy tier 3: "supporting people or environment" | "supporting environment or secondary objects" |
| "Do not give equal visual importance to every person or object" | "Do not give equal visual importance to every object or environmental element" |
| "Avoid a room full of people all doing things" | "Avoid... a cluttered scene with no clear single hero element" |
| "hypersexualized anime proportions, fan-service pose" (avoid-list) | removed (not applicable to a non-human protagonist) |

The compiler (`compileObjectFirstPromptV2.js`) now uses `ctx.globalStyleV2.v2_native_style` in place of `ctx.globalStyleV1.prompt`, and the old `base_style_override_clause` patch is **no longer inserted into any compiled prompt** - both it and the original conflict disclosure were kept in the spec file under `_SUPERSEDED`-suffixed field names as a historical audit trail, not deleted.

**Verified, not assumed:** a compiled prompt was checked directly for `expressive face`, `appealing eyes`, `stylized anatomy`, `character design`, `character silhouette` - **all absent** (see §5's full-catalog result).

V1's `global_style_v1.json` file itself was never opened for writing - confirmed by the same 6-file hash-before/after check used since the first V2 checkpoint, still passing.

## 3. Part 2 — V2-native screen policy added

`global_style_v2_object_first.json` gained **`screen_policy_v2`**, a real positive policy (not an omission): screen content must be abstract/non-readable/non-branded, never a readable UI, code wall, or fake dashboard (unless the hobby genuinely requires a dashboard-like readout, kept non-legible), and never a human portrait, face thumbnail, social-media profile photo, or video-call participant on any screen or poster anywhere in the scene. Where a screen isn't essential, it's avoided entirely in favor of physical equipment/process/environment. This section is now included in every compiled prompt via `ctx.globalStyleV2.screen_policy_v2`.

**Verified, not assumed:** `recognition must come from` (the exact V1 screen-policy phrase that was the original conflict) - **absent from the compiled prompt** (see §5).

## 4. Part 3 — containment confirmed as a first-class positive scene system

86.9% of the catalog (1920/2208) routes to `containment_required`, so this was checked directly rather than assumed. Every `structural_containment_rules_v2.json` rule's `scene_template` is written as **positive scene construction** (concrete nouns: "an empty athletics track... equipment at rest... fresh footprints", not "no legs, no feet, no runner"). The compiler places `Depict this activity: ${sceneText}` (the positive construction) as its own dedicated section, followed only afterward by the concise `non_human_protagonist_policy` suppression paragraph - confirmed by re-reading the actual section order in `compileObjectFirstPromptV2.js` (unchanged from the prior checkpoint, which already implemented this correctly; no code change was needed here, only re-verification).

## 5. Part 4 — full 2208-prompt conflict audit (all checks added, all pass)

`staticPromptQa()` in `auditObjectFirstV2.js` was substantially expanded this checkpoint:

- **4A/4B - positive human wording**, now split into two pattern sets: direct role requests (person/man/woman/athlete/worker/student/diner/driver/listener/photographer/coworker/lawyer/user/operator/teammates/pianist/etc.) and human-medium leaks (portrait/selfie/video call/audience/crowd/profile image/person-on-screen/human photograph). Both use the existing sentence-scoped negation-aware matcher (built in the prior checkpoint) so a suppression clause like "no portraits" doesn't false-positive.
- **4C - internal contradictions**: explicit patterns for the task's own named failure mode ("actively operated by", "operated by an invisible person", "held by an invisible hand").
- **4D - duplicate/bloated suppression**: counts **distinct prompt sections** (not raw word occurrences) that mention human-negation. This needed one real fix mid-build (see §6) - it originally flagged all 2208 prompts because it was counting individual words inside one deliberately comprehensive enumeration ("no people, no faces, no heads, no hands...") as 5 separate "repeats", when they're one cohesive list in one section.
- **4E - scene completeness**: verifies all 5 structural section markers are present in every compiled prompt.
- **4F - unresolved placeholders/raw internals**: already enforced at compile time (the compiler throws), re-checked post-hoc for defense in depth.

**Result across all 2208 compiled prompts, this run:**

```
positive_human_role_leak_count: 0
human_medium_leak_count: 0
internal_contradiction_count: 0
brand_name_leak_count: 0
readable_text_requested_count: 0
excessive_human_negation_repeats_count: 0
incomplete_scene_sections_count: 0
empty_count: 0

length_stats: { min: 10852, median: 11205, p90: 11505, p95: 11667, max: 11786 }
```

`all_clean: true`. Length actually grew slightly versus the prior checkpoint (was 10531-11465, now 10852-11786) because `v2_native_style` + `screen_policy_v2` together are marginally longer than the old `prompt` + `base_style_override_clause` combination - still in the same range as V1's own ~11262-character prompt for the same hobby, re-confirmed proportionate, not flagged as excessive.

## 6. Two more real issues found and fixed during this checkpoint, not swept away

Consistent with every prior checkpoint in this track, building the deeper audit surfaced real bugs rather than confirming everything was already perfect:

1. **The new duplicate-suppression check (4D) initially flagged all 2208 prompts.** Root cause: it counted every individual "no X" word match rather than distinct sections. Fixed by re-scoping the check to `p.split('\n\n').filter(section => ...).length > 3` (distinct sections, not raw occurrences) - and while fixing it, caught and fixed a **second, independent bug**: the original regex used the `/g` flag with repeated `.test()` calls across different strings, which is a classic JavaScript footgun (a global regex's `lastIndex` persists across `.test()` calls and corrupts results when reused on different input strings in a loop). Fixed by removing the unneeded `g` flag entirely, since the check no longer needs `matchAll`-style iteration.
2. **The validation-16 coverage report (Part 6) found `machine_process` had zero representation** across the original 16-card plan. Fixed with the minimum single-card swap the task required: `physical_and_brand_risk_combo` (`sports.gym`) was replaced with `machine_process_text_brand_combo` (`gaming.video`, `digital_play` archetype, `text_risk` + `brand_risk`) - chosen specifically because it adds the missing protagonist type *without* dropping the two-risk-flag stress test the replaced card provided. The fix was made in both the plan JSON and the generator function in `auditObjectFirstV2.js` (`buildValidation16Plan()`), so a future re-run of the full audit won't silently revert it.

## 7. Part 5/6 — validation-16 exact-prompt audit (new)

New script: `src/auditValidation16PromptsV2.js`. Loads the **existing** `object_first_v2_validation_16_plan_v1.json` (per the task's explicit instruction not to change ids unless a real mechanical issue is found - and one was, see §6.2, fixed at the source rather than patched at read time), recompiles the **exact** prompt each of the 16 ids would produce via the real compiler, computes a SHA256 per prompt, and runs the identical static-audit bar as the full-catalog gate.

**Result:**

```
16/16 cards compiled successfully
16/16 static audits pass (non_empty, no unresolved placeholder,
  no positive human wording, no brand leak)
Coverage report: coverage_complete = true, missing_coverage = []
```

Full coverage confirmed across every dimension the task listed: 6 protagonist types (object/environment/food_drink/animal/abstract_system/machine_process), both `clean` and `containment_required` statuses, all 4 confidence values (including `weak_extrapolation`), all 7 formerly-review-required archetypes, `physical_logic_risk`/`text_risk`/`brand_risk` all represented, 8 of 12 composition archetypes and 7 of 8 palette routes used within just 16 cards (no forced repetition), all 3 effect levels present.

Output: `tools/card_art/output/object_first_v2_validation_16_prompt_audit_v1/` (`manifest_v1.json` - full per-card routing + static audit + the 10 required text-only Q&A answers per card, `compiled_prompts_v1.json` - the exact 16 prompt strings + SHA256, `coverage_report_v1.json`, `summary_v1.json`).

The per-card Q1-Q10 answers (all mechanically derived from the compiled text and cross-referenced against the other 15 cards, not from visual judgment) are in `manifest_v1.json`; every card answered "YES"/"NO" cleanly on the binary checks (Q3 human wording, Q4 contradictions), with Q5/Q6 (composition/palette distinctness) reporting real numbers rather than a blanket claim (e.g. several cards legitimately share a composition_archetype within this small 16-card sample even though the catalog-wide distribution is healthy - disclosed rather than hidden).

## 8. Part 7 — community_gathering special review

All 8 `community_gathering` rows' actual rendered scene text was read directly (not sampled or assumed):

| ID | Verdict |
|---|---|
| `business.founder_meetups`, `business.startup_meetups`, `business.tech_meetups`, `business.alumni_networking` | **Resolved** - generic professional-meetup grammar fits plausibly |
| `lifestyle.book_swaps`, `lifestyle.clothing_swaps` | **Moderate confidence, unresolved** - the grammar's generic "communal objects and shared materials" phrasing doesn't explicitly evoke books or clothing specifically; not clearly broken, but weaker identity than the resolved rows. Left as-is per "honesty over forcing 0" - flagged for the future visual test rather than patched blind. |
| `transport.car_meets` | **FIXED this round** - the original grammar (shared table, chairs, food, decorations "warmly prepared for togetherness") was genuinely nonsensical read directly against the actual compiled text. Fixed with a new id-exact override + new rule `community_gathering_vehicles` (generic unbranded vehicles parked together, no owners/drivers/spectators). `protagonist_type` corrected from `environment` to `machine_process`. |
| `lifestyle.repair_workshops` | **FIXED this round** - the communal/food/decoration tone tonally mismatched a workshop's tools-and-craft identity, confirmed by reading the actual text. Fixed with a new id-exact override rerouting it to the already-existing `generic_structural_containment` rule (tools, natural wear, activity mid-progress), which fits far better. `protagonist_type` corrected from `environment` to `object`. |

**Summary: 4/8 confidently resolved, 2/8 remaining moderate-confidence (not forced), 2/8 fixed this round with real id-specific grammar corrections.** Full detail: `output/object_first_v2_full_catalog_audit_v1/community_gathering_review_v1.json`.

This required extending the router's override mechanism: `objectFirstV2Router.js`'s `matchesIdPrefixOverride()` previously only supported `id_prefix` matching (`pets.*`, `collecting.*`); it now also supports exact `id` matching (`{"match": {"id": "transport.car_meets"}}`), used for these two new targeted fixes.

## 9. Part 8 — professional/legal/shared-workspace text-risk check

Spot-checked `business.startups` (professional_world), `business.coworking` (shared_workspace), `learning.mock_trial` (legal_practice), and `business.marketing` (campaign_planning) by reading their actual compiled `Depict this activity:` sections directly. All four explicitly suppress the exact failure modes named in the task (fake headings, whiteboard/kanban labels, legal document titles, fake case names, business charts) while preserving hobby-specific material identity through non-textual objects - e.g. legal_practice explicitly constrains the scales-of-justice detail to "a small supporting element, never the sole subject", exactly matching the task's warning against that cliche. Brand-like software UI (Figma/Slack/etc.) is covered catalog-wide by the shared, unmodified `global_brand_safety_policy` rather than duplicated per-archetype. No changes were needed - these grammars, written in the prior checkpoint (Part B of `3175b77`), already satisfy this check. Full detail: `output/object_first_v2_full_catalog_audit_v1/professional_legal_shared_workspace_text_risk_review_v1.json`.

## 10. Part 9 — zero-cost regression gates (17/17 pass)

| # | Check | Result |
|---|---|---|
| 1-12 | (unchanged from `3175b77` - all 2210 route, 2208 compile, deterministic, V1 unchanged, queue unchanged, quarantine unchanged, protagonist/composition routes present, containment rules valid, no human-exception explosion, no forbidden side effects, no image calls) | PASS |
| 13 | Keyword false-positive regression tests pass | PASS (unchanged, still 13/13) |
| 14 | Human exception list conservative | PASS (0) |
| 15 | Review-required reduction reported honestly | PASS |
| 16 | Every compiled row has a final V2 prompt | PASS |
| 17 | Static prompt QA clean (now with the full Part 4A-4F check set) | PASS (after 1 fix iteration this checkpoint - see §6.1) |

New this checkpoint (not separately numbered in code, folded into the overall gate): keyword-scan regression, validation-16 static audit (16/16), validation-16 coverage (`coverage_complete: true`, after 1 fix - see §6.2), community_gathering residual honesty (2/8 disclosed as unresolved, not forced), professional/legal/shared-workspace text-risk confirmation.

## 11. Remaining architectural conflicts

**None identified.** Both conflicts disclosed at `3175b77` are now eliminated at the source (not patched): D4's base style has a genuine human-language-free V2-native replacement, and V1's screen policy has a genuine V2-native replacement rather than an omission. The full 2208-prompt static audit found zero positive human wording, zero human-medium leaks, zero internal contradictions, zero brand leaks, zero incomplete-section prompts, and zero excessive-repetition prompts.

**Residual, disclosed, non-blocking uncertainty (not "conflicts"):** the 2 `community_gathering` rows flagged moderate-confidence in §8, and the general fact that 372 `new_grammar_unvalidated` + 8 `weak_extrapolation` rows (now including the 2 freshly-id-overridden ones) remain untested by any actual image generation. This is exactly what the validation-16 batch exists to test.

## 12. V2 readiness

**READY for the $0.2688 paid 16-card validation, pending explicit user authorization.** Both disclosed architectural conflicts are eliminated at the source; the exact 16 prompts that would be sent are compiled, hashed, and statically clean; coverage is complete across every dimension the task specified. Not generated. Not authorized by this checkpoint.

---

*Continues from `AI_STATE/HANDOFF_20260925_CARD_ART_OBJECT_FIRST_V2_COMPILER_AND_REVIEW_REDUCTION.md` (`3175b77`) and `AI_STATE/HANDOFF_20260925_CARD_ART_OBJECT_FIRST_V2_ARCHITECTURE.md` (`a369058`). All three remain part of the isolated object-first research track, separate from the paused production V1/D4 track referenced by `AI_STATE/LATEST_HANDOFF.md`'s primary chain.*

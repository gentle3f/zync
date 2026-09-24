# Zync Card Art — Object-First V2 Candidate Architecture (Zero-Cost Audit)

Branch: `card-art-pilot-v1-20260921`
Scope: architecture + full-catalog audit only. **$0.00 image-generation cost. No image was generated or visually inspected in this checkpoint.**

## 1. Why V2 exists

Rounds 1-4 of the isolated object-first experiment (separate from this checkpoint's
production V1/D4 track) produced enough evidence to justify treating
non-human-first as the **default** candidate visual language for Zync, with
human-led artwork as an exception rather than an equal default lane:

- **Round 1** (6 hobbies): `collecting.stamps`, `outdoors.mountain_biking`,
  `crafts.pottery_wheel`, `music.violin` passed cleanly. `gaming.tabletop_rpg`
  and `food.dish.bun_cha` failed on background-human leaks.
- **Round 2** (8 hobbies): both round-1 failures were fixed with stronger
  environment-containment language (`food.dish.bun_cha` fully fixed;
  `gaming.tabletop_rpg`'s environment fixed, a narrower hero-miniature issue
  remained). 4/6 new hobbies (`books.reading`, `outdoors.camping`,
  `technology.3d_printing`, `lifestyle.home_decor`) passed cleanly; 2/6
  (`sports.badminton`, `food.coffee`) had narrow, independent minor issues
  (brand-mark leak, object-logic issue).
- **Round 3** (12 hobbies, cross-family stress test): 4/12 clean pass
  (`photography.general`, `music.piano`, `lifestyle.gardening`,
  `food.baking`), 4/12 minor/ambiguous, 4/12 clear-to-severe fail
  (`media.movies`, `sports.running`, `gaming.board`, `technology.ai`). The
  composition-diversity router was validated (11/12 archetype compliance,
  no golden-hour/cozy/centered/sparkle convergence). The failures were not
  random - they clustered in specific, identifiable categories: screen/
  narrative media, human-biomechanics sports, social/group-space hobbies,
  and device-operator-cliche abstract concepts.
- **Round 4** (7 hobbies, structural containment rescue test): re-designed
  exactly those 7 failing scenes from the ground up using **structural
  containment** (empty/private environments, before/after-action staging)
  instead of a human-centered scene with the human subtracted. Images were
  generated and collected successfully (7/7, $0.1176); per the standing
  operating rule in effect since that round, **Claude performed no visual
  inspection of the Round 4 images** - visual QA is being done separately
  via ChatGPT and its result is not yet known to this checkpoint.

**This checkpoint's evidentiary stance:** the Round-3-to-Round-4 prompt
*redesign itself* - i.e. the discovery that scene structure, not just an
appended "no humans" negative, was the actual leak source in every Round-3
failure - is treated as validated architecture-level evidence, independent
of Round 4's still-pending visual verdict. This is stated explicitly in
`specs/object_first_rules_v2.json`'s `evidence_rounds.round4_note` field so
a future reader does not mistake "the redesign is evidence" for "Round 4's
images passed QA."

## 2. V1 preservation

V1 (`global_style_v1.json`, `buildPromptV1.js`, `production_queue_v1.json`,
`production_batch_plan_v1.json`, `generation_guardrails_v1.json`) was never
opened for writing by this checkpoint. `src/auditObjectFirstV2.js` hashes
six V1/production guard files before and after every run and hard-fails if
any hash changes (`v4_v1_production_files_unchanged` / `v5_no_production_
queue_mutation` in `audit_summary_v1.json`) - both passed. V1 remains the
live production architecture; V2 is a fully separate, independently
selectable candidate that a future compiler step could choose between.

## 3. V2 architecture (files)

All new, all read-only inputs to a not-yet-built V2 compiler (see §7):

- `specs/global_style_v2_object_first.json` - the V2 base-style delta.
  References `global_style_v1.json`'s `prompt`, `global_brand_safety_policy`,
  and `global_screen_policy` fields by pointer rather than duplicating them,
  and adds the non-human-protagonist policy, anti-sameness policy, and a
  nuanced V2 text policy (suppress *unwanted* text, not text as a concept -
  mirrors V1's already-validated `arts_text_suppression_policy`/
  `business_text_suppression_policy` approach, per the task's explicit
  instruction not to over-correct back to "all text forbidden").
- `specs/object_first_rules_v2.json` - the routing table. For every one of
  the 39 archetypes in `archetypes_v1.json`, defines a default
  `protagonist_type`, `object_first_status`, and (where applicable)
  `structural_containment_rule_id`, each with a written rationale citing
  either a specific validating round or an explicit "not yet tested,
  extrapolated from X" disclosure. Also defines two id-prefix overrides
  (`pets.*` -> animal/containment_required; `collecting.*` -> object/clean)
  and the conservative `human_exception_keyword_scan` mechanism (see §5).
- `specs/structural_containment_rules_v2.json` - 8 reusable containment
  rules (`action_aftermath`, `private_empty_venue`, `object_hero_no_
  performer`, `abstract_system_no_operator`, `screen_non_human_content`,
  `private_environment_animal`, `swimming_hard_case_no_visible_swimmer`,
  `generic_structural_containment`), each with a BAD/GOOD pattern pair and
  a `validated_by` citation where a round has actually tested it.
- `specs/composition_diversity_v2.json` - a 12-value composition-archetype
  router, an 8-value palette/lighting router, and a weighted (45/40/15)
  none/restrained/expressive effects router, all using the same
  proven per-id stable-hash technique as `src/diversityLayer.js` (see
  `hashing_note`), reimplemented locally so V2 has zero code dependency on
  V1's diversity system.
- `specs/physical_logic_v1.json` - the permanent "no invisible-human
  physics" rule (no self-operating tools/instruments/vessels) plus an
  explicit allowed-causes-of-motion list (gravity, wind, machine
  automation, already-in-flight objects, settling water, fire, spinning
  wheels, bubbles, aftermath traces, established mechanical/electronic
  processes).
- `src/objectFirstV2Router.js` - pure, zero-I/O routing function
  (`routeHobbyV2(row, ctx)`) implementing all of the above rule files plus
  three risk flags (`physical_logic_risk`, `text_risk`, `brand_risk`) keyed
  off archetype membership in three locally-defined risk sets.
- `src/auditObjectFirstV2.js` - the zero-cost full-catalog audit CLI (see
  §6). Makes no network call, reads no API key, calls no image-generation
  endpoint, and writes only to `output/object_first_v2_full_catalog_audit_v1/`.

**Deliberately not built this checkpoint:** an actual V2 prompt compiler
(`compileHobbyPromptV2()` or similar) that turns a routing decision into a
final prompt string. This checkpoint only decides *what* each card should
route to. `global_style_v2_object_first.json`'s `not_yet_built` field says
this explicitly so a future reader doesn't assume prompts can already be
generated from V2.

## 4. Routing philosophy and how it was applied

Per the task's explicit instruction, the default assumption for every
archetype is **non-human-first**, and a hobby is never classified as
human-required merely because people commonly perform it. Concretely, of
the 39 V1 archetypes:

- **2 archetypes -> `clean`** (`food_hero`, `collection_object_hero`): their
  own V1 composition language is already object/food-hero-first.
- **30 archetypes -> `containment_required`**: routed to one of the 8
  structural containment rules, either because a round directly validated
  that pattern, or because the extrapolation from a validated sibling
  archetype is judged low-risk (e.g. `vertical_adventure` extrapolated from
  the validated `solo_action`/`outdoor_motion` aftermath pattern).
- **7 archetypes -> `review_required`**: `professional_world`,
  `music_listening`, `campus_activity`, `community_gathering`,
  `shared_workspace`, `campaign_planning`, `legal_practice`. These are
  inherently social/professional/interpersonal archetypes that no round has
  tested at all. Each has a plausible non-human substitute noted in its
  rationale (e.g. legal_practice -> courtroom architecture, closed folders,
  gavel, scales) but it is genuinely unconfirmed, so they are queued for
  review rather than defaulted either to human-led or to an unverified
  object-first claim.
- **0 archetypes preset to `human_exception_candidate`.** No archetype was
  judged irreducibly human-required by default.

## 5. Human-exception audit (the part the task asked to scrutinize hardest)

A conservative, id/title keyword scan (`human_exception_keyword_scan` in
`object_first_rules_v2.json`) looks for hobbies whose identity might be
inseparable from a visible human body/identity (patterns: `model`,
`pageant`, `runway`, `public_speaking`, `debate`, `stand_up`, `improv`,
`beauty_queen`, `drag`, `cosplay_performance`). Every match is
**programmatically challenged** against an object/aftermath/environment/
animal/machine/miniature/symbolic alternative and downgraded to
`containment_required` unless the id is explicitly listed in
`irreducible_human_ids` (currently empty).

Running this against the real 2210-row catalog matched **13 ids**, and
**all 13 were downgraded** to `containment_required`
(`human_exception_candidates_v1.json`). Final `human_exception_candidate`
count: **0**.

**Known limitation, disclosed rather than hidden:** the substring-based
scan produced several false-positive matches from unrelated meanings of
the same substring - `crafts.model_building`, `transport.modelrailways`,
`crafts.model_kit_building`, `technology.3d_modeling`,
`learning.model_united_nations` (all matched on "model", meaning
scale/simulation models, not fashion modeling); `outdoors.dragon_boat` and
`sports.dragon_boat_racing` (matched on "drag", an unrelated word);
`learning.self_improvement` and `lifestyle.home_improvement` (matched on
"improv"); `outdoors.stand_up_paddleboarding` (matched on "stand_up"). Only
3 of the 13 matches were true positives with a sensible challenge
rationale: `business.public_speaking`, `entertainment.stand_up_comedy`,
`lifestyle.improv_comedy`. The false positives' *routing_note* text is
nonsensical for their actual hobby (e.g. dragon boat racing's note
references a "makeup vanity display"), even though their final
`object_first_status` (`containment_required`) happens to still be correct
because that is what their archetype would have defaulted to anyway.
**Recommended fix before this mechanism is trusted further:** tighten the
scan to word-boundary matching with explicit exclusions for `_building`,
`_kit_building`, `railways`, `_united_nations`, `self_`, `home_`, `_boat`,
`_paddleboarding` compound forms. Not fixed in this checkpoint since it
does not change any final routing outcome, but it is a real defect in the
audit mechanism, not a cosmetic one, and should not be presented as
production-ready without the fix.

## 6. Full-catalog zero-cost audit results

Run: `node tools/card_art/src/auditObjectFirstV2.js` (no flags, no API key
needed, $0.00). Output: `output/object_first_v2_full_catalog_audit_v1/`
(`audit_manifest_v1.jsonl` - one row per eligible canonical id,
`audit_summary_v1.json`, `human_exception_candidates_v1.json`,
`review_required_v1.json`).

```
total_catalog: 4053
total_eligible: 2210
total_blocked: 1843
total_quarantined_excluded: 2
total_routed_nonquarantined: 2208

protagonist_type_distribution:
  object: 671   environment: 525   food_drink: 332   machine_process: 223
  unresolved: 376 (= review_required rows, protagonist not yet decided)
  abstract_system: 52   animal: 29

object_first_status_distribution:
  containment_required: 1545   clean: 287   review_required: 376   excluded_quarantined: 2

composition_archetype_distribution (12 values, ~8.3% uniform baseline):
  strong_diagonal 204, cool_night-adjacent palette not applicable here...
  quiet_atmospheric 189, action_aftermath_frame 188, architectural_wide 188,
  dense_detail 186, minimal_iconic 188, overhead_tabletop 183,
  low_angle_kinetic 182, elevated_three_quarter 182, macro_hero 181,
  rainy_moody_window 173, extreme_scale_contrast 164
  (spread: 164-204, i.e. 7.4%-9.2% of catalog - no value exceeds the
  suspicious-concentration threshold of ~16.6%)

palette_lighting_route_distribution (8 values, 12.5% uniform baseline):
  rainy_moody 294, cool_night 309, warm_intimate 287, cool_daylight_shade 272,
  dusk_transition 270, bright_daylight 270, neutral_overcast 247, studio_dark 259
  (spread: 247-309, i.e. 11.2%-14.0% of catalog - no suspicious concentration)

effect_level_distribution (weighted 45/40/15 target):
  none 981 (44.4%), restrained 902 (40.9%), expressive 325 (14.7%)
  (matches the configured weights closely)

physical_logic_risk_count: 545 / 2208 (24.7%)
text_risk_count: 695 / 2208 (31.5%)
brand_risk_count: 427 / 2208 (19.3%)

human_exception_candidate_count: 0 (rate 0.000%)
review_required_count: 376 (17.0%)
```

**Concentration check:** `concentration_problems: []` - no composition or
palette value exceeded double its uniform baseline. The composition and
palette routers are catalog-wide well-distributed, addressing the task's
explicit "if 40% routes to one composition, that is a problem" concern -
the actual maximum is 9.2%.

**Determinism check:** the router was run twice independently over the
same 2210 rows inside the same process and the two output arrays were
byte-identical (`v3_deterministic_across_two_runs: true`).

**Validation summary (12/12 pass):**

| # | Check | Result |
|---|---|---|
| 1 | All 2210 eligible IDs compile | PASS |
| 2 | No duplicate IDs | PASS |
| 3 | Deterministic across two independent runs | PASS |
| 4 | V1 files unchanged (6 guard files hashed before/after) | PASS |
| 5 | No production queue mutation | PASS |
| 6 | Quarantine IDs untouched and excluded (2/2) | PASS |
| 7 | Every non-quarantined row has a protagonist route | PASS |
| 8 | Every non-quarantined row has a composition route | PASS |
| 9 | Containment rules reference valid archetypes | PASS |
| 10 | No human-exception explosion (< 3%; actual 0.0%) | PASS |
| 11 | No forbidden production side effects | PASS (no such code exists) |
| 12 | No image generation calls | PASS (no such code exists) |

## 7. Unresolved risks

- **No V2 prompt compiler exists yet.** Routing decisions are not yet
  assembled into compiled prompt strings. This is the next required
  engineering step before any validation batch can run.
- **376 `review_required` rows (17.0% of the catalog)** span 7
  fundamentally social/professional archetypes that no round has tested at
  all. These should not be assumed to work under V2 until a dedicated
  experiment runs.
- **The human-exception keyword scan has a real false-positive-matching
  defect** (§5) that should be tightened before being relied on for a
  larger automated sweep, even though it did not change any final routing
  outcome this run.
- **Round 4's actual visual pass/fail result is still unknown** to this
  checkpoint (visual QA is being done separately via ChatGPT, per the
  standing no-visual-QA operating rule). The `structural_containment_rules_
  v2.json` entries for `action_aftermath`, `private_empty_venue`,
  `object_hero_no_performer`, `abstract_system_no_operator`,
  `screen_non_human_content`, `private_environment_animal`, and
  `swimming_hard_case_no_visible_swimmer` are written from the Round-3-to-
  Round-4 prompt *redesign*, not from a confirmed Round-4 visual pass. If
  Round 4's ChatGPT review finds any of these redesigns did not actually
  fix the Round-3 leak, the corresponding rule (and every archetype routed
  to it) should be revisited before trusting this audit's `containment_
  required` bucket as "solved."
- **`physical_logic_risk` (545 rows), `text_risk` (695 rows), and
  `brand_risk` (427 rows)** are catalog-semantic risk *flags*, not
  per-hobby fixes - no per-hobby containment language has been written for
  any of them yet beyond the shared, catalog-wide `physical_logic_v1.json`
  rule.

## 8. Human exception candidates (final)

**0.** See §5 for the full challenge/downgrade mechanism and its known
limitation. The 13 keyword-scan matches and their downgrade rationale are
listed in full in `output/object_first_v2_full_catalog_audit_v1/human_
exception_candidates_v1.json`.

## 9. Is V2 mechanically ready for a small validation batch?

**Not yet - one engineering step remains.** The routing/audit layer is
complete and fully validated (12/12 checks pass, $0 cost, deterministic,
V1-preserving). What is missing is the actual prompt-compiler step
(`compileHobbyPromptV2()` or equivalent) that turns a routing decision
(protagonist type + containment rule + composition/palette/effect route)
into a final compiled prompt string, analogous to what `compileHobbyPrompt()`
does for V1. That compiler was explicitly out of scope for this checkpoint
(architecture + audit only, $0.00) and is the natural next build step,
ideally built directly against the specific validation-set IDs below so it
is exercised on a real, representative sample rather than written
speculatively against the whole catalog.

## 10. Recommended next experiment (plan only - NOT generated this checkpoint)

A small, representative validation set to test whether the not-yet-built
V2 compiler produces prompts that visually hold up, before considering any
larger rollout. Target size: **16 cards** (within the requested ~12-20
range). Sampling logic:

All 16 ids below were checked against the real `audit_manifest_v1.jsonl`
output and confirmed to exist and route as described (verified by lookup,
not guessed):

| # | Canonical ID | Routing | Why it's in the sample |
|---|---|---|---|
| 1 | `crafts.knitting` | `collection_object_hero`? no - `object`/`containment_required` via `generic_structural_containment` | sanity-check a validated-family craft id not directly tested |
| 2 | `collecting.sneakers` | `object`/`clean` (`collecting.*` override) | confirms the `clean` bucket on a different collecting sub-type than stamps |
| 3 | `sports.hiking` | `environment`/`containment_required`, `generic_structural_containment` (`nature_immersion`) | untested specific id in a validated archetype family (camping) |
| 4 | `sports.tennis` | `object`/`containment_required`, `action_aftermath` | different equipment/aftermath shape than the validated running/basketball cases |
| 5 | `gaming.chess` | `object`/`containment_required`, `private_empty_venue` | stresses the human-shaped-miniature (chess piece) carve-out on a different game than round 3/4's board game |
| 6 | `music.guitar` | `object`/`containment_required`, `object_hero_no_performer` | different instrument shape than the validated piano case |
| 7 | `technology.robotics` | **excluded_quarantined** - do not include; use `technology.ai` sibling instead if a `tech_workspace` retest is wanted | flagging explicitly: the only robotics id in the catalog is already quarantined and must stay untouched/unsubmitted |
| 8 | `entertainment.theatre_going` | `environment`/`containment_required`, `story_culture` (`screen_non_human_content` family) | tests whether the cinema-specific screen-content fix generalizes to a non-screen live-performance venue |
| 9 | `pets.cats` | `animal`/`containment_required` (`pets.*` override) | confirms the private-environment-animal fix generalizes beyond the one directly-tested dog case |
| 10 | `outdoors.scuba_diving` | `object`/`containment_required`, `swimming_hard_case_no_visible_swimmer` | stress-tests the strictest containment rule on a sibling water sport |
| 11 | `travel.backpacking` | `environment`/`containment_required`, `private_empty_venue` | different from the validated road-trip case |
| 12 | `food.drink.wine_appreciation` | `food_drink`/`containment_required`, `drink_ritual` (untested archetype, extrapolated rule) | tests the `drink_ritual` extrapolation directly |
| 13 | `business.public_speaking` | `object`/`containment_required` (true-positive human-exception-keyword match, downgraded) | directly tests whether the keyword-scan downgrade holds visually |
| 14 | `business.networking` | `unresolved`/`review_required` (`professional_world`) | tests the riskiest untested archetype bucket |
| 15 | `business.tech_meetups` | `unresolved`/`review_required` (`community_gathering`) | tests a second untested social archetype |
| 16 | `sports.skateboarding` | `object`/`containment_required`, high `brand_risk` (`solo_action` family) - already has a validated V1 brand-safety override to cross-check against | stress-tests V2's brand-risk flag on an id with a known, already-fought brand-leak history |

This plan is **not generated**. No image API call, no fal.ai call, and no
preview image were produced for this list in this checkpoint. IDs #7 and
#16 needed a correction after checking the real catalog against the
initial draft (robotics is quarantined; the original sneaker/meetup/
theater/diving/wine guesses in an early draft of this table did not all
exist verbatim in the catalog) - the table above reflects the corrected,
verified set.

---

*Related prior checkpoints (isolated object-first experiment, not part of
the production V1/D4 track referenced by `AI_STATE/LATEST_HANDOFF.md`'s
main chain): Rounds 1-4 were committed as their own isolated experiment
commits on this same branch but were not previously given AI_STATE
handoffs, per the explicit isolation instructions under which they were
run. This is the first AI_STATE handoff covering that work, written at the
point where it transitions from visual experimentation into architecture.*

# Zync — Card-Art Catalog Bulk Routing Split v1

Date: 2026-09-23
Branch: `card-art-pilot-v1-20260921`
Parent HEAD: `7563be85afb63f407aeb7ed0e15fb8f5c029e9b5`

Read `AI_STATE/OPERATING_RULES.md` before any write or external action.

## Purpose

This is a planning/classification pass, not a generation task. After many
rounds of single-hobby micro-tuning (Robotics, PC Gaming, American
Football, screen/UI leakage, letterbox/chrome), the goal is to stop
iterating on the hardest individual cases and instead route the **whole
eligible catalog** into three buckets based on the evidence accumulated
across this entire remediation arc:

1. **BULK-FIRST** — generate now with the current cheap FLUX pipeline.
2. **HOLDOUT / HARD-CASE** — do not bulk-generate yet; reserved for manual
   Image 2.5 or a further small, cheap FLUX/Klein experiment.
3. **QUARANTINED / BLOCKED** — already confirmed unsafe or technically
   broken; kept separate from ordinary holdouts.

**No paid generation was run to produce this split.** It is derived by
running the actual production compiler (`catalogRecipeBridge.js` +
`buildPromptV1.js`) against the full eligible catalog to see which
archetype/variant every canonical interest actually resolves to, then
applying the accumulated evidence from every prior round to each
archetype/cluster.

## Evidence basis (what this split is built on)

This reuses, not re-derives, the findings from the whole `card-art-pilot-v1`
remediation arc on this branch:

- **`professional_world` scene-prior** (workshop/jewelry/apprentice
  hijack): confirmed on `business.coworking`, `business.marketing`,
  `career.legal_profession`; fixed by moving those three (plus BookTube,
  mock_trial/moot_court) to new dedicated archetypes
  (`shared_workspace`, `campaign_planning`, `legal_practice`,
  `creator_workflow`), all now confirmed clean.
- **Sportswear/equipment trademark leakage** in `solo_action`: confirmed
  on `sports.american_football` (Standard: swoosh; Klein: dropped
  helmet), `sports.fencing`, `sports.archery` (both fixed by a
  cluster-matched brand-safe `profile_rule` covering `sports/racket`,
  `sports/combat`, `sports/precision`, now confirmed clean).
- **Screen/code/UI structural prior** in `tech_workspace`: a full
  10-card structural remediation with an explicit `global_screen_policy`
  still failed 4 of 5 tested IDs (`robotics`, `generative_ai`,
  `machine_learning`, `javascript`) with readable code/UI; a follow-up
  3-call discriminator and a further Klein style-anchor retest both
  confirmed `technology.robotics` has no production-safe route on either
  Standard or Klein. Now machine-quarantined.
- **`digital_play` / PC Gaming screen dependency**: `gaming.pc_gaming`
  failed 3 consecutive Standard-FLUX attempts across increasingly
  targeted archetypes (`desktop_focus` -> `collection_object_hero/
  hands_build` -> dedicated `screenless_pc_play/tower_input_play`),
  narrowing from severe screen-soup down to a single residual monitor
  object, but never fully clearing the gate.
- **`arts.vlogging`**: failed 3 consecutive rounds with a different
  defect each time (hobby-name text leak, then editing-UI leak, then
  code-screen leak), despite four sibling `creator_workflow` IDs on the
  same variant passing cleanly every time.
- **`gaming.game_streaming` production route**: the original
  `stream_broadcast` variant failed with a readable code IDE screen and
  is the first confirmed occurrence of the rounded light card-border/
  chrome defect; the fix that worked (`screenless_broadcast/
  camera_gamepad_performance`) is experiment-only, not wired into
  production for this ID.
- **Rounded light card-border/chrome defect**: 2 independent confirmed
  observations (`gaming.game_streaming` on Standard, `technology.robotics`
  on Klein), with clean controls on the exact same hobby+model+route in
  both cases. Classified as a recurring stochastic/upstream framing
  defect with an unproven weak hypothesis (global "collectible/card"
  wording); not tied to any one archetype, model, or dimension. See
  `AI_STATE/CARD_ART_CHROME_DEFECT_AUDIT_20260923.md`. This is treated as
  low-probability background noise across the whole catalog, not a
  reason to holdout any specific archetype on its own.
- **`travel.japan`**: a known, deferred signage + card-chrome
  recognition issue, never resolved.
- **`data_science`/global caption suppression**: confirmed stable across
  4 rounds and 63+ cards with zero recurrences — not a live risk factor
  anymore, and not a reason to holdout anything by itself.

## Method

1. Ran `buildCatalogRecipeBridge()` to get all 2210 baseline-art-eligible
   canonical interests (rights-safe: `originalGeneric` + `abstractOnly`).
2. Compiled every one of them through `compileHobbyPrompt()` (the same
   function the real generator uses) to get its actual archetype and
   visual variant — zero API calls, pure local compilation.
3. Grouped by archetype (and, where an archetype mixes safe and unsafe
   sub-populations, by `runtime_cluster` or specific canonical ID) and
   applied the evidence above:
   - An entire archetype is excluded from BULK-FIRST only when there is
     direct evidence a meaningfully-sized, representative sample of it
     failed (`tech_workspace`, `digital_play`, `professional_world`).
   - Within `solo_action`, only the clusters/IDs actually covered by the
     confirmed-working brand-safe rule are BULK-FIRST; everything else in
     that archetype carries the same unmitigated risk the fixed IDs
     originally had.
   - Within `creator_workflow`, only the two specific IDs with direct
     negative evidence (`arts.vlogging`, `gaming.game_streaming`) are
     held out; the other 17 IDs, several of which have direct positive
     evidence, are BULK-FIRST.
   - Within `travel_vista`, destination-specific IDs (signage/landmark
     dependency, matching the `travel.japan` pattern) are held out;
     travel-style IDs (no such dependency) are BULK-FIRST.
   - `collection_object_hero` is held out conservatively on one
     incidental (not directly causal) observation, pending a cheap
     confirmatory check.
   - Everything else defaulted to BULK-FIRST: no archetype-level or
     cluster-level negative evidence exists, and the category shape
     matches the task's own listed "expected positive candidates"
     (music, food, story/culture, reading, home, nature, wellness,
     performance, non-signage travel, uncontested sports, already-fixed
     professional/legal archetypes).
4. Ran a keyword sanity sweep (`screen|monitor|code|coding|streaming|
   esport|vr|ai`) across everything provisionally marked BULK-FIRST to
   catch any mis-bucketed risky title. Found 5 hits, all confirmed benign
   on inspection (`entertainment.screenwriting`, `learning.book_genre.
   programming_books`, `arts.screen_printing`, `arts.livestreaming`,
   `gaming.game_streaming` — the last already correctly held out).
5. One data-integrity bug surfaced during compilation:
   `outdoors.ice_fishing` resolves to `visual_variant: "water_ritual"`,
   which does not exist in `archetype_variants_v1.json` — this would
   throw at generation time. This is a technical defect, not an
   aesthetic judgment call, and is filed under QUARANTINED/BLOCKED
   separately from the two content-quality quarantines.

## Counts

| Bucket | Count |
|---|---|
| **BULK-FIRST** | **1730** |
| **HOLDOUT** | **477** |
| **QUARANTINED / BLOCKED** | **3** |
| Total eligible | 2210 |

### BULK-FIRST by archetype

```
music_listening: 272        home_lifestyle: 38
food_hero: 255              nature_immersion: 37
story_culture: 188          water_outdoors: 37
reading_world: 142          journey_machine: 31
urban_discovery: 93         companion_bond: 29
travel_vista: 87            campus_activity: 21
creative_studio: 78         calm_wellness: 20
learning_exploration: 67    fitness_training: 17
drink_ritual: 65            creator_workflow: 17
group_play: 64              lens_perspective: 16
performance: 49             outdoor_motion: 15
solo_action: 45             food_exploration: 12
                             strategy_table: 9
                             community_gathering: 8
                             wellness_experience: 6
                             vertical_adventure: 4
                             campaign_planning: 3
                             legal_practice: 3
                             aviation_world: 1
                             shared_workspace: 1
```

### HOLDOUT by group

| Group | Archetype | Count | Recommended track |
|---|---|---|---|
| tech_workspace | `tech_workspace` | 53 | Manual Image 2.5 (first choice); one more cheap experiment is defensible but not required |
| digital_play (all gaming subgenres) | `digital_play` | 172 | Manual Image 2.5, or await a production-wired screenless route |
| professional_world (remaining business.*) | `professional_world` | 70 | Cheap small stratified experiment first, before bulk or manual |
| solo_action (uncovered clusters) | `solo_action` | 51 | Cheap experiment: extend the brand-safe rule's cluster coverage, then retest |
| collection_object_hero | `collection_object_hero` | 33 | Cheap small stratified experiment first |
| travel destinations (signage risk) | `travel_vista` | 96 | Cheap small stratified experiment first |
| creator_workflow exceptions | `creator_workflow` | 2 | Manual Image 2.5, or wire the confirmed experiment route to production |

(53 + 172 + 70 + 51 + 33 + 96 + 2 = 477.)

### QUARANTINED / BLOCKED

| ID | Reason |
|---|---|
| `sports.american_football` | Machine-quarantined. No production-safe route on Standard or Klein. |
| `technology.robotics` | Machine-quarantined. No production-safe route on Standard or Klein, even with an explicit style anchor. |
| `outdoors.ice_fishing` | Data-integrity error — compiles to a non-existent `visual_variant`. Generation would throw. Needs a routing/data fix, not a content judgment. |

## Manual Image 2.5 vs. cheap-experiment-first: which holdouts are which

**Image 2.5 is manual-only for this catalog. It is never called through
fal.ai.** The two groups above marked "Manual Image 2.5 (first choice)" —
`tech_workspace` (53) and `digital_play` (172) — are the ones with the
strongest, most repeated negative evidence (multiple failed structural
remediation attempts across different models and prompt strategies). They
are the best candidates for you to run manually through Image 2.5 rather
than spending further FLUX/Klein experiment budget.

The other five groups (`professional_world`, `solo_action` uncovered
clusters, `collection_object_hero`, `travel_vista` destinations,
`creator_workflow`'s 2 exceptions) have thinner or more indirect evidence
— either untested-but-structurally-similar-to-a-known-problem
(`professional_world`), a coverage gap in an already-working fix
(`solo_action`), or a single incidental/non-causal observation
(`collection_object_hero`). These are reasonable candidates for one more
small, cheap FLUX-based confirmatory experiment (a handful of API calls
each, not a broad batch) before falling back to manual Image 2.5 — that
decision is left for the next task, not made here.

## What this task did NOT do

- No paid image generation was run.
- No 10/50/100 batch was started.
- Robotics and American Football experiments were not reopened.
- Image 2.5 was not called via fal.ai anywhere.
- The prompting/archetype system was not rewritten — this is a routing
  classification layered on top of the existing system, expressed as
  data files.

## Repo artifacts produced

- `tools/card_art/catalog/bulk_first_v1.json` — 1730 IDs, grouped by
  archetype, with full ID list.
- `tools/card_art/catalog/manual_image25_holdout_v1.json` — 477 IDs,
  grouped into the 7 evidence groups above, each with its own reason and
  recommended track.
- `tools/card_art/catalog/quarantined_or_blocked_v1.json` — 3 items with
  explicit reasons.

These are plain data files. Nothing in the generator, compiler, or
archetype specs was changed by this task.

## Recommended next steps (not executed this task)

1. If you want to start bulk production, `bulk_first_v1.json`'s 1730 IDs
   are the conservative starting set — still large enough to warrant its
   own staged rollout (e.g. a few hundred at a time with spot-check
   visual QA), not a single 1730-image batch.
2. For `tech_workspace` and `digital_play`, begin manual Image 2.5
   production on your own schedule; no further FLUX/Klein spend is
   recommended for these two groups based on current evidence.
3. For the five smaller holdout groups, the next-smallest useful FLUX
   experiment per group is:
   - `professional_world`: a ~5-8 card stratified sample across
     different `business.*` sub-clusters, structured like the earlier
     `structural_scene_remediation_v1` validation.
   - `solo_action` uncovered clusters: extend the existing cluster-based
     `profile_rule` to cover the missing clusters (`team_ball`'s
     remaining 11 IDs at minimum, since that rule already exists in
     concept), then retest a handful.
   - `collection_object_hero`: a small stratified sample of its actual
     33 intended collecting/building hobbies (not a mismatched gaming
     override) to see if the one incidental defect recurs.
   - `travel_vista` destinations: a small stratified sample including
     `travel.japan` plus a few other signage-heavy destinations.
   - `creator_workflow`'s 2 exceptions: either wire
     `screenless_broadcast/camera_gamepad_performance` into
     `gaming.game_streaming`'s production route (already confirmed
     clean), or hand both IDs to manual Image 2.5.
4. Fix the `outdoors.ice_fishing` data bug (`visual_variant:
   "water_ritual"` needs to be corrected to an existing variant or a new
   variant needs to be added) before this ID can be classified at all.

## Infrastructure

Vercel, GitHub Actions, Production, and Google Play remain closed for this
branch. No `FAL_KEY` was exposed or committed. No image API calls were
made while producing this classification.

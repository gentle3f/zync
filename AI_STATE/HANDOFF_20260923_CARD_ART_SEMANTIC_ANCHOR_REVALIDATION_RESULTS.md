# Zync — Semantic Anchor 24-Card Revalidation: Results

Date: 2026-09-23
Branch: `card-art-pilot-v1-20260921`
Parent HEAD: `930d73dd292cd4a22e377f24d88b30f30b5432a4`

Read `AI_STATE/OPERATING_RULES.md` before any write or external action.

## Bottom line

**The semantic anchor architecture does not produce a directional
improvement over the 100-card BULK-FIRST failure. 22 of 24 FAIL, 2 MINOR,
0 clean PASS.** The anchor rules themselves are well-written and
precisely target the correct defects — verified directly in the compiled
prompt text, not assumed — but the model overrides them in the
overwhelming majority of generated cards, including the single most
detailed anchor in the whole set (`outdoors.ice_fishing`) and two
hand-tuned **manual** recipes (`photography.general`, `gaming.board`).
Two cards (`entertainment.screenwriting`,
`entertainment.movie_subgenre.legal_thriller`) are arguably **worse**
than their 100-card counterparts — more chaotic multi-screen "screen
soup" scenes, not fewer defects.

Per the task's explicit decision rule, this is not a case for further
FLUX prompt-architecture investment. **Families that failed here should
move to the user's manual Image 2.5 workflow rather than receive another
round of semantic-anchor tuning.**

## What ran

```bash
cd tools/card_art
node src/auditSemanticAnchors.js
node src/runSemanticAnchorRevalidation24.js --dry-run
node src/runSemanticAnchorRevalidation24.js
```

### Zero-cost semantic coverage audit — clean

- `eligible: 2210 = manual 14 + derived_covered 1892 + derived_uncovered 304`.
- Uncovered (304) is dominated by archetypes that are HOLDOUT anyway and
  were never bulk-generation candidates: `digital_play` (172),
  `professional_world` (70), `tech_workspace` (53) = 295 of 304.
- The remaining uncovered items (`campaign_planning` 3, `legal_practice`
  3, `aviation_world` 1) are **not a gap** — confirmed by direct dry-run
  inspection that `career.legal_profession` still compiles through its
  own detailed, hand-engineered `legal_practice/courtroom_advocacy`
  archetype text from the earlier structural remediation arc. These
  archetypes don't need a semantic-anchor rule because their content
  anchor already lives at the archetype/variant level.
- `nature_immersion`'s 2 remaining uncovered stragglers are
  `outdoors.glamping` and `outdoors.bushcraft` — low priority.
- Safety checks all passed: `missing_safety_anchor_ids: []` (sauna/hot_
  springs/cold_plunge all covered), `global_positive_card_framing_terms_
  found: []` (old "collectible" wording confirmed removed), old bulk
  queue confirmed `production_ready: false`.

### 24-card dry-run — clean, anchors verified precise

All 24 compiled without error. Read the full compiled prompt text for
every card (not just headers) and confirmed the semantic anchors
correctly and specifically target the exact 100-card failure they were
built for — e.g. `outdoors.ice_fishing`'s anchor requires "a snow-covered
frozen lake with solid ice surface, one drilled/cut fishing hole... no
open-water boating scene" and explicitly forbids "open water, paddleboard,
kayak, boat"; `pets.dogs`/`pets.terrariums` explicitly forbid "camera,
binoculars, gimbal, controller, laptop, or unrelated gadget as focal
object" and "generic wildlife-photography composition";
`business.coworking` explicitly reinforces "front-facing readable
monitor, code, IDE, terminal, dashboard, multi-screen code setup" as
forbidden; `wellness.sauna` requires "modest swimwear, securely wrapped
towel/robe... never a domestic bathtub" and explicitly forbids "nudity,
implied nudity, sexualized pose, bare-body bathtub framing." The prompt
engineering itself is not the problem.

### Generation — 24/24 succeeded

No failures, no auto-rerolls. **Actual cost: $0.30** — matches estimate
exactly.

Manifest: `tools/card_art/output/semantic_anchor_revalidation_24_v1/manifest.json`
Images: `tools/card_art/output/semantic_anchor_revalidation_24_v1/images/`

All 24 images were individually opened and visually inspected.

## Per-card verdicts

| # | ID | Verdict | Defect |
|---|---|---|---|
| 1 | food.yum_cha | MINOR | Real shared-food scene now (improved), but shows a mixed stir-fry, not dim sum specifically; a camera is present despite being forbidden |
| 2 | food.dish.egg_tart | FAIL | Shows sliced meat with rice, not an egg tart — wrong dish, unchanged |
| 3 | food.dish.bun_cha | FAIL | Shows a shrimp stir-fry, not bun cha — wrong dish; a game controller is visible despite explicit prohibition |
| 4 | music.style.trip_hop | FAIL | Person + guitar + headphones is correct, but a background monitor shows readable code |
| 5 | music.style.japanese_alternative | FAIL | Two screens (monitor + laptop) both show clearly readable code/waveform UI |
| 6 | entertainment.screenwriting | FAIL | Severe: a giant monitor showing readable code floats above a crowd/stage scene; cameras dominate |
| 7 | entertainment.movie_subgenre.legal_thriller | **FAIL (worse than 100-card run)** | Catastrophic "screen soup": multiple monitors with code, waveform panel, game controllers, phone screens, all simultaneously |
| 8 | travel.style_deep.pilgrimage_routes | MINOR | Clean, no defects, but reads as generic travel photography rather than specifically "pilgrimage" |
| 9 | travel.cabin_getaways | FAIL | Shows a coastal cityscape with a train, not a cabin — wrong content |
| 10 | pets.dogs | FAIL | Shows rodents/rabbits in a forest, not a dog; a game controller is the central prop — direct violation of an explicit prohibition |
| 11 | pets.terrariums | FAIL | Same wildlife-forest scene as `pets.dogs`; camera/gimbal held — direct violation |
| 12 | learning.philosophy | FAIL | Laptop with readable code, camera, and controller on the desk — no book or philosophical object anchor |
| 13 | lifestyle.interior_design | FAIL | Game controller + laptop with readable code — nothing about interior design |
| 14 | outdoors.rockhounding | FAIL | Shows a tent/campfire scene — the exact substitution the anchor explicitly named and forbade |
| 15 | outdoors.cycling | FAIL | Shows a person on skis, not a bicycle — the exact substitution the anchor explicitly forbade |
| 16 | outdoors.ice_fishing | FAIL | Shows paddleboarding on open water — the exact substitution the single most detailed anchor in the set explicitly and repeatedly forbade |
| 17 | transport.ferries | FAIL | Shows a small hatchback car in a workshop, not a ferry; camera rigs dominate the scene |
| 18 | photography.general | FAIL | Shows binoculars, not a camera — recurs even in this **manual, hand-tuned** recipe |
| 19 | fashion.streetwear | FAIL | Readable neon storefront signage clearly visible — direct violation of detailed anti-signage language |
| 20 | gaming.board | FAIL | Game controllers and a phone visible at the table — recurs even in this **manual** recipe |
| 21 | gaming.chess | FAIL | Wrong specific game (Catan/Risk-style board, not chess); a camera and controller are both present |
| 22 | wellness.pilates | FAIL | Camera + game-controller-like device + code-screen monitor — no pilates action at all |
| 23 | wellness.sauna | **FAIL — safety risk persists** | Two figures in a bath/pool with bare shoulders and precarious strapless coverage in an ambiguously domestic-reading setting — close to exactly what the new safety rule was written to prevent; cameras also intrude into the water |
| 24 | business.coworking | FAIL | Multiple monitors and laptops showing clearly readable code — direct violation of the explicitly reinforced coworking screen rule |

**Tally: 0 PASS / 2 MINOR / 22 FAIL.**

## Defect-class summary

1. **Camera/gadget/controller intrusion as an unwanted focal object** —
   the single most common defect, present in the large majority of FAIL
   cards (pets ×2, learning.philosophy, lifestyle.interior_design,
   gaming.board, gaming.chess, wellness.pilates, transport.ferries,
   business.coworking, several food/music/travel cards). This recurs
   even where the anchor names the exact forbidden object list.
2. **Readable code/UI screens** — recurs across `music_listening` (2/2
   sampled here), `story_culture` (2/2), `business.coworking`, several
   others. Two cases are worse than their 100-card counterparts.
3. **Wrong specific instance of the correct general category** — exact
   dish identity (egg tart, bun cha), exact vehicle (car instead of
   ferry), exact sport (Catan-style board instead of chess), exact
   outdoor activity (skis instead of bike, paddleboard instead of ice
   fishing), exact animal (rodents/rabbits instead of dog).
4. **Readable signage/text** — `fashion.streetwear`'s neon storefront
   text, despite the most detailed anti-signage/anti-trademark language
   in the whole rule set.
5. **Wellness content-safety risk — not resolved.** The new safety rule
   is well-written, but `wellness.sauna`'s output still reads as
   precariously-covered figures in an ambiguously domestic bath setting.
   This needs to be treated as an unresolved, live risk, not a closed
   item.

## What did improve, narrowly

- `food.yum_cha` moved from a completely unrelated pasta scene (100-card
  run) to a genuine shared-food moment with real dishes and human
  interaction — a real, if partial, improvement, even though the exact
  dish identity (dim sum specifically) still wasn't achieved.
- `travel.style_deep.pilgrimage_routes` is clean and defect-free, though
  its concept-specificity is weak.

These two are the only signal of the intervention doing *something*
positive; everything else in this sample shows the same dominant failure
classes persisting essentially unchanged, and in two cases worsening.

## Decision, per the task's explicit rule

> "If the same generic gadget / unrelated-hobby / screen prior remains
> dominant even with concrete semantic anchors, stop further FLUX prompt
> tweaking for those families and recommend which families should move
> directly to the user's manual Image 2.5 workflow."

**That condition is met.** The dominant priors are still dominant. This
task does not recommend further semantic-anchor-rule investment as the
next step for the families tested here:

- `food_hero` / `food_exploration` (dish-identity substitution)
- `music_listening` (code-screen prior)
- `story_culture` (code-screen prior, now the worst-observed defect class)
- `travel_vista` destinations (`cabin_getaways`-style content mismatch)
- `companion_bond` (pets — wildlife/gadget substitution, unresolved
  across two independent rounds)
- `learning_exploration` (gadget/code substitution)
- `home_lifestyle` (gadget/code substitution)
- `nature_immersion` / `outdoor_motion` / `water_outdoors` (exact-activity
  substitution, unresolved even for the single most detailed anchor
  tested — ice fishing)
- `journey_machine` (wrong-vehicle substitution)
- `lens_perspective` (binoculars-for-camera substitution, unresolved even
  in a manual recipe)
- `urban_discovery` (signage leakage, unresolved even with the most
  detailed anti-signage language in the set)
- `group_play` / `strategy_table` (controller intrusion, unresolved even
  in manual recipes)
- `calm_wellness` (gadget/code substitution)
- `shared_workspace` (`business.coworking` — code-screen regression,
  now confirmed twice)

**Recommendation: route all of the above families to manual Image 2.5.**
This is a large fraction of the catalog's BULK-FIRST candidates. Given
the consistency and severity of this result, it is not defensible to
recommend a third round of FLUX prompt-architecture work for these
specific families without new evidence of a fundamentally different
technical approach (e.g. a different model route, reference-image
conditioning, or a structural composition change of the kind that worked
for `aviation_world`/`campaign_planning`/`legal_practice` earlier in this
arc — not more negative wording).

## What was NOT invalidated by this test

This 24-card sample intentionally targeted the **hardest** known failure
cases. It says nothing new, positive or negative, about the archetypes
that were structurally redesigned earlier in this remediation arc
(`aviation_world`, `campaign_planning`, `legal_practice`) — none of those
were retested here, and prior evidence for them stands unchanged. It also
says nothing about the large uncontested middle of the catalog (most of
`music_listening`'s 272 IDs, most of `food_hero`'s 255 IDs, etc.) beyond
what this stratified 24-card sample suggests about their shared
archetype-level risk.

## Recommended next steps (not executed this task)

1. **Do not run the semantic-anchor-covered 100-card or 1731-card bulk
   batch.** This is now the third consecutive validation round
   (100-card generic templates → 24-card semantic anchors) to show the
   same dominant failure classes; a fourth round without a different
   technical approach is not a good use of budget.
2. **Route the families listed above to manual Image 2.5**, per the
   user's own stated workflow. Manual Image 2.5 remains manual-only and
   is never called through fal.ai.
3. **Escalate `wellness.sauna`/`wellness.hot_springs`/`wellness.cold_
   plunge` as a standalone, higher-priority safety review**, independent
   of the general recognizability work — the new safety rule reduced but
   did not eliminate the risk, and this is a different severity class
   than a recognizability miss.
4. If any further FLUX investment is wanted at all, the smallest
   defensible next experiment is a **structural** one (archetype
   redesign, not more anchor text) on a single narrow family — following
   the pattern that worked for `legal_practice`/`campaign_planning`
   rather than repeating the anchor-rule approach that this task shows
   is not sufficient on its own.
5. `sports.american_football` and `technology.robotics` remain
   quarantined; not touched this task.

## Infrastructure

Vercel, GitHub Actions, Production, and Google Play remain closed for this
branch. No `FAL_KEY` was exposed or committed. No auto-reroll was
performed. No Image 2.5 call was made via fal.ai. No 100-card or
1731-card batch was started. `sports.american_football` and
`technology.robotics` remain quarantined and untouched.

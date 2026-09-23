# Zync — Structural Scene-Prior Remediation: Validation Results

Date: 2026-09-23
Branch: `card-art-pilot-v1-20260921`

Read `AI_STATE/OPERATING_RULES.md` before any write or external action.

## Bottom line

**Gate passed — decisively.** All four repaired cards (`business.coworking`,
`business.marketing`, `career.legal_profession`,
`learning.book_genre.booktube`) produced clean, unambiguous PASS results
that meet every specific gate criterion. The `professional_world`
workshop/jewelry/apprentice scene prior — which survived three independent
hobby prompts with detailed exclusions in the previous round — did not
recur even once after routing these interests to new, purpose-built
archetypes (`shared_workspace`, `campaign_planning`, `legal_practice`,
`creator_workflow`). The `technology.generative_ai` control remains
fundamentally clean (no caption regression, no readable code); it shows one
minor, already-known, low-priority UI-clutter texture consistent with the
deferred `technology.electronics` finding from the prior round.

**Diagnosis of the original failure, confirmed by this result:** it was a
genuine **model semantic prior** tied to the `professional_world`
archetype/variant combination, not a compiler bug, override-precedence bug,
or variant-selection bug. The same hobby-specific hardware (subject text,
exact-ID exclusions) had already been present and ignored under
`professional_world`; moving the *archetype* itself — giving the model a
structurally different scene template rather than more negative wording
inside the same one — is what fixed it. This matches the pattern already
proven for uniform-sports and ethnic-food earlier in this remediation
effort.

## What ran

```bash
cd tools/card_art
npm run audit-structural-scene-remediation-v1
npm run generate-structural-scene-remediation-v1
```

- **Audit:** passed cleanly. 5/5 compiled (all standard FLUX), $0.063 est.
  (~$0.0625). Verified directly against the raw dry-run output:
  - Routing confirmed exactly as specified: `business.coworking` ->
    `shared_workspace / communal_desks`; `business.marketing` ->
    `campaign_planning / mockup_table`; `career.legal_profession` ->
    `legal_practice / courtroom_advocacy`; `learning.book_genre.booktube` ->
    `creator_workflow / camera_creation`; BookTube confirmed on the
    `standard` route (Standard FLUX, not Klein — only one route existed in
    this batch, containing all 5 cards).
  - `global_text_policy` present in all 5 compiled prompts.
  - Zero forbidden compiler headers, zero raw internal ids anywhere (not
    even in the CLI's own debug line).
  - Coworking's compiled prompt structurally requires "three to five adult
    professionals," "communal desks," and explicitly excludes "craft bench,
    laboratory, makerspace, assembly table, hand tools, microscopes,
    jewelry, machine parts, or apprentice scene."
  - Marketing's compiled prompt structurally requires a "campaign-planning
    table," "product sample, blank packaging mockups, image cards,
    unlabeled color/material swatches," and explicitly excludes "craft
    tools, machinery, jewelry, workshop benches, manufacturing equipment,
    or apprentice scene."
  - Legal_profession's compiled prompt structurally requires "courtroom or
    formal client-consultation setting," "counsel table, judge bench,
    witness stand," and explicitly excludes "workshops, craft benches, hand
    tools, microscopes, machinery, apprentices, or children."
  - BookTube's compiled prompt requires "camera or phone on a tripod aimed
    at the creator," "expressive speaking gestures," and explicitly
    excludes "platform interface, logos, captions, or readable book text."
- **Generation:** **5/5 API calls succeeded**, no failures, no automatic
  retries. **Actual cost: $0.063** — matches the $0.0625 estimate.

Manifest: `tools/card_art/output/structural_scene_remediation_v1/manifest.json`
Images: `tools/card_art/output/structural_scene_remediation_v1/images/`

All 5 images were individually opened and visually inspected (not judged
from prompts/API success/manifest alone).

## Per-card verdicts

| ID | Verdict | Q | Intended structural scene visible? | Title/caption returned? | Card chrome? | Style drift | vs. previous round |
|---|---|---|---|---|---|---|---|
| business.coworking | **PASS** | 5 | Yes — six adult professionals at communal desks, laptops, headphones, mugs, plants, natural neighbour interaction; zero workshop/jewelry/craft content | No | No | N/A (standard) | **Fixed.** Previous round: unrelated jewelry/watchmaking workshop with child apprentices. Now an unambiguous, textbook shared-office scene. |
| business.marketing | **PASS** | 5 | Yes — campaign-planning table with blank packaging mockups, photo image cards, unlabeled colour/material swatches, three people actively pointing/comparing/arranging | No | No | N/A (standard) | **Fixed.** Previous round: same unrelated jewelry workshop scene as coworking. Now an unambiguous campaign-planning tableau. |
| career.legal_profession | **PASS** | 5 | Yes — adult advocate in suit gesturing beside a counsel table, judge on an ornate bench behind, closed blank folders, courtroom architecture | No | No | N/A (standard) | **Fixed.** Previous round: "LEGAL PROFESSION" caption on a jewelry-workshop scene. Now a clean, unambiguous courtroom scene with zero text. |
| learning.book_genre.booktube | **PASS** | 5 | Yes — camera on tripod clearly aimed at an adult creator, softbox light, active speaking gesture, plain blank-cover book held up, desk with notebook/pens | No | No | N/A (moved to standard FLUX; no MATERIAL photoreal drift — painterly, consistent with house style) | **Fixed.** Previous two rounds (both on Klein): plain reading with no recording cue, MATERIAL style drift. Now an unambiguous creator/recording scene in the correct painterly style. |
| technology.generative_ai (control) | **MINOR** | 5 | N/A (control) | No — no hobby-title caption reappeared | No | N/A (standard) | Remains fundamentally clean (this was the primary risk to check). One minor, already-known issue: a faint illegible UI-panel/text-clutter texture on one monitor, the same low-priority class of finding already flagged and explicitly deferred for `technology.electronics` in the prior round. Not the caption/code regression that would have mattered for this gate. |

## Specific gate checks

### `business.coworking` — **PASS**
Multiple (6) unrelated adult professionals ✅, communal/shared desks ✅,
separate individual work setups ✅, no jewelry/watchmaking/craft workshop ✅,
no lab/makerspace ✅, no child-apprentice scene ✅.

### `business.marketing` — **PASS**
Generic product sample / blank packaging mockups ✅, visual/image cards ✅,
unlabeled colour/material swatches ✅, people actively comparing/refining a
campaign layout ✅, no craft workshop ✅, no jewelry/watchmaking ✅, no
hardware/manufacturing scene ✅.

### `career.legal_profession` — **PASS**
Adult legal professional ✅, courtroom setting (counsel table + judge bench)
✅, active advocacy gesture ✅, no unrelated workshop ✅, no child apprentices
✅, no readable legal text needed for recognition (folders are closed and
blank) ✅.

### `learning.book_genre.booktube` — **PASS**
Adult creator ✅, plain unbranded book ✅, visible camera/phone on tripod
aimed at creator ✅, active speaking/presenting gesture ✅, no platform
logo/UI/text ✅. **Moving from Klein to Standard FLUX fixed the prior
MATERIAL style drift** — this result is painterly and visually consistent
with the rest of the collection, not photoreal/stock-photo.

### `technology.generative_ai` (control) — **clean, minor note**
No hobby-title caption reappeared ✅, no readable code/UI text ✅. Minor
regression: faint illegible text-like UI-panel clutter on one monitor
(same low-priority pattern as the deferred `technology.electronics`
finding) — worth a future look but does not represent the caption or
scene-prior failure this gate exists to catch.

## Decision gate: **PASSED**

All four repaired target cards materially improved — in fact all four
achieved a clean, unambiguous PASS against every specific criterion listed.
The `generative_ai` control remains clean on the dimensions that mattered
(no caption regression, no readable code). Per the task's explicit
instruction, this clears the gate.

### Root cause, now confirmed

This was a **model semantic prior**, not a compiler/routing/override/
variant-selection bug. Evidence: the `professional_world` archetype had
correct, detailed, hobby-specific subject text and explicit exclusions in
the prior round and still collapsed three independent hobbies into a
near-identical unrelated scene; giving the model a different archetype
template (not more negative wording within the same one) eliminated the
failure completely, on the first attempt, for all three of the previously
broken professional hobbies plus the separately-diagnosed BookTube case.
This is the same causal pattern already established for the uniform-sports
and ethnic-food sentinels earlier in this remediation arc — model-level
compositional priors tied to a specific archetype/variant require a
structural template change, not iterative negative-prompt tuning.

## Recommended next confirmatory batch

**Do not jump straight to 50+.** Recommend a **~30-card confirmatory batch**,
smaller than the previously-paused 50-card ceiling, composed of two parts:

1. **Breadth-confirmation of the four newly-fixed archetypes (~10-12
   cards):** 2-3 additional, different hobbies routed through each of
   `shared_workspace`, `campaign_planning`, `legal_practice`, and
   `creator_workflow` (e.g. other coworking-adjacent or advocacy-adjacent
   interests, other content-creation hobbies) to confirm the fix
   generalizes beyond the single hobby tested per archetype in this round,
   not just these four specific IDs.
2. **Fresh stratified sample (~18-20 cards)** across categories/archetypes
   not yet exercised anywhere in this remediation arc, to surface any other
   undiscovered archetype-level scene-priors before committing to a larger
   production run — following the same stratification logic as the original
   100-card batch but now starting from a cleaner baseline.

Defer, but do not forget: `travel.japan` (signage + card-chrome regression)
and the recurring minor screen-clutter texture on `tech_workspace`/
`creator_interface`-style displays remain open, lower-priority issues from
earlier rounds, deliberately not addressed in this pass.

## Infrastructure

Vercel deployment confirmed disabled for this branch (unchanged). No GitHub
Actions workflow triggers on push to this branch. This commit/push is a
plain repo write with no CI/deployment side effects. Play/Production remain
untouched and closed. `FAL_KEY` was not committed or exposed. No auto-reroll
was performed.

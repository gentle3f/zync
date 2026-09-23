# Zync — Global Caption Remediation: Validation Results

Date: 2026-09-23
Branch: `card-art-pilot-v1-20260921`

Read `AI_STATE/OPERATING_RULES.md` before any write or external action.

## Bottom line

**Title-caption suppression works. Professional-scene recognition does not.
Decision gate NOT met — do not start a 50-card batch.**

The global `global_text_policy` fix cleanly solved the specific defect it
targeted: all three cross-archetype title/caption cases
(`career.legal_profession`, `technology.generative_ai`, `travel.general`)
are now free of hobby-title captions, poster layouts, and gibberish text
boxes — including `travel.general`, previously the worst offender. But the
exact-ID recognition rules for `business.coworking` and `business.marketing`
did **not** change what the model actually rendered: both cards, and also
`career.legal_profession`, independently produced near-identical unrelated
"jewelry/watchmaking workshop with child apprentices" scenes despite having
fully different, detailed, hobby-specific subject text in their compiled
prompts. This is a strong, repeatable prior in the `professional_world`
archetype that prompt content alone is not overriding.

## What ran

```bash
cd tools/card_art
npm run audit-caption-remediation-v1
npm run generate-caption-remediation-v1
```

- **Audit:** passed cleanly. 8/8 compiled, 7 standard ($0.088 est.) + 1 Klein
  ($0.011 est.) = $0.0989 est. Verified directly:
  - `global_text_policy` text ("The hobby or interest name is semantic
    context only and must never appear visually...") present verbatim in all
    8 compiled prompts.
  - Hobby names appear only inside ordinary descriptive prose (e.g. "Depict
    this activity: ... Legal Profession...") — never as an instruction to
    render text.
  - Zero raw compiler ids/forbidden headers anywhere (not even in the CLI's
    own debug line this time).
  - `business.coworking` and `business.marketing` exact-ID rules present
    and correctly detailed: coworking specifies "at least three independent
    workers," "communal desk," and explicitly excludes "laboratory,
    workshop, startup prototype bench, or corporate boardroom"; marketing
    specifies "blank packaging mockups, image cards, unlabeled colour
    swatches" and excludes workshop/hardware/jewelry substitutions.
  - `learning.book_genre.booktube`'s creator cue ("book creator actively
    discussing one plain unbranded book while recording... camera or phone
    on a tripod clearly aimed at the creator") present.
  - Klein's real `negative_prompt` (verified programmatically, 38 total
    constraints) includes the new caption/title/poster-layout negatives:
    "title, subtitle, caption, heading, label, footer...", "poster,
    advertisement, magazine-cover, card-face, or editorial-page layout",
    "text boxes, caption bands, lower-thirds...".
- **Generation:** **8/8 API calls succeeded**, no failures, no automatic
  retries. **Actual cost: $0.098** ($0.087 standard + $0.011 Klein) —
  matches the $0.0989 estimate.

Manifest: `tools/card_art/output/caption_remediation_v1/manifest.json`
Images: `tools/card_art/output/caption_remediation_v1/images/`

All 8 images were individually opened and visually inspected (not judged
from prompts/API success/manifest alone).

## Per-card verdicts

| ID | Route | Verdict | Q | Defect class | Diagnosis (vs. previous archetype-fix result) |
|---|---|---|---|---|---|
| career.legal_profession | Standard | **FAIL** | 4.5 | recognition (new) | The "LEGAL PROFESSION" caption is completely gone — text fix confirmed. But the scene is now an unrelated jewelry/watchmaking workshop with child apprentices; no legal cue (gavel, law books, suit, desk) remains at all. Traded a text defect for a recognition defect. |
| technology.generative_ai | Standard | **PASS** | 5 | - | The "Generative AI" caption is gone. Screen shows only clean abstract node/graph/geometric visuals, no code. Clear, complete fix. |
| travel.general | Standard | **PASS** | 5 | - | The "Travel" title, the gibberish paragraph, the white caption box, and the poster/ad layout are all gone — this was the worst prior offender and is now clean. Scene reads reasonably as a journey (train, travelers, backpacks) even if the skyline leans fantastical rather than grounded. |
| business.coworking | Standard | **FAIL** | 5 | recognition (unresolved) | Renders the same unrelated jewelry/machine-shop workshop scene as legal_profession, not a shared coworking space — no communal desk, no independent workers with laptops, no coworking-specific cue at all, despite the exact-ID rule being present in the prompt verbatim. Recognition problem is unchanged from the prior round. |
| business.marketing | Standard | **FAIL** | 5 | recognition (unresolved) | Also renders an unrelated jewelry/watchmaking workshop scene — no campaign mockups, no packaging, no colour swatches, none of the new exact-ID content appears. Same failure mode as before, unresolved. |
| travel.japan | Standard | **FAIL** | 5 | cardchrome + recognition | Readable Japanese street signage (the specific defect this fix targeted) is gone — a genuine partial win. But a white rounded card-frame border now wraps the whole image (new card-chrome defect), and the architecture is generic/fantastical rather than recognisably Japanese (no torii, traditional wooden buildings, or cherry blossoms this time) — a recognition regression from the prior attempt. |
| learning.book_genre.booktube | Klein | **FAIL** | 5 | recognition (unresolved) | Shows a man simply reading in an armchair — no camera, phone, tripod, or recording gesture of any kind, despite the new creator cue being present verbatim in the compiled prompt and in Klein's negative_prompt scaffold. Identical recognition failure to the prior round. Style drift: MATERIAL (strongly photoreal). |
| technology.electronics (control) | Standard | **MINOR** | 4.5 | text (minor, new) | Main visible panels remain clean abstract graphs/nodes as before, but several small illegible UI-label-like clutter blocks now dot the screen edges — not clearly readable, but more visual "text noise" than the fully clean control result in the prior round. Borderline, arguable regression. |

## Specific evaluation asks

- **career.legal_profession — no hobby-title/caption text:** ✅ confirmed
  gone. (Recognition regressed instead — see above.)
- **technology.generative_ai — no hobby-title/caption text:** ✅ confirmed
  gone, and the card is otherwise clean.
- **travel.general — no "Travel" title, gibberish paragraph, text box,
  poster/ad layout:** ✅ all four confirmed gone. This is the clearest,
  strongest individual result in this validation.
- **business.coworking — must read as shared coworking space:** ❌ still
  reads as an unrelated craft workshop.
- **business.marketing — must read as campaign/marketing planning:** ❌
  still reads as an unrelated craft workshop (jewelry/watchmaking).
- **travel.japan — readable Japanese signage:** ✅ gone from the scene
  itself, though a new card-chrome border appeared and Japan-specific
  identity weakened.
- **learning.book_genre.booktube — clear recording/creator cue:** ❌ absent;
  reads as plain reading, unchanged from before.
- **technology.electronics — known-clean control, check regression:** ⚠️
  minor, arguable regression (illegible screen-clutter increase, not clearly
  readable text).

## Klein style drift (BookTube)

**MATERIAL** — strongly photoreal rendering (skin, lighting, depth of
field), consistent with the pattern seen across all prior Klein rounds.

## Before/after comparison with the previous archetype-fix batch

| ID | Archetype-fix round | Caption-remediation round | Net change |
|---|---|---|---|
| career.legal_profession | FAIL (text: "LEGAL PROFESSION" caption) | FAIL (recognition: unrelated workshop) | Defect *class* changed; still FAIL |
| technology.generative_ai | FAIL (text: "Generative AI" caption) | **PASS** | **Fixed** |
| travel.general | FAIL (text: "Travel" title + gibberish paragraph, *this was the worst case*) | **PASS** | **Fixed** |
| business.coworking | FAIL (recognition: generic workshop) | FAIL (recognition: generic workshop) | **Unchanged** |
| business.marketing | FAIL (recognition: generic workshop) | FAIL (recognition: generic workshop) | **Unchanged** |
| travel.japan | FAIL (text: readable signage) | FAIL (cardchrome + recognition) | Defect *class* changed; still FAIL |
| learning.book_genre.booktube | FAIL (recognition: no creator cue) | FAIL (recognition: no creator cue) | **Unchanged** |
| technology.electronics | PASS (clean control) | MINOR (slight screen-clutter increase) | Slight regression |

## Decision gate

The task's stated conditions for recommending a 50-card confirmatory batch:
1. title/caption suppression materially works across the three
   cross-archetype cases — **met** (3/3: legal_profession, generative_ai,
   travel.general all lost their caption/poster defect);
2. coworking and marketing recognition materially improves — **not met**
   (0/2, both unchanged, same defect as before);
3. the known-clean electronics control does not regress — **borderline, not
   clearly met** (minor illegible screen-clutter increase);
4. no raw compiler-id leakage reappears — **met** (confirmed zero
   occurrences).

**2 of 4 conditions fully met, 1 partially, 1 not met. Per the task's
explicit instruction, this does NOT clear the gate. Do not start a 50-card
batch.**

## Root-cause diagnosis for the remaining failure

The `professional_world` archetype has a strong, repeatable compositional
prior toward a "workshop craftsman with child apprentices, jewelry/
watchmaking tools, microscope-like instrument" scene that at least three
independently-different hobby prompts (legal_profession, coworking,
marketing) all collapsed into, near-identically, despite each having
detailed, hobby-specific subject/environment text and an explicit exclusion
list (coworking's prompt explicitly said "not a laboratory, workshop,
startup prototype bench"; marketing's explicitly said no
"workshop/hardware/jewelry/manufacturing substitutions"). Since the
exclusion language is present and specific yet ignored, this looks like a
genuine model-prior problem for this archetype/variant combination, not a
missing-instruction problem — the same class of issue diagnosed for the
sports-uniform and ethnic-food sentinels before those were fixed by giving
the model a completely different, concrete alternative scene rather than
just more negative wording.

## Smallest targeted repair (not executed this task)

Do not reroll all 5 FAILs blindly. Recommended smallest next step,
cheapest first:

1. **Diagnostic reroll of `business.coworking` and `business.marketing`
   only** (2 cards, ~$0.025) on the exact same prompt, to check whether the
   "jewelry workshop" scene is a single-sample fluke (stochastic) or a
   deterministic prior. If a second sample also collapses to the same
   workshop scene, that confirms the model-prior diagnosis above rather than
   noise.
2. If confirmed, the fix is structural, following the same pattern that
   worked for uniform sports and ethnic food: change the `visual_variant`
   for these two hobbies away from `environmental_role`/`collaboration_case`
   (which may itself carry the workshop bias) to a variant built around a
   completely different, concrete staging — e.g. an explicit desk/monitor/
   coffee-cup/headphones tableau for coworking, or an explicit
   mood-board/mockup-table close-up for marketing — rather than relying on
   subject-text exclusions alone.
3. `career.legal_profession` and `travel.japan` picked up new, milder
   defects (recognition drift and a card-chrome border respectively) that
   are lower priority than coworking/marketing but worth a note for the same
   remediation pass.
4. `learning.book_genre.booktube`'s creator-cue instruction is present and
   specific but was completely ignored in this one sample — worth one more
   diagnostic sample before concluding it needs a structural fix too.

## Infrastructure

Vercel deployment confirmed disabled for this branch (unchanged). No GitHub
Actions workflow triggers on push to this branch. This commit/push is a
plain repo write with no CI/deployment side effects. Play/Production remain
untouched and closed. `FAL_KEY` was not committed or exposed. No auto-reroll
was performed.

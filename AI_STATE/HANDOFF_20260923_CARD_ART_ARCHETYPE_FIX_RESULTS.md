# Zync — Archetype Content Fix: Before/After Validation Results

Date: 2026-09-23
Branch: `card-art-pilot-v1-20260921`

Read `AI_STATE/OPERATING_RULES.md` before any write or external action.

## Bottom line

**Mixed but genuinely informative result — two of six problem classes are now
fully solved, two are substantially improved, two remain broken (one got
worse).** Overall this 20-card sample moved from **0% PASS / 90% FAIL**
(scale-100 baseline for these exact 20 IDs) to **55% PASS / 5% MINOR / 40%
FAIL**. The structural fixes work well where they gave the model a concrete
alternative subject (ethnic food, uniform sports, book covers, abstract tech
displays) and work poorly where the underlying scene concept is still
abstract (coworking/marketing as professions, generic "travel"). A new,
cross-cutting defect emerged: **spontaneous hobby-title caption text**,
independent of archetype, now the dominant remaining failure mode. Klein
style drift got **worse** in this sample (83% MATERIAL vs 52% in the 100-card
batch).

## What ran

```bash
cd tools/card_art
npm run audit-archetype-fix-v1
npm run generate-archetype-fix-v1
```

- **Audit:** passed cleanly on the first try — no execution blocker found,
  no code changes needed this task. 20/20 compiled, 14 standard ($0.175
  est.) + 6 Klein ($0.068 est.) = $0.2434 est. Verified directly against the
  raw dry-run output: zero `ARCHETYPE (`/`VISUAL VARIANT (`/`CATEGORY (`/
  `SUBCATEGORY (` occurrences, zero raw internal ids anywhere (not even in
  the CLI's own debug header this time), zero `REFERENCE STYLE` leakage,
  Klein confirmed sending a real, non-empty `negative_prompt`. Manually
  inspected the compiled prompts for `business.startups`, `career.journalism`
  (professional_world), `sports.american_football`, `sports.football`
  (uniform sports), and `food.yum_cha` (ethnic food) — the intended new
  structural language (concrete physical action, plain unnumbered kit, close
  food-interaction framing, no-code display language) was present exactly as
  designed in every one.
- **Generation:** **20/20 API calls succeeded**, no failures, no automatic
  retries. **Actual cost: $0.243** ($0.175 standard + $0.068 Klein) —
  matches the $0.2434 estimate.

Manifest: `tools/card_art/output/archetype_fix_v1/manifest.json`
Images: `tools/card_art/output/archetype_fix_v1/images/` (20 files)

All 20 images were individually opened and visually inspected (not judged
from prompts/API success/manifest alone), and compared directly against
their scale-100 result for the same canonical ID.

## Full before/after table

| ID | Route | Group | Scale-100 verdict | New verdict | Q | Defect (new) | Diagnosis |
|---|---|---|---|---|---|---|---|
| business.startups | Standard | professional_world | MINOR (recognition) | **PASS** | 4.5 | - | Now a coherent hardware-startup prototyping scene (blueprints, mechanical device, team) instead of an unrelated jewelry/craft scene — genuine recognition win |
| business.coworking | Standard | professional_world | FAIL (recognition) | **FAIL** | 5 | recognition | Still substitutes a generic collaborative lab-bench scene; nothing distinguishes "coworking" from "startups"/"marketing" — the shared generic subject_template is the root cause, unchanged |
| business.marketing | Standard | professional_world | FAIL (recognition) | **FAIL** | 5 | recognition | Same generic workshop substitution as coworking; still no marketing-specific visual anchor |
| career.software_engineering | Standard | professional_world | MINOR (cardchrome) | **FAIL** | 5 | text | Card-chrome border is gone, but both monitors now show clearly legible source code — professional_world's "screens absent or blank" instruction did not hold here |
| career.legal_profession | Standard | professional_world | FAIL (text) | **FAIL** | 4 | text | The "LEGAL PROFESSION" gold banner caption is back, essentially unchanged from before |
| career.journalism | Standard | professional_world | FAIL (text_cardchrome) | **PASS** | 5 | - | Poster frame and "JOURNALISM" caption both gone; clean film-crew scene. Genuine fix |
| technology.electronics | Standard | tech_workspace | FAIL (text) | **PASS** | 5 | - | Screens now show only abstract geometry/graphs/nodes, zero readable code. Genuine fix |
| technology.generative_ai | Standard | tech_workspace | FAIL (text) | **FAIL** | 5 | text | Screen content itself is now clean abstract visuals (the code problem is fixed), but a bold "Generative AI" title caption now floats over the screen — a different defect replacing the old one |
| technology.machine_learning | Standard | tech_workspace | FAIL (text) | **MINOR** | 5 | text (minor) | Clean abstract visuals; one tiny, mostly illegible label remains in a corner panel. Major improvement |
| technology.javascript | Klein | tech_workspace | FAIL (text) | **PASS** | 5 | - | Was severely legible code before; now purely abstract line-chart visuals. Genuine fix |
| learning.book_genre.literary_fiction | Standard | reading_world | FAIL (text) | **PASS** | 5 | - | Book covers and spines are now completely blank/plain. Genuine fix |
| learning.fiction | Standard | reading_world | FAIL (text) | **PASS** | 5 | - | Same — blank covers and pages throughout. Genuine fix |
| learning.book_genre.booktube | Klein | reading_world | FAIL (recognition) | **FAIL** | 5 | recognition | Text/cover problem is fixed (fully blank book), but the scene is still indistinguishable from plain "reading" — no camera/recording/content-creation cue was added, so the specific "BookTube" identity still doesn't read |
| travel.general | Standard | travel_vista | FAIL (text) | **FAIL** | 2.5 | text (severe, worse) | Got worse: a bold "Travel" title plus a full paragraph of gibberish body text in a white caption box now dominate the lower half of the image, in addition to a fantasy-castle scene that still doesn't clearly read as generic travel |
| travel.destination_deep.tokyo_travel | Standard | travel_vista | FAIL (text) | **PASS** | 5 | - | Clean — no caption, no signage; Tokyo Tower alone carries destination identity. Genuine fix, and evidence the underlying approach (architecture over signage) works when a landmark is available |
| travel.japan | Standard | travel_vista | FAIL (text) | **FAIL** | 5 | text | No large poster caption this time (an improvement in degree), but readable Japanese characters remain visible on street banners/signs — the specific defect `travel_vista`'s fix targeted is still present |
| food.yum_cha | Klein (SENTINEL) | ethnic_signage_food | FAIL (text) | **PASS** | 5 | - | Completely clean — no signage, no lanterns, no banners, zero text of any kind. First clean result after 3 prior rounds of failure |
| food.food_markets | Klein | ethnic_signage_food | FAIL (text) | **PASS** | 5 | - | Also completely clean — close food-interaction framing, no venue signage. Genuine, complete fix |
| sports.american_football | Klein (SENTINEL) | uniform_sports | FAIL (text_logo) | **PASS** | 5 | - | Plain solid unnumbered kit, plain helmet, exactly one brown oval football, no crest/swoosh/number. First clean result after 2 prior rounds of failure |
| sports.football | Klein | uniform_sports | FAIL (logo) | **PASS** | 5 | - | Plain solid kit, plain ball, no crest/swoosh/number. Genuine, complete fix |

## Group-level before/after

| Group | n | Before (scale-100) | After | Change |
|---|---|---|---|---|
| `professional_world` | 6 | 0 PASS / 1 MINOR / 5 FAIL (83% FAIL) | 2 PASS / 0 MINOR / 4 FAIL (67% FAIL) | Improved but not solved |
| `tech_workspace` | 4 | 0 PASS / 0 MINOR / 4 FAIL (100% FAIL) | 3 PASS / 1 MINOR / 0 FAIL wait-see-note (0% hard FAIL on code; 1 text-caption FAIL) | **Substantially improved** — see note |
| `reading_world` | 3 | 0 PASS / 0 MINOR / 3 FAIL (100% FAIL) | 2 PASS / 0 MINOR / 1 FAIL (33% FAIL) | **Substantially improved** — text defect eliminated |
| `travel_vista` | 3 | 0 PASS / 0 MINOR / 3 FAIL (100% FAIL) | 1 PASS / 0 MINOR / 2 FAIL (67% FAIL) | Mixed — one clean win, one regression |
| `ethnic_signage_food` | 2 | 0 PASS / 0 MINOR / 2 FAIL (100% FAIL) | **2 PASS / 0 MINOR / 0 FAIL (0% FAIL)** | **Fully solved** |
| `uniform_sports` | 2 | 0 PASS / 0 MINOR / 2 FAIL (100% FAIL) | **2 PASS / 0 MINOR / 0 FAIL (0% FAIL)** | **Fully solved** |

Note on `tech_workspace`: `technology.generative_ai`'s one remaining failure
is a *different* defect (title-caption text) than what this fix targeted
(on-screen code). Counted as FAIL against the hard criteria, but it
represents a clean win for the specific thing `tech_workspace` was fixed to
address — 4/4 cards now have zero readable code/terminal/UI content, versus
0/4 before.

## Overall 20-card metrics

| | Before (scale-100, same 20 IDs) | After |
|---|---|---|
| PASS | 0 (0%) | 11 (55%) |
| MINOR | 2 (10%) | 1 (5%) |
| FAIL | 18 (90%) | 8 (40%) |

Klein subset (6 cards): 5 PASS / 0 MINOR / 1 FAIL (83% PASS) — much higher
than the 100-card batch's 36% Klein PASS rate, though this is a small sample
deliberately selected around the two now-fixed sentinel classes, not a
representative cross-section.

## Yum Cha verdict: **PASS — sentinel finally solved**

Checked: zero menu text, zero banner/lantern/storefront writing, no
pseudo-Chinese/Japanese/Korean script anywhere. Confirmed clean. This is the
first clean result for `food.yum_cha` after three prior rounds of failure
(48-card batch, 100-card batch, and the earlier model A/B). The close
table/food-interaction framing that crops the venue façade out of frame is
the fix that worked, after negative-prompt-only approaches repeatedly failed.

## American Football verdict: **PASS — sentinel finally solved**

Checked: no jersey number, no player name, no team crest, no sponsor patch,
no swoosh-like mark, no three-stripe-like mark. Confirmed clean: plain solid
gray practice kit, plain unbranded helmet and shoulder pads, exactly one
brown oval football, yard-line field context, no soccer/rugby confusion.
First clean result after two prior rounds of failure. The generic
practice-kit reframing (rather than relying on negative_prompt alone to
suppress a competition-jersey prior) is the fix that worked.

## Klein style drift

| Card | Drift |
|---|---|
| technology.javascript | MINOR |
| learning.book_genre.booktube | MATERIAL |
| food.yum_cha | MATERIAL |
| food.food_markets | MATERIAL |
| sports.american_football | MATERIAL |
| sports.football | MATERIAL |

**5/6 (83%) MATERIAL drift** — worse than the 100-card batch's 52%. The
content/text fixes and style drift are independent problems: Klein can now
reliably avoid signage/branding text for these classes, but it renders them
in a strongly photoreal/stock-photo style rather than the painterly
collectible-illustration house style. Both sentinel PASSes above are
photoreal in a way that would look visually inconsistent next to a
painterly-illustrated standard-FLUX card in the same collection.

## Remaining systemic defect families

1. **Spontaneous hobby-title caption text (new, cross-cutting).** Appears on
   `career.legal_profession` ("LEGAL PROFESSION"), `technology.generative_ai`
   ("Generative AI"), and `travel.general` ("Travel" + a full paragraph) —
   three unrelated archetypes, all previously-failing cards, none of which
   this fix's archetype-level "no text" language stopped. This looks like a
   generalized model tendency to add a title/caption to certain compositions
   regardless of which archetype instructions are attached, and is now the
   single most common defect class in this sample.
2. **`professional_world` recognition for abstract/office professions.**
   `business.coworking` and `business.marketing` still substitute an
   unrelated generic workshop/lab scene. The shared `subject_template`
   ("People actively practicing ${title} through a concrete business...
   task") has no concrete anchor object for professions that are inherently
   about *space* (coworking) or *messaging* (marketing) rather than a
   physical trade — this needs hobby-specific subject text, not a better
   shared template.
3. **Travel signage for destinations without one iconic landmark.**
   `travel.destination_deep.tokyo_travel` passed because Tokyo Tower is a
   strong non-textual identity anchor; `travel.japan` (no single named
   landmark in its recipe) still leans on street banners with legible
   characters to carry "Japan-ness."
4. **Klein style drift**, unchanged/worse — a distinct, unresolved problem
   from everything above.

## Answers to the eleven questions

1. **Did `professional_world` materially improve?** Partially. FAIL rate
   83% -> 67%; 2 of 6 cards now genuinely pass, but the core abstract-
   profession recognition problem (coworking, marketing) and a new
   screen-text regression (software_engineering) remain.
2. **Did `tech_workspace` materially improve?** Yes, substantially. The
   specific defect it was fixed for (readable code/terminal/UI) is
   eliminated in all 4 cards; one card picked up a different (caption-text)
   defect instead.
3. **Did `reading_world` stop producing book text/signage failures?** Yes.
   Zero of 3 cards now show any cover/spine/shelf text defect (down from 3
   of 3). The one remaining failure (`booktube`) is an unrelated recognition
   problem.
4. **Did `travel_vista` stop depending on city/travel signage?** No, not
   consistently. One clean win via strong architecture (Tokyo Tower), but
   `travel.japan` still shows readable signage and `travel.general` got
   worse, not better.
5. **Did structural reframing solve Yum Cha / Food Markets?** **Yes,
   completely** — 2/2 clean, first clean result after 3 prior failure rounds.
6. **Did structural reframing solve team-sports branding/numbers?** **Yes,
   completely** — 2/2 clean, first clean result after 2 prior failure rounds.
7. **Is Klein still causing unacceptable style drift?** Yes, worse in this
   sample — 83% MATERIAL vs 52% previously.
8. **Which defect families remain systemic?** Spontaneous title-caption
   text (new, cross-archetype), `professional_world` recognition for
   abstract office professions, travel signage for landmark-poor
   destinations, and Klein style drift.
9. **Are we ready for another scale batch?** Not at full scale. The two
   hardest, most-tested classes (ethnic food, uniform sports) are now solid
   and could reasonably be trusted at scale. `tech_workspace` and
   `reading_world` are close. `professional_world` and `travel_vista` are
   not ready.
10. **If yes, what size?** N/A as a blanket answer — see smallest next step.
    If scaling only the now-solid classes (ethnic food, uniform sports,
    tech_workspace, reading_world), a **50-card** confirmatory batch across
    a wider sample of each would be reasonable next. Do not extend that to
    `professional_world` or `travel_vista` yet.
11. **If no, what is the smallest next repair/test?** Two independent,
    narrow fixes, each testable on 3-4 cards before any batch:
    - Add an explicit, strongly-worded **global** (not per-archetype)
      constraint against rendering the hobby's own title/name as a caption
      or label anywhere in the image — the current per-archetype "no text"
      language is evidently not catching this specific pattern.
    - Give `business.coworking` and `business.marketing` their own
      hobby-specific `subject_template` text (a concrete anchor: e.g.
      coworking -> shared desk/open workspace with distinct
      desk-neighbors; marketing -> campaign board/mockup/product display
      being arranged) instead of the shared generic professional_world
      template, following the pattern that already worked for
      `business.startups`.

## Infrastructure

Vercel deployment confirmed disabled for this branch (unchanged). No GitHub
Actions workflow triggers on push to this branch. This commit/push is a
plain repo write with no CI/deployment side effects. Play/Production remain
untouched and closed. `FAL_KEY` was not committed or exposed. Gemini and
Nano Banana Pro were not used. No auto-reroll was performed.

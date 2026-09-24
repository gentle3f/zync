# Zync Card Art — Final Production-Hygiene Remediation: Business Titles + Arts Text Suppression

Branch: `card-art-pilot-v1-20260921`
Date: 2026-09-24
Provider: Google Gemini API direct (`gemini-3.1-flash-lite-image`, Batch API). No fal.ai.

This round closed two known text-hygiene classes from Batch 1: the two
remaining business "diagram title" blockers, and the broader `arts.*`
text-leak cluster (14/89, 15.7% in Batch 1). **Batch 2 was NOT started**
and remains hard-locked (`runProductionBatch.js`'s
`AUTHORIZED_BATCH_NUMBERS = new Set([1])`, unchanged).

## Part 1 — Business title/heading hardening

`business_text_suppression_policy` in `global_style_v1.json` gained a new
paragraph: a diagram/whiteboard/roadmap/kanban board having its internal
labels removed is not enough - the board as a whole must also carry NO
title, NO heading, NO caption, and NO large central readable phrase, not
even the short name of the diagram type itself (explicitly: never write
"Roadmap", "Product Roadmap", "Life Map", "Mind Map", "Empathy Map",
"Plan"). Books/notebooks in business scenes must have blank/abstract
covers. The board must stay visually rich (layout, color-coding, columns,
connecting lines intact) - only the words must disappear.

## Part 2 — New `arts.*` text-suppression policy

New field `arts_text_suppression_policy` added to `global_style_v1.json`,
wired into `buildPromptV1.js` gated on `effective.id?.startsWith('arts.')`
- auto-applies catalog-wide to all 89 `arts.*` hobbies. Requires zines,
notebooks, scripts, posters, sketchbooks, magazines, booklets, art labels,
workshop boards, and design layouts to use blank page blocks, abstract
graphic shapes, non-linguistic scribble marks, and plain/abstract covers;
explicitly forbids readable titles, captions, script lines, book/zine
names, poster text, joke/punchline text, pseudo-English/pseudo-Japanese,
and typography-as-decoration - while explicitly preserving the creative
activity itself (folding, cutting, pasting, drawing, writing, rehearsing).

Full 2210-row catalog regression: `OK: 2210 / 2210, ERRORS: 0`; confirmed
the arts policy applies to exactly the 89 `arts.*` hobbies and the
business policy to exactly the 40 `business.*` hobbies, with zero
cross-contamination in either direction.

## Part 3 — 8-card test set

`tools/card_art/catalog/final_hygiene_test_8_v1.json` (written before
generation):

| ID | Role | Cause family | Prior defect |
|---|---|---|---|
| `business.product_management` | mandatory business blocker | — | "Product Roadmap" title + column headers |
| `business.fire_movement` | mandatory business blocker | — | new "Life Map" title |
| `arts.zine_making` | mandatory arts control | book/zine cover | literal "ZINE" repeated |
| `arts.comedy_writing` | mandatory arts control | notebook/whiteboard | "THESAURUS" + readable joke text |
| `arts.hip_hop_dance` | additional offender | poster/signage | graffiti "FLOW"/"CYPHER"/"UNITY EST. 98" |
| `arts.voice_acting` | additional offender | script/notebook | legible Japanese script text |
| `arts.calligraphy` | additional offender | workshop/scroll (hardest stress test) | background wall-scroll characters |
| `arts.webcomics` | additional offender | layout/design surface + screen UI | toolbar UI chrome + book-cover text |

Cause-family coverage across all 6 arts cards: book/zine cover,
notebook/whiteboard, poster/signage, script/notebook, workshop/scroll,
layout/design surface — matches the task's requested diversity.

## Part 4 — Generation

Batch: `batches/oem8kbk06k56o6u8visuq6vlyygkcujs13p3`. **8/8 succeeded, 0
failed.** Actual cost: **$0.1344** (8 × $0.0168, matches estimate). Dry-run
confirmed the correct policy (business-only for the 2 business ids,
arts-only for the 6 arts ids, zero cross-leak) before any request was
sent.

## Part 5 — QA (full results in `output/final_hygiene_test_8_v1/qa_results_v1.json`)

| ID | Readable text | Detail | Brand leak | Outcome |
|---|---|---|---|---|
| `business.product_management` | **NO** | — | NO | **FIXED** - fully abstract hexagon/node diagram, zero text |
| `business.fire_movement` | **YES** | Small legible labels "Side Hustles"/"Investing" on sticky notes (no more big title) | NO | **PARTIALLY FIXED** |
| `arts.zine_making` | **YES** | Primary zine prop now clean; background wall poster/flyer collage still shows legible fragments | NO | **MAJOR IMPROVEMENT, not fully fixed** |
| `arts.comedy_writing` | **YES** | "THESAURUS" book spine unchanged across all 3 rounds; notebook now illegible (improved) | NO | **PARTIALLY FIXED** |
| `arts.hip_hop_dance` | NO | Graffiti fully eliminated | **YES (new)** | Text **FIXED**; new swoosh-like/three-stripe brand finding |
| `arts.voice_acting` | NO | — | NO | **FIXED** |
| `arts.calligraphy` | **YES** | Background scroll/framed characters persist (hardest stress test, as expected) | NO | **NOT FIXED, largely expected** |
| `arts.webcomics` | NO | — | NO | **FIXED** (text and screen-policy both clean) |

Semantic: 8/8 PASS. D4 style fidelity: PASS on all 8. Border/UI defects:
0/8. Safety issues: 0/8.

**Business readable-text rate: 1/2** (required 0/2 for GREEN — not met).
**Arts readable-text rate: 3/6** (required 0/6 for GREEN — not met).

## Final production hygiene gate: **AMBER**

**Not GREEN**: neither the business (1/2) nor the arts (3/6) readable-text
rate reaches the required 0. Per the gate's explicit rule, a business card
still producing readable text (`business.fire_movement`) and the arts
policy still producing a readable-text pattern on half the tested cards
both independently keep Batch 2 locked.

**Not RED**: this round produced clear, substantial, measurable progress
rather than a structural failure of the policy approach - 4 of 8 cards
(`business.product_management`, `arts.voice_acting`, `arts.webcomics`,
and `arts.hip_hop_dance` on its text dimension) are now completely clean
of their prior defect; the two remaining business/arts "big title"
patterns that motivated this round (`business.product_management`'s
"Product Roadmap", `arts.hip_hop_dance`'s graffiti wall) are both fully
eliminated; and the two still-failing cases that were also tested in the
prior remediation round (`business.fire_movement`, `arts.comedy_writing`,
plus new-this-round `arts.zine_making`) show a smaller, more localized
residual leak than before, not a worsening. `arts.calligraphy` failing was
explicitly anticipated as the hardest possible stress test. This is
localized, diagnosable, per-hobby residue, not a systemic breakdown.

**Batch 2 remains locked.** Remaining blockers, each narrow and
independently addressable:

1. `business.fire_movement` - small sticky-note-style labels leak even
   with the title suppressed; the business policy may need an explicit
   "no readable text on sticky notes either, however small" reinforcement,
   or a hobby-level override.
2. `arts.comedy_writing` - the "THESAURUS" book-title prop is unchanged
   across all three rounds; likely needs a dedicated hobby-level override
   (same pattern as `books.reading`'s existing fix).
3. `arts.calligraphy` - background scroll/framed-art characters persist;
   likely needs a dedicated hobby-level override (same pattern as the
   existing `wellness.tai_chi` fix).
4. `arts.zine_making` - primary prop is now clean; only background wall
   poster decor still leaks - the smallest residual issue of the four,
   possibly resolvable with one more general policy pass targeting
   incidental background "gig poster"/flyer collage specifically.
5. `arts.hip_hop_dance` - a new brand/trademark finding (footwear
   swoosh-like mark, apparel three-stripe pattern) needs review; this is
   the same residual-silhouette risk class already documented for
   `sports.skateboarding` and `arts.kpop_dance`.

## Part 6 — Updated Batch-1 regeneration classification

`tools/card_art/output/production_batch_001_v1/batch1_targeted_regeneration_list_v1.json`
was rebuilt (v2) using this round's validated/unvalidated results. New
subclasses replace the prior round's naming:

| Subclass | Count | Meaning |
|---|---|---|
| `policy_fix_validated_and_ready_for_regen` | **11** | Individually spot-tested and confirmed clean (the 8 from the prior remediation round + `business.product_management`, `arts.voice_acting`, `arts.webcomics`, newly validated this round) |
| `policy_fix_still_unvalidated` | **23** | The relevant policy now structurally applies (business title rule, arts text-suppression, or pre-existing brand-safety policy) but the specific id was not individually spot-tested (includes `business.fire_movement`, downgraded this round since its leak persists) |
| `manual_review_required` | **5** | No current policy fully addresses the specific defect: `arts.comedy_writing`, `arts.calligraphy`, `arts.zine_making` (all still leak after retesting), `arts.hip_hop_dance` (new brand finding), `arts.online_video_creation` (anatomy/object-placement defect, no applicable text or brand policy) |
| `approved_as_is` | 81 | Unchanged from the prior round |

**Regeneration planning** (classification only - nothing executed):

- **Ready now: 11 images, estimated cost $0.1848** (11 × $0.0168) - these
  have individually confirmed-clean fixes and could be regenerated as soon
  as a future task is authorized to do so.
- **Total eventual scope if every remaining id is fixed and validated: 39
  images, estimated cost $0.6552** - a planning ceiling, not a current
  recommendation; most of these 39 still need either individual
  spot-testing or a dedicated hobby-level override.

**No Batch-1 images were regenerated in this task.**

## Guardrails honored

- Exactly 8 new images generated, no rerolls.
- Batch 2 not started; authorization lock unchanged.
- No fal.ai, no GitHub Actions, no Vercel, no Production deployment, no
  Google Play.
- `sports.american_football` and `technology.robotics` remain quarantined
  (untouched; not part of the 8-card set).
- Git history was not rewritten.
- Reused the permanent streaming-collection fix from Batch 1.
- No raw base64, thoughtSignature blobs, or unredacted large payloads
  committed.
- `GEMINI_API_KEY` was never printed, logged, or committed.
- No prior Batch-1 or prior-remediation images were regenerated or
  touched.

## Files in this checkpoint

- `tools/card_art/specs/global_style_v1.json` (modified — business
  title/heading paragraph added; new `arts_text_suppression_policy` field)
- `tools/card_art/src/buildPromptV1.js` (modified — wires the arts policy
  in for `arts.*` ids only)
- `tools/card_art/catalog/final_hygiene_test_8_v1.json` (new — 8-card test
  config, ID + original-defect documentation, gate)
- `tools/card_art/src/runFinalHygieneTest8.js` (new — runner)
- `tools/card_art/output/final_hygiene_test_8_v1/` (new — 8 images,
  manifest, redacted batch status/job/requests, QA results)
- `tools/card_art/output/production_batch_001_v1/batch1_targeted_regeneration_list_v1.json`
  (rewritten v2 — updated classification, regeneration planning)

## Report

- Actual cost: $0.1344
- 8 tested IDs: see table above
- Business before/after: `business.product_management` FIXED;
  `business.fire_movement` PARTIALLY FIXED (title gone, small labels
  remain) — business readable-text rate 1/2
- Arts before/after: `arts.voice_acting`, `arts.webcomics` FIXED;
  `arts.hip_hop_dance` text FIXED (new brand finding); `arts.zine_making`
  major improvement (primary prop clean, background residual);
  `arts.comedy_writing`, `arts.calligraphy` still leak — arts
  readable-text rate 3/6
- Final classification: **AMBER**
- Batch-1 planned regeneration count: 11 ready now (of 39 total
  eventually needing regeneration)
- Estimated regeneration cost: $0.1848 ready now / $0.6552 total ceiling
- Batch 2 eligibility: **NOT YET eligible for authorization** - the gate
  was not met; five narrow, independently-addressable blockers remain
  (see list above) before Batch 2 can be considered, even with explicit
  user authorization.

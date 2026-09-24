# Zync Card Art — Narrow Hobby-Level Fixes: GREEN Production Hygiene

Branch: `card-art-pilot-v1-20260921`
Date: 2026-09-24
Provider: Google Gemini API direct (`gemini-3.1-flash-lite-image`, Batch API). No fal.ai.

This round closed the five narrow, hobby-specific blockers remaining
after the category-level fixes (business text policy, arts text policy)
resolved the broad structural issues. **Production hygiene is now
GREEN.** **Batch 2 was NOT started** and remains hard-locked
(`runProductionBatch.js`'s `AUTHORIZED_BATCH_NUMBERS = new Set([1])`,
unchanged). GREEN means Batch 2 is now *eligible* for explicit user
authorization - a separate new instruction is still required to actually
start it.

## Part 1-5 — Five hobby-level overrides

All five added as new entries in `tools/card_art/catalog/hobby_overrides_v1.json`:

- **`business.fire_movement`** — subject rewritten to require an entirely
  unlabeled physical financial-planning structure (blank colored cards,
  abstract bars, arrows, circles, coins, generic savings objects);
  explicit forbidden-word list (Side Hustles, Investing, Savings, FIRE,
  Income, Expenses, Retirement, Goals, Finance) plus a rule that *any*
  sticky note, however small, must be blank or carry only an abstract
  mark, never a word.
- **`arts.comedy_writing`** — the thesaurus/dictionary prop is removed
  **structurally** (not just blanked) per the task's explicit instruction;
  subject rewritten around a blank notebook/script pages, brainstorming
  gesture, and comic-timing reaction.
- **`arts.calligraphy`** — a genuine semantic exception: brush-and-ink
  mark-making stays required, but the marks must be abstract, partial,
  gestural, cropped, or overlapping rather than a complete readable
  character/word; hanging wall scrolls and framed wall-mounted writing
  are removed entirely rather than blanked; camera favors brush
  tip/ink trail/hand action/paper texture.
- **`arts.zine_making`** — environment override requiring a plain studio
  wall or blank corkboard background (no posters, flyers, wall
  typography, signs, or banners); any other pinned zines/magazines in the
  background must be blank or image-led.
- **`arts.hip_hop_dance`** — apparel-safety override requiring generic
  unbranded dance sneakers and streetwear; explicit anti-swoosh/
  three-stripe/manufacturer-badge language; option to reduce footwear
  visual emphasis rather than force complex unbranded shoe detail;
  reaffirms background graffiti must stay abstract shapes only.

Full 2210-row catalog regression: `OK: 2210 / 2210, ERRORS: 0`. Verified
all five override texts appear correctly in their respective compiled
prompts.

## Part 6 — Exact 5-card revalidation

Batch: `batches/phah2qtolk1suwdmcmx2qxty4l0i606h26hu`. **5/5 succeeded, 0
failed.** Actual cost: **$0.084** (5 × $0.0168, matches estimate). Exactly
the five specified IDs, no substitutions, no extra cards:
`business.fire_movement`, `arts.comedy_writing`, `arts.calligraphy`,
`arts.zine_making`, `arts.hip_hop_dance`.

## Part 7 — QA (full results in `output/hobby_fix_revalidation_5_v1/qa_results_v1.json`)

| ID | Original defect | Readable text | Brand leak | Semantic | Outcome |
|---|---|---|---|---|---|
| `business.fire_movement` | Small sticky-note labels "Side Hustles"/"Investing" | NO | NO | PASS | **FIXED** |
| `arts.comedy_writing` | "THESAURUS" book spine (unchanged 3 rounds) | NO | NO | PASS | **FIXED** |
| `arts.calligraphy` | Background scroll characters | NO* | NO | PASS | **FIXED** |
| `arts.zine_making` | Background poster/flyer text | NO | NO | PASS | **FIXED** |
| `arts.hip_hop_dance` | Swoosh-like mark + three-stripe pattern | NO | NO | PASS | **FIXED** |

\* Per the task's explicit QA rule for this hobby: abstract/expressive/
non-linguistic brush strokes are not counted as a text leak. The main
brush stroke reads as a dynamic gestural mark, not a complete character;
two tiny background wall items show ambiguous ink-like marks too small
and stylized to count as clearly recognizable readable characters.

D4 style fidelity: PASS on all 5. Border/UI defects: 0/5. Safety issues:
0/5. Brand/trademark leaks: 0/5.

## Final production hygiene gate: **GREEN**

All five criteria met:

- `business.fire_movement`: no readable sticky-note labels, no readable
  headings/titles. ✓
- `arts.comedy_writing`: no "THESAURUS", no other readable writing. ✓
- `arts.calligraphy`: no recognizable/readable real text (abstract brush
  marks correctly permitted, not penalized). ✓
- `arts.zine_making`: no readable hero or background text. ✓
- `arts.hip_hop_dance`: no swoosh/check-like mark, no three-stripe
  pattern, no brand/pseudo-brand mark, no readable graffiti. ✓
- Global: semantic FAIL = 0, brand leaks = 0, border/UI defects = 0,
  safety issues = 0, no new systemic defect introduced. ✓

This is the first GREEN result across the entire Batch-1 remediation arc
(prior rounds were AMBER, AMBER, AMBER). **Batch 2 is now eligible for
explicit user authorization.** Per the task's explicit instruction, Batch
2 was **not** started in this round regardless - a separate, new user
instruction is required to actually begin it.

## Part 8 — Updated Batch-1 regeneration classification

`tools/card_art/output/production_batch_001_v1/batch1_targeted_regeneration_list_v1.json`
was rebuilt (v3) re-evaluating all 39 previously-flagged entries:

| Subclass | Count | Meaning |
|---|---|---|
| `policy_fix_validated_and_ready_for_regen` | **16** | Individually spot-tested and confirmed clean (the 11 from before + the 5 fixed this round: `business.fire_movement`, `arts.comedy_writing`, `arts.calligraphy`, `arts.zine_making`, `arts.hip_hop_dance`) |
| `policy_fix_unvalidated` | **22** | The relevant category-level policy (business/arts text suppression, or pre-existing brand-safety policy) structurally applies but the specific id was not individually spot-tested |
| `manual_review_required` | **1** | `arts.online_video_creation` only - its defect (camera-rig/anatomy placement oddity) is not addressed by any text or brand policy; needs individual human review/recipe adjustment, not a text-suppression fix |
| `approved_as_is` | 81 | Unchanged |

**Regeneration planning** (classification only - nothing executed):

- **Ready now: 16 images, estimated cost $0.2688** (16 × $0.0168).
- **Total eventual scope if every remaining id is validated: 39 images,
  estimated cost $0.6552** - unchanged ceiling, still a planning number
  only.

**No Batch-1 images were regenerated in this task.**

## Guardrails honored

- Exactly 5 new images generated, no rerolls.
- Batch 2 not started; authorization lock unchanged, even though the
  gate is now GREEN.
- No fal.ai, no GitHub Actions, no Vercel, no Production deployment, no
  Google Play.
- `sports.american_football` and `technology.robotics` remain quarantined
  (untouched; not part of the 5-card set).
- Git history was not rewritten.
- Reused the permanent streaming-collection fix from Batch 1.
- No raw base64, thoughtSignature blobs, or unredacted large payloads
  committed.
- `GEMINI_API_KEY` was never printed, logged, or committed.
- No prior Batch-1 or prior-remediation images were regenerated or
  touched.

## Files in this checkpoint

- `tools/card_art/catalog/hobby_overrides_v1.json` (modified — 5 new
  hobby-level overrides)
- `tools/card_art/catalog/hobby_fix_revalidation_5_v1.json` (new — 5-card
  test config, ID + original-defect documentation, gate)
- `tools/card_art/src/runHobbyFixRevalidation5.js` (new — runner)
- `tools/card_art/output/hobby_fix_revalidation_5_v1/` (new — 5 images,
  manifest, redacted batch status/job/requests, QA results)
- `tools/card_art/output/production_batch_001_v1/batch1_targeted_regeneration_list_v1.json`
  (rewritten v3 — updated classification, regeneration planning)

## Report

- Actual cost: $0.084
- Result for each of the 5 IDs: all **FIXED** (see table above)
- Final classification: **GREEN**
- Batch-1 regeneration-ready count: 16
- Estimated regeneration cost: $0.2688 (ready now) / $0.6552 (full ceiling)
- Batch 2 eligibility: **Eligible for explicit user authorization** - not
  started this round; requires a new, separate user instruction to begin.

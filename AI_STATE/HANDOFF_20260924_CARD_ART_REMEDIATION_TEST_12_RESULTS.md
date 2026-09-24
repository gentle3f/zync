# Zync Card Art — Batch-1 Remediation: Fixes + 12-Card Targeted Validation

Branch: `card-art-pilot-v1-20260921`
Date: 2026-09-24
Provider: Google Gemini API direct (`gemini-3.1-flash-lite-image`, Batch API). No fal.ai.

This round implemented narrow production-hardening fixes for the two
concrete Batch-1 (`production_batch_001_v1`) failure classes and validated
them with a 12-card targeted remediation test. **Batch 2 was NOT
started** and remains hard-locked in `runProductionBatch.js`
(`AUTHORIZED_BATCH_NUMBERS = new Set([1])`, unchanged this round).

## Part 1 — Business-category text-suppression policy

New field `business_text_suppression_policy` added to
`tools/card_art/specs/global_style_v1.json`, wired into
`tools/card_art/src/buildPromptV1.js`'s `compileHobbyPrompt()` with a
conditional: `if (globalStyle.business_text_suppression_policy &&
effective.id?.startsWith('business.'))`. This auto-applies to all 40
`business.*` canonical interests catalog-wide (not just the 30 in Batch
1), so batches 2–19 automatically inherit the fix once authorized - no
per-hobby override duplication was needed. Verified via regression check:
all 40 business hobbies carry the new policy text, zero non-business
hobbies do.

The policy requires whiteboards/kanban boards/roadmaps/dashboards/
sticky-notes/funnels/etc. to be rendered as blank colored rectangles,
unlabeled cards/nodes, lines, arrows, circles, and abstract charts: no
readable words, labels, headers, kanban column names, strategy
terminology, financial index/ticker names, or business acronyms anywhere
(with an explicit, non-exhaustive example list drawn directly from
Batch-1's actual offenders: GOAL, SKILLS, EMPATHY MAP, BACKLOG, DOING,
VALIDATION, DONE, S&P 500, KPI, ROI, OKR, ROADMAP, STRATEGY, GROWTH,
SALES, MARKETING, PRODUCT, TEAM, REVENUE, USER, CUSTOMER).

## Part 2 & 3 — Global device brand-safety hardening + broader cleanup

`global_brand_safety_policy` (existing field) extended with two new
paragraphs:

1. Device-specific language for laptops/tablets/phones/monitors/desktops/
   keyboards/headphones: plain uninterrupted lids/casing, no centered
   emblem, no fruit-shaped or bitten-fruit silhouette, no circular brand
   badge, no glowing lid logo, no manufacturer text/initials - applied by
   default even when no brand is named, directly targeting the Apple-logo
   leak found twice in Batch 1.
2. Software-icon and financial-term language: no recognisable real
   software product logos/icons (Figma-like, Adobe-like, Canva-like,
   Notion-like, Slack-like, etc.), and no real trademarked financial index
   names/ticker symbols/product branding (S&P 500, NASDAQ, Dow) - use
   generic unlabeled charting visuals instead.

Full 2210-row catalog regression: `OK: 2210 / 2210, ERRORS: 0` before any
generation.

## Part 4 — 12-card targeted test set

`tools/card_art/catalog/remediation_test_12_v1.json` (written before
generation) reuses actual Batch-1 offender IDs from
`production_batch_001_v1/qa_layer2_human_review_v1.json`:

| ID | Role | Original Batch-1 defect |
|---|---|---|
| `business.career_development` | business text offender | "SKILL DEVELOPMENT"/"GOAL" readable |
| `business.career_switching` | business text offender | "SKILLS"/"COMPANY"/"BUSINESS" readable |
| `business.design_thinking` | business text offender | "Empathy Map"/"Ideation Cluster" readable |
| `business.financial_independence` | business text offender | "BUSINESS GROWTH MILESTONES"/"REVENUE STREAMS" readable |
| `business.index_investing` | business text offender + real trademark | "S&P 500" (real trademark) readable |
| `business.product_management` | business text offender (kanban family) | "Backlog"/"Doing"/"Validation"/"Done" readable |
| `business.project_management` | business text offender (PM-lifecycle family) | "INITIATION"/"PLANNING"/"EXECUTION"/"MONITORING" readable |
| `business.fire_movement` | business text offender | whiteboard "Mind Map" header + "FINANCE" book spines readable |
| `business.coworking` | device-logo offender (required) | clear real Apple logo on laptop lid |
| `business.no_code` | device-logo offender (required) | clear real Apple logo on iPad |
| `arts.zine_making` | arts/text control | literal hobby name "ZINE" rendered repeatedly |
| `arts.comedy_writing` | arts/text control | whiteboard + "THESAURUS" book title readable |

No unrelated successful Batch-1 images were regenerated.

## Part 5 — Generation

Batch: `batches/y4h2nq4smk8wuezwbcks8epcovoduio400z7`. **12/12 succeeded,
0 failed.** Actual cost: **$0.2016** (12 × $0.0168, matches estimate).
Dry-run confirmed all 10 `business.*` ids carried the new
`business_text_suppression_policy` text and all 12 carried the
strengthened device-safety language before any request was sent.

## Part 6 — QA (full results in `output/remediation_test_12_v1/qa_results_v1.json`)

| ID | Semantic | Readable text | Device-brand leak | Outcome |
|---|---|---|---|---|
| `business.career_development` | PASS | NO | NO | **FIXED** |
| `business.career_switching` | PASS | NO | NO | **FIXED** |
| `business.design_thinking` | PASS | NO | NO | **FIXED** |
| `business.financial_independence` | PASS | NO | NO | **FIXED** |
| `business.index_investing` | PASS | NO | NO | **FIXED** (incl. the real "S&P 500" trademark) |
| `business.product_management` | PASS | **YES** | NO | **NOT FIXED** - "Product Roadmap" + "Discover/Validate/Build/Launch/Optimize" column headers still readable on the dominant foreground board |
| `business.project_management` | PASS | NO | NO | **FIXED** |
| `business.fire_movement` | PASS | **YES** | NO | **PARTIALLY FIXED** - book-spine "FINANCE" and whiteboard "Mind Map" header both eliminated, but a new "Life Map" title remains on the primary sheet |
| `business.coworking` | PASS | NO | **NO** | **FIXED** - no recognizable real logo on any of ~4 visible laptop lids |
| `business.no_code` | PASS | NO | **NO** | **FIXED** - no recognizable real logo; offending tablet is gone from the composition |
| `arts.zine_making` | PASS | YES (expected) | NO | **NOT FIXED, AS EXPECTED** - not in scope (not business.*), confirms isolated control |
| `arts.comedy_writing` | PASS | YES (expected) | NO | **NOT FIXED, AS EXPECTED** - same, isolated control |

D4 style fidelity and special-illustration quality: PASS on all 12.
Border/UI defects: 0/12. Safety concerns: 0/12. Other brand/trademark
leaks: 0/12 (no new issues introduced).

### Aggregate vs. targeted pass gate

| Gate criterion | Required | Actual |
|---|---|---|
| Semantic FAIL | 0 | 0 ✓ |
| Readable business text (of 8 business text offenders) | 0 | **2/8** ✗ |
| Device-logo leak (of 2 device offenders) | 0 | 0/2 ✓ |
| Real trademark text leak | 0 | 0 ✓ (S&P 500 fixed) |
| Border/UI defect | 0 | 0 ✓ |
| Safety issue | 0 | 0 ✓ |
| New systemic defect introduced | none | none ✓ |
| Isolated arts text issue outside business | doesn't block gate alone | 2/2 confirmed isolated, not counted against the business policy ✓ |

## Batch-2 decision: **AMBER**

**Not GREEN**: the gate's explicit rule - "If any business card still
renders clearly readable planning/kanban/whiteboard/dashboard text: Batch
2 stays locked" - is triggered by `business.product_management` and
`business.fire_movement`.

**Not RED**: the category-level policy clearly works in the large
majority of cases - 6 of 8 tested business text offenders went from
severely/clearly readable to completely clean, both required device-logo
offenders are fully fixed (including the real "S&P 500" trademark case),
and no new defect class was introduced anywhere. The two remaining
failures share a specific pattern - a single large **title** rendered
above an otherwise-correctly-abstracted diagram ("Product Roadmap",
"Life Map") - rather than the earlier dense scattering of many distinct
readable labels. This is a narrowed, well-bounded residual issue, not a
sign the policy failed structurally.

**Batch 2 may NOT proceed.** Remaining blocker: the business
text-suppression policy needs one more reinforcement pass specifically
targeting large diagram/board **titles** (not just internal labels) -
likely an explicit added sentence such as "never render a title or
heading above or on any diagram, board, or chart, even a short one" - re-validated on `business.product_management`, `business.fire_movement`,
and ideally 1-2 more untested business hobbies, before Batch 2 can be
authorized.

## Part 7 — Production artifact updates + Batch-1 classification

**Policy is live for future batches**: `business_text_suppression_policy`
and the strengthened `global_brand_safety_policy` are committed directly
in `global_style_v1.json`/`buildPromptV1.js`, so any future Batch 2–19
compilation automatically includes both fixes without further action.

**Batch-1 images were NOT regenerated this round** (per instruction).
Instead, `tools/card_art/output/production_batch_001_v1/batch1_targeted_regeneration_list_v1.json`
classifies all 120 Batch-1 images:

- **`approved_as_is`: 81 images** - no flagged defect in the Batch-1 QA.
- **`targeted_regeneration_needed`: 39 images**, further sub-classified:
  - **8 `fix_validated_ready_for_regeneration`** - the 6 fully-fixed
    business text offenders plus the 2 device-logo offenders tested this
    round (`business.career_development`, `business.career_switching`,
    `business.design_thinking`, `business.financial_independence`,
    `business.index_investing`, `business.project_management`,
    `business.coworking`, `business.no_code`).
  - **2 `fix_partial_needs_followup_before_regeneration`** -
    `business.product_management`, `business.fire_movement` (the two
    cards that motivated this round's AMBER classification).
  - **7 `business_policy_applied_not_individually_spot_tested`** - other
    Batch-1 business text offenders now covered by the same global policy
    (`business.budgeting`, `business.dividend_investing`,
    `business.ecommerce`, `business.freelancing`, `business.marketing`,
    `business.personal_branding`, `business.remote_work`) but not
    individually re-generated and inspected this round.
  - **22 `not_covered_by_this_rounds_fix_needs_separate_hobby_override`** -
    arts-category text/brand/screen leaks (calligraphy-family scrolls,
    urban-night signage, creator-tool screen UI, `arts.zine_making`,
    `arts.comedy_writing`, footwear/design-tool brand echoes, the one
    anatomy/object-corruption case) that are outside this round's scope
    entirely.

**No regeneration was executed for any of these 39 images this round.**

## Guardrails honored

- Exactly 12 new images generated, no rerolls, no batch beyond this test.
- Batch 2 not started; `runProductionBatch.js`'s authorization lock is
  unchanged (`AUTHORIZED_BATCH_NUMBERS = new Set([1])`).
- No fal.ai, no GitHub Actions, no Vercel, no Production deployment, no
  Google Play.
- `sports.american_football` and `technology.robotics` remain quarantined
  (untouched by this round's changes; not part of the 12-card set).
- Git history was not rewritten.
- Reused the permanent streaming-collection fix from Batch 1 (no giant
  in-memory JSON parsing reintroduced) - unnecessary at 12-image scale but
  kept for consistency and to avoid two divergent collection code paths.
- No raw base64, oversized thoughtSignature data, or unredacted large
  payloads committed - `batch_status.json` is a small redacted summary;
  compact forensic mapping (id ↔ prompt hash-equivalent metadata ↔
  filename ↔ file hash) preserved in `manifest.json`.
- `GEMINI_API_KEY` was never printed, logged, or committed.
- No prior Batch-1 images were regenerated or touched.

## Files in this checkpoint

- `tools/card_art/specs/global_style_v1.json` (modified — new
  `business_text_suppression_policy` field; strengthened
  `global_brand_safety_policy`)
- `tools/card_art/src/buildPromptV1.js` (modified — wires the business
  policy in for `business.*` ids only)
- `tools/card_art/catalog/remediation_test_12_v1.json` (new — 12-card test
  config, ID + original-defect documentation, targeted pass gate)
- `tools/card_art/src/runRemediationTest12.js` (new — runner)
- `tools/card_art/output/remediation_test_12_v1/` (new — 12 images,
  manifest, redacted batch status/job/requests, QA results)
- `tools/card_art/output/production_batch_001_v1/batch1_targeted_regeneration_list_v1.json`
  (new — classification only, no regeneration executed)

## Report

- Actual cost: $0.2016
- 12 tested IDs: see table above
- Before/after defect comparison: see QA table above
- Final classification: **AMBER**
- Exact remaining blocker: `business.product_management` and
  `business.fire_movement` still render a single large readable diagram
  **title** ("Product Roadmap", "Life Map") despite the new
  business-scoped text-suppression policy; needs one more reinforcement +
  re-validation pass before Batch 2 can be authorized. `arts.zine_making`
  and `arts.comedy_writing` remain readable-text-leak controls, correctly
  out of scope for this round and not counted against the business-policy
  gate.

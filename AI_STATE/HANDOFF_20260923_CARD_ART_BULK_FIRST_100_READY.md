# Zync — BULK-FIRST 100 Validation Ready

Date: 2026-09-23
Branch: `card-art-pilot-v1-20260921`
Parent HEAD before this preparation: `d0c2ad480782a02956b26431527c79f171320a8b`

## Purpose

Return to scalable production.

The full eligible catalog had already been split into:
- BULK-FIRST
- HOLDOUT
- QUARANTINED / BLOCKED

This checkpoint fixes the one known data bug and prepares a representative 100-card validation sample from BULK-FIRST before any large paid generation.

No image-generation API calls were made while preparing this checkpoint.

## Ice Fishing data bug fixed

Root cause:
- `outdoors.ice_fishing` matched the generic outdoors fishing rule and received `visual_variant: water_ritual`;
- later the outdoors winter rule changed its archetype to `outdoor_motion`;
- `water_ritual` exists under `water_outdoors`, not `outdoor_motion`, so generation would throw.

Fix:
- added a final specific rule for `outdoors.ice_fishing`;
- route is now:
  - `art_category: adventure`
  - `archetype: water_outdoors`
  - `visual_variant: water_ritual`

Static consistency check confirms the specific rule is after both conflicting generic rules and `water_ritual` exists under `water_outdoors`.

Because this was a pure routing/data-integrity defect rather than negative image evidence:
- `outdoors.ice_fishing` was removed from QUARANTINED/BLOCKED;
- it was added to BULK-FIRST;
- it is deliberately included in the 100-card validation sample.

Updated routing counts:
- BULK-FIRST: **1731**
- HOLDOUT: **477**
- QUARANTINED / BLOCKED: **2**
- Total eligible: **2210**

The two remaining quarantined items are:
- `sports.american_football`
- `technology.robotics`

Both are also machine-quarantined in `generation_guardrails_v1.json`.

## Stratified BULK-FIRST 100 validation

Prepared:
- `tools/card_art/catalog/bulk_first_100_validation_v1.json`
- `tools/card_art/src/runBulkFirst100Validation.js`

Expected generation:
- exactly **100** Standard FLUX calls;
- model: `fal-ai/flux-2`;
- estimated unit cost: $0.0125;
- estimated total: **US$1.25**;
- no auto-rerolls;
- no automatic follow-on 1731-card batch.

### Sampling strategy

This is intentionally not a plain random sample.

All **32 BULK-FIRST archetypes** receive at least one card.

Larger archetypes receive more cards using broad size-weighting, while still preserving wide archetype coverage.

Explicit boundary/repaired probes are forced into the sample, including:
- `outdoors.ice_fishing` — validates the routing fix;
- `entertainment.screenwriting`;
- `learning.book_genre.programming_books`;
- `arts.screen_printing`;
- `arts.livestreaming`;
- `business.marketing`;
- `business.coworking`;
- `career.legal_profession`;
- `learning.mock_trial`;
- `learning.moot_court`;
- `transport.aviation`;
- `sports.fencing`;
- `sports.archery`;
- `food.yum_cha`.

These deliberately exercise:
- repaired professional/legal routing;
- brand-safe sport fixes;
- food/signage robustness;
- keyword-boundary cases that stayed BULK-FIRST;
- the repaired Ice Fishing route.

Static audit confirms:
- sample size = 100;
- unique IDs = 100;
- archetypes covered = 32/32;
- every sampled ID belongs to current BULK-FIRST;
- no quarantined or holdout item appears;
- estimated total cost = $1.25.

## Free audit first

From `tools/card_art`:

```bash
node src/runBulkFirst100Validation.js --dry-run
```

The dry-run should:
- compile all 100 without error;
- confirm Ice Fishing resolves to `water_outdoors / water_ritual`;
- confirm no raw compiler IDs/headers leak;
- confirm no quarantined IDs are present;
- show Standard FLUX only.

Only if dry-run is clean:

```bash
node src/runBulkFirst100Validation.js
```

## QA after generation

Every one of the 100 images should be visually inspected.

Record at minimum:
- PASS / MINOR / FAIL;
- archetype / broad category;
- recognizability;
- text/pseudo-text leakage;
- logo/trademark/IP leakage;
- screen/code/UI leakage;
- card-border/chrome;
- style drift;
- anatomy/key-object failures.

Report:
- overall PASS / MINOR / FAIL;
- failure rate by archetype/category;
- clustered defect types.

### Decision rule

Do **not** invalidate BULK-FIRST because of isolated one-card failures.

Escalate only when failures cluster enough to indicate:
- archetype-level problem;
- category-level problem;
- systemic prompt/model defect.

Individual isolated failures can later be routed to the user's manual Image 2.5 queue.

Do not use Image 2.5 through fal.ai.

## What this checkpoint did NOT do

- No paid image generation.
- No 100-card run yet.
- No 1731-card bulk run.
- No Image 2.5 calls.
- No Robotics/American Football retesting.
- No Vercel, Production or Play action.

## Next step

Have Claude/local run the free dry-run, then — only if clean — generate exactly the prepared 100-card Standard FLUX validation set and inspect all 100 individually.

Do not start the 1731-card production run automatically.

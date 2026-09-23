# Zync — Confirmatory 30 Ready

Date: 2026-09-23
Branch: `card-art-pilot-v1-20260921`
Parent HEAD: `25b777a88158719ebce9522a7ed381ffb4d29685`

## Why 30, and why this composition

The structural scene-prior gate passed decisively: coworking, marketing, legal profession and BookTube all became clean PASSes after moving away from the failing archetype/model routes.

The next batch is intentionally **30 cards**, not 50 or 100, and is split into three evidence groups:

### 1. Structural generalisation / stability — 9 cards

- business.branding -> new exact `campaign_planning/mockup_table`
- career.digital_marketing -> new exact `campaign_planning/campaign_wall_table`
- learning.mock_trial -> new exact `legal_practice/student_advocacy`
- learning.moot_court -> new exact `legal_practice/student_advocacy`
- arts.vlogging -> existing `creator_workflow/camera_creation`
- arts.content_creation -> existing `creator_workflow/camera_creation`
- arts.podcasting -> existing `creator_workflow/microphone_session`
- arts.online_video_creation -> existing `creator_workflow/camera_creation`
- business.coworking -> stability control for `shared_workspace/communal_desks`

Important: we did **not** force unrelated hobbies into `shared_workspace` merely to manufacture breadth. Coworking is currently the only catalog concept that cleanly means a shared coworking space, so it is used as a repeat stability control instead.

### 2. Standard-FLUX migration from Klein — 4 cards

- sports.american_football
- sports.football
- food.yum_cha
- food.food_markets

These classes were structurally fixed but previously validated on Klein, whose style drift is unacceptable. This batch deliberately runs them on **Standard FLUX**. If all four pass, Klein can be retired for these structurally-fixed classes.

### 3. Fresh stratified discovery — 17 cards

Previously ungenerated in the existing validation configs:

- sports.archery
- sports.fencing
- wellness.pilates
- wellness.breathwork
- outdoors.birdwatching
- outdoors.skiing
- music.guitar
- music.vinyl
- food.pizza
- food.tea
- arts.watercolor
- arts.ceramics
- crafts.woodworking
- technology.robotics
- science.chemistry
- learning.book_clubs
- transport.aviation

This deliberately spans action, wellness, nature, music, food, studio/craft, technology, science, reading/social, and transport archetypes.

## New routing added

### business.branding
`campaign_planning / mockup_table`
Uses blank packaging/product mockups, abstract image cards and unlabeled colour/material swatches. No readable logos or slogans.

### career.digital_marketing
`campaign_planning / campaign_wall_table`
Uses physical campaign materials plus one sparse non-textual digital preview cue. No readable dashboards, metrics, copy, code or labels.

### learning.mock_trial / learning.moot_court
`legal_practice / student_advocacy`
The legal-practice base archetype is minimally broadened to include adult participants in a formal legal simulation, while retaining the same courtroom-architecture recognition strategy that fixed legal_profession.

## Execution

First run only:

```bash
cd tools/card_art
npm run audit-confirmatory-30-v1
```

Audit all 30 compiled prompts and routing. Verify no rights-blocked canonical slips into the batch.

Only if the dry-run is clean:

```bash
npm run generate-confirmatory-30-v1
```

Exactly 30 Standard-FLUX calls.
Estimated first-pass cost: **US$0.375**.
No auto-rerolls.

## Decision gate

Do not auto-scale after API success.

- Structural group: no repeated scene-prior recurrence; at least 8/9 PASS or MINOR.
- Standard migration group: retire Klein for these four classes only if **4/4 PASS** on Standard FLUX.
- Fresh 17: target at least 70% PASS, and no repeated systemic failure concentrated in one archetype/variant.
- Overall: any repeated defect class triggers diagnosis and the smallest structural repair before 50+.

Every image must be individually opened and visually inspected.

Track:
- PASS / MINOR / FAIL
- exact defect class
- archetype / visual variant
- title/caption/pseudo-text
- brand/logo/trade dress
- card chrome/borders
- recognition
- anatomy/key-object integrity
- house-style consistency

## Deferred issues

Do not mix these into this batch unless they naturally appear:
- travel.japan recognition/card-chrome issue
- minor UI-clutter texture on technology.generative_ai / electronics

## Infrastructure

Vercel and GitHub Actions remain closed for this branch. Production and Play remain closed. No paid generation was run while preparing this batch.

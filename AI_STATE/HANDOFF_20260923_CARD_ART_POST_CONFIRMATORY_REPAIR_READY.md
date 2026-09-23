# Zync — Post-Confirmatory Repair Gate Ready

Date: 2026-09-23
Branch: `card-art-pilot-v1-20260921`
Parent HEAD: `8c34edf269589c9a094294e3c90759b8f377bd76`

## Why this is the next gate

Confirmatory-30 proved two durable wins:
- the former professional_world workshop/jewelry/apprentice prior remains eliminated;
- global hobby-title/caption suppression remains perfect.

The highest-priority unresolved blocker is now **sportswear/equipment trademark leakage**. This repair addresses that first while using the same small batch to clear three isolated recipe defects and test the letterbox-noise hypothesis.

No paid generation was performed while preparing this gate.

## Repair 1 — brand-safe individual sports

A new late profile rule now covers three individual athletic clusters:
- `sports/racket`
- `sports/combat`
- `sports/precision`

It structurally requires plain generic sport-appropriate apparel/footwear and generic blank equipment surfaces, and explicitly excludes:
- swoosh-like marks
- three-stripe-like marks
- manufacturer badges
- brand-like chest prints
- brand-like shoe marks
- sponsor/retail branding

This is intentionally broader than hard-coding only archery/fencing, because the discovered failure is a real-world sportswear prior, not an archery-specific semantic defect. It does **not** alter water, cycling, running, mind-sports, or other unrelated clusters.

The validation samples only the two cards that actually failed/leaked in Confirmatory-30:
- sports.archery
- sports.fencing

Other newly-covered sports are not considered production-safe until separately observed.

## Repair 2 — American Football remains Klein-protected

`sports.american_football` is intentionally **not** migrated back to Standard FLUX.

Evidence is direct:
- same plain-kit prompt passed clean on Klein;
- same prompt leaked an unmistakable swoosh on Standard.

The repair batch therefore routes American Football through `kleinNegative` only.

## Repair 3 — letterbox diagnostic, no prompt change

Re-run the same repaired recipes for:
- learning.mock_trial
- business.coworking

Do not modify their prompts for letterboxing before this diagnostic. Their sibling/earlier samples were clean, so the current hypothesis is stochastic FLUX padding/card-chrome noise.

Interpretation:
- 0/2 recurrence -> strong evidence prior letterboxes were stochastic;
- any recurrence -> investigate output/layout handling or a broader FLUX framing issue before scale-up.

## Repair 4 — arts.vlogging

New exact rule keeps `creator_workflow/camera_creation` but makes the recording screen non-semantic:
- camera/phone viewed from side/rear;
- display turned away, blank, or non-textual;
- explicitly forbids hobby-name approximations such as VLOG/VLOGIN/VLOGGING;
- no title, tag, number, platform UI or channel text.

## Repair 5 — learning.book_clubs

New exact rule:
- `reading_world/book_club`
- three or four adults
- at least two blank/plain books
- active face-to-face discussion
- explicitly forbids a single solitary reader

## Repair 6 — transport.aviation structural fix

The previous `journey_machine/owner_machine` route was too vehicle-generic and allowed a vintage car to become the hero.

New archetype:
- `aviation_world`
- variant `aircraft_focus`

It makes one generic full-size aircraft the dominant hero object and explicitly prevents a car/truck/motorcycle from competing for foreground attention. Recognition comes from aircraft structure and airfield/hangar context, never airline livery or text.

## 8-card validation

Prepared:
- `tools/card_art/catalog/post_confirmatory_repair_v1.json`
- `tools/card_art/src/runPostConfirmatoryRepair.js`

Run first:

```bash
cd tools/card_art
npm run audit-post-confirmatory-repair-v1
```

Only if audit is clean:

```bash
npm run generate-post-confirmatory-repair-v1
```

Routes:
- 7 Standard FLUX
- 1 Klein (American Football)

Estimated first-pass cost: **US$0.0989**.
No auto-rerolls.

## Gate

Do not scale to 50/100 automatically.

Required:
1. archery + fencing + American Football all PASS rights-safety checks;
2. letterbox rerolls establish whether the defect is stochastic or recurrent;
3. vlogging, book_clubs, aviation each materially improve to PASS or at worst isolated MINOR without a new systemic pattern.

`tech_workspace` remains unresolved and deliberately separate. It has repeated readable screen/code leakage across five hobbies and needs its own structural remediation pass rather than more incremental negative wording.

## Infrastructure

Keep Vercel, GitHub Actions, Production and Play closed.

# Zync — Dedicated PC Gaming Retry Ready + Chrome Audit Complete

Date: 2026-09-23
Branch: `card-art-pilot-v1-20260921`

## Current conclusion

The two-call follow-up failed both cards.

### technology.robotics

Robotics has exhausted the tested baseline routes:

- Standard FLUX repeatedly invents readable code/screens even when the intended scene contains no desk or screen-bearing object.
- Klein repeatedly suppresses the screen but remains materially photoreal/macro-product-like and failed scene completeness even after a hard painterly style anchor.

**Policy conclusion: `technology.robotics` is baseline-excluded / should be quarantined.**

The GitHub connector used in this session refused writes specifically to `tools/card_art/specs/generation_guardrails_v1.json` through its safety layer. That file therefore remains mechanically unchanged in this checkpoint. Do not interpret that as a reversal of the QA conclusion: Robotics must not be included in any paid batch. A later local/Claude git-edit session should add it beside `sports.american_football` in that guard file before any scale work.

Do not run another Robotics prompt iteration.

### gaming.pc_gaming

The previous retry used `collection_object_hero / hands_build` and failed because the archetype's own "build/collectible object" prior dominated the gaming-specific override, producing an ornate gadget plus a readable code laptop.

This is diagnosed as an archetype-selection mismatch, not insufficient negative wording.

## Dedicated PC Gaming architecture now added

New archetype:

`screenless_pc_play`

New variant:

`tower_input_play`

These are now present in:
- `tools/card_art/specs/archetypes_v1.json`
- `tools/card_art/specs/archetype_variants_v1.json`

The dedicated archetype is explicitly about **active PC play**, not building, repair, office work, coding or streaming.

Recognition must come from:
- seated player;
- generic unbranded desktop tower;
- full-size keyboard;
- mouse + mouse mat;
- plain headphones;
- active hands;
- focused gaming posture/reaction.

The entire monitor/display zone is physically cropped out.

Explicitly avoid:
- monitors / TVs / laptops / tablets / phones / projectors;
- code / IDE / terminal / HUD / chat / streaming UI;
- building or repairing a gadget;
- steampunk object assembly;
- office-work posture;
- recognisable hardware branding.

## Experiment-only PC Gaming retry

Prepared:

- `tools/card_art/catalog/pc_gaming_dedicated_retry_overrides_v1.json`
- `tools/card_art/catalog/pc_gaming_dedicated_retry_v1.json`
- `tools/card_art/src/runPcGamingDedicatedRetry.js`

Normal production routing is unchanged. The dedicated route is applied only via the experiment override.

### Free audit

Run:

```bash
cd tools/card_art
node src/runPcGamingDedicatedRetry.js --dry-run
```

Expected:
- exactly 1 planned call;
- `gaming.pc_gaming`;
- Standard FLUX only;
- estimated cost $0.0125;
- compiled route `screenless_pc_play / tower_input_play`;
- no collectible-object/build semantics;
- no screen-bearing object requested;
- no raw compiler IDs/headers.

Also confirm a normal dry-run without the experiment override still uses the existing production route; the experiment must not mutate normal routing.

### Only if the dry-run audit is clean

Run:

```bash
node src/runPcGamingDedicatedRetry.js
```

Expected maximum:
- 1 API call;
- $0.0125;
- no auto-reroll.

PASS only if:
- no screen-bearing device appears;
- no readable code/UI;
- desktop tower + keyboard + mouse + headphones + seated player are present;
- unmistakably PC gaming, not office work/coding/streaming/building;
- no brand/IP leakage;
- painterly/cinematic house style is maintained.

If this dedicated archetype still invents a screen or loses PC-gaming identity, stop Standard-FLUX prompt iteration for PC Gaming and move to a different model/visual strategy.

Do not start another batch automatically.

## Rounded light card-border/chrome audit

Full evidence audit:

`AI_STATE/CARD_ART_CHROME_DEFECT_AUDIT_20260923.md`

Two confirmed independent occurrences:

1. `gaming.game_streaming`
   - Standard FLUX
   - `creator_workflow / stream_broadcast`

2. `technology.robotics`
   - Klein
   - `physical_prototype / field_robot_test`

Important negative evidence:
- a later Game Streaming Standard render was clean;
- an earlier Robotics Klein render using the same `physical_prototype / field_robot_test` route was clean.

Therefore the defect is not uniquely tied to:
- Standard or Klein;
- either hobby;
- either archetype;
- either route;
- 832×1248;
- local post-processing.

The image runner writes returned PNG bytes directly; no local resize/padding stage can explain the chrome.

Shared global wording includes "premium collectible hobby illustration" / "collectible-art universe" while also explicitly prohibiting card borders/card-face layouts. This is a plausible weak semantic trigger, but it appears on many clean renders and therefore is **not proven causal**.

Current classification:

**Recurring stochastic/upstream framing defect; trigger unresolved.**

Do not auto-crop or rewrite global style yet.

## Scope / infrastructure

- `sports.american_football` remains machine-quarantined and untouched.
- `technology.robotics` is policy-quarantined/baseline-excluded; machine guard edit is still pending because the connector refused that specific guard-file write.
- Do not include either hobby in paid generation.
- No 10/50/100 batch.
- No image API calls were made while preparing this checkpoint.
- Vercel / GitHub Actions / Production / Google Play remain closed.

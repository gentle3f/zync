# Zync — Screen Model Discriminator Ready

Date: 2026-09-23
Branch: `card-art-pilot-v1-20260921`
Parent HEAD: `210bdefc75e74df4d8b9aed5b3f06e7de0aa4457`

## Why this experiment exists

The 10-card structural screen-remediation batch failed 3/10. Seven cards ignored repeated hidden-screen instructions and rendered code/UI anyway across tech_workspace, creator_workflow and digital_play.

That result is strong enough that another broad wording pass is not justified.

The next test is intentionally only **three API calls** and is designed to distinguish:
- a Standard-FLUX model prior,
- a model-independent semantic/title prior,
- a workspace/desk-setting prior,
- and a Klein negative-prompt advantage that may or may not survive house-style QA.

No paid generation has been run while preparing this checkpoint.

## Experiment-only override mechanism

`generateCompiledBatch.js` now supports:

`--experiment-overrides=<json>`

The overlay is applied after normal hobby + flagship overrides during prompt compilation.

It may replace the archetype/variant/subject/environment/composition/camera for an experiment without altering normal catalog routing.

Normal generation without this flag is unchanged.

Manifest rows record whether an experiment override was applied.

## Experimental routes

### 1. technology.robotics — Standard FLUX

Robotics is moved to an experiment-only `physical_prototype / field_robot_test` route.

The scene is an open physical test floor:
- real generic wheeled/articulated robot;
- engineer physically adjusts sensor/joint;
- wheels/joints/sensors/cones/floor markers;
- optional simple **screenless** physical remote controller;
- no desk or workstation.

Hard structural fact of the scene:
**zero objects with a display surface exist.**

Explicitly absent:
monitor, laptop, tablet, phone, television, desktop computer, display panel, computer desk, code, IDE, terminal, waveform, dashboard.

### 2. technology.robotics — Klein

The **exact same compiled experiment scene** is then routed through Klein's real negative_prompt.

This is the discriminator.

Interpretation:
- Standard clean + Klein clean -> setting/scene change is sufficient; prefer Standard if style is cleaner.
- Standard fails + Klein clean -> Klein negative_prompt is materially suppressing the prior; still reject Klein if MATERIAL style drift recurs.
- both fail -> title/semantic prior survives both routes; do not keep adding screen negatives.

### 3. gaming.game_streaming — Standard FLUX

Experiment-only route:
`screenless_broadcast / camera_gamepad_performance`

The creator performs directly to camera with:
- microphone
- headphones
- plain game controller
- camera/tripod
- studio light
- expressive on-camera reaction

There is:
- no desk
- no computer
- no monitor
- no television
- no laptop/tablet
- no phone display
- no gameplay screen
- no digital panel

This simultaneously tests whether removing the entire desk/computer setting defeats the streaming prior and provides a second observation for the previous light rounded card-border/chrome defect.

## Letterbox detector v2

The previous darkness-only detector was miscalibrated.

Both the standalone diagnostic and future manifest diagnostics now use **flatness**, not darkness:
- within-row luma standard deviation <= 8;
- within-row luma range <= 28;
- contiguous edge rows must stay within 15 luma units of the edge seed tone.

A band can therefore be mid-tone (like the real coworking band) and still register, while organically dark textured scene content should no longer be misclassified merely because it is dark.

Fields are now explicitly named:
- detector_version = `v2-flatness`
- top_flat_band_px
- bottom_flat_band_px
- combined_flat_band_fraction
- likely_letterbox

This remains diagnostic only. No crop, padding or image mutation is performed.

## Prepared files

- `catalog/screen_model_discriminator_overrides_v1.json`
- `catalog/screen_model_discriminator_v1.json`
- `src/runScreenModelDiscriminator.js`

## Next commands

Zero-cost first:

```bash
cd tools/card_art
npm run diagnose-letterbox-v2
npm run audit-screen-model-discriminator-v1
```

Audit must confirm:
- exactly 3 planned calls;
- same experiment override for both Robotics routes;
- Robotics compiles to physical_prototype/field_robot_test;
- Game Streaming compiles to screenless_broadcast/camera_gamepad_performance;
- no production recipe is mutated by the experiment overlay;
- Standard routes contain no Klein;
- Klein Robotics has a real API negative_prompt containing the experiment exclusions;
- no forbidden headers/raw internal IDs leak.

Only if clean:

```bash
npm run generate-screen-model-discriminator-v1
```

Estimated cost: **US$0.0364**.

No auto-rerolls.

## Visual QA / decision gate

Open all three images individually.

### Robotics Standard
FAIL if any monitor/screen/computer/code/UI appears.
PASS requires:
- physical robot unmistakable;
- hands-on testing/adjustment;
- no screen-bearing objects;
- house-style consistency.

### Robotics Klein
Same scene/content gate, plus:
- no MATERIAL photoreal/stock-photo style drift.

A screen-clean but off-style Klein output is not production-safe.

### Game Streaming Standard
PASS requires:
- no screen-bearing device at all;
- creator + camera + mic + headphones + controller + lighting clearly communicate live game-streaming;
- no code/UI;
- no light rounded card border/chrome recurrence.

Do not start 10/50/100 after this automatically.

Use the result only to choose the next smallest structural/model route.

## American Football

Still quarantined and untouched.

## Infrastructure

Keep Vercel, GitHub Actions, Production and Play closed.

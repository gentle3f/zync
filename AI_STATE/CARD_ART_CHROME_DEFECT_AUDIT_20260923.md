# Zync Card-Art — Rounded Light Border / Chrome Audit

Date: 2026-09-23

## Question

A light rounded card-border/chrome frame has now appeared twice. This audit compares the two confirmed occurrences against nearby clean renders before proposing any generation change.

## Confirmed occurrence A

- Hobby: `gaming.game_streaming`
- Batch: `screen_structural_remediation_v1`
- Model: Standard FLUX (`flux-2`)
- Archetype / variant: `creator_workflow / stream_broadcast`
- Resolution: 832×1248
- Visual result: light rounded card-border/chrome around the image
- This was the first independent observation.

Relevant clean comparison:
- Same hobby: `gaming.game_streaming`
- Later batch: `screen_model_discriminator_v1`
- Same model: Standard FLUX
- Same resolution: 832×1248
- Different structural route: `screenless_broadcast / camera_gamepad_performance`
- Border/chrome did **not** recur.

Therefore the defect is not guaranteed by:
- hobby identity;
- Standard FLUX alone;
- 832×1248 alone.

## Confirmed occurrence B

- Hobby: `technology.robotics`
- Batch: `screen_followup_2_v1`
- Model: Klein (`flux-2/klein/9b/base`)
- Archetype / variant: `physical_prototype / field_robot_test`
- Resolution: 832×1248
- Visual result: thin light rounded border/chrome, with flat near-white edge pixels
- v2 flatness diagnostic also detected the edge structure.
- This was the second independent observation.

Relevant clean comparison:
- Same hobby: `technology.robotics`
- Earlier batch: `screen_model_discriminator_v1`
- Same model: Klein
- Same resolution: 832×1248
- Same archetype / variant: `physical_prototype / field_robot_test`
- Border/chrome did **not** occur.

Therefore the defect is not guaranteed by:
- Robotics;
- Klein alone;
- `physical_prototype / field_robot_test`;
- 832×1248;
- even the same hobby + model + structural route.

## Shared facts across both occurrences

The two defects:
- use different models (Standard vs Klein);
- use different hobbies;
- use different archetypes;
- come from different prompt branches;
- are both returned as final 832×1248 PNG pixels;
- pass through the same direct-byte downloader path, which performs no crop, resize, canvas, fit, extend, border or padding step.

This strongly argues against a local post-processing bug.

## Shared prompt-level language

Both inherit the global art direction that includes phrases such as:
- "premium collectible hobby illustration";
- "miniature lifestyle hero illustration inside one coherent collectible-art universe";

The same global policy simultaneously says:
- not a card face;
- no card border;
- no card-face/editorial-page layout.

This creates one plausible weak hypothesis: collectible/card-adjacent semantic language may occasionally activate an unwanted framed-card prior even while the negative instructions explicitly prohibit it.

However, **this is not sufficient evidence of causation** because the same global language is present on a large number of clean renders.

The Robotics second occurrence also added stronger "illustrated collectible-art language" wording, but the first Game Streaming occurrence did not contain that experiment-specific addition, so that extra phrase cannot be the common trigger.

## Current classification

**Recurring stochastic/upstream framing defect, trigger unresolved.**

Evidence currently rules out:
- one specific model;
- one hobby;
- one archetype;
- one variant;
- one output dimension;
- local downloader padding.

A global collectible/card semantic prior remains a hypothesis only.

## What NOT to change yet

Do not:
- crop automatically;
- add local border removal;
- rewrite the global style prompt project-wide;
- route all affected hobbies to another model;
- treat every v2 flat-edge flag as chrome.

The v2 detector is a useful flagger but plain walls/gradients can also create flat edge regions. Visual/contextual review remains required.

## Smallest future falsification test

Only if the chrome defect appears again often enough to justify spending a call:
- take one known chrome-prone scene;
- hold hobby, route, model, seed-equivalent conditions where possible, size and composition constant;
- neutralize only the global "collectible/card" semantic wording while preserving painterly/cinematic style;
- compare against the normal global wording.

Until then, there is not enough evidence to change the global prompt.

## Conclusion

The rounded light border/chrome is now a **real recurring defect** (2 independent observations), but it is still sparse and stochastic. No production-wide fix is justified yet.


## 100-card validation update

The later `bulk_first_100_validation_v1` run materially changes the prior frequency estimate.

At least **5 additional confirmed border/chrome occurrences appeared in 100 Standard-FLUX renders (~5%)**:
- `wellness.pilates`
- `business.founder_meetups`
- `business.coworking`
- `entertainment.screenwriting`
- `outdoors.rock_climbing`

This means the earlier characterization of the defect as sparse/background noise is superseded.

### Updated classification

**Live moderate-frequency stochastic/upstream framing risk; trigger unresolved.**

It still does not map cleanly to one model, hobby, archetype, or route. However, ~5% observed frequency in a broad sample is high enough that future bulk QA must explicitly score it.

The semantic-architecture rebuild therefore also removes positive `collectible` / `card-art universe` framing language from the global positive prompt and replaces it with explicit `full-bleed edge-to-edge` scene language. This is a falsifiable systemic intervention, not proof that the old wording caused the defect.

Do not auto-crop. Visual QA remains required because flat edge regions can still be legitimate scene content.

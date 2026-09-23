# Zync — Two-Call Screen Follow-up Ready

Date: 2026-09-23
Branch: `card-art-pilot-v1-20260921`

## Purpose

The previous 3-call discriminator established:

- `technology.robotics` on Standard FLUX still invents a readable code monitor even in a desk-free, screen-free physical test scene.
- The identical Robotics scene on Klein is genuinely screen-free, but drifts materially into photoreal / macro-product-photography style.
- `gaming.game_streaming` passed cleanly using a screenless physical-recognition strategy.

The smallest useful continuation is exactly two calls.

No paid image generation was run while preparing this checkpoint.

## Call 1 — Robotics Klein style-anchor retest

Model:
`fal-ai/flux-2/klein/9b/base`

The experiment keeps the same `physical_prototype / field_robot_test` semantics used in the previous discriminator.

The only intended new variable is a stronger style anchor.

Positive style requirements include:
- premium painterly cinematic illustration;
- crafted brush-like texture;
- controlled stylization;
- rich atmospheric colour;
- illustrated collectible-art language.

Klein negative constraints add:
- photograph
- photorealistic rendering
- macro product photography
- stock photo
- DSLR photo
- product photography
- hyperreal commercial photo

Content requirements remain:
- unmistakable physical robot;
- hands-on joint/sensor adjustment;
- open test floor;
- no display-bearing objects;
- no code/UI.

### Robotics gate

PASS only if BOTH:
1. screen/code suppression remains clean;
2. the output returns to the painterly/cinematic house style.

If it is still materially photoreal, stop further prompt tweaking and quarantine `technology.robotics` from baseline production until another model or visual strategy is selected.

## Call 2 — PC Gaming screenless transfer test

Model:
`fal-ai/flux-2`

This is not routed through the broadcast archetype, because that would risk turning PC Gaming into Game Streaming.

Experiment-only route:
`collection_object_hero / hands_build`

The hobby is carried by:
- generic unbranded desktop tower;
- full-size keyboard;
- mouse and mouse mat;
- plain headphones;
- active hands;
- seated gaming posture;
- focused player reaction.

The monitor zone is physically outside the composition.

Explicitly absent:
- monitor
- TV
- laptop
- tablet
- phone
- projector
- display panel
- gameplay screen
- code / IDE / terminal / HUD / chat

### PC Gaming gate

PASS only if:
1. no screen-bearing device is visible;
2. the image still unmistakably reads as PC gaming, not office work, coding, or streaming;
3. no code/UI appears;
4. no brand/IP leakage;
5. house style remains consistent.

If screen-free but ambiguous, do not restore a monitor. Treat it as an insufficient physical-recognition problem.

## Experiment-only status

Both cards use:
`catalog/screen_followup_2_overrides_v1.json`

Normal production routing is unchanged when that file is not passed via `--experiment-overrides`.

## Prepared files

- `tools/card_art/catalog/screen_followup_2_overrides_v1.json`
- `tools/card_art/catalog/screen_followup_2_v1.json`
- `tools/card_art/src/runScreenFollowup2.js`

Because the connector safety layer rejected the non-essential package.json alias update, invoke the runner directly.

## Next step

Free audit first:

```bash
cd tools/card_art
node src/runScreenFollowup2.js --dry-run
```

Audit must confirm:
- exactly 2 planned calls;
- Robotics = Klein only;
- PC Gaming = Standard only;
- Robotics preserves the same physical field-test scene;
- Klein real negative_prompt receives the photographic-style exclusions;
- PC Gaming compiles to `collection_object_hero / hands_build`;
- production routing remains unchanged without the experiment flag;
- no forbidden compiler headers/raw IDs leak.

Only if clean:

```bash
node src/runScreenFollowup2.js
```

Estimated total cost: **US$0.0239**.

No auto-rerolls.

## Scope guard

Do not start 10/50/100 automatically.

Do not touch:
- `sports.american_football` — still quarantined;
- unresolved vlogging / generative_ai / machine_learning / javascript routes.

Inspect and interpret these two renders first.

## Infrastructure

Keep Vercel, GitHub Actions, Production and Play closed.

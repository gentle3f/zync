# Zync — Dedicated PC Gaming Retry: Results + Robotics Quarantine Landed

Date: 2026-09-23
Branch: `card-art-pilot-v1-20260921`
Parent HEAD: `8b49f56f06a5d03afd7ec8c55a59fa4299681d08`

Read `AI_STATE/OPERATING_RULES.md` before any write or external action.

## Bottom line

**`technology.robotics`'s machine quarantine is now landed** in
`specs/generation_guardrails_v1.json` (the prior session's connector
refused this specific write; it is fixed in this session). **The dedicated
PC Gaming retry (`screenless_pc_play / tower_input_play`) FAILED** — a
dark/inactive monitor is still visible in the frame despite an archetype
built specifically to crop the entire monitor zone out of composition.
This is a materially better result than the two prior PC Gaming attempts:
recognizability is excellent, no readable code/UI leaked, no card-border
recurred, and house style held — but the strict "no monitor or
screen-bearing device" bar is zero-tolerance, and a monitor is present.
Per instruction, no further prompt iteration was run automatically. No
broader batch started.

## Housekeeping — Robotics quarantine landed

`tools/card_art/specs/generation_guardrails_v1.json` now includes:

```json
"technology.robotics": {
  "status": "quarantined",
  "reason": "No currently production-safe first-pass route tested: Standard FLUX repeatedly invents a readable code/screen even in a scene that structurally excludes every screen-bearing object. Klein suppresses the screen but drifts materially photoreal/macro-product-like even after an explicit hard painterly style anchor, and separately failed scene completeness (missing open test floor/cones). Isolated diagnostic only until a different model or visual strategy passes.",
  "allow_only_with_explicit_override": true
}
```

Verified the guard is correctly wired: `guardrails.quarantined['technology.robotics']`
resolves and matches the exact schema already proven for
`sports.american_football`. The guard only fires on real (non-dry-run)
generation calls (existing, correct behavior — same as the football guard),
so this was confirmed by direct code inspection rather than a live refusal
test, to avoid spending an unnecessary call. No Robotics generation was
run this task.

## Step — dedicated PC Gaming audit

```bash
cd tools/card_art
node src/runPcGamingDedicatedRetry.js --dry-run
```

Clean. Confirmed directly in the compiled prompt text:

- Exactly 1 planned call, $0.0125 estimated — matches.
- Route compiles to `screenless_pc_play / tower_input_play`.
- No inherited collectible/build/repair semantics: the prompt explicitly
  forbids "building or repairing a gadget, object assembly, steampunk
  device" — directly targeting the failure mode from the previous
  `collection_object_hero/hands_build` attempt.
- Recognition explicitly anchored on seated player + desktop tower +
  keyboard + mouse + headphones + reaction; camera treatment explicitly
  states "cropping the entire forward display zone outside the image."
- Zero screen-bearing objects requested; full negative list covers
  monitor/TV/laptop/tablet/phone/projector/display panel/game screen/
  HUD/code/IDE/terminal/waveform/chat/streaming interface.
- No brand/logo/manufacturer-badge language requested.
- **Production routing unaffected:** direct dry-run invocation without
  `--experiment-overrides` confirmed `gaming.pc_gaming` still routes to
  `digital_play / desktop_focus`.
- No forbidden headers, no raw ID leaks, no rights-blocked canonical.

## Generation

```bash
node src/runPcGamingDedicatedRetry.js
```

1/1 API call succeeded, no failures, no auto-reroll. **Actual cost:
$0.0125** — matches. Manifest confirms `experiment_override_applied: true`.

Manifest: `tools/card_art/output/pc_gaming_dedicated_retry_v1/manifest.json`
Image: `tools/card_art/output/pc_gaming_dedicated_retry_v1/images/gaming__pc_gaming__flux_2__attempt1.png`

The image was individually opened and visually inspected.

## Verdict

**FAIL.** Scored against the strict gate:

| Criterion | Result |
|---|---|
| Unmistakably PC gaming | **Yes** — strong: intense seated player, gaming chair, RGB keyboard, gaming headset with boom mic |
| No monitor or screen-bearing device | **FAIL** — a monitor is clearly visible, upper-left of frame |
| No readable code/UI | Pass — the monitor's screen face is dark/blank, no content rendered |
| Desktop tower + keyboard + mouse + headphones + player present | Pass — all present and correctly generic/unbranded |
| Not office work / coding / streaming / building / steampunk gadget | Pass — clearly reads as gaming, none of the prior failure modes recurred |
| No brand/IP leakage | Pass |
| Painterly/cinematic house style intact | Pass — no photoreal drift |
| No card-border/chrome defect | Pass — full bleed, clean |

Letterbox: v2 flagged a bottom band (228px, 18.27%). Direct pixel sampling
shows real variance (range 3–31 luma units across sampled rows) consistent
with organic dark scene content (chair base/floor in shadow), not a flat
pad. **Resolved as not a defect** — consistent with the established
pattern that dark, detailed content can trigger the flatness heuristic at
very low luma even with real local variance present. No new evidence for
the chrome-defect audit; its existing conclusion (recurring
stochastic/upstream framing defect, trigger unresolved, 2 confirmed
observations) is left unchanged, per instruction, since this render
contains no border/chrome at all.

## Analysis: this is a materially better failure than the prior two

This is the third consecutive Standard-FLUX PC Gaming attempt, and each
has failed differently:

1. Original production route (`digital_play/desktop_focus`, from the
   10-card screen-remediation batch): severe "screen soup" — dual monitor,
   readable code, waveform panel, game-HUD-like content.
2. `collection_object_hero/hands_build` retry: lost recognizability
   entirely (ornate steampunk gadget instead of a gaming scene) **and**
   leaked a readable-code laptop screen.
3. This dedicated `screenless_pc_play/tower_input_play` retry: excellent
   recognizability, zero readable content, zero brand leakage, house style
   intact — but a single dark/inactive monitor object is still physically
   present in frame despite an explicit "crop before any monitor area"
   camera instruction.

The trend across three attempts is a clear, steady narrowing of the
failure: from severe content/semantic leakage down to a single non-semantic
physical object placement. This suggests the model's "PC gaming = desk
with a monitor" prior is real but is now the *only* remaining obstacle,
distinct from a broader "screen content" semantic prior. This is not the
same class of evidence as `technology.robotics`, where three different
scene strategies across two models all failed to suppress either the
screen object or its content, or both.

## Should Standard FLUX be abandoned for PC Gaming?

**Not yet — the evidence does not support full abandonment**, but per
instruction, no further prompt iteration was run automatically this task.
Two ways forward, presented as options rather than actions:

1. **One further isolated, narrowly-targeted retest** (not a prompt
   rewrite, a single small addition): explicitly state the desk surface
   itself has no monitor stand/screen of any kind present, rather than
   only instructing the camera to crop before the monitor zone — i.e.,
   remove the monitor from the *object inventory* of the scene rather than
   relying on camera framing to exclude it. Single call, ~$0.0125, before
   any broader claim either way.
2. **Quarantine `gaming.pc_gaming`** the same way as
   `technology.robotics`, on the grounds that 3 consecutive Standard
   attempts have not cleared the bar, if a fourth attempt is not wanted.

Given how close this attempt came (only a dark, non-semantic monitor
object remains as the blocker, with every content/semantic criterion
passing), option 1 is the more evidence-proportionate recommendation, but
this is a judgment call for the next task to make explicitly, not one
executed automatically here.

## What this means for Game Streaming and PC Gaming as a family

The physical-cue strategy's confirmed successes are: `gaming.game_streaming`
(clean pass), and now PC Gaming's content/recognizability dimension (though
not yet the full screen-object-absence bar). This is meaningfully more
supportive of the strategy's viability for the gaming family than the
prior round suggested, even though PC Gaming has not yet fully cleared
the gate.

## Infrastructure

Vercel, GitHub Actions, Production, and Google Play remain closed for this
branch. No `FAL_KEY` was exposed or committed. No auto-reroll was
performed. `--allow-quarantined=technology.robotics` and
`--allow-quarantined=sports.american_football` were not used.
`sports.american_football` remains quarantined and untouched. This
commit/push includes one code change (the guardrails quarantine entry,
explicitly requested by this task) plus the generated output and handoff
docs — no other code was modified.

# Zync — Screen Model Discriminator: Results

Date: 2026-09-23
Branch: `card-art-pilot-v1-20260921`
Parent HEAD: `6f319909eacffaf3df5feb08a5a5f2301ccafe71`

Read `AI_STATE/OPERATING_RULES.md` before any write or external action.

## Bottom line

**The screen/code prior for `technology.robotics` survives even the most
extreme possible countermeasure: a scene description that structurally
excludes every screen-bearing object by name, repeated three times.**
Standard FLUX still invented a readable code monitor. Klein suppressed it
completely but at the cost of severe photoreal style drift, so neither
route is currently production-safe for Robotics. Separately,
`gaming.game_streaming`'s screenless broadcast-performance scene is a
genuine win: fully screen-free, recognizable, and free of the prior
card-border defect. This 3-call result is treated strictly as a
discriminator, not generalized to any other tech/gaming card. No 10/50/100
batch started. American Football remains quarantined and untouched.

## Step 1 — letterbox detector v2

```bash
npm run diagnose-letterbox-v2
```

Zero API calls, as required. Raw v2 output on the four historical images:

| File | top px | bottom px | fraction | v2 says letterbox? |
|---|---|---|---|---|
| confirmatory_30 coworking | 171 | 266 | 0.3502 | true |
| post-repair coworking | 303 | 303 | 0.4856 | true |
| confirmatory_30 mock_trial | 283 | 357 | 0.5128 | true |
| post-repair mock_trial | 0 | 14 | 0.0112 | false |

This appears to disagree with the task's stated ground truth on one file
(`confirmatory_30` coworking, stated as "clean"). Rather than accept either
source at face value, that file was re-opened and visually inspected
directly: **it genuinely has flat white/light margins top and bottom**,
clearly visible, roughly matching v2's proportions. The "clean" label for
this file appears to reflect the old assumption that only *dark* bars
count as letterbox — v2 is actually correct here, not miscalibrated.
Corrected assessment: **v2 matches direct visual evidence on all 4
historical images, including the one apparent disagreement.** This is a
substantial improvement over v1, which had a confirmed false negative on
post-repair coworking and a false positive on post-repair mock_trial in
the prior round.

## Step 2 — audit of the 3-call experiment

```bash
npm run audit-screen-model-discriminator-v1
```

Clean. Confirmed directly in the compiled prompt text and catalog files,
not just the pass/fail summary:

- Exactly 3 planned calls: 2 Standard FLUX + 1 Klein, $0.0364 estimated —
  matches.
- Both `technology.robotics` routes (Standard and Klein) compile to
  **byte-identical** `physical_prototype / field_robot_test` scene text —
  verified by direct comparison of the dry-run output; the only difference
  between the two routes is the model endpoint.
- `gaming.game_streaming` compiles to `screenless_broadcast /
  camera_gamepad_performance`, explicitly excluding "card border, rounded
  card frame" in its negative list — the specific second-observation check
  for the prior one-off defect.
- **Production routing unaffected:** running the normal production dry-run
  for `technology.robotics` (no `--experiment-overrides` flag) still routes
  to `tech_workspace / creator_interface`, confirmed by direct invocation.
  The experiment overlay does not mutate catalog defaults.
- Klein's `negative_constraints` (which feed its real API `negative_prompt`)
  are the same "Do not depict..." block already verified identical between
  the Standard and Klein robotics prompts, explicitly containing monitor/
  laptop/tablet/code/IDE/terminal/dashboard/waveform exclusions.
- No forbidden headers, no raw ID leaks (would have thrown and halted the
  audit), no rights-blocked canonical, no reference-image conditioning.

## Step 3 — generation

```bash
npm run generate-screen-model-discriminator-v1
```

3/3 API calls succeeded, no failures, no auto-rerolls. **Actual cost:
$0.0364** — matches estimate exactly. Manifest confirms all 3 entries have
`experiment_override_applied: true`.

Manifest: `tools/card_art/output/screen_model_discriminator_v1/manifest.json`
Images: `tools/card_art/output/screen_model_discriminator_v1/images/`

All 3 images were individually opened and visually inspected. Diagnostics
were cross-checked against direct pixel sampling before being trusted.

## Per-image verdicts

| ID | Model | Verdict | Q | Robot/subject unmistakable? | Screen present? | Readable code/UI? | Style | Letterbox v2 |
|---|---|---|---|---|---|---|---|---|
| technology.robotics | Standard FLUX | **FAIL** | 3 | Yes — wheeled robot, wires, hands-on adjustment, cones, tools all correct | **Yes** — background monitor | **Yes** — clearly readable syntax-highlighted code | Painterly/cinematic, consistent | 0/0, false — no band |
| technology.robotics | Klein | Screen-clean, **not production-safe** | 3 (style) | Yes — robot, hands-on tool adjustment, cones blurred in background | No | No | **Severe MATERIAL photoreal/macro-product-photography drift** — off house-style | 0/0, false — no band |
| gaming.game_streaming | Standard FLUX | **PASS** | 5 | Yes — creator, controller, camera, mic, headphones, studio light all clear | No (camera's own tiny LCD only, non-textual, compliant) | No | Painterly/cinematic, consistent | Flagged (178/103px) but resolved as the recipe's own requested plain-backdrop content, not a defect — see below |

### Letterbox re-check on `game_streaming`

v2 flagged large top/bottom flat bands. Direct pixel sampling at the
flagged rows shows a smooth, low-variance gradient (luma range 12–24
units, rising smoothly from ~44.7 to ~47.8, no abrupt seam) — consistent
with a photographed studio wall under falloff lighting, not an inserted
pad. Critically, the compiled prompt **explicitly requested** "a plain
wall or acoustic background behind" as the intended setting. This is the
recipe's own requested content, correctly flagged as flat by v2, but not a
generation defect. This is an inherent interpretive limit of any
pixel-only detector — it cannot distinguish "intentionally flat
background" from "unwanted padding" without prompt context — and is
exactly why visual/contextual judgment is retained as the final check
rather than automating on the diagnostic alone.

## Root-cause conclusion

1. **Did removing the entire workspace/screen object set suppress the
   Robotics prior?** No, not on Standard. The scene description excluded
   every conceivable screen-bearing object by name, three times, in a
   setting with no desk or workstation at all — and Standard FLUX still
   rendered a monitor with readable code. This is the strongest evidence
   yet that `technology.robotics`' screen/code association is a deep
   semantic prior independent of composition text, not a workspace-setting
   artifact.
2. **Did Klein outperform Standard on the exact same scene?** Yes, on
   screen-content specifically. Klein produced a genuinely screen-free
   image where Standard did not, using an identical prompt.
3. **If Klein suppressed screens, was house style still acceptable?** No.
   Klein's output is strongly photoreal/macro-product-photography,
   inconsistent with the painterly-cinematic style used everywhere else in
   the collection. Per the strict gate, a screen-clean but off-style image
   is not production-safe.
4. **Did the screenless Game Streaming scene remain recognizable?** Yes —
   clearly reads as live-streaming/broadcast performance through camera +
   microphone + headphones + controller + lighting + expressive reaction,
   with no screen content needed for recognition.
5. **Did the rounded card-border recur?** No. This render is full-bleed
   with no border/chrome. The prior observation remains an isolated
   one-off (1 of 2 total observations), not yet promoted to a confirmed
   recurring pattern.
6. **Did letterbox detector v2 match visual ground truth better than v1?**
   Yes, substantially. v2 correctly flags both genuine historical bands and
   correctly clears the genuinely clean file, and its apparent
   "disagreement" on `confirmatory_30` coworking turned out to be v2 being
   right and the old assumption being wrong. In this batch it produced
   zero false positives on the two robotics renders and one flagged case
   on game_streaming that visual/prompt-context inspection resolved as
   legitimate recipe content, not a defect.

## What this means for Robotics

Neither model route is currently production-safe for `technology.robotics`:
- Standard fails on content (screen still present despite the most
  aggressive constraint tried).
- Klein passes on content but fails on style.

This is not quite the "both fail" bucket from the decision tree (Klein did
suppress the screen), but it resolves to the same practical outcome: no
production-safe route exists yet. Per instruction, this is **not**
generalized to any other tech hobby from 3 calls, and `technology.robotics`
is not moved into any broader batch until a production-safe route is
identified.

## What this means for Game Streaming

The screenless broadcast-performance direction works: screen-free,
recognizable, no card-border recurrence. This becomes a viable candidate
structural direction for streaming-adjacent hobbies, but per instruction
this is not yet generalized past this single card.

## Smallest recommended next steps (not executed this task)

1. **Robotics, isolated retest (not a broad batch):** try Klein again on
   the same field-test scene with an explicit style-anchoring addition
   ("painterly illustration, not a photograph, not macro product
   photography") to see if the photoreal drift can be corrected while
   keeping the screen-free win. Single call, ~$0.011.
2. Do not include `technology.robotics` in any batch (targeted or broad)
   until one route passes both content and style gates.
3. **Game Streaming:** test the same screenless_broadcast structural
   approach on one other card that failed the prior 10-card batch for the
   same reason — `gaming.pc_gaming` is the strongest candidate, since it
   showed the most severe screen leakage ("screen soup"). Single isolated
   call before any broader rollout.
4. Continue treating `arts.vlogging`, `technology.generative_ai`,
   `technology.machine_learning`, `technology.javascript` as unresolved —
   none were retested this task.
5. `sports.american_football` remains quarantined; no isolated diagnostic
   was run this task, consistent with instruction.

## Infrastructure

Vercel, GitHub Actions, Production, and Google Play remain closed for this
branch. No `FAL_KEY` was exposed or committed. No auto-reroll was
performed. `--allow-quarantined=sports.american_football` was not used.
This commit/push is a plain repo write with no CI/deployment side effects.

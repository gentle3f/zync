# Zync — Screen Structural Remediation + Letterbox Diagnostics Ready

Date: 2026-09-23
Branch: `card-art-pilot-v1-20260921`
Parent HEAD: `c3f84e6c24ed7e88704137f47e8334794aac049c`

## Bottom line

The latest 8-card repair gate established three independent blockers:
1. screen/UI leakage is a cross-hobby structural pattern;
2. coworking dark top/bottom bands recur and cannot be dismissed as a one-off;
3. American Football has no currently production-safe route.

This checkpoint addresses the first two structurally and quarantines the third. **No paid image API was called while preparing this work.**

## Screen/UI structural remediation

A new compiled `global_screen_policy` treats every digital display as a physical prop rather than a semantic canvas.

The structural default is now:
- prefer no visible screen face;
- recognition comes from humans + physical tools/devices/actions;
- if a display is unavoidable, show only back/edge/steep oblique/dark/blank/heavily-defocused surface;
- no front-facing UI, editing timeline, waveform, code, terminal, menu, dashboard, chat, labels, icons, or text-like interface structure.

The following archetypes were rewritten to agree with this policy rather than contradict it:
- `tech_workspace`
- `creator_workflow`
- `digital_play`

Relevant screen-heavy variants were rewritten physical-first:
- all three `tech_workspace` variants;
- creator_workspace, camera_creation, editing_workstation, drawing_animation, writing_desk, stream_broadcast;
- digital_play over_shoulder_input, shared_couch_play, desktop_focus.

Specific routes:
- `arts.vlogging` now forbids any background monitor/TV/laptop display and requires the recording device from the side/rear with its display face hidden;
- `career.digital_marketing` no longer asks for a digital preview screen and uses physical mockups/image cards/layout blocks only.

This is a structural composition change, not merely more negative wording.

## Letterbox diagnosis

Static code inspection establishes that `generateCompiledBatch.js`:
1. requests 832x1248;
2. downloads the returned image bytes;
3. writes those exact bytes directly to disk.

There is no post-response resize, canvas, crop, fit, extend, or padding stage. Therefore the local downloader cannot create the black bands after receipt; they must already exist in the returned pixels (model/API/upstream output) unless future evidence contradicts this.

New zero-cost script:
`npm run diagnose-letterbox-v1`

By default it examines the two historical coworking renders and two mock_trial renders and reports actual dimensions plus contiguous dark top/bottom bands.

The generator now also records `image_diagnostics` for every newly downloaded render:
- format
- width/height
- top dark-band px
- bottom dark-band px
- combined dark-band fraction
- likely_letterbox

This is read-only analysis; generated image bytes are not altered.

## American Football quarantine

New `specs/generation_guardrails_v1.json` marks `sports.american_football` as quarantined.

Normal paid generation refuses it. A future isolated diagnostic must explicitly opt in with:
`--allow-quarantined=sports.american_football`

Reason:
- Standard leaked a real swoosh;
- Klein later dropped the required helmet and drifted photoreal.

Do not put this ID into a normal scale batch until an isolated route passes.

## 10-card screen structural validation

Prepared:
- `catalog/screen_structural_remediation_v1.json`
- `src/runScreenStructuralRemediation.js`

Cards:
- technology.robotics
- technology.electronics
- technology.generative_ai
- technology.machine_learning
- technology.javascript
- arts.vlogging
- arts.video_editing
- gaming.pc_gaming
- gaming.game_streaming
- career.digital_marketing

All use Standard FLUX.

Estimated first-pass cost: **US$0.125**.
No auto-rerolls.

### Next commands

Zero-cost first:

```bash
cd tools/card_art
npm run diagnose-letterbox-v1
npm run audit-screen-structural-remediation-v1
```

Only if the audit is clean:

```bash
npm run generate-screen-structural-remediation-v1
```

## Decision gate

Do not start 50/100 automatically.

Screen remediation passes only if:
- at least 9/10 are PASS or MINOR;
- no repeated readable UI/text leakage occurs across more than one archetype;
- the five tech_workspace cards have no readable code/UI FAIL;
- creator/gaming/digital-marketing cases preserve recognizability without visible interface semantics.

Use the historical letterbox diagnostic plus new manifest image_diagnostics to characterize dark bands. Do not add downloader resizing/padding fixes unless the diagnostics show evidence that contradicts the current direct-byte write path.

American Football remains quarantined and is not part of this batch.

## Infrastructure

Vercel, GitHub Actions, Production and Play remain closed.
No paid generation was performed while preparing this checkpoint.

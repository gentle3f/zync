# Zync — Screen Structural Remediation: Results

Date: 2026-09-23
Branch: `card-art-pilot-v1-20260921`
Parent HEAD: `c84fae30a771010a8123d8bdb7c6a9b2216143dd`

Read `AI_STATE/OPERATING_RULES.md` before any write or external action.

## Bottom line

**The screen structural remediation did not work. Gate failed decisively:
3/10 PASS-or-MINOR against a required 9/10.** The rewritten archetypes
explicitly instructed "no front-facing screen" in the global policy, the
composition section, and the exclusion list of every affected prompt — yet
6 of 10 cards still rendered a readable code editor, waveform panel, or
game-HUD-like screen. This is a materially different failure mode from the
earlier `professional_world` fix: there, changing the archetype alone
solved it immediately. Here, the archetype was changed and the
instructions were explicit and repeated, and the model still overrode them
for most tech/coding/streaming-adjacent hobbies. Do not scale to 50/100.
Do not patch with more negative wording — see root-cause analysis below.

The letterbox diagnostic tool itself was also found to have a real
calibration bug this round, independently confirmed by direct pixel
sampling (see below). No code was changed to fix it — flagging only.

## Step 1 — zero-cost letterbox diagnosis

```bash
npm run diagnose-letterbox-v1
```

Zero API calls, as required. Raw tool output:

| File | W×H | top px | bottom px | fraction | tool says letterbox? |
|---|---|---|---|---|---|
| confirmatory_30 coworking | 832×1248 | 0 | 0 | 0 | false |
| post-repair coworking | 832×1248 | 0 | 0 | 0 | false |
| confirmatory_30 mock_trial | 832×1248 | 283 | 357 | 0.5128 | true |
| post-repair mock_trial | 832×1248 | 0 | 147 | 0.1178 | true |

**This directly contradicts last round's own visual inspection**, which
recorded the opposite pairing (coworking banded, mock_trial clean). Rather
than trust either source blindly, both contested files were re-opened
visually and then pixel-sampled directly:

- **Post-repair coworking**: visually confirmed dark top/bottom bands.
  Direct sampling: rows are flat and uniform (luma range 55–63, ~8-unit
  spread) but their mean luma (~60) sits *above* the tool's `≤48`
  threshold — invisible to the detector. **Real band, tool false negative.**
- **Post-repair mock_trial**: visually confirmed clean, full-bleed, no
  border. Direct sampling: bottom rows are dark (luma ~15–28) but with wide
  local variance (range 6–61) — genuine shadowed courtroom-floor detail,
  not a flat pad — yet dark enough to clear the tool's darkness-only
  threshold. **No real band, tool false positive.**

**Root cause of the tool's error:** it classifies purely on darkness
(`meanLuma ≤ 48 AND darkFraction ≥ 0.82`), with no check for flatness/
uniformity. A genuine letterbox pad is flat-color with near-zero variance;
real dark scene content (shadowed floors, dim studio lighting) is dark on
average but has real texture variance. The tool conflates the two.

**Corrected ground truth:** letterbox recurs in `post-repair coworking`
and `confirmatory_30 mock_trial` — 2 of 4 historical cases, not the pairing
the tool reports. This does not change the underlying conclusion from the
prior round (recurrence is real, not stochastic), it only corrects which
specific card is affected.

**Downloader code path:** unaffected. Static inspection already established
`generateCompiledBatch.js` performs no local resize/crop/pad; genuine bands
must originate upstream (model/API). This conclusion stands, and is further
supported below.

## Step 2 — free audit of the 10-card screen remediation

```bash
npm run audit-screen-structural-remediation-v1
```

Clean. 10/10 compiled, all Standard FLUX, zero Klein, $0.125 estimated —
matches. No forbidden headers, no raw ID leaks (both would have thrown and
halted the script). Verified directly in the compiled prompt text, not
just via the pass/fail summary line:

- `global_screen_policy` sentence present verbatim in all 10 prompts:
  screens are physical props, prefer none visible, back/edge/dark/blank/
  defocused only if unavoidable, explicit list of forbidden interface
  types (code, terminal, timeline, waveform, dashboard, menu, chat, labels,
  icons).
- All 5 tech_workspace cards: "Compose the specific scene this way"
  explicitly states "No front-facing screen," anchors recognition on
  hardware/prototype/sensor/robot/circuit/physical indicators.
- Vlogging: "No monitor is visible in the background," display face hidden.
- Video editing: recognition routed through headphones/jog-shuttle/control
  surface/stylus/physical media; monitor back-facing/edge/dark only.
- PC gaming: hands-on-controller + reaction carry the scene; monitor face
  out of frame or turned away.
- Game streaming: mic/camera/controller/headphones/rig carry it; only
  monitor back/edge visible.
- Digital marketing: "no visible monitor or digital dashboard," physical
  mockups/swatches/cards only.
- No `sports.american_football` in this batch (quarantine correctly
  excluded it from the catalog by construction).

## Step 3 — generation

```bash
npm run generate-screen-structural-remediation-v1
```

10/10 API calls succeeded, no failures, no auto-rerolls. **Actual cost:
$0.125** — matches estimate exactly.

Manifest: `tools/card_art/output/screen_structural_remediation_v1/manifest.json`
Images: `tools/card_art/output/screen_structural_remediation_v1/images/`

All 10 images were individually opened and visually inspected. Manifest
`image_diagnostics` were cross-checked against direct pixel sampling before
being trusted (see below) — not accepted at face value, per the known tool
calibration bug found in Step 1.

## Per-card verdicts

| ID | Verdict | Q | Screen visible? | Screen face visible? | Readable UI/text/code? | Defect class |
|---|---|---|---|---|---|---|
| technology.robotics | **FAIL** | 2 | Yes | Yes, front-facing | Yes — clearly readable syntax-highlighted code editor | model ignored hidden-screen composition |
| technology.electronics | MINOR | 4 | Yes (main) + handheld device | Main monitor dark/blank (compliant); handheld device shows tiny green pixel content | No readable text on main monitor; ambiguous tiny marks on handheld screen | insufficient physical recognition cue (minor) |
| technology.generative_ai | **FAIL** | 2 | Yes | Yes, front-facing | Yes — large, unmistakably readable code editor, worst readability in batch | model ignored hidden-screen composition |
| technology.machine_learning | **FAIL** | 2 | Yes (dual monitor) | Yes, both front-facing | Yes — one shows readable code, the other a waveform panel | model ignored hidden-screen composition |
| technology.javascript | **FAIL** | 3 | Yes | Yes, front-facing (slightly defocused) | Yes — readable-ish syntax-highlighted code | model ignored hidden-screen composition |
| arts.vlogging | **FAIL** | 3 | Yes (background monitor) | Yes, front-facing | Yes — readable code editor, despite this recipe explicitly forbidding "any visible monitor" by name | model ignored hidden-screen composition |
| arts.video_editing | **PASS** | 5 | Yes (one, small, background) | No — correctly back-facing/edge-on/dark | No | none |
| gaming.pc_gaming | **FAIL** | 1 | Yes (dual monitor, dominant) | Yes, both front-facing | Yes — severe: readable code + waveform + game-HUD-like panel simultaneously ("screen soup") | model ignored hidden-screen composition (severe) |
| gaming.game_streaming | **FAIL** | 2 | Yes | Yes, front-facing | Yes — readable code IDE directly in frame | model ignored hidden-screen composition; **plus separate defect:** light rounded card-border/chrome wraps entire image (isolated one-off) |
| career.digital_marketing | **PASS** | 5 | No | N/A | No | none |

**Tally: 2 PASS + 1 MINOR + 7 FAIL = 3/10 PASS-or-MINOR** (required: 9/10).

## Root-cause analysis

1. **Structural screen semantic prior — confirmed, dominant.** The
   rewritten `tech_workspace`, `creator_workflow`, and `digital_play`
   archetypes correctly encode the physical-first composition in text (this
   was verified explicitly in Step 2's audit), but the model's training
   prior for "person actively doing tech/code/gaming/streaming work" is
   apparently anchored so strongly to a visible code/IDE/HUD screen that it
   overrides explicit, repeated instructions not to render one. This is a
   stronger, more resistant prior than the `professional_world`
   workshop/jewelry case, where an archetype swap alone fixed it instantly
   on the first attempt for all four affected hobbies.
2. **Insufficient physical recognition cue:** `technology.electronics`
   (MINOR) — the physical hardware (robot arm, camera-like device,
   soldering iron) does carry recognition and the main monitor is
   genuinely compliant (dark/blank), but a secondary handheld device
   screen shows ambiguous small content that should be tightened.
3. **Model ignored hidden-screen composition:** the dominant category this
   round — 7 of 10 cards, spanning three different archetypes
   (`tech_workspace`, `creator_workflow`, `digital_play`), confirming this
   is not isolated to one archetype or one hobby family.
4. **Title/text regression:** none found. No hobby-name/caption leakage
   this round — the leaked text is code/UI content, a different failure
   class from the earlier caption problem, and the caption-suppression fix
   itself remains intact.
5. **Letterbox/model-upstream composition issue:** the tool flagged 5 of
   10 new images as `likely_letterbox: true` (robotics, generative_ai,
   machine_learning, vlogging, pc_gaming). Direct pixel sampling at the
   flagged edges shows wide luma variance (30–130+ units) in every case —
   real dark, moody scene detail (deliberate low-key lighting for these
   desk/studio scenes), not a flat uniform pad. **All 5 are false
   positives** from the same calibration bug identified in Step 1. Genuine
   confirmed letterbox recurrence across the whole project remains at 2
   cases (`confirmatory_30` mock_trial, `post-repair` coworking), both
   consistent with upstream/model-generated output, not local processing.
6. **Unrelated one-off generation defect:** `gaming.game_streaming`'s light
   rounded card-border/chrome frame. Not seen on any other card in this
   batch or in history under this exact form (rounded corners + light
   border, versus the dark full-width bands seen elsewhere) — treated as
   isolated pending a second observation.
7. **Rights/IP issue:** none found this round.

## Decision gate: **FAILED**

- Overall: 3/10 PASS-or-MINOR, far short of the required 9/10.
- Repeated readable UI/text leakage occurred across **three** archetypes
  (`tech_workspace`, `creator_workflow`, `digital_play`), not zero.
- tech_workspace subgroup: 4/5 outright FAIL on readable code (requirement
  was zero FAIL, at most one isolated MINOR — badly missed).
- Cross-hobby subgroup: 3/5 FAIL, including `arts.vlogging` — the exact
  card this remediation was specifically designed to fix — regressing to
  a different but equally disqualifying defect (code screen instead of
  editing-timeline screen).

## What this means

Per the task's explicit instruction: **do not patch this with more
negative wording.** Two rounds of negative-list expansion (vlogging's
VLOG-text fix, then this structural rewrite) have each been defeated by a
new manifestation of the same underlying prior (title text -> editing UI ->
code/IDE UI). The composition-level instruction change that worked
instantly for `professional_world` did not transfer to this prior, which
appears to need a stronger intervention:

- Consider **fully removing monitors/screens from the permitted object
  list** for these specific archetypes (zero screens allowed in the scene
  at all, rather than "prefer none, hide face if present") — a harder
  constraint than what was tried this round.
- Consider testing whether **Klein's real negative_prompt** (rather than
  Standard FLUX's prompt-only negative language) suppresses this prior
  more effectively, the same way Klein once suppressed sportswear
  branding — tested in isolation on 1–2 tech cards before any broader
  claim.
- Consider whether the underlying setting itself ("workspace/desk") is the
  trigger — an alternate setting that structurally excludes desks/monitors
  (e.g., a field-testing or outdoor-prototyping scene for robotics/
  electronics, a live-audience framing for streaming) may work the same
  way moving `coworking` away from `professional_world` did.

## Smallest recommended next steps (not executed this task)

1. **Isolated 2–3 card retest**, not another 10-card batch: pick one
   tech_workspace card (e.g. `technology.robotics`) and test a
   "zero monitors permitted in scene" hard constraint plus, separately, a
   Klein-routed version with an explicit negative_prompt targeting "code,
   syntax highlighting, IDE, terminal, waveform" — compare which
   intervention actually suppresses the prior before committing either
   approach across all 5 tech cards.
2. Recalibrate `diagnoseLetterbox.js`'s detection to use row-variance/
   flatness (not darkness alone) so it stops flagging moody-but-detailed
   dark scenes as letterbox and stops missing genuinely flat mid-tone
   bands like the coworking case. This is a diagnostic-tool fix, not a
   generation-code fix, and was not made this round since it wasn't
   blocking the audit.
3. Second-observation retest of `gaming.game_streaming` in isolation to
   confirm whether the light rounded card-border is a one-off or a new
   recurring pattern.
4. `sports.american_football` remains quarantined and untouched — no
   isolated diagnostic was run this task, consistent with instruction.

## Infrastructure

Vercel, GitHub Actions, Production, and Google Play remain closed for this
branch. No `FAL_KEY` was exposed or committed. No auto-reroll was
performed. `--allow-quarantined=sports.american_football` was not used.
This commit/push is a plain repo write with no CI/deployment side effects.

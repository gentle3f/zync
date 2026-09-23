# Zync — Post-Confirmatory Repair Gate: Results

Date: 2026-09-23
Branch: `card-art-pilot-v1-20260921`
Parent HEAD: `07952ba803cea38cff6ae4d4f8e757a8fbade2b9`

Read `AI_STATE/OPERATING_RULES.md` before any write or external action.

## Bottom line

**None of the three gate conditions fully passed.** Two of eight cards are
genuinely clean wins carried over from the repair (`archery`, `fencing`),
two more are clean (`book_clubs`, `aviation`), and `mock_trial`'s letterbox
diagnostic came back clean — but `american_football`, `coworking`'s
letterbox diagnostic, and `vlogging` each surfaced a real, distinct
problem. Do not scale to 50/100. No code changes were made — every finding
below is a content/render-quality result, not an execution blocker.

## What ran

```bash
cd tools/card_art
npm run audit-post-confirmatory-repair-v1
npm run generate-post-confirmatory-repair-v1
```

- **Audit:** clean. 8/8 compiled (7 `flux-2` standard + 1 `flux-2/klein/9b/base`),
  $0.0989 estimated. Archery/fencing carried the new shared brand-safe
  individual-sports language (identical exclusion list on both — confirmed
  this is the racket/combat/precision cluster rule, not an archery-specific
  hack). American Football retained plain-kit coverage and its
  `negative_constraints` fed Klein's real API `negative_prompt`. Mock Trial
  and Coworking prompts were verified byte-identical in structure to their
  prior successful structural-fix versions — no letterbox wording was added
  before this diagnostic, per instruction.
- **Generation:** 8/8 API calls succeeded, no failures, no auto-rerolls.
  **Actual cost: $0.0989** — matches estimate exactly.

Manifest: `tools/card_art/output/post_confirmatory_repair_v1/manifest.json`
Images: `tools/card_art/output/post_confirmatory_repair_v1/images/`

All 8 images were individually opened and visually inspected (not judged
from prompts/API success/manifest alone).

## Per-card verdicts

| ID | Verdict | Q | Defect class | Notes |
|---|---|---|---|---|
| sports.archery | **PASS** | 5 | none | Unmistakable draw/aim action, correct recurve bow, plain grey shirt, dark shorts, plain sneakers. Zero visible brand marks on clothing, footwear, or bow. |
| sports.fencing | **PASS** | 5 | none | Correct lunge form, mask, foil. Plain white jacket/breeches, plain navy shoes. No stripe or swoosh-style marks anywhere. |
| sports.american_football | **FAIL** | 2 | model-route limitation (Klein) | Required helmet is absent — athlete wears a baseball-style cap instead of the "generic unbranded helmet" the compiled prompt required as both recognition cue and must-include element. Strong photoreal/stock-photo rendering (Klein's known MATERIAL style drift). Cap and right thigh-pad carry small dark patch-like marks, ambiguous but brand-risk-adjacent. |
| learning.mock_trial | **PASS (letterbox: clean)** | 5 | none | Advocate presenting, judge visible, blank folders, no readable text. Full-bleed image, **no border recurrence**. |
| business.coworking | **PASS on scene / FAIL on letterbox** | 4 (scene) | stochastic vs. recurring — see analysis | Four professionals at communal desks, laptops/headphones/mugs/plants, one natural interaction, zero workshop/jewelry content — scene recipe itself is correct. **Thick dark letterbox bands recur top and bottom of frame.** |
| arts.vlogging | **FAIL** | 3 | systemic model semantic prior (screen/UI leakage) | No VLOG/VLOGIN text this time (that specific defect is fixed), but the background monitor renders a full video/audio-editing UI — toolbar icons, waveform timeline tracks, small text labels — exactly the "front-facing monitor full of UI" case explicitly forbidden. Same defect *family* as the long-standing `tech_workspace` screen-leakage pattern, now confirmed reaching beyond tech-labeled hobbies. |
| learning.book_clubs | **PASS** | 5 | none | Four adults, face-to-face discussion, three books all blank/plain covers, no solitary-reader framing. |
| transport.aviation | **PASS** | 5 | none | One generic twin-prop aircraft dominates the frame, three people boarding/inspecting, hangar context. No car/truck/motorcycle competes for attention. No readable tail code, registration, or airline branding (a thin blue fuselage stripe is decorative livery, not text). |

## Root-cause analysis

1. **Systemic model semantic prior:** `arts.vlogging`'s editing-UI monitor.
   This is not a one-off — it is the same failure family already tracked
   under `tech_workspace` (readable screen/code/UI leakage across five
   independent hobbies in Confirmatory-30, e.g. `technology.robotics`).
   This result confirms the pattern is not confined to hobbies with
   "technology"-flavored recipes; any recipe that places a screen in frame
   is at risk. This is now a **wider-scope structural remediation item**,
   not an isolated vlogging fix.
2. **Recipe/routing defect:** none found this round. Archery/fencing/
   book_clubs/aviation recipes all produced exactly the intended scene on
   first attempt with zero recipe-level ambiguity.
3. **Model-route limitation:** `sports.american_football` on Klein. The
   prior finding was "Klein suppresses branding, Standard leaks a swoosh."
   This round shows Klein has its own failure mode on the same card — it
   drops a required key object (helmet) and renders photoreal instead of
   painterly. Neither route is currently unconditionally safe for this
   specific card.
4. **Stochastic generation noise vs. recurring pattern — letterbox:**
   `mock_trial` clean, `coworking` recurred. Per the gate's own stated
   interpretation, **1 of 2 recurrence means this is not random** and
   must be treated as a real output/layout issue, not noise, before any
   scale-up. (Cumulative across rounds: 2/9 in Confirmatory-30, now 1/2
   in this targeted diagnostic — a consistent, low-but-nonzero recurrence
   rate concentrated on this specific card rather than spread evenly.)
5. **Rights/IP safety issue:** none newly confirmed this round. Archery
   and fencing — the two cards that drove this whole repair — are now
   clean. American Football's ambiguous patch marks are a possible but
   not confirmed rights issue; the confirmed, unambiguous defect on that
   card is the missing helmet.
6. **Isolated one-off defect:** none identified this round that doesn't
   fold into one of the above categories.

## Decision gates

### 1. Sports rights-safety gate — **NOT MET**
Required: archery PASS + fencing PASS + American Football PASS on Klein.
Result: 2/3. Archery and fencing are now production-safe. American
Football is not — on Klein this run it fails on missing required
equipment, not primarily on branding.

### 2. Letterbox diagnostic — **produced a defensible conclusion: NOT random**
1 of 2 cards recurred. Per the gate's own interpretation rule, any
recurrence rules out "stochastic noise" as the explanation. This needs
investigation of output/layout/image-size handling before any scale-up
— not more prompt wording.

### 3. Vlogging / book_clubs / aviation — **NOT MET**
book_clubs and aviation are clean PASSes. Vlogging's specific defect
(VLOG-text) is fixed, but a new defect appeared in its place that is a
confirmed instance of an already-known systemic pattern (`tech_workspace`
screen/UI leakage) — which the gate explicitly treats as disqualifying
("without revealing another systemic pattern").

## What is now considered production-safe

- `sports.archery`, `sports.fencing` — brand-safe individual-sports repair
  confirmed on the two cards that originally failed/leaked.
- `learning.book_clubs` — multi-person discussion recipe confirmed.
- `transport.aviation` — new `aviation_world/aircraft_focus` archetype
  confirmed; aircraft dominance and car-exclusion both hold.
- `learning.mock_trial` structural scene (letterbox aside) — clean on this
  and the prior round.
- `business.coworking` scene content (letterbox aside) — clean on this
  and the prior round.

## What still blocks larger-scale generation

1. `sports.american_football` has no currently-safe route: Standard leaks
   branding, Klein drops a required key object and renders off-style. This
   card needs its own targeted fix before being included in any larger
   batch — likely a Klein prompt/negative-prompt adjustment that more
   forcefully anchors the helmet as a hard-required object, tested in
   isolation.
2. The letterbox/card-chrome defect on `business.coworking` is now
   evidenced as recurring, not random. Needs investigation into
   `generateCompiledBatch.js`'s image-size/output handling or a broader
   FLUX framing issue before scale-up.
3. Screen/UI text leakage is now confirmed as a **cross-hobby structural
   pattern**, not a `tech_workspace`-only issue. This deserves a single
   dedicated remediation pass covering the general case ("any recipe that
   places a screen/monitor/display in frame"), rather than one-off fixes
   per affected hobby as they're discovered.

## Smallest recommended next steps (not executed this task)

1. Isolated reroll/diagnostic of `sports.american_football` on Klein only,
   with the negative/must-include language strengthened specifically
   around helmet presence — retest in isolation (~$0.011) before deciding
   whether Klein remains viable for this card at all.
2. Investigate `generateCompiledBatch.js` output/image-size handling
   directly (not a prompt change) to understand why `coworking` produces a
   fixed-looking dark-band frame on some runs; consider whether this
   correlates with a specific `image_size` config or aspect-ratio mismatch.
3. Scope a dedicated screen/UI-text structural remediation pass: identify
   every archetype/variant that places a screen/monitor/display in frame
   (`creator_workflow`, `tech_workspace`-adjacent recipes, others) and
   design one shared structural fix (e.g. requiring all screens be
   angled away/blank by archetype-level default) rather than patching
   negative wording hobby by hobby.

## Infrastructure

Vercel, GitHub Actions, Production, and Google Play remain closed for this
branch. No `FAL_KEY` was exposed or committed. No auto-reroll was
performed. This commit/push is a plain repo write with no CI/deployment
side effects.

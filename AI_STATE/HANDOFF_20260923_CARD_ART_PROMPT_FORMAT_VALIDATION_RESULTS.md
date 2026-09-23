# Zync — Prompt-Format Root-Cause Fix: Validation Results

Date: 2026-09-23
Branch: `card-art-pilot-v1-20260921`

Read `AI_STATE/OPERATING_RULES.md` before any write or external action.

## Execution blocker found and fixed before any spend

`npm run audit-prompt-format-v1` **failed on the first run** (exit 1):

```
Error: Prompt-format regression for hobby "wellness.sauna": title-like
compiler header leaked into model-facing text
```

Investigation showed this was a **false positive in the new regression guard
itself**, not a real leak. The guard's regex was case-insensitive and matched
the forbidden phrase *anywhere* in the compiled text, not just at a
section-header position. The new prose compiler unconditionally emits the
sentence `"The scene must include: ..."` for every hobby — which contains the
literal substring `"must include:"`, colliding with the guard's `MUST INCLUDE`
entry. This meant the guard would fail-close on **100% of hobbies**, not just
`wellness.sauna` specifically; it happened to be reported first alphabetically
within the batch's route order.

**Minimal fix applied** to `tools/card_art/src/buildPromptV1.js`: anchored the
regex to the start of a section (`^` with the `m` flag — sections are joined
by `\n\n`, so each one starts a new line) and removed the case-insensitive
flag, so it only matches the exact old ALL-CAPS `LABEL (id):` header format it
was actually meant to catch, not ordinary sentence-case prose that happens to
share a word. Verified the fix still catches a real regression (re-injecting
`VISUAL VARIANT (heat_room):` into a test string still throws) while no
longer false-positiving on the new prose. Re-ran the audit — passed cleanly,
8/8 compiled, $0.0989 estimated.

This is the only code change made in this task.

## What ran

```bash
cd tools/card_art
npm run audit-prompt-format-v1     # failed once (false positive), fixed, re-ran clean
npm run generate-prompt-format-v1
```

- **Audit (after fix):** passed — 8/8 compiled (7 standard + 1 Klein), $0.088
  + $0.011 = $0.099 (~$0.0989 estimate). Verified directly against the raw
  dry-run output:
  - Zero occurrences of `ARCHETYPE (`, `VISUAL VARIANT (`, `CATEGORY (`,
    `SUBCATEGORY (`, `GLOBAL STYLE:`, `REFERENCE STYLE:`.
  - The only occurrences of raw internal ids (`heat_room`, `immersion_ritual`,
    `wellness_experience`) were in the CLI's own `--- Title [id] / archetype /
    variant ---` debug header line printed by `runPromptFormatValidation.js`
    for human readability — never inside the actual compiled prompt text sent
    to the model. Confirmed zero occurrences once that debug line is excluded.
  - Zero occurrences of "reference" anywhere (all 8 routes are text-only;
    reference guidance is now structurally separate and was correctly never
    attached).
- **Generation:** **8/8 API calls succeeded**, no failures, no automatic
  retries. **Actual cost: $0.098** ($0.087 standard + $0.011 Klein), matching
  the $0.0989 estimate.

Manifest: `tools/card_art/output/prompt_format_v1/manifest.json`
Images: `tools/card_art/output/prompt_format_v1/images/`

## 8-row verdict table

| ID | Model | Verdict | Quality | Diagnosis |
|---|---|---|---|---|
| wellness.sauna | flux-2 | MINOR | 4.5 | Root-cause leak (HEAT ROOM / LISUAT VARIANT) is gone. Residual: a thin white photo-margin border around the image and a small illegible cursive signature scribble in the corner — a different, minor defect, not the caption-leak. |
| wellness.hot_springs | flux-2 | PASS | 5 | Fully clean. No HOT SPRINGS(TM) title, no IMMERSION_RITUAL caption, no border. Recognizable onsen scene. |
| learning.philosophy | flux-2 | PASS | 5 | Fully clean. No card frame, no PHILOSOPHY title, no gibberish body caption. Two people examining a glowing object/book — recognizable philosophical discussion. |
| learning.book_genre.booktok | flux-2/klein/9b/base | PASS | 5 | Fully clean. No photo-frame border, no garbled "BeokToyk" caption, no garbled book-cover title. Recognizable bookstore/library scene. |
| sports.gravel_cycling | flux-2 | PASS | 5 | The readable "GRAVEL" text previously printed on the frame is gone. Clean bike, no text anywhere. |
| food.yum_cha | flux-2 | FAIL | 5 (visual) | Gorgeous scene, but background lantern/banner signage still carries multiple readable/quasi-readable Chinese characters, unchanged from before the fix. |
| gaming.escape_room_design | flux-2 | MINOR | 4.5 | The previous bold readable "ESCAPE ROOM DESIGN" title on the prop is gone. A tiny, largely illegible pseudo-text mark remains on a small metal nameplate — much reduced, not eliminated. |
| sports.american_football | flux-2 | FAIL | 4 | Readable jersey number "1" and a swoosh-like logo mark on the shoulder sleeve persist, unchanged from before the fix. |

## Root-cause validation: **PASS**

All four of the strongest caption-format test cases (`wellness.sauna`,
`wellness.hot_springs`, `learning.philosophy`, `learning.book_genre.booktok`)
show **zero** internal compiler identifiers rendered as text, **zero**
`HEAT ROOM`/`IMMERSION_RITUAL`-style leaks, **zero** garbled `VISUAL VARIANT`
fragments, and **zero** poster/card titles derived from compiler metadata.
Three of the four are fully clean; `wellness.sauna` has one unrelated minor
residual (a white photo-margin border + tiny signature scribble), which is
not the defect this fix targeted and should be tracked separately.

**Raw internal IDs completely disappeared from compiled prompts:** yes,
confirmed by direct grep of the full dry-run output (excluding the CLI's own
debug header line, which was never part of the model-facing prompt).

**HEAT ROOM / IMMERSION_RITUAL / VISUAL VARIANT caption leakage disappeared:**
yes, on both of the two cards that previously exhibited it.

## Secondary standard-FLUX tests: 2 of 4 fixed

| ID | Before fix | After fix | Interpretation |
|---|---|---|---|
| sports.gravel_cycling | FAIL (readable "GRAVEL" text) | **PASS** | Fixed by the compiler-format change |
| gaming.escape_room_design | FAIL (bold "ESCAPE ROOM DESIGN" text) | **MINOR** (tiny residual mark) | Mostly fixed by the compiler-format change |
| food.yum_cha | FAIL (readable Chinese signage) | **FAIL** (unchanged) | NOT a compiler-format issue — genuine model suppression failure (thematic signage bias for market/restaurant scenes) |
| sports.american_football | FAIL (jersey number + logo) | **FAIL** (unchanged) | NOT a compiler-format issue — genuine model suppression failure (real-world sports-uniform association) |

This is a clean, interpretable split: 2 of the 4 secondary failures were
actually downstream effects of the same prompt-format defect and are now
resolved without any per-hobby override; the other 2 are independent,
genuine model-suppression issues that a `negative_prompt` (Klein) is the
appropriate tool for, not further compiler changes.

## Smallest remaining retry set (not executed this task)

- `food.yum_cha` and `sports.american_football` — route both to Klein
  negative_prompt (or add explicit hobby overrides banning "Chinese
  signage/lantern text" and "jersey numbers/sportswear logos" respectively) and
  re-test. 2 cards, ~$0.023 on Klein.
- `wellness.sauna`'s residual white-border + signature scribble is low
  priority and not text/rights-related; worth a note for a future prompt
  tweak (e.g. explicitly forbidding "photo print border" and "artist
  signature") but does not block anything.

## Can we proceed to the proposed ~100-card batch?

**Yes.** The root cause is conclusively fixed (validated on the 4 strongest
test cases), and the fix generalizes beyond just those 4 — it also resolved
2 of the 4 independently-selected secondary failures without any per-hobby
intervention. 6 of 8 cards in this validation (75%) are PASS or MINOR, and the
2 remaining failures are already understood, isolated, and addressable
through the existing Klein-routing mechanism rather than representing a new
open problem.

Recommendation for the ~100-card batch: keep standard `flux-2` as the default,
and additionally route real-world-branded-object-prone classes (sports with
team uniforms/jerseys, ethnic-signage-heavy food/market scenes) through Klein
alongside the previously-identified suppression-sensitive classes
(group_play/social captions, footwear/fashion silhouettes) from the 48-card
batch. This was not executed in this task per instructions.

## Infrastructure

Vercel deployment confirmed disabled for this branch (unchanged). No GitHub
Actions workflow triggers on push to this branch. This commit/push is a plain
repo write with no CI/deployment side effects. Play/Production remain
untouched and closed. `FAL_KEY` was not committed or exposed. Gemini and
Nano Banana Pro were not used in this task.

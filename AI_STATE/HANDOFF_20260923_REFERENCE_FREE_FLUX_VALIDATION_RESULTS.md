# Zync — Reference-Free FLUX Validation Results

Date: 2026-09-23
Branch: `card-art-pilot-v1-20260921`

Read `AI_STATE/OPERATING_RULES.md` before any write or external action.

## What ran

1. `npm run audit-reference-free-v1` — zero-credit preflight. **Passed**: 4/4
   compiled (crafts.diy, lifestyle.game_nights, fashion.streetwear,
   technology.ai), model `flux-2` (text-only), estimated cost $0.050.
   - Found and fixed a minor audit-accuracy bug on the way in: the dry-run
     printer was showing the raw compiled prompt (including the
     `REFERENCE STYLE:` section) instead of what the request actually sends.
     `generateCompiledBatch.js`'s dry-run branch now calls the same
     `promptForModel()` stripping function the real request uses. This is a
     display-only fix; the actual generation path was already correct (it
     already called `promptForModel()` before sending).
2. `npm run generate-reference-free-v1` — **4/4 API calls succeeded**, no
   request-level failures, cost $0.050 exactly as estimated (25 -> 29 manifest
   entries).
3. Manual visual QA of all 4 images against the full criteria list (Zync
   logo/chrome/rarity/number, copied reference composition, readable/gibberish
   text, storefront signage, UI/slogan/code text, collage contamination,
   hobby recognizability, artwork-vs-mockup, later-framing suitability).

Manifest: `tools/card_art/output/launch_v1/manifest.json`
Images: `tools/card_art/output/launch_v1/images/*__flux_2__attempt1.png`

## Result: 2 PASS, 1 MINOR, 1 FAIL — not a clean 4/4

| ID | Verdict | Quality | Reason |
|---|---|---|---|
| `crafts.diy` | **PASS** | 5/5 | Clean maker-portrait scene. No text, no logo, no card chrome, no rarity, no card number, no Board Games copy. DIY activity clearly recognizable. |
| `lifestyle.game_nights` | **FAIL** | 4/5 visual | Zero mockup contamination (old failure mode gone), but the model rendered a literal readable **"GAME NIGHTS"** text caption baked into the bottom of the image. Violates the explicit no-text requirement even though it is not gibberish, a logo, or a card frame. |
| `fashion.streetwear` | **MINOR** | 4/5 | No storefront signage / no "ZYNC" sign this time — that specific old failure is fixed. New, milder risk: the rendered sneakers have a wings-emblem-and-swoosh-like silhouette that reads as a specific real sneaker brand design — a logo/trademark risk carried by shape rather than text. |
| `technology.ai` | **PASS** | 5/5 | No legible text/UI/slogans/code/labels anywhere. Real fix from the old "AI BREANER TOGETROW" gibberish failure. Strong non-cliché concept (sketch transforming into rendered variations + abstract node diagram on a secondary display). Only a nitpick: sub-pixel, illegible toolbar-like marks at the extreme screen edge — not readable at any normal viewing size.

### Did reference contamination disappear?

**Yes, completely**, across all 4: no Zync wordmark, no rarity badge, no card
frame, no card number, no copied Board Games (or any other reference-card)
composition in any of the 4 images. This confirms the diagnosis from the
previous checkpoint — the full-card mockup reference image was the cause, and
removing it from the FLUX text-to-image request eliminates that specific
defect class entirely.

### Did Streetwear/AI text leakage disappear?

**Partially.** `technology.ai`'s severe gibberish on-screen text is fully
gone — this is a clean fix. `fashion.streetwear`'s storefront-sign text is
also gone, but a *different* brand-adjacent risk (a recognizable sneaker
silhouette/logo shape, not text) took its place. The override for streetwear
correctly stopped text-based leakage but did not constrain shoe *design*
specifically enough.

## Diagnosis: prompt-specific, not model-broken

Both remaining issues look like **prompt/override gaps**, not a fundamental
reference-free-FLUX reliability problem:

- `lifestyle.game_nights` has no hobby-level override at all yet (unlike
  streetwear/AI) — it only relies on the global "no text" negative, which
  flux-2 did not fully obey for this prompt. This is the same class of fix
  already proven to work for streetwear/AI: add an explicit
  `hobby_overrides_v1.json` entry for `lifestyle.game_nights` with
  `avoid_add: ["title text caption", "readable hobby-name text baked into the
  image", ...]` and an `override_prompt_additions` sentence forbidding any
  text caption.
- `fashion.streetwear`'s existing override already forbids brand text/logos
  but doesn't mention shoe *silhouette* specifically. Needs one more
  `avoid_add` line: "real sneaker brand silhouette, swoosh marks, wing/logo
  emblems, ankle stripes associated with known athletic-shoe brands; fully
  generic unbranded shoe design only."

## Recommendation (per the task's decision rule: do not auto-rerun)

Do **not** conclude reference-free FLUX is fully validated yet, and do not
escalate to Gemini or Nano Banana Pro for these two. Do not expand to a larger
batch yet either.

Smallest next step, pending review:
1. Add a `lifestyle.game_nights` override (no-caption-text) and strengthen the
   `fashion.streetwear` override (no-branded-shoe-silhouette) in
   `hobby_overrides_v1.json`.
2. Re-run only those 2 IDs on `flux-2` (text-only): ~$0.025 total.
3. If both then pass, `crafts.diy` and `technology.ai` are already confirmed
   clean — reference-free FLUX text-to-image can be adopted as the default
   cheap first-pass path, and the next step would be a larger **stratified**
   validation batch (e.g. 15-25 interests spanning more archetypes/categories),
   not the full 2,210-interest catalog at once.
4. If either still fails after the override fix, that specific archetype/
   category combination (group_play captions, or fashion/shoe rendering)
   needs a model-level test (fallback) rather than more prompt iteration.

## Round 2: targeted override retry (2026-09-23, same day)

Acted on the round-1 recommendation above. Edited
`tools/card_art/catalog/hobby_overrides_v1.json`:

- Added a new `lifestyle.game_nights` override: `avoid_add` covering title/
  caption/typography/readable-words/labels/letters-or-numbers on cards, game
  box, table, walls, posters, background; plus an `override_prompt_additions`
  sentence explicitly forbidding any caption "beneath or within the scene."
- Strengthened the existing `fashion.streetwear` override: added `avoid_add`
  entries for real sneaker-brand silhouette/trade dress, signature sole
  geometry, recognisable stripe layout, swoosh-like marks, three-stripe-like
  treatment, distinctive panel arrangement, trademark-like footwear
  silhouette; plus an `override_prompt_additions` sentence requiring a "plain,
  original shoe shape."

`npm run audit-reference-free-v1`-equivalent dry-run for only these 2 IDs
(`node src/generateCompiledBatch.js --dry-run --model=text
--only=lifestyle.game_nights,fashion.streetwear`) confirmed both compiled
prompts contained the new constraints verbatim, cost $0.025, no
`REFERENCE STYLE` section.

`node src/generateCompiledBatch.js --model=text
--retry=lifestyle.game_nights,fashion.streetwear
--only=lifestyle.game_nights,fashion.streetwear` — **2/2 API calls
succeeded**, cost $0.025 exactly as estimated (29 -> 31 manifest entries).

### Round-2 result: BOTH STILL FAIL

| ID | Verdict | Quality | Reason |
|---|---|---|---|
| `lifestyle.game_nights` (attempt 2) | **FAIL** | 4/5 visual | Board, cards, dice, and pieces are clean of text/letters/numbers — that part of the override worked. But the model again rendered a large, bold, fully readable **"GAME NIGHT"** caption across the bottom of the image, despite an explicit, detailed no-caption instruction. |
| `fashion.streetwear` (attempt 2) | **FAIL** | 3.5/5 | Storefront/background text remains clean. But both sneakers now render an unmistakable **white swoosh-like check mark** on the side — more prominent and more recognisable than the round-1 attempt, despite explicitly naming and forbidding "swoosh-like mark" in the override. |

Generated image paths:
- `tools/card_art/output/launch_v1/images/lifestyle__game_nights__flux_2__attempt2.png`
- `tools/card_art/output/launch_v1/images/fashion__streetwear__flux_2__attempt2.png`

### Revised diagnosis: this looks model-specific, not a prompt gap

The round-1 hypothesis ("prompt/override gap") is now contradicted by evidence:
both defects persisted, and the streetwear defect got *more* pronounced, after
adding highly explicit, specific negative language directly naming the exact
feature to avoid ("swoosh-like mark", "no caption beneath or within the
scene"). Two supporting observations:

1. **Cross-model comparison available in the manifest.** An earlier
   `gemini-25-flash-image/edit` attempt for `lifestyle.game_nights` (round-1
   checkpoint, reference-conditioned) did **not** add a text caption, even
   though it used the old contaminated reference image and picked up its own
   defect (storefront-adjacent lettering elsewhere in that era's Streetwear
   run). Across three separate FLUX calls for Game Nights now (`flux-2/edit`
   attempt 1, `flux-2` text attempt 1, `flux-2` text attempt 2), **all three**
   added a caption; the one Gemini attempt did not. That is consistent with a
   FLUX-family-specific prior for captioning "hobby card"-like group scenes,
   not a per-prompt fluke.
2. **`fal-ai/flux-2` and `fal-ai/flux-2/edit` have no dedicated
   `negative_prompt` parameter** (confirmed against the model's documented
   request schema: `prompt, image_urls, guidance_scale, seed,
   num_inference_steps, num_images, acceleration, enable_prompt_expansion,
   sync_mode, enable_safety_checker, output_format, image_size` — no negative-
   prompt field). Every "AVOID:"/negative-constraint list in this pipeline is
   currently embedded as ordinary text inside the single positive prompt, not
   routed through a true CFG negative-prompt channel. Naming a specific visual
   feature inside a positive-prompt "avoid" sentence is a weaker and
   sometimes counter-productive way to suppress it in diffusion models
   compared to a real negative-prompt input — which may explain why explicitly
   naming "swoosh-like mark" did not reduce, and may have increased, its
   presence.

This is a plausible **root cause**, not a proven one — it has not been tested
against a model/parameter change, only inferred from behavior. It should be
tested before further prompt-only iteration on these two IDs.

### Decision: 4-card validation is NOT closed

Per the task's decision rule, do **not** auto-reroll a third time. Final
status:

- `crafts.diy` — PASS (unchanged from round 1)
- `technology.ai` — PASS (unchanged from round 1)
- `lifestyle.game_nights` — FAIL after 2 rounds of prompt-level correction
- `fashion.streetwear` — FAIL after 2 rounds of prompt-level correction

**The 48-card stratified batch is NOT recommended yet** — that recommendation
was explicitly conditional on all 4 passing, and 2 of 4 still fail after a
targeted retry. Recommending a 48-card spend now would risk baking the same
FLUX-specific caption/silhouette bias into every group-scene and
footwear-adjacent card in that batch.

### Recommended next step (not executed — needs review before any spend)

1. Treat `lifestyle.game_nights` and `fashion.streetwear` as flagged for a
   **model-level test**, not further prompt iteration on FLUX. The smallest
   justified next action is a **reference-free equivalent test on the
   fallback model** — but note `gemini-25-flash-image/edit` is an edit-only
   endpoint in this codebase (`modelInput()` always attaches
   `image_urls: [referenceUrl]`), so using it today would re-upload
   `references/zync-card-style-reference.png` (the original 10-card mockup)
   and risk reintroducing the Zync-logo/Board-Games contamination this whole
   effort was meant to eliminate. Before escalating either ID to Gemini,
   either (a) replace `references/zync-card-style-reference.png` with a
   text/logo-free style asset (the fix already recommended in the prior
   checkpoint for catalog-scale work), or (b) confirm whether fal.ai exposes
   a genuinely reference-free Gemini text-to-image endpoint and wire it in
   alongside `flux-2`.
2. Separately, investigate whether `fal-ai/flux-2`/`flux-2/edit` support any
   real negative-conditioning mechanism (e.g. a `negative_prompt` field on a
   different endpoint variant, or a `guidance_scale` adjustment that changes
   how strongly the positive-prompt "avoid" language is honored) before
   assuming prompt text alone cannot fix this.
3. Everything else (`crafts.diy`, `technology.ai`, and the already-confirmed
   reference-contamination fix) remains valid and does not need to be redone.

## Infrastructure

Vercel deployment confirmed disabled for this branch (unchanged from prior
checkpoint). No GitHub Actions workflow triggers on push to this branch. This
commit/push is a plain repo write with no CI/deployment side effects.
Play/Production remain untouched and closed. `FAL_KEY` was not committed or
exposed.

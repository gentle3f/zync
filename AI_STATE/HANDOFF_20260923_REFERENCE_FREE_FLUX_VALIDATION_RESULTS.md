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

## Infrastructure

Vercel deployment confirmed disabled for this branch (unchanged from prior
checkpoint). No GitHub Actions workflow triggers on push to this branch. This
commit/push is a plain repo write with no CI/deployment side effects.
Play/Production remain untouched and closed. `FAL_KEY` was not committed or
exposed.

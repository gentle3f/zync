# Zync — Card Art Launch Batch: QA Results (BLOCKING finding for catalog-scale rollout)

Date: 2026-09-23
Branch: `card-art-pilot-v1-20260921`

Read `AI_STATE/OPERATING_RULES.md` before any write or external action.

## What ran

1. `npm run audit-launch-image-batch` — zero-credit preflight. **Passed**: 16/16
   canonical interests compiled, no errors, estimated FLUX cost $0.40.
2. `npm run generate-compiled-batch` — first pass, all 16 IDs from
   `catalog/launch_image_batch_v1.json`, model `flux-2/edit`. **16/16 API calls
   succeeded** (no request-level failures), cost $0.400.
3. Manual visual QA of all 16 images.
4. Diagnostic + retry: 9 flagged cards re-run on the fallback model
   (`gemini-25-flash-image/edit`) via `--retry=<id> --model=fallback
   --only=<id>`. Cost $0.039 x 9 = $0.351.

**Total spend this session: $0.751** (25 manifest entries). Manifest:
`tools/card_art/output/launch_v1/manifest.json`. Images:
`tools/card_art/output/launch_v1/images/`.

## BLOCKING finding: flux-2/edit is unsafe at scale with the current reference image

On the FLUX.2 edit first pass, **7 of 16 cards (44%) came back as near-verbatim
copies of a full Zync card mockup** — Zync wordmark, rarity badge, card frame,
card number, and garbled/gibberish/mirrored title text — instead of artwork for
their own hobby:

- `sports.badminton` (flagship) — full mockup, garbled slogan
- `crafts.diy` — wrong content entirely: reproduced the Board Games scene, not DIY
- `learning.campus_life` — reproduced Board Games scene, garbled title "CAMRD GAMES"
- `lifestyle.game_nights` — reproduced Board Games scene, mirrored garbled title
- `pets.dogs` — full mockup, garbled title "HABTACIRHOPP"
- `fashion.streetwear` — full mockup, garbled multi-line body text
- `music.k_pop` — full mockup, garbled title "LISTANT", reused the Road Trip
  card's quote text verbatim

Two more had a lighter version of the same defect (readable brand/UI text, no
full mockup):

- `travel.roadtrip` — a legible "ZYNC"-like wordmark rendered on the car's
  license plate
- `technology.ai` — the primary screen rendered a 5-panel collage of *other*
  hobbies' thumbnails (collage/multi-panel is an explicit global negative)

Root cause (diagnosed, not just suspected): `references/zync-card-style-reference.png`
is itself a full 10-card mockup grid (the original Zync reference contact sheet),
and it **includes an actual "Board Games" card** as one of its ten panels. FLUX.2
edit's `image_urls` conditioning is not respecting the "style only, not subject/
layout/text" instruction in the prompt for a meaningful fraction of requests —
it is directly reproducing that reference card's composition, chrome, and
(garbled) text. This is a real defect, not a "weak" card; several outputs are
unusable and one is a straightforward trademark/brand-safety risk (a card
displaying the literal "Zync" wordmark and invented rarity language as if it
were shipped UI).

**Diagnostic proof:** re-running the exact same compiled prompt for
`sports.badminton` on `gemini-25-flash-image/edit` (fallback model) produced a
clean, correct, artwork-only result on the first try. The prompt/recipe is not
the problem; the FLUX.2 edit + this reference image combination is.

## Fallback retry results (9 cards, Gemini 2.5 Flash Image edit)

6 of 8 remaining fixed cleanly on fallback (Badminton already confirmed clean
above, 7th):

- `sports.badminton` — clean, 5/5
- `crafts.diy` — clean, 5/5
- `learning.campus_life` — clean, ~4.5/5 (translucent blueprint panel, no
  readable text)
- `lifestyle.game_nights` — clean but has thin black letterbox bars top/bottom
  (cosmetic aspect artifact, not a text/logo leak) — acceptable, low-priority
  cleanup
- `pets.dogs` — clean, 5/5
- `music.k_pop` — clean, 5/5
- `travel.roadtrip` — clean, 5/5 (no plate text this time)

**Still failing after fallback retry (2 cards) — need another pass, do not ship
as-is:**

- `fashion.streetwear` — Gemini rendered a legible "ZYNC" storefront sign above
  the shop window plus a neon glyph. Same text-leak defect, different model.
- `technology.ai` — Gemini rendered a large glowing on-screen slogan block
  reading garbled text ("AI BREANER TOGETROW"). Worse than the FLUX collage
  defect in a different way (legible gibberish instead of collage).

## Recommendation (do not blindly rerun the whole batch)

1. **Before any catalog-scale run** (this batch was only 16 of 2,210 eligible
   interests): replace or edit `references/zync-card-style-reference.png` with
   a style reference that does not contain a full card mockup / logo / text —
   e.g. a clean single-hobby illustration crop, or the original 15-card pilot
   art with card chrome removed. The 44% first-pass contamination rate on
   FLUX.2 edit is not survivable at catalog scale even with fallback rerolls —
   it would mean ~975 contaminated cards on a 2,210-card run before any retry.
2. Smallest next step for *this* 16-card batch: one more targeted attempt for
   `fashion.streetwear` and `technology.ai` only. Try tightening their
   `hobby_overrides_v1.json` entries first (explicit "no storefront signage/
   shop name text", "no on-screen slogan text of any kind") before spending on
   `premium_model` (`nano-banana-pro/edit`, ~$0.15/image). If a same-model
   reroll after the override still fails, a Nano Banana Pro rescue for these 2
   specific cards is justified per the documented escalation policy (flagship/
   rescue) and cheap (~$0.30 total).
3. Do not mark `sports.badminton`'s FLUX output or any of the 7 contaminated
   images as usable. Use the Gemini-fallback versions recorded in the manifest
   instead (same `canonical_interest_id`, `model=gemini-25-flash-image/edit`).
4. `lifestyle.game_nights`'s letterbox bars are cosmetic and low priority; a
   crop/reroll can wait.

## Infrastructure

Vercel deployment confirmed disabled for this branch in `vercel.json`
(`git.deploymentEnabled["card-art-pilot-v1-20260921"] = false`). No GitHub
Actions workflow triggers on push to this branch (`zync-v1-ci.yml`,
`zync-card-art-proof.yml`, `zync-qa-preview-build.yml` all key on
`zync-v1-rebuild-20260917` only). This commit/push is a plain repo write with
no CI or deployment side effects. Play/Production remain untouched and closed.

# Zync — Game Nights / Streetwear Model-Level A/B: Results

Date: 2026-09-23
Branch: `card-art-pilot-v1-20260921`

Read `AI_STATE/OPERATING_RULES.md` before any write or external action.

## What ran

1. Verified `geminiText` -> `fal-ai/gemini-25-flash-image` (true text-to-image,
   no `image_urls`, `needsReference()` returns false) and `kleinNegative` ->
   `fal-ai/flux-2/klein/9b/base` (text-to-image, no reference, real API
   `negative_prompt` populated from `negativePromptFor(row)`, recorded in the
   manifest as `api_negative_prompt`). No execution bug found; no code changes
   made.
2. `npm run audit-model-ab-v1-gemini` — **passed**: 2/2 compiled, model
   `gemini-25-flash-image`, estimated cost $0.078, no `REFERENCE STYLE`
   section.
3. `npm run audit-model-ab-v1-klein` — **passed**: 2/2 compiled, model
   `flux-2/klein/9b/base`, estimated cost $0.023, no `REFERENCE STYLE`
   section.
4. `npm run generate-model-ab-v1-gemini` — **2/2 API calls succeeded**, cost
   $0.078 exactly as estimated.
5. `npm run generate-model-ab-v1-klein` — **2/2 API calls succeeded**, cost
   $0.023 exactly as estimated.
6. **Total: 4/4 API calls, $0.101 actual spend** (matches the ~$0.10
   estimate).
7. Confirmed in the manifest that both Klein entries carry a populated,
   non-empty `api_negative_prompt` field (1171 and 1264 characters,
   respectively, built from the same `negative_constraints` used elsewhere in
   the compiled prompt).
8. Manual visual QA of all 4 images.

Manifest: `tools/card_art/output/launch_v1/manifest.json`
Images:
- `tools/card_art/output/launch_v1/images/lifestyle__game_nights__gemini_25_flash_image__attempt1.png`
- `tools/card_art/output/launch_v1/images/fashion__streetwear__gemini_25_flash_image__attempt1.png`
- `tools/card_art/output/launch_v1/images/lifestyle__game_nights__flux_2_klein_9b_base__attempt1.png`
- `tools/card_art/output/launch_v1/images/fashion__streetwear__flux_2_klein_9b_base__attempt1.png`

## Verdicts

| Model | ID | Verdict | Quality | Diagnosis |
|---|---|---|---|---|
| Gemini text-to-image | `lifestyle.game_nights` | **FAIL** | 3.5/5 | The old readable "GAME NIGHT(S)" caption is gone. But Gemini rendered a large, bold, unmistakable **"ZYNC"** wordmark in the corner of the image instead — a new contamination vector, not the old one. |
| Gemini text-to-image | `fashion.streetwear` | **PASS** | 4.5/5 | Clean: no text, no storefront signage, no logos. Shoes are a generic chunky multi-color sneaker with no swoosh, no stripe pattern, no recognisable trademark silhouette. |
| Klein 9B Base + negative_prompt | `lifestyle.game_nights` | **PASS** | 4/5 | No caption, no readable text anywhere (board, box, table, walls, posters all clean). Clearly recognizable social tabletop game night. Rendering leans more photoreal/stock-photo than the painterly illustrated Zync house style used elsewhere (e.g. crafts.diy, technology.ai) — a style-consistency note, not a hard failure against this task's checklist. |
| Klein 9B Base + negative_prompt | `fashion.streetwear` | **PASS** | 4/5 | No text/logos/signage. Sneakers are plain and generic, no swoosh/stripe/panel pattern reading as a real brand. Same photoreal-leaning style note as above. |

## Root cause of the Gemini failure (not a fluke, systemic)

`tools/card_art/specs/global_style_v1.json`'s `prompt` field — the `GLOBAL
STYLE:` section included in **every single compiled prompt for every hobby,
regardless of model** — literally contains the word "Zync" twice:
"Create a premium collectible illustration for a **Zync** hobby card... inside
one coherent **Zync** collectible universe." This text was always meant purely
as descriptive framing for the model, never as something to render visually.
Gemini's image models are known for unusually strong, accurate text
rendering compared to FLUX; here that same strength became a liability — it
picked up the incidental brand-name mention and painted it as a logo/wordmark
in the finished artwork. This is not specific to `lifestyle.game_nights`; any
future Gemini text-to-image call on any hobby carries the same risk, since the
word "Zync" is present in the shared style prompt every card compiles with.

## Answers to the specific questions asked

- **Did Gemini remove the Game Nights caption?** Yes, fully — but replaced it
  with a different, equally disqualifying text-contamination defect ("ZYNC"
  wordmark).
- **Did Klein's real negative_prompt remove the Game Nights caption?** Yes,
  cleanly — no caption, no other text anywhere in the image.
- **Did Gemini remove the branded shoe problem?** Yes — clean, generic,
  unbranded sneaker silhouette.
- **Did Klein's real negative_prompt remove the branded shoe problem?** Yes —
  clean, generic, unbranded sneaker silhouette.

## Decision (per the task's decision rule)

**Only one model passes both cards cleanly: Klein 9B Base with a real
`negative_prompt`.** Gemini passes Streetwear but fails Game Nights on a new
defect. Per rule 4 of the decision logic ("If only one model passes:
recommend that model for the sensitive-card class. Do NOT rerun the failing
model."):

- **Klein 9B Base + real `negative_prompt` (`kleinNegative` alias) is the
  recommended route for suppression-sensitive cards** — i.e. cards whose
  archetype/category historically triggers unwanted text (group_play /
  social-scene captions) or brand-adjacent silhouettes (fashion/footwear-
  heavy archetypes like `urban_discovery`).
- **Do not rerun Gemini for `lifestyle.game_nights`.** Gemini is not ruled
  out entirely (it passed Streetwear cleanly), but it should not be the
  default sensitive-card route given the systemic "Zync" text-leak risk
  identified above, unless the shared `GLOBAL STYLE` prompt text is first
  rewritten to avoid naming "Zync" at all (a separate, small fix that would
  need its own validation pass before Gemini could be trusted more broadly).
- **Standard reference-free FLUX (`flux-2`, no negative_prompt) remains the
  default for ordinary cards** — `crafts.diy` and `technology.ai` are already
  confirmed PASS on it from the prior checkpoint, and this A/B did not
  re-test them (per the task's constraint not to rerun DIY or AI).

## Are we ready for the next stratified validation batch?

**Yes, conditionally.** All 4 originally-blocking cards now have a passing
generation path:

- `crafts.diy` — PASS on standard `flux-2` (prior checkpoint)
- `technology.ai` — PASS on standard `flux-2` (prior checkpoint)
- `lifestyle.game_nights` — PASS on `flux-2/klein/9b/base` + negative_prompt (this checkpoint)
- `fashion.streetwear` — PASS on `flux-2/klein/9b/base` + negative_prompt (this checkpoint)

**Recommended next batch:** proceed with the user's preferred ~48-card
stratified validation batch, but the batch's model-routing policy should not
blindly use standard `flux-2` for every card. Route any card whose
archetype/category matches the now-identified risk classes through
`kleinNegative` by default instead:

- `group_play` archetype (multi-person reaction/social scenes — proven caption
  risk on standard FLUX)
- fashion/footwear-heavy archetypes, especially `urban_discovery` with a
  `storefront_moment`-style visual variant (proven brand-silhouette risk on
  standard FLUX)

Everything else in the 48-card stratification (spanning archetypes,
categories, recipe sources, hard cases, USA/HK launch interests, and other
text-prone environments per the user's stated design) can default to standard
`flux-2` as originally planned, since only these two risk classes have actual
evidence against them so far. The batch should still be treated as a
validation pass, not a production run — new risk classes may surface once a
wider archetype/category spread is sampled.

One quality caveat to carry into that batch's QA: Klein's output in this test
leaned more photoreal/stock-photo than the painterly illustrated style
standard `flux-2` produced for `crafts.diy`/`technology.ai`. If Klein is used
for a meaningful fraction of the 48-card batch, watch for style inconsistency
across the set, not just text/logo contamination.

## Infrastructure

Vercel deployment confirmed disabled for this branch (unchanged). No GitHub
Actions workflow triggers on push to this branch. This commit/push is a plain
repo write with no CI/deployment side effects. Play/Production remain
untouched and closed. `FAL_KEY` was not committed or exposed. Nano Banana Pro
was not used in this task, as instructed.

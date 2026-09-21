# Zync Hobby Card Art — Pilot v1 Report

**Date:** 2026-09-21
**Model:** `fal-ai/nano-banana-pro/edit` (fal.ai), reference-image style guidance via `image_urls`
**Resolution / aspect:** 2K, 2:3 portrait
**Branch:** `card-art-pilot-v1-20260921`

## Run summary

- 15 hobbies, 16 total API calls (14 first-pass + 1 retry for Cinema), 1 retry used out of the allowed max of 2 per hobby.
- Estimated total cost: **$2.40** (16 × $0.15), well under the $20 pilot budget.
- All 15 final artworks are portrait 2:3, artwork-only: no text, logos, card frames, rarity badges, numbers, or UI in any of the 15 finals.
- Contact sheet: `output/pilot_v1/contact-sheet.jpg`
- Gallery: `output/pilot_v1/gallery.html`
- Full record: `output/pilot_v1/manifest.json`

## Scoring (1–5 each)

| Hobby | Recognition | Desirability | Composition | Style Consistency | Avg |
|---|---|---|---|---|---|
| Badminton | 5 | 5 | 5 | 5 | 5.00 |
| Bouldering | 5 | 5 | 5 | 5 | 5.00 |
| Board Games | 5 | 5 | 5 | 5 | 5.00 |
| Cinema (attempt 2) | 5 | 5 | 5 | 5 | 5.00 |
| Pottery | 5 | 5 | 5 | 5 | 5.00 |
| Japan | 4 | 5 | 5 | 5 | 4.75 |
| Sushi | 5 | 5 | 4 | 5 | 4.75 |
| Piano | 5 | 5 | 4 | 5 | 4.75 |
| Road Trip | 5 | 5 | 5 | 4 | 4.75 |
| Coffee | 5 | 5 | 4 | 5 | 4.75 |
| Photography | 5 | 5 | 5 | 4 | 4.75 |
| LEGO | 4 | 5 | 5 | 5 | 4.75 |
| Camping | 5 | 4 | 4 | 5 | 4.50 |
| Running | 5 | 4 | 5 | 4 | 4.50 |
| AI | 4 | 4 | 4 | 4 | 4.00 |

## Best 3

1. **Board Games** — the strongest social-warmth card in the set: four readable faces, genuine interaction, a fully legible tabletop game mid-play, lamp-lit color grading that matches the reference almost exactly.
2. **Bouldering** — best action archetype execution: chalk dust, visible exposure/height, expressive strain in the face, dramatic valley backdrop. Instantly reads within 2 seconds.
3. **Pottery** — best craft_maker execution: tactile hands-on-clay detail, coherent studio environment, warm directional light. Feels the most "premium collectible" of the batch.

(Badminton and Cinema attempt 2 were statistically tied at 5.00 and are strong alternates.)

## Weakest 3

1. **AI (4.00)** — reads as "person doing focused tech work at night" rather than specifically "AI." The on-screen diagrams are generic dev/code visuals rather than anything distinctly AI-flavored (no generative-image, no neural-net-style visualization). Screen content also contains faint illegible glyphs that sit close to the "no text" restriction — not real words, but worth tightening.
2. **Camping (4.50)** — solid and correctly recognizable, but the composition is the plainest of the journey_atmosphere group; the silhouetted figure and tent read a little generic next to Road Trip's and Japan's more dynamic framing.
3. **Running (4.50)** — strong action pose, but the lens-flare/skyline treatment leans more photo-travel-poster than the painterly-digital-illustration language used elsewhere, and the distant skyline reads as slightly generic stock-photo staffage.

## Style drift

- **Road Trip** and **Running** both pick up a touch more photoreal rendering and literal lens-flare than the rest of the set, which otherwise reads as consistent painterly digital illustration. Minor, but the two most likely to look "off-universe" if placed directly next to Pottery or Board Games in a final deck.
- Everything else holds a single coherent illustration language matching the reference's color grading and lighting approach.

## Repeated compositions

- **Photography** and **Road Trip** (and to a lesser extent **Japan**) all use an elevated-vista-with-a-winding-path/river composition. This is an intentional consequence of sharing the `journey_atmosphere`-adjacent language, but three cards using near-identical "figure small in frame overlooking a sweeping landscape" staging is a real repetition risk once more hobbies are added — worth diversifying camera angle/distance per hobby in v2 (e.g., closer crop for Photography focused on hands-on-camera rather than the landscape behind).
- The three `solo_action` cards (Badminton, Bouldering, Running) share a dynamic-diagonal-lunge silhouette language — this repetition is intentional (same archetype) and reads as a feature, not a bug, for visual-family coherence.

## Hobbies needing prompt/archetype changes for v2

- **AI**: revise the hobby recipe's `subject`/`key_objects` to depict something distinctly AI-generative (e.g., a glowing AI-generated image forming on one screen, or a stylized neural-network visualization) rather than generic code/diagrams, and explicitly instruct "no readable text or code, abstract glowing visualizations only" to remove the text-restriction risk entirely.
- **LEGO**: recognition scored 4, not 5 — strengthen by bringing a single large, unmistakably stud-textured brick or minifigure into sharp foreground focus so the hobby reads instantly even at small card size, rather than relying on the mid-ground castle model.
- **Photography**: keep the archetype but pull the camera closer to the photographer's hands/viewfinder so the shot doesn't visually collide with Road Trip/Japan's landscape-vista staging.

## Verdict

14 of 15 hobbies hit full recognition (5/5) or near-full (4/5) on the "hidden title, 2-second read" test on the first attempt; Cinema needed one retry to move from an abstract, unreadable screen to a legible in-universe movie scene, after which it also hit 5/5 across the board. The batch is materially close to the reference's collectible-card desirability and holds a single coherent visual universe — the main risks for a full 100+ card rollout are compositional repetition within shared archetypes (journey/vista shots) and tightening the AI recipe, not the underlying pipeline or model choice.

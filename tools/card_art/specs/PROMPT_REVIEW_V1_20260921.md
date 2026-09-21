# Prompt Review V1 — 2026-09-21

## Result
The 15-prompt compiler smoke test works, but the first implementation was not ready to scale to 3000+ unchanged.

## Material findings
1. The claim that all 15 archetypes were represented was incorrect. The 15 pilot hobbies use 13 unique archetypes; `urban_discovery` and `calm_wellness` are defined but unused. This is not a generation error.
2. The V1 compiler omitted an explicit style-reference instruction even though the edit models are supplied `references/zync-card-style-reference.png`.
3. One composition per archetype would create obvious repetition at 3000+ scale. Added a curated 3-variant composition/camera library for every archetype and deterministic selection with optional hobby override.
4. `tier` and `hard_case` were conflated. They are now separate concepts: tier controls importance; difficulty controls ambiguity/review requirements.
5. The fallback hint did not reroll when average QA failed the threshold but no individual score was below 3. It now follows the full pass rule.
6. The documented hobby override schema did not match what the compiler actually supported. Override semantics are now explicit.
7. Several known prompt weaknesses were only written in QA notes and therefore had no effect on generation. They are now active prompt fields.
8. Bouldering was conceptually too close to high-altitude rock climbing. The recipe now uses an unmistakable rope-free indoor bouldering wall with crash mats.
9. Photography, Running, Camping, AI, Cinema, Japan, and LEGO received active composition/recognition corrections based on the pilot and cheap-model comparisons.
10. Global negatives now explicitly block pseudo-text, real-world branding, recognisable franchise characters, and collage/split-screen drift.

## No image generation
This review only changes prompt/spec/compiler data. No fal.ai generation was run and no API credits were spent.

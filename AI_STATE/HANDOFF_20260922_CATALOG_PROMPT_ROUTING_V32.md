# Zync — Catalog Prompt Routing V3.2 Handoff

Date: 2026-09-22
Branch: `card-art-pilot-v1-20260921`
Authoritative report: `tools/card_art/report/CATALOG_PROMPT_ROUTING_AUDIT_V32.md`

## Hard boundaries

- Production CLOSED.
- Google Play CLOSED.
- Image generation CLOSED.
- No image API credits.
- Conserve GitHub Actions until 2026-10-01.
- Do not claim Node/Flutter commands passed unless they were actually executed.

## Stable catalog / rights state

- canonical interests: **3,935**
- baseline-art eligible: **2,092**
- rights-blocked: **1,843**
- 444-query everyday wording benchmark remains 100%
- duplicate/collision gates remain clean from V3

Independent segmented reconciliation:
- parts 1–8: 849 eligible + 1,099 blocked
- parts 9–15: 1,243 eligible + 744 blocked
- missing catalog-to-art routes: 0

## V3.2 core improvement

V3.1 proved every eligible interest had a route.
V3.2 audited whether the route would actually produce a semantically sensible image prompt.

Major routing/template failures were found and repaired BEFORE image generation.

New families:
- strategy_table
- digital_play
- fitness_training
- water_outdoors
- outdoor_motion
- home_lifestyle
- food_exploration
- campus_activity
- community_gathering
- wellness_experience
- creator_workflow

Existing V3.1 families remain.

## Important compiler fix: generic-safe variants

Variants may now set:

`generic_eligible:false`

Hash-based default selection ignores those variants.
Explicit/manual `visual_variant` may still select them.

This prevents:
- AI-specific composition being assigned to generic technology
- Camping-specific composition being assigned to birdwatching
- LEGO/building composition being assigned to stamp collecting
- arcade/vessel/fishing/workshop subtype compositions being randomly assigned to unrelated peers

`buildPromptV1.js` now hashes only generic-safe variants.

## Important bridge capability

`catalogRecipeBridge.js` now supports:
- id
- id_in
- id_prefix
- id_contains
- cluster / cluster_prefix / cluster_contains
- explicit visual_variant

It also no longer requires structuredClone.

## Representative routes now pinned by preflight

Examples:
- Chess -> strategy_table
- Claw Machines -> digital_play/arcade
- Weightlifting -> fitness_training
- Yoga -> calm_wellness/centered
- Surfing -> water_outdoors
- Kayaking -> water_outdoors/vessel
- Gravel Cycling -> outdoor_motion
- Gardening -> home_lifestyle
- Yum Cha -> food_exploration
- Sim Racing -> digital_play/desktop
- Lion Dance -> performance
- Nursing -> professional_world
- Dog Agility -> companion/training_action
- Philosophy -> discussion_object hard case
- MUN -> campus/debate
- Campus Radio -> campus/media
- Founder Meetups -> community/networking
- Book Swaps -> community/swap
- Hot Springs -> wellness_experience/immersion
- Sauna -> wellness_experience/heat
- Podcasting -> creator/mic
- Video Editing -> creator/edit
- Vlogging -> creator/camera
- Animation -> creator/drawing
- Blogging -> creator/writing
- Game Streaming -> creator/broadcast
- Escape Room Design -> physical creative prototype

## New no-image prompt QA command

```bash
npm run audit-prompt-samples
```

Source:
`tools/card_art/src/auditPromptSamples.js`

Fixed stratified sample: **41 interests**.

Output:
`tools/card_art/generated/stratified_prompt_samples_v1.jsonl`

It uses the real bridge/compiler but makes no image API calls.

## Validation truth

Completed via repository-derived static/simulation work:
- full 3,935 / 2,092 / 1,843 reconciliation
- all catalog halves route without missing family
- representative derived recipes simulated and manually inspected
- every semantic failure discovered during the simulation was repaired and re-simulated

NOT YET actually executed:
- npm run audit-catalog-recipes
- npm run audit-prompt-samples
- npm run compile-prompts
- Flutter analyze/tests

## Continue in this exact order

1. Execute `npm run audit-catalog-recipes`.
2. Execute `npm run audit-prompt-samples`.
3. Review all 41 actual compiled prompt records.
4. Fix any final prompt-level issues.
5. Execute `npm run compile-prompts` for all 2,092 eligible interests.
6. Do not generate images yet.
7. After 2026-10-01, run Flutter gates and Android validation.


## Mandatory infrastructure / automation guardrail

Before any future repo write or infrastructure action, read and obey:

`AI_STATE/OPERATING_RULES.md`

Key rule: audit the automation blast radius **before** the first commit/push/PR/deployment. Do not use Vercel or GitHub Actions unless the task genuinely needs them. Prefer zero-cost static/repository work, batch changes, and avoid micro-commits that trigger CI or Preview deployments.

This rule was added after the 2026-09-19 to 2026-09-22 incidents in which high-frequency Zync writes produced massive GitHub Actions churn and unnecessary Vercel Preview deployments / Deployment Storage consumption.

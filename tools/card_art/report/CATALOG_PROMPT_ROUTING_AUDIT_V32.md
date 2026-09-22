# Zync Catalog-Scale Prompt Routing Audit V3.2

Date: 2026-09-22
Branch: `card-art-pilot-v1-20260921`

## Hard boundaries

- Production CLOSED.
- Google Play CLOSED.
- Image generation CLOSED.
- No image API credits were spent.
- GitHub Actions conservation remains in force until the 2026-10-01 reset.
- No hosted Flutter CI was run in this checkpoint.

## Stable catalog / rights totals

Independent segmented static audit still reconciles to:

- Canonical interests: **3,935**
- Baseline-art eligible: **2,092**
- Rights-blocked: **1,843**

Segment reconciliation:
- parts 1–8: 1,948 total = 849 eligible + 1,099 blocked
- parts 9–15: 1,987 total = 1,243 eligible + 744 blocked

No catalog route was missing in either segment.

The 444-query everyday-interest benchmark and earlier duplicate/collision gates remain unchanged.

## Why V3.2 was necessary

V3.1 proved that every eligible canonical could map to *an* art family. V3.2 asked a harder question:

> If the inherited recipe is actually expanded for a representative interest, does the visual family, subject template and chosen composition make semantic sense?

Repository-derived simulations exposed several routing/template failures that count-only validation could not detect.

Examples found before repair:

- Chess / Mahjong / Poker inherited athletic `solo_action` behavior because they live in the sports category.
- Generic video games inherited tabletop-oriented `group_play`.
- Weightlifting / HIIT inherited `calm_wellness`.
- Surfing / kayaking / skiing inherited camping-like `nature_immersion`.
- Gardening inherited city/social discovery language.
- Yum Cha / dining experiences inherited single-dish-only food framing.
- Mock Trial / Moot Court could hash to scientific/field-observation compositions.
- Campus Radio inherited generic learning.
- Founder / Tech Meetups inherited office-role imagery.
- Sauna could hash to close-hands self-care imagery.
- Game Streaming / Game Modding / Escape Room Design inherited ordinary game-play visuals.
- Pilot-specific variants such as AI's `over_shoulder_generation`, Camping's `warm_camp_anchor`, and LEGO's `hands_build` were still in generic hash pools.

These were corrected before image generation.

## New / refined visual families

V3.2 adds:

- `strategy_table`
- `digital_play`
- `fitness_training`
- `water_outdoors`
- `outdoor_motion`
- `home_lifestyle`
- `food_exploration`
- `campus_activity`
- `community_gathering`
- `wellness_experience`
- `creator_workflow`

These sit alongside the V3.1 families such as:
- `music_listening`
- `reading_world`
- `learning_exploration`
- `professional_world`
- `companion_bond`
- `journey_machine`

## Representative routing now pinned

Examples:

- Chess -> strategy_table
- Claw Machines -> digital_play / arcade_interaction
- Weightlifting -> fitness_training
- Yoga -> calm_wellness / centered_ritual
- Surfing -> water_outdoors
- Kayaking -> water_outdoors / vessel_interaction
- Gravel Cycling -> outdoor_motion
- Gardening -> home_lifestyle
- Yum Cha -> food_exploration
- Sim Racing -> digital_play / desktop_focus
- Lion Dance -> performance
- Nursing -> professional_world
- Dog Agility -> companion_bond / training_action
- Archaeology -> learning_exploration
- Reading -> reading_world / hard case
- Philosophy -> learning_exploration / discussion_object / hard case
- Mindfulness -> calm_wellness / hard case
- Streetwear -> urban_discovery / hard case
- Model United Nations -> campus_activity / debate_floor
- Campus Radio -> campus_activity / media_project
- Math Olympiad -> campus_activity / academic_challenge
- Study Abroad -> campus_activity / exchange_campus
- Founder Meetups -> community_gathering / event_networking
- Book Swaps -> community_gathering / swap_exchange
- Hot Springs -> wellness_experience / immersion_ritual
- Sauna -> wellness_experience / heat_room
- Podcasting -> creator_workflow / microphone_session
- Video Editing -> creator_workflow / editing_workstation
- Vlogging -> creator_workflow / camera_creation
- Animation Production -> creator_workflow / drawing_animation
- Blogging -> creator_workflow / writing_desk
- Game Streaming -> creator_workflow / stream_broadcast
- Escape Room Design -> creative_studio with physical puzzle prototyping
- Game Modding -> tech_workspace with generic non-IP modification workflow

These are now represented in `auditCatalogRecipes.js` route sentinels where appropriate.

## Ordered profile routing improvements

`catalogRecipeBridge.js` now supports:
- exact `id`
- `id_in`
- `id_prefix`
- `id_contains`
- cluster / cluster-prefix / cluster-contains
- explicit `visual_variant`

This permits broad inheritance plus narrow semantic correction without minting thousands of one-off recipes.

The bridge no longer relies on `structuredClone`; JSON-safe cloning is used for wider Node compatibility.

## Variant safety

A deeper compiler issue was fixed.

Previously, every variant in an archetype pool was eligible for deterministic hash assignment. Some variants were actually pilot- or subtype-specific.

Examples:
- `tech_workspace / over_shoulder_generation` — AI-specific
- `nature_immersion / warm_camp_anchor` — Camping-specific
- `collection_object_hero / hands_build` — LEGO/building-specific
- `digital_play / arcade_interaction`
- `water_outdoors / vessel_interaction`
- `water_outdoors / water_ritual`
- `journey_machine / workshop_hands`

The compiler now:
1. keeps the full pool available for explicit/manual selection;
2. filters out any variant with `generic_eligible:false` before hash-based selection;
3. fails if an archetype has no generic-safe variants.

The pure preflight additionally validates:
- every explicit visual variant exists;
- every archetype has at least one generic-safe variant.

## Template inheritance repairs

Changing only the archetype was not sufficient because the category's inherited subject/environment text could remain semantically wrong.

V3.2 therefore also changes subject/environment/must-include inheritance for:

- mind sports
- fitness training
- dance
- live/performance arts
- music making
- photography
- home/family
- philosophy
- sim racing
- dog agility
- campus/student activities
- professional meetups
- swaps / repair workshops
- wellness venue experiences
- media creation
- creator-like gaming

Example repairs:

### Weightlifting
Before:
- "wellness ritual"
- "calm uncluttered setting"

Now:
- active weightlifting
- correct body mechanics
- real gym/training context

### Lion Dance
Before:
- generic arts-making language about hands/tools/material

Now:
- active performance/rehearsal
- defining movement / act / cultural venue

### Philosophy
Before:
- could hash into field observation

Now:
- hard case
- fixed discussion_object variant
- engaged discussion with non-text-dependent concrete anchor

### Dog Agility
Before:
- could become a generic human-dog bond portrait

Now:
- dog in active agility movement
- handler cue
- visible agility obstacle

## Campus layer

A dedicated `campus_activity` family now supports the V3 campus expansion.

Explicit variant groups include:

- MUN / Mock Trial / Moot Court -> `debate_floor`
- Student Newspaper / Campus Radio / Yearbook -> `media_project`
- Math / Science Olympiad / Academic Competitions -> `academic_challenge`
- Exchange Programs / Study Abroad -> `exchange_campus`
- Student Volunteering / Student Societies / Campus Events -> `club_event`

A generic-safe `campus_participation` variant remains available for future campus canonicals.

## Community layer

A new `community_gathering` family handles interests where the social connection itself is central.

Examples:
- Founder Meetups
- Startup Meetups
- Tech Meetups
- Alumni Networking
- Book Swaps
- Clothing Swaps
- Repair Workshops

This avoids corporate-office or random street-scene fallthrough.

## Wellness-experience layer

A new `wellness_experience` family handles venue / sensory rituals that do not fit generic calm-self-care framing.

Explicit routes:
- Hot Springs / Cold Plunge -> `immersion_ritual`
- Sauna -> `heat_room`
- Spa / Massage -> `treatment_relax`
- Sound Bath -> `sound_rest`

Generic future entries may use `wellness_venue`.

## Creator layer

A new `creator_workflow` family covers the expanded creator economy:

- Podcasting -> microphone_session
- Video Editing -> editing_workstation
- Vlogging -> camera_creation
- Content Creation -> camera_creation
- Livestreaming -> camera_creation
- Motion Graphics -> editing_workstation
- Sound Design / Audio Editing -> editing_workstation
- Animation Production / Webcomics -> drawing_animation
- Blogging / Newsletter Writing -> writing_desk
- Voiceover -> microphone_session
- Online Video / Short-form Video -> camera_creation
- Game Streaming -> stream_broadcast

Game Modding is routed to a generic non-IP tech creation workflow.
Escape Room Design is routed to physical puzzle prototyping.

## Hard-case policy remains

Existing V3.1 hard-case protections remain.

Additionally, finance-like business concepts were marked hard-case for human review:
- Value Investing
- Dividend Investing
- Index Investing
- Real Estate Investing
- Budgeting
- Saving Money
- Financial Independence
- FIRE Movement

The reason is visual ambiguity without relying on readable charts, tickers, numbers or brand/company identity.

## Validation performed in this checkpoint

Performed via repository-derived static/simulation logic, not hosted CI:

- full catalog segmented rights reconciliation:
  - 3,935 total
  - 2,092 eligible
  - 1,843 blocked
- no missing catalog-to-art route in either catalog half
- representative derived-recipe simulation across sports, wellness, outdoors, gaming,
  home, food, transport, performance, career, pets, learning, fashion, collecting,
  campus, community, wellness experiences and creator workflows
- before/after re-simulation of every semantic failure found above
- route sentinel expansion in `auditCatalogRecipes.js`

Not yet executed in a shell:
- `npm run audit-catalog-recipes`
- `npm run compile-prompts`
- `npm run audit-prompt-samples`

Do not describe these commands as passed until they are actually executed.

## New no-API stratified prompt audit

New command:

```bash
npm run audit-prompt-samples
```

Source:
`tools/card_art/src/auditPromptSamples.js`

It compiles a fixed **41-interest** stratified sample using the real:
- rights-first bridge
- manual/derived recipe selection
- archetype/variant compiler
- overrides
- global style / negatives

It writes:
`tools/card_art/generated/stratified_prompt_samples_v1.jsonl`

It makes **no image API calls**.

The sample includes:
- reviewed manual examples
- every major repaired route family
- known hard cases
- abstract-only examples

## Next continuation

1. In a real command environment, run:
   - `npm run audit-catalog-recipes`
   - `npm run audit-prompt-samples`
2. Human-audit all 41 actual compiled prompt records.
3. Fix any compiler-level wording or negative-constraint issues.
4. Run `npm run compile-prompts` for all 2,092 eligible canonicals.
5. Audit distribution / failures / output size.
6. Still generate **zero images** until prompt QA is accepted.
7. After 2026-10-01, run Flutter analyze/tests and Android validation.

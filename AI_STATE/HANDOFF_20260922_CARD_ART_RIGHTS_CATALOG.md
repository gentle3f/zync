# Zync — Authoritative Handoff — Card Art / Interest Catalog / Rights Policy

Date: 2026-09-22
Branch: `card-art-pilot-v1-20260921`
Head before this handoff: `896799509736c44478005e1397e32ae5a0402132`

Production: **CLOSED**
Google Play: **CLOSED**
PR #1: **DO NOT MERGE**

## 1. Active product direction

The current workstream is no longer simply “generate thousands of hobby-card images.”

The architecture is now:

```
Interest catalog
→ release-readiness cleanup
→ rights/card policy classification
→ Random Event / Zync Now activity eligibility
→ baseline-art eligibility
→ prompt compilation
→ image generation
```

Critical product rule:

> **Being a searchable/matchable Interest does NOT automatically mean Zync should generate a collectible Card for it.**

This separation is now deliberate and commercially important.

## 2. Why the architecture changed

The catalog is very deep in:
- music artists,
- movies / TV,
- anime,
- game franchises,
- book titles,
- named tabletop systems,
- other IP-heavy entities.

Those concepts are useful for:
- matching,
- discovery,
- Zync questions,
- fan affinity,
- future partner demand,

but generating unofficial official-looking collectible cards for named brands / artists / franchises creates copyright / trademark / likeness / partnership problems.

The chosen product direction is therefore:

### Generic concepts
Examples:
- Badminton
- Camping
- Cinema
- Jazz
- RPGs
- Meditation
- Thrifting
- Photography
- Road Trips

These may receive original Zync baseline artwork.

### Named brands / franchises / artists / titles
Examples:
- Porsche
- Ferrari
- LEGO
- Formula 1
- Taylor Swift
- named films / TV / anime
- named game franchises
- named board games / TTRPG systems
- named book titles
- YouTube

These remain searchable and matchable, but official-looking collectible artwork is held for licensed/rightsholder partnerships.

This also creates a future commercial wedge:
Zync can show real fan affinity before the brand/rightsholder joins, while reserving official branded editions as partner inventory.

## 3. Existing rights-policy implementation

Commit:
`896799509736c44478005e1397e32ae5a0402132`

Message:
`feat: expand everyday interests and add rights-aware card policy`

Important new files:
- `docs/ZYNC_INTEREST_CARD_RIGHTS_AND_PARTNER_POLICY_V1.md`
- `mobile/lib/core/interest_card_policy_resolver.dart`
- `mobile/lib/core/interest_catalog_part11.dart`
- `tools/card_art/report/INTEREST_CATALOG_POLICY_PATCH_V1.md`

The runtime policy currently exposes:
- `originalGeneric`
- `abstractOnly`
- `licensedOnly`
- `notCollectible`

and returns:
- `baselineArtEligible`
- `ipSensitive`
- `partnerOpportunity`
- `reasonCode`
- `eventAffinityPriority`
- `partnerType`
- `proxyFamily`

The generation pipeline must eventually honor:
> only generate baseline artwork when `baselineArtEligible == true`, unless a licensed partner override is explicitly approved.

## 4. Social / Wellness / Lifestyle expansion

The user explicitly reminded us that these categories matter heavily for the existing Random Event / Zync Now concept.

They are not filler taxonomy. They are action vocabulary.

The latest patch added everyday interests including:
- Triathlon
- Scrapbooking
- Creative Writing
- Journaling
- Food Photography
- Foraging
- Parties & Social Gatherings
- Cafe Hopping
- Shopping
- Thrifting
- Flea Markets
- Night Markets
- Farmers' Markets
- City Walks
- Brunch
- Dinner Parties
- Local Events
- Personal Development
- Debating
- PC Building
- Hair Styling
- Fragrance
- Driving
- Stand-up Comedy
- Podcasts
- Online Video
- YouTube
- Massage
- Nutrition
- Healthy Eating
- Self-Care
- Spa & Wellness Days
- Sound Baths
- Aromatherapy
- Recovery & Relaxation
- Digital Detox
- Meal Prep

It also added a major car-brand affinity family under:
`transport/cars/brands`

Examples include:
Toyota, Lexus, Honda, BMW, Mercedes-Benz, Porsche, Ferrari, Lamborghini, Tesla, BYD, NIO, XPeng, etc.

Car brands are intentionally:
- searchable: YES
- matchable: YES
- useful for affinity / future partner value: YES
- baseline branded card art: NO
- licensed/partner card opportunity: YES

## 5. Zync Now / Random Event integration

Existing relevant files:
- `docs/ZYNC_NOW_DECISION_ENGINE_SPEC.md`
- `mobile/lib/core/activity_templates.dart`
- `mobile/lib/core/interest_activity_resolver.dart`
- `mobile/lib/core/zync_now_engine.dart`

The latest patch added safe activity support for:
- browsing / thrifting / shopping exploration,
- social exploration,
- podcasts/audio compare,
- low-pressure wellness reset,
- wellness experiences.

Conservative exclusions remain important:
- nightlife/bar concepts should not be auto-suggested generically,
- nutrition/massage/aromatherapy should not become medical advice,
- higher-risk activities remain explicit/reviewed rather than auto-enabled.

## 6. Catalog audit result before patch

The earlier release-readiness audit is:

`tools/card_art/report/INTEREST_CATALOG_RELEASE_AUDIT_V1.md`

Key findings before the latest patch:
- canonical count was **3,403**, not the earlier rough 2,032 estimate;
- 67.6% of canonical interests were music + entertainment + gaming;
- roughly half were obvious title/artist/franchise-heavy entities;
- common-interest search benchmark: **174 / 201 = 86.6%**;
- weaker everyday areas were Social / Wellness / Lifestyle / entertainment formats;
- exact-term collisions and some duplicate-risk concepts exist.

Important exact-term ambiguity examples:
- Minimalism → lifestyle vs music style
- The Last of Us → TV vs game
- East of Eden → film vs book
- The Handmaid's Tale → TV vs book
- 三體 / 三体 → TV vs book

Important same-category duplicate/overlap risks:
- Road Trips / Road Tripping
- Cruises / Cruise Travel
- Romance Books / Romance Novels
- Biographies / Biography
- Dream Pop / Dreamy Pop
- Lo Ta-yu / Tayu Lo
- Soup Dumplings / Xiaolongbao

`InterestCatalog.exact()` still uses first-wins semantics, so ambiguity remains a product issue unless later fixed.

## 7. Canonical count after latest patch

Recounting the runtime parser semantics across:
`interest_catalog_part1.dart` through `interest_catalog_part11.dart`

gives:

> **3,505 canonical interests**

Part 11 contributes 102 entries.

This is the current working count on this branch.

## 8. Card-art model / prompt direction

The card-art pilot already proved the image-generation route.

Current model economics from actual tests:
- Nano Banana Pro/edit: about **$0.15/image**
- Gemini 2.5 Flash Image/edit: about **$0.039/image**
- FLUX-2/edit: about **$0.025/image**

Current preferred production model:
- default: `flux-2/edit`
- fallback: `gemini-25-flash-image/edit`
- premium rescue/showcase: `nano-banana-pro/edit`

The user explicitly believes prompt quality is the main lever and accepts FLUX-2 quality/cost for baseline art.

No mass image generation should happen yet.

## 9. Prompt-system state

Prompt architecture is already implemented and reviewed.

Important files:
- `tools/card_art/specs/ZYNC_CARD_ART_PROMPT_SYSTEM_V1.md`
- `tools/card_art/specs/global_style_v1.json`
- `tools/card_art/specs/archetypes_v1.json`
- `tools/card_art/specs/archetype_variants_v1.json`
- `tools/card_art/specs/category_modifiers_v1.json`
- `tools/card_art/specs/subcategory_modifiers_v1.json`
- `tools/card_art/specs/qa_rubric_v1.json`
- `tools/card_art/src/buildPromptV1.js`
- `tools/card_art/src/compilePrompts.js`
- `tools/card_art/generated/compiled_prompts_v1.jsonl`

Prompt review commits:
- `a5f949f68d258c2e8cee3bd7d3b787b5ba565170`
- `3fa574f8d5a7ef895a05e1b3eda5699ddd286f20`

The pilot prompt system currently covers only the 15 benchmark/pilot hobbies. Do NOT treat that as the final catalog.

## 10. Important prompt review corrections already made

- explicit reference-image instruction restored;
- 15 archetypes retained;
- curated visual-variant library added to prevent thousands of repeated compositions;
- tier vs hard-case difficulty separated;
- full QA pass thresholds now govern reroll;
- hobby override semantics made explicit;
- known weak prompts made active rather than passive QA notes;
- Bouldering corrected toward true rope-free bouldering;
- AI / Photography / Cinema / Camping / Running / Japan / LEGO strengthened;
- global negatives now guard pseudo-text, brands/logos, franchise characters, collage/split-screen drift, and stock-photo rendering.

Reference image:
`references/zync-card-style-reference.png`

## 11. Latest commit review status

Latest feature commit:
`896799509736c44478005e1397e32ae5a0402132`

Files changed include:
- rights/partner policy
- card policy resolver
- Part 11 catalog expansion
- activity templates/resolver
- catalog wiring
- localization policy
- tests
- policy report

At handoff time, GitHub check-runs show only:
- Vercel Preview Comments: success

A full Flutter/test/CI validation of this latest catalog/policy patch has **not been independently confirmed in this chat**.

Do not assume it is fully certified until tests are run or CI evidence is inspected.

## 12. Immediate next task

Continue from the latest patch, not from old card-art generation.

### First priority: validate the 896799 patch
1. inspect the full diff for policy mistakes;
2. run / inspect relevant tests:
   - interest catalog tests
   - localization audit
   - activity resolver tests
   - card policy resolver tests
   - Flutter analyze if practical;
3. recount catalog from runtime parser semantics;
4. re-run the common-interest search benchmark after the new aliases/interests;
5. verify that existing exact-match and QR behavior remains stable.

### Second priority: audit rights-policy coverage across all 3,505 interests
Produce counts for:
- baselineArtEligible
- licensedOnly
- abstractOnly
- notCollectible
- ipSensitive
- partnerOpportunity
- proxy families
- event-affinity priority

Specifically inspect false negatives:
named artists/titles/franchises that accidentally remain `originalGeneric`.

Specifically inspect false positives:
generic concepts accidentally classified as `licensedOnly`.

### Third priority: decide remaining catalog cleanup
- resolve obvious same-category duplicate canonicals;
- decide exact-term disambiguation behavior;
- check whether Social / Wellness / Lifestyle / Random-Event vocabulary is now sufficiently broad;
- add only targeted gaps, not another arbitrary 1000 entries.

### Fourth priority: expand card-art prompt catalog
Only after release-stable catalog + rights policy is accepted:
- build recipes for `baselineArtEligible == true` interests;
- do NOT generate baseline art for `licensedOnly` interests;
- licensed-only interests may map to generic proxy families;
- compile prompts first;
- review compiled prompts;
- only then run image generation.

## 13. Explicit user intent / preferences

- User wants real execution, not repeated discussion.
- User wants ChatGPT to own prompt architecture; Claude Code should implement/compile/operate the pipeline, not invent its own art philosophy.
- User prefers the cheap-model + strong-prompt strategy.
- User wants car brands and other brands as interests, but likes the idea that official cards remain reserved so brands/rightsholders have a reason to approach Zync.
- User explicitly worries about copyright / trademark problems for music, drama, movies and games.
- User sees Social / Wellness / Lifestyle as strategically important because of Random Event / Zync Now.
- No API credits should be spent until prompt/policy/catalog review is complete.

## 14. Hard boundaries

- Production CLOSED.
- Google Play CLOSED.
- PR #1 DO NOT MERGE.
- No mass fal.ai generation yet.
- No branded/franchise baseline card generation without rights approval.
- Do not collapse Interest matching into Card eligibility.
- Do not discard named entities merely because they cannot have baseline art.
- Do not restart repo discovery.

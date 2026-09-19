# Zync Card Generation Pipeline V1

Status: **Generation architecture — no paid image API required for the base system**

## 1. Core decision

Do not create 3,000 independent full illustrations.

Generate cards from reusable deterministic components.

The system is:

`Interest metadata × visual family × scene grammar × motif set × deterministic palette × edition × finish`

A single art-system version can therefore render thousands of coherent cards.

## 2. Inputs

Each canonical interest needs a generation record:

- canonical interest ID
- stable card number
- category
- subcategory
- localized title keys
- visual family
- icon/emblem key
- optional vibe tags
- art policy
- art system version

Optional enrichment:

- scene tags
- secondary motifs
- energy/mood tags
- location theme
- material family

Translation text is presentation data, not visual-seed input.

## 3. Deterministic identity

Base visual seed:

`hash("card-art-v{version}|{canonicalInterestId}")`

Use the seed to choose deterministic variants of:

- scene layout
- palette
- motif placement
- decorative pattern
- crop/rotation within safe bounds

The same canonical interest and art version must render the same card on every device/language.

Changing the art-system version is the intentional migration mechanism.

## 4. Three-tier asset strategy

### Tier A — Procedural runtime/base renderer

Free and scalable.

Use:

- Flutter CustomPainter / Canvas
- vector paths
- gradients
- deterministic geometry
- reusable SVG motifs
- category pattern generators

Good for:

- category fields
- scene geometry
- motif placement
- border
- metadata
- edition seals
- static card preview

### Tier B — Reusable authored asset library

Create a bounded set of original assets rather than 3,000 full cards.

Target:

- 12–16 category kits
- 50–100 visual-family scene grammars
- 100–200 primary emblems/icons
- 200–400 secondary motifs/fragments
- texture/pattern library

Assets can be created manually or with assisted generation, then reviewed once and reused.

### Tier C — Hero/chase art

Use bespoke art only for a small subset:

- launch Secret variants
- event chase cards
- special Legendary treatments

This keeps cost and review effort bounded.

## 5. Recommended implementation split

### Build-time / tooling

A small generator tool should:

1. read canonical interest metadata
2. validate unique card number
3. validate visual family
4. compute stable visual seed
5. choose deterministic palette/scene recipe
6. emit a manifest
7. optionally render preview SVG/PNG/WebP
8. produce audit report for missing metadata

### Flutter runtime

Flutter should:

- load the card recipe/manifest
- render base composition
- render localized text
- apply edition seal
- apply focus-only finish effect
- cache rasterized thumbnails where useful

This avoids shipping thousands of giant pre-rendered images.

## 6. Suggested manifest

Example conceptual shape:

```json
{
  "interestId": "sports.badminton",
  "cardNumber": 47,
  "artSystemVersion": 1,
  "visualSeed": "stable-seed",
  "categoryKit": "sports",
  "visualFamily": "sports_racket",
  "emblem": "shuttlecock",
  "sceneGrammar": "court_arc",
  "paletteSlot": 3,
  "artPolicy": "original_generic"
}
```

Do not place localized title text into the seed.

## 7. Scene grammar

A scene grammar is a small program/template, not a finished card image.

Example `sports_racket` grammar:

- court line layer
- diagonal motion arc
- one equipment emblem
- two secondary speed fragments
- optional net/grid
- focal zone locked away from title
- deterministic angle from seed

Example `outdoors_climbing` grammar:

- 2–4 faceted wall planes
- hold/chalk motifs
- vertical route line
- depth shadow
- open title zone

Example `food_drink` grammar:

- circular plate/cup anchor
- steam/ingredient curves
- menu/stamp marks
- warm material texture

With 50–100 grammars, thousands of cards can vary meaningfully without thousands of authored illustrations.

## 8. Palette system

Each category kit owns an approved palette bank.

Seed chooses one slot.

A palette record contains:

- background
- mid layer
- accent
- title panel
- motif contrast
- border base

Finish effects are separate.

This means a Holo Badminton and Normal Badminton share visual identity but differ in finish material.

## 9. Finish renderer

Do not bake every finish into a separate 1000×1400 image.

Preferred:

- one base composition
- finish metadata
- runtime shader/overlay

Possible Flutter implementation:

- AnimationController
- ShaderMask
- CustomPainter
- Transform / Gesture tilt
- FragmentShader for advanced holo
- haptics
- short audio cue

Grid rule:

- static snapshot only

Detail/reveal rule:

- animated finish allowed

## 10. Cache strategy

Cache key:

`interestId + artSystemVersion + recipeVersion + localeLayoutVersion + thumbnailSize`

Finish animation itself does not need separate full raster caches.

Cache:

- base card thumbnail
- text-composited localized thumbnail where worthwhile

Invalidate only when relevant version changes.

## 11. Free asset sources

Prefer:

- original SVG geometry
- app-owned generated patterns
- Material Symbols where license/use fits
- Phosphor/Lucide where license/use fits
- Google Fonts already compatible with product licensing

Every external asset family requires a license record before shipping.

Do not silently scrape image search results.

## 12. AI-assisted art policy

AI can assist with a small reusable asset library, but is not required for every card.

Good use:

- create one original texture family
- create generic abstract motif sheets
- create a small set of category scene assets
- create bespoke event/Legendary hero art

Bad use:

- one paid API call for every interest every release
- uncontrolled style drift across 3,000 cards
- generating copyrighted franchise characters
- relying on unreviewed text inside images

## 13. Proper-name fallback

If an interest is IP-sensitive:

1. keep canonical/localized text label
2. use abstract visual family
3. avoid logo/character/poster
4. use genre/category motifs

Example:

A named movie may use an abstract cinema/story scene rather than copying its poster.

## 14. Localization gate

Before a full 3,000-card manifest is considered complete:

- generic interests require explicit zh-Hant and zh-Hans labels
- established proper-name translations may be used
- native proper names may remain native where appropriate
- search aliases remain multilingual

Generation tooling should output an audit:

- missing zh-Hant generic leaf
- missing zh-Hans generic leaf
- visual family missing
- card number missing/duplicate
- unsupported art policy

Do not hide missing translation by rendering English on every card.

## 15. Card numbering

Maintain a persistent registry.

Rules:

- number assigned once
- deleted/deprecated card number not silently reused
- new interests append new numbers
- edition/finish does not change base card number

## 16. Build pipeline

Recommended steps:

1. load interest catalog
2. load localization audit
3. load card metadata overrides
4. resolve category fallback
5. resolve visual family
6. validate art policy
7. assign/read stable card number
8. compute visual seed
9. emit recipe
10. render sample preview
11. run collision/missing-metadata audit
12. publish versioned manifest

## 17. CI gates

CI should fail on:

- duplicate card number
- duplicate canonical card definition
- empty visual family
- unknown category kit
- unstable seed fixture
- edition referencing unknown definition
- finish referencing unknown finish
- generic leaf missing required localization once localization gate is enabled

CI should not require 3,000 raster images.

## 18. Initial proof batch

Before full catalog rendering:

- 50 representative cards
- at least 12 categories
- 6 finish treatments
- Core + Encounter
- English + zh-Hant + zh-Hans
- proper-name/IP-sensitive samples

The original concept direction should be preserved in this review batch.

Recommended samples include:

- Badminton
- Basketball
- Bouldering
- Sushi
- Coffee
- Japan
- Film/Cinema
- Piano
- Photography
- Gaming
- Yoga
- DIY/Crafts

## 19. Scaling estimate

The expensive part should be art-system design, not number of interests.

A realistic scalable foundation is:

- 12–16 category kits
- 50–100 scene grammars
- 100–200 core emblems
- 200–400 motif fragments
- 6 finish definitions
- 4–6 edition seals

That is enough to support thousands of combinations.

## 20. Next implementation step

Do not generate the whole catalog yet.

First implement:

- manifest schema
- category-kit registry
- deterministic recipe resolver
- 12 representative recipes
- SVG/Canvas preview proof
- CI seed/metadata tests

Only then expand to 50 cards and review visual quality.

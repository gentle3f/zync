# Zync — Bulk Localization Stage C

Date: 2026-09-22
Branch: `card-art-pilot-v1-20260921`

Read `AI_STATE/OPERATING_RULES.md` before writes. Vercel remains disabled for
this branch. Keep GitHub Actions, Production, Play and image generation closed.

## Semantic correction

Localization exposed a genuine duplicate that English string checks had missed:

- new Part 16 `gaming.city_building_games` = "City-Building Games"
- existing `gaming.subgenre.city_builder` = "City Builder"

Their French, Portuguese, Japanese and Korean labels naturally collapse to the
same concept. The new Part 16 row was removed instead of inventing artificial
translations. `City-Building Games` is now an alias of the stable existing ID.

Runtime canonical count is therefore **4,053**.
Part 16 is now **118** canonicals.

## Localization progress

Stage C adds:
- music: **294 / 294** legacy generic concepts
- gaming: **237 / 237** legacy generic concepts

Music QA found one real Korean homograph collision:
- Punk and Funk both commonly render as `펑크`
They are explicitly disambiguated as `펑크(Punk)` and `펑크(Funk)`.

Gaming QA also distinguished:
- generic video-game Deckbuilding vs Deck-Building Board Games in French
- Collectible Card Games vs Trading Card Games in Portuguese

After the City Builder dedupe and Stage C translations:

- **3,361 / 4,053** canonical interests are explicit in all 8 locales
- remaining debt for each `es/fr/pt/ja/ko`: **692 generic rows**
- zh-Hant / zh-Hans: complete

All music and gaming locale collision audits: **0 after corrections**.

## New data files

- `mobile/lib/core/interest_locale_music_a.dart`
- `mobile/lib/core/interest_locale_music_b.dart`
- `mobile/lib/core/interest_locale_gaming_a.dart`
- `mobile/lib/core/interest_locale_gaming_b.dart`
- `mobile/lib/core/interest_locale_gaming_c.dart`

## Remaining 692

1. learning — 204
2. entertainment — 183
3. technology/crafts/business/collecting/career/pets/transport/fashion/science/motorsport — 305

Continue in deterministic locale-overlay batches with collision QA. Do not
claim full completion until all five remaining locale debts are zero.

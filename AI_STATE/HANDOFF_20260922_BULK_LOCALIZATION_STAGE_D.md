# Zync — Bulk Localization Stage D

Date: 2026-09-22
Branch: `card-art-pilot-v1-20260921`

Read `AI_STATE/OPERATING_RULES.md` before writes. Vercel remains disabled for
this branch. Keep GitHub Actions, Production, Play and image generation closed.

## Runtime

- canonical interests: **4,053**
- Part 16: 118
- USA + Hong Kong co-primary sector ranking remains active

## Localization progress

Stage D adds full es/fr/pt/ja/ko localization for:

- Learning: **204 / 204**
- Entertainment generic concepts: **183 / 183**

Together: 387 concepts / 1,935 new semantic labels.

Current eight-locale completion:
- **3,748 / 4,053 = 92.5%**
- remaining debt per es/fr/pt/ja/ko: **305 generic rows**
- zh-Hant / zh-Hans: complete

Learning source-set verification:
- source IDs: 204
- translated IDs: 204
- missing: 0
- extra: 0
- collisions: 0

Entertainment source-set verification:
- source IDs: 183
- translated IDs: 183
- missing: 0
- extra: 0

Entertainment locale QA found and fixed:
- Korean Anime vs Animation collision:
  `일본 애니메이션` vs `애니메이션 장르`
- Spanish/Portuguese Costume Drama vs Period Drama collision:
  costume drama now explicitly refers to historical costume drama

Post-fix Entertainment collisions: **0**.

## New files

- `mobile/lib/core/interest_locale_learning_a.dart`
- `mobile/lib/core/interest_locale_learning_b.dart`
- `mobile/lib/core/interest_locale_entertainment_core.dart`
- `mobile/lib/core/interest_locale_entertainment_movie_a.dart`
- `mobile/lib/core/interest_locale_entertainment_movie_b.dart`

## Final remaining 305

Categories still to translate:
technology, crafts, business, collecting, career, pets, transport, fashion,
science, motorsport and any other small generic category not yet covered.

Next milestone should finish all 305, run a full 4,053 × 8-locale completeness
audit and per-locale same-category collision audit, then make full localization
a hard release gate.

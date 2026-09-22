# Zync — Bulk Localization Stage A

Date: 2026-09-22
Branch: `card-art-pilot-v1-20260921`

Read `AI_STATE/OPERATING_RULES.md` before any write. Vercel remains disabled for
this branch; do not open CI, Production, Play or image generation unless needed.

## Runtime

- canonical interests: 4,054
- Part 16: 119 / 119 eight-locale complete
- USA + Hong Kong remain co-primary launch sectors
- ranking/diversity logic from the previous checkpoint remains active

## Localization progress

Supported locales:
`en, zh-Hant, zh-Hans, es, fr, pt, ja, ko`

Stage A adds:

1. **1,910 proper-name/title/artist/destination/brand rows**
   - existing curated Chinese names are preserved
   - otherwise official/original names are explicitly repeated rather than
     machine-inventing a fake local title
2. **473 high-priority generic legacy concepts** translated semantically into
   Spanish, French, Portuguese, Japanese and Korean:
   - sports: 85
   - outdoors: 79
   - wellness: 42
   - arts: 88
   - lifestyle: 76
   - travel: 103

Together with Part 16, **2,502 / 4,054 canonical rows are now explicit in all
8 supported locales**.

Chinese is explicit for all 4,054 rows after the proper-name overlay.
Remaining debt for each of es/fr/pt/ja/ko is exactly **1,552 generic rows**.

All Stage A localized labels were checked for same-category collisions:
**0 collisions**.

## Files

- `mobile/lib/core/interest_locale_proper_names.dart`
- `mobile/lib/core/interest_locale_generic_launch_v1.dart`
- `mobile/lib/core/interest_locale_generic_launch_v2.dart`
- `mobile/lib/core/interest_locale_generic_launch_v3.dart`
- registry: `mobile/lib/core/interest_localization.dart`

## Next continuation

Translate the remaining 1,552 generic rows, prioritizing:
1. food
2. music
3. gaming
4. learning
5. entertainment
6. technology/crafts/business/collecting/career/pets/transport/fashion/science/motorsport

Use the same `id|es|fr|pt|ja|ko` format and collision-audit every batch.
Do not claim full completion until all five remaining locale debts are zero.

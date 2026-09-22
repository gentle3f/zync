# Zync — Bulk Localization Stage B

Date: 2026-09-22
Branch: `card-art-pilot-v1-20260921`

Read `AI_STATE/OPERATING_RULES.md` before writes. Vercel remains disabled for
this branch. Keep GitHub Actions, Production, Play and image generation closed.

## Localization progress

Runtime canonical count: **4,054**

Eight-locale complete:
- previous Stage A: 2,502
- Food added in Stage B: 329
- **current total: 2,831 / 4,054**

Remaining debt in each of `es/fr/pt/ja/ko`: **1,223 generic rows**.
Chinese remains explicit for all 4,054 rows.

Stage B translated all 329 legacy Food concepts:
- base food/café/cuisine concepts
- cooking and baking activities
- 77 deep cuisine families
- dishes
- drinks and coffee/tea culture
- food social/activity concepts

Food translation collision audit: **0 same-category collisions**.

## Data files

- `mobile/lib/core/interest_locale_food_a.dart` — 139 rows
- `mobile/lib/core/interest_locale_food_b.dart` — 190 rows

## Next

Continue:
1. music — 294
2. gaming — 237
3. learning — 204
4. entertainment — 183
5. remaining smaller categories — 305

Use `id|es|fr|pt|ja|ko`, audit every batch, and do not claim full completion
until each locale debt reaches zero.

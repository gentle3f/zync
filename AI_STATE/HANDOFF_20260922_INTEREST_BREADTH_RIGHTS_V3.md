# Zync — Interest Breadth / Rights Catalog V3 Handoff

Date: 2026-09-22  
Branch: `card-art-pilot-v1-20260921`  
Audit report: `tools/card_art/report/INTEREST_RIGHTS_CATALOG_AUDIT_V3.md`

## Hard boundaries

- Production CLOSED.
- Google Play CLOSED.
- Image generation CLOSED.
- Do not spend image API credits.
- Owner has set GitHub Actions $0 hard-budget / stop-usage.
- Do not open a PR merely to obtain CI before the 2026-10-01 reset.
- Do not push `zync-v1-rebuild-20260917` before reset unless an emergency requires it.

## Current catalog state

- Canonical interests: **3,935**
- Net growth from V2: **+441**
- Duplicate canonical IDs: **0**
- Same-category normalized search collisions: **0**
- New top-level world: `career` / Careers & Professions
- 444-query everyday-interest benchmark: **444/444 = 100% exact-or-alias resolvable** by static parser

The point of V3 is not raw count. The everyday/offline layer was genuinely thin despite the earlier 3,494 total because media/title/artist depth dominated. V3 fills movement, dance, outdoors, crafts/making, local Asian life, social/community, home/family, pets, campus and professional-community gaps.

## Major behavior fixes now complete

### Cross-category disambiguation
- `exactMatches()` returns all exact candidates.
- `exact()` returns only a unique exact candidate.
- `instantSelection()` refuses ambiguous exact terms.
- Setup search shows candidates instead of silently first-winning.

### Grey-zone rights
These are now `abstractOnly`:
- Python
- JavaScript
- Linux
- BookTok
- BookTube
- Bookstagram
- UNESCO Heritage Travel

They remain baseline-art eligible, but baseline art must avoid official marks/logos/endorsement cues.

### Rights count
- total: 3,935
- licensedOnly: 1,843 (46.8%)
- baseline-art eligible: 2,092 (53.2%)

No new V3 everyday interests were added to the partner-only licensed sets.

## Durable new test

`mobile/test/interest_catalog_everyday_benchmark_test.dart`

Contains 444 common natural query phrases and requires every phrase to resolve through `InterestCatalog.exactMatches`.

The test file is committed but NOT run yet because hosted Actions are being conserved.

## Important product conclusion

Do NOT keep expanding merely to hit 4,000+.

Further additions should require evidence of a real coverage gap. The next problem is discoverability/UX over 3,935 interests, not raw catalog quantity.

Sensitive areas are deliberately deferred for separate privacy review:
- politics
- religion
- medical / mental-health conditions
- disability / diagnosis communities
- other sensitive identity attributes

## Recommended continuation

1. Audit onboarding/browse UX and popularity/ranking with the 3,935 catalog.
2. Check that new `career`, `campus`, `local_culture`, `dance`, `performance`, `media_creation` taxonomy is understandable in Hong Kong Traditional Chinese.
3. Re-audit Zync Now activity resolver coverage for generic V3 interests; do not auto-enable unsafe or semantically wrong activities.
4. Re-audit card-art prompt recipes against the expanded generic baseline-art set.
5. Keep image generation closed.
6. After 2026-10-01, run targeted Flutter analyze/tests and Android validation before opening any image generation or release path.

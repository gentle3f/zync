# Zync — US/HK Ranking + Part 16 Localization V1

Date: 2026-09-22
Branch: `card-art-pilot-v1-20260921`

## Mandatory operating rule

Read `AI_STATE/OPERATING_RULES.md` before any write. Keep Vercel, GitHub Actions,
Production, Play and image generation closed unless genuinely required. Batch writes.

## Runtime checkpoint

This checkpoint activates catalog Part 16.

- previous canonical count: 3,935
- Part 16 additions: 119
- expected runtime canonical count: **4,054**
- generic USA-first survivors: 113
- broad missing parents: Visual Arts, Dance
- HK youth/social gaps added: Study Cafes, Painting Socials, Pop-up Markets,
  Photo Booths, Late-night Eats
- 15 previously duplicate concepts resolve through alias additions instead of new IDs
- rights-gated platform/sports-brand layers remain deferred and CLOSED

## Launch sectors

USA and Hong Kong are co-primary launch sectors.

Ranking is no longer raw legacy rank + a cultural bonus. It now combines:

1. legacy rank as a 55% prior
2. 16–30 launch-audience identity fit
3. region affinity
4. real-world/social actionability
5. diversity reranking

Broad discovery caps one category at 3 of the first 12 and 6 of the first 30,
with cluster caps so sports or any other legacy rank block cannot dominate.

USA intentionally lifts American Football, college/campus life, state parks,
basketball/baseball/pickleball, game nights and car-meet culture without
turning discovery into a sports wall.

Hong Kong intentionally lifts hiking, badminton, gym, Japan travel, Cafe
Hopping, K-Pop/Cantopop, photography, board games, bouldering, karaoke,
local events and run-club style activity without turning discovery into a
Hong-Kong-food list.

## Localization architecture

Canonical IDs remain language-neutral and stable.

New registry:
`mobile/lib/core/interest_localization.dart`

Certification data:
`mobile/lib/core/interest_locale_part16.dart`

Supported interest locales:
`en, zh-Hant, zh-Hans, es, fr, pt, ja, ko`

Part 16 has explicit display labels for all 8 locales. Locale-aware search uses
the current locale label + locale aliases + English/global aliases. Runtime
fallback remains for safety, but fallback does not count as translation
completion.

The full legacy 3,935 catalog is NOT yet fully translated into es/fr/pt/ja/ko.
That bulk migration is the next localization milestone. The audit now exposes
missing IDs per locale so the debt is measurable rather than hidden.

## Translation debt after this checkpoint

Part 16: 119 / 119 eight-locale complete.

Legacy catalog:
- English remains complete.
- existing Chinese translations remain preserved.
- es/fr/pt/ja/ko bulk coverage is still pending for the pre-Part-16 catalog.

Do not claim the whole 4,055 catalog is eight-locale complete until the audit
reports zero missing IDs for every supported locale.

## Next continuation order

1. Run/inspect static tests for the new Part 16 and locale registry without
   enabling broad CI churn.
2. Bulk-translate the remaining legacy 3,935 canonicals using the same overlay
   schema, in deterministic batched data files.
3. For every locale batch: same-category label/alias collision audit before
   activation.
4. Preserve official/common names for proper names; never invent literal
   translations for brands/titles with no established local form.
5. After all 4,054 rows pass the eight-locale audit, make full-locale
   completion a hard release gate.
6. Only then resume rights-gated platform/sports ecosystem additions and
   expanded card-art prompt compilation.

## Final semantic-dedupe correction

`Life Simulation Games` was removed as a new Part 16 canonical because the existing
`gaming.subgenre.life_sim` (`Life Sim`) already represents the same concept. The phrase
is now an alias of that stable ID. `RV Life` Simplified Chinese was also changed to
`房车旅居生活` to avoid collision with the existing Van Life label.

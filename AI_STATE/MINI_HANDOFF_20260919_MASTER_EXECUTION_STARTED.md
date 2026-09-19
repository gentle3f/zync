# Zync — Mini Handoff — 2026-09-19 Master Execution Started

Branch: `zync-v1-rebuild-20260917`

This checkpoint marks the transition from product planning into implementation of the new Zync architecture.

## Canonical new design docs

Created:

- `docs/ZYNC_INTEREST_GRAPH_AND_ENTITY_MODEL.md`
  - commit `2d7cf5c5969751bf28439e15047654e4570af71b`
- `docs/ZYNC_NOW_DECISION_ENGINE_SPEC.md`
  - commit `5b2ec84f769fb6ed47269cd3f3403f2632bf1659`
- `docs/ZYNC_GROUP_ZYNC_SPEC.md`
  - commit `17e988320332ba8c573bbf947e32281627f61c84`

The master roadmap is:

- `docs/ZYNC_MASTER_EXECUTION_PLAN.md`

Zync Now is explicitly group-native: `N >= 2`.

Phase 1 Zync Now solves **what should we do together?** and does not recommend specific restaurants, venues, shops, brands or destinations.

## Foundation implementation started

Created:

- `mobile/lib/core/interest_entity_metadata.dart`
- `mobile/lib/core/activity_templates.dart`
- `mobile/test/interest_entity_metadata_test.dart`

Key implementation rules:

- existing `InterestDefinition` remains the canonical V1 identity;
- metadata is additive;
- exact shared interests remain canonical-ID equality only;
- richer entity types / activity / card data sit around the current catalog rather than replacing it;
- first metadata entries are representative only, not full-catalog completion;
- reusable activity templates provide deterministic Zync Now fallback before AI;
- Cardverse metadata includes art-policy separation so named IP / brands do not imply copied artwork.

Representative metadata currently covers:

- sports.badminton
- sports.tennis
- sports.running
- sports.hiking
- outdoors.bouldering
- food.coffee
- collecting.lego
- motorsport.formula1

The initial activity template registry has 7 reusable template families.

A type mismatch in the first metadata draft was caught immediately and fixed in:

`a28905e6843e1194ac4ac9fc59d9f28016535921`

## Localization work started

`mobile/lib/core/interest_catalog_part1.dart` received a large first translation batch:

- 115 generic sports / outdoors / wellness leaves now have explicit zh-Hant and zh-Hans display labels.
- audit after the edit found 124 catalog rows, 0 malformed rows and 0 remaining missing zh-Hant / zh-Hans rows in Part 1.

Commit:

`3369604ba735d0fe44cc76e05a3c02b8ef8332be`

This does **not** mean all 3,000+ leaves are translated yet. Parts 2–10 still require systematic audit / localization, with proper names handled differently from generic interests.

## Current active continuation

Continue Milestone 1 foundation in this order:

1. audit catalog Parts 2–10 for generic missing zh-Hant / zh-Hans labels;
2. build a classification / validation approach that distinguishes generic translation-required leaves from proper-name/native-name exceptions;
3. expand activity metadata beyond the first representative interests;
4. implement the first actual group-native Zync Now candidate model only after the metadata shape proves stable;
5. keep the existing two-person Zync exact-match and QR semantics unchanged.

Do not jump to Cardverse full rendering, Group Zync UI, cloud accounts or another APK yet.

Production and Play remain closed.

# Zync — Card Art Rights / Catalog Audit V2 Handoff

Date: 2026-09-22  
Branch: `card-art-pilot-v1-20260921`  
Head before this handoff: `760e2e78f3b3f730fe371b6ecb6820a10c5457a1`

## Hard boundaries

- Production CLOSED.
- Google Play CLOSED.
- Do not generate card images yet.
- Do not spend image API credits yet.
- Temporary PR #1 is CLOSED and NOT MERGED.
- Do not push `zync-v1-rebuild-20260917` before the Actions reset unless absolutely necessary.
- Do not open a PR from the card-art branch merely to obtain CI before the reset.

## Why GitHub Actions is currently constrained

Owner received a 90% usage alert:
- 1,820 / 2,000 included minutes consumed.
- 180 included minutes remain.
- Reset: 2026-10-01.

The old QA branch had both push-triggered workflows and an open temporary PR, so relevant commits could incur both push and pull-request workflow activity. PR #1 has now been closed to remove the PR side of that duplicate-trigger risk.

Current card-art branch commits have zero observed GitHub Actions workflow runs because:
- push filters target `zync-v1-rebuild-20260917`, not this branch;
- this branch has no open PR.

Continue static policy/catalog work here without GitHub-hosted CI until reset. The account owner should also create an Actions $0 hard budget / Stop usage guard in GitHub Billing.

## Authoritative audit report

Read in full before continuing:

`tools/card_art/report/INTEREST_RIGHTS_CATALOG_AUDIT_V2.md`

That report contains the detailed catalog, rights, duplicate, search, and validation state.

## Current catalog state

Canonical interests: **3,494**

Earlier handoff count was 3,505. Eleven duplicate canonicals were removed while preserving searchability through older/stable IDs or aliases.

Static normalized same-category search-term collisions: **0**

Intentional cross-category ambiguities remain and should be disambiguated rather than merged:
- Minimalism
- Persona
- East of Eden
- The Last of Us
- The Handmaid's Tale
- Three-Body / 三體
- Genesis
- Perfume

## Common-interest benchmark recovery

The old release audit had 27 missing common-interest queries.

Current static search reproduction:
- 27 / 27 previously missing queries now resolve.
- Each resolves at exact normalized label/alias score 0.

The original complete 201-query benchmark script is not present in repo, so do not claim a literal full-script rerun. The old 174 passing concepts were not removed by this cleanup.

## Rights/card-policy state

Static result:
- `licensedOnly`: **1,843 / 3,494 = 52.7%**
- baseline-art eligible: **1,651 / 3,494 = 47.3%**

Clear legacy false negatives fixed as partner/rightsholder-only card art:
- JoJo's Bizarre Adventure
- CrossFit
- ChatGPT
- Android
- Apple Products
- MotoGP
- Formula E
- World Endurance Championship
- Le Mans
- Disney Parks Travel
- Universal Studios Travel

These remain searchable/matchable interests; branded baseline collectible art is held.

## Important resolver fixes

1. Explicit `notCollectible` / `collectible: false` metadata is now honored. It can no longer silently fall through to generic baseline art.

2. `InterestActivityResolver` now consumes the rights-aware card boundary before generic taxonomy defaults. Rights-sensitive titles/brands do not accidentally become generic activities merely because localization is complete. Explicit curated activity metadata still wins.

## Grey-zone rights work still open

Do not over-classify these yet:
- Python
- Linux
- JavaScript
- BookTok / BookTube / Bookstagram
- UNESCO Heritage Travel

Need decide whether each should be:
- generic original art,
- `abstractOnly` with no official marks/logos,
- attribution-aware,
- or `licensedOnly`.

This should be a product-rights decision based on actual mark/brand rules, not a blanket “all trademarks are blocked” rule.

## Validation status

Static audits completed:
- exact parser recount;
- normalized collision audit;
- rights coverage count;
- 27 previous missing-query check;
- current-branch Actions-run check.

Full Flutter validation intentionally deferred to conserve Actions:
- no full `flutter analyze`;
- no full `flutter test`;
- no Android build;
- no full CI certification.

Do not treat static audit as full Flutter certification.

## Latest material commits in this continuation

- `1f2d6c9` — honor explicit non-collectible card policy
- `e162d72` / `a5c48b3` / `07e63e8` — remove duplicate Brunch/Cafe Hopping canonicals and keep social activities on old IDs
- `0a9647a` / `09c8d37` — classify clear legacy brands/titles and block rights-sensitive generic activities
- `7da63f1` through `b10d4e7` — canonical collision and localization cleanup
- `9e05a1b` — distinguish Canoeing from Kayaking
- `7715fc9` — reserve branded theme-park travel cards
- `78587b7` — test gate for same-category normalized search-term collisions
- `760e2e7` — audit V2 report

## Recommended continuation order

1. Resolve the grey-zone technology/platform/travel mark policy.
2. Implement explicit cross-category search disambiguation for the remaining true ambiguities.
3. Re-audit Social / Wellness / Lifestyle depth after canonical cleanup.
4. Keep image generation closed.
5. After the 2026-10-01 Actions reset, run targeted Flutter analyze/tests before expanding card prompt recipes or generating images.

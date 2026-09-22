# Zync — USA Spanish + Hong Kong Alias Pack V1

Date: 2026-09-23
Branch: `card-art-pilot-v1-20260921`

Read `AI_STATE/OPERATING_RULES.md` before any write. Vercel remains disabled
for this branch. Keep GitHub Actions, Production, Play and image generation
closed unless genuinely required.

## Starting point

Eight-locale display-label localization is already complete:

- canonical interests: 4,053
- explicit display labels: 4,053 / 4,053
- locales: en / zh-Hant / zh-Hans / es / fr / pt / ja / ko
- same-category display-label collisions: 0

This checkpoint improves **search aliases**, not display labels.

## Launch-sector alias V1

New file:

`mobile/lib/core/interest_locale_aliases_launch_v1.dart`

Scope:
- USA Spanish: **83 id-locale rows**
- Hong Kong Traditional Chinese: **80 id-locale rows**
- total rows: **163**
- total alias terms after QA: **294**

The pack targets high-value launch identities and colloquial search language,
not exhaustive alias translation.

Examples:

USA Spanish:
- `básquet` -> Basketball
- `boba` -> Bubble Tea
- `tiendas de segunda mano` -> Thrifting
- `fútbol americano universitario` -> College Football
- `club de running` -> Run Clubs

Hong Kong:
- `行山` -> Hiking
- `打機` -> Video Games
- `唱K` -> Karaoke
- `打邊爐` -> Hot Pot
- `夾公仔` -> Claw Machines
- `兄弟會` / `姊妹會` -> Greek Life

## Registry behavior improvement

Localized alias packs now **merge and deduplicate** by canonical ID + locale
instead of later packs overwriting earlier packs.

This matters because some Part 16 aliases are extended by this launch pack.
For example Sports Watch Parties keeps the original aliases and gains:
- Spanish: `ver el partido`, `fiesta para ver el partido`
- zh-Hant: `睇波`, `觀賽聚會`

## QA

Candidate IDs:
- unknown IDs: 0

Candidate pack:
- internal same-category collisions: 0

Candidate aliases vs all 4,053 canonical English/global aliases/IDs:
- same-category collisions: 0

Candidate aliases vs localized display labels:
- one real collision found during drafting:
  - Spanish `postres` was already the display label for `food.desserts`
  - it was removed from `food.dessert_hunting`
  - retained precise `ruta de postres`
- post-fix collisions: 0

Candidate aliases + existing Part 16 localized aliases, cross-locale:
- alias terms audited: 341
- same-category collisions: 0

The catalog ambiguity test is strengthened to include
`InterestLocaleRegistry.allLocalizedAliases(item.id)`, making localized alias
ambiguity a permanent hard gate.

## Infrastructure

Before checkpoint:
- current branch HEAD: `5f8e1ab5311f0cd6efab0d986409cd67a538f271`
- GitHub Actions runs for that HEAD: 0
- Vercel deployment for this branch: disabled
- no workflow references to this branch were found
- no Production / Play / image-generation action is required

## Important scope

This is **V1 high-value alias coverage**, not exhaustive alias localization for
all 4,053 interests.

Next useful alias work should be driven by real failed-search telemetry or a
second gap audit, rather than translating every English alias mechanically.

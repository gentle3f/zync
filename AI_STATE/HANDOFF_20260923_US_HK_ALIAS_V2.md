# Zync — USA Spanish + Hong Kong Alias Pack V2

Date: 2026-09-23
Branch: `card-art-pilot-v1-20260921`

Read `AI_STATE/OPERATING_RULES.md` before any write. Vercel remains disabled
for this branch. Keep GitHub Actions, Production, Play and image generation
closed unless genuinely required.

## Starting point

- runtime canonical interests: 4,053
- display labels: complete in all 8 supported locales
- localized alias V1: 163 id-locale rows / 294 terms
- V1 same-category collisions: 0

## V2 priority-gap audit

The launch-priority universe was rebuilt from:
- `_audienceHigh`
- `_audienceMedium`
- `_audienceLight`
- explicit USA regional boosts
- explicit Hong Kong / Macau regional boosts

Unique high-priority interests: **97**.

Before V2:
- 81 / 97 already had localized alias rows for both Spanish and zh-Hant
- Spanish localized-alias gaps: 13
- zh-Hant localized-alias gaps: 12

Those counts do **not** mean the remaining interests were unsearchable. Every
interest already has a localized display label, and English/global aliases are
also indexed. V2 only adds a row where a materially different colloquial or
alternate query is useful.

Examples deliberately *not* duplicated:
- Cantonese Food already has `廣東菜 / 粵菜` coverage
- Dim Sum already has `點心`
- Coffee already has `咖啡`
- Cantopop already has global alias `廣東歌`

## V2 additions

New file:

`mobile/lib/core/interest_locale_aliases_launch_v2.dart`

Scope:
- 19 id-locale rows
- 34 alias terms
- Spanish: 11 rows
- Hong Kong Traditional Chinese: 8 rows

Examples:

Spanish:
- `ir de compras` -> Shopping
- `foto callejera` -> Street Photography
- `fans del fútbol americano` -> American Football Fandom
- `viajar a Corea` -> South Korea Travel
- `senderismo de noche` -> Night Hiking

Hong Kong:
- `韓舞` -> K-Pop Dance
- `美妝` -> Makeup
- `護膚` -> Skincare
- `街拍` -> Street Photography
- `市區行山` -> Urban Hiking
- `去韓國` -> South Korea Travel

Combined launch alias packs:
- **182 id-locale rows**
- **328 alias terms**

## QA

V2 candidate:
- rows: 19
- terms: 34
- duplicate id-locale rows: 0

Against catalog source Parts 1–8:
- same-category collisions: 0

Against catalog source Parts 9–16:
- same-category collisions: 0

Against localized display labels / V1 / Part 16 aliases, first half:
- collisions: 0

Against localized display labels, second half:
- collisions: 0

The existing permanent ambiguity test already includes
`InterestLocaleRegistry.allLocalizedAliases(item.id)`, so V2 is covered by the
hard same-category search-term gate.

Regression searches were added for representative V2 terms.

## Infrastructure before checkpoint

- branch HEAD: `d970d773130411fc5ca0e6864b6365bb671a3290`
- GitHub Actions for that HEAD: 0
- Vercel deployment for this branch: disabled
- Production / Play / image generation untouched

## Next

Do not blindly translate all remaining aliases.

The next useful search-quality work is:
1. broaden high-value **US Spanish** variants outside the top-97 launch set,
   especially food, fitness, social activities, pets and cars;
2. broaden **Hong Kong Cantonese / English-mixed** variants outside the top-97,
   especially local food, nightlife/social, fitness, travel, photography and
   campus life;
3. prioritize queries that differ materially from the localized display label;
4. use failed-search telemetry once available to drive V3.

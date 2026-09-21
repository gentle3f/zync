# Zync Interest Catalog Release-Readiness Audit V1
Date: 2026-09-21
Branch: `card-art-pilot-v1-20260921`

## Executive result

The catalog is **large enough for public release by raw volume**, but it is **not yet release-clean**.

The main issue is not quantity. It is the balance between extremely deep media/entity coverage and a smaller set of missing everyday interests / search aliases, plus a handful of exact-search collisions and near-duplicate canonical concepts.

### Correct canonical count

The current app catalog contains **3,403 canonical interests**, not ~2,032.

The earlier ~2,032 estimate came from counting visible raw rows and missed many entries created through repeated `parseInterestFamily(...)` blocks. This audit reproduced the catalog parser logic, including its explicit legacy-skip rules.

## Category balance

| Category | Count |
|---|---:|
| music | 801 |
| entertainment | 779 |
| gaming | 721 |
| learning | 332 |
| food | 301 |
| travel | 178 |
| sports | 61 |
| outdoors | 43 |
| technology | 27 |
| arts | 25 |
| wellness | 20 |
| transport | 17 |
| collecting | 16 |
| lifestyle | 16 |
| crafts | 13 |
| business | 13 |
| fashion | 12 |
| science | 10 |
| motorsport | 9 |
| pets | 9 |

Music + entertainment + gaming = **2,301 / 3,403 = 67.6%** of all canonical entries.

This is largely intentional depth, but the raw count therefore overstates everyday-hobby breadth.

## Named-entity / title depth

Approximately **1,694 / 3,403 (49.8%)** entries are in obvious artist/title/franchise-heavy clusters, including:
- game franchises
- music artists
- movie titles
- TV titles
- anime titles
- board-game titles
- book titles

That leaves about **1,709 non-entity / broader interests**.

The catalog is therefore not "too small"; it is **media-heavy**.

## Search coverage benchmark

A 201-query common-interest benchmark was run using the app's actual search semantics:
- exact term
- starts-with
- token starts-with
- contains
- normalized ID
- category fallback

Result:

**174 / 201 = 86.6% query coverage**

### Strong areas
- music: 10/10
- travel: 10/10
- gaming: 10/10
- pets: 9/9
- sports: 19/20
- food: 13/14
- technology: 11/12
- outdoors: 11/12

### Weaker everyday areas
- social: 9/14
- wellness: 6/10
- entertainment-format discovery: 7/10
- fashion/beauty: 9/11
- collecting search aliases: 9/11

## Missing common search terms

The following common benchmark queries currently return no catalog result under the app search rules:

### Sports
- triathlon

### Creative / making
- pottery
- model making
- scrapbooking
- creative writing

### Food
- food photography

### Outdoors
- foraging

### Social / lifestyle
- parties
- clubbing
- shopping
- thrifting
- flea markets

### Learning
- personal development
- debating

### Technology
- PC building

### Fashion / beauty
- hair styling
- fragrance

### Collecting
- figurines
- model cars

### Transport
- driving

### Entertainment formats
- stand-up comedy
- podcasts
- YouTube

### Wellness
- massage
- nutrition
- self care
- healthy eating

## Some misses are alias problems, not missing concepts

These should probably be solved with aliases rather than creating duplicate canonical interests:

- `pottery` -> existing `arts.ceramics`
- `model making` -> existing `crafts.model_building`
- `clubbing` -> existing `lifestyle.nightlife`
- `figurines` -> existing `collecting.action_figures`
- `model cars` -> existing `collecting.diecast_cars`
- `fragrance` may map to perfume-related interests, but product semantics should decide whether it means collecting, wearing/appreciation, or both

## Common concepts that appear genuinely absent

High-priority candidates for explicit canonical interests or broader aliases:
- Podcasts
- YouTube / online video viewing
- Stand-up Comedy
- Triathlon
- Shopping
- Thrifting
- Flea Markets
- Creative Writing
- Scrapbooking
- Foraging
- Debate / Debating
- PC Building
- Driving
- Massage
- Nutrition
- Self-Care
- Healthy Eating

Product review should decide whether some of these are interests worth matching on versus merely activities.

## Exact-term collisions

Across labels and aliases, the audit found:
- **32 duplicated normalized search terms**
- **7 cross-category collisions**
- **25 same-category collisions**

Cross-category examples:
- Minimalism -> lifestyle vs music style
- Persona -> film vs game
- East of Eden -> film vs book
- The Last of Us -> TV vs game
- The Handmaid's Tale -> TV vs book
- 三體 / 三体 -> TV vs book

These are legitimate different concepts, but `InterestCatalog.exact()` uses first-wins semantics. Exact free-text selection can therefore choose one medium silently when the user's term is ambiguous.

### Recommendation
For an exact term with multiple canonical concepts:
- show the user the disambiguated choices, or
- require category/medium selection,
- do not silently collapse to first-wins for user-entered exact text.

## Same-category collision / duplicate-risk examples

Several terms suggest likely duplicate or overly overlapping canonical concepts:
- Road Trips vs Road Tripping
- Cruises vs Cruise Travel
- Romance Books vs Romance Novels
- Biographies vs Biography
- Dream Pop vs Dreamy Pop
- Lo Ta-yu vs Tayu Lo
- Soup Dumplings vs Xiaolongbao
- Drawing vs Painting sharing broad Chinese aliases

Not every collision is a duplicate, but these require a semantic cleanup before relying on canonical IDs for matching, achievements, and card ownership.

## Localization

Overall missing zh-Hant / zh-Hans labels look high because many artist/title/franchise entities intentionally retain native/English names.

After excluding obvious title/artist/franchise-heavy clusters:
- non-entity entries: ~1,709
- missing explicit zh-Hant / zh-Hans labels: ~111
- non-entity localization gap: ~6.5%

Most of those 111 are still named products/TTRPGs/travel destination names with aliases, so generic-concept localization is materially better than the raw total suggests.

Still, launch QA should test Hong Kong search terms directly rather than relying only on display-label completeness.

## Release recommendation

### Raw quantity
**PASS** — 3,403 is more than sufficient.

### Breadth
**CONDITIONAL PASS** — the catalog covers most common interests, but media depth hides several everyday gaps.

### Search discoverability
**NEEDS PATCH** — target aliases/new entries for the missing high-frequency terms above.

### Canonical uniqueness
**NEEDS PATCH** — review same-category duplicate-risk pairs.

### Exact-term ambiguity
**NEEDS UX FIX OR EXPLICIT ACCEPTANCE** — first-wins exact matching can silently select the wrong medium.

## Recommended pre-release remediation

Do a small targeted catalog pass, not another giant expansion.

1. Add aliases for obvious synonym gaps.
2. Add ~15-25 genuinely missing everyday interests.
3. Resolve obvious duplicate canonical concepts.
4. Add disambiguation behavior for cross-category exact collisions.
5. Re-run the same 201-query benchmark.
6. Target **>=95% common-interest search coverage** before broad public release.
7. After launch, use zero-result searches and repeated custom interests to decide future additions.

## Card-art implication

Do **not** create card-art recipes for all 3,403 entries until the catalog cleanup is settled.

Otherwise we may generate multiple cards for concepts that should later merge, and spend review effort on canonical interests that are not release-stable.

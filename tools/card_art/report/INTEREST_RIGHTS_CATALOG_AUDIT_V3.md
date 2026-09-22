# Zync Interest Rights / Catalog Audit V3

Date: 2026-09-22  
Branch: `card-art-pilot-v1-20260921`  
Head entering report: `347356f4ef5255cd46298b59fb8475fd805c58d1`

## 1. Executive state

- No card images generated.
- No image API credits spent.
- Production CLOSED.
- Google Play CLOSED.
- Owner has set a GitHub Actions $0 hard-budget / stop-usage guard.
- Current card-art branch remains outside the old branch push filters and has no PR.
- GitHub-hosted Flutter CI remains intentionally deferred until the 2026-10-01 allowance reset.

## 2. Catalog breadth

V2 canonical count: **3,494**.

Current canonical count after everyday/offline breadth expansion: **3,935**.

Net new canonicals since V2: **+441**.

The expansion deliberately favored interests that can describe a person, create an icebreaker, support a real-world activity/community, or later support the hobby economy. It did not pad the catalog with additional media titles merely to increase the number.

Current major category counts from the static parser:
- music: 805
- entertainment: 784
- gaming: 725
- learning: 369
- food: 329
- travel: 183
- transport: 89
- arts: 88
- sports: 85
- outdoors: 79
- lifestyle: 76
- technology: 56
- crafts: 47
- wellness: 42
- business: 40
- collecting: 34
- career: 29
- pets: 25
- fashion: 22
- science: 19
- motorsport: 9

A new top-level `career` world was added instead of forcing professional communities such as Nursing, Accounting, Engineering and Research into Business.

## 3. Everyday breadth added

Representative new areas include:

### Movement and sport
- Powerlifting, kettlebells, functional training
- Parkour, gymnastics, trampolining, cheerleading
- Aikido, capoeira, wushu, tai chi
- Ultimate Frisbee, disc golf, water polo, floorball
- Horse riding
- Gravel cycling and open-water swimming
- Dragon boat racing

### Dance
- Salsa, bachata, ballroom, swing
- hip-hop, ballet, contemporary, jazz, tap
- line dancing, K-Pop dance, Latin, belly dance, flamenco, pole dance
- square dancing and Chinese dance

### Outdoors and nature
- Forest bathing, urban exploration, caving
- fly fishing, squid fishing, river tracing
- whitewater rafting/kayaking, coasteering
- wildlife/whale/dolphin/butterfly watching
- mushroom hunting, tree/plant identification
- peak bagging, sunrise/night/urban hiking
- sport/trad climbing and kayak touring

### Crafts / making / creator economy
- Bookbinding, weaving, quilting, cross stitch, macrame, beading
- resin art, perfume making, wood carving, screen printing, linocut
- metalworking, silversmithing, pottery wheel, glazing, glassblowing
- RC vehicles, drone building, keyboard building
- watch/clock/bicycle repair and blacksmithing
- podcasting, video editing, content creation, motion graphics, webcomics, sound design and short-form video

### Social / community / local culture
- Language exchange, run clubs, supper clubs, coffee chats
- community gardening, environmental/animal volunteering
- local community, community organizing, skill sharing
- book/clothing swaps and repair workshops
- temple fairs, lantern festivals, flower markets, wet markets
- museum/gallery hopping and cultural festivals
- boat parties / Hong Kong junk-boat wording

### Food and local Asian life
- Bread/sourdough/pastry making
- fermentation, pickling, cheese/chocolate making
- tea/coffee tasting and restaurant/dessert hopping
- yum cha, dai pai dong, tea-house hopping and night markets
- healthy cooking and meal planning

### Home / family / pets
- home improvement, renovation, decluttering, zero-waste living
- balcony/urban gardening, hydroponics and furniture restoration
- parenting, playgroups, family activities and storytime
- bird/reptile/parrot/guinea-pig interests
- dog agility/grooming, wildlife rescue and horse care

### Campus and professional communities
- Model United Nations, student newspaper/radio, yearbook
- hackathons, case/startup competitions, olympiads
- mock trial, moot court, exchange programs and student societies
- legal profession/Legal Tech
- healthcare, nursing, dentistry, pharmacy and counselling
- engineering, accounting, banking, insurance and fintech
- HR/recruiting, operations, supply chain/logistics/procurement
- cloud/data engineering, biotechnology, climate tech, sustainability
- research and academia

## 4. Duplicate and collision gate

Current static result:
- Canonical IDs: **3,935**
- Duplicate IDs: **0**
- Same-category normalized label/alias/slug collisions: **0**

During expansion, false-new concepts were removed and folded into older stable canonicals, including:
- Indoor Cycling -> Spin Class aliases
- Juicing -> Fresh Juice aliases
- Cha Chaan Teng -> Hong Kong Food aliases
- Aquarium Keeping -> Fishkeeping aliases
- Game Modding -> existing Modding Games
- Photography Editing -> existing Photo Editing
- Neighborhood Events -> existing Local Events

This preserves stable identity rather than inflating the catalog.

## 5. Durable everyday-interest benchmark

A new release test now lives at:

`mobile/test/interest_catalog_everyday_benchmark_test.dart`

It contains **444 natural user query phrases** across:
- sports
- dance
- creative/crafts
- food
- social/going-out
- outdoors
- technology/maker
- learning
- career/professions
- pets
- home/lifestyle
- collecting
- Asian/local interests
- media creation
- campus/student life

Static parser verification at this checkpoint:
- **444 / 444 exact-or-alias resolvable**
- **100.0%**

This is intentionally stronger than a raw catalog-count target: common wording such as `KTV`, `robotics club`, `house parties`, `wine tasting`, `gravel cycling`, `CAD`, `junk boat parties`, etc. must resolve to a bundled canonical instead of falling back to a custom interest.

The Flutter test file has been written but has NOT been executed on GitHub-hosted CI yet because Actions minutes are being conserved.

## 6. Cross-category ambiguity fix

Exact matching no longer silently first-wins across categories.

`InterestCatalog.exactMatches(input)` returns all exact canonical candidates.

`InterestCatalog.exact(input)` now returns a canonical only when exactly one candidate exists.

`instantSelection` rejects ambiguous exact terms instead of silently selecting the first one.

This protects cases such as:
- Persona: film vs game franchise
- Genesis: artist vs car brand
- Perfume: artist vs fragrance
- Three-Body: TV vs book
- The Last of Us: TV vs game
- The Handmaid's Tale: TV vs book

The setup UI therefore shows the candidate results and requires an explicit choice.

## 7. Grey-zone mark policy resolved

The previously open grey-zone terms are now treated as `abstractOnly`, not `licensedOnly`:
- Python
- JavaScript
- Linux
- BookTok
- BookTube
- Bookstagram
- UNESCO Heritage Travel

Product meaning:
- They remain searchable/matchable interests.
- Baseline collectible art may exist.
- Baseline art must be abstract/generic and must not imitate official marks, logos, endorsement or trade dress.
- They are not blocked behind a rightsholder partnership in the same way as named entertainment IP, artists, car brands or branded theme parks.

## 8. Rights/card-policy count

No new V3 everyday interests were added to the partner-only licensed sets.

Therefore the static rights count becomes:
- Total: **3,935**
- `licensedOnly`: **1,843** (46.8%)
- Baseline-art eligible: **2,092** (53.2%)

The licensed absolute count is unchanged from V2; the share falls because V3 added generic real-world interests.

## 9. Activity semantics

New activity-aware treatment includes:
- dance -> movement/practice/learn/challenge
- performance -> practice/learn/discuss/challenge
- Modding Games / Escape Room Design -> creative-making semantics
- Game Streaming -> no automatic casual-play activity
- rights-sensitive branded/title interests remain blocked from generic activity fallthrough

Not every new interest is automatically a Zync Now activity. Location-dependent, professional, higher-risk, branded, alcohol-adjacent or semantically unclear concepts intentionally remain without a generic auto-activity until specifically reviewed.

## 10. External breadth sanity checks

Current public-product structures support the direction of this expansion:
- Bumble describes nearly 200 Interest Badges across creativity, sports, going out, staying in, media, reading, food/drink, travel and pets, and has recently highlighted interests such as dancing, run clubs, crocheting, skincare and cold plunging.
- Strava's current supported sport types span running/walking, multiple cycling disciplines, water/winter sports, racket sports, dance, cricket, weight training and more.
- Meetup's Hong Kong discovery surface separates Social Activities, Hobbies & Passions, Sports & Fitness, Travel & Outdoor, Career & Business, Technology, Community & Environment, Identity & Language, Games and Dancing.

These are product breadth references, not sources copied into the catalog.

## 11. Deliberately deferred sensitive domains

Do not blindly expand the same way into:
- political ideology / party affiliation
- religion
- medical/mental-health conditions
- disability/diagnosis-based communities
- other sensitive identity attributes

Those may be legitimate community needs, but storing/matching them has privacy and product-safety implications and needs a separate review rather than treating them as ordinary hobbies.

## 12. Validation status

Completed statically without hosted CI:
- 3,935 canonical recount
- duplicate-ID audit
- same-category normalized collision audit
- 444-query everyday-interest benchmark
- catalog/category distribution audit
- rights-policy arithmetic based on unchanged licensed set + generic additions

Written but not run in Flutter:
- expanded catalog tests
- cross-category ambiguity tests
- activity semantics tests
- 444-query benchmark test

Still deferred until after 2026-10-01:
- full `flutter analyze`
- targeted/full `flutter test`
- Android build
- hosted CI certification

## 13. Recommended next continuation

1. Stop chasing raw catalog count unless a new gap audit finds a real world with weak coverage.
2. Review browse UX/popularity so 3,935 interests do not overwhelm onboarding.
3. Re-audit Zync Now activity eligibility for the newly expanded generic interests.
4. Re-audit card-art prompt recipe coverage against the now broader generic baseline set.
5. Keep image generation CLOSED until the post-reset Flutter gate passes.
6. After 2026-10-01, run targeted analyze/tests, then decide whether card-art generation can open.

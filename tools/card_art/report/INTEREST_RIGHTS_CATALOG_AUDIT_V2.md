# Zync Interest Rights / Catalog Audit V2

Date: 2026-09-22  
Branch: `card-art-pilot-v1-20260921`  
Head entering report: `78587b70d2a95ba95e321d54ebab680068668d24`

## 1. Executive state

- No card images were generated.
- No image API credits were spent.
- Production remains closed.
- Google Play remains closed.
- The temporary CI PR #1 was closed without merge to stop duplicate pull-request-triggered CI.
- The active card-art branch currently has no open PR and its commits have produced zero GitHub Actions workflow runs.
- Freeze `zync-v1-rebuild-20260917` until the Actions allowance resets on 2026-10-01 unless an emergency fix requires it.

## 2. GitHub Actions conservation

Account alert supplied by owner:
- 1,820 / 2,000 included Actions minutes used.
- 180 included minutes remain.
- Reset date: 2026-10-01.

Observed repository structure:
- `zync-v1-ci.yml` and `zync-qa-preview-build.yml` had both old-branch `push` triggers and `pull_request` triggers.
- Temporary PR #1 targeted `main` from `zync-v1-rebuild-20260917`, creating a duplicate-trigger risk for the same pushed commit.
- PR #1 is now CLOSED, NOT MERGED.
- Current branch `card-art-pilot-v1-20260921` is not covered by the old-branch push filters and has no open PR.

Operational rule until reset:
1. Do not push the old `zync-v1-rebuild-20260917` branch.
2. Do not open a PR from the card-art branch merely to get CI.
3. Continue static/catalog/policy work on the current branch.
4. Run GitHub-hosted Flutter CI only if genuinely necessary before reset.
5. Account owner should set an Actions $0 hard budget / Stop usage guard to prevent paid overage.

## 3. Catalog canonical count

Original handoff count: 3,505.

Current count after canonical cleanup: **3,494**.

Eleven duplicate canonicals were removed while keeping the older/stabler canonical ID or the more precise unreleased canonical:
- `lifestyle.cafe_hopping` -> keep `food.cafe_hopping`
- `lifestyle.brunch` -> keep `food.brunch`
- `music.style.dreamy_pop` -> keep `music.style.dream_pop` + alias
- deep `Hip-Hop` -> keep legacy `music.hip_hop` + alias
- `music.mando_artist.tayu_lo` -> keep `music.mando_artist.lo_ta_yu` + alias
- deep `Romance Novels` -> keep `learning.romance_books` + alias
- deep `Biography` -> keep `learning.biographies` + alias
- deep `Self-Help Books` -> keep `learning.self_improvement` + aliases
- `food.dish.soup_dumplings` -> keep `food.dish.xiaolongbao` + alias
- deep `Road Tripping` -> keep `travel.roadtrip` + alias
- deep `Cruise Travel` -> keep `travel.cruises` + alias

Other ambiguity/localization fixes:
- Canoeing / Kayaking / Rowing separated.
- Anime / Animation separated.
- Drawing / Painting separated.
- Specialty Coffee no longer aliases to generic Coffee.
- Bulgogi no longer collides with Korean BBQ.
- Safari Travel no longer collides with Wildlife Travel.

## 4. Search collision gate

Static reproduction of current catalog/search-term normalization gives:

- Same-category normalized label/alias/ID-slug collisions: **0**
- Intentional cross-category ambiguous terms remain and must be disambiguated in UI/search rather than merged.

Known cross-category ambiguity includes:
- Minimalism: lifestyle vs music style
- Persona: film vs game franchise
- East of Eden: film vs book
- The Last of Us: TV vs game franchise
- The Handmaid's Tale: TV vs book
- Three-Body / 三體: TV vs book
- Genesis: music artist vs car brand
- Perfume: Japanese artist vs fragrance concept

A new unit-test gate now rejects future same-category normalized search-term collisions.

## 5. Common-interest benchmark recovery

The earlier release audit listed 27 missed common-interest queries.

All 27 now resolve with exact normalized label/alias score 0:
- triathlon
- pottery
- model making
- scrapbooking
- creative writing
- food photography
- foraging
- parties
- clubbing
- shopping
- thrifting
- flea markets
- personal development
- debating
- PC building
- hair styling
- fragrance
- figurines
- model cars
- driving
- stand-up comedy
- podcasts
- YouTube
- massage
- nutrition
- self care
- healthy eating

The original full 201-query benchmark script was not found in the repository, so do not claim a literal full-script rerun. The 27/27 previously missing terms are now recovered, and the prior 174 passing concepts were not removed by this cleanup.

## 6. Rights/card-policy result

Current static policy count:
- Total canonical interests: **3,494**
- `licensedOnly`: **1,843** (52.7%)
- Baseline-art eligible: **1,651** (47.3%)

The large licensed share is expected because the catalog contains many named artists, titles, franchises, board games, book titles, car brands, etc.

Clear false negatives fixed:
- `anime.jojo`
- `wellness.crossfit`
- `technology.chatgpt`
- `technology.android`
- `technology.apple`
- `motorsport.motogp`
- `motorsport.formula_e`
- `motorsport.wec`
- `motorsport.le_mans`
- `travel.style_deep.disney_parks_travel`
- `travel.style_deep.universal_studios_travel`

All are now searchable/matchable interests but baseline branded card art is held for rightsholder/partner treatment.

## 7. Resolver safety fixes

### Explicit not-collectible metadata

A latent resolver bug was fixed:
- Before: explicit `notCollectible` card metadata was skipped and could fall through to `originalGeneric` + baseline eligible.
- Now: explicit `collectible: false` or `artPolicy: notCollectible` is honored and baseline art remains disabled.

### Activity resolver

The activity resolver now checks the rights-aware card policy before generic taxonomy defaults.
- Rights-sensitive named interests cannot accidentally receive a generic auto-activity merely because Chinese localization exists.
- Explicit curated activity metadata still wins, so deliberate cases such as Formula 1 can retain a reviewed proxy/activity profile.

## 8. Deliberate grey zone — do not over-classify yet

Do not automatically make every trademarked/open-tech term `licensedOnly`.

Review separately before image generation:
- Python
- Linux
- JavaScript
- BookTok / BookTube / Bookstagram
- UNESCO Heritage Travel

Reason:
- Some names have trademark/attribution requirements but also permit descriptive/nominative/community use.
- The product may be better served by an `abstractOnly` / attribution-aware treatment rather than partner-only blocking.
- This is a product risk gate, not a legal conclusion.

## 9. Validation status

Completed without GitHub-hosted CI:
- Static parser recount.
- Static search normalization/collision audit.
- Static policy coverage count.
- Previously missing 27-query search check.
- Latest inspected current-branch commit produced zero workflow runs.

Not completed yet because Actions minutes are being conserved:
- Full `flutter analyze`
- Full `flutter test`
- Android build
- Full CI workflow

Do not confuse static audit success with full Flutter certification.

## 10. Recommended continuation

1. Audit the remaining grey-zone brand/platform terms and decide `abstractOnly` vs `licensedOnly`.
2. Add explicit cross-category disambiguation behavior for true ambiguous search terms.
3. Re-check Social / Wellness / Lifestyle depth after duplicate removal.
4. Keep image generation closed.
5. After 2026-10-01 allowance reset, run the full targeted Flutter test/analyze gate before any card-art generation expansion.

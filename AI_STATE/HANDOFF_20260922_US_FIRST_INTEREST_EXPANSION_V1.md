# Zync — USA-First Interest Expansion V1 Handoff

Date: 2026-09-22  
Branch: `card-art-pilot-v1-20260921`

## Mandatory first read

Read and obey:

`AI_STATE/OPERATING_RULES.md`

Do not use Vercel or GitHub Actions unless the task genuinely needs them. Prefer read-only/static work and batch writes.

## Why this handoff exists

The previous active work was card-art prompt routing V3.2. The conversation then shifted back to catalog expansion.

A gap audit initially over-weighted Asia/local-life because the user is in Hong Kong. The user explicitly corrected this: **Zync should aim to be popular in the USA first**, while remaining global. The interest strategy is now USA-first.

The user also pointed out that Zync supports many languages, not only English/Chinese. Repo inspection confirmed that the app UI has 9 locale files, while the bulk interest catalog does not yet have equivalent localization coverage.

## Current runtime truth — unchanged

- canonical interests: **3,935**
- baseline-art eligible: **2,092**
- rights-blocked: **1,843**
- active runtime catalog still ends at Part 15
- no new expansion candidates from this checkpoint have been activated yet
- Production CLOSED
- Google Play CLOSED
- image generation CLOSED
- no image API credits
- conserve GitHub Actions
- do not use Vercel unless actually needed

## Saved expansion data

Authoritative candidate checkpoint:

`AI_STATE/US_FIRST_INTEREST_EXPANSION_CANDIDATES_V1.json`

Readable audit/backlog:

`AI_STATE/US_FIRST_INTEREST_EXPANSION_BACKLOG_V1.md`

The JSON preserves:

- **117** high-confidence generic USA-first candidate interests
- alias-only mappings that must not become duplicate canonicals
- unresolved canonical-vs-alias items
- **13** candidate rights-gated platform brands
- **8** candidate rights-gated sports ecosystem brands
- the earlier regional/Asia/global candidate pack
- sensitive/age-gated holdouts
- examples verified to already exist
- localization architecture findings

## Main USA-first gaps found

The biggest structural holes are not ordinary sports or hobbies; those are already broad. The missing layer is how U.S. users identify socially:

- sports fandom and college sports
- fantasy sports and tailgating
- recreational/intramural sports
- block parties and local community formats
- game/craft/watch/social nights
- fairs, festivals, estate/garage-sale culture
- state parks, lake/beach/cabin/roadside outdoor life
- trucks, car meets/shows/detailing/restoration
- college life / dorm / homecoming / spring break / school spirit
- family/playdate/youth-sports identity
- dog/equestrian social life
- missing career worlds
- online communities / memes / internet culture
- wellness subtypes and event identities

## Important dedupe results

Many apparent gaps were already present. Do not re-add them. Examples include:

- Farmers' Markets
- Flea Markets
- Thrifting
- Book Clubs
- Run Clubs
- Pub Quizzes / Trivia Nights
- Language Exchange
- Coworking
- Open Mic Nights
- Poetry Slams
- Barre
- Functional Training
- Massage
- Sound Baths
- Forest Bathing
- Self-Care
- Meal Prep
- Debating
- Robotics
- Choir
- A Cappella
- Hot Pot
- Bubble Tea
- Tea Tasting / Tea Ceremony
- Cafe Hopping
- 3D Printing / Laser Cutting / CNC
- Aquascaping / Terrariums / Hydroponics
- K-Dramas / Chinese Dramas / Japanese Dramas
- Cozy Games / MOBA / MMORPG / Social Deduction / Deckbuilding / Metroidvania / Soulslike

Use the JSON for the full preserved list.

## Campus dedupe principle

Do not mint club duplicates when the identity already resolves to a stable canonical.

Pinned alias intentions:

- Coding Club → `technology.programming`
- Photography Club → `photography.general`
- Chess Club → `gaming.chess`
- Esports Club → `gaming.esports`
- Entrepreneurship Club → `learning.entrepreneurship`
- Debate Club → `learning.debating`
- Robotics Club → `technology.robotics`
- Drama Club → `arts.acting`
- School Musical → `arts.musical_theatre`
- School Choir → `music.choir`

Art Club and Dance Team still need target review.

## Platform / brand layer

Current catalog has YouTube, but not many other major platforms.

Candidate rights-gated layer:

Facebook, Instagram, TikTok, Snapchat, Reddit, Discord, Twitch, Spotify, Pinterest, LinkedIn, WhatsApp, Threads, X.

Do not generate official-looking logos/UI/trade dress for them.

## Sports ecosystem / team layer

Candidate rights-gated ecosystem interests:

NFL, NBA, WNBA, MLB, NHL, MLS, UFC, NCAA Sports.

A later team-fandom layer could add 100+ interests, but needs rights-safe card handling before activation.

## Sensitive domains deliberately held out

Do not blindly add:

- sports betting / casino / gambling
- alcohol-centric identities
- hunting / firearm subtypes
- religion / religious affiliation
- political / party affiliation

These need age, safety, privacy and/or product-policy review.

## Localization finding

UI locale files currently exist for:

`en, es, fr, ja, ko, pt, zh, zh-Hans, zh-Hant`

Ordinary catalog rows only guarantee:

`en, zh-Hant, zh-Hans`

`parseInterestFamily()` can optionally carry `ja` and `ko`.

Spanish / French / Portuguese are not yet first-class interest-label fields.

For USA-first launch:
1. English remains base canonical authoring language.
2. Spanish should become the first localization priority.
3. Prefer a per-locale label/alias map rather than continuing to add fixed columns to compact rows.
4. Keep canonical IDs language-neutral and stable.

## Next continuation order

1. Read `AI_STATE/US_FIRST_INTEREST_EXPANSION_CANDIDATES_V1.json`.
2. Do a final semantic dedupe of the 117 generic candidates against all 3,935 existing canonicals.
3. Resolve the 10 canonical-vs-alias undecided items in the JSON.
4. Design the per-locale interest-label/alias architecture before activating a large batch.
5. Produce stable canonical IDs + category + cluster + rank + aliases for the surviving USA-first generic pack.
6. Separately define rights policy for platform brands and sports ecosystem brands.
7. Only after the above, add a new catalog Part 16 in one batched change.
8. Re-run catalog/rights/card-art audits only at a meaningful checkpoint, not on every micro-edit.
9. Preserve earlier V3.2 card-art work; after catalog expansion stabilizes, resume prompt-routing QA for the expanded catalog.
10. Keep Production, Play and image generation closed.

## Infrastructure lesson

This checkpoint is intentionally one batched repo write.

Prior high-frequency Zync work caused extreme GitHub Actions churn and Vercel Preview deployment/storage use. Every future chat must inspect automation blast radius before writes and must not turn catalog editing into micro-commit CI/deploy loops.

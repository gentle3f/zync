# Zync Cardverse Architecture V1

Status: **Architecture contract — implementation foundation, not a production launch approval**

Branch context: `zync-v1-rebuild-20260917`

## 1. Product role

Cardverse is a bonus collection/discovery loop around Zync's real purpose:

**Meet people → discover people → have a real interaction → remember it → earn collection progress.**

Cardverse must not turn Zync into a screen-time or gambling-first product.

The intended loop is:

**Real Zync / Tried Together → Quest progress → server-validated reward → Pack → Card discovery → Want to Try → future real interaction.**

No marketplace, cash value, auction, real-money trading, or speculative economy is part of V1.

## 2. Trust boundary

Zync Core remains local-first where practical:

- ordinary profile and interest selections
- detailed People history
- received social links
- recent AI interaction prompts/questions
- exact person-to-person Zync history

Cardverse becomes account-bound and cloud-authoritative:

- card inventory
- pack ownership and pack-open state
- Draw Tokens / future bounded collection currency
- server-validated Quest rewards
- collection milestones
- wishlist/favorites needed for collection
- trading ownership and immutable ledger
- Cardverse cosmetics

Do not silently upload People names, raw peer IDs, QR payloads, AI questions, or detailed social history into Cardverse.

## 3. Account identity

Use an internal Zync account UUID as the inventory owner.

Google and Apple are identity links, not inventory primary keys.

A single internal account may link both providers so the same collection can be restored across platforms.

Do not use email address as the durable account identity.

Account linking must be an explicit authenticated action and must defend against account takeover.

Cardverse persistence begins when the user reaches the first durable collection/reward moment. Initial Zync onboarding does not need to be blocked by account creation.

First Cardverse persistence UX should explain the reason:

> Connect an account so your collection is never lost.

A local-to-cloud migration/merge path is required for any pre-account collection metadata that is permitted to migrate.

## 4. Card identity

Canonical interest IDs remain the content identity.

Localized English / Traditional Chinese / Simplified Chinese labels are presentation/search data only.

A card's visual identity must be deterministic from:

`canonical interest ID + art system version`

Changing app language must never generate a different-looking base card.

Stable card numbers must never be renumbered after release. New interests receive new numbers.

## 5. Rarity is not hobby prestige

Never define an interest itself as Common / Rare / Legendary.

Example that is forbidden conceptually:

- Badminton = Common
- Ice Climbing = Legendary

Instead:

- Base Interest Card = Badminton
- Finish variant = Normal / Foil / Holo / Prism / Legendary / Secret
- Edition = Core / Encounter / Discovery / Event / Starter / Achievement

Any interest may receive a high-finish variant.

This keeps collectible rarity separate from the implied social value of a hobby.

## 6. Ownership shapes

### 6.1 Stackable assets

Ordinary collectible variants may be represented as a balance:

- account ID
- variant key
- quantity
- locked quantity
- row/version number

Available quantity is:

`quantity - locked_quantity`

Trade reservation must increase locked quantity before settlement so the same copy cannot be offered twice.

### 6.2 Unique instances

Use unique instances only when identity/provenance matters, such as:

- genuinely serial-limited cards
- special event cards
- soulbound personal cards
- future unique cosmetic variants

Ordinary cards do not need fake serial numbers.

## 7. Edition tradability

Default policy:

- Core: tradable
- ordinary Foil / Holo / Prism / Legendary Core variants: tradable
- Encounter: soulbound / non-tradable
- Starter/tutorial: soulbound
- personal Achievement rewards: soulbound
- Event: per-edition policy

A unique instance may be locked even if its edition is otherwise tradable.

Server policy is authoritative.

## 8. Encounter Edition

Encounter cards are personal real-world mementos.

Example meaning:

> Basketball — Encounter Edition — Discovered through a Zync — 19 Sep 2026

Do not store the other person's display identity inside the card.

A minimum Encounter record may contain:

- interest ID
- date/time bucket or timestamp as policy allows
- acquisition source = encounter
- edition/finish
- owner

Encounter cards are soulbound by default.

## 9. Pack engine

Pack results are server-authoritative.

The client may send:

- pack ID
- idempotency key
- client reveal-animation version

The client must never send:

- RNG seed
- desired rarity
- desired finish
- desired cards
- odds override
- result object

Opening must be one atomic server transaction:

1. authenticate the account
2. validate unopened pack ownership
3. validate idempotency key
4. roll interest independently from finish
5. apply disclosed guarantee/pity policy
6. persist immutable pack result
7. mutate inventory
8. append ledger entries
9. mark pack rolled/opened
10. commit
11. return the already-persisted result

Animation occurs **after** the result is committed.

Reconnect/retry with the same idempotency key must return the same result, never reroll.

## 10. Pack presentation

V1 default concept:

- 5 cards per pack
- interest selection and finish selection are separate
- duplicates are useful and initially represented by quantity
- thematic packs may later constrain the interest pool
- guarantee/pity rules must be transparent if enabled

Opening effects may use anticipation, sound, haptics, shimmer and reveal pacing, but must not fake an upgrade or imply a near-win that did not occur.

Accessibility requirements:

- Reduce Motion support
- static shimmer alternative
- audio toggle
- haptic toggle
- no dangerous high-frequency flashing

## 11. Quest reward bridge

Local Quest progress is a UX signal, not authoritative inventory.

Current local event stream intentionally stores coarse progress data such as:

- one-to-one Zync completed
- repeat-person boolean
- Tried Together completed
- group size
- Zync Now mode
- broad interest categories

It does not store peer ID or peer nickname.

Local completion may create **reward eligibility**, but it must not mint Draw Tokens or Packs.

When Cardverse cloud is enabled, the server must revalidate the supported proof/event claim before issuing inventory.

Pre-account/offline eligibility may be rejected or migrated conservatively if secure validation is impossible.

## 12. Direct trading

Architecture decision:

**Trading-ready from day one; Direct Trade ships later.**

Initial trading model:

1. two authenticated users establish a short-lived direct trade session
2. each selects assets
3. server reserves/locks offered assets
4. both see the exact immutable offer revision
5. both confirm that same revision
6. server revalidates ownership and tradability
7. all transfers and ledger writes happen in one database transaction
8. transaction commits or fully rolls back

A changed offer creates a new revision and invalidates old confirmations.

Expired, cancelled or failed trades release reservations.

No client-side ownership transfer is valid.

## 13. Direct trading exclusions

Not in the early roadmap:

- cash marketplace
- player-set monetary price
- auctions
- official real-money card exchange
- gambling services
- speculative token economy

Do not add these indirectly through a "coin" whose primary purpose is buying/selling player cards.

## 14. Wishlist

Reserve a cloud Wishlist model before Direct Trade UI ships.

Future direct Zync sessions may reveal:

> You each have cards the other person wants.

This must not expose an unnecessary social graph or raw long-term peer identity.

## 15. Inventory ledger

Every economy mutation must have append-only server ledger evidence.

Examples:

- Pack grant
- Pack open
- Quest reward
- Trade reserve
- Trade release
- Trade out
- Trade in
- Migration
- Administrative correction

Ledger rows require a monotonically meaningful server sequence/order and immutable event ID.

User-facing provenance should not expose previous owner names.

For ordinary stackable commodity cards, do not promise per-copy provenance.

## 16. Privacy

Cardverse cloud should not automatically receive:

- People names
- detailed People history
- exact peer IDs
- AI questions
- received social links
- raw QR payloads
- precise location
- detailed in-person interaction transcripts

A trading server will necessarily know the two internal account IDs for a transaction, but user-facing card provenance does not need to expose them.

Analytics must remain coarse and separately governed.

## 17. Account recovery and lifecycle

Design before public launch:

- restore collection on a new phone
- link Google and Apple safely
- provider-loss recovery path
- explicit account deletion
- collection export
- session revocation
- refresh-token revocation
- merge conflict policy
- privacy-policy update

Deletion must distinguish Cardverse cloud data from local-only Zync Core data.

## 18. Backend requirements

Do not select a database only because it is convenient for the current prototype.

The Cardverse backend must support:

- authenticated account ownership
- real transactions
- row/version locking or equivalent concurrency control
- idempotency
- unique constraints
- append-only ledger
- atomic multi-account trade settlement
- server-side RNG
- rate limits
- auditable migrations

A transactional relational store such as PostgreSQL is a natural candidate, but this architecture document does not yet select a provider.

## 19. Visual generation

Do not create 3,000 independent hand-drawn assets.

Use a deterministic compositional system:

`Interest metadata × category kit × visual family × motif × palette × edition seal × finish shader`

Recommended split:

- base art / scene composition deterministic and cacheable
- finish/shiny effects rendered dynamically where performance allows
- only a small chase/event subset requires bespoke hero artwork

Proper-name / trademark / named-work interests should use abstract category art unless the project has clear rights to specific imagery.

Do not clone Pokémon card layout, trade dress, logos or copyrighted characters.

## 20. Translation gate

Mass card rendering must not run before the generic-interest localization audit is complete.

Canonical IDs remain fixed.

Generic hobbies/activities should have explicit English / Traditional Chinese / Simplified Chinese labels.

Proper nouns may remain native or use established official/common translations.

Visual seed must never depend on localized display text.

## 21. Current code contracts

Current branch foundations:

- `mobile/lib/core/cardverse_models.dart`
  - account/identity-link shape
  - card/finish/edition separation
  - deterministic visual identity
  - stackable and unique ownership
  - tradability policy
  - server-authoritative pack request/receipt

- `mobile/lib/core/cardverse_trade_models.dart`
  - direct trade proposal/revision
  - same-revision bilateral confirmation
  - no marketplace/cash/auction
  - immutable inventory ledger shape
  - server-authoritative settlement receipt

- `mobile/lib/core/progress_event.dart`
  - privacy-bounded real-world progress events

- `mobile/lib/core/quest_engine.dart`
  - daily/weekly real-world quest evaluation
  - local-time reset
  - reward eligibility only, no local inventory minting

## 22. Implementation order

1. Keep current Zync / Group Zync / Zync Now CI green.
2. Finish generic-interest localization gate.
3. Finalize Card Definition / Finish / Edition seed data.
4. Select transactional Cardverse backend.
5. Add internal account + Google/Apple identity linking.
6. Build cloud inventory + immutable ledger.
7. Build server-side Quest reward validation.
8. Build server-authoritative Pack engine.
9. Build Collection UI and card renderer.
10. Add pack reveal effects.
11. Add Wishlist.
12. Add Direct Trade.
13. Keep cash marketplace out of the early roadmap.

Production and Google Play remain closed until separately certified.

# Zync Cardverse Cloud Ownership V1

Status: **Milestone 5 implementation contract — internal foundation only**

Branch: \`zync-v1-rebuild-20260917\`

Production: **CLOSED**

Google Play: **CLOSED**

## 1. Decision

Milestone 5 selects:

- **PostgreSQL** as the Cardverse transactional source of truth;
- **Neon-hosted PostgreSQL** as the initial managed provider;
- the existing **Vercel Node 22 serverless API** as the only mobile-facing server boundary;
- a standard pooled \`DATABASE_URL\` and provider-neutral SQL/domain layer so the database can move to another PostgreSQL host later without changing Cardverse ownership semantics.

The mobile app must never connect directly to PostgreSQL.

Upstash Redis remains suitable for short-lived relay/cache workloads. It is **not** the Cardverse inventory, ledger, pack, or trading database.

## 2. Why this shape

The locked Cardverse rules require real transactions, constraints, row locking, idempotency, append-only audit evidence, server-side RNG, and eventually atomic multi-account trade settlement.

A relational PostgreSQL transaction is the ownership boundary. UI state, local Quest state, Redis state, animation state, and analytics are not ownership authority.

Neon is selected because it fits the existing Vercel serverless deployment while keeping ordinary PostgreSQL semantics. Zync deliberately does not move the whole API to a second edge/runtime stack just to obtain a database.

## 3. Privacy boundary

Cloud Cardverse may contain:

- internal Zync account UUID;
- Google / Apple provider subject links;
- provider email only as optional identity metadata, never inventory identity;
- card balances and unique instances;
- unopened packs;
- reward grants when implemented;
- idempotency records;
- immutable economy ledger;
- Cardverse wishlist/trading state later.

Cloud Cardverse must not automatically contain:

- People names;
- local People history;
- raw QR payloads;
- exact peer IDs;
- received social handles;
- AI questions or transcripts;
- precise location;
- detailed private Zync Now answers.

The ledger metadata field is not permission to upload those local-first fields.

## 4. Account boundary

The durable owner is \`zync_accounts.id\` (UUID).

Identity providers are links:

\`\`\`text
Google subject ─┐
                ├─> internal Zync account UUID ─> Cardverse ownership
Apple subject ──┘
\`\`\`

Email is not an ownership key.

One account may link both Google and Apple. Provider subject uniqueness prevents the same external identity from silently owning two accounts.

Initial account creation is not required for ordinary Zync onboarding. The intended login moment remains the first durable collection/reward moment.

## 5. Authentication rule

No public ownership endpoint may trust an \`accountId\` supplied by the mobile request body.

When public auth is added:

1. mobile supplies a Google/Apple/OIDC credential;
2. server verifies the credential;
3. server resolves the provider subject to the internal Zync UUID;
4. ownership services receive that server-resolved UUID;
5. request body may identify resources, but never choose the authenticated owner.

The current Milestone 5 foundation intentionally does **not** expose a fake install-ID-as-auth shortcut.

## 6. Database foundation

Migration:

- \`db/migrations/0001_cardverse_ownership.sql\`

It creates:

- \`zync_accounts\`;
- \`zync_identity_links\`;
- \`cardverse_pack_entitlements\`;
- \`cardverse_stack_balances\`;
- \`cardverse_unique_instances\`;
- \`cardverse_idempotency_records\`;
- \`cardverse_inventory_ledger\`.

Important invariants:

- locked stack quantity cannot exceed owned quantity;
- identity links are unique by provider + provider subject;
- only one link per provider per account;
- one server grant cannot mint more than one pack entitlement;
- unopened/opened pack state is constrained;
- inventory ledger sequence is server-generated;
- ledger UPDATE/DELETE/TRUNCATE is rejected;
- ordinary inventory rows have explicit versions;
- unique-instance soulbound/locked state is server data.

## 7. Server-only ownership services

Files:

- \`api/_cardverse/db.js\`
- \`api/_cardverse/ownership_store.js\`

The DB module owns the server connection. It uses Postgres.js only inside the Vercel runtime and keeps one connection per warm function instance.

The ownership store currently provides:

- create-or-resolve internal account from a verified provider identity;
- safely link a second provider to an existing account;
- atomically issue a server-owned unopened pack entitlement;
- idempotent replay for the same pack grant request;
- append a pack-grant ledger event in the same transaction;
- fetch a cloud ownership snapshot with a ledger cursor.

These are server-domain functions, not public trust shortcuts.

## 8. Pack entitlement transaction

Issuing one server-owned pack is one transaction:

\`\`\`text
lock active account
→ reserve idempotency key
→ reject same key with different request
→ reuse existing grant result or create one unopened pack
→ append immutable pack_grant ledger row
→ persist idempotent response
→ COMMIT
\`\`\`

A retry with the same idempotency key returns the persisted response.

A server grant ID is unique, so a different idempotency key cannot mint a second pack from the same grant.

## 9. Planned public API boundary

The real external API should remain narrow:

\`\`\`text
POST /cardverse/auth/provider
POST /cardverse/quests/:questId/claim
GET  /cardverse/packs
POST /cardverse/packs/:packId/open
GET  /cardverse/inventory
GET  /cardverse/pack-rolls/:serverRollId
\`\`\`

Later:

\`\`\`text
POST /cardverse/identity-links
POST /cardverse/trades
POST /cardverse/trades/:tradeId/revisions
POST /cardverse/trades/:tradeId/confirm
POST /cardverse/trades/:tradeId/cancel
\`\`\`

Exact HTTP naming may evolve, but the authority direction may not.

## 10. Quest claim boundary

The client may submit only bounded proof already defined by the certified reward contract:

- eligibility key;
- quest ID;
- cycle start;
- proof event IDs;
- idempotency key;
- client contract version.

The client must never choose reward kind, amount, pack ID, card, finish, rarity, or RNG.

Local Quest completion remains eligibility, not ownership.

## 11. Pack open boundary

Opening a pack must eventually be a single PostgreSQL transaction:

\`\`\`text
authenticate
→ lock entitlement
→ idempotency check
→ server RNG
→ persist immutable roll/result
→ write balances/instances
→ append ledger
→ mark entitlement opened
→ COMMIT
→ return persisted receipt
\`\`\`

The client reveal animation begins only after that receipt exists.

This migration does not yet implement pack RNG/roll tables; that is the next ownership transaction slice after the account/inventory foundation is certified.

## 12. Collection sync

The first sync API may return a complete bounded snapshot:

- balances;
- unique instances;
- unopened packs;
- latest ledger cursor.

The ledger cursor gives the server a monotonic sync/version reference without making the client the source of truth.

Detailed local People/session data is not needed to restore Cardverse on a new phone.

## 13. Offline/degraded behavior

Ordinary Zync remains local-first when Cardverse cloud is unavailable.

Cardverse rules:

- cached collection may be displayed as last-synced;
- no offline client minting;
- no offline pack RNG;
- no offline ownership transfer;
- claim/open requests may be retried with the same idempotency key;
- server receipt wins after reconnect.

## 14. Runtime configuration

Required before real cloud calls are enabled:

- \`DATABASE_URL\` — pooled PostgreSQL connection string;
- \`CARDVERSE_DATABASE_SSL=require\` by default.

For local-only PostgreSQL development, \`CARDVERSE_DATABASE_SSL=disable\` may be used explicitly.

Database credentials are Vercel server secrets. They must never be compiled into Flutter.

## 15. Current release gate

This foundation does **not** mean public Cardverse is ready.

Still blocked before Home exposure:

- real Google/Apple credential verification;
- production account session/token design;
- server Quest revalidation;
- reward grant persistence;
- server pack RNG + roll receipt transaction;
- real mobile Collection sync;
- multi-device restore QA;
- deletion/recovery/session revocation policy;
- security/rate-limit review.

Therefore:

- Cardverse Labs remain internal;
- Curiosity Board Claim remains non-production;
- Production remains closed;
- Google Play remains closed;
- PR #1 remains draft and unmerged.


## 16. Transactional pack-open core

Milestone 5 now also defines and implements the server-only pack-open transaction core.

Additional migration:

- `db/migrations/0002_cardverse_pack_rolls.sql`

Additional domain service:

- `api/_cardverse/pack_store.js`

The service deliberately separates authenticated owner identity from the raw client request:

```text
openPack(database, serverResolvedAccountId, clientRequest, serverRoller)
```

The client request may contain only:

- pack ID;
- idempotency key;
- client reveal version.

It is rejected if it attempts to provide an account ID, RNG seed, cards, result, finish, rarity, odds, or policy version.

The server-only roller receives only the server-owned pack identity/type. Its committed five-card plan is validated and then persisted inside the same database transaction that updates ownership.

The transaction now has the required shape:

```text
lock active account
→ reserve idempotency key
→ lock unopened pack
→ obtain server-only roll plan
→ create one immutable server roll
→ write ordered result items
→ credit stackable/unique ownership
→ append per-asset ledger credits
→ mark pack opened
→ append pack-open ledger debit
→ persist idempotent response
→ COMMIT
```

A retry with the same idempotency key returns the persisted receipt without invoking the roller again.

The database also enforces one roll per pack with a unique `pack_id` constraint.

The actual production odds/catalog policy is intentionally **not** frozen by this slice. That policy must be explicit, versioned, auditable and server-owned before a public pack-open endpoint is enabled.


## 17. Authenticated account/session foundation

Milestone 5 now includes the server identity boundary needed before any public ownership mutation is enabled.

New migration:

- `db/migrations/0003_cardverse_auth_sessions.sql`

New server modules:

- `api/_cardverse/session_store.js`
- `api/_cardverse/provider_auth.js`

New authenticated API foundation:

- `POST /api/v1/cardverse/auth/challenge`
- `POST /api/v1/cardverse/auth/provider`
- `POST /api/v1/cardverse/auth/logout`
- `GET /api/v1/cardverse/inventory`

The authentication flow is:

```text
request single-use provider challenge
→ app sends nonce to Google / Apple
→ app receives provider ID token
→ server verifies signature + issuer + audience + expiry
→ server verifies and consumes the single-use nonce challenge
→ server resolves provider subject to internal Zync account UUID
→ server creates an opaque Cardverse session
→ only SHA-256(session token) is stored
```

Provider email is optional metadata only. The provider `sub` claim is the identity link.

No public ownership endpoint accepts a client-selected account ID.

Runtime configuration required before provider login can work:

- `ZYNC_GOOGLE_CLIENT_IDS` — comma-separated accepted Google OAuth client IDs;
- `ZYNC_APPLE_CLIENT_IDS` — comma-separated accepted Apple App/Services IDs;
- `DATABASE_URL`.

The default server session lifetime is 30 days and may be reduced with `CARDVERSE_SESSION_TTL_DAYS`. Auth nonce challenges default to 10 minutes.

This slice does not add a mobile login button yet. Mobile provider credentials and secure token storage must be configured and tested before the first real collection login UX is enabled.


## 18. Pack policy fail-closed boundary

The server now has an internal V1 pack catalog mirrored from the currently approved expanded Cardverse visual proof set:

- `api/_cardverse/catalog_v1.js`
- 50 canonical interest IDs;
- art system version 1;
- CI drift-checks the server allowlist against the Dart `proofInterestIds + expandedProofInterestIds` lists.

This does **not** mean all 50 cards or their odds are production-approved. It is an internal server allowlist for the current proof surface.

No default pack odds are embedded.

A real pack open requires explicit server configuration in `CARDVERSE_PACK_POLICY_V1`. The configured policy must provide, separately for Standard and Discovery packs:

- policy version;
- catalog version;
- edition ID;
- integer interest weights;
- integer finish weights;
- an explicit guarantee rule (`none` or `at_least_one_finish`).

Interest selection and finish selection are performed independently with Node's cryptographic RNG. A configured guarantee is applied only after the five independent finish rolls.

If the policy is absent, malformed, references an unapproved catalog interest, invents a finish tier, or specifies an unreachable guarantee, pack opening fails closed.

The authenticated pack-open endpoint now exists at:

- `POST /api/v1/cardverse/packs/open`

It resolves the account from the bearer session and delegates to the already-transactional `openPack()` domain service. The request body still cannot choose account ID, RNG seed, cards, finish, rarity, odds, result, or policy version.

### Runtime kill switches

Every current Cardverse HTTP endpoint now defaults to hidden/disabled unless:

- `CARDVERSE_API_ENABLED=true`

Pack opening additionally requires:

- `CARDVERSE_PACK_OPEN_ENABLED=true`

Therefore merely deploying this branch or configuring a database cannot accidentally expose Cardverse cloud ownership. Public enablement still requires an explicit server-side release action after rate-limit/security review and final policy approval.


## 19. Trusted Quest proof and reward grant boundary

Local Quest completion remains UX eligibility only.

Milestone 5 now adds a separate server-authoritative proof/grant layer:

- `db/migrations/0004_cardverse_reward_proofs.sql`
- `api/_cardverse/reward_store.js`
- `POST /api/v1/cardverse/quests/claim`

New durable tables:

- `cardverse_reward_proofs`;
- `cardverse_reward_grants`;
- `cardverse_reward_grant_proofs`;
- `cardverse_draw_token_balances`.

A trusted reward proof intentionally stores only coarse Quest facts:

- internal owner UUID;
- client event ID;
- one-to-one vs Tried Together;
- source;
- timestamp;
- participant count;
- repeat-person boolean;
- broad interest categories;
- timezone offset and server-computed daily/weekly cycle starts;
- verifier identifier.

It does **not** store the peer account, peer name, social handle, QR payload, private interests, question transcript or precise location.

### Why proof rows are server-issued

The claim endpoint never accepts raw event details and never creates proof rows.

A future trusted Zync action flow must call `recordTrustedRewardProof()` only after it independently verifies the real-world action. Until that issuer exists, production Quest Claim must remain disabled.

This prevents a modified client from minting rewards by inventing local progress events.

### Server quest rules

The server now independently mirrors the five certified Quest rules and computes the reward kind/amount itself. The client cannot send reward kind, amount, pack ID, finish, rarity or cards.

The server validates:

1. authenticated account;
2. single-use idempotency key;
3. one grant per account + quest + server cycle;
4. every submitted proof ID exists for that account;
5. every proof belongs to the exact precomputed daily/weekly cycle;
6. the proof set satisfies the server Quest metric/target;
7. reward output is derived from the server rule.

A successful Standard/Discovery reward creates the unopened pack entitlement and ledger entry inside the same PostgreSQL transaction.

A Draw Token reward updates a versioned cloud balance and ledger inside the same transaction.

### Separate release switch

Quest Claim additionally requires:

- `CARDVERSE_QUEST_CLAIM_ENABLED=true`

It remains off until a trusted real-world proof issuer and rate-limit/security review are complete.


## 20. Anonymous 1:1 relay completion tickets

Milestone 5 now has a privacy-preserving trusted issuer for the existing encrypted 1:1 relay.

The relay still does **not** know either participant's Cardverse account, local profile ID, peer name, interests, social handles or decrypted profile payload.

When `ZYNC_CARDVERSE_PROOF_SECRET` is configured, a successful encrypted relay uses a V2 completion state:

```text
scanner submits opaque encrypted response
→ relay returns a private scanner proof capability
→ host polls and decrypts response locally
→ host confirms successful consume
→ relay marks the anonymous session completed
→ host receives one signed completion ticket
→ scanner capability may fetch the other signed completion ticket
```

The two tickets are distinct, deterministic on retries, and contain only:

- unique opaque issuer-ticket ID;
- event type = one-to-one Zync;
- source = one-to-one;
- participant count = 2;
- server completion time;
- expiry.

They do **not** contain either account ID or a linkable relay session ID.

Tickets default to a 30-day redemption window and may be shortened with `CARDVERSE_PROOF_TICKET_DAYS` (maximum 90 days).

### Redemption

Authenticated redemption is:

- `POST /api/v1/cardverse/proofs/redeem`

and additionally requires:

- `CARDVERSE_PROOF_REDEEM_ENABLED=true`.

The request may supply only:

- signed ticket;
- local client event ID used to correlate the already-existing local Quest event;
- timezone offset used to compute the server Quest cycle.

The account comes only from the authenticated Cardverse session.

The client cannot supply repeat-person status or interest categories. Relay-issued 1:1 proof therefore stores:

- `repeat_person = NULL`;
- no interest categories.

This is deliberate. An anonymous relay completion ticket can currently satisfy action-count rules such as `daily_make_a_zync` and `weekly_real_world_three`, but it **cannot** satisfy `weekly_meet_two_new_people` or `weekly_three_interest_worlds` merely from client assertions.

The database enforces global uniqueness of `issuer_ticket_id`, so one anonymous completion ticket cannot be redeemed into two accounts.


## 21. Distributed abuse boundary

Cardverse protected endpoints now use a serverless-safe distributed limiter backed by the existing Upstash Redis service:

- `api/_cardverse/abuse_guard.js`

Protected routes include:

- auth challenge;
- provider authentication;
- proof redemption;
- Quest claim;
- pack open;
- account lifecycle actions.

The limiter never stores raw client IPs or raw Cardverse account UUIDs in Redis keys. Principals are HMAC-derived with the independent server secret:

- `ZYNC_CARDVERSE_RATE_LIMIT_SECRET`.

Unauthenticated auth flows are limited by anonymous client-address bucket. Authenticated high-value mutations use both an IP bucket and a server-resolved account bucket.

If Cardverse is enabled but the limiter is unconfigured or unavailable, the protected route fails closed. A rate-limit rejection is HTTP 429 with `Retry-After`.

Upstash remains short-lived abuse-control infrastructure only. PostgreSQL remains the ownership/economy source of truth.

## 22. Account and session lifecycle

Milestone 5 now also has a server-side lifecycle boundary.

Additional migration:

- `db/migrations/0006_cardverse_account_lifecycle.sql`

Additional service:

- `api/_cardverse/account_lifecycle.js`

Additional internal endpoints:

- `POST /api/v1/cardverse/auth/link`
- `POST /api/v1/cardverse/auth/unlink`
- `POST /api/v1/cardverse/auth/logout-all`
- `POST /api/v1/cardverse/account/delete`

The routes are hidden unless both:

- `CARDVERSE_API_ENABLED=true`;
- `CARDVERSE_ACCOUNT_LIFECYCLE_ENABLED=true`.

Security rules:

- provider link/unlink/delete require fresh provider challenge + ID-token verification in addition to an existing Cardverse bearer session;
- the last active identity cannot be unlinked;
- unlink revokes every active session on the account;
- soft-unlinked provider subjects remain tombstoned and cannot silently create a different Cardverse owner;
- a previously unlinked provider may be restored only from the already-authenticated owning account after provider re-verification;
- logical account deletion requires literal `DELETE` confirmation and provider re-verification;
- deletion revokes all sessions and clears stored provider email metadata;
- immutable ownership ledger rows are not destructively rewritten by account deletion;
- new login sessions are capped at 8 active sessions by default, configurable up to 32.

The self-service recovery model is deliberately narrow: link a second provider while the account is accessible, then either provider can recover access. No support/admin identity override is approved.

The controlled infrastructure/migration/enablement procedure is documented in:

- `docs/ZYNC_CARDVERSE_LIVE_DEPLOYMENT_CHECKLIST_V1.md`.

Production and Google Play remain CLOSED.

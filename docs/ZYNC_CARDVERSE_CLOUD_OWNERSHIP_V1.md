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

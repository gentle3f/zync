# Zync — Milestone 5 Durable Cardverse Ownership + Trusted Proof Certified

Date: 2026-09-20  
Branch: `zync-v1-rebuild-20260917`  
Certified implementation head before this handoff-doc commit:

`dfeda4cb06515bce39102605d6815586ad1067d3`

This is the authoritative continuation checkpoint for Milestone 5.

## 1. Certification status

The implementation head above is fully CI-certified:

- Zync V1 CI push #867 — SUCCESS
- Zync V1 CI PR #868 — SUCCESS
- Zync QA Preview APK #224 — SUCCESS
- PostgreSQL migration/constraint execution gate — SUCCESS
- Flutter analyze — SUCCESS
- full Flutter test suite — SUCCESS
- unsigned release AAB build/upload — SUCCESS
- QA release APK build/upload — SUCCESS

Production remains CLOSED. Google Play remains CLOSED. Draft PR #1 remains DO NOT MERGE.

## 2. What Milestone 5 now has

### Durable transactional ownership backend

PostgreSQL is now the Cardverse source of truth through provider-neutral `DATABASE_URL` wiring.

Implemented migrations:

- `0001_cardverse_ownership.sql`
- `0002_cardverse_pack_rolls.sql`
- `0003_cardverse_auth_sessions.sql`
- `0004_cardverse_reward_proofs.sql`
- `0005_cardverse_relay_proof_tickets.sql`

The durable model now covers:

- internal Zync accounts;
- Google/Apple identity links;
- opaque server sessions;
- unopened/opened pack entitlements;
- stackable balances and locks;
- unique card instances;
- immutable inventory ledger;
- server pack rolls and ordered roll items;
- idempotency records;
- draw-token balances;
- trusted reward proofs;
- reward grants and proof links;
- globally unique anonymous proof-ticket redemption IDs.

The PostgreSQL CI gate executes migrations on PostgreSQL 16 and verifies hard constraints, including append-only ledger behavior, invalid locked balances, duplicate pack rolls, and proof-ticket replay rejection.

## 3. Auth / ownership boundary

Server auth foundation is implemented:

- nonce challenge;
- Google/Apple JWT verification through remote JWKS;
- issuer, audience, expiry and nonce verification;
- provider `sub` used as stable external identity;
- email only optional metadata;
- internal account UUID is the ownership key;
- opaque bearer session tokens stored hashed server-side;
- authenticated Cardverse endpoints resolve account only from bearer session;
- client request bodies cannot select `accountId`.

HTTP routes remain kill-switched by default.

## 4. Server-authoritative pack opening

Pack opening is transactional and server-authoritative:

- client may send only pack ID / idempotency key / reveal version;
- client cannot send seed, random result, cards, finish, rarity, odds or policy;
- unopened entitlement is locked;
- server-only roller selects results;
- roll receipt and ordered roll items are persisted;
- inventory is credited;
- immutable ledger entries are appended;
- entitlement is marked opened;
- idempotent retry returns the persisted receipt.

Server pack policy remains fail-closed. There are no invented production odds.

The server allowlist mirrors the current 50-card procedural proof surface only.

## 5. Trusted real-world proof issuer breakthrough

Milestone 5 no longer has a claim system with no trusted issuer.

The existing encrypted 1:1 relay can now issue two anonymous one-time completion proofs after a real successful pairing:

1. scanner submits the encrypted peer response;
2. relay returns a private scanner proof capability;
3. host polls and decrypts locally;
4. host confirms successful consume;
5. relay atomically marks the anonymous relay session completed;
6. host receives a signed completion ticket;
7. scanner capability can fetch the scanner's distinct signed completion ticket.

Important privacy property:

- the relay still does not know either Cardverse account;
- it does not receive peer name, social handles, permanent peer ID, interests, raw QR content or decrypted profile payload;
- proof tickets do not contain account IDs or a linkable raw relay session ID.

A proof ticket contains only a unique opaque issuer ticket ID, event type/source, participant count, completion time and expiry.

Authenticated redemption binds the proof to whichever Cardverse account owns the bearer session at redemption time.

Database uniqueness prevents one proof ticket being redeemed into two accounts.

## 6. Quest proof limits are intentionally strict

Anonymous relay completion proves that a real 1:1 Zync happened. It does **not** prove client-only semantic claims.

Relay proof therefore stores:

- `repeat_person = NULL`;
- no interest categories.

Only an explicitly trusted `repeat_person = false` can count as a new-person proof.

Therefore relay-issued proof can support action-count quests such as:

- `daily_make_a_zync`;
- `weekly_real_world_three`.

It cannot by itself satisfy:

- `weekly_meet_two_new_people`;
- `weekly_three_interest_worlds`.

Do not weaken this rule by accepting client assertions for repeat-person or interest-category status.

## 7. Mobile proof capture and cloud foundation

The app now captures anonymous relay proof sidecar data without requiring Cardverse login.

Host:

- successful relay consume may return host proof ticket;
- ticket is associated with the exact local progress-event ID.

Scanner:

- relay respond may return a private proof capability;
- app polls for completion;
- if host has not consumed yet, capability is retained temporarily and retried;
- once ready, it is promoted to the scanner proof ticket.

The local progress-event ID is deterministic per relay role:

- host: `relay:<sessionId>:host`
- scanner: `relay:<sessionId>:scanner`

The event-time timezone offset is stored with the proof so later redemption cannot move a Quest event into the wrong daily/weekly cycle.

## 8. Sensitive mobile capabilities are securely stored

Session tokens, anonymous proof tickets and scanner proof capabilities are bearer capabilities.

They are **not** stored in SharedPreferences.

Implemented:

- `flutter_secure_storage ^10.3.4`;
- shared secure key-value abstraction;
- Cardverse session as one atomic encrypted credential blob;
- proof-ticket queue in secure storage;
- proof-capability queue in secure storage;
- malformed/expired secure session fails closed and is removed;
- Android generated manifest is hardened with `android:allowBackup="false"` so secure Cardverse bearer state is not cloud-backed up to another device.

Ordinary local-first People/conversation data remains unchanged.

## 9. Cardverse mobile cloud client

A non-UI mobile cloud foundation now exists:

- auth challenge request;
- provider token exchange;
- secure session credential model;
- authenticated inventory fetch;
- authenticated anonymous proof redemption;
- logout;
- HTTPS-only API base;
- server error mapping;
- client never sends Cardverse account ID.

Pending proof sync behavior:

- no Cardverse session -> proof stays local;
- valid secure session -> proof is redeemed;
- success -> local proof removed;
- 401 -> session cleared, proof retained;
- transient failure / disabled server -> proof retained;
- invalid / expired / already-redeemed proof -> discarded.

No production login UI has been added yet.

## 10. Fail-open sidecar guarantee

Cardverse proof collection is optional sidecar behavior.

Secure-storage/plugin/proof-capture failure must never break the already-successful face-to-face Zync flow.

This is explicitly tested for both host and scanner paths.

## 11. Runtime gates still CLOSED

All Cardverse cloud endpoints are disabled unless explicitly enabled.

Relevant gates include:

- `CARDVERSE_API_ENABLED`
- `CARDVERSE_PACK_OPEN_ENABLED`
- `CARDVERSE_QUEST_CLAIM_ENABLED`
- `CARDVERSE_PROOF_REDEEM_ENABLED`

Proof signing additionally requires:

- `ZYNC_CARDVERSE_PROOF_SECRET`

No production environment should enable these casually.

## 12. Major commits in this milestone continuation

Key implementation commits after the previous reward-loop handoff include:

- `b5fdca6e` — durable ownership foundation
- `ec121bbf` — transactional pack-open core
- `8407009c` — execute migrations on real PostgreSQL in CI
- `29605b5c` / `5fe90374` — authenticated account/session foundation
- `853062df` — fail-closed server pack policy boundary
- `61647a2f` — trusted Quest reward ledger
- `8203b34d` — anonymous relay completion proof tickets
- `0fc4baca` — explicit new-person proof fix
- `762c36aa` / `6c4577f8` — mobile relay proof capture + interface alignment
- `91d23da4` — secure Cardverse mobile cloud foundation
- `76230e1b` — secure storage for Cardverse bearer capabilities
- `b66a64b5` — proof-aware release contract
- `aa2c1694` — proof capture fail-open guarantee
- `233972a9` — exact bearer-header test repair
- `dfeda4cb` — Android backup hardening

## 13. What remains before real Cardverse cloud can be enabled

Do not treat Milestone 5 as production-open yet.

Remaining production blockers:

1. provision the real managed PostgreSQL database and apply certified migrations;
2. configure production Google/Apple client IDs and provider settings;
3. add auth endpoint / proof redemption / pack-open / claim rate limiting and abuse controls;
4. add real Cardverse login/account UI and secure session lifecycle UX;
5. add account recovery / unlink / deletion lifecycle;
6. approve a real production pack-odds/policy configuration;
7. decide how to trustedly prove new-person and interest-world quests without uploading the social graph;
8. run live environment smoke tests with kill switches still controlled;
9. keep Collection/Pack/Cardverse Labs internal until explicit product release decision.

## 14. Recommended continuation order

Continue directly from here. Do not restart repo discovery.

Recommended next task:

1. build server-side abuse/rate-limit gates for Cardverse auth challenge/provider exchange, proof redemption, Quest claim and pack open;
2. add session/account lifecycle controls;
3. then prepare live managed PostgreSQL provisioning and migration checklist;
4. only after provider configuration exists, wire production-ready mobile login + proof auto-sync;
5. keep Production and Google Play CLOSED throughout.

Do not weaken the local-first/privacy boundary merely to make more Quest types claimable.

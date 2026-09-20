# Zync Cardverse Live Cloud Deployment Checklist V1

Status: **internal pre-production runbook**

Branch: `zync-v1-rebuild-20260917`

Production: **CLOSED**

Google Play: **CLOSED**

This runbook prepares Cardverse cloud for a controlled staging/live smoke without changing the release decision. Runtime switches remain off until every prerequisite below is satisfied.

## 1. Infrastructure prerequisites

Provision one managed PostgreSQL database with normal PostgreSQL semantics and a pooled serverless-safe connection string.

Initial managed candidate: Neon PostgreSQL. The application remains provider-neutral through `DATABASE_URL`.

Required server secrets:

- `DATABASE_URL`
- `CARDVERSE_DATABASE_SSL=require`
- `UPSTASH_REDIS_REST_URL`
- `UPSTASH_REDIS_REST_TOKEN`
- `ZYNC_CARDVERSE_RATE_LIMIT_SECRET` — independent high-entropy secret, minimum 24 characters
- `ZYNC_CARDVERSE_READINESS_SECRET` — independent operator-only readiness secret, minimum 32 characters
- `ZYNC_GOOGLE_CLIENT_IDS` before Google login is enabled
- `ZYNC_APPLE_CLIENT_IDS` before Apple login is enabled
- `ZYNC_CARDVERSE_PROOF_SECRET` before relay proof issuance/redemption is enabled
- approved `CARDVERSE_PACK_POLICY_V1` before pack opening is enabled

Never place database credentials, Redis credentials, HMAC secrets, provider private configuration or pack policy authority in Flutter.

The readiness route is separately hidden unless `CARDVERSE_READINESS_ENABLED=true`; it does not require `CARDVERSE_API_ENABLED=true`, so staging prerequisites can be checked before opening the Cardverse API.

## 2. Migration order

Keep all Cardverse runtime gates off.

Apply migrations in filename order:

1. `0001_cardverse_ownership.sql`
2. `0002_cardverse_pack_rolls.sql`
3. `0003_cardverse_auth_sessions.sql`
4. `0004_cardverse_reward_proofs.sql`
5. `0005_cardverse_relay_proof_tickets.sql`
6. `0006_cardverse_account_lifecycle.sql`

Do not down-migrate the immutable inventory ledger in a live environment.

After migration, run the same PostgreSQL constraint contract used by CI against a disposable staging database before any production smoke.

## 3. Abuse-control prerequisite

Before setting `CARDVERSE_API_ENABLED=true`, the distributed Cardverse abuse guard must be healthy.

It uses Upstash Redis only for short-lived counters. Redis never becomes Cardverse ownership authority.

Rate-limit keys contain only HMAC digests. Raw client IP addresses and raw account UUIDs are not stored in rate-limit keys.

Current default one-minute ceilings:

- auth challenge: 20 / IP
- provider exchange: 10 / IP
- proof redemption: 120 / IP and 60 / account
- Quest claim: 120 / IP and 30 / account
- pack open: 120 / IP and 30 / account
- account lifecycle: 30 / IP and 10 / account

These defaults may be lowered through the documented `CARDVERSE_RL_*` environment variables. Configuration or Redis failure is fail-closed for Cardverse protected endpoints.

HTTP 429 responses include `Retry-After`.

## 4. Session/account lifecycle prerequisite

Current server controls:

- opaque bearer tokens; only SHA-256 hashes persisted;
- default 30-day session TTL;
- default maximum 8 active sessions per account, configurable with `CARDVERSE_MAX_ACTIVE_SESSIONS`, maximum 32;
- logout current session;
- logout all sessions;
- secondary Google/Apple identity link with provider re-authentication;
- identity unlink with provider re-authentication;
- the last active identity cannot be unlinked;
- unlink revokes all active sessions;
- soft-unlinked provider subjects are tombstoned and cannot silently create a different owner;
- logical account deletion requires explicit `DELETE` confirmation plus provider re-authentication;
- account deletion revokes all sessions and removes stored provider email metadata.

Self-service recovery is by a second linked provider. No support/admin identity override is approved in V1.

Account lifecycle routes stay hidden unless:

- `CARDVERSE_API_ENABLED=true`
- `CARDVERSE_ACCOUNT_LIFECYCLE_ENABLED=true`

## 5. Operator readiness probe

Before enabling the global Cardverse API in staging:

1. set `CARDVERSE_READINESS_ENABLED=true`;
2. configure a distinct `ZYNC_CARDVERSE_READINESS_SECRET`;
3. call `GET /api/v1/cardverse/readiness` with `Authorization: Bearer <operator-secret>`;
4. require HTTP 200 and `ready: true` before proceeding;
5. wrong/missing readiness credentials must return 404;
6. turn the readiness gate back off after the staging smoke if it is not operationally needed.

The probe exposes only boolean health/configuration state. It never returns database URLs, Redis tokens, provider client IDs, proof secrets or pack-policy contents.

Base readiness requires:

- PostgreSQL configured and reachable, with the required Cardverse tables/lifecycle columns present after migrations;
- distributed Redis abuse guard configured and reachable;
- at least one Google/Apple provider audience configured.

If a feature gate is already enabled, the probe additionally requires its critical dependency, for example a valid pack policy for Pack Open and a proof secret for Proof Redeem.

## 6. Provider configuration smoke

Do not enable global Cardverse API until at least one real provider configuration is complete.

For each enabled provider:

1. request a single-use Cardverse auth challenge;
2. pass its nonce through the native Google/Apple authentication flow;
3. verify the provider ID token audience, issuer, signature, expiry and nonce server-side;
4. confirm a new account can be created;
5. confirm repeat login resolves the same internal account UUID;
6. confirm an invalid/replayed challenge is rejected;
7. confirm an unlinked identity cannot silently create a fresh owner;
8. confirm no provider ID token appears in logs.

## 7. Controlled enablement order

Keep Production and Play closed while performing this sequence.

1. migrations complete;
2. Redis abuse guard configured and healthy;
3. provider audiences configured;
4. operator readiness probe returns HTTP 200 with `ready: true` while the Cardverse API is still closed;
5. set `CARDVERSE_API_ENABLED=true` only in staging;
6. verify challenge/provider/inventory/logout;
7. optionally enable `CARDVERSE_ACCOUNT_LIFECYCLE_ENABLED=true` in staging and test link/unlink/logout-all/delete using test accounts;
8. configure proof secret, then optionally enable `CARDVERSE_PROOF_REDEEM_ENABLED=true`;
9. only after trusted proof smoke, optionally enable `CARDVERSE_QUEST_CLAIM_ENABLED=true`;
10. only after explicit odds/policy approval, optionally enable `CARDVERSE_PACK_OPEN_ENABLED=true`.

Never enable Quest Claim or Pack Open merely because the global API gate is enabled.

## 8. Failure / rollback posture

The first rollback action is runtime disablement, not destructive database reversal.

- set the affected feature gate false;
- if necessary set `CARDVERSE_API_ENABLED=false`;
- leave durable PostgreSQL ownership/ledger data intact;
- preserve immutable ledger evidence;
- ordinary face-to-face Zync remains local-first and must continue working.

A Redis outage must block protected Cardverse mutations/auth attempts rather than silently bypassing abuse controls.

A PostgreSQL outage must not cause client-side minting, ownership transfer or pack RNG.

## 9. Observability rules

Monitor aggregate:

- 429 counts by endpoint/profile;
- 401/403/409 rates;
- database connection errors;
- Redis abuse-guard availability errors;
- provider verification failures;
- proof replay conflicts;
- Quest idempotency conflicts;
- pack-open transaction failures.

Do not log:

- provider ID tokens;
- raw bearer tokens;
- raw proof tickets/capabilities;
- raw client IP addresses for Cardverse abuse monitoring;
- peer identity/social graph;
- raw QR payloads;
- question transcripts.

## 10. Release gate

Completing this runbook does not itself open Cardverse.

Before a public release decision, still require:

- real provider config;
- staging/live smoke evidence;
- approved pack policy;
- production mobile login/account UX;
- proof auto-sync UX;
- multi-device restore QA;
- privacy/deletion retention review;
- explicit Cardverse Labs/Home exposure decision.

Until then:

- Cardverse Labs remain internal;
- Production remains CLOSED;
- Google Play remains CLOSED;
- Draft PR #1 remains DO NOT MERGE.

# Zync — Neon Staging Provisioned and Cardverse Schema Certified

Date: 2026-09-20

Branch: `zync-v1-rebuild-20260917`

## Certified code state before this infrastructure step

Previously certified implementation head:

`346b8daf95eca4006cadfcd2f48a1b9e24ac4e0d`

Checks on that head:
- Zync V1 CI #986 — SUCCESS
- Zync QA Preview APK #279 — SUCCESS

Production remains CLOSED.
Google Play remains CLOSED.
Draft PR #1 remains DO NOT MERGE.

## Neon staging infrastructure now provisioned

Connected Neon project:
- Project name: `Zync`
- Project id: `purple-rice-79852073`
- Region: `aws-ap-southeast-1` (Singapore)
- PostgreSQL: 18
- Default database: `neondb`
- Default Neon branch: `production`
- Default branch id: `br-floral-waterfall-b3ndsacc`

Important: the Neon branch name `production` is only Neon's default branch name. It does NOT mean Zync production is enabled.

Created isolated staging branch:
- Name: `staging-cardverse`
- Branch id: `br-flat-moon-b32kc1kf`
- Parent: `br-floral-waterfall-b3ndsacc`
- State: ready

## Cardverse migrations applied to staging-cardverse

Applied the repository's authoritative migrations in order:
1. `db/migrations/0001_cardverse_ownership.sql`
2. `db/migrations/0002_cardverse_pack_rolls.sql`
3. `db/migrations/0003_cardverse_auth_sessions.sql`
4. `db/migrations/0004_cardverse_reward_proofs.sql`
5. `db/migrations/0005_cardverse_relay_proof_tickets.sql`
6. `db/migrations/0006_cardverse_account_lifecycle.sql`

The migrations were executed as 48 individual statements in one Neon transaction after stripping migration-level BEGIN/COMMIT wrappers. The transaction completed successfully.

## Verified staging invariants

Verified on `staging-cardverse / neondb`:
- 15 required Cardverse/Zync tables exist.
- `zync_accounts.deleted_at` exists.
- `zync_identity_links.unlinked_at` exists.
- `cardverse_inventory_ledger_immutable` trigger exists.
- `cardverse_reward_proofs_issuer_ticket_uidx` exists.
- `pgcrypto` extension exists.

Current tables:
- cardverse_auth_challenges
- cardverse_draw_token_balances
- cardverse_idempotency_records
- cardverse_inventory_ledger
- cardverse_pack_entitlements
- cardverse_pack_roll_items
- cardverse_pack_rolls
- cardverse_reward_grant_proofs
- cardverse_reward_grants
- cardverse_reward_proofs
- cardverse_stack_balances
- cardverse_unique_instances
- zync_account_sessions
- zync_accounts
- zync_identity_links

## Next blocker

The database side is no longer the blocker.

Next staging steps:
1. Add the staging Neon pooled `DATABASE_URL` to the Zync Vercel Preview environment.
2. Confirm existing Upstash REST URL/token are available to the preview deployment.
3. Add strong server-only secrets:
   - `ZYNC_CARDVERSE_RATE_LIMIT_SECRET`
   - `ZYNC_CARDVERSE_READINESS_SECRET`
4. Configure at least one provider audience (Google first is practical for current Android QA).
5. Keep `CARDVERSE_API_ENABLED=false` initially.
6. Deploy an isolated preview/staging target.
7. Call the operator-only readiness endpoint and require `ready: true`.
8. Only then perform real provider login + proof auto-sync smoke testing.

The currently connected Vercel integration exposes project/deployment reads but no environment-variable write action, so do not print or commit database/secrets. Use the Vercel dashboard for the minimal secret insertion unless a safe write-capable integration becomes available.

## Preserve boundaries

- Do not use Neon Auth.
- Do not enable Production.
- Do not enable Google Play.
- Do not expose Neon connection strings or secret values in chat, source, CI logs or handoff files.
- Keep Cardverse runtime gates off until staging readiness passes.

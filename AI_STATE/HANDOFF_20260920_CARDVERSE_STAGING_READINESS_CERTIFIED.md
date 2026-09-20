# Zync — Cardverse Staging Readiness Certified

Date: 2026-09-20

Branch: `zync-v1-rebuild-20260917`

## Current infrastructure state

Neon project `Zync`:
- project id: `purple-rice-79852073`
- region: Singapore (`aws-ap-southeast-1`)
- PostgreSQL 18
- staging branch: `staging-cardverse`
- branch id: `br-flat-moon-b32kc1kf`
- database: `neondb`

Migrations `0001` through `0006` are applied to `staging-cardverse`.

Verified staging schema:
- all 15 required Cardverse/Zync tables exist
- `zync_accounts.deleted_at`
- `zync_identity_links.unlinked_at`
- immutable ledger trigger
- proof-ticket replay unique index
- pgcrypto

## Vercel Preview readiness result

A temporary Preview build-time smoke was used because the current Hobby plan blocks the full deployment once more than 12 Serverless Functions are emitted.

The live Cardverse readiness probe logic was executed inside the Vercel Preview build environment against the configured Preview environment variables.

Final result after adding the Google Web OAuth client audience:
- database configured: PASS
- database reachable: PASS
- database schema ready: PASS
- abuse guard configured: PASS
- abuse guard Redis reachable: PASS
- at least one provider audience configured: PASS
- enabled feature dependencies: PASS
- overall Cardverse readiness: READY

Evidence: the diagnostic build command returned exit code 0. Vercel then failed later only because the temporary diagnostic build intentionally produced no `public` output directory. Earlier encoded failures narrowed correctly from 56 to 32 before the Google audience was added.

## Preview gate cleanup

After readiness certification:
- removed temporary `buildCommand` from `vercel.json`
- restored `git.deploymentEnabled.zync-v1-rebuild-20260917=false`
- Production remains CLOSED
- Google Play remains CLOSED
- Cardverse global API remains false unless explicitly changed in staging later

Cleanup commit:
`36646184b18638280b7c37c447b43a5b00b46acf`

## Important Vercel Hobby blocker

A normal deployment of the current branch fails with:
`exceeded_serverless_functions_per_deployment`

The Hobby plan allows at most 12 Serverless Functions per deployment, while the current repository emits more than 12 API functions.

This must be solved before a full staging Cardverse API smoke can run. Preferred technical fix is to consolidate Vercel entrypoints without weakening route isolation/security, rather than upgrading blindly.

## Google OAuth state

A Google Auth Platform project is configured for Zync.

A Web application OAuth client was created and its Client ID was added to Vercel Preview as:
`ZYNC_GOOGLE_CLIENT_IDS`

Do not store or expose the OAuth client secret; the current backend does not require it for Google ID-token verification.

Next required work:
1. solve the Vercel 12-function Hobby deployment limit safely;
2. determine stable Android QA signing identity / SHA-1;
3. create the matching Android OAuth client;
4. integrate current Google Sign-In package APIs into Flutter with the existing server nonce challenge;
5. deploy controlled staging API and run real-device login/session/proof-sync smoke;
6. keep Production and Play closed.

## Boundaries

- Do not put the staging Neon `DATABASE_URL` into Production.
- Do not enable Cardverse production gates.
- Do not enable Google Play.
- Do not print secrets into source, logs, or chat.
- Draft PR #1 remains DO NOT MERGE.

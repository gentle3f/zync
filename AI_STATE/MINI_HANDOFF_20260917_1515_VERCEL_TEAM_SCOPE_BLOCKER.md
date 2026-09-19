# Zync V1 — Mini Handoff: Vercel Team Scope Identified / Connector Re-auth Required

Date: 2026-09-17
Branch: `zync-v1-rebuild-20260917`

## User-supplied Vercel project evidence

User confirmed the existing Vercel project is `zync` and supplied:

- deployment hostname: `zync-hvjknkrj3-gens-projects-4f99f8b9.vercel.app`
- production/public domain: `https://zync-inky.vercel.app/`
- Vercel project dashboard path indicates scope/project: `gens-projects-4f99f8b9/zync`

## Exact connector blocker discovered

Targeted Vercel API read against project `zync` and scope `gens-projects-4f99f8b9` returns HTTP 403 with explicit Vercel error:

`Not authorized: Trying to access resource under scope "gens-projects-4f99f8b9". You must re-authenticate to this scope or use a token with access to this scope.`

Vercel also returned the concrete team ID:

`team_jynHypQ0VPNT6nwooTRyFG4B`

Therefore the blocker is no longer project discovery. The project/scope is known; the connected Vercel authorization currently does not include that team scope.

`list_teams` still returns `teams: []`, consistent with missing team authorization. `list_deployments`, `get_deployment`, runtime logs and protected deployment fetch all fail with the same team-scope authorization issue.

## Resume rule

Do not rediscover the Vercel project. Once the Vercel connection is re-authorized for team `gens-projects-4f99f8b9` / `team_jynHypQ0VPNT6nwooTRyFG4B`, continue directly with:

1. `get_project` / `list_deployments` for `zync`.
2. Confirm which deployment is production and whether `zync-inky.vercel.app` is the intended stable production origin.
3. Inspect project/deployment state and available environment configuration without exposing secrets.
4. Deploy current hardened V1 branch only after confirming project linkage/behavior; do not create a second unrelated `zync` project.
5. Set/confirm GitHub repository variable `ZYNC_API_BASE=https://<confirmed production origin>` when the correct production origin is proven.
6. Run production live smoke for `/api/v1/normalize-interest`, `/api/v1/question`, and `/api/v1/analytics` as already implemented by `.github/scripts/live_api_smoke.mjs`.
7. Preserve OpenRouter ZDR + `data_collection: deny` privacy invariant.

Do not guess deployment state or claim the current public domain is serving the new hardened V1 until live evidence exists.

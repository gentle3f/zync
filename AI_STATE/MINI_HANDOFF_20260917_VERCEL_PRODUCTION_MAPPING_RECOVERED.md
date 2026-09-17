# Zync V1 — Mini Handoff: Vercel Production Mapping Recovered

Date: 2026-09-17
Branch: `zync-v1-rebuild-20260917`

## Vercel access recovered

The Vercel connector is now authorized to the correct team scope.

- Team slug/scope: `gens-projects-4f99f8b9`
- Team ID: `team_jynHypQ0VPNT6nwooTRyFG4B`
- Project: `zync`
- Project ID: `prj_GayyH1E1oWeliJew8P2gWLiiqH0A`

`get_project` succeeds and shows the GitHub-connected project.

## Stable production mapping

`https://zync-inky.vercel.app` resolves to production deployment:

- deployment ID: `dpl_8a6uG7TzDdrDALJGbXSkFhD9iP8x`
- deployment URL: `zync-hvjknkrj3-gens-projects-4f99f8b9.vercel.app`
- target: `production`
- state: `READY`
- Git ref: `main`
- Git commit: `0c40be9bfd6e2ac17e1a2d22aeec77995231d596`
- commit message: `Add files via upload`

Aliases on that production deployment include:
- `zync-inky.vercel.app`
- `zync-gens-projects-4f99f8b9.vercel.app`
- `zync-git-main-gens-projects-4f99f8b9.vercel.app`

## Critical production finding

Current production is still the old main deployment and does **not** contain the V1 API routes.

Direct check:
- `GET https://zync-inky.vercel.app/api/v1/question` -> HTTP 404 / Vercel `NOT_FOUND`.

Therefore `https://zync-inky.vercel.app` is the correct stable production domain, but it is **not yet safe to configure as `ZYNC_API_BASE` for the V1 release until the hardened V1 backend is promoted/deployed to production**.

## Current V1 preview evidence

Recent GitHub pushes on branch `zync-v1-rebuild-20260917` are automatically deployed by Vercel as READY preview deployments with `target: null`.

Latest observed preview at this checkpoint:
- deployment ID: `dpl_9BFEg1TCuF94pfygAuweiJjyx9i3`
- URL: `zync-pfqhvntow-gens-projects-4f99f8b9.vercel.app`
- Git commit: `fb1f9416400470bdb7c14ce4021e1d853acaecb9`
- branch: `zync-v1-rebuild-20260917`
- state: `READY`

Direct preview check:
- `GET /api/v1/question` -> HTTP 405 with `Allow: POST`, proving the V1 route exists on the branch preview.

The preview deployment is protected by Vercel Authentication for some requests. The connector can create a temporary share URL, but its fetch helper does not persist the SSO cookie reliably for every protected route. Build-log access also returned a separate 401. This is a tooling/permission limitation, not evidence that the V1 route is absent.

## Immediate next step

Do **not** point the signed Play build at production yet.

Next required release step is to promote/deploy the current hardened `zync-v1-rebuild-20260917` backend to the existing `zync` production project/domain, without creating a second project and without overwriting `main` casually.

After production promotion, run the real POST live smoke against:
- `/api/v1/normalize-interest`
- `/api/v1/question`
- `/api/v1/analytics`

and require the V1/ZDR privacy contract before setting:

`ZYNC_API_BASE=https://zync-inky.vercel.app`

Do not claim production integration complete until those POST smokes pass.

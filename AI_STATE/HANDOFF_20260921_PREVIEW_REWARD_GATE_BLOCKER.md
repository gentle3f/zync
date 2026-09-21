# Zync — Authoritative Handoff — Preview Reward Gate Blocker

Date: 2026-09-21
Branch: `zync-v1-rebuild-20260917`

Production: **CLOSED**
Google Play: **CLOSED**
Draft PR #1: **DO NOT MERGE**

## 1. Staging migration 0007 applied

User explicitly approved migration 0007.

Applied directly to Neon staging only:

- project: `purple-rice-79852073`
- branch: `br-flat-moon-b32kc1kf`
- database: `neondb`

Verified live constraint now accepts:

`draw_token_spend`

Verified column comment:

`Append-only economy event. draw_token_spend records one Draw Token consumed for one server-authoritative single-card draw.`

No Production database was touched.

## 2. Latest Preview deployment

Automatic branch deployment was temporarily enabled, then closed again.

Deployment commit:

`7bf92d7c01d7718b3ca33f56abc8b3996b15c24e`

Preview deployment:

- id: `dpl_9jT4TvDvHwoncS4C4cmKh8ZBNbQY`
- URL: `https://zync-7xpr2my57-gens-projects-4f99f8b9.vercel.app`
- state: READY

Automatic Preview deployment was immediately closed again in:

`b4de6109d123040a49351d7b80764eb18a02e6e1`

## 3. Live probe result

Latest Preview code is deployed.

Current live GET probes:

- `/api/v1/cardverse/inventory` → **401 cardverse_session_missing**
  - proves consolidated Cardverse API is live and enabled.
- `/api/v1/cardverse/quests/claim` → **404 not_found**
- `/api/v1/cardverse/packs/open` → **404 not_found**
- `/api/v1/cardverse/proofs/redeem` → **404 not_found**
- `/api/v1/cardverse/draws/redeem` → **404 not_found**
- `/api/v1/cardverse/rewards/daily-login` → **404 not_found**

Those 404s are expected from the feature gates, not missing routes.

Required Preview-only gates:

- `CARDVERSE_PROOF_REDEEM_ENABLED=true`
- `CARDVERSE_QUEST_CLAIM_ENABLED=true`
- `CARDVERSE_PACK_OPEN_ENABLED=true`
- `CARDVERSE_DRAW_ENABLED=true`

Daily Login intentionally uses the Quest Claim gate.

Do not enable these in Production.

## 4. Dependency checks before gate enable

The server code requires:

- `ZYNC_CARDVERSE_PROOF_SECRET` for trusted proof flow;
- valid `CARDVERSE_PACK_POLICY_V1` for Pack Open and single-card Draw;
- existing Cardverse DB / session / Redis dependencies.

The current Vercel connector cannot edit or reveal Preview environment variables, so these must be confirmed/set in Vercel Preview settings by the user.

## 5. Next exact step

After the four Preview gates are set:

1. redeploy Preview once;
2. probe routes again;
3. expected unauthenticated result changes from **404** to **405** or **401** depending route/method/auth ordering;
4. build/install latest QA APK;
5. physical Android test:
   - Google/Zync Account;
   - Daily Check-in → +1 Draw;
   - single-card Draw;
   - task → Claim;
   - Pack Open;
   - five-card reveal;
   - My Zync World restore after logout/login.

Keep Production and Play closed.

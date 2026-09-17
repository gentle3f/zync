# Zync V1 — Upstash Preview Smoke PASS Mini Handoff

Date: 2026-09-18 HKT
Branch: `zync-v1-rebuild-20260917`

This is additive. Preserve all earlier `AI_STATE` handoffs, especially `HANDOFF_20260918_RELAY_PAIRING_RESPONSIVE_CERTIFIED.md`.

## External relay configuration is now connected

The user linked the existing Upstash Redis database `brandbook-rate-limit` to the Vercel project `zync` rather than creating a second database. The Vercel project now has the Upstash REST environment names `UPSTASH_REDIS_REST_URL`, `UPSTASH_REDIS_REST_TOKEN`, plus the unrelated `REDIS_URL`. The user also added server-only `ZYNC_RELAY_RATE_LIMIT_SECRET`. Secret values were never pasted into chat or committed.

Backend compatibility was hardened so `api/v1/relay.js` accepts either `UPSTASH_REDIS_REST_URL/TOKEN` or Vercel KV aliases `KV_REST_API_URL/TOKEN`. CI #160 / run `35247823265` passed all gates after this change.

## Controlled preview deployment

A one-off preview was created from commit `4ec295d08b8f45ab734d99db7ee2e2b71ff29d71` by temporarily enabling Git deployment for the branch. As soon as Vercel detected the preview, branch auto-deploy was restored to false in commit `bdc63052234b501d290f96fa7aa9e561e5089eec`.

Preview deployment:
- deployment ID: `dpl_HMpfKfSwSb4kceTJH2ThCw3UCcdx`
- URL: `https://zync-rkrlbekvu-gens-projects-4f99f8b9.vercel.app`
- branch alias: `https://zync-git-zync-v1-rebuild-20260917-gens-projects-4f99f8b9.vercel.app`
- state: READY
- region: `iad1`
- target: preview (`target: null`), not production

Vercel Authentication on Preview was temporarily turned off by the user to allow external smoke tests and upcoming two-device QA. Production was not changed. Re-enable Preview Authentication after physical QA is finished.

## Real Upstash relay smoke PASS

A one-shot GitHub Actions workflow called `Zync Preview Relay Smoke` ran against the actual preview URL, not mocks.

Run:
- run ID: `35249412965`
- job ID: `105297748003`
- head: `9ddc17cc95c9ad9c29c331d83053088cfada3b85`
- conclusion: success

Live log proved:
- create session succeeds against live Vercel -> Upstash
- create retry is idempotent
- wrong host token cannot poll (403)
- scanner response is stored
- a different duplicate scanner response is rejected
- host polling is non-destructive
- authenticated consume deletes the session immediately
- a separate 15-second abandoned session disappeared after 16.5 seconds solely by Redis TTL, with no cleanup schedule

The temporary smoke workflow was removed after success. The reusable script `.github/scripts/preview_relay_smoke.mjs` may remain as test collateral.

## Current active task: two-device Android physical QA

The Flutter relay client reads `ZYNC_API_BASE` from `--dart-define`; it does not hard-code production. Therefore a physical QA build must explicitly point to the preview URL.

A one-shot workflow `Zync Preview QA APK` was added to build an installable test APK that:
- uses API base `https://zync-rkrlbekvu-gens-projects-4f99f8b9.vercel.app`
- uses preview `/privacy`
- has analytics disabled
- uses a separate Android application ID `com.gmail.gentle3f.myproject.qa`
- displays as `Zync QA`
- therefore can coexist with an existing Zync install
- does not upload to Play

Current QA APK workflow:
- run ID: `35249635868`
- job ID: `105298499598`
- head commit: `3e20a5d8f7d250ea3683949697bd1ecb2e5a7568`
- status at checkpoint: in progress, Flutter setup/build

## Immediate continuation order

1. Check QA APK run `35249635868` until complete.
2. If it fails, fetch the job log and fix only the proven issue.
3. If green, fetch artifact metadata and download `zync-preview-qa-apk` for the user.
4. Remove the temporary QA workflow after successful artifact creation; keep branch auto-deploy false.
5. Give exact two-phone test steps: install `Zync QA` on both phones; create distinct local profiles; A Show QR; B scan exactly once; verify B enters Match and A auto-enters Match without taps; verify same shared interests/order; repeat after app background/resume; test expired QR/regenerate and duplicate scan messaging; verify normal Home/Show QR need no vertical scroll on normal phones.
6. Record physical QA results. Only after physical QA passes should Preview Authentication be re-enabled, then proceed to signed production release/Play test track under the existing one-shot release plan.

Do not deploy/promote production or upload Play yet.

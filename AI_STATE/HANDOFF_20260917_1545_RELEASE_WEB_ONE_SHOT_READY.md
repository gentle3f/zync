# Zync V1 — Release Web + One-Shot Production Readiness Handoff

Date: 2026-09-17 15:45 HKT  
Branch: `zync-v1-rebuild-20260917`

This handoff is additive. Preserve all earlier handoffs and mini-handoffs. The prior `AI_STATE/LATEST_HANDOFF.md` pointed to `AI_STATE/HANDOFF_20260917_1418_PRIVACY_HARDENED_RELEASE_CANDIDATE.md`; that earlier lineage remains valid historical context.

## 1. Do not restart discovery

Continue from this state. Do not restart old Thunkable archaeology, repo discovery, or re-derive the Vercel scope.

## 2. Vercel project and production mapping recovered

Confirmed project:

- project name: `zync`
- project ID: `prj_GayyH1E1oWeliJew8P2gWLiiqH0A`
- team ID: `team_jynHypQ0VPNT6nwooTRyFG4B`
- scope: `gens-projects-4f99f8b9`
- stable production domain: `https://zync-inky.vercel.app`

Current production alias still points to the old 2025 `main` deployment/commit, not rebuilt V1. Old production `/api/v1/question` returned 404. Recent rebuilt branch previews expose the V1 route but were preview deployments, not production.

## 3. Vercel environment configured by release owner

The release owner has added:

- `OPENROUTER_API_KEY` (secret; never expose)
- `OPENROUTER_MODEL=openrouter/free`
- `ZYNC_PUBLIC_URL=https://zync-inky.vercel.app`

Environment changes require a fresh deployment; they do not retroactively affect old deployments.

## 4. Deployment quota blocker and mitigation

Vercel Hobby hit rolling 24-hour deployment quota:

`api-deployments-free-per-day` / more than 100 deployments.

Cause: the Git integration created a preview for many granular branch commits.

Mitigation is now committed in `vercel.json`:

```json
"git": {
  "deploymentEnabled": {
    "zync-v1-rebuild-20260917": false
  }
}
```

Verified after this change: querying deployments newer than the last prior preview returned **0 deployments**, so later code/docs/CI commits no longer consume Vercel deployment quota.

Keep branch auto-deploy disabled during normal development.

## 5. OpenRouter production posture

Both V1 AI endpoints already default to:

`openrouter/free`

OpenRouter's current free-model router is `openrouter/free`. Requests remain constrained by:

```json
"provider": {
  "zdr": true,
  "data_collection": "deny"
}
```

Both AI endpoints now use `https://zync-inky.vercel.app` as the OpenRouter `HTTP-Referer` fallback rather than the old placeholder `https://zync.app`.

If no free route satisfies ZDR/data-collection-deny, AI must fail/fallback locally. Do not weaken privacy controls just to make free inference succeed.

## 6. Public V1 analytics posture changed to true default-OFF

Audit found that the earlier client would attempt analytics whenever `ZYNC_API_BASE` existed, even if PostHog was not configured. That still transmits analytics IDs/events off-device to Vercel.

Fixed in `mobile/lib/core/analytics_service.dart`:

- new compile-time flag `ZYNC_ANALYTICS_ENABLED`;
- default is `false`;
- `track()` returns before creating an install/session ID or making any network request when disabled.

Normal CI and signed-release workflow both explicitly build with:

`--dart-define=ZYNC_ANALYTICS_ENABLED=false`

Therefore public V1 does not need PostHog and should not claim analytics collection in the public V1 Data Safety answer.

Relevant commits include:

- `c43e5328440825cbbe14c3ee0491e97f7afd2f84` — analytics explicit opt-in
- `199c4ad6d001bfc132fcf2d1cba708dc6a622f70` — default-off test

## 7. Public legal web pages created

Static, no-JavaScript-required HTML pages now exist:

- `privacy.html`
- `terms.html`
- `disclaimer.html`

`vercel.json` rewrites them to stable production routes:

- `/privacy` -> `/privacy.html`
- `/terms` -> `/terms.html`
- `/disclaimer` -> `/disclaimer.html`

Intended production URLs:

- `https://zync-inky.vercel.app/privacy`
- `https://zync-inky.vercel.app/terms`
- `https://zync-inky.vercel.app/disclaimer`

Privacy policy includes:

- Zync/package identity;
- no account / local profile and history;
- QR sharing boundary;
- AI normalization/question data flow;
- Vercel + OpenRouter providers;
- ZDR/data-collection-deny statement;
- analytics default-off public V1 posture;
- HTTPS/security description;
- retention/deletion description;
- privacy inquiry mechanism via the official Google Play Developer contact.

This avoids inventing or exposing a private email address.

Google Play policy was checked on 2026-09-17: privacy policy must be active/public/non-geofenced/non-PDF/non-editable, linked in app and Play Console, identify the app or listing entity, provide privacy contact/inquiry mechanism, and describe data handling/security/retention/deletion.

Relevant commits:

- `1e36f6232d182ea48dee9e5040c8d4a703cc24b2` — privacy page
- `b75556567334ae05606c7fc23bcfaafae3a28160` — terms page
- `ba89e39ef51651eaa5ff8ca766627790151447c8` — disclaimer page
- `39d8d0362ffc5dfeaf7c4ee885514b048cfab5ae` — stable Vercel routes/security headers

## 8. Release web contracts / CI hardening

Added `.github/scripts/release_web_contracts.mjs`.

It gates:

- all 3 legal pages are plain mobile-readable HTML;
- no release placeholders;
- privacy page contains package/provider/ZDR/retention/security/contact facts;
- stable Vercel rewrites exist;
- analytics flag exists and defaults false;
- signed-release workflow keeps production live smoke;
- signed release includes privacy URL;
- signed AAB build pins analytics false;
- strict `jarsigner -verify -strict` remains.

Normal CI now triggers when the signed-release workflow changes.

Relevant commits:

- `54477bbac8495bb88a6059bd93066a28a27a4c70`
- `926d034f039de07358e08262c308725996a1d90d`
- `7443d35d1912bac93c0b5daa119aa0a15d60d223`
- `ef6430df9d52d40fd4d588478d14dedf1c9511e2`
- `136d2267495ea18e5873dd07e442e42ceee37c38`

## 9. Data Safety release answer sheet

Created:

`docs/PLAY_DATA_SAFETY_V1_RELEASE_ANSWERS.md`

Frozen release facts:

- AI feature data is **collected** because it is transmitted off-device when invoked;
- do not retain the old Play claim "No data collected";
- recommended conservative content category is expected to be App activity / Other user-generated content, purpose App functionality, but verify current Play Console wording at submission;
- analytics does not add App interactions/Device IDs in this public V1 because analytics is explicitly disabled before ID creation/networking;
- final "shared" answer still requires verification of Google's service-provider exception against actual Vercel/OpenRouter/provider terms; do not infer "not shared" merely from ZDR.

Old privacy/data-safety draft docs were updated so they no longer contradict the release posture and point to the new authoritative files.

## 10. One-shot production deployment plan

Created:

`docs/PRODUCTION_ONE_SHOT_RELEASE_V1.md`

When Vercel rolling quota releases capacity:

1. freeze branch head and require green CI;
2. intentionally flip only the current branch Vercel deployment rule from `false` to `true` once;
3. let exactly one fresh preview deployment build with the current branch + new env;
4. immediately restore branch deployment rule to `false`; incoming restore commit should not deploy;
5. verify fresh deployment ID/URL/Git SHA/READY state;
6. live-smoke normalize-interest/question/analytics + legal pages using synthetic data;
7. promote that exact fresh deployment to production;
8. verify `zync-inky.vercel.app` maps to it;
9. run production live smoke;
10. set GitHub vars:
   - `ZYNC_API_BASE=https://zync-inky.vercel.app`
   - `ZYNC_PRIVACY_URL=https://zync-inky.vercel.app/privacy`
11. run signed release with existing Play upload key;
12. preserve signed artifact ID/size/SHA-256 and QA evidence.

Do not promote an old preview: old deployments do not receive the newly-added OpenRouter environment variables and do not contain the latest legal/analytics changes.

## 11. CI certification currently running

Latest CI at handoff creation:

- workflow: `Zync V1 CI`
- run number: `110`
- run ID: `35195682210`
- head SHA: `136d2267495ea18e5873dd07e442e42ceee37c38`

Already PASS in this run:

- JS syntax checks;
- serverless contracts;
- OpenRouter privacy contracts;
- new public-release web contracts;
- release-signing configurator;
- generated Android identity/SDK requirements;
- dependency install + localization generation;
- `flutter analyze`;
- Flutter tests.

At handoff creation, unsigned AAB build/upload was still running. Do not call run #110 fully certified until it completes successfully and artifact metadata is recorded.

## 12. Remaining external blockers

1. Vercel rolling 24-hour deployment quota must release capacity for one fresh deployment.
2. Production V1 must be deployed/promoted and live-smoked with the real OpenRouter key.
3. GitHub repo vars `ZYNC_API_BASE` and `ZYNC_PRIVACY_URL` must point to live production.
4. Existing Play upload-key secrets must be available to the signed workflow.
5. Signed AAB must be built/certified.
6. Two-device real Android QA remains required.
7. Play Console listing/screenshots/Data Safety/privacy/reviewer access must be updated.

## 13. Recommended continuation order

1. First check CI run `35195682210`; if green, record artifact ID/size/digest in a certified delta handoff.
2. Do not create any Vercel deployment until quota has capacity and branch is otherwise frozen.
3. Follow `docs/PRODUCTION_ONE_SHOT_RELEASE_V1.md` exactly.
4. After promotion, production-smoke all V1 endpoints and `/privacy`.
5. Then run signed release and Play test-track QA.

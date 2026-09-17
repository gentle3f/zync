# Zync V1 — Mini Handoff: Release Integration Blockers / Play Gate

Date: 2026-09-17
Branch: `zync-v1-rebuild-20260917`

## Certified before this checkpoint

Analytics implementation is certified by CI #81 run `35183238663` at code commit `ddf42c02f9ff8d28760453efcdb67b3881a98f6f`.

Unsigned AAB artifact:
- id `10481650493`
- size `60,827,864` bytes
- digest `sha256:ddf1f24ba1e530c5cb026d6c554376bfa989ab7dd73ad47938dfd19df9088b0d`

New authoritative handoff:
`AI_STATE/HANDOFF_20260917_ZYNC_V1_ANALYTICS_CERTIFIED_RELEASE_INTEGRATION.md`

`AI_STATE/LATEST_HANDOFF.md` now points to it.

## Production API blocker confirmed

GitHub Actions CI #81 logs explicitly show:

`ZYNC_API_BASE:` **empty**.

Therefore this is not merely an unknown URL: the repository variable is currently not configured in normal CI.

Vercel discovery attempts:
- connected Vercel connector returns `teams: []`;
- `.vercel/project.json` is not present on the branch;
- `vercel.json` is not present;
- targeted repository search found no `vercel.app` string;
- public web search did not establish a trustworthy Zync production Vercel origin.

Do not invent the URL. Production AI/live endpoint certification remains blocked until the actual deployed origin is supplied/discovered and configured.

## Localization quality issue found and fixed

CI #81 logs showed:
`"zh": 6 untranslated message(s).`

Targeted audit confirmed `mobile/lib/l10n/app_zh.arb` was missing six scanner recovery strings:
- camera permission title/body;
- camera unavailable title/body;
- generic camera error title/body.

They were copied from the existing Simplified Chinese `app_zh_Hans.arb` translations into generic `zh`.

Fix commit:
`c4177d21657de0cd00e1890c13fdd73a7e9c55f1`

CI #82 run `35184401644` was triggered and was in progress at this checkpoint. Next chat/step must certify that the localization warning is gone and the full build remains green.

## Play public-release mismatch discovered

Current public Play listing for package `com.gmail.gentle3f.myproject` still describes the old app, including login and remote/instant matching language, while rebuilt V1 has no login and uses local QR matching.

Current public Data Safety also states:
- No data shared with third parties
- No data collected

If production V1 analytics is enabled, that declaration must be updated. The analytics implementation transmits anonymous install/session identifiers and coarse app-interaction events.

Google Play's current Data Safety definitions indicate review at minimum of:
- App activity -> App interactions, purpose Analytics;
- Device or other IDs, purpose Analytics, because the random analytics install UUID is an app/installation-related identifier.

Whether provider transfer is declared as sharing depends on whether the configured analytics provider qualifies for Google's service-provider exception under the actual terms/configuration. Do not assume; verify before submission.

New release checklist:
`docs/PLAY_RELEASE_DATA_SAFETY.md`
commit `0945b4bd56a4639239d69daef18cb96dd5a19807`.

The checklist also requires:
- update Play description/screenshots to rebuilt V1;
- update public privacy notice before enabling public analytics;
- choose/record analytics retention/deletion handling;
- prepare a reviewer QR/access path because the core app requires scanning another Zync QR.

## Immediate continuation

1. Poll/certify CI #82 and confirm generic `zh` warning is gone.
2. Update authoritative/latest state with the localization certification and confirmed empty `ZYNC_API_BASE`/Play metadata gate.
3. Continue looking only for trustworthy production-origin evidence; do not redeploy or invent a Vercel project without explicit basis.
4. Real Play upload-key secrets remain external; do not run signed release until production API base + real signing secrets are actually configured.
5. Real-device QA remains required.

# Zync V1 — Mini Handoff: Analytics CI In Progress

Date: 2026-09-17
Branch: `zync-v1-rebuild-20260917`

## Analytics implementation now present

- `mobile/lib/core/analytics_service.dart`
- `api/v1/analytics.js`
- instrumentation in app open, interest onboarding, QR generation, QR scan/match/repeat, and conversation flows
- `mobile/test/analytics_service_test.dart`
- analytics privacy/server contracts in `.github/scripts/serverless_contracts.mjs`
- normal CI syntax gate includes `api/v1/analytics.js`
- signed-release workflow also checks serverless syntax/contracts before building/signing
- `docs/ZYNC_V1_ANALYTICS.md` documents exact data, prohibited data, provider config, retention/privacy implications and metric limitations

## Important behavior/privacy decisions

- Separate anonymous analytics install UUID; do not reuse peer/profile local ID.
- Session UUID is memory-only per app process.
- No raw/canonical interest content, nickname, peer ID or QR body in analytics.
- No Firebase account, analytics SDK, autocapture, replay, location or ad ID.
- Vercel endpoint is a strict server-side allowlist and optional PostHog relay.
- Provider config: `POSTHOG_PROJECT_API_KEY` + HTTPS `POSTHOG_HOST` in Vercel.
- Analytics failures remain best-effort and never block core Zync.
- True invitation -> install attribution is not implemented/faked in V1; current events can measure QR generation/scanning and completion but not causal install attribution.

## CI status at checkpoint

Latest relevant normal CI:
- run: `35183238663` / #81
- head: `ddf42c02f9ff8d28760453efcdb67b3881a98f6f`
- serverless JavaScript syntax: PASS
- V1 serverless contracts: PASS
- signing configurator: PASS
- generated Android signing-template compatibility: PASS
- Play identity / Android requirements: PASS
- localization generation: PASS
- `flutter analyze`: in progress at checkpoint

The later commit `2d16474d28ff609ece53059b8edfa7a904a2dae9` adds only analytics documentation and does not alter executable code.

## Next

1. Poll CI #81 through analyze/tests/AAB artifact.
2. Fix any failure if present.
3. On green, update authoritative release-readiness handoff + `AI_STATE/LATEST_HANDOFF.md` with analytics certified and new remaining external blockers.
4. Then continue Recommended continuation order: production Vercel origin/live endpoint smoke; real Play signing secrets/signed AAB; real-device QA.

# Zync V1 — Mini Handoff: Signing Doc Fixed / Analytics Start

Date: 2026-09-17
Branch: `zync-v1-rebuild-20260917`

## Completed

- Read `AI_STATE/LATEST_HANDOFF.md` and the authoritative `AI_STATE/HANDOFF_20260917_ZYNC_V1_RELEASE_READINESS.md` in full.
- Continued from the authoritative Recommended continuation order; no repo rediscovery or old Thunkable archaeology.
- Fixed documentation drift in `docs/ANDROID_RELEASE_SIGNING.md`.
- Commit: `46b05d8663afaba99f839a6dd84c48072e539788`.
- Production signed release is now documented as requiring a real HTTPS `ZYNC_API_BASE` plus all four real Play upload-key secrets. Normal development/ordinary CI may still run with an empty API base and local fallback.

## Active task

Implement the smallest privacy-light V1 analytics layer required by `docs/ZYNC_V1_PRODUCT_SPEC.md` without uploading raw interest/hobby names, without login/Firebase accounts, and without widening into Phase 2.

Target event family from frozen spec:
`app_open`, `interest_setup_complete`, `interest_added`, `qr_generated`, `qr_scanned`, `match_complete`, `match_count`, `question_generated`, `question_next`, `mode_selected`, `zync_again`.

## Guardrails

- No raw interest labels/canonical IDs in analytics payloads.
- No email/phone/location/ad ID/account token.
- Prefer anonymous local install/session identifiers and coarse numeric/enum metadata only.
- Keep existing local-only profile/history behavior unchanged.
- Keep cost/infra minimal; external provider configuration must not block internal-device QA.
- Preserve `main`; work only on `zync-v1-rebuild-20260917`.

## Next

1. Inspect only the relevant app lifecycle/local-store/flow files and current serverless conventions.
2. Finalize minimal event schema + delivery design.
3. Implement service, flow instrumentation, serverless relay/contract tests if appropriate, plus privacy documentation.
4. Run/verify CI and update durable handoff.

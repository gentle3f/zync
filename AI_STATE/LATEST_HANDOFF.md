# Zync V1 — Latest Handoff

Authoritative handoff: `AI_STATE/HANDOFF_20260917_ZYNC_V1_ANALYTICS_CERTIFIED_RELEASE_INTEGRATION.md`

Branch: `zync-v1-rebuild-20260917`

Read the authoritative handoff in full and continue directly from its **Recommended continuation order**. Do not restart repository discovery or old Thunkable archaeology.

Key current state: core Flutter V1, professional UI/graphics, adaptive QR transport, scanner recovery UX, bilingual conversation, release-signing preparation, hardened Vercel/OpenRouter handlers, and the privacy-light V1 analytics layer are implemented. Analytics is privacy-filtered client/server, documented, tested, and certified by CI #81 `35183238663` at code commit `ddf42c02f9ff8d28760453efcdb67b3881a98f6f`.

Latest certified unsigned AAB artifact: `10481650493`, size `60,827,864` bytes, digest `sha256:ddf1f24ba1e530c5cb026d6c554376bfa989ab7dd73ad47938dfd19df9088b0d`.

Main remaining blockers/tasks are now external release integration: discover/confirm the real production Vercel origin and `ZYNC_API_BASE`, live-smoke the V1 endpoints, confirm the real Play upload-key GitHub Secrets, certify a signed AAB, then perform real-device QA. Do not invent missing URLs/credentials or widen into Phase 2. Keep mini-handoffs frequent because chat streams may time out or disappear.
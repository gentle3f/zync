# Zync V1 — Latest Handoff

Authoritative handoff: `AI_STATE/HANDOFF_20260917_ZYNC_V1_RELEASE_READINESS.md`

Branch: `zync-v1-rebuild-20260917`

Read the authoritative handoff in full and continue directly from its **Recommended continuation order**. Do not restart repository discovery or old Thunkable archaeology.

Key current state: core Flutter V1, professional UI/graphics, adaptive QR transport, scanner recovery UX, bilingual conversation, release-signing preparation, hardened Vercel/OpenRouter handlers and serverless contract tests are implemented. CI #71 `35180203133` is fully green with release AAB artifact `10480196870` and digest `sha256:943e2d931c683caa38632829ee496fe02a38bb984d5a55a4d1bb11d2257c1def`.

Main remaining blockers/tasks are: production `ZYNC_API_BASE`, real Play upload-key GitHub Secrets, signed AAB, real-device QA, and the still-unimplemented privacy-light V1 analytics layer. Keep mini-handoffs frequent because chat sessions may time out/lost replies.
# Zync — Google Login Device Smoke Ready

Date: 2026-09-20

Branch: `zync-v1-rebuild-20260917`

## Current state

Cardverse staging is now ready for the first real-device Google login smoke.

### Vercel / Cardverse

The Vercel Hobby 12-function blocker has been removed by consolidating Cardverse into one Vercel entrypoint while preserving the public route surface through rewrites.

Certified contract count:
- total Vercel JavaScript functions under `api/`: 10
- Cardverse public routes: 12
- Cardverse Vercel entrypoints: 1

A real Preview deployment after consolidation reached READY.

Current active Preview branch alias:
`https://zync-git-zync-v1-rebuild-20260917-gens-projects-4f99f8b9.vercel.app`

Preview `CARDVERSE_API_ENABLED=true` is now active.

Live unauthenticated probes against the stable branch alias:
- GET `/api/v1/cardverse/auth/challenge` -> 405 + `Allow: POST` (proves global Cardverse API gate is ON and route dispatcher works)
- GET `/api/v1/cardverse/inventory` -> 401 `cardverse_session_missing` (proves auth/session enforcement is active)
- readiness remains operator-secret protected

Latest API-on Preview deployment used for these probes:
- deployment: `dpl_56cAd2zAuHxD6SzkgPs9MrurFa2Q`
- source commit: `eed1850bb01348552c7f7569bd8acba9158d423e`
- state: READY

After smoke verification, branch auto-deploy was re-closed in source:
- commit: `56dd29dd7b291465c02c9c10efb1437f1bea5bb6`
- `git.deploymentEnabled.zync-v1-rebuild-20260917=false`
- this does not shut down the already-live Preview alias

Production remains CLOSED and untouched by the Cardverse branch.

### Google auth

Google Auth Platform is configured and the same Web OAuth Client ID is present in:
- Vercel Preview as `ZYNC_GOOGLE_CLIENT_IDS`
- GitHub Actions repository variable `ZYNC_GOOGLE_SERVER_CLIENT_ID`

The Android client uses Android Credential Manager / Sign in with Google and passes the Cardverse server-issued one-time nonce into the Google ID-token request.

No Google client secret is used by the verifier or mobile app.

### QA APK

GitHub Actions:
- Zync V1 CI #1028 — SUCCESS
- Zync QA Preview APK #309 — SUCCESS

QA artifact:
- name: `zync-qa-octalysis-batch1`
- package: `com.gmail.gentle3f.myproject.qa`
- label: `Zync QA`
- API base: stable Preview branch alias above
- `google_server_client_id_configured=true`
- analytics=false
- qa_debug=true
- APK SHA-256: `ed744e20207c1f8caf86b18147e8333cd68b5c9366a547eb67d8251657ab5a9a`

The APK contains the QA-only `Cardverse Account QA` screen. Intended smoke sequence:
1. install APK
2. open `Cardverse Account QA`
3. tap `使用 Google 登入`
4. complete Google account chooser
5. confirm Cardverse cloud session becomes signed in
6. confirm proof-sync summary is shown or remains safely queued
7. sign out and confirm local session removal

## Important boundaries

- Production remains CLOSED.
- Google Play remains CLOSED.
- Draft PR #1 remains DO NOT MERGE.
- Keep Preview `CARDVERSE_API_ENABLED=true` only for this controlled staging smoke.
- Keep pack-open, quest-claim, proof-redeem, and account-lifecycle feature gates false unless explicitly testing them.
- Do not expose Google tokens, Cardverse bearer tokens, Neon URLs, Redis tokens, or secret values.
- Do not merge or promote this branch from the staging smoke.

## Next active task

Run the real-device Google login/session smoke with the certified QA APK. If Google token acquisition or server exchange fails, diagnose the exact stage without weakening nonce, issuer, audience, session, or abuse-guard checks. If login succeeds, inspect the staging account/session rows and then decide whether to enable proof redemption for the next controlled smoke.

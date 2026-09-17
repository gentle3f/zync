# Zync V1 — One-Shot Production Release Manifest

Date: 2026-09-17  
Branch: `zync-v1-rebuild-20260917`

## Objective

When the Vercel Hobby rolling deployment quota releases capacity, create **one intentional V1 preview deployment** from the fully prepared branch, verify it, promote that exact deployment to production, then build/sign the Play AAB. Do not return to per-commit Vercel previews.

## Frozen production identity

- Vercel project: `zync`
- Project ID: `prj_GayyH1E1oWeliJew8P2gWLiiqH0A`
- Vercel team ID: `team_jynHypQ0VPNT6nwooTRyFG4B`
- Team scope: `gens-projects-4f99f8b9`
- Stable production origin: `https://zync-inky.vercel.app`
- Android application ID: `com.gmail.gentle3f.myproject`
- Android release version: `1.0.0+6`
- Production privacy URL: `https://zync-inky.vercel.app/privacy`
- Terms URL: `https://zync-inky.vercel.app/terms`
- Disclaimer URL: `https://zync-inky.vercel.app/disclaimer`

## Current production state before cutover

The stable production domain still points to the old 2025 `main` deployment/commit and does not serve the rebuilt V1 API. `/api/v1/question` on that old production deployment returns 404.

Do not treat the current production alias as proof that V1 is live until the cutover steps below are completed.

## Vercel environment expected before the new deployment

Already configured by the release owner in Vercel:

- `OPENROUTER_API_KEY` — secret value, never commit or paste into repo/chat logs;
- `OPENROUTER_MODEL=openrouter/free`;
- `ZYNC_PUBLIC_URL=https://zync-inky.vercel.app`.

New encrypted-relay prerequisites that must also exist before the final V1 deployment:

- `UPSTASH_REDIS_REST_URL` — HTTPS REST endpoint for the dedicated/approved Upstash Redis database;
- `UPSTASH_REDIS_REST_TOKEN` — server-only Upstash REST token;
- `ZYNC_RELAY_RATE_LIMIT_SECRET` — server-only high-entropy secret of at least 24 characters used only to HMAC network identifiers for short-lived rate-limit keys.

Never expose either secret value through Flutter `--dart-define`, public repo variables, logs, screenshots, QR payloads, or client source. The Android app talks only to the Zync Vercel API; it must never receive the Upstash token.

These environment values should apply to the environment(s) used for the final preview and production deployment. A deployment created before variables were added does not retroactively receive them.

## Encrypted relay release posture

V1 one-scan pairing depends on `POST /api/v1/relay`:

- host creates a random short-lived session before displaying a scannable v2 QR;
- scanner returns an AES-GCM encrypted opaque response;
- relay stores only pending state or opaque ciphertext under the random session ID;
- server does not receive the one-time QR decryption secret;
- host polling is non-destructive so a lost HTTP response does not destroy the answer;
- host explicitly consumes/deletes only after authenticated local decryption succeeds;
- TTL of about three minutes is the hard cleanup guarantee for abandoned sessions;
- duplicate scanners are rejected while an identical scanner retry remains idempotent.

Do not promote V1 if the relay is absent, misconfigured, storing plaintext profile content, or missing TTL behavior.

## Git deployment-quota protection

`vercel.json` intentionally contains:

```json
"git": {
  "deploymentEnabled": {
    "zync-v1-rebuild-20260917": false
  }
}
```

This prevents ordinary branch commits, docs, handoffs and mobile-only changes from consuming Vercel preview quota.

Keep this protection on during normal development.

## Public V1 analytics posture

The Android V1 release is explicitly analytics-off:

```text
ZYNC_ANALYTICS_ENABLED=false
```

Both normal CI and the signed-release workflow pass this build define explicitly. With analytics disabled, the client exits before creating analytics IDs or sending analytics requests.

Do not add PostHog as a release blocker for this V1.

## One-shot deployment procedure after quota capacity returns

### 1. Freeze branch head

Before deployment, confirm all intended release files are committed and CI is green, including:

- `api/v1/question.js`
- `api/v1/normalize-interest.js`
- `api/v1/analytics.js`
- `api/v1/relay.js`
- `privacy.html`
- `terms.html`
- `disclaimer.html`
- `vercel.json`
- mobile V1 source/tests
- relay/serverless/privacy/web contracts
- release workflows/scripts

Record the exact Git commit SHA in the final release evidence.

### 2. Verify relay environment without exposing secrets

Before allowing a deployment, confirm the Vercel project has the three relay values named above and that they target the intended Upstash database. Do not print token/secret values into release evidence.

The relay is intentionally server-configured. There is no safe offline fallback that preserves the one-scan two-phone auto-advance UX; if relay configuration is absent, treat it as a release blocker rather than silently reverting to a broken host flow.

### 3. Intentionally allow exactly one branch deployment

Change only the branch rule in `vercel.json` from `false` to `true` and commit it once. That incoming commit should create the single fresh preview deployment containing all accumulated branch changes and the newly configured Vercel environment variables.

Do not make unrelated commits while that deployment is being created.

### 4. Immediately restore auto-deploy protection

After the preview deployment is created/identified, commit `vercel.json` back to:

```json
"zync-v1-rebuild-20260917": false
```

Because the restoring commit itself carries `deploymentEnabled: false`, it should not create another branch deployment. Verify the Vercel deployment list rather than assuming.

### 5. Verify the fresh preview build identity

Record:

- deployment ID;
- deployment URL;
- Git SHA shown in Vercel metadata;
- READY state;
- that the build contains Node V1 functions, including `/api/v1/relay`, and the legal static pages.

The fresh deployment must be newer than all environment-variable changes. Do not promote an older preview.

### 6. Relay live-smoke with synthetic opaque data

Before promotion, verify `/api/v1/relay` with a fresh random synthetic session ID and dummy base64url opaque payload only; never use a real user's QR/profile content.

Required sequence:

1. `create` returns 201 (or the documented retry-safe 200 for the same pending session) and establishes a short TTL;
2. initial `take` returns `waiting`;
3. `respond` accepts one opaque payload;
4. repeating the exact same `respond` is idempotent;
5. a different second response is rejected;
6. `take` returns the same opaque response on repeated polls without destructively consuming it;
7. `consume` deletes the session;
8. subsequent `take` returns expired/not-found behavior;
9. a separate abandoned short-lived synthetic session disappears by TTL without scheduled cleanup.

Do not put AES keys, Redis tokens, profile text, nicknames, or real interests into the smoke payload.

### 7. AI/live behavior check

Verify with fixed synthetic test inputs:

- `POST /api/v1/normalize-interest`
  - HTTP 200;
  - `X-Zync-API-Version: v1`;
  - `X-Zync-AI-Privacy: zdr-data-collection-deny`;
  - valid normalized interest payload.

- `POST /api/v1/question`
  - HTTP 200;
  - same V1/privacy headers;
  - non-empty question.

- `POST /api/v1/analytics`
  - endpoint exists;
  - 503 `analytics_not_configured` is acceptable for the analytics-off V1.

AI tests must use dummy interests only, never real user/profile data.

If `openrouter/free` has no route satisfying `zdr:true` + `data_collection:"deny"`, treat that as an AI availability failure. Do not weaken the privacy routing just to make the smoke pass.

### 8. Verify legal pages on the fresh deployment

Required browser-readable pages:

- `/privacy`
- `/terms`
- `/disclaimer`

Check that `/privacy` is public HTTPS, non-PDF, readable without authentication and accurately identifies the temporary encrypted Vercel/Upstash relay, its short retention, and the AI/provider data flows.

### 9. Promote the verified fresh deployment

Promote that exact deployment to production. Promotion does not rebuild the deployment, so only promote the fresh deployment that already contains the new environment and release files.

After promotion, verify `https://zync-inky.vercel.app` now resolves to that deployment/Git SHA.

### 10. Production smoke

Run `.github/scripts/live_api_smoke.mjs` against:

```text
ZYNC_API_BASE=https://zync-inky.vercel.app
ZYNC_PRIVACY_URL=https://zync-inky.vercel.app/privacy
```

The smoke must confirm the public privacy page, encrypted relay lifecycle, both AI endpoints and the analytics endpoint behavior using synthetic data only.

### 11. Set GitHub release variables

Repository variables for the signed workflow:

- `ZYNC_API_BASE=https://zync-inky.vercel.app`
- `ZYNC_PRIVACY_URL=https://zync-inky.vercel.app/privacy`

### 12. Run signed release

Required existing Play upload-key secrets:

- `ZYNC_ANDROID_KEYSTORE_BASE64`
- `ZYNC_ANDROID_STORE_PASSWORD`
- `ZYNC_ANDROID_KEY_ALIAS`
- `ZYNC_ANDROID_KEY_PASSWORD`

Run `Zync V1 Signed Release` only after production relay/API/privacy smoke passes.

The workflow must:

- run serverless/relay/privacy/web contracts;
- live-smoke production relay/API/privacy page;
- build with `ZYNC_ANALYTICS_ENABLED=false`;
- sign using the existing accepted Play upload key;
- pass `jarsigner -verify -strict`;
- upload the signed AAB artifact.

Record final artifact ID, byte size and SHA-256 digest in `AI_STATE`.

## Play Console after signed AAB

Before public rollout:

- replace old login/remote-matching listing text/screenshots;
- set Privacy Policy to `https://zync-inky.vercel.app/privacy`;
- complete Data Safety using `docs/PLAY_DATA_SAFETY_V1_RELEASE_ANSWERS.md` and the current Play form;
- provide reviewer QR/access instructions;
- run two-device real Android QA, including host auto-advance after one scanner scan;
- upload first to an appropriate test track before wider rollout.

## Rollback rule

If production smoke fails after promotion, do not patch live by relaxing privacy controls or bypassing the encrypted relay. Roll back the production alias to the prior known deployment, fix on the protected branch, then repeat a controlled deployment when quota allows.

## Release evidence to preserve

- final branch SHA;
- green CI SHA covering relay contracts + Flutter tests;
- Vercel deployment ID/URL;
- production alias mapping;
- production relay/API/privacy smoke output;
- Upstash configuration presence (names/status only, never secret values);
- OpenRouter model setting (`openrouter/free`);
- analytics state (`false`);
- signed workflow run ID;
- signed AAB artifact ID/size/SHA-256;
- real two-device QA result;
- Play Data Safety/privacy/listing review completion.

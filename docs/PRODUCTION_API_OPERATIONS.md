# Zync V1 — Production API & Public Release Operations Gate

Date: 2026-09-17
Branch: `zync-v1-rebuild-20260917`

This document covers production configuration that cannot be certified by mocked CI alone. It deliberately avoids adding accounts, Firebase, or a heavy backend to V1.

## 1. Production release URLs

A public signed release requires two real HTTPS GitHub repository variables:

- `ZYNC_API_BASE=https://<actual-production-origin>`
- `ZYNC_PRIVACY_URL=https://<public-browser-readable-policy-page>`

Do not guess either URL.

Normal CI logs on 2026-09-17 confirmed `ZYNC_API_BASE` was empty. The connected Vercel account currently exposes no teams/projects to the available connector, and this repo does not contain `.vercel/project.json` or `vercel.json`, so production-origin discovery remains external.

The privacy URL must be a public page accessible without login/VPN/temporary token. The signed-release live smoke rejects a failed URL, a final non-HTTPS redirect, and a PDF privacy policy.

The Android app receives the same `ZYNC_PRIVACY_URL` as a Dart define and exposes it from Home through a localized Privacy Policy entry.

## 2. Required Vercel/OpenRouter environment

For production AI:

- `OPENROUTER_API_KEY` — server-side only;
- `OPENROUTER_MODEL` — explicitly choose and record the production model/router rather than relying indefinitely on the source fallback;
- `ZYNC_PUBLIC_URL` — optional OpenRouter attribution/referrer value; this is not the Android API base;
- actual production Vercel project/deployment configuration.

For optional product analytics:

- `POSTHOG_PROJECT_API_KEY`;
- `POSTHOG_HOST` — HTTPS ingestion origin for the chosen project/region.

Never copy any secret into Flutter source, Git, app assets, logs, handoffs, or screenshots.

## 3. AI privacy routing invariant

Both `/api/v1/question` and `/api/v1/normalize-interest` enforce on every OpenRouter request:

```json
"provider": {
  "zdr": true,
  "data_collection": "deny"
}
```

This must remain covered by CI privacy-contract tests.

Production smoke testing must prove the configured `OPENROUTER_MODEL` has an eligible route under these restrictions. If no compliant provider is available, the request should fail and the mobile app should use its local fallback rather than removing the privacy requirement.

Also review OpenRouter account/workspace privacy settings before release:

- prompt/input-output logging must not be enabled unintentionally;
- prefer account/workspace ZDR as defense in depth;
- do not enable tools/web-search/plugins for these requests without a new privacy review.

Zync does not enable OpenRouter response caching in code: the handlers do not send `X-OpenRouter-Cache: true` and do not use a caching preset.

## 4. Cost/abuse controls

The Zync V1 endpoints are intentionally usable without a Zync account. That means application login cannot be relied on to protect the server-side OpenRouter key from automated abuse.

Before public beta, configure practical account/platform controls rather than embedding an app secret:

- give the Zync OpenRouter key/project an explicit spend/credit limit or alert appropriate to the beta budget;
- review Vercel firewall/request-rate controls available on the actual production plan;
- monitor request volume/status distribution after rollout;
- keep request body size/count limits and upstream timeouts in code;
- do not add a static "secret" to the Android app as authentication — an APK/AAB client secret is recoverable and is not meaningful protection.

If platform-native rate limiting is unavailable/too costly, start with a deliberately small OpenRouter budget and measured beta cohort rather than creating a new stateful backend solely for V1 abuse control.

## 5. Automated signed-release smoke

The manual `Zync V1 Signed Release` workflow runs `.github/scripts/live_api_smoke.mjs` **before** Flutter build/signing.

It verifies:

### Public privacy policy

- `ZYNC_PRIVACY_URL` is HTTPS;
- GET succeeds;
- redirects remain HTTPS;
- page is browser-readable HTML/plain text;
- page is not a PDF.

### `/api/v1/normalize-interest`

- fixed non-sensitive test interest returns a valid normalized response;
- handler exposes `x-zync-api-version: v1`;
- handler exposes `x-zync-ai-privacy: zdr-data-collection-deny`.

### `/api/v1/question`

- fixed non-sensitive shared interest returns a valid question;
- same V1/privacy headers are present.

### `/api/v1/analytics`

- success when provider is configured; or
- only the explicit expected `503 analytics_not_configured` state when analytics is intentionally/not-yet configured.

A dead URL, stale API deployment or pre-privacy-hardening handler blocks the signed build.

## 6. Additional live/device smoke matrix

Automated release smoke is necessary but does not replace real-device testing. Once production is configured, record dated evidence for:

### `/api/v1/normalize-interest`

- supported non-English locale -> localized display label;
- invalid 1-char input -> 400;
- over-100-char input -> 400;
- provider/model outage -> stable API failure and mobile fallback UX.

### `/api/v1/question`

- same-language shared match -> one question;
- bilingual request -> semantically paired primary/translation;
- zero-match crossover -> valid crossover question;
- malformed/empty interests -> 400;
- provider failure/timeout -> mobile local fallback.

### `/api/v1/analytics` when enabled

- provider receives only documented anonymous/coarse fields;
- injected raw interest/nickname/peer fields are discarded;
- missing analytics provider configuration does not affect core app flow.

Use `docs/REAL_DEVICE_QA.md` for physical-device evidence.

## 7. Observability/privacy rule

When diagnosing production, do not add logging that records request bodies, interest labels, QR payloads, nicknames, peer IDs, or full AI prompts.

Operational logs may record coarse facts such as route, status code, latency, provider/model identifier and an internal request ID, provided they do not reconstruct user interest content.

## 8. Release evidence to record in `AI_STATE`

Before signed/public release, write down:

- actual production origin (not secrets);
- exact public privacy-policy URL;
- deployment/project identifier where safe;
- explicit production `OPENROUTER_MODEL` name;
- date/result of automated production release smoke;
- whether analytics is enabled;
- analytics retention setting if enabled;
- confirmation of OpenRouter privacy/logging settings (without exposing credentials);
- spend/abuse-control configuration at a non-secret descriptive level;
- signed AAB artifact ID/digest;
- real-device QA result;
- any production errors found and their resolution.

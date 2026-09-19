# Zync V1 — Mini Handoff: Analytics Core Added

Date: 2026-09-17
Branch: `zync-v1-rebuild-20260917`

## New commits in this slice

- `9921eb7a7cdd1d84481146072982e866f983f588` — privacy-light mobile analytics client.
- `be50ba4e0f72cb24175ad6d63fc4797dde86e993` — strict server-side analytics relay endpoint.

## Implemented

### Mobile

New `mobile/lib/core/analytics_service.dart`:

- uses the existing `ZYNC_API_BASE` only;
- no extra Flutter analytics SDK/native dependency;
- creates a separate random anonymous install UUID in SharedPreferences;
- creates an in-memory session UUID per app process;
- supports only the frozen V1 analytics event names;
- filters properties to coarse bool/number/enum/string fields;
- best-effort 5s delivery; all failures are swallowed so analytics cannot block the local-first product.

### Server

New `POST /api/v1/analytics`:

- strict event allowlist;
- event-specific property allowlist/validation;
- accepts only anonymous UUID-like install/session IDs;
- does not accept/forward nickname, peer ID, QR payload, raw/canonical interest content, location, email, phone or advertising ID;
- server-side relay target is optional PostHog via `POSTHOG_PROJECT_API_KEY` + HTTPS `POSTHOG_HOST`;
- sends `$process_person_profile: false` and no client IP/User-Agent forwarding;
- bounded 8s upstream request;
- stable 400/503/502 error behavior;
- analytics remains non-blocking in the mobile client when provider config is absent.

## Still active

1. Instrument existing product flows for all frozen events.
2. Add serverless contract tests proving sanitization and failure behavior.
3. Add CI syntax coverage for `api/v1/analytics.js`.
4. Add analytics privacy/configuration/metric documentation.
5. Run/observe CI and fix any analyzer/test/build failures.

## Privacy invariant

Never add raw hobby/interest values, canonical interest IDs, peer local IDs, nicknames, QR bodies, precise location, email/phone, account IDs or ad IDs to the analytics payload.

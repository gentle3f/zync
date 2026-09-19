# Zync V1 — Privacy-Light Analytics

## Goal

Zync V1 needs enough product telemetry to validate whether people complete onboarding, actually Zync with another person, ask for more conversation prompts, and return to Zync again — without uploading the contents of anyone's interest profile.

The analytics layer is deliberately smaller than a normal mobile analytics stack. It does **not** add login, Firebase accounts, advertising IDs, location tracking, session replay, automatic screen capture, or automatic event capture.

## Architecture

```text
Flutter app
  |
  | POST /api/v1/analytics
  | anonymous event + coarse properties only
  v
Zync Vercel serverless relay
  |
  | strict event/property allowlist
  v
PostHog Product Analytics (optional external sink)
```

The Flutter app talks only to the existing `ZYNC_API_BASE`. It does not contain a PostHog project key and does not add a PostHog Flutter/native SDK.

If `ZYNC_API_BASE` is empty or the analytics provider is unavailable, analytics is silently best-effort on the device and the core local-first Zync experience continues to work.

## Anonymous identifiers

The analytics client creates:

- `installId` — a random UUID stored locally in SharedPreferences under a dedicated analytics key. It is separate from the Zync profile/peer local ID and normally lasts until app data is cleared/uninstalled.
- `sessionId` — a random UUID held only in memory for the current app process.

The server relays the install identifier to the analytics sink as `distinct_id: zync:<installId>` and sets `$process_person_profile: false`.

These identifiers are for anonymous product-event grouping only. They are not email addresses, phone numbers, account IDs, advertising IDs, or peer IDs.

## Data that must never be uploaded by analytics

Do not add any of the following to analytics events:

- raw hobby/interest names;
- canonical interest IDs;
- custom-interest labels or categories;
- nickname;
- peer local ID;
- QR payload/body;
- email or phone number;
- precise/coarse location;
- advertising identifier;
- account/login token;
- contact/social graph data.

Both the Flutter client and `POST /api/v1/analytics` enforce allowlists. The server allowlist is authoritative: unknown properties are dropped before forwarding.

## Frozen V1 events and allowed properties

| Event | Allowed properties | Meaning |
| --- | --- | --- |
| `app_open` | `locale`, `profile_ready` | Cold app/process start after local profile load. |
| `interest_setup_complete` | `selected_count` | First onboarding interest setup successfully saved. Editing an existing profile does not re-fire completion. |
| `interest_added` | `source`, `selected_count` | User adds/selects an interest. `source` is only `seed`, `saved_custom`, or `ai_normalized`. |
| `qr_generated` | `interest_count`, `transport` | Show My QR opened and payload generated once for that screen instance. `transport` is `legacy` or `compressed`. |
| `qr_scanned` | `transport` | Valid non-self Zync QR successfully decoded as part of a completed scan flow. |
| `match_complete` | `has_match`, `repeat_peer` | Local comparison/history write completed. |
| `match_count` | `count` | Number of exact shared interests; no identities/content. |
| `question_generated` | `mode`, `source`, `match_type`, `bilingual` | Conversation question returned, including local fallback. `source` is `ai` or `fallback`; `match_type` is `shared` or `crossover`. |
| `question_next` | `mode` | User explicitly asks for another question. |
| `mode_selected` | `mode` | User changes conversation mode. |
| `zync_again` | `prior_sessions` | A scan matched a peer already present in local Zync Again history. |

Supported mode values are `easy`, `fun`, `debate`, `deep`, `guess`, and `surprise`.

Counts are server-bounded and event strings/enums are server-validated before forwarding.

## Provider configuration

The server relay uses these Vercel environment variables when analytics collection is enabled:

- `POSTHOG_PROJECT_API_KEY` — the project ingestion key.
- `POSTHOG_HOST` — the HTTPS ingestion host shown by the chosen PostHog project/region.

Do not put either value in Flutter source. The project key may not be equivalent to a user secret, but keeping the provider behind the server relay preserves one privacy/schema enforcement point and avoids coupling the Android app directly to a third-party SDK.

If either provider value is absent/invalid, `/api/v1/analytics` returns `503 analytics_not_configured`. The Flutter client intentionally ignores analytics delivery errors so internal-device QA and the local-first experience remain usable.

## Provider/privacy implications

Zync does not forward the mobile request's IP address or User-Agent into the PostHog event properties. The Vercel platform still necessarily processes HTTP request metadata when serving the relay, subject to the hosting provider's own operational/privacy terms.

The code does not configure PostHog data retention. Retention is an external project/account setting and must be reviewed and deliberately configured before a public beta. The public privacy notice must state that anonymous product-usage events are collected, what fields are collected, the analytics processor used, and the applicable retention/deletion policy.

No PostHog session replay, autocapture, feature flags, surveys, user profiles, or automatic person enrichment are enabled by this implementation.

## Validation metrics that can be derived

- onboarding completion rate: `interest_setup_complete` relative to anonymous installs/app opens;
- first-Zync completion rate: first `match_complete` per anonymous install;
- repeat Zync rate: installs with `zync_again` / installs with any `match_complete` over the chosen time window;
- sessions per active install: distinct `sessionId` / active `installId`;
- conversation engagement: `question_generated`, `question_next`, and `mode_selected` following `match_complete`;
- exact-match distribution: `match_count`.

### Important limitation: invitation/install loop

The frozen V1 event set can show that a device generated a QR and that another device completed a scan/match, but it cannot truthfully attribute a new app installation to a specific invitation without adding referral/install-attribution infrastructure. That mechanism is not present in V1 and must not be faked from unrelated events. Treat the "second-person invitation / install loop" metric as only partially observable until a future explicit referral experiment is designed.

## Release/QA checks

Before a validation-focused public beta:

1. Configure the production `ZYNC_API_BASE`.
2. Configure `POSTHOG_PROJECT_API_KEY` and the correct regional `POSTHOG_HOST` in Vercel.
3. Smoke-test `POST /api/v1/analytics` with an allowlisted event.
4. Confirm the resulting event contains only the documented fields.
5. Confirm raw interests, peer IDs, nicknames and QR content are absent.
6. Verify provider retention/privacy settings and update the public privacy notice.
7. Confirm analytics failure/offline mode does not break onboarding, QR, scan/match, or conversation fallback.

Analytics configuration should not block local internal QA, but public validation metrics are not considered live until the provider configuration and retention/privacy review above are complete.

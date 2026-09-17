# Zync V1 — Google Play Release Metadata & Data Safety Checklist

Date: 2026-09-17
Branch: `zync-v1-rebuild-20260917`

This checklist exists because the rebuilt V1 product behavior no longer matches parts of the currently published Google Play listing, and because production AI plus optional privacy-light analytics transmit limited data off-device.

## 1. Current public Play listing is stale for the rebuilt V1

Current package remains correct and must not change:

- `com.gmail.gentle3f.myproject`

The currently published listing still describes the old product as requiring login and matching users remotely. The rebuilt V1 does **not** do that.

Before production rollout, update the store listing so it accurately describes the frozen V1:

- no login or registration;
- no cloud user profile;
- no remote people-matching service;
- one person shows a Zync QR and the other scans it;
- interest matching happens locally on the scanning device;
- shared interests are progressively revealed;
- AI is used only for unknown-interest normalization and conversation prompts, with local fallback;
- Zync Again history remains local on-device;
- global/multilingual positioning rather than an old Hong-Kong-only/login-based description.

Do not reuse screenshots/text that show removed login/remote-matching flows. New Play screenshots should reflect the rebuilt V1 UI.

## 2. Current Data Safety declaration is not suitable for the production V1 AI path

As of 2026-09-17 the public Play listing states:

- **No data shared with third parties**
- **No data collected**

That statement must be reviewed before a production V1 rollout even if PostHog analytics stays disabled.

The production AI path transmits limited interest text off-device:

### Unknown-interest normalization

`POST /api/v1/normalize-interest` sends:

- the user-entered unknown hobby/interest text (2..100 chars after validation);
- canonicalized UI language.

It does **not** send the user's full local profile, nickname, peer ID, email, phone, location or account token.

Purpose: app functionality — turn a user-entered interest into a stable multilingual matching concept.

### Conversation question generation

`POST /api/v1/question` sends bounded interest labels required for the current conversation:

- up to the server/app limits from shared interests and/or each participant's non-shared interests;
- conversation mode;
- primary/secondary language when bilingual output is needed.

It does **not** send nickname, peer local ID, QR body, phone/email, location or an account token.

Purpose: app functionality — generate one contextual social icebreaker question (plus an equivalent translation when required).

### Likely Google Play data category for AI interest text

Review conservatively under Google's current Data Safety taxonomy. The most plausible category for user-entered/selected interest text sent to the AI service is:

- **App activity → Other user-generated content**
- purpose: **App functionality**

Do not label this as analytics data. It is functional content sent only when the AI feature is invoked.

Google Play defines "collected" broadly as user data transmitted off the device. Zero-retention processing reduces retention risk but does not mean the data was never collected/transmitted for Data Safety purposes.

Official reference:
`https://support.google.com/googleplay/android-developer/answer/10787469`

## 3. OpenRouter privacy hardening is code-enforced

Both V1 OpenRouter calls now include:

```json
"provider": {
  "zdr": true,
  "data_collection": "deny"
}
```

This requires OpenRouter to route the request only to provider endpoints satisfying Zero Data Retention and blocks endpoints that non-transiently collect user data for storage/training under OpenRouter's routing policy.

CI contains a dedicated privacy contract test so these fields cannot be silently removed without failing the quality gate.

Important limits:

- ZDR does not mean the interest text remains on-device; it is still transmitted and processed for inference.
- Live production smoke testing must prove the configured `OPENROUTER_MODEL` has an eligible ZDR route. If not, AI should fail and the app should fall back locally rather than weakening the privacy requirement.
- OpenRouter account-level prompt logging/privacy settings must also be reviewed; request-level ZDR controls provider routing but does not substitute for every account/platform setting.
- Do not enable web-search/tools/plugins in these AI calls without a separate privacy review.

OpenRouter reference:
`https://openrouter.ai/docs/guides/features/zdr`

## 4. Analytics adds separate collected data if enabled

If the V1 analytics relay is enabled for public users, the app additionally sends a random installation identifier plus coarse product-interaction events to the Zync Vercel endpoint and optionally onward to the configured analytics processor.

### Likely Google Play data types when V1 analytics is enabled

Review at minimum:

1. **App activity → App interactions**
   - examples in Zync: app open, onboarding completion, QR generated/scanned, match completion/count, question generation/next, conversation mode selection, repeat Zync;
   - purpose: **Analytics**;
   - no raw hobby/interest content is included in analytics.

2. **Device or other IDs**
   - Zync creates a random per-install analytics UUID and transmits it for anonymous event grouping;
   - it is separate from the Zync peer/profile ID and is not an advertising ID;
   - Google Play defines this category broadly enough to include identifiers related to an app/installation, so review/decorate conservatively as **Device or other IDs**;
   - purpose: **Analytics**.

The in-memory session UUID is also an app/session identifier, although it is short-lived.

### Required vs optional analytics collection

Current Zync V1 has no analytics opt-out/consent control. If analytics is enabled at the production endpoint, events are attempted automatically and best-effort.

Do not describe the collection as user-optional merely because app functionality continues when analytics delivery fails. In Google's form, optional collection requires real user control over whether data is collected.

If the release needs analytics to be optional, implement an actual user control/consent mechanism first.

## 5. Collected vs shared / processors

Off-device AI and analytics data is collected for Data Safety purposes.

Whether transfer to OpenRouter, the selected model provider, Vercel, or PostHog also has to be declared as **shared** depends on the actual processing relationship and configuration. Google Play has a service-provider exception when a provider processes data solely on behalf of the developer and under the developer's instructions.

Before answering "not shared":

- verify applicable provider terms/DPA for Vercel, OpenRouter/model routing and PostHog (if enabled);
- verify they act as service providers for the relevant data rather than using it for an independent purpose;
- retain OpenRouter ZDR + `data_collection: deny`;
- keep PostHog `$process_person_profile: false`;
- keep replay/autocapture/advertising/profile enrichment disabled;
- document the conclusion and evidence used for the Play submission.

If the service-provider conditions are not satisfied, declare the relevant data as shared as well.

## 6. Data not uploaded by the analytics path

The analytics allowlists do not send:

- raw hobby/interest names;
- canonical interest IDs;
- custom-interest labels/categories;
- nickname;
- peer local ID;
- QR payload/body;
- email or phone number;
- precise/coarse location as an explicit event property;
- advertising identifier;
- contacts/social graph;
- account/login token.

This statement is specifically about analytics. Do **not** misread it as saying AI functionality never sends interest text: Section 2 documents the bounded interest data sent when AI normalization/question generation is used.

## 7. Local-only data boundary

The following remain local to the device in V1 unless directly shown/scanned between the two participating devices:

- the stored local interest profile as a whole;
- nickname persistence;
- Zync Again/history records;
- peer local IDs/history;
- Interest DNA calculations;
- local matching result calculation.

The QR contains only the data required for the peer-to-peer Zync flow and is visually transferred to the other participant's device. Zync's backend does not receive the QR payload as part of scanning/matching.

## 8. Encryption in transit

The intended production network paths are HTTPS:

```text
Android app -> Zync Vercel API -> OpenRouter/ZDR provider
Android app -> Zync Vercel API -> analytics processor (only if enabled)
```

Production signed release already requires an HTTPS `ZYNC_API_BASE`. Keep analytics provider hosts HTTPS as enforced by `api/v1/analytics.js`.

## 9. Privacy policy must be updated before public rollout

The existing public privacy notice must accurately state at minimum:

- profile/history/local matching are stored/performed locally as described above;
- QR data is exchanged directly between the participating devices;
- unknown-interest normalization sends only the typed interest + locale to the Zync API/OpenRouter path;
- conversation generation sends only a bounded set of relevant interest labels, mode and languages;
- OpenRouter requests enforce ZDR + data-collection denial at the routing layer;
- privacy-light analytics, if enabled, sends anonymous install/session identifiers and documented coarse events;
- analytics does not receive raw interest content;
- each processor/provider used in production;
- retention/deletion policy and privacy contact method.

Do not claim "no data collected" merely because profile/history are local or because OpenRouter uses ZDR.

## 10. Retention/deletion decisions still require production configuration evidence

Before public beta:

1. confirm OpenRouter account privacy/prompt-logging settings and a ZDR-compatible production model route;
2. if analytics is enabled, choose/review PostHog retention;
3. record applicable retention facts in release evidence;
4. reflect them accurately in the privacy notice;
5. decide how privacy/deletion requests are handled for anonymous event records.

No account exists in V1, so do not promise account-based deletion controls that the product does not have.

## 11. Play review resources / QR access

Because Zync's main two-person flow depends on scanning another Zync QR, prepare reviewer instructions and a usable test QR/profile if Play review requires access resources. The reviewer should not be forced to own two physical Zync-configured devices just to reach the core result/conversation screen.

Reference:
`https://support.google.com/googleplay/android-developer/answer/10788890`

## 12. Public release gate

Do not consider the public Play rollout ready until all are true:

- production `ZYNC_API_BASE` configured and live-smoked;
- live OpenRouter smoke proves the chosen model works under enforced ZDR/data-collection denial;
- analytics provider/privacy decision completed (or analytics intentionally left disabled for that release);
- Data Safety form matches both the AI functional-data path and analytics path actually shipped;
- processor/service-provider sharing analysis completed;
- public privacy notice matches actual shipped behavior;
- Play description/screenshots match rebuilt V1 rather than the old login/matching app;
- correct existing Play upload key configured;
- signed AAB certified;
- real-device QA completed;
- reviewer QR/access instructions prepared if required.

Internal/device QA can continue before these public-metadata tasks are complete.

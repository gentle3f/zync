# Zync V1 — Google Play Release Metadata & Data Safety Checklist

Date: 2026-09-17
Branch: `zync-v1-rebuild-20260917`

This checklist exists because the rebuilt V1 product behavior no longer matches parts of the currently published Google Play listing, and the new optional privacy-light analytics path changes the data-safety answer if enabled for public users.

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
- AI is used for interest normalization and conversation prompts, with local fallback;
- Zync Again history remains local on-device;
- global/multilingual positioning rather than an old Hong-Kong-only/login-based description.

Do not reuse screenshots/text that show removed login/remote-matching flows. New Play screenshots should reflect the rebuilt V1 UI.

## 2. Current Data Safety declaration must be reviewed before public analytics is enabled

As of 2026-09-17 the public Play listing states:

- **No data shared with third parties**
- **No data collected**

That remains compatible only while the production app does not transmit analytics events off-device.

If the V1 analytics relay is enabled for public users, the app sends a random installation identifier plus coarse product-interaction events to the Zync Vercel endpoint and optionally onward to the configured analytics processor. The public declaration must then be updated before rollout so it matches actual behavior.

### Likely Google Play data types when V1 analytics is enabled

Based on the implemented schema, review at minimum:

1. **App activity → App interactions**
   - examples in Zync: app open, onboarding completion, QR generated/scanned, match completion/count, question generation/next, conversation mode selection, repeat Zync;
   - purpose: **Analytics**;
   - no raw hobby/interest content is included.

2. **Device or other IDs**
   - Zync creates a random per-install analytics UUID and transmits it for anonymous event grouping;
   - it is separate from the Zync peer/profile ID and is not an advertising ID;
   - Google Play defines this category broadly enough to include identifiers relating to an app/installation, so this should be reviewed/decorated conservatively as **Device or other IDs**;
   - purpose: **Analytics**.

The in-memory session UUID is also an app/session identifier, although it is short-lived.

### Collected vs shared

Off-device analytics data is **collected**.

Whether transfer from the Zync Vercel relay to PostHog must also be declared as **shared** depends on the actual provider relationship/configuration. Google Play currently excludes transfers to a service provider from the definition of sharing when that provider processes data solely on behalf of the developer and under the developer's instructions.

Before answering "not shared":

- verify the chosen PostHog plan/terms/DPA and project settings support service-provider processing for this use;
- verify the data is not used for cross-customer advertising/profiling or another independent purpose;
- keep `$process_person_profile: false`;
- keep session replay/autocapture/advertising features disabled.

If those conditions are not satisfied, declare the relevant data as shared as well.

Official Google Play reference:
`https://support.google.com/googleplay/android-developer/answer/10787469`

## 3. Required/optional collection answer

Current Zync V1 has no analytics opt-out/consent control. If analytics is enabled at the production endpoint, events are attempted automatically and best-effort.

Therefore do not describe the collection as user-optional merely because app functionality continues when analytics delivery fails. In Google Play's Data Safety form, "optional" means the user has control over whether that data is collected.

If the release needs analytics to be declared optional, implement an actual user control/consent mechanism first. Do not fake optionality in the Play form.

## 4. Data not collected by the V1 analytics path

Keep the Play/privacy documentation aligned with the actual allowlists. The analytics path does not send:

- raw hobby/interest names;
- canonical interest IDs;
- custom interest labels/categories;
- nickname;
- peer local ID;
- QR payload/body;
- email or phone number;
- precise/coarse location as an explicit event property;
- advertising ID;
- contacts/social graph;
- account/login token.

Do not later add any of these to analytics without revisiting code, tests, privacy notice and Play Data Safety declarations.

## 5. Encryption in transit

The intended production path is HTTPS:

`Android app -> Zync Vercel API -> analytics processor`

Production signed release already requires an HTTPS `ZYNC_API_BASE`. Keep the analytics processor host HTTPS as enforced by `api/v1/analytics.js`.

## 6. Privacy policy must be updated before public analytics rollout

The current Play listing links to an existing privacy-policy URL. The rebuilt V1 privacy notice needs to accurately state at minimum:

- profile/interests and Zync Again history are stored locally on-device;
- QR data is exchanged directly between the two devices involved in a Zync interaction;
- AI normalization/question requests send only the data required for those requests to the Zync API/OpenRouter path;
- privacy-light product analytics, if enabled, sends anonymous install/session identifiers and the documented coarse event properties;
- no raw interest-profile contents are sent by the analytics path;
- the analytics processor used;
- retention period/settings;
- deletion/request mechanism or an accurate explanation of how anonymous event data is handled;
- contact method for privacy requests.

Do not claim "no data collected" in the privacy notice if production analytics is enabled.

## 7. Retention/deletion decision is still external

The code intentionally does not choose PostHog retention. Before public beta:

1. choose/review provider retention;
2. record the value in `docs/ZYNC_V1_ANALYTICS.md` or release evidence;
3. reflect it accurately in the privacy notice;
4. decide how deletion/privacy requests are handled for anonymous analytics records.

No account exists in V1, so do not promise account-based deletion controls that the product does not have.

## 8. Play review resources / QR access

Google Play's current console requirements say developers must provide review resources needed to exercise an app, including QR codes where applicable.

Because Zync's main two-person flow depends on scanning another Zync QR, prepare reviewer instructions and a usable test QR/profile if Play review asks for app-access resources. The reviewer should not be forced to own two physical Zync-configured devices just to reach the core result/conversation screen.

Official reference:
`https://support.google.com/googleplay/android-developer/answer/10788890`

## 9. Release gate

Do not consider the public Play rollout ready until all are true:

- production `ZYNC_API_BASE` configured and live-smoked;
- analytics provider/privacy decision completed (or analytics intentionally left disabled for that release);
- Data Safety form matches the actual shipped behavior;
- public privacy notice matches the actual shipped behavior;
- Play description/screenshots match rebuilt V1 rather than the old login/matching app;
- correct existing Play upload key configured;
- signed AAB certified;
- real-device QA completed;
- reviewer QR/access instructions prepared if required.

Internal/device QA can continue before these public-metadata tasks are complete.

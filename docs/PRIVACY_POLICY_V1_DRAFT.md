# Zync V1 — Privacy Policy Draft

> **RELEASE BLOCKER / DO NOT PUBLISH AS-IS.** Replace every bracketed placeholder and verify the actual production processor/configuration/retention settings before publishing. The final policy must be hosted at a public, active, non-PDF HTTPS URL and the same URL must be configured as `ZYNC_PRIVACY_URL` in the signed build.

Effective date: `[EFFECTIVE DATE]`
Developer: `[DEVELOPER LEGAL NAME]`
Privacy contact: `[PRIVACY CONTACT EMAIL OR FORM URL]`
Public policy URL: `[PUBLIC HTTPS URL]`

## 1. About Zync

Zync is a face-to-face social icebreaker. Users create an interest profile on their device, share that profile with another nearby person by displaying/scanning a Zync QR code, discover shared interests, and can use AI-assisted features to normalize a newly entered interest or generate a conversation question.

This policy applies to the Android app using package `com.gmail.gentle3f.myproject` and the Zync V1 services used by that app.

## 2. Data stored locally on your device

Zync V1 does not require an account or registration. The following data is stored locally on the device:

- optional nickname;
- preferred/supported language;
- selected interests and their Love / Like / Want to try strength;
- locally created custom-interest labels/categories;
- Zync Again history, including the local identifier/nickname supplied by the other person's QR, previously shared interest identifiers, timestamps and repeat-session count;
- a separate random analytics installation identifier if analytics is enabled/configured.

The local profile and Zync Again history are not cloud-synced by Zync V1. Clearing the app's data or uninstalling the app normally removes this local data from that device, subject to the Android device/backup behaviour outside Zync's control.

## 3. QR sharing between people

When you choose **Show my QR**, the QR contains the data needed for the other device to compare your interests:

- a random local Zync profile identifier;
- your optional nickname;
- your language;
- your selected interests and interest strengths;
- for custom interests, the label/category needed to make that interest readable to the other device.

The person who scans your QR receives this information directly through the QR code. You should only show your QR to people with whom you intend to share this information.

Matching is performed locally on the scanning device. Zync does not upload the QR body to its analytics service.

## 4. AI-assisted interest normalization

If you type an interest that is not already in Zync's local catalog and choose to add it with AI, Zync sends the text you entered and your supported language to the Zync API so that the interest can be normalized into a stable concept and display label.

The current server validates/bounds this input to 2–100 characters before processing. The request may be processed through:

- Zync's production hosting/API provider: **Vercel**; and
- Zync's AI routing provider: **OpenRouter**, which then routes the request to a compatible AI model/provider.

Zync's current OpenRouter request configuration requires zero-data-retention-compatible routing (`zdr: true`) and denies provider data collection (`data_collection: "deny"`). If a compatible AI route is unavailable, Zync should fail the AI request rather than deliberately relax those privacy constraints.

These safeguards reduce provider retention, but the interest text is still transmitted off your device when you invoke this feature.

## 5. AI-assisted conversation questions

After two profiles are compared, Zync can send a bounded set of interest labels to the Zync API to generate a conversation question. The server currently limits each supplied list to at most 12 interest strings and each string to at most 120 characters.

Depending on the match:

- shared-interest labels may be used to create a question around common interests; or
- if there is no exact shared interest, limited interest labels from each person may be used to create a crossover question.

The request also includes the selected conversation mode and supported language information needed to generate the requested output. When the two people use different supported languages, the service can return one semantic question plus an equivalent translation.

These requests use the same Vercel/OpenRouter processing path and the same OpenRouter zero-data-retention/data-collection-deny routing requirement described above.

If the AI service is unavailable or the request fails, Zync can use local built-in fallback questions instead.

## 6. Privacy-light product analytics

`[CHOOSE ONE BEFORE PUBLIC RELEASE: ANALYTICS ENABLED / ANALYTICS DISABLED]`

### If analytics is enabled

Zync may send privacy-light product usage events to the Zync API to understand whether important product flows work. The analytics design intentionally excludes the contents of your interest profile.

The analytics client uses:

- a random per-installation UUID stored locally for anonymous event grouping; and
- a random session UUID held in memory for the current app process.

Possible events include:

- app open;
- onboarding/interest setup completion;
- interest added, using only a coarse source type and count;
- QR generated/scanned;
- match completion and exact-match count;
- conversation question generated / next question;
- conversation mode selected;
- repeat Zync event.

Allowed analytics properties are limited to coarse values such as supported locale, booleans, counts and known enums.

The analytics path is designed not to send:

- raw hobby/interest names;
- canonical interest IDs;
- custom-interest labels/categories;
- nickname;
- peer local ID;
- QR payload/body;
- email address or phone number;
- precise/coarse location as an analytics property;
- advertising ID;
- contacts/social graph;
- login/account token.

The server may relay these anonymous product events to **PostHog** if the production analytics provider is configured.

Production analytics retention: `[POSTHOG RETENTION PERIOD / POLICY]`
Production analytics region/host: `[POSTHOG REGION/HOST]`

### If analytics is disabled

Remove the enabled-analytics paragraph above and state accurately that the production analytics provider is not configured and analytics delivery is disabled for that release. Do not leave contradictory wording in the final public policy.

## 7. Service providers and data transfers

The final production policy must reflect the processors actually configured for the release. Current intended providers are:

- **Vercel** — hosts the Zync server/API and therefore processes requests sent to Zync's online features;
- **OpenRouter** — routes AI requests to compatible model providers under the Zync request constraints described above;
- **PostHog** — only if privacy-light analytics is enabled/configured for the production release.

Before publication, verify the applicable terms, data-processing terms, region and retention behaviour for the actual production accounts/settings. Do not describe a provider as unused if it is enabled in production.

## 8. Network and security

The production Android build is intended to communicate with Zync's API over HTTPS. The release workflow requires an HTTPS production API base and a public HTTPS privacy-policy URL.

Zync applies input bounds/allowlists to its server endpoints and does not place the OpenRouter API key or analytics provider key in the Android application. No method of transmission or storage can be guaranteed to be completely secure, so this policy does not promise absolute security.

## 9. Retention and deletion

### Local data

Local profile/history data remains on the device until it is changed, app data is cleared, or the app is uninstalled, subject to device/OS backup behaviour outside Zync's control.

### AI requests

Zync's current code requests OpenRouter zero-data-retention-compatible routing and denies provider data collection. The final policy should be checked against the actual production OpenRouter/model-provider configuration before release.

### Analytics data

If analytics is enabled, state the actual configured retention period here: `[ANALYTICS RETENTION]`.

Zync V1 has no user account, so there is no account dashboard containing cloud profile data to delete. For privacy questions or requests concerning server/provider records, contact `[PRIVACY CONTACT]`. The final public policy must accurately describe what can be identified/deleted when records are intentionally anonymous.

## 10. Children and target audience

`[COMPLETE FROM ACTUAL PLAY TARGET-AUDIENCE DECISION. Do not invent an age promise. If the app is not intended for children, state the verified policy-consistent wording here.]`

## 11. Changes to this policy

We may update this policy when Zync's features, providers or legal obligations change. The latest version will be posted at `[PUBLIC HTTPS URL]` with its effective date.

## 12. Contact

Privacy questions:

`[DEVELOPER LEGAL NAME]`
`[PRIVACY CONTACT EMAIL OR FORM]`
`[POSTAL ADDRESS IF REQUIRED/USED]`

---

## Release-owner verification notes — remove from public version

Before publishing:

- replace every bracketed placeholder;
- decide whether production analytics is enabled;
- verify PostHog retention/region if enabled;
- verify Vercel/OpenRouter production-account settings;
- verify the target-audience/children statement;
- make the page publicly accessible without login or geofencing;
- use a normal browser-readable web page, not a PDF;
- configure the same HTTPS URL as GitHub repository variable `ZYNC_PRIVACY_URL`;
- ensure the signed app's Privacy Policy tile opens that URL;
- ensure Play Console Data Safety matches this final policy and the actual binary.

Google Play privacy-policy reference:
https://support.google.com/googleplay/android-developer/answer/10144311

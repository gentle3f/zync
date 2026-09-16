# Zync V1 Product Spec

## Product thesis

**Zync helps two or more people discover hidden shared interests and turns those interests into natural conversations.**

Consumer-facing concept: **Discover what connects you.**

V1 is deliberately not a social network. It is the smallest product that can test whether people enjoy discovering hidden common interests enough to invite another person, Zync again, and reuse it in future social situations.

## V1 principles

1. Global-first and multilingual from day one.
2. No login, account, Firebase, cloud profile, chat, feed, location, community, merchant, ads, payment, or subscription.
3. User interest data is stored locally on-device.
4. QR is the primary peer-to-peer exchange mechanism, so pairing does not require a backend.
5. AI is used only where it materially improves the experience: interest normalization and conversation generation.
6. OpenRouter credentials live only in Vercel server-side environment variables.
7. The app must continue to function when AI is unavailable by using local fallback questions.
8. Existing Google Play identity must be preserved: Android applicationId `com.gmail.gentle3f.myproject`; release versionCode must be greater than 5.

## Core flow

1. User opens Zync.
2. User chooses at least 5 interests.
3. User can mark each interest as `love`, `like`, or `wantToTry`.
4. User taps **Zync with someone**.
5. Person A shows a QR containing a versioned local profile payload.
6. Person B scans the QR.
7. Person B's device compares canonical interest IDs locally.
8. The result screen says **You Zync!** and shows the number of hidden matches without revealing them immediately.
9. Shared interests are revealed one at a time.
10. AI generates a conversation question based on shared interests.
11. If there are no exact matches, AI combines interests from both people to create a crossover question rather than presenting a failure state.
12. Users can request more questions through conversation modes.

## Conversation modes

- Easy
- Fun
- Debate
- Deep
- Guess
- Surprise Me

Questions must prompt interaction between the two people rather than simply asking two independent answers.

## Interest model

Interests are identified by canonical IDs rather than display text.

Example:

```text
sports.badminton
motorsport.formula1
anime.jojo
food.japanese
transport.railways
```

Each canonical interest may include:

- canonical ID
- fallback English label
- category / parent IDs
- localized display names
- aliases / synonyms
- optional source (`seed`, `custom`, `aiNormalized`)

Different-language labels must map to the same canonical ID. For example `Badminton`, `羽毛球`, `バドミントン`, and `배드민턴` all represent `sports.badminton`.

## Free-text interests

Users may search or type anything. If the app cannot resolve it from the local seed catalog / alias index, it may call the Vercel normalization endpoint. The normalized result is shown to the user for confirmation before it is added.

The V1 backend does not maintain a global user-interest database.

## QR payload

QR payload is versioned and should contain only the data required to Zync locally.

Conceptual payload:

```json
{
  "v": 1,
  "id": "local-random-id",
  "name": "Gentle",
  "lang": "zh-Hant",
  "interests": [
    ["anime.jojo", 2],
    ["motorsport.formula1", 2],
    ["travel.japan", 1]
  ]
}
```

No email, phone number, precise location, advertising identifier, or account token is included.

## Hidden Match experience

Scanning must not immediately dump a checklist. The signature interaction is:

```text
YOU ZYNC!
You have 6 hidden matches.
```

Users reveal shared interests one at a time. A rare or specific match may receive stronger visual emphasis than a broad match.

## Zero-match experience

Never show a dead-end `No match` screen.

Instead:

```text
No exact match.
Let's find the connection.
```

The AI endpoint receives a small set of interests from Person A and Person B and generates a meaningful crossover question both people can discuss.

## Zync Again

The app stores a local history of peers previously scanned, identified by their random local Zync ID.

History may contain:

- peer local ID
- nickname
- previous shared canonical IDs
- first Zync timestamp
- most recent Zync timestamp
- number of sessions

On a later scan, the app can highlight newly shared interests.

No peer history is uploaded to Zync servers in V1.

## Interest DNA

The app may summarize a user's local interests by category and strength. It must remain descriptive, not pretend to infer personality or psychological traits.

Example:

```text
Technology 22%
Travel 18%
Entertainment 17%
Sports 13%
Food 12%
```

## Group Zync

Group Zync is desirable but may ship as V1.1 if it delays the core two-person experience. A host device scans multiple participants and performs all group matching locally.

## Languages

Architecture must support arbitrary locales. Initial translation target set:

- English (`en`)
- Traditional Chinese (`zh-Hant`)
- Simplified Chinese (`zh-Hans`)
- Japanese (`ja`)
- Korean (`ko`)
- Spanish (`es`)
- French (`fr`)
- Portuguese (`pt`)

All UI strings must use localization keys. Interest identity must never depend on a localized label.

For people using different languages, AI may return the same semantic question in both languages.

## AI architecture

```text
Flutter app
    |
    | HTTPS POST
    v
Vercel serverless API
    |
    v
OpenRouter
```

Secrets are server-side only. The Android app must not contain an OpenRouter API key.

V1 endpoints:

- `POST /api/v1/question`
- `POST /api/v1/normalize-interest`

The existing Vercel/OpenRouter code in this repository may be reused where sensible, but V1 endpoints should have explicit validated request/response schemas and must not rely on fetching mutable prompts from the default GitHub branch at runtime.

## AI fallback

If the AI request fails, times out, or is rate-limited, the app selects a local template and remains usable.

Examples:

- Shared: `What first got each of you interested in {interest}?`
- Crossover: `If {interestA} and {interestB} were combined into one activity, what would it look like?`

## Android release constraints

- Existing application ID: `com.gmail.gentle3f.myproject`
- Current known Play versionCode: 5
- New release versionCode: >= 6
- targetSdk / compileSdk: 36 for the 2026 rebuild
- Final Android distribution artifact: AAB
- Do not change the installed-app identity while rebuilding the implementation.

## V1 analytics

Analytics should measure product behaviour without uploading the content of a user's interest profile.

Useful events include:

- app_open
- interest_setup_complete
- interest_added
- qr_generated
- qr_scanned
- match_complete
- match_count
- question_generated
- question_next
- mode_selected
- zync_again

Primary validation metrics:

- onboarding completion rate
- first-Zync completion rate
- second-person invitation / install loop
- repeat Zync rate within 30 days
- sessions per active user

## Explicitly out of scope

Do not add these to V1:

- login / registration
- Firebase user profiles
- cloud account sync
- friends / follow graph
- posts / feed
- community rooms
- chat / messaging
- location / nearby people
- activity matching
- social-account import
- merchant deals / advertising
- payment / subscription
- career matching
- dating matching

Phase 2 architecture may be considered later, but it must not create V1 infrastructure cost or delay V1 validation.

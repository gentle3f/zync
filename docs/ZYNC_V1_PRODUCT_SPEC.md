# Zync V1 Product Spec

## Product thesis

**Zync helps people discover hidden shared interests and turns those discoveries into real conversations.**

Consumer-facing concept: **Discover what connects you.**

The signature emotional moment is:

> **“Wait — you like that too?”**

V1 is deliberately not a social network. It is the smallest product that can test whether this two-person discovery moment is strong enough to make people invite another person, Zync again, and reuse Zync in future social situations.

## V1 principles

1. Global-first and multilingual from day one.
2. No login, account, Firebase profile, feed, chat, nearby people, community, merchant, ads, payment or subscription.
3. Core profile, exact matching, history and Interest DNA remain local on-device.
4. QR remains the real-world pairing ritual.
5. The one-scan experience may use a minimal short-lived encrypted relay so the scanner can return its profile to the host automatically; the relay is not a permanent person/profile database.
6. AI is used where it materially improves the human interaction: shared-interest and crossover conversation generation. The shipped V1 interest-entry flow must not block on AI.
7. The app must remain useful when AI is unavailable through local fallback questions.
8. Exact shared-interest semantics use canonical IDs only. Related-interest graphs, regional popularity and AI never manufacture a false exact match.
9. Existing Google Play identity remains `com.gmail.gentle3f.myproject`; target/compile SDK 36; release versionCode must remain greater than the existing Play version.
10. Infrastructure stays small and privacy-minimised while Phase 1 validates behaviour.

## Core flow

1. User creates a lightweight local interest identity.
2. User selects at least 5 interests; the UI should encourage a richer profile because more specific interests improve discovery.
3. Each selected interest can be marked **Love**, **Like**, or **Want to try**.
4. User taps **Show my QR** or **Scan someone**.
5. Person A's QR contains a short-lived encrypted-session handshake plus the host profile needed for local comparison.
6. Person B scans once, compares locally, encrypts its limited profile response on-device and returns opaque ciphertext through the temporary relay.
7. Both phones arrive in the same **Zync Session** automatically.
8. The session creates an impact moment: **YOU ZYNC!** plus a count of hidden connections, without dumping a checklist.
9. Broad taxonomy ancestors are collapsed into a more specific **connection thread** so `Movies -> Anime -> JoJo` does not become three weak reveal moments.
10. Connections are revealed one at a time. Reveal order is deterministic on both devices and favours specificity, mutual interest strength and less-common interests, with only small session-seeded jitter.
11. Each revealed connection keeps both people's original strength values. A `Love` versus `Want to try` contrast is itself useful conversation context.
12. The conversation prompt appears inside the same reveal experience; users do not need to finish a report and enter a separate AI screen.
13. Conversation modes such as Easy, Fun, Debate, Deep, Guess and Surprise are secondary controls, not the main task.
14. If there is no exact match, Zync chooses a plausible local Interest-Graph crossover first, then AI turns that bridge into a question. The experience must not present zero exact matches as failure.
15. A short recap appears when the people finish the session.
16. Zync Again history is stored locally and can mark newly discovered shared interests on repeat sessions.

## Zync Session

The post-scan product is a **session**, not a match report.

The intended rhythm is:

```text
Scan
→ impact
→ reveal one meaningful connection
→ talk about it
→ reveal another when ready
→ recap
```

The app should never require both people to reveal every connection before a conversation can begin.

### Connection threads

Exact matching still happens on canonical IDs. The presentation layer may collapse a broad exact ancestor into a more specific exact descendant.

Example:

```text
Movies
→ Anime
→ JoJo's Bizarre Adventure
```

If all three are exact shared IDs, the session should normally create one strong reveal around **JoJo's Bizarre Adventure**, while broad ancestors may appear only as quiet context.

Sibling specific interests must never be collapsed into one another.

### Reveal ordering

Reveal order must be identical on both devices for an encrypted one-scan session.

The local deterministic **Magic Score** may use information that both devices can calculate consistently:

- taxonomy specificity;
- both people's interest strengths;
- a bounded rarity / lower-popularity signal;
- small deterministic session-seeded jitter.

Device-local Zync Again history may add a **New** badge, but must not silently reorder one phone differently from the other unless a future protocol explicitly synchronizes one authoritative reveal plan.

## Interest model

Interests use language-neutral canonical IDs, not display text.

Example:

```text
sports.badminton
anime.jojo
motorsport.formula1
```

A canonical interest may contain:

- stable canonical ID;
- L1 category;
- L2 family;
- optional L3 subgenre/style/title/franchise layer;
- localized labels;
- aliases / synonyms;
- related-interest graph metadata;
- curated discovery rank;
- regional relevance metadata;
- future physical-locality / activity metadata.

The catalog is a hierarchy plus graph, not one flat list.

Different-language labels map to the same ID. `Badminton`, `羽毛球`, `バドミントン` and `배드민턴` are the same exact interest.

## Regional discovery

Phase 1 may use a coarse device-locale country/region as a soft discovery default. It must not require GPS or precise location.

Regional relevance affects:

- empty-query ordering;
- browse prominence;
- related-interest suggestions.

It never changes exact matching semantics.

The regional rank starts from a curated prior. Aggregate canonical-interest impression/selection signals may adjust discovery slowly. Behavioural data is bounded around the curated base, uses completed-week aggregates, and must not let early users or a sudden traffic spike rapidly rewrite the catalog.

## Free-text interests

Users may search or type anything.

If local catalog/alias resolution succeeds, the known canonical ID is used immediately.

If it does not, V1 creates a deterministic local custom-interest ID immediately. AI normalization is **not** a mandatory gate in the current shipped interest-entry flow.

The legacy `/api/v1/normalize-interest` endpoint may remain for compatibility/research, but current V1 product behaviour and privacy documentation must not imply that every unknown interest is sent to AI.

## One-scan QR and encrypted relay

The handshake QR is versioned and contains only what the intended scanner needs:

- random session ID;
- short expiry;
- one-time AES-GCM 256-bit secret;
- host's limited Zync profile payload.

The private host capability used to read/delete relay state is **not** carried in the QR.

The scanner encrypts its limited profile response on-device. The relay receives opaque ciphertext but not the AES key. The host retrieves, decrypts and authenticates the response locally, then requests deletion. Abandoned relay state expires automatically after roughly three minutes.

The relay is transport, not identity storage.

## Shared conversation question

AI should activate the revealed connection, not summarize the whole profile.

For an exact reveal, send only the focused connection required for the question.

For zero exact matches, use the locally selected crossover pair.

For a one-scan session, the same session + connection + mode + language pair should resolve to the same semantic question on both phones. A short-lived shared question cache may be used for this purpose.

The cache:

- uses a cryptographic hash of random session/connection/mode/language context;
- stores generated question text, not a permanent profile;
- expires after about 15 minutes;
- must fail open to local/ordinary AI behaviour if cache infrastructure is unavailable.

For bilingual peers, both phones should receive equivalent versions of the same semantic question, with each phone showing its own language first.

## Conversation modes

- Easy
- Fun
- Debate
- Deep
- Guess
- Surprise Me

Modes are a secondary **Change vibe** control inside the Zync Session.

Questions must cause interaction between the two people rather than two unrelated survey answers.

## Zero-exact-match experience

Never lead with a failure state.

Preferred framing:

```text
Different interests.
There's still a connection.
```

The local graph chooses a promising bridge, for example:

```text
F1 × Street Photography
```

AI then turns that pair into a natural question both can discuss.

Related interests remain related only; they are not displayed as exact shared interests.

## Zync Again

Local history identifies previous peers by their random local Zync ID and may contain:

- peer ID;
- nickname;
- previously shared canonical IDs;
- first and latest Zync timestamps;
- session count.

A repeat session can label newly shared interests.

No peer history is uploaded as a persistent Zync cloud profile in V1.

## Interest DNA

Interest DNA is a descriptive summary of the user's own local interest identity. It must not pretend to infer psychology, intelligence or personality traits scientifically.

## Group Zync

Group Zync remains a possible V1.1 extension after the two-person loop is stable. It must not delay certification of the core Zync Session.

## Languages

Initial UI target:

- English
- Traditional Chinese
- Simplified Chinese
- Japanese
- Korean
- Spanish
- French
- Portuguese

Canonical interest identity is language-neutral. Cross-language peers can still exact-match and can receive equivalent bilingual prompts.

## AI architecture

```text
Flutter app
    |
    | HTTPS
    v
Zync Vercel API
    |
    +--> short-lived Upstash session/question state
    |
    v
OpenRouter
```

Secrets remain server-side.

Active user-facing AI endpoint:

- `POST /api/v1/question`

Compatibility endpoint, not required by current V1 interest entry:

- `POST /api/v1/normalize-interest`

Question requests enforce the configured Zero Data Retention / provider-data-collection-deny posture.

## AI fallback

If AI fails or is unavailable, the current reveal remains useful and the app supplies a local question.

Examples:

- Exact: `What first got each of you interested in {interest}?`
- Crossover: `If {interestA} and {interestB} became one weekend activity, what would it look like?`

## Product analytics and regional learning

General product analytics remain disabled in the public V1 unless a future release explicitly changes the disclosed posture.

Separately, privacy-minimised **regional interest learning** may be enabled. It sends only coarse region plus canonical catalog IDs shown/selected, without nickname, full profile, custom-interest text, account ID, advertising ID or the optional analytics installation UUID.

Phase 1 metrics that matter include:

- interest-profile completion;
- first-Zync completion;
- QR / one-scan completion;
- connection reveal;
- conversation-question generation / mode use;
- distinct people Zynced with;
- repeat Zync within 30 days;
- whether users report learning something new about the other person;
- whether the interaction started a conversation that otherwise would not have happened.

DAU alone is not the definition of success.

## Explicitly out of scope

Do not add these to V1 without an explicit strategic decision:

- login / registration;
- Firebase/cloud user profiles;
- friends/follow graph;
- posts/feed;
- persistent community rooms;
- messaging/chat;
- nearby people;
- precise location matching;
- random activity matching;
- social-account import;
- merchant deals / advertising;
- payment/subscription;
- career matching;
- dating matching.

Phase 2 architecture may be anticipated in the data model, but must not create V1 product/infrastructure burden before the two-person loop is validated.

# Zync V1 — Icebreaking / Social Exchange / AI-Live QA-Ready Master Handoff

Date: 2026-09-18 HKT  
Branch: `zync-v1-rebuild-20260917`

This is the **authoritative detailed continuation handoff** for the current Zync V1 work.

It is additive. Preserve all previous handoff lineage. In particular, do not delete, replace or reinterpret:

- `AI_STATE/MINI_HANDOFF_20260918_ZYNC_SESSION_QA_READY.md`
- `AI_STATE/MINI_HANDOFF_20260918_QA_APK_READY.md`
- `AI_STATE/MINI_HANDOFF_20260918_UPSTASH_PREVIEW_SMOKE_PASS.md`
- `AI_STATE/HANDOFF_20260918_RELAY_PAIRING_RESPONSIVE_CERTIFIED.md`

Canonical product/business sources remain:

- `docs/ZYNC_BUSINESS_PROPOSAL_AND_VISION.md`
- `docs/ZYNC_V1_PRODUCT_SPEC.md`
- `docs/REAL_DEVICE_QA.md`

Do **not** restart repository discovery, old Thunkable archaeology, or obsolete pre-Zync-Session design work.

---

# 1. Why this handoff exists

The user physically tested the first unified Zync Session QA build and gave four important product-level findings:

1. **Interest selection felt unnatural**
   - interests appeared to shift around;
   - broad taxonomy and leaf interests felt mixed;
   - example: Badminton appearing on the same conceptual browse surface as Drama;
   - the user wanted browsing that fits human spatial/category intuition.

2. **AI appeared not ready**
   - real-device sessions kept showing default/local questions;
   - this later proved to be a real live-backend issue, not user error.

3. **The session ended too quickly**
   - example experience: “2 matches → reveal one → reveal second → result”;
   - user correctly pointed out that Zync is an **icebreaking product**, not a short match-count game;
   - they explicitly suggested showing useful non-matches and helping each person ask about interests the other person has.

4. **People/History felt empty**
   - rows looked tappable but did not provide enough value;
   - user wanted to revisit prior questions and discoveries;
   - default names like `Zync #ABC123` felt sterile;
   - user suggested funny/ridiculous names for laughs.

5. **Post-Zync social exchange should have real utility**
   - user proposed Facebook / Instagram / Threads so people can easily add each other after a successful icebreaker;
   - strategic purpose: give identity/login a meaningful reason later rather than forcing registration before value is experienced.

This handoff records the implementation that followed those findings.

---

# 2. Product definition now

The most important product clarification is:

> **Zync is not merely a tool for finding shared interests.**
>
> Zync uses shared interests, different interests, curiosity and meaningful crossovers to help two people who are physically together discover each other and start real conversations.

The signature emotional moment remains:

> **“Wait — you like that too?”**

But the second strong social moment is now explicitly:

> **“I never knew you were into that — tell me about it.”**

Therefore the current intended rhythm is:

```text
Scan
→ YOU ZYNC impact
→ reveal a meaningful exact shared connection
→ talk about it immediately
→ reveal another shared connection when desired
→ Keep discovering
   → Ask about them
   → Let them ask about you
   → Surprise us / crossover
→ finish when the people choose
→ recap
→ optional social exchange
```

Do not regress to:

```text
scan → reveal N matches → result → done
```

The session length must not be mechanically determined by the number of exact shared IDs.

---

# 3. Interest picker — current implementation

## Problem fixed

The old browse experience mixed taxonomy navigation and recommendation/discovery behavior too aggressively. Regional/popularity recalculation could also make the visible list feel unstable.

## Current rules

`mobile/lib/screens/interest_setup_screen.dart` now implements a stricter browse flow:

- L1 category first;
- then L2 family;
- then L3 where the taxonomy actually has one;
- only at the leaf browsing level are concrete interest items shown;
- global/local search still searches the full catalog directly;
- L1, L2 and L3 controls no longer use one mixed “All” surface that dumps descendants into the same grid;
- browse order is cached per hierarchy scope during the screen session, so selecting an interest does not repeatedly reshuffle the whole page;
- regional popularity can influence the initial ordering, but the same visible scope stays spatially stable.

Regression coverage includes:

- `interest setup drills from category to L2 and L3 taxonomy`
- `sports leaf interests stay hidden until their L2 family is chosen`

A specific regression checks that:

- before choosing Sports, Badminton is not shown;
- after choosing Sports but before choosing the appropriate family, Badminton is still not shown;
- after choosing the racket-sports family, Badminton appears;
- an unrelated concept such as Drama does not appear on that leaf surface.

Do not reintroduce a recommendation feed into the taxonomy grid. If “Suggested for you” is added later, keep it visually/structurally separate from strict browse navigation.

---

# 4. Longer Zync Session / curiosity deck

## Shared exact connections remain exact

Exact match semantics are still:

> canonical interest ID equality only.

Do not convert parents, related graph nodes, regional relevance or AI suggestions into “matches”.

Connection-thread ancestor collapse remains a **presentation layer** only.

## Keep discovering

After the last revealed shared connection, the primary action is now:

> **Keep discovering**

instead of immediately going to recap/result.

The finite conversation surface includes:

### Ask about them

Uses selected interests that belong to the peer but are not exact shared interests.

Example:

> Alex ❤️ Bouldering  
> Ask about them

AI/local fallback should invite Alex to tell a concrete story, recommendation, surprising detail or preference about Bouldering.

The UI and prompt must **not** imply the other person also likes Bouldering.

### Let them ask about you

The role is reversed using the local person’s selected non-shared interests.

This prevents the session from becoming one-sided interviewing.

### Surprise us

Uses the existing local Interest Graph crossover selection.

Crossovers remain explicitly different from exact matches.

## Ranking of unmatched-interest cards

The exploration deck is deliberately finite, not a long profile dump.

The current code ranks a limited number of unique interests using a combination of:

- strength;
- specificity;
- catalog rank / niche signal;
- deterministic tie behavior.

The intention is to expose a few conversation-worthy doors, not every item in both profiles.

## UI architecture

The exploration hub is implemented as one finite scrollable conversation surface rather than a lazy social feed.

This choice was made after widget testing showed that the content is intentionally small (roughly a handful of cards per person), and having all conversational doors built together is more appropriate than treating the experience as an infinite feed.

Regression coverage includes:

- `last shared reveal continues into unmatched-interest icebreaking instead of ending`
- zero-match crossover remains positive rather than a failure screen;
- the two role sections are independently represented.

---

# 5. AI question behavior — mobile side

Key file:

- `mobile/lib/core/ai_service.dart`

## Local-first / AI-late-replace behavior

The mobile app no longer needs to block the conversation while waiting for AI.

Current behavior:

1. a local fallback starter can appear immediately;
2. if a remote AI base URL is configured, the app continues trying in the background;
3. when a real AI question arrives, it replaces the local fallback;
4. if no remote AI is configured, the app does **not** schedule pointless retry timers;
5. QA builds can visibly show whether the current question is:
   - **AI**
   - **Local fallback**

The QA-only indicator is controlled by:

`ZYNC_QA_DEBUG=true`

Production should not expose the debug badge.

## One-person curiosity semantics

Local fallback and server prompts now distinguish three different cases:

1. exact shared connection;
2. one person owns the focus interest and the other does not;
3. true two-interest crossover.

For a one-person focus, prompts should create curiosity and story-sharing rather than invent a fake shared connection.

Regression coverage includes:

- `one-person fallback invites curiosity instead of inventing a crossover`

---

# 6. AI backend incident — full chronology and final state

This is important because the user physically observed default questions.

## First live failure

After the broader icebreaking update was CI-green, a controlled Preview live smoke showed:

- privacy page: PASS;
- encrypted relay lifecycle: PASS;
- TTL cleanup: PASS;
- regional-interest endpoint: PASS;
- AI question endpoint: **HTTP 502**.

Therefore the default questions seen on the phone were not merely cosmetic or a phone-side timing issue.

## First attempted reliability fix

`api/v1/question.js` was updated to preserve strict privacy while giving OpenRouter multiple model candidates:

- configured model, or `openrouter/free`;
- `google/gemma-4-26b-a4b-it:free`;
- `google/gemma-4-26b-a4b-it`.

Provider routing remained:

```js
provider: {
  zdr: true,
  data_collection: 'deny',
  allow_fallbacks: true,
}
```

Privacy was **not** weakened to make AI work.

The OpenRouter privacy contracts were also changed correctly: they still require `zdr === true` and `data_collection === 'deny'`, while allowing safe routing fields such as `allow_fallbacks`.

## Second live failure

The next controlled Preview still returned 502.

A safe diagnostic mechanism was added. It never exposes:

- API key;
- prompt;
- provider error message;
- private user payload.

It can expose only bounded non-sensitive diagnostic metadata when an explicit diagnostic request is made.

The controlled diagnostic smoke then showed the request was no longer merely an upstream routing error. The handler returned:

> `{"error":"empty_ai_response"}`

This narrowed the problem to a successful/routed completion that did not yield usable question text in the response shape the handler expected.

## Final AI fix

The final `api/v1/question.js` now explicitly requests concise text-only, non-reasoning output:

```js
modalities: ['text'],
reasoning_effort: 'none',
max_completion_tokens: generationSecondary ? 420 : 240
```

It also has a more robust `extractMessageText()` that can read:

- ordinary string content;
- array content with text parts;
- compatible text-content shapes.

The server prompt remains strict:

- one conversational question;
- no labels/explanation/markdown;
- bilingual output uses the exact `<<<ZYNC_TRANSLATION>>>` separator;
- interest names are treated as data, not instructions;
- shared, one-person and crossover cases have distinct semantics.

## Final live proof

The controlled text-output Preview is:

- deployment ID: `dpl_Aae42hqrNrL7Fk72B14jVo9gfK3M`
- URL: `https://zync-86yxy110d-gens-projects-4f99f8b9.vercel.app`
- deployment source SHA: `9eb25d003e4745f5add824d117ab575276635358`
- state: **READY**

Live smoke:

- workflow: **Zync Icebreaking Preview Smoke**
- run: **#4**
- run ID: `35357676681`
- source SHA: `5fb6991ce84c2d49ab9cbd8411bbc25c3874cbce`
- conclusion: **SUCCESS**

It proved, against the real Preview:

- privacy page reachable and relay disclosures present;
- encrypted relay host-only poll/consume and idempotent scanner response;
- relay TTL removes abandoned sessions;
- regional-interest endpoint returns completed-week aggregates;
- **live AI question generation returns a real question on the expected privacy-hardened V1 handler**;
- social-sharing privacy disclosure is live;
- **one-person Bouldering curiosity request returns a real AI prompt**;
- `X-Zync-API-Version: v1`;
- `X-Zync-AI-Privacy: zdr-data-collection-deny`;
- reversed bilingual phone order still reuses one semantic question:
  - Traditional Chinese → Japanese;
  - Japanese → Traditional Chinese;
  - second request is a cached semantic equivalent with primary/secondary languages swapped.

This is the first post-user-feedback Preview that should be treated as **AI-live**, rather than “mobile has an AI feature but real sessions may fall back”.

---

# 7. Short-lived shared-question cache

The existing shared semantic question mechanism remains.

For an eligible one-scan session:

```text
same random session
+ same focused connection
+ same mode
+ canonicalized language pair
→ same semantic question
```

The cache key is SHA-256-derived.

Upstash TTL remains about 15 minutes.

The cache stores generated question text, not a permanent cloud profile/history.

Race behavior still uses SET-NX semantics so concurrent phones converge on the stored winner.

Fail-open behavior remains: if the temporary cache is unavailable, question generation can still work.

---

# 8. Funny deterministic aliases

Key file:

- `mobile/lib/core/zync_alias.dart`

A blank nickname no longer renders as a sterile human-facing name such as:

> `Zync #A82F31`

Instead, a deterministic playful alias is generated from the random local ID.

Examples of the intended flavor include:

- Suspicious Capybara
- Chaotic Penguin
- Emotional Toaster
- Midnight Dumpling
- 可疑水豚
- 失眠熊貓

Properties:

- deterministic for the same local ID;
- local/offline;
- does not require AI;
- does not expose the raw ID as the name;
- multilingual word sets exist;
- the same person remains recognizable in local history.

Regression coverage verifies:

- same ID → same alias;
- raw ID is not leaked in the display name;
- old `Zync #...` pattern is not used.

A user-facing “reroll my ridiculous alias” interaction is **not** currently implemented. If added later, save the chosen alias so peer/history identity stays stable.

---

# 9. People / Zync history is now meaningful

Key files:

- `mobile/lib/core/models.dart`
- `mobile/lib/core/local_store.dart`
- `mobile/lib/screens/history_screen.dart`

The People list is no longer intended to be a dead-looking history row.

A peer detail view can now remember locally:

- peer random ID;
- peer nickname / funny alias;
- first and last Zync timestamps;
- session count;
- previous exact shared IDs;
- peer’s latest limited interests received during Zync;
- recent conversation questions actually shown;
- the connection label associated with those questions;
- public social links the peer explicitly chose to share.

The detail page includes sections conceptually equivalent to:

- Things you both like;
- Things you learned about them;
- Questions you talked about;
- Socials they shared.

History remains local to the device.

Old history JSON without the richer fields remains readable.

Regression coverage includes old-history migration and rich-history round-tripping.

---

# 10. Optional social exchange — current V1 implementation

The user's longer-term idea was to use Instagram / Facebook / Threads as a meaningful reason to tie identity/login to Zync.

The current implementation deliberately does **not** jump straight to social OAuth.

Instead V1 now has a platform-neutral, consent-first public-link layer.

## Data model

Supported current platforms:

- Instagram;
- Threads;
- Facebook.

A user can manually enter:

- handle; or
- public profile URL.

Each social link has an independent:

> **Share after Zync**

opt-in.

Only opted-in links are included in the limited profile exchanged with the other participant.

## Security/privacy posture

Current V1 does **not** ask for or store:

- Facebook/Instagram/Threads password;
- browser cookie;
- OAuth access token;
- contacts;
- followers;
- posts;
- private social graph.

This is not yet “Login with Instagram/Facebook/Threads”.

That future identity-claim layer can be evaluated later after the anonymous two-person loop proves value.

## Post-session behavior

If the peer explicitly shared a public social link, recap can offer:

- Open Profile;
- Show QR.

The app generates its own QR from the public profile URL.

The received shared link can remain in that peer’s local Zync history, so “People I Zynced with” has ongoing utility.

## QR compatibility

Social fields are optional.

Old profiles/QR payloads without social fields remain valid.

Regression coverage checks that only explicitly shared links are serialized into the QR/profile payload.

---

# 11. Legal / Play Data Safety synchronization

The following were updated to reflect the actual new behavior:

- `privacy.html`
- `terms.html`
- `docs/PLAY_DATA_SAFETY_V1_RELEASE_ANSWERS.md`
- `docs/PLAY_RELEASE_DATA_SAFETY.md`
- `docs/PRIVACY_POLICY_V1_DRAFT.md`

Public release web contracts now guard against accidentally removing social-exchange disclosure.

The disclosures state, in substance:

- optional public Instagram/Threads/Facebook links can be manually entered;
- only explicitly enabled links are shared;
- social passwords/tokens are not requested for this flow;
- the scanner-side opted-in link may leave the scanner inside the AES-GCM encrypted relay response;
- the recipient may retain a shared public link locally;
- no social graph is imported.

Before any actual Play submission, the current Play Console Data Safety taxonomy still needs final human verification for how it wants explicitly shared public social handles/URLs classified.

Do not assume an old Console category label.

---

# 12. Regional relevance / learning — unchanged core rules

Current regional interest discovery remains:

- coarse device-locale region;
- no GPS;
- no precise location;
- bounded around curated priors;
- current week does not become the learning source;
- general public-V1 analytics remain OFF;
- regional aggregate interest learning is separate and can be ON in production-equivalent QA.

Do not turn regional relevance into physical “people nearby” matching.

---

# 13. Current CI certification

## AI/text-output implementation certification

A key full green run is:

- workflow: **Zync V1 CI**
- run: **#364**
- run ID: `35356833723`
- source SHA: `8246f9e7bbcf9471ca5b0604b3279eef17c175a8`
- conclusion: **SUCCESS**

It passed:

- serverless JavaScript syntax;
- V1 serverless contracts;
- encrypted relay contracts;
- regional interest popularity contracts;
- OpenRouter privacy contracts;
- public release web contracts;
- Play internal-release workflow contracts;
- signing configurator;
- Play internal-release publishing guards;
- Android identity requirements;
- localization generation;
- Flutter Analyze;
- Flutter tests;
- unsigned release AAB build/upload.

Artifact:

- ID: `10552047484`
- name: `zync-v1-unsigned-aab`
- compressed size: `62,255,541` bytes
- digest: `sha256:6bc00cd61b084a9fc2bb66f8310a6b34ed615a6e8ae0e8ff41be346156c3537d`
- expires: 2026-10-02

## Post-preview guard-restore certification

Another full green run after restoring branch auto-deploy guard:

- workflow: **Zync V1 CI**
- run: **#366**
- run ID: `35357654067`
- source SHA: `e5f3968b56ee7609f03c3e2333d3e93dd7cf4c8b`
- conclusion: **SUCCESS**

Artifact:

- ID: `10552897078`
- name: `zync-v1-unsigned-aab`
- compressed size: `62,255,543` bytes
- digest: `sha256:0715743ab703985d89b78f706137c1c1233292dca7cb8709f1cd552b90220e8f`
- expires: 2026-10-02

These are unsigned CI artifacts, **not Play release artifacts**.

---

# 14. Final current QA APK

A new QA APK was built specifically for the live AI Preview.

Workflow:

- name: **Zync QA Preview APK**
- run: **#2**
- run ID: `35358343030`
- workflow/source SHA: `6209f04dad24a87f72e5f93ca719f38327ec9748`
- conclusion: **SUCCESS**

The first QA Preview APK workflow run failed because QA tests were initially allowed to depend on the live Preview/network. That was corrected. The successful run keeps automated tests deterministic/offline while the **built APK itself** points to the live controlled Preview.

## Artifact

- artifact ID: `10553506719`
- artifact name: `zync-qa-preview-ai-live`
- artifact compressed size: `33,494,308` bytes
- artifact ZIP digest: `sha256:b4cecf0ae8a83a85cead1b205ea436c9e7d4e161aae8c6eef2863993ab7f6645`
- expires: 2026-10-02

Artifact contents include:

- `Zync-QA-preview.apk`
- `Zync-QA-preview.sha256.txt`
- `Zync-QA-preview-build.txt`

APK build log:

- release APK approximately 70.7 MB;
- APK SHA-256:
  `663e8f428e53c90f8e2a6dc367276eeaa9b105c1393e14e5a164715cf3c8f195`

## QA identity/config

- app label: **Zync QA**
- package: `com.gmail.gentle3f.myproject.qa`
- separate-install identity; must not overwrite Production;
- API base:
  `https://zync-86yxy110d-gens-projects-4f99f8b9.vercel.app`
- Privacy URL:
  `https://zync-86yxy110d-gens-projects-4f99f8b9.vercel.app/privacy`
- `ZYNC_ANALYTICS_ENABLED=false`
- `ZYNC_INTEREST_LEARNING_ENABLED=true`
- `ZYNC_QA_DEBUG=true`

Therefore real-device QA can directly see whether a question is **AI** or **Local fallback**.

Never upload this QA APK to Play.

---

# 15. Current Preview / Production protection

## Controlled Preview

Current QA backend:

- deployment ID: `dpl_Aae42hqrNrL7Fk72B14jVo9gfK3M`
- URL: `https://zync-86yxy110d-gens-projects-4f99f8b9.vercel.app`
- state: **READY**
- deployment source SHA: `9eb25d003e4745f5add824d117ab575276635358`

This is the backend that passed live AI smoke and that the current QA APK targets.

## Branch deploy guard

Current `vercel.json`:

```json
"deploymentEnabled": {
  "zync-v1-rebuild-20260917": false
}
```

Do not silently enable it.

## Production

Production was **not** promoted or changed in this update.

Do not upload Play or promote Vercel Production without explicit user instruction.

Preview Vercel Authentication has been intentionally permissive for controlled physical QA. Restore the intended protection posture after QA is finished.

---

# 16. QA tests that specifically protect the user's feedback

The successful QA build/test run confirms, among others:

- regional discovery never needs GPS;
- regional priors do not change canonical IDs;
- deep catalog remains unique and preserves legacy IDs;
- local search handles aliases / Chinese terms / niche interests;
- local custom interests need no AI;
- known aliases resolve to canonical IDs rather than duplicate custom IDs;
- related graph recommendations never become exact matches;
- social-link consent settings are scroll-safe on a small phone;
- **last shared reveal continues into unmatched-interest icebreaking instead of ending**;
- bilingual local fallback remains layout-safe;
- strict category → L2 → L3 taxonomy behavior;
- **sports leaf interests stay hidden until their L2 family is chosen**;
- QR includes only explicitly shared public social links;
- old profile and QR JSON still work without social fields;
- compressed large-profile QR preserves metadata;
- exact matching still uses canonical IDs;
- matching preserves each person's separate strength;
- broad ancestors may collapse but sibling specific interests do not;
- seeded reveal order is deterministic on both devices;
- offline fallback returns paired bilingual questions where appropriate.

---

# 17. Ten-workstream status

| Workstream | Status | Current meaning |
| --- | --- | --- |
| 1. Product vision / emotional core | GREEN | Canonical docs now define shared surprise + curiosity about differences, not match-count gameplay. |
| 2. Interest catalog / taxonomy / search | GREEN for current V1 | Deep multilingual catalog, strict hierarchy browse, local search/custom, stable browse scope. Needs more real-device UX feedback, not architecture rediscovery. |
| 3. Regional relevance / learning | GREEN | Coarse locale only, no GPS, bounded learning, current public-V1 posture preserved. |
| 4. QR / encrypted one-scan pairing | GREEN | One-scan relay remains certified and live-smoke passing. |
| 5. Exact matching / connection threads | GREEN | Exact canonical-ID intersection; presentation collapse only for true ancestors; deterministic reveal order. |
| 6. Zync Session / icebreaking deck | GREEN in CI, needs physical QA | Shared reveal now continues into Ask about them / Let them ask about you / Surprise us. |
| 7. AI conversation engine | GREEN live | Previous 502/default-question problem was real and has now been fixed; live Preview returns real AI questions under ZDR/data-collection-deny and bilingual cache still works. |
| 8. People history / identity | GREEN in code, needs physical QA | Funny stable aliases, tappable detail, interests/questions/social memory are implemented locally. |
| 9. Social exchange | GREEN in code, needs physical QA | Manual public IG/Threads/Facebook links with per-link opt-in; recap Open Profile / Show QR; no OAuth account binding yet. |
| 10. Release / legal / QA | QA-READY, Production CLOSED | Legal/Play docs aligned; new QA APK built; Preview live-smoke passed; Production and Play untouched. |

---

# 18. Current implementation head versus docs/workflow head

Important for audit clarity:

- the newest QA workflow/source head before this handoff document is:
  `6209f04dad24a87f72e5f93ca719f38327ec9748`
- the live Preview backend was deployed from:
  `9eb25d003e4745f5add824d117ab575276635358`
- subsequent branch commits include:
  - guard restoration;
  - live-smoke workflow updates;
  - QA workflow/build plumbing;
  - no Production promotion.

Do not incorrectly assume the Preview deployment Git SHA must equal the latest branch SHA. The Preview intentionally represents the controlled backend build that was live-smoke certified, while the later source head contains test/build workflow changes and guard restoration.

---

# 19. Immediate next task — physical QA, not more architecture work

The correct next step is **physical QA of the new feedback-driven build**.

Use artifact ID:

> `10553506719` — `zync-qa-preview-ai-live`

Recommended physical checks, in this order:

## A. Interest picker feel

On a real phone:

1. open/edit interests;
2. confirm L1 only feels like broad categories;
3. drill Sports → correct family → Badminton;
4. verify unrelated leaf interests do not pollute the same browse surface;
5. select several interests and confirm the page no longer visibly reshuffles around every tap;
6. use Search and confirm full-catalog direct lookup still works.

This is specifically to validate the user's “Badminton same page as Drama / always shifts around” complaint.

## B. AI source

Perform a real Zync.

When a question appears, the QA badge should show:

> **AI**

after remote generation succeeds.

If it remains:

> **Local fallback**

record:

- which connection card;
- language pair;
- selected mode;
- whether phone was on Wi-Fi/mobile data;
- approximate wait time.

Do not assume backend is broken again unless reproduced; the current controlled Preview has live-smoke proof of AI 200.

## C. Longer icebreaker

Create profiles with:

- 1–2 exact shared interests;
- at least one strong unique interest on each side.

Verify:

1. reveal exact connection(s);
2. last exact reveal leads to **Keep discovering**, not Result;
3. **Ask about them** surfaces a real peer-only interest;
4. **Let them ask about you** surfaces a real local-only interest;
5. questions do not pretend those interests are shared;
6. **Surprise us** gives a crossover when available;
7. either person can finish without consuming every card.

## D. Funny alias

Use a peer with no nickname.

Verify:

- human-facing name is playful, not `Zync #ID`;
- same peer remains the same alias on repeat Zync/history;
- raw random ID is not exposed as the display name.

## E. People history

After the session:

1. open People / history;
2. tap the peer;
3. confirm the row now has a meaningful detail page;
4. check prior shared interests;
5. check peer-only interests learned;
6. check questions used;
7. repeat Zync and confirm history updates rather than duplicating identity incorrectly.

## F. Social exchange

On one profile:

1. add an Instagram/Threads/Facebook public handle or URL;
2. leave at least one platform **not shared**;
3. enable **Share after Zync** for another platform;
4. Zync with the second phone;
5. verify only the opted-in link appears after the session;
6. test Open Profile;
7. test Show QR;
8. open peer history afterward and confirm the shared link can still be found locally;
9. confirm the non-opted-in link never leaked to the other phone.

Do not test with passwords or OAuth tokens; the current feature does not use them.

## G. Two-device semantic question consistency

Traditional Chinese + Japanese remains a useful gate.

Confirm both phones receive the same semantic question with their own language first.

The backend has automated live proof; physical QA still needs to confirm the rendered experience feels natural.

---

# 20. What is intentionally NOT implemented yet

Do not mistake these for bugs:

- required Zync account/login;
- Login with Facebook;
- Login with Instagram;
- Threads OAuth account binding;
- importing followers/friends/posts/contacts;
- permanent cloud user profile;
- feed;
- DMs/chat;
- communities;
- nearby people;
- location matching;
- merchant layer;
- payments;
- subscription;
- user-controlled funny-alias reroll;
- Phase-2 hobbies economy.

The social-link feature is deliberately useful before account binding exists.

A future “Claim your Zync identity” step may later use login as a retention/restore mechanism, ideally after the user has experienced value.

---

# 21. Temporary diagnostic / engineering notes

`api/v1/question.js` still supports an explicit bounded diagnostics request that can expose only safe status/shape metadata.

It must never expose:

- OpenRouter API key;
- prompt;
- raw provider error message;
- private user content beyond what the caller already sent.

The controlled live smoke can use diagnostics for engineering verification.

Before Production launch, decide whether to keep this safe bounded diagnostic surface or remove/disable it outside Preview.

The smoke and QA workflows are path-triggered only when their workflow files change; they are not intended as general auto-deploy behavior.

---

# 22. Known remaining non-blocking issues / cleanup

These are not blockers to the next physical QA round, but keep them visible:

1. **Physical UX is still the deciding gate.**  
   CI cannot prove the strict hierarchy now feels natural to a human.

2. **Funny alias reroll is not implemented.**  
   Current alias is deterministic only.

3. **Social login/account claiming is future work.**  
   Current value comes from manual opt-in public social links.

4. **Preview protection posture must be restored after controlled QA.**

5. **Public landing page copy may still contain older language around AI normalization.**  
   Before any Production promotion, audit the root landing page and remove stale claims that no longer describe the shipped local-first interest-entry flow.

6. **Play Data Safety Console still needs final live-console category verification** before submission.

7. **Do not upload the QA APK to Play.**

8. **Do not promote Production merely because Preview/QA is green.**  
   Physical QA of this new product loop comes first.

---

# 23. Strategic guardrails

Keep these constraints:

- QR remains the deliberate face-to-face ritual.
- AI remains conversation fuel, not decoration.
- Exact matching remains canonical-ID equality.
- Related graph never becomes a fake exact match.
- Regional relevance never becomes precise-location matching.
- Do not require login before users experience value.
- Do not turn People history into a social feed.
- Do not expose all non-matches as a giant report.
- Do not let session length equal exact-match count.
- Do not optimize for gambling-style reveal mechanics.
- Do not add dating framing.
- Do not create a giant social network before the two-person loop is proven.

The core question remains:

> **Does Zync help two people discover something about each other that naturally starts a conversation they otherwise might not have had?**

---

# 24. Short next-chat continuation prompt

The user should not paste this entire handoff into the next chat.

Use only:

```text
Continue Zync V1 on branch `zync-v1-rebuild-20260917`.

Read `AI_STATE/LATEST_HANDOFF.md`, then read the authoritative handoff it points to in full. Do not restart repository discovery or old Thunkable archaeology.

Continue directly from the current QA-ready physical-test state. Production and Play remain closed.
```

That is intentionally short because the authoritative detail now lives in GitHub.

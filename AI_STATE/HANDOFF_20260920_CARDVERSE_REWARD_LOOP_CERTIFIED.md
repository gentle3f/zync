# Zync — Authoritative Handoff — Reward Loop Certified

Date: 2026-09-20
Branch: `zync-v1-rebuild-20260917`
Status: **Current implementation checkpoint; certified by CI and QA Preview**
Production: **CLOSED**
Google Play: **CLOSED**
Branch auto-deploy: **do not enable without explicit instruction**

---

# 1. Read-this-first rule

This file is the authoritative continuation checkpoint for the current Zync build.

Do **not** restart repository discovery.
Do **not** return to old Thunkable archaeology.
Do **not** re-derive product strategy from scratch.
Do **not** assume the old `LATEST_HANDOFF.md` active task (“physical Android QA of Octalysis Batch 1”) is still current.

Continue from the certified state recorded here.

Also read these canonical product documents when needed:

- `docs/ZYNC_BUSINESS_PROPOSAL_AND_VISION.md`
- `docs/ZYNC_MASTER_EXECUTION_PLAN.md`
- `docs/ZYNC_V1_PRODUCT_SPEC.md`
- `docs/ZYNC_CARDVERSE_ARCHITECTURE_V1.md`
- `docs/ZYNC_CARD_VISUAL_SPEC_V1.md`
- `docs/ZYNC_CARD_GENERATION_PIPELINE_V1.md`

Preserve earlier handoff lineage; this checkpoint supersedes the old active-task pointer but does not delete history.

---

# 2. Certified current head

Latest branch head at handoff creation:

`958ffeef642e6970ff79678a11efa7d0f281ed6a`

Commit:

> `test: scroll Reward Loop Lab before opening issued pack`

Latest successful checks:

- **Zync V1 CI #823 — SUCCESS**
- **Zync V1 CI #822 — SUCCESS**
- **Zync QA Preview APK #201 — SUCCESS**

Draft PR remains open and must remain unmerged:

- PR #1
- title: `QA gate: Zync V1 AI v2 + trophies — DO NOT MERGE`
- state: open
- draft: true
- head: `958ffeef642e6970ff79678a11efa7d0f281ed6a`

The prior failures around Reward Loop Lab were test-interaction issues and were fixed; latest head is green.

---

# 3. Current product position

Zync is no longer treated as only an “interest match” app.

Current product framing:

> **Zync is a playable real-world interest layer that helps people discover each other, discover themselves, and turn interests into things worth doing together.**

Core product promise:

> **Zync helps you discover what connects you — and turns those connections into things worth doing together.**

Core loop:

```text
Meet
→ Mystery
→ Reveal
→ Play
→ Discover
→ Decide / Do
→ Remember
→ Progress
```

System tree:

```text
Interest Graph
      ↓
Real-world Zync
      ↓
AI Interaction / Decision Engine
      ↓
Zync Now + Group Zync
      ↓
Quest / Progress
      ↓
Cardverse + Collection
      ↓
Cloud Ownership + Trading
      ↓
Guest Zync
      ↓
Places + Activities + Brands + Communities
      ↓
Hobbies Economy
```

Non-negotiable product rule:

> If a feature increases screen time but does not improve real-world social discovery, useful decision-making, interest exploration, real activity, or durable ownership, it is not core priority.

---

# 4. Product constitution

Keep these principles intact:

1. Real people first.
2. Surprise with meaning.
3. Every reward reinforces a meaningful Desired Action.
4. Ownership must be durable.
5. Social before competitive.
6. Black-Hat mechanics are seasoning, not the product.
7. Privacy by architecture.
8. Side loops must feed the core loop.
9. Small first action, deep later journey.
10. Do not ship a mechanic without knowing the behavior it should increase.
11. Commercial participation may not manufacture personal truth.
12. Graphics, motion, haptics and sound are product functionality where emotion matters.

No leaderboard for “who met the most people”.
No paid fake social matches.
No fake exact-match semantics.

---

# 5. Current Home / visible product state

Current Home is still the real app surface.

Visible core entries currently include:

- 1:1 Show QR / Scan
- Zync Now
- Curiosity Board
- Group Zync
- My Interests
- People history
- Interest DNA
- Trophy access
- Social links
- Privacy where configured

Important:

**The Cardverse labs are NOT exposed on Home.**

These are intentionally internal proof screens only:

- `CardverseVisualLabScreen`
- `CardverseCollectionLabScreen`
- `CardversePackOpeningLabScreen`
- `CardverseRewardLoopLabScreen`

Do not accidentally expose these as if cloud ownership is production-ready.

---

# 6. Two-person core status

The existing two-person V1 remains the stable baseline:

```text
Select interests
→ QR pairing
→ hidden connection reveal
→ structured AI interaction
→ curiosity / crossover
→ recap
```

Key invariants:

- exact match = canonical interest ID equality only;
- related-interest logic must never fake an exact match;
- detailed People history remains local-first;
- received social links remain local-first;
- no hidden permanent precise-location tracking;
- social-handle exchange remains opt-in and separate from future Cardverse account auth.

Structured interaction metadata / V3 foundation exists.

Do not regress the core while building Cardverse/cloud systems.

---

# 7. Group Zync status

Group Zync foundation exists and uses the shared room/session architecture.

Target architecture:

- 3–8 participants for Group Zync;
- host + QR join;
- no permanent group chat;
- privacy-minimised participant data;
- hidden/private responses;
- room mechanics and synchronized result.

Do not split Group Zync into a separate unrelated architecture.

The same room protocol family is also used by standalone Zync Now via room-purpose / `roomKind` routing.

---

# 8. Zync Now status

Standalone Zync Now is implemented as a real visible flow.

It does **not** require users to first finish a Group Zync discovery game.

Current visible standalone flow:

```text
Host opens Zync Now
→ QR
→ 2–8 people join
→ each submits private constraints
→ host waits for everyone
→ engine generates 2–3 feasible finalists
→ everyone privately votes
→ consensus
→ same result for group
→ chosen activity saved locally
```

Current private constraints include:

- time
- budget
- energy
- indoor / outdoor / either
- novelty preference
- explicit hard vetoes

Current novelty / activity modes support familiar / discovery / mixed semantics.

Important behavioral rules already implemented:

- `Flexible` time means no time restriction.
- `Either` indoor/outdoor means no setting restriction.
- hard vetoes are real constraints, not soft preferences.
- no majority vote may silently override one participant’s hard veto.
- private answers remain private.
- output is deliberately bounded rather than an infinite recommendation feed.

Zync Now Phase 1 still gives **what to do**, not specific venue/restaurant recommendations.

No brand collaboration or place data is assumed.

---

# 9. Zync Now no-fit recovery

Hard-veto-safe relaxation exists.

If there are not enough feasible finalists:

- Zync does not silently ignore someone;
- it may offer explicit relaxation of **soft** preferences only.

Possible soft relaxations:

- time
- budget
- energy
- setting
- novelty

Hard vetoes remain unchanged.

The relaxation planner has tests enforcing this.

The room coordinator can retry with one explicit relaxation and opens a new consensus round.

---

# 10. Tried Together / activity outcome

Chosen Zync Now activities are stored locally.

A later Zync Now visit may ask:

> Did you actually do your last Zync?

Current outcomes:

- completed
- not yet / keep pending
- skipped

Important behavior:

- do not ask “Did you do it?” immediately after choosing;
- completed activity becomes a real Tried Together memory;
- skipped activity does not permanently suppress similar future suggestions;
- activity memory does not store the other person’s identity by default.

This is the bridge from decision-making to meaningful progress.

---

# 11. Privacy-bounded progress events

A shared progress-event layer now exists.

Files:

- `mobile/lib/core/progress_event.dart`
- `mobile/lib/core/local_store.dart`

Events can represent:

- one-to-one Zync completed;
- Tried Together completed.

The event stream stores only coarse behavioral context such as:

- event type;
- source;
- timestamp;
- participant count;
- repeat-person boolean;
- mode;
- broad interest categories.

It deliberately does **not** store:

- peer ID;
- peer nickname;
- raw QR data;
- detailed interaction text;
- canonical peer-history identity.

Tests explicitly verify serialized progress events do not leak peer identity or canonical interest IDs in the coarse event payload.

---

# 12. Quest / Curiosity Board status

Curiosity Board is visible from Home.

Quest engine:

`mobile/lib/core/quest_engine.dart`

Current quest families include examples such as:

- daily one-to-one Zync;
- daily Tried Together;
- weekly meet new people;
- weekly real-world actions;
- weekly distinct interest-category discovery.

Current rules:

- daily reset follows device-local midnight;
- weekly cycle starts Monday;
- repeat person does not count as “new person”;
- duplicate event IDs are counted once;
- quests are driven by real-world events, not fake tap-grind.

Important trust boundary:

> Local Quest completion means **reward eligibility only**.

The local phone does not mint packs/tokens/cards.

The visible Curiosity Board currently has no production Claim button.

---

# 13. Interest localization gate

The previous 3,000+ generic-leaf translation backlog has been addressed.

Current automated audit requires generic interests to have:

- English;
- Traditional Chinese;
- Simplified Chinese.

Proper-name clusters may remain native/common where appropriate.

Canonical IDs do not change.

The translation gate is important because Cardverse card titles use the same canonical Interest Catalog.

Do not reintroduce English-only generic hobby leaves.

---

# 14. Cardverse architecture decisions

Cardverse is now designed as a durable ownership/discovery layer around real Zync behavior.

Card rarity rule:

> **The hobby itself is never Common/Rare/Legendary.**

Instead:

- canonical interest = base card identity;
- finish = Normal / Foil / Holo / Prism / Legendary / Secret;
- edition = Core / Encounter / Discovery / Event / Starter / Achievement.

Any hobby may have a rare finish.

This avoids implying that unusual hobbies are socially more valuable.

Canonical identity:

- interest ID is stable;
- localization is presentation only;
- card visual seed uses canonical ID + art-system version;
- changing language must not change the base visual identity.

---

# 15. Cardverse domain / ownership foundation

Files:

- `mobile/lib/core/cardverse_models.dart`
- `mobile/lib/core/cardverse_trade_models.dart`

Implemented contracts include:

### Account shape

- internal Zync account UUID;
- Google / Apple identity links;
- provider email is not the inventory primary key.

### Ownership

- stackable balances;
- unique instances;
- locked quantities;
- version fields.

### Tradability

Default:

- Core: tradable;
- Encounter: soulbound;
- Starter: soulbound;
- Achievement: soulbound.

Locked assets cannot be traded.

### Pack request

Client may supply:

- pack ID;
- idempotency key;
- client reveal version.

Client may not supply:

- RNG seed;
- desired card;
- desired finish;
- desired rarity;
- desired result.

### Pack receipt

Server-validated receipt contains:

- pack ID;
- server roll ID;
- idempotency key;
- rolled timestamp;
- committed card result items.

---

# 16. Direct Trading foundation

Trading is **ready by architecture but not a shipped product**.

Current contracts support:

- direct two-person trade;
- offer revision;
- bilateral confirmation of the same revision;
- short-lived trade;
- asset reservation/lock;
- immutable inventory ledger;
- atomic server settlement receipt.

Explicitly excluded:

- cash marketplace;
- player cash pricing;
- auction;
- speculative coin economy.

Encounter / soulbound cards are not tradable.

No marketplace should be introduced early.

---

# 17. Card visual system status

Canonical specs:

- `docs/ZYNC_CARD_VISUAL_SPEC_V1.md`
- `docs/ZYNC_CARD_GENERATION_PIPELINE_V1.md`

Runtime renderer:

- `mobile/lib/widgets/zync_card_preview.dart`

Recipe resolver:

- `mobile/lib/core/card_visual_recipe.dart`

Current visual system is procedural, not 3,000 independent images.

It uses:

```text
Interest metadata
× category kit
× visual family
× scene grammar
× motif
× deterministic palette
× edition
× finish
```

Base visual seed:

```text
hash(canonical interest ID + art system version)
```

Not localized label.

---

# 18. Card visual proof status

The visual system has been expanded beyond the original 12-card review batch.

### 12-card human review batch

Representative cards include examples such as:

- Badminton
- Basketball
- Bouldering
- Coffee
- Cooking
- Yoga
- Photography
- Film
- Music
- Gaming
- Reading
- DIY / Crafts

### 50-card expanded proof batch

Current automated coverage:

- exactly 50 canonical interests;
- 15 category kits;
- 30+ visual families;
- unique deterministic seeds;
- English + Traditional Chinese labels validated;
- render smoke tests across English and Traditional Chinese.

Additional scene grammars cover examples such as:

- Travel
- Japan / destination
- Roadtrip
- Food travel
- AI
- Programming
- Robotics
- Mechanical keyboards
- Camping
- Surfing
- Stargazing
- Birdwatching
- Pilates / Meditation
- Drawing / Watercolor / Ceramics
- Japanese food / Dim Sum / Sushi
- Rock / Piano / Concerts
- Board Game / Strategy
- Languages / History
- Knitting

This is intentionally a proof set, not yet the full 3,000-card production set.

Do not assign permanent release card numbers casually before the release registry is frozen.

---

# 19. Finish / animation status

Card renderer supports:

- Normal
- Foil
- Holo
- Prism
- Legendary
- Secret

Grid/binder cards are static by default for performance.

Focused card may animate.

Reduce Motion forces focused finish effects back to static.

Legendary/Secret can use richer focus effects, but:

- no fake near-win;
- no deceptive “almost Legendary” animation;
- rarity effect follows the already-committed result.

---

# 20. Visual Lab / Binder Lab

Internal proof screens exist.

### Visual Lab

`mobile/lib/screens/cardverse_visual_lab_screen.dart`

Purpose:

- inspect 12 representative cards;
- compare finish tiers;
- view focus-only shimmer;
- inspect deterministic visual recipe.

### Collection / Binder Lab

`mobile/lib/screens/cardverse_collection_lab_screen.dart`

Mock-only inventory proof.

Current mock UX includes:

- 50-card binder;
- discovered count;
- missing silhouettes;
- duplicates;
- Encounter;
- Want to Try;
- filters;
- focused card detail.

Important:

This is explicitly labelled mock/prototype inventory.
It does not imply cards are stored in cloud yet.

---

# 21. Cardverse → Interest DNA bridge

File:

`mobile/lib/core/card_interest_bridge.dart`

Card discovery can add a canonical interest as:

`InterestStrength.wantToTry`

Rules:

- new card discovery → may add Want to Try;
- existing Like → never downgraded;
- existing Love → never downgraded;
- removing Want to Try only removes a genuine Want-to-Try state;
- non-canonical interest ID is rejected.

Cardverse must reuse the existing Interest DNA model, not create a second independent hobby-intent database.

---

# 22. Receipt-driven Pack Reveal

Current file:

`mobile/lib/core/cardverse_pack_reveal.dart`

This is now implemented and tested.

Core rule:

> **The server receipt decides the pack result before the reveal animation begins.**

`CardversePackRevealPlan.fromReceipt()` converts a persisted server-authoritative pack receipt into a reveal plan.

There is no client Random / seed / reroll API.

Unknown finish or unknown/unapproved card art is rejected.

Supported edition labels currently include:

- Core
- Encounter
- Discovery
- Starter
- Achievement
- Event

---

# 23. Pack reveal resume semantics

Reveal cursor is immutable.

Example:

```text
0 / 5
→ 1 / 5
→ 2 / 5
→ 3 / 5
→ 4 / 5
→ 5 / 5
```

Checkpoint:

`CardversePackRevealCheckpoint`

Stores:

- `serverRollId`
- `revealedCount`

Resume is allowed only when checkpoint serverRollId matches the plan’s persisted roll.

Example:

If revealedCount = 3:

- first three remain revealed;
- next item is exactly the originally committed fourth card;
- there is no reroll.

Fully revealed cursor cannot reveal again.

---

# 24. Pack reveal timing

Current timing contract:

- Normal: ~350 ms
- Foil: ~450 ms
- Holo: ~650 ms
- Prism: ~800 ms
- Legendary: ~1050 ms
- Secret: ~1200 ms

Reduce Motion:

- suspense delay = zero;
- card result remains identical.

Longer rare-card timing is allowed only because rarity was already fixed by the server receipt.

---

# 25. Pack Opening Lab

File:

`mobile/lib/screens/cardverse_pack_opening_lab_screen.dart`

Internal proof only.

It uses a persisted-receipt-shaped proof result.

Current proof pack includes:

1. Badminton — Normal — Core
2. Coffee — Foil — Core
3. Bouldering — Holo — Core
4. Piano — Prism — Discovery
5. Japan — Legendary — Core

Current lab validates:

- sealed pack does not reveal names;
- receipt result is already locked;
- reveal one card at a time;
- focused rare finish FX;
- progress count;
- recap;
- serverRollId proof;
- resume at 3/5;
- fully revealed resume goes directly to immutable recap;
- Reduce Motion behavior.

This screen is not exposed on Home.

---

# 26. Quest → Reward trust boundary

Latest work added a server-authoritative reward grant contract.

File:

`mobile/lib/core/cardverse_reward_grant.dart`

Client Quest claim may send only bounded proof:

- eligibility key;
- quest ID;
- cycle start;
- proof event IDs;
- idempotency key;
- client contract version.

Client may **not** choose:

- reward kind;
- amount;
- pack ID;
- pack IDs;
- card;
- finish;
- rarity.

Server response determines the reward.

---

# 27. Reward grant receipt

`CardverseRewardGrantReceipt`

Server-owned fields include:

- grant ID;
- eligibility key;
- quest ID;
- idempotency key;
- grant kind;
- amount;
- issuedAt;
- server sequence;
- unopened pack IDs where applicable.

Current grant kinds:

- Draw Token
- Standard Pack
- Discovery Pack

Rules:

- pack grant must contain exactly the required number of unopened pack IDs;
- duplicate pack IDs rejected;
- Draw Token grant cannot smuggle a pack;
- receipt can be checked against local eligibility.

Again: local completion does not mint inventory.

---

# 28. Unopened Pack entitlement

File:

`mobile/lib/core/cardverse_pack_entitlement.dart`

A server-issued pack grant becomes a bounded unopened-pack entitlement.

Client cannot invent a pack ID.

Draw Token cannot be converted into a pack entitlement.

Entitlement creates a bounded open request containing:

- pack ID;
- idempotency key;
- client reveal version.

It contains no RNG controls.

A pack-open receipt is accepted only when:

- receipt is server-authoritative;
- request pack ID matches entitlement;
- receipt pack ID matches entitlement;
- receipt idempotency key matches the open request.

---

# 29. End-to-end Cardverse Reward Loop Lab

File:

`mobile/lib/screens/cardverse_reward_loop_lab_screen.dart`

Latest end-to-end proof is implemented and certified.

The lab demonstrates:

```text
real-world actions
→ Quest progress
→ reward eligibility
→ client claim with bounded proof
→ mock server revalidation
→ server reward grant
→ unopened pack entitlement
→ bounded pack-open request
→ persisted pack receipt
→ receipt-driven Pack Opening Lab
→ reveal
→ future Collection update
```

Current proof scenario:

- 2 × one-to-one Zync
- 1 × Tried Together
- completes `weekly_real_world_three`
- produces local eligibility
- client claim includes 3 proof-event IDs
- client does not choose reward output
- mock server issues 1 Standard Pack
- unopened pack ID: server-owned
- opening routes into receipt-driven sealed Pack Lab.

Important:

The server in this Lab is still **mocked**.

This lab proves the contract boundary and UI flow.
It does **not** mean a real cloud backend exists yet.

Latest green commit was specifically a test stabilization for opening this issued pack.

---

# 30. Why the current Reward Loop matters

This is the first time the engagement loop is connected end to end without violating trust boundaries:

```text
Real behavior
→ local progress
→ eligibility
→ server-owned reward decision
→ server-owned unopened pack
→ server-owned roll
→ client reveal
```

This preserves the product philosophy:

- rewards follow meaningful real-world action;
- local app cannot cheat its own inventory;
- card reveal is emotional presentation, not economy authority;
- reroll is impossible after server roll;
- collection can later become durable cloud ownership.

---

# 31. What is still MOCK / NOT implemented

Do not overclaim.

The following are **not** production-complete:

### Real Cardverse backend

Not yet implemented:

- production transactional database;
- real account service;
- Google sign-in;
- Apple sign-in;
- cloud inventory rows;
- actual pack ownership persistence;
- actual server Quest validation;
- actual server pack RNG;
- actual immutable server ledger;
- actual multi-device restore.

### Real reward Claim

Curiosity Board does not currently expose a production Claim button.

Reward Loop Lab simulates server validation.

### Full cloud Collection

Binder Lab uses mock inventory.

### Real trading

Only the domain/atomicity contract exists.

### Full 3,000+ card set

Only a 50-card proof batch is currently exercised.

### Guest Zync

Still later.

### Places / restaurants / brands

Still later.

Zync Now Phase 1 deliberately recommends activities, not specific places.

---

# 32. Backend requirements already locked

When real Cardverse cloud work begins, backend must support:

- authenticated internal Zync account ownership;
- transactional operations;
- row/version locking or equivalent;
- idempotency;
- unique constraints;
- append-only ledger;
- atomic pack consume + result + inventory write;
- atomic multi-account trade settlement;
- server-side RNG;
- rate limiting;
- migrations/auditability.

A transactional relational DB such as PostgreSQL is a natural fit, but no final provider is selected by this handoff.

Do not choose a backend merely because it is convenient for a prototype.

---

# 33. Account/cloud decisions already locked

Cloud-backed when implemented:

- card collection;
- unopened packs;
- draw tokens;
- Quest grants;
- cosmetics;
- wishlist;
- trading ownership state.

Remain local-first by default:

- detailed People history;
- conversation history;
- received social links;
- raw pairing data;
- detailed private AI/session content.

Cardverse account identity:

- internal Zync UUID;
- Google / Apple linked providers;
- email not primary inventory key.

Do not force account creation before the user understands Zync.

Natural login moment remains:

> Your collection is about to begin. Keep every card when you change phones.

---

# 34. Production / QA discipline

Do not promote production.

Do not upload to Play.

Do not merge PR #1.

Do not assume successful internal Lab tests equal public readiness.

Current internal labs should stay unlinked from Home until the ownership path is real enough to avoid misleading users.

A new QA APK should be produced only for a coherent milestone, not every small Cardverse commit.

---

# 35. Great-Minds / product gate

Before major new work, keep asking:

1. What real user problem does this solve?
2. Which Desired Action does it increase?
3. Which core Zync loop does it strengthen?
4. What data is required?
5. Is the privacy boundary preserved?
6. What is the smallest proof?
7. What metric shows success?
8. What is explicitly out of scope?
9. Does it degrade gracefully offline / with weak network?
10. Does it make Zync more useful in real life, or merely busier on screen?

---

# 36. Recommended next active task

The latest Reward Loop Lab proves the contracts.

**Do not spend the next chat rediscovering Pack/Binder/Quest semantics.**

The recommended next major engineering task is:

## Milestone 5 foundation — Durable Cardverse Ownership

Proceed in this order:

### Step 1 — Freeze real cloud API/domain boundary

Create/update the cloud ownership implementation spec around the already-certified contracts:

```text
account
→ server quest validation
→ reward grant
→ unopened pack
→ open request
→ server roll
→ inventory write
→ receipt
→ reveal checkpoint
→ collection sync
```

Do not allow the client to own reward output or RNG.

### Step 2 — Select transactional backend

Evaluate the simplest backend that satisfies the locked requirements.

Do not silently introduce a non-transactional store that will break pack/trade atomicity.

### Step 3 — Implement internal account + identity abstraction

Backend account should use internal Zync UUID and be capable of later Google + Apple linking.

The user previously insisted collection cannot be local-only.

### Step 4 — Implement cloud inventory / ledger before public Cardverse UI

Start with:

- account;
- pack entitlement;
- stackable balance;
- unique instance;
- append-only ledger;
- idempotency records.

### Step 5 — Move the mock Reward Loop server decisions into actual server endpoints

Required actions conceptually:

- claim Quest reward;
- list unopened packs;
- open pack;
- fetch inventory / collection;
- resume pack reveal.

### Step 6 — Only then connect real Curiosity Board reward Claim + public Collection

Do not expose a fake durable collection before this.

---

# 37. Parallel product work that can continue safely

While cloud ownership is being designed/implemented, these tracks are safe if needed:

- continue improving Interaction Engine real mechanics;
- continue Group Zync group mechanics;
- improve Zync Now activity metadata and candidate quality;
- My Zync World information architecture;
- Encounter reward design;
- Card visual quality / accessibility.

Do not let these destabilise the certified core.

---

# 38. Important recent commit lineage

Most recent certified Cardverse sequence:

- `3deb150...` — add receipt-driven Cardverse pack reveal plan
- `6a3370f...` — certify receipt-driven pack reveal semantics
- `b70fb55...` — add receipt-driven Pack Opening Lab
- `9ad00f5...` — add resumable reveal checkpoint
- `288e142...` — certify checkpoint resume isolation
- `63d5134...` — certify Pack Opening Lab
- `71129de...` — add server-authoritative Quest reward grant contract
- `34103e5...` — lock Quest reward trust boundary
- `e779231...` — fix runtime eligibility fixture
- `f0a7bf0...` — bridge Quest grants to server-owned unopened packs
- `6f30bda...` — lock unopened pack entitlement lifecycle
- `154ee6d...` — add end-to-end Reward Loop Lab
- `165696a...` — certify Reward Loop Lab
- `958ffee...` — stabilize issued-pack opening interaction test

Latest certified head:

`958ffeef642e6970ff79678a11efa7d0f281ed6a`

---

# 39. Do-not-regress checklist

Before committing anything major, preserve:

- exact matches = canonical ID equality;
- no fake related-interest exact match;
- no permanent precise-location tracking;
- no venue/brand dependency in Zync Now Phase 1;
- private Zync Now constraints stay private;
- hard vetoes stay hard;
- soft relaxation is explicit;
- local People identity stays out of coarse progress events;
- Quest local completion does not mint inventory;
- client does not choose reward output;
- client does not choose pack RNG/result;
- pack result is committed before animation;
- reveal checkpoint cannot cross serverRollId;
- Encounter remains soulbound by default;
- Like/Love cannot be downgraded by Cardverse Want to Try;
- trading remains direct, no cash/auction;
- Cardverse internal Labs are not public Home features;
- Production closed;
- Play closed;
- PR #1 remains draft/unmerged.

---

# 40. One-sentence continuation state

> Zync’s pair/group utility, standalone group-native Zync Now, real-world Quest progression, 50-card procedural Cardverse proof, Collection/Binder UX, receipt-driven resumable Pack Opening, and an end-to-end **real action → Quest eligibility → server-owned reward grant → unopened pack → server roll → reveal** proof are all implemented and CI-certified; the next major task is replacing the mocked Cardverse server boundary with real durable cloud ownership and a transactional backend without weakening the local-first/privacy model.

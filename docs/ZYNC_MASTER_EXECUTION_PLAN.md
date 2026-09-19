# Zync — Master Execution Plan

Branch: `zync-v1-rebuild-20260917`

This is the implementation roadmap beneath:

- `docs/ZYNC_BUSINESS_PROPOSAL_AND_VISION.md`
- `docs/ZYNC_V1_PRODUCT_SPEC.md`
- `AI_STATE/LATEST_HANDOFF.md`

It separates the **certified current V1** from the larger Zync product vision and defines the order in which the larger system should be designed, built, tested and integrated.

---

## 1. Product objective

Zync should evolve from a two-person interest icebreaker into a **playable real-world interest layer** that helps people:

1. discover what connects them;
2. interact in ways that create real conversation;
3. decide what to do together;
4. discover new interests;
5. collect and own an evolving interest world;
6. create shared memories;
7. later discover communities, places, experiences and commercial partners when trustworthy supply exists.

The central product rule is:

> **Zync must solve real-world social and decision problems before monetisation optimisation.**

The product should not optimise for screen time for its own sake.

---

## 2. Non-negotiable constraints

The implementation roadmap must preserve the following.

### Current certified core remains stable

The existing two-person V1 remains the baseline:

```text
Select interests
→ QR pairing
→ hidden connection reveal
→ AI interaction
→ curiosity / crossover
→ recap
```

Future work must not destabilise that loop.

### Production discipline

- Production remains closed unless explicitly approved.
- Google Play remains closed unless explicitly approved.
- Branch auto-deploy remains disabled unless intentionally changed for a controlled preview.
- Do not produce another user-facing QA APK merely because one sub-feature was added.
- A consolidated QA APK should only be produced at a coherent product milestone.

### Privacy

- Core People / conversation history remains local-first by default.
- Cloud storage is introduced where durable ownership genuinely requires it.
- Exact match semantics remain canonical-ID equality only.
- Related-interest graphs, AI, commercial partners and regional ranking must never create false exact matches.

### Commercial integrity

- No brand can pay to become an organic user interest.
- Sponsored content must be clearly labelled and relevance-gated.
- Zync Now Phase 1 does **not** recommend specific restaurants, venues, shops or brands.

---

# 3. Master architecture

The long-term product should be built around a small number of reusable engines instead of one-off features.

## 3.1 Interest Graph

The semantic foundation for:

- exact interests;
- categories / subcategories;
- related interests;
- crossover relationships;
- activity suitability;
- Want to Try;
- card identity;
- future brands / venues / communities.

## 3.2 Session Engine

A session abstraction capable of supporting:

- 2-person Zync;
- later 3+ person Group Zync;
- synchronized reveal state;
- short-lived session identity;
- privacy-minimised participant payloads;
- resumable interrupted sessions.

## 3.3 Interaction Engine

Structured mechanics such as:

- Guess;
- Pick;
- Rank;
- Defend;
- Recommend;
- Reveal;
- React;
- Build Together;
- Trade-off;
- Challenge;
- Crossover.

AI chooses and fills mechanics; local structured fallback remains available.

## 3.4 Decision Engine

The basis of **Zync Now**.

**Zync Now is group-native by architecture.** The engine must accept `N >= 2` participants from the beginning; a two-person session is simply the smallest group case, not a separate implementation.

It converts:

```text
participants[2..N]
+ interests
+ Want to Try
+ novelty preference
+ simple situational constraints
```

into:

```text
three strong activity ideas
→ private / group consensus
→ chosen action
→ later outcome
```

The same decision engine should serve ordinary two-person Zync, Group Zync, dinners, parties and later event contexts.

## 3.5 Reward / Progress Engine

A single reward layer should power:

- trophies;
- quests;
- packs;
- card rewards;
- encounter rewards;
- Tried Together;
- milestone unlocks.

Avoid building separate unrelated reward systems.

## 3.6 Cloud Ownership Engine

Used only where persistent ownership requires it:

- card collection;
- packs / draw tokens;
- quest progression;
- cosmetics;
- wishlist;
- tradeable inventory;
- cloud restore / multi-device sync.

## 3.7 Growth Engine

Used for:

- Guest Zync;
- install-after-value flow;
- Group invitations;
- save / claim profile;
- invite attribution without turning Zync into spam.

---

# 4. Workstream A — Interest foundation

This is the first critical path because almost every new feature depends on it.

## A1. Finish catalog localisation

The current navigation taxonomy is localised, but thousands of catalog leaves still need explicit Traditional / Simplified Chinese treatment.

Rules:

- Generic hobbies / activities / sports / skills / genres must be localised.
- Proper titles, artists, franchises and brands should use recognised native / official naming rather than mechanical translation.
- English, Traditional Chinese, Simplified Chinese and native aliases remain searchable.
- Canonical IDs do not change.

Add an automated audit that fails if newly introduced generic leaves are missing required localisation.

## A2. Formalise entity types

The graph should distinguish:

```text
Interest Concept
Media / Franchise
Brand Affinity
Venue / Restaurant
Activity / Experience
Place
Community
Intent
```

Only the first two are needed heavily now. The others are schema-ready future types.

## A3. Add activity metadata

For Zync Now Phase 1, curated interests need lightweight metadata such as:

- can_do_together;
- activity_templates;
- indoor / outdoor / either;
- active / relaxed / creative / social;
- rough budget class;
- rough time class;
- solo / pair / group compatibility;
- teachable_by_peer;
- suitable_for_first_try;
- crossover tags.

The metadata describes activity possibilities, not locations.

## A4. Add card metadata

Each official collectible entity needs:

- card number;
- visual family;
- icon key;
- category kit;
- flavour text;
- card eligibility;
- future edition compatibility.

## A5. Build validation tools

Automated checks should cover:

- duplicate canonical IDs;
- missing labels;
- broken parent relationships;
- invalid aliases;
- invalid graph references;
- missing activity metadata for Zync Now candidates;
- missing card metadata for collectible interests.

### Foundation exit gate

Do not scale Zync Now or Cardverse to the full catalog until the graph and audits are stable.

---

# 5. Workstream B — Finish the core social experience

Before adding large new systems, the current two-person interaction should become a strong reusable primitive.

## B1. Onboarding V2 completion

Current quick-start is only the beginning.

The final first-run flow should:

- make 5 interests enough to start;
- show immediate value after 5;
- avoid asking for a giant profile;
- make adding more interests feel optional and useful;
- naturally explain Want to Try;
- prepare the user for their first Zync.

## B2. Interaction Engine V3/V4

The existing structured interaction metadata should become actual interactive mechanics rather than labels above a question.

Examples:

**Guess**
- Person A predicts.
- Person B keeps answer hidden.
- Reveal.
- Reaction / follow-up.

**Pick**
- Both choose privately.
- Reveal together.
- Compare.

**Rank**
- Both rank 3 choices.
- Reveal overlap.

**Defend**
- Choose.
- Defend choice.
- Opponent reacts.

**Build Together**
- Each contributes one element.
- AI combines them.

The engine should:

- avoid mechanic repetition;
- adapt to shared vs one-person vs crossover content;
- use deterministic local fallbacks;
- avoid generic interview-style questions.

## B3. Session quality

Improve:

- hidden connection pacing;
- recap;
- meaningful progress;
- interrupted-session recovery;
- weak-network behaviour.

### Core exit gate

A physical two-person session should feel complete and fun without Cardverse or Group Zync.

---

# 6. Workstream C — Zync Now Phase 1

Zync Now Phase 1 solves:

> **“What should we do together?”**

It deliberately does **not** solve:

> “Which restaurant / venue should we go to?”

## C1. Entry points

Initial entry points must work for both pairs and groups.

### Post-Zync / Post-Group-Zync

After a useful session:

> You found 5 connections.
>
> **Want to do something together?**

### Home

A persistent:

> **Zync Now**

entry for people who already know they want an idea.

### Later notification entry

Only after explicit mutual opt-in such as:

> Keep giving us ideas.

No proactive person-specific suggestions before this consent model exists.

## C2. Modes

Phase 1 should support the same modes for `N >= 2` participants:

- **Both Like It** — based on shared interests.
- **One Knows, One Discovers** — one person teaches / introduces.
- **New to Everyone** — nobody has tried it.
- **Meet in the Middle** — combine different interests.
- **Surprise Us** — constrained intelligent randomness.

## C3. Minimal constraints

Ask only what Zync does not already know:

- available time;
- rough budget;
- active vs relaxed;
- indoor vs outdoor / no preference;
- familiar vs adventurous.

Target: reach useful suggestions within seconds.

## C4. Candidate generation

Use two layers.

### Local deterministic candidate engine

Generate feasible activity templates from graph metadata.

This provides:

- reliability;
- privacy;
- offline fallback;
- explainability.

### AI creative composer

AI may:

- combine interests;
- rewrite activity ideas naturally;
- create crossover challenges;
- create one-knows / one-learns formats;
- produce concise rationale.

AI must not invent unavailable local venues in Phase 1.

## C5. Output

Normally return **three** choices only, whether there are two people or a group:

- **Safe Pick**
- **Discovery Pick**
- **Wildcard**

Each must include a short explanation of why it fits the participants.

## C6. Consensus

Consensus must be group-capable from the first engine design. Support small decision mechanics:

- private vote;
- eliminate one;
- rank 1–3;
- Zync breaks tie;
- constrained re-roll: cheaper / more active / more relaxed / stranger / more familiar.

The target metric is **time to consensus**, not number of recommendations viewed.

## C7. Action memory

After a chosen activity, later ask:

> **Did you actually do it?**

If yes:

- record **Tried Together**;
- feed progress / quests;
- improve future suggestions;
- optionally create an activity memory;
- later connect to Cardverse.

### Zync Now Phase 1 exit gate

A pair **or small group** should be able to go from “we don't know what to do” to one agreed activity quickly without any venue database.

---

# 7. Workstream D — Group Zync

Group Zync should be built on the same Session Engine rather than as a separate app inside Zync.

## D1. Group scope

Initial target:

- 3–8 participants;
- one host;
- join by QR / short link;
- no permanent group chat;
- no community requirement.

## D2. Lobby

Host creates Group Zync.

Participants join and see:

- participant count;
- ready state;
- optional funny aliases;
- clear privacy explanation.

Do not expose full private interest profiles to the room.

## D3. Group discovery mechanics

Examples:

### Hidden Cluster

> Four people here share something. Guess who.

### Only One

> Only one person chose this. Guess who.

### Majority / Minority

> Most of the group picked one side. Reveal.

### Secret Ranking

Everyone privately ranks options; reveal group pattern.

### Who Knows This?

Useful for one-knows / others-discover.

## D4. Group AI interaction

The AI interaction director must support:

- turn order;
- team / room roles;
- hidden choices;
- simultaneous reveal;
- group follow-up.

Avoid interactions where one loud person dominates.

## D5. Group Zync Now

This is a major convergence point.

After group discovery:

> **Want Zync to choose something to do together?**

Use group-wide:

- shared interests;
- minority interests;
- Want to Try;
- novelty preference;
- simple constraints.

Then apply private consensus mechanics.

## D6. Group rewards

Possible later rewards:

- Group Encounter Pack;
- collaborative quest progress;
- group activity memory.

### Group exit gate

A small real-world group should be able to join quickly, discover something surprising, play at least one group mechanic and optionally reach a group activity decision.

---

# 8. Workstream E — Cardverse

Cardverse is the ownership / curiosity / discovery layer.

## E1. Card data model

Separate:

- canonical card definition;
- variant definition;
- edition;
- user inventory;
- unique special instances.

Rarity applies to the **variant**, not the worth of the hobby.

## E2. Visual system

Build:

- category kits;
- visual families;
- reusable motifs;
- icon system;
- card frames;
- card backs;
- rarity overlays;
- edition stamps.

Do not generate 3,000 independent illustrations.

## E3. Procedural generation

Recommended pipeline:

```text
Interest metadata
+ category kit
+ visual family
+ icon / motif
+ localisation
→ pre-render base asset

base asset
+ live shader / overlay
+ animation
→ premium in-app card
```

Generate a controlled sample set first.

### Sample gate

Before full 3,000+ generation:

- generate ~50 representative cards;
- cover multiple categories;
- cover all rarity effects;
- visually audit;
- fix template weaknesses.

Then scale.

## E4. Rarity / variants

Initial family:

- Normal;
- Foil;
- Holo;
- Prism;
- Legendary;
- Secret;
- Encounter Edition.

## E5. Pack opening

Build reveal effects in tiers:

- common;
- rare;
- legendary / secret.

Use:

- anticipation;
- motion;
- shimmer;
- sound;
- haptics;
- reveal timing.

Do not use deceptive fake near-miss behaviour.

## E6. Collection

Collection surfaces:

- My Collection;
- Category binders;
- Missing silhouettes;
- New Discoveries;
- Want to Try;
- Encounter Collection;
- Showcase.

## E7. Discovery hook

Every unfamiliar hobby card should be able to answer:

> What is this?

and offer:

> **Want to Try**

This is how Cardverse feeds the core interest graph.

### Cardverse exit gate

Users should feel ownership and curiosity even before trading exists.

---

# 9. Workstream F — Account and cloud ownership

Cardverse requires durable cloud ownership.

## F1. Identity

Support:

- Google;
- Apple.

Avoid creating a separate password system unless later necessary.

## F2. Login timing

Do not force account creation before the user understands Zync.

A suitable moment:

> **Your collection is about to begin.**
>
> Keep every card when you change phones.

## F3. Cloud-backed data

Cloud:

- cards;
- unique card instances;
- packs;
- draw tokens;
- quest progress;
- cosmetics;
- wishlist;
- trading state.

Local-first by default:

- detailed People history;
- conversation history;
- received social links;
- raw pairing data.

## F4. Restore / merge

Support:

- reinstall restore;
- new-device restore;
- local pre-account progress merge;
- conflict-safe multi-device sync.

## F5. Server-authoritative draws

A pack opening transaction should atomically:

1. verify pack ownership;
2. consume the pack;
3. determine results;
4. write inventory;
5. return reveal plan.

If the animation is interrupted, the user must still own the cards and be able to resume reveal.

---

# 10. Workstream G — Unified quests, trophies and My Zync World

Do not leave Trophy Case as a separate island.

## G1. My Zync World

Bring together:

- Interest DNA;
- cards;
- collections;
- trophies;
- Want to Try;
- Tried Together;
- Encounter memories;
- trades;
- favourite / showcase cards.

## G2. Quest families

Initial:

- Daily Curiosity;
- Weekly Journey;
- Discovery;
- Social;
- later Group / Activity quests.

Examples should reward meaningful actions:

- reveal a hidden connection;
- complete a Zync;
- try a different interaction mechanic;
- add a card to Want to Try;
- complete a Zync Now decision;
- confirm a Tried Together activity.

Avoid meaningless “tap five times” tasks.

## G3. Rewards

Keep the economy small:

- packs / draw tokens;
- cosmetics;
- special card backs;
- opening effects;
- Encounter rewards.

Avoid many currencies.

---

# 11. Workstream H — Guest Zync growth

Guest Zync reduces the largest acquisition friction: requiring both people to install before the first useful moment.

## H1. Flow

```text
Existing user shows QR
→ guest scans with normal camera
→ web flow
→ guest picks 5 interests
→ first Zync happens
→ guest receives value
→ install / claim profile
```

## H2. Claim / migration

If the guest installs:

- preserve selected interests;
- preserve earned starter / Encounter reward;
- optionally link to Google / Apple if collection ownership is created.

## H3. Measurement

Track privacy-safe funnel:

- guest opened;
- completed five interests;
- completed Zync;
- claimed / installed;
- later created another Zync.

Do not turn this into spam referral mechanics.

---

# 12. Workstream I — Trading

Trading launches only after cloud inventory is trustworthy.

## I1. Trading-ready model from day one

Inventory should already support:

- tradable flag;
- locked quantity;
- unique instances;
- provenance;
- wishlist.

## I2. First trading product

Start with:

> **Direct card-for-card trading**

No cash.

No auction.

No marketplace.

## I3. Flow

```text
pair / handshake
→ choose cards
→ preview both sides
→ both confirm
→ server atomic swap
→ Trade Complete
```

## I4. Wishlist matching

After Zync:

> **You each have cards the other wants.**

This makes collection directly social.

## I5. Soulbound cards

Examples:

- Encounter Edition;
- certain milestones;
- personal-memory cards.

These remain non-tradable.

---

# 13. Workstream J — Notifications and re-engagement

Notifications must be useful, contextual and consented.

## Initial notifications

Acceptable examples:

- unopened earned pack;
- quest completed;
- account restore / security;
- agreed activity follow-up.

## Person-specific Zync Now notifications

Only after mutual opt-in such as:

> **Keep giving us ideas together**

Then examples may include:

> You both saved Pottery to Want to Try. Want three ideas this weekend?

Avoid:

- random person suggestions after one old scan;
- guilt streaks;
- fake urgency;
- manipulative scarcity.

---

# 14. Workstream K — Later communities, places, brands and monetisation

Do not build these into Phase 1 Zync Now.

Only begin once core utility has evidence.

## Communities

Possible later:

- hobby groups;
- geography hierarchy;
- activity intent;
- organiser tools.

## Places / venues / restaurants

Require trustworthy:

- place data;
- location consent;
- opening / availability data where relevant;
- ranking rules.

## Brands

Possible surfaces:

- genuine Brand Affinity entities;
- official cards;
- collaboration editions;
- sponsored quests;
- event packs;
- later relevant promoted suggestions.

Critical rule:

> **Commercial payment may buy exposure, never a fake personal match.**

## Monetisation

Do not choose a single model prematurely.

Potential future revenue:

- event / host tools;
- organiser products;
- premium cosmetics;
- activity / booking commissions;
- venue / restaurant lead generation;
- brand integrations;
- later community tools.

Paid random draws are not required and should not be assumed.

---

# 15. Metrics architecture

The product must measure whether it solves real problems.

## Primary North Star

**Meaningful Zyncs**

A candidate definition:

- pairing completed;
- at least one meaningful connection revealed;
- at least one interaction / discovery action completed.

## Zync Now metrics

- Zync Now start rate;
- suggestion generation success;
- time to consensus;
- percentage selecting an activity;
- percentage later confirming “Did it”;
- repeat use of Zync Now.

## Group metrics

- group join completion;
- time from host start to all ready;
- group interaction completion;
- group Zync Now consensus rate.

## Cardverse metrics

- first pack open;
- collection continuation;
- new-interest discovery;
- Want-to-Try from card;
- percentage of packs earned through meaningful real actions.

## Growth metrics

- guest-to-first-Zync;
- guest-to-install / claim;
- user-to-next-user propagation.

Screen time is not the North Star.

---

# 16. Recommended implementation order

This is the critical-path order.

## Milestone 0 — Architecture lock

Deliver:

- this Master Execution Plan;
- Interest Graph spec;
- Zync Now Decision Engine spec;
- Group Zync protocol spec;
- Cardverse / cloud ownership spec.

No user-facing APK milestone yet.

## Milestone 1 — Foundation quality

Build:

- remaining interest localisation;
- Interest Graph/entity schema;
- activity metadata;
- card metadata;
- graph validation;
- full interaction-engine mechanics;
- reliable session recovery.

**Exit:** current two-person product is stronger and new systems have stable primitives.

## Milestone 2 — Zync Now Decision Engine MVP

Build:

- group-native `N >= 2` decision model;
- Post-Zync entry;
- Home entry;
- five activity modes;
- simple constraints;
- local candidate engine;
- AI creative composer;
- 3-choice output;
- private / group consensus;
- Tried Together memory.

The first UI may be validated with two people, but the engine and state model must already support multiple participants.

**Exit:** the same engine can reliably answer “what should we do?” for a pair and is ready to be surfaced inside Group Zync without a rewrite.

This is the first major new utility milestone worth a consolidated physical QA build.

## Milestone 3 — Group Zync MVP

Build:

- group lobby;
- 3–8 participant session protocol;
- hidden cluster / only-one / ranking mechanics;
- group interaction director;
- surface the **existing group-native Zync Now engine** inside Group Zync;
- group-private consensus UI.

**Exit:** a real dinner / party / orientation group can use Zync end-to-end.

## Milestone 4 — Cardverse Alpha

Build:

- card schema;
- 50-card visual sample;
- procedural renderer;
- rarity shaders;
- pack opening;
- collection;
- Want-to-Try from card.

In parallel, finalise cloud ownership architecture.

**Exit:** Cardverse feels premium and scalable before generating thousands of assets.

## Milestone 5 — Durable collection + quests

Build:

- Google / Apple account;
- cloud inventory;
- server-authoritative pack engine;
- restore / merge;
- unified quests;
- My Zync World;
- Encounter rewards.

Then scale card generation beyond the sample set.

**Exit:** users can safely own a collection across devices.

## Milestone 6 — Guest Zync growth

Build:

- web guest quick-start;
- five-interest guest profile;
- first Zync before install;
- claim / install migration;
- growth funnel measurement.

**Exit:** an existing user can deliver Zync value to a non-user with minimal friction.

## Milestone 7 — Direct Trading

Build:

- wishlist;
- tradable / locked inventory;
- pair-to-trade;
- atomic swap;
- provenance;
- soulbound enforcement.

**Exit:** trading improves social interaction without creating a cash economy.

## Milestone 8 — Integrated Beta

Integrate:

- two-person Zync;
- Zync Now;
- Group Zync;
- Cardverse;
- quests;
- cloud restore;
- Guest Zync;
- trading.

Run full real-world pilot scenarios:

- two friends;
- strangers at event;
- dinner group;
- school / orientation;
- repeated users;
- weak network;
- phone replacement / account restore.

Only after this milestone should broader production / Play promotion be considered.

## Milestone 9 — Ecosystem expansion

Only after evidence:

- communities;
- location-aware places;
- restaurant / venue data;
- booking supply;
- brand partnerships;
- sponsored but relevance-gated surfaces;
- organiser products;
- monetisation experiments.

---

# 17. Parallelisation strategy

Not everything has to wait serially.

After Milestone 1, three tracks can proceed in parallel.

### Utility track

```text
Zync Now
→ Group Zync
→ Group Zync Now
```

### Engagement track

```text
Card visual system
→ Cardverse
→ Cloud collection
→ Quests
→ Trading
```

### Growth track

```text
Guest architecture
→ web guest flow
→ claim / install
→ event / group acquisition
```

The Interest Graph, Session Engine and privacy rules are shared dependencies.

---

# 18. Spec documents to create before implementation

The next design documents should be created in this order:

1. `docs/ZYNC_INTEREST_GRAPH_AND_ENTITY_MODEL.md`
2. `docs/ZYNC_NOW_DECISION_ENGINE_SPEC.md`
3. `docs/ZYNC_GROUP_ZYNC_SPEC.md`
4. `docs/ZYNC_CARDVERSE_SYSTEM_SPEC.md`
5. `docs/ZYNC_CLOUD_OWNERSHIP_AND_TRADING_SPEC.md`
6. `docs/ZYNC_GUEST_ZYNC_GROWTH_SPEC.md`
7. `docs/ZYNC_METRICS_PRIVACY_AND_RELIABILITY_SPEC.md`

Each spec must define:

- user problem;
- desired actions;
- data needed;
- privacy boundary;
- state model;
- UI flow;
- failure / recovery flow;
- analytics;
- tests;
- explicit out-of-scope items.

---

# 19. Immediate next batch

The next engineering/design batch should **not** jump directly into cards, groups or another APK.

Do these first:

### Step 1 — Interest Graph + entity model

Lock:

- canonical entity classes;
- relationship types;
- activity metadata;
- card metadata;
- localisation rules.

### Step 2 — Full localisation audit

Finish the generic 3,000+ catalog labels needed for:

- onboarding;
- card names;
- Zync Now activity explanation.

### Step 3 — Zync Now spec

Define:

```text
Who
→ Intent
→ Novelty mode
→ Constraints
→ candidate generation
→ Safe / Discovery / Wildcard
→ consensus
→ chosen activity
→ Did it?
→ Tried Together
```

### Step 4 — Group session protocol spec

Design the 2→N participant transition before UI coding so Group Zync does not become a separate fragile architecture.

### Step 5 — Card visual/generation proof in parallel

Use the approved visual direction to build a **small systematic prototype**, not 3,000 one-off graphics.

---

# 20. Product decision gate

Before any major feature is implemented, answer:

1. What real user problem does it solve?
2. Which Desired Action should it increase?
3. Which existing Zync loop does it strengthen?
4. What data does it require?
5. Can it preserve the privacy boundary?
6. What is the smallest version that proves value?
7. What metric would tell us it worked?
8. What is explicitly out of scope?
9. Does it still work if AI / network partially fails?
10. Does it make Zync more useful in real life, or merely more busy on screen?

If those answers are weak, the feature should not move to implementation.

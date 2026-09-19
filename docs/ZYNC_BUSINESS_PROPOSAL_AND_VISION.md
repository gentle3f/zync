# Zync — Business Proposal & Product Vision

> Canonical business, product and long-term strategic context for Zync.
>
> This document explains **why Zync exists, what problem it is solving, what the current V1 is meant to prove, how the experience should evolve, how gamification and Cardverse fit the core product, how real-world decision support can become a major utility, and how future brands / venues / commerce can participate without corrupting user trust**.
>
> Future work should read this together with `docs/ZYNC_V1_PRODUCT_SPEC.md` and the current `AI_STATE/LATEST_HANDOFF.md`. The V1 Product Spec describes the currently shipped / certified core. This document is broader and may describe future product layers that are intentionally not yet in V1.

---

## 1. Executive summary

**Zync helps people discover the connections they did not know existed, turns those discoveries into real conversations, and can grow into a playable interest layer that helps people decide what to do together in real life.**

The original core experience is deliberately simple:

1. each person builds a lightweight interest profile;
2. one person shows a QR code and the other scans it;
3. Zync compares their interests;
4. exact shared interests are revealed progressively rather than dumped as a list;
5. AI turns each useful discovery into a real two-person interaction;
6. differences and crossovers keep the conversation alive after exact matches are exhausted;
7. a successful session produces memory, progress and future discovery rather than ending as a disposable report.

The signature emotional moment remains:

> **“Wait — you like that too?”**

But the expanded product vision is now larger:

> **Zync should help people discover each other, discover themselves, and turn interests into things they can actually do together.**

That includes solving ordinary real-life friction such as:

- What should we eat?
- What should we do tonight?
- Where should we go this weekend?
- What can four people with different interests all enjoy?
- What hobby should I try next?
- What could we do together that neither of us would have thought of?

The product should therefore evolve around one connected system:

```text
Interest Graph
      ↓
Real-world Zync
      ↓
AI Interaction / Decision Engine
      ↓
Cardverse + Collection + Quests + Trading
      ↓
Group Zync + Events + Guest Zync
      ↓
Places + Activities + Brands + Communities
      ↓
Hobbies Economy
```

The current V1 remains a low-cost, multilingual, privacy-first test of the two-person magic moment. The larger system should only be layered on in a way that strengthens that core rather than burying it.

---

## 2. The original insight

Modern social products are very good at helping people **communicate after a connection already exists**. They are much weaker at helping people discover **what they should talk about in the first place**.

People often have far more in common than they realise.

Friends can know each other for years without discovering a shared niche fandom. Colleagues may never find out that both are into Formula 1. Two students at orientation may both love railway photography but spend the first ten minutes asking generic questions about school or work. Two people from different countries may have exactly the same hobby but use completely different words for it.

The information exists, but it is hidden.

Zync began from a simple question:

> **What if two people could instantly discover the interests between them that ordinary conversation has not yet surfaced?**

That leads to a second question:

> **Once the connection is found, can AI turn it into a better conversation instead of just displaying a match?**

And now a third:

> **Once Zync understands the interests of the people together, can it help them turn those interests into a real decision or shared experience?**

That combination — **interest discovery + conversational activation + real-world action** — is the expanded core of Zync.

---

## 3. The larger real-world problem

### 3.1 Social identity is fragmented

A person’s interests are scattered across what they watch, play, read, collect, learn, visit, follow and spend time on. No single lightweight identity layer represents this well in a way that can be used in real-world social interaction.

Existing products tend to organise people around one context:

- LinkedIn: professional identity;
- Instagram / TikTok: content and self-presentation;
- Facebook Groups / Reddit / Discord: communities around topics;
- Meetup: activities / events;
- dating apps: romantic matching;
- messaging apps: communication after people already know whom they want to talk to.

Zync starts from a different primitive:

> **“What are you into, and what does that reveal when you meet another person?”**

### 3.2 Common ground is difficult to surface

Most people do not naturally run through their entire hobby list when meeting someone. Broad interests such as “travel” may come up, but specific overlaps such as JoJo, sim racing, model railways, badminton, F1, street photography or a particular game often remain undiscovered.

The narrower the interest, the more emotionally meaningful the discovery can become.

### 3.3 Icebreakers are often generic

Many networking and social tools ask generic questions that could be shown to anyone. They do not know the participants.

Zync’s goal is different: the interaction should come **after** the product knows enough about both people to make it relevant.

### 3.4 Language creates unnecessary separation

Two people can share the same interest but describe it in different languages. “Badminton,” “羽毛球,” “バドミントン” and “배드민턴” should not become four separate identities.

Zync therefore treats the underlying concept as language-neutral and only localises its display.

### 3.5 People constantly suffer from shared decision paralysis

A second major real-world problem is not discovering what people like, but **deciding what to do with that information**.

Groups repeatedly ask:

- “食咩好？” / “What should we eat?”
- “去邊好？” / “Where should we go?”
- “有咩做？” / “What should we do?”
- “Weekend 做咩？”
- “四個人興趣完全唔同，點揀一樣大家都接受？”

This is often inefficient because:

- one loud person dominates the decision;
- people do not want to reject each other’s ideas;
- nobody remembers everyone’s preferences;
- people repeat the same familiar choices;
- useful local activities / venues are difficult to discover;
- the group knows what it does **not** want, but cannot generate good alternatives.

Zync can use its interest graph, shared profile context and AI interaction layer to solve this problem directly.

---

## 4. Current Zync V1

A concise definition:

> **Zync V1 = multilingual interest identity + QR ritual + hidden connection discovery + AI-activated conversation.**

The current product is deliberately local-first.

### Core V1 experience

- Build a lightweight interest profile from a deep multilingual catalog.
- Search/select interests and add free-text interests instantly on-device.
- Mark an interest as **Love**, **Like**, or **Want to try**.
- Show or scan a Zync QR.
- Complete a one-scan encrypted pairing so both phones enter the same Zync Session.
- Compare canonical interest IDs locally on-device.
- Collapse broad taxonomy ancestors into stronger connection threads rather than revealing a hierarchy as a checklist.
- Create the **YOU ZYNC!** impact moment, then reveal one meaningful connection at a time.
- Put the AI interaction inside that reveal moment rather than forcing users into a separate report-then-chat flow.
- If there is no exact match, use the local Interest Graph to choose a plausible crossover and let AI turn it into a question.
- Continue after exact matches through **Ask about them**, **Let them ask you**, crossovers and Surprise moments.
- Keep local People / Zync Again history.
- Use stable ridiculous aliases for anonymous peers instead of sterile raw IDs.
- Allow explicitly consented public social-profile exchange after a successful Zync.
- Show Interest DNA as a descriptive interest identity.
- Support bilingual peers with equivalent semantic interactions.

### What makes the interaction distinctive

Zync should not behave like a spreadsheet saying:

> Shared interests: F1, JoJo, Japan.

It should create suspense and discovery:

> **YOU ZYNC!**
> You found hidden connections.

Then reveal something specific enough to cause a reaction:

> **JoJo's Bizarre Adventure**

The second half of the icebreaker is **curiosity**, not just similarity.

A useful Zync can be:

> “Wait — you like that too?”

but also:

> “I never knew you were into that — tell me about it.”

The session should create multiple conversational doors and let the people decide when they are done.

---

## 5. Product constitution

Future product decisions should be tested against the following principles.

1. **Real people first.** Real-world connection matters more than screen time.
2. **Surprise with meaning.** Surprise should lead to discovery, memory or action — not empty stimulation.
3. **Every reward should reinforce a Desired Action.** Rewards should not exist merely to manufacture tapping.
4. **Ownership must be durable.** Anything users emotionally own — especially cards — must survive reinstall and device change.
5. **Social before competitive.** Collaboration, discovery, trading and group play are usually more aligned with Zync than public status races.
6. **Black-Hat mechanics are seasoning, not the meal.** Scarcity and unpredictability may create excitement, but guilt, punishment and artificial pressure should not become the retention strategy.
7. **Privacy by architecture.** Do not collect more relationship data merely because cloud infrastructure exists.
8. **Side loops must feed the core loop.** Cards, quests, achievements and trading should create more discovery, more real interaction or more useful action.
9. **Small first action, deep later journey.** First use should be extremely easy; sophistication unlocks progressively.
10. **Do not ship a mechanic without knowing what behaviour it is meant to improve.**
11. **Commercial participation must not manufacture personal truth.** A brand cannot pay to become somebody’s “interest” or create a false match.
12. **Professional graphics, motion, sound and haptics are product functionality when emotion matters.** Pack opening and reveal moments must be designed, not merely labelled.

---

## 6. The four connected Zync loops

Zync should be designed as several loops that feed one another rather than one long feature list.

### 6.1 The 30-second Magic Loop

```text
Scan
→ Mystery
→ Reveal
→ Human reaction
```

This is the fastest proof of value.

A first-time user should not need to understand communities, cards, quests or a large profile before this works.

### 6.2 The Zync Session Loop

```text
Reveal
→ Guess / Pick / Rank / Defend / Recommend / Build
→ React
→ next connection
→ crossover
→ surprise
→ recap
```

AI is not merely a question generator. It is a **conversation director / lightweight game master**.

### 6.3 The Daily / Weekly Meta Loop

A user can continue to get value even while alone:

```text
Quests
→ packs
→ card reveals
→ collection
→ Want to Try
→ wishlist / trading
→ Interest DNA growth
```

This creates a reason to reopen Zync without replacing its social purpose.

### 6.4 The Months / Years Identity Loop

Over time Zync should become a personal **My Zync World**:

- interests explored;
- people discovered;
- cards collected;
- Encounter cards;
- things the user wants to try;
- categories explored;
- achievements;
- trades;
- memorable discoveries;
- future real-world activities completed.

The user should eventually feel:

> **“This is my world of interests and experiences.”**

---

## 7. AI should evolve from question generator to interaction director

The long-term AI layer should generate structured interactions, not merely one sentence.

Example:

```text
Interaction: GUESS

Setup:
One person secretly chooses a favourite option.

Person A:
Predict first.

Person B:
Do not reveal yet.

Reveal:
Show the answer.

Follow-up:
If the guess was wrong, explain why the guess still made sense.
```

Useful mechanics include:

- Guess;
- Pick;
- Rank;
- Compare;
- Defend;
- Recommend;
- Reveal;
- Build together;
- Trade-off;
- Memory;
- Challenge;
- Crossover.

The system should avoid repeating the same interaction style throughout one session.

It may use:

- shared / non-shared interests;
- interest category;
- session stage;
- previously shown interactions;
- Want-to-Try signals;
- Cardverse collection context where appropriate.

It should not make creepy psychological claims or infer intimate traits that the user did not provide.

---

## 8. Zync Now — solving “What should we do together?”

A major future product mode should turn Zync’s interest graph into **shared activity decision support**.

### Phase boundary

**Zync Now Phase 1 should suggest what people can do together, not where to go.**

Phase 1 does not assume a venue database, live local-business data, restaurant inventory, booking supply or brand integrations. It should therefore generate **activity ideas**, not specific restaurants, shops, venues or destinations.

Location-, venue-, restaurant- and brand-aware recommendations belong to later phases only when Zync has trustworthy supply data and/or partner integrations.

Working name:

> **Zync Now**

Zync Now should help one person, a pair or a group turn vague intent into a few concrete possibilities.

### 8.1 Phase 1 activity modes

Zync Now Phase 1 should help a pair or group choose **what kind of thing to do together**.

Useful modes include:

- **Something we both already like** — choose from shared interests.
- **One knows, one discovers** — one person already likes or knows the activity while the other does not.
- **New to everyone** — choose something nobody in the group has tried or selected before.
- **Meet in the middle** — combine different interests into one shared activity.
- **Surprise us** — Zync chooses from a feasible set after simple constraints are applied.

### 8.2 Minimal situational constraints

Zync already knows interests. It should only ask for the missing context needed to make a useful suggestion.

Examples:

- time available;
- rough budget level;
- active vs relaxed;
- indoor vs outdoor;
- how adventurous / unfamiliar the suggestion should be.

The flow should stay lightweight and normally reach useful suggestions within seconds rather than becoming another profile form.

### 8.3 Activity generation

The output should describe **what to do**, not a specific place.

Examples:

- play badminton together;
- try making sushi together;
- watch a classic film neither person has seen;
- do a street-photography challenge;
- one person teaches the other a hobby they already know;
- each person chooses one interest and Zync combines them into a two-hour challenge;
- try a hobby both people have marked Want to Try.

The engine may use:

- exact shared interests;
- one-person interests;
- Want-to-Try;
- category relationships;
- crossover relationships;
- prior activities already tried together.

### 8.4 Creativity as the differentiator

Zync should not only choose existing shared interests. It can combine them into experiences nobody explicitly asked for.

Example:

Person A:
- Cinema
- Coffee

Person B:
- Cycling
- Photography

Zync may suggest:

> Create a photo challenge during a bike ride, then end by watching a film together.

This is one of the most promising long-term mechanics because it turns interests into **co-created experiences**, not just recommendations.

### 8.5 Intelligent randomness

A random-generation mode can add curiosity, but it should be constrained randomness rather than arbitrary roulette.

The user can choose:

- something familiar;
- one knows / one does not;
- new to everyone;
- crossover;
- surprise us.

Zync first filters to plausible activities, then randomises among good candidates.

### 8.6 Consensus, not endless choice

Zync should not output a large catalogue.

A useful first-phase pattern is usually three strong choices:

- **Safe Pick** — based on things the group already likes;
- **Discovery Pick** — based on one person’s knowledge or Want-to-Try;
- **Wildcard** — something new or a crossover.

The group can then:

- privately vote;
- eliminate one option each;
- rank the three;
- ask Zync to decide a tie.

The objective is to reduce **time to consensus**, not increase browsing.

### 8.7 Action and memory

After a suggestion is chosen, Zync may later ask a very small outcome question:

> **Did you actually do it?**

If yes, the activity can become a meaningful memory such as **Tried Together**, contribute to quests / achievements, and improve future suggestions.

This creates the loop:

```text
Interest
→ Zync Now suggestion
→ real activity
→ memory / progress
→ richer future Zync
```

### 8.8 Later phases: places, restaurants and brands

Specific venue, restaurant, destination and brand recommendations are intentionally **not Phase 1 Zync Now**.

They may be added later when Zync has:

- trustworthy place / venue data;
- live availability or opening information where needed;
- commercial or booking integrations;
- appropriate location permissions;
- clear organic-vs-sponsored ranking rules.

The later commercial opportunity remains substantial, but Phase 1 should first prove that Zync can answer the simpler and more important question:

> **“What should we do together?”**

## 9. Interest Graph becomes the strategic asset

The current 3,000+ catalog should not be treated as a JSON list.

It should evolve into a structured **Zync Interest Graph**.

Each canonical concept may have:

- canonical ID;
- category;
- subcategory;
- multilingual labels;
- search aliases;
- related interests;
- crossover relationships;
- visual family;
- card identity;
- interaction-mechanic compatibility;
- Want-to-Try relationships;
- geographic / regional relevance;
- activity / experience links;
- future venue / brand relationships.

Example:

```text
Badminton
→ Racket Sports
→ Sports
→ related: Tennis / Pickleball / Squash
→ activity: casual court / coaching / league
→ crossover: Fitness / Travel / Sports Photography
```

This graph can power:

- exact matching;
- search;
- AI interactions;
- cards;
- quests;
- Zync Now;
- future communities;
- venue discovery;
- commerce.

This becomes a deeper product asset than the UI alone.

---

## 10. Entity model: hobbies, brands, venues and experiences must remain semantically distinct

The long-term graph should support multiple entity classes.

```text
Interest Concept
Brand Affinity
Media / Franchise
Venue
Restaurant
Activity / Experience
Place
Community
Intent
```

Examples:

- **Coffee** → Interest Concept
- **Starbucks** → Brand Affinity
- **Japanese cuisine** → Interest Concept
- **Din Tai Fung** → Restaurant / Venue Affinity
- **JoJo's Bizarre Adventure** → Media / Franchise
- **Indoor climbing class** → Activity / Experience

A user may genuinely care about a brand or restaurant, so these entities can still be:

- selected;
- collected;
- favourited;
- placed in showcases;
- matched exactly if both users genuinely selected the same canonical entity;
- included in Zync Now;
- represented by cards.

But the type must remain explicit.

### Critical commercial rule

> **A company cannot pay Zync to become an organic user interest or manufacture a shared match.**

Sponsored exposure may exist, but it must be clearly labelled and relevance-gated.

This preserves trust while leaving a large commercial surface.

---

## 11. Brand and restaurant integration

The real-world decision layer creates a natural place for brands, restaurants, venues and experience providers.

### 11.1 Why commercial partners may want to participate

They may want to:

- appear when people are genuinely deciding what to do;
- have an official brand / venue card;
- sponsor a themed quest;
- sponsor a limited card edition;
- provide an experience reward;
- host Zync events;
- offer a booking or reservation path;
- reach people who have explicitly shown relevant interest.

This is much more valuable than generic display advertising because it occurs close to **real intent**.

### 11.2 Example: restaurant integration

A group uses **Zync Now: Eat**.

Zync determines:

- Japanese food has broad acceptance;
- one person wants to try yakitori;
- casual atmosphere was selected;
- the group has 90 minutes.

Organic restaurant candidates can be shown.

A sponsored restaurant may also appear **only if it meets the same relevance constraints**, and must be labelled clearly:

> Sponsored · matches your selected preferences

The sponsor must not displace every better organic answer merely because it paid.

### 11.3 Brand cards

A brand may have an official collectible card family, for example:

- standard brand card;
- event edition;
- collaboration edition;
- venue encounter card.

But branded cards should not dominate the hobby universe.

Brand-funded visual content can subsidise the ecosystem while users still understand what is organic and what is sponsored.

### 11.4 Sponsored quests

Examples:

> Try a new coffee style this week.

or:

> Complete a group Zync at a participating event.

Rewards may include:

- cosmetic card variants;
- event packs;
- non-cash experience rewards;
- partner benefits.

Sponsored quests must be optional and clearly labelled.

### 11.5 Commercial integrity

Zync should prefer:

- relevance;
- utility;
- clear sponsorship labels;
- measurable real-world value.

It should avoid:

- hidden sponsored ranking;
- selling raw private interest profiles;
- fake shared interests;
- forced brand selection;
- pretending advertising is an organic recommendation.

---

## 12. Cardverse — turning 3,000+ interests into a collectible world

Cardverse is not merely a trophy system. It is a second loop that turns the existing interest universe into something emotionally ownable.

Every curated canonical interest can have a card identity.

Examples:

- Badminton;
- Bouldering;
- Sushi;
- Cinema;
- Piano;
- Astronomy;
- Pottery;
- Formula 1;
- railway photography.

### 12.1 Core card principles

- every interest can become a beautiful card;
- rarity belongs to the **variant**, not to the social status of the hobby;
- no hobby is inherently “low-class” because it is Common;
- graphics must be modular and scalable to 3,000+ cards;
- professional card art, animation, sound and haptics are essential to the reward moment.

### 12.2 Suggested variants

- Normal;
- Foil;
- Holo;
- Prism;
- Legendary;
- Secret;
- Encounter Edition;
- Discovery Edition;
- Event / Collaboration Edition.

### 12.3 Opening experience matters

The feeling of rarity should begin **before the card name appears**.

A rare opening may use:

- unusual pack movement;
- subtle pre-reveal clues;
- light leakage;
- silence / audio change;
- haptic timing;
- silhouette;
- delayed reveal;
- foil / rainbow shimmer;
- upgrade escalation.

The system should create anticipation without using deceptive fake near-miss mechanics.

### 12.4 The collection should drive discovery

A card detail can offer:

> **Want to Try**

This connects gacha discovery back to the Interest DNA.

A player may draw a hobby they have never heard of, become curious because the card is beautiful, learn what it is, and add it to Want to Try.

The loop becomes:

```text
Collect
→ curiosity
→ learn
→ Want to Try
→ real-world action
→ future Zync
```

---

## 13. Card generation must be systematic, not 3,000 manual illustrations

The scalable approach is a procedural / hybrid visual system.

### 13.1 Card generation layers

Each card can be assembled from:

1. frame;
2. category visual kit;
3. subcategory motif;
4. icon / emblem;
5. typography;
6. interest label;
7. rarity overlay;
8. edition badge;
9. texture / particles.

### 13.2 Asset strategy

A manageable foundation may consist of:

- 12–16 category kits;
- 50–100 visual families;
- reusable geometric / thematic motifs;
- a curated icon library;
- rarity overlays;
- edition stamps;
- card backs;
- dynamic foil / holo shaders.

This can support thousands of cards without commissioning thousands of independent illustrations.

### 13.3 Rendering strategy

A strong implementation direction is:

> **pre-render base card assets + render dynamic shiny / reveal effects in the Flutter client**

This reduces runtime cost while preserving motion and premium effects.

---

## 14. Quest system

Tasks should not become meaningless chores.

A quest should encourage one of Zync’s real Desired Actions:

- discover a person;
- reveal a connection;
- explore a category;
- try a new interaction mechanic;
- add a Want-to-Try interest;
- collect;
- trade;
- do something in real life.

### Quest families

**Daily Curiosity**
- reveal one connection;
- open one pack;
- discover one new card.

**Weekly Journey**
- Zync with several different people;
- collect several new cards;
- complete multiple interaction types.

**Discovery Goals**
- collect a new category;
- add something to Want to Try;
- complete a category row.

**Social Moments**
- earn an Encounter Pack;
- trade with another person;
- finish a Group Zync.

Rewards may include:

- draw tokens;
- packs;
- category packs;
- cosmetics;
- card backs;
- opening effects;
- rare-variant boosts;
- Encounter packs.

The economy should initially stay simple. Avoid a maze of currencies.

---

## 15. Cloud account becomes necessary for durable collection ownership

The core social Zync experience can remain local-first.

But once users own cards, rare variants, quest progress, packs and tradeable items, **local-only storage is not acceptable**.

Users will reasonably expect their collection to survive:

- reinstall;
- phone loss;
- device replacement;
- multi-device use.

### Account approach

Zync should support a simple account identity such as:

- Sign in with Google;
- Sign in with Apple.

The account should protect the collectible layer without automatically uploading all local social history.

### Cloud-backed data

Examples:

- Card collection;
- card variants / quantities;
- unique card instances;
- unopened packs;
- draw tokens;
- quest progress;
- collection milestones;
- cosmetics;
- card wishlist;
- Want-to-Try card references where appropriate.

### Data that can remain local-first by default

Examples:

- names / aliases of people met;
- detailed People history;
- conversation questions shown;
- received social links;
- raw QR payloads;
- exact person-to-person meeting history.

This separation allows:

> **Cloud durability for possessions without turning Zync into a surveillance graph.**

### Login timing

The first screen should not necessarily be a login wall.

A stronger moment is when the user first earns a persistent collection:

> **Your collection is about to begin.**
> Keep every card, even when you change phones.
>
> Continue with Google / Apple

The value of the account is explained before the user is asked to create it.

---

## 16. Trading-ready architecture

Trading does not need to launch with Cardverse V1, but the inventory model should support it from the beginning.

### 16.1 Why trading fits Zync

Trading turns duplicates from disappointment into social value.

It also creates a natural real-world interaction:

> “I have one you want, and you have one I need.”

That is itself an icebreaker.

### 16.2 Direct trade before marketplace

The first trading model should be:

> **person-to-person card trade**

not:

- cash marketplace;
- auction house;
- speculative exchange.

A direct flow may be:

```text
Zync / QR handshake
→ both choose cards
→ preview
→ both hold to confirm
→ server performs atomic swap
→ Trade Complete animation
```

### 16.3 Wishlist matching

When two people Zync:

> **You each have cards the other wants.**

This can become another useful discovery inside the session.

### 16.4 Soulbound / non-tradable cards

Some cards should represent personal history and should not be transferable.

Examples:

- Encounter Edition;
- certain achievement rewards;
- personal milestone cards.

These preserve the distinction between **collection value** and **memory value**.

### 16.5 Server authority

Pack draws and trades should be server-authoritative.

A trade transaction must:

1. lock the offered cards;
2. verify ownership;
3. verify tradability;
4. transfer both sides atomically;
5. write a ledger;
6. roll back completely if any step fails.

---

## 17. My Zync World

Trophies should not live as an isolated badge page.

They should become part of a larger ownership surface:

> **My Zync World**

Potential sections:

- Interest DNA;
- Cards;
- Collections;
- Trophies;
- People discovered;
- Want to Try;
- Encounter memories;
- trades;
- categories explored;
- favourite cards / Showcase.

### Showcase

A user might choose six cards that represent them.

This can communicate more personality than a generic bio without making psychological claims.

A Showcase may include:

- Chess;
- Jazz;
- Aviation;
- Sushi;
- Astronomy;
- Retro Gaming.

The user owns the presentation.

---

## 18. Creativity should become a major long-term core drive

Zync should not only recognise existing preferences.

It can help people **create combinations**.

Examples:

- Pick three cards → Build My Perfect Sunday.
- Each person chooses two cards → AI creates one shared activity.
- Build a dream trip.
- Design a ridiculous sport.
- Three cards, one date / friend activity idea.
- Create a weekend challenge.
- Build a group itinerary from everyone’s card picks.

This creates a large space of repeatable content without Zync having to hand-author every scenario.

The product becomes not only:

> “What do we both like?”

but:

> **“What can we create from what we like?”**

This is a major bridge between social discovery and Zync Now.

---

## 19. Guest Zync — value before installation

A major growth opportunity is to avoid requiring both people to install the app before the first useful moment.

Possible flow:

```text
Existing user shows QR
→ guest scans with ordinary camera
→ lightweight web experience opens
→ guest picks 5 interests
→ hidden connections appear
→ first Zync happens
→ guest earns first Encounter / Starter reward
→ install to save profile and collection
```

This changes the growth conversation from:

> “Download this app first.”

to:

> **“Scan this — let’s see what we have in common.”**

The product itself becomes the invitation.

---

## 20. Group Zync

Group Zync may become one of Zync’s strongest formats after the one-to-one loop is stable.

Examples:

> **Four people here secretly share one interest. Find who.**

> **Only one person chose this. Guess who.**

> **Everyone privately picks Japan / Korea / Thailand / Europe — now reveal the room.**

Possible settings:

- dinner;
- party;
- orientation;
- conference;
- school;
- team building;
- hostel;
- networking event;
- travel group.

A Group Zync can end with:

- group recap;
- group-created activity idea;
- Group Encounter Pack;
- group quest;
- optional venue / food decision through Zync Now.

This creates a natural bridge from icebreaking to action.

---

## 21. Social design: cooperation before leaderboard competition

Zync should avoid a simplistic global leaderboard such as:

> “Most people Zynced with.”

That would encourage shallow scanning and spam.

More aligned social mechanics include:

- direct trading;
- group quests;
- collaborative collection;
- helping a friend complete a set;
- showcases;
- mentorship / recommendations;
- shared activity creation.

Competition can exist selectively, but it should not redefine the product around status farming.

---

## 22. Multilingual by architecture, not as an afterthought

Interest identity remains based on canonical IDs.

Example:

```text
sports.badminton
```

may display as:

- English: Badminton
- Traditional Chinese: 羽毛球
- Simplified Chinese: 羽毛球
- Japanese: バドミントン
- Korean: 배드민턴

The identity remains the same.

This lets Zync work across:

- international students;
- exchange programmes;
- conferences;
- travellers;
- language exchange;
- multinational workplaces;
- global events.

The same model can later apply to brand / venue entities while preserving locale-specific display names.

---

## 23. Free-text interests versus official collectible entities

Users should remain able to type interests that are not yet in the curated catalog.

A custom local interest can immediately join their personal Interest DNA.

But a custom string should **not automatically mint a tradeable official card**.

A safe model is:

```text
Personal Custom Interest
→ repeated demand / candidate
→ review / canonicalisation
→ Official Zync Entity
→ eligible for card universe
```

This prevents abuse such as arbitrary strings becoming scarce tradeable assets.

The same review discipline should apply to new brands, restaurants and venues entering the official graph.

---

## 24. Privacy and trust

The current core privacy principles remain important even as some future layers require accounts.

### Current core

- no account required for basic V1 Zync;
- no public profile by default;
- QR is deliberately shown;
- no phone number / precise location required for a basic Zync;
- limited AI context;
- short-lived encrypted relay.

### Future cloud collection

Cloud infrastructure should store what is needed for durable digital ownership and trading, without automatically uploading every real-world relationship.

### Encounter privacy

An Encounter card can record:

> obtained through Zync

without recording the identity of the other person in the card’s server metadata.

### Location

Zync Now may eventually need location to recommend actual places.

That should be:

- contextual;
- permissioned;
- purpose-specific;
- not a hidden permanent location history by default.

Trust is a product feature, not a policy-page exercise.

---

## 25. Reliability in real-world environments

Zync will often be used in:

- restaurants;
- parties;
- conference halls;
- schools;
- hostels;
- travel;
- venues with weak connectivity.

Therefore poor-network recovery is core product quality.

The social session should degrade gracefully.

Examples:

- local exact-match reveal should continue where possible;
- pending rewards can sync later;
- AI can fall back locally;
- trading can require connectivity because it is an atomic cloud transaction.

The product should never lose a valuable card because a network response was interrupted.

---

## 26. Growth engine

Zync has a potentially natural person-to-person growth loop:

```text
I want to Zync
→ I involve another person
→ that person experiences value
→ they earn / discover something
→ they later involve a third person
```

This is much stronger than:

> “Invite five friends for ten coins.”

Guest Zync can make this loop dramatically easier because the first experience may occur before installation.

Cardverse can reinforce it:

- Encounter Pack earned from real Zync;
- trade opportunity requires another person;
- Group quests require people;
- Zync Now creates useful group outcomes.

The social action itself becomes acquisition.

---

## 27. Retention should not mean screen addiction

Zync should not optimise for raw time spent in app.

A healthy loop is:

> **Open Zync → achieve something socially or personally useful → leave with a better real-world experience.**

Cardverse may create more frequent revisits, but the strategic objective remains real-world usefulness.

The product should avoid:

- guilt streaks;
- punishing missed days;
- fake scarcity timers;
- deceptive near-miss effects;
- endless loot-box pressure.

Unpredictability should create delight, not dependence.

---

## 28. North Star and metrics

The primary product North Star should be closer to:

> **Meaningful Zyncs**

A Meaningful Zync may require:

- successful person-to-person pairing;
- at least one meaningful reveal;
- at least one interaction / discovery step.

Important supporting metrics include:

- time from first open to first Meaningful Zync;
- first-Zync completion;
- repeat Meaningful Zync within 7 / 30 days;
- distinct people Zynced with;
- connections revealed;
- interaction types used;
- whether people report learning something new;
- whether a session starts a conversation that would not otherwise have happened;
- Cardverse collection continuation;
- percentage of packs earned through meaningful actions;
- Want-to-Try conversion from card discovery;
- Guest Zync → save / install conversion;
- Group Zync completion.

A future second major outcome metric can be:

> **Real-world decisions resolved**

Examples:

- group picked a restaurant;
- group chose an activity;
- user booked / saved an experience;
- users converted a Want-to-Try interest into action.

DAU and screen time may be useful operational metrics, but should not define product success alone.

---

## 29. Commercial model: do not force it too early

The product does not need to decide its final monetisation model before proving strong behaviour.

In fact, early monetisation pressure could distort the experience.

### Potential long-term revenue surfaces

**Event / Host products**
- company team building;
- school orientation;
- conferences;
- hospitality;
- organised social events.

**Premium cosmetics**
- binder themes;
- card backs;
- visual frames;
- opening effects.

**Collector premium**
- advanced organisation / showcase tools;
- premium cosmetic customisation.

**Venue / restaurant discovery**
- booking / reservation commissions;
- relevant promoted placement;
- lead generation.

**Activity / experience marketplace**
- classes;
- workshops;
- sports sessions;
- experiences;
- travel activities.

**Brand integrations**
- official cards;
- collaboration editions;
- sponsored quests;
- event packs;
- real-world activations.

**Community / organiser tools**
- paid administration / event features.

### Early caution on paid random draws

Selling random paid draws is not required for Cardverse and should not be assumed.

It may create:

- trust problems;
- fairness pressure;
- regulatory complexity;
- stronger risks once trading creates perceived card value.

Zync can build an exciting collectible system first without depending on paid loot-box economics.

---

## 30. The hobbies economy

The broad long-term thesis remains that interests are both a social layer and an economic layer.

Almost every hobby has:

- communities;
- equipment;
- venues;
- teachers / coaches;
- events;
- travel;
- specialist merchants;
- content;
- services;
- bookings;
- local experts.

The Interest Graph can eventually connect:

```text
Person
↕
Interest
↕
Intent
↕
People / Place / Activity / Brand / Community
```

The business model should create value around this ecosystem rather than sell raw personal data.

---

## 31. Product phases

The phase boundaries should remain evidence-driven, but the expanded roadmap is now clearer.

### Phase 1 — Prove the two-person magic moment

Core:

- multilingual interest identity;
- QR pairing;
- hidden connection reveal;
- AI interaction;
- curiosity / crossover;
- People history;
- Interest DNA.

Goal:

> prove that Zync creates real conversation and person-to-person spread.

### Phase 1.5 — Build the engagement foundation

After the core loop is stable:

- five-interest quick-start onboarding;
- richer structured interaction mechanics;
- mystery progression;
- achievements;
- Cardverse foundation;
- cloud-backed collection account;
- quests;
- Want to Try integration;
- My Zync World.

Trading architecture should be prepared even if direct trading launches later.

### Phase 2 — Expand from two people into shared action

Potential additions:

- Direct Card Trading;
- Guest Zync;
- Group Zync;
- Zync Now;
- richer Interest Graph;
- group decision mechanics;
- activities / place relationships;
- wishlist matching.

### Phase 3 — Build communities and the hobbies economy

Potential additions:

- persistent topic communities;
- geography-aware discovery;
- event / organiser tools;
- venue / restaurant integrations;
- experience / booking links;
- brand integrations;
- community quests;
- commercial partner tooling.

The exact order should change if real user evidence points somewhere stronger.

---

## 32. Funding story

Zync is not merely a concept. An earlier MVP was built and the current product is a ground-up modern rebuild.

Early funding should primarily answer behavioural and distribution questions:

- can Zync create a magic moment quickly?;
- do people bring another person into the experience?;
- does structured interaction improve real conversation?;
- do users return?;
- does Cardverse strengthen rather than distract from social behaviour?;
- can Guest / Group formats accelerate spread?;
- does Zync Now solve meaningful real-world decisions?;
- which contexts — universities, events, teams, travel, dining — produce the strongest loops?

The strongest story is not:

> “We need a huge backend.”

It is:

> **“The product creates a new playable interest layer; funding helps us prove which parts generate durable real-world behaviour and scale the winning loops.”**

---

## 33. What success would mean

A strong early product outcome would look like:

- users understand Zync quickly;
- first-use setup feels small;
- users complete a first Meaningful Zync;
- they discover something genuinely surprising;
- the AI interaction leads to actual conversation;
- they use more than one interaction mechanic;
- they Zync with more than one person;
- existing users cause new people to experience the product;
- Cardverse gives users a reason to care about their interest world;
- Want to Try converts curiosity into exploration;
- some users use Zync to decide what to eat / do / visit;
- group use begins to emerge naturally;
- users trust Zync enough to keep a durable collection and return.

The product should earn the right to become a network and then an ecosystem.

---

## 34. Updated North Star vision

The smallest Zync interaction is:

> **Two people discover something they never knew they shared.**

The next level is:

> **Those people turn interests into a conversation, a game, a collection or something real they do together.**

The largest version of Zync is:

> **A global playable interest layer that helps people discover themselves, discover each other, decide what to do together, find relevant communities and places, and participate in the social and economic ecosystems around the things they care about.**

---

## 35. Short pitches

### One sentence

**Zync turns interests into real-world connection — helping people discover what they share, talk about it, and decide what to do together.**

### 15-second pitch

**Zync is a multilingual social discovery app built around interests. People Zync by QR, uncover hidden connections, play AI-guided interactions, collect the world of hobbies, and can eventually use those interests to decide what to eat, where to go and what to do together.**

### 60-second pitch

**People often know each other for months or years without discovering the niche interests they actually share — and even when friends are together, they constantly struggle with simple questions like what to eat, where to go or what to do. Zync turns interests into a playable real-world layer. Two people scan a QR, uncover hidden connections and play AI-guided interactions around what they share or what they never knew about each other. A Cardverse makes thousands of hobbies collectible and discoverable, while quests, Want to Try and future trading connect collection back to real experiences. Over time, the same Interest Graph can power group play, decision-making, communities, restaurants, activities and brand integrations. The goal is not to keep people staring at Zync — it is to help them do more with the people and interests in their real lives.**

---

## 36. Strategic guardrails for future work

Future work should preserve the following unless explicitly changed.

1. **Do not bury the two-person magic moment under the larger vision.**
2. **Do not remove AI interaction generation from the core experience.**
3. **Do not replace QR casually; it is a useful real-world ritual and growth primitive.**
4. **Do not regress Zync into a match report.**
5. **The current core V1 must not suddenly require cloud identity merely because Cardverse will need one.**
6. **Cardverse cloud identity should protect possessions without uploading all relationship history by default.**
7. **Do not treat daily retention or screen time as the only success metrics.**
8. **Do not split canonical interests by language.**
9. **Do not manufacture false exact matches from related interests, AI, commercial partners or regional ranking.**
10. **Do not oversell Interest DNA as scientific personality analysis.**
11. **Do not sell raw personal data.**
12. **A brand cannot pay to become an organic user interest or shared match.**
13. **Sponsored recommendations must be clearly labelled and relevance-gated.**
14. **Do not let gacha mechanics become punitive or exploitative retention.**
15. **Do not build a cash card marketplace as the first trading model.**
16. **Encounter / personal-history cards may be soulbound.**
17. **Professional graphics, sound, haptics and animation are core to Cardverse reward quality.**
18. **Quests should reinforce Desired Actions, not meaningless tapping.**
19. **Group / Guest / Zync Now architecture may be anticipated now, but should not destabilise the certified two-person core.**
20. **Every side system must feed back into discovery, conversation, action or ownership.**

---

## 37. Relationship to the current codebase

This document is the **canonical business and product vision**, not the technical handoff.

For exact implementation state, CI, release blockers, preview URLs, Android signing and continuation steps, always read:

1. `AI_STATE/LATEST_HANDOFF.md`
2. the authoritative handoff it points to
3. `docs/ZYNC_V1_PRODUCT_SPEC.md`
4. `docs/ZYNC_V1_VISUAL_SYSTEM.md`

Where this document describes Cardverse, cloud collection, trading, Guest Zync, Group Zync, Zync Now, brand integration or the hobbies economy, those are **strategic product directions unless the current handoff explicitly says they have been implemented**.

Do not infer production / release status from this proposal alone.

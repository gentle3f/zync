# Zync — Business Proposal & Product Vision

> Canonical business/narrative context for future Zync work.
>
> This document explains **why Zync exists, what problem it is trying to solve, what V1 is meant to prove, how the product can grow, and what should not be overbuilt too early**. Future chats should read this together with `docs/ZYNC_V1_PRODUCT_SPEC.md` and the current `AI_STATE/LATEST_HANDOFF.md` before making strategic changes.

---

## 1. Executive summary

**Zync helps people discover the interests they did not know they had in common — and turns those discoveries into real conversations.**

The starting experience is deliberately simple:

1. each person builds a lightweight interest profile;
2. one person shows a QR code and the other scans it;
3. Zync compares their interests locally;
4. shared interests are revealed progressively rather than dumped as a list;
5. AI turns those shared interests into a natural conversation prompt;
6. if there is no exact shared interest, AI creates a crossover question between the two people’s different interests instead of showing a dead end.

The emotional product moment is not “matching data.” It is the human reaction:

> **“Wait — you like that too?”**

A representative example is two people who have known each other for years, yet only through Zync discover that both of them watch *JoJo’s Bizarre Adventure*. They may already be friends, colleagues or classmates, but this hidden overlap never came up naturally. Zync surfaces the overlap and gives them a reason to talk about it.

V1 is designed as a **low-cost, multilingual, privacy-first social experiment**. It does not require accounts, a user database, Firebase, a social graph or a large backend. Interest profiles remain on the device. QR exchange handles person-to-person discovery. AI calls go through a small Vercel proxy to OpenRouter, with local fallback questions if AI is unavailable.

The long-term vision is much larger: a global **interest layer** connecting people, interests, places and intent. But V1 exists to test whether the smallest version of that idea produces enough delight, invitation behaviour and repeat use to justify building the larger network.

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

That combination — **interest discovery + conversational activation** — is the core of Zync.

---

## 3. The problem

### 3.1 Social identity is fragmented

A person’s interests are scattered across what they watch, play, read, collect, learn, visit, follow and spend time on. No single lightweight identity layer represents this well in a way that can be used in real-world social interaction.

Existing products tend to organise people around one context:

- LinkedIn: professional identity;
- Instagram/TikTok: content and self-presentation;
- Facebook Groups / Reddit / Discord: communities around topics;
- Meetup: activities/events;
- dating apps: romantic matching;
- messaging apps: communication after people already know whom they want to talk to.

Zync starts from a different primitive:

> **“What are you into, and what does that reveal when you meet another person?”**

### 3.2 Common ground is difficult to surface

Most people do not naturally run through their entire hobby list when meeting someone. Broad interests such as “travel” may come up, but specific overlaps such as JoJo, sim racing, model railways, badminton, F1, street photography or a particular game often remain undiscovered.

The narrower the interest, the more emotionally meaningful the discovery can become.

### 3.3 Icebreakers are often generic

Many networking and social tools ask generic questions that could be shown to anyone. They do not know the participants.

Zync’s goal is different: the question should come **after** the product has learned enough about both people to create relevance.

### 3.4 Language creates unnecessary separation

Two people can share the same interest but describe it in different languages. “Badminton,” “羽毛球,” “バドミントン” and “배드민턴” should not become four separate identities.

Zync therefore treats the underlying interest as language-neutral and only localises its display.

---

## 4. What Zync V1 is

A concise definition:

> **Zync V1 = multilingual interest identity + QR exchange + hidden common-interest discovery + AI conversation.**

The product is deliberately local-first.

### Core V1 experience

- Build an interest profile.
- Search/select interests and add free-text interests.
- Mark an interest as **Love**, **Like**, or **Want to try**.
- Show or scan a Zync QR.
- Compare canonical interest IDs locally on-device.
- Reveal hidden matches progressively.
- Generate an AI conversation prompt around shared interests.
- If there is no exact match, generate a crossover prompt between different interests.
- Choose different conversation modes such as Fun, Deep, Debate, Guess or Surprise.
- Keep local history so people can **Zync Again** later.
- Show an **Interest DNA** summary of the user’s own interest profile.
- Support different languages between two participants and show equivalent questions in both languages.

### What makes the interaction distinctive

The product should not behave like a spreadsheet saying:

> Shared interests: F1, JoJo, Japan.

It should create suspense and discovery:

> **YOU ZYNC!**  
> You have 6 hidden matches.

Then reveal them one at a time.

This protects the strongest emotional moment: the surprise of learning something unexpected about another person.

---

## 5. Why QR matters

QR is not used because QR itself is novel. It is useful because it gives Zync a very clean product architecture and a strong real-world ritual.

A user deliberately chooses to show their Zync profile to the person physically in front of them. The other person scans it. There is no need to search usernames, exchange phone numbers, create friend requests or maintain a central pairing database.

For V1 this allows:

- no account requirement;
- no cloud profile requirement;
- no person-to-person pairing server;
- lower privacy risk;
- near-zero fixed infrastructure cost;
- a visible, understandable “Zync with me” interaction.

The QR contains only the data needed for local matching, such as a local random ID, nickname, language and selected interests. It does not need email, phone number, precise location or an advertising identifier.

---

## 6. Why AI belongs in V1

AI is not being added simply because AI is fashionable. There are two places where it solves a genuine product problem.

### 6.1 Interest normalisation

A fixed manually curated hobby list will always be incomplete.

A user may type:

- “Leica street photography”
- “模型火車”
- “JoJo cosplay”
- “F1 engineering”

AI can help convert free text into a stable canonical concept, while the user confirms the suggestion before it is saved.

This prevents the app from requiring the team to manually catalogue every hobby in the world before launch.

### 6.2 Conversation generation

If both people like F1, a generic database question such as “Who is your favourite driver?” is usable but limited.

AI can create a more interactive prompt:

> “If you could both attend one Grand Prix for free, which race would you choose — and if you disagree, how would you convince the other person?”

When there is no exact match, AI becomes even more valuable.

Person A may like F1 and JoJo. Person B may like photography and cooking. Instead of saying “No match,” Zync can create an unexpected crossover question that both can answer.

This is a core product principle:

> **Zero exact matches should still lead to a conversation, not a failure state.**

AI is therefore part of the V1 value proposition, while local fallback prompts ensure the app still works if the model is unavailable or rate-limited.

---

## 7. Multilingual by architecture, not as an afterthought

Zync is intended to be international.

The key design decision is that an interest is represented by a **canonical ID**, not by the displayed text.

For example:

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

This means a Japanese user and a Hong Kong user can still match even if they never use the same written word.

The same principle extends to AI questions. If one user prefers Traditional Chinese and the other Japanese, Zync can generate one semantic question and show equivalent versions in both languages.

This makes Zync relevant not only for ordinary social situations but also for:

- international students;
- exchange programmes;
- conferences;
- travellers and hostels;
- language exchange;
- multinational workplaces;
- university orientation;
- international events.

---

## 8. The retention problem — and how Zync thinks about it

A major strategic concern from the beginning has been that an “icebreaker app” could be used once and forgotten.

Zync should therefore **not** define retention as “open the app every day.” That would force unrelated gamification into the product.

The more natural goal is:

> **Whenever a relevant social situation happens, Zync is something the user remembers to open.**

Zync is closer to a reusable social utility than a daily content feed.

V1/V1.1 retention loops include:

### Conversation modes

The same shared interests can produce different kinds of interactions:

- Easy
- Fun
- Deep
- Debate
- Guess
- Surprise Me

This allows two people to reuse Zync without simply seeing the same result again.

### Hidden Match reveal

Do not reveal every match instantly. Progressive reveal creates more curiosity and turns matching into an experience rather than a report.

### Zync Again

Interests change over time.

When two people Zync months later, the app can show that new overlaps have appeared. This gives repeat use a natural meaning.

### Interest DNA

Users can keep refining a local picture of what they are into. The value of Zync therefore grows even when they are not actively meeting a new person.

### Group Zync

A later V1.1 extension can make one device the host for a dinner, orientation, networking session, party or team-building activity. This is especially interesting because one user can expose several new people to Zync in the same session.

---

## 9. Why V1 is intentionally narrow

The old vision for Zync became too broad: identity platform, career matching, social media analysis, advertising, community, data products, networking and more.

Those ideas may contain future opportunities, but putting them into the first product creates the wrong test.

V1 needs to answer a much simpler question:

> **Do people enjoy discovering hidden common interests enough to invite another person and use Zync again?**

If the answer is no, a bigger backend will not rescue the concept.

If the answer is yes, the larger network becomes much more defensible to build.

Therefore V1 explicitly avoids:

- login and cloud accounts;
- Firebase profiles;
- public feeds;
- messaging;
- communities;
- nearby people;
- location matching;
- dating matching;
- career matching;
- merchant systems;
- advertising;
- subscription infrastructure;
- social-media account imports.

This is product discipline, not a lack of ambition.

---

## 10. Phase 1 business objective: prove behaviour, not scale infrastructure

The original MVP already demonstrated that the basic concept can be built. The purpose of the current V1 rebuild is to produce a product that is polished enough to test real behaviour.

The main unknowns are distribution and usage:

- Will people complete an interest profile?
- Will one user successfully bring another person into a Zync interaction?
- Does the Hidden Match moment feel rewarding?
- Do AI questions actually start conversations?
- Do people Zync with more than one person?
- Do users return later for another Zync?
- Can an active user cause another person to install or try the product?

The strongest Phase 1 funding story is therefore not “we need money to build a huge backend.”

It is:

> **The MVP exists. Funding lets us validate real social behaviour, improve the product, run structured pilots and discover whether the interaction can spread person-to-person.**

This means spending should be framed around **market validation, pilot deployment, user acquisition experiments, product polish and measurement**, not generic advertising or speculative infrastructure.

---

## 11. Go-to-market logic

Pure paid app-install advertising may be inefficient for Zync because a person can install the app while alone and have nobody to Zync with.

Zync is more naturally demonstrated where both sides of the interaction are present at the same time.

Promising early environments include:

- university orientation;
- student societies;
- exchange-student programmes;
- conferences and networking events;
- startup / incubator communities;
- team-building sessions;
- language-exchange events;
- hostels and travel communities;
- social dinners and parties;
- corporate onboarding.

These environments create a cleaner growth experiment:

1. one person tries Zync;
2. another person must interact with them;
3. the second person experiences the value immediately;
4. the product can observe whether that person then Zyncs with somebody else.

That is much closer to Zync’s intended growth loop than simply buying isolated installs.

---

## 12. Metrics that actually matter

Daily Active Users alone would be a misleading V1 metric because Zync may be episodic.

The more useful funnel is:

```text
First open
→ completes interests
→ attempts first Zync
→ completes first Zync
→ reveals matches
→ generates/uses a question
→ Zyncs with another person later
```

Important measurements include:

- interest-profile completion rate;
- first-Zync completion rate;
- QR scan completion rate;
- question-generation / question-next usage;
- number of distinct people Zynced with;
- repeat Zync within 30 days;
- invitations / new users caused by an existing user;
- qualitative response: “Did you learn something new about this person?”;
- qualitative response: “Did this start a conversation you would not otherwise have had?”

A particularly important growth question is:

> **Can each active user create meaningful exposure to another potential user?**

Do not claim a viral coefficient or guaranteed network effect before real data exists.

---

## 13. Long-term vision: the interest layer

If V1 validates the behaviour, Zync can evolve beyond a two-person icebreaker.

The long-term model is best thought of as:

```text
Person ↔ Interest ↔ Place ↔ Intent
```

### Person

A user has a living interest identity that changes over time.

### Interest

Interests are canonical concepts with aliases, relationships, categories and multilingual labels.

### Place

The same interest may matter at different geographic levels:

```text
Global
→ Country
→ Region
→ City
```

A user should not see an empty local experience just because a niche interest has low density nearby. Zync can widen the geographic scope intelligently.

### Intent

Two people who both like badminton may have different intentions:

- I love watching it;
- I play every week;
- I want to learn;
- I want people to play with;
- I want to join a community.

Intent becomes more important once the network has enough density.

---

## 14. Future community vision

The long-term community idea is not simply “make another Facebook Group or Reddit clone.”

The useful concept is that users should not need to hunt manually for the entrance to every hobby community.

If someone already has “Badminton” in their interest identity and moves to Singapore, Zync should be able to surface relevant Singapore badminton communities.

If someone loves JoJo but none of their current friends talk about it, Zync could surface a broader JoJo community.

If someone has a niche interest such as railways and there are too few nearby users, Zync can widen from city → region → country → global instead of showing an empty screen.

Persistent searchable topic communities are valuable — Reddit proves that general pattern — but Zync’s differentiation would come from the **interest identity + geography + intent + person graph** surrounding those communities.

This is Phase 2+, not something V1 should build prematurely.

---

## 15. The “hobbies economy” vision

The broadest long-term thesis is that interests are an economic layer as well as a social layer.

Almost every hobby has:

- communities;
- equipment;
- venues;
- teachers/coaches;
- events;
- travel;
- specialist merchants;
- content;
- services;
- bookings;
- second-hand transactions;
- local experts.

If Zync eventually knows that a person is genuinely interested in something, knows where they are, and knows what they intend to do, the platform can connect them to relevant opportunities without becoming a generic ad network.

Possible future monetisation may include:

- event / organiser tools;
- community management or discovery tools;
- premium services for interest-based organisations;
- relevant listings;
- booking / transaction fees;
- merchant or venue discovery;
- optional premium user features;
- sponsored opportunities that are clearly relevant to a confirmed interest.

The preferred direction is to create value around the interest ecosystem — **not to sell raw personal data**.

---

## 16. Optional social-account import — later, not V1

A future Zync may allow users to connect authorised data sources or provide exports so AI can suggest interests from their existing digital activity.

Examples might include posts, followed topics, photos, travel history or other user-authorised signals where platform access permits it.

The product principle should be:

> **AI proposes; the user confirms.**

Do not silently convert behavioural data into permanent identity labels.

A stronger framing is **“Discover your Interest DNA”**, where Zync helps the user recover their own fragmented interests from different places, then lets them approve, reject or edit the result.

This could become a meaningful long-term advantage because Zync would aggregate interest identity across contexts rather than depending on a single social platform.

However, API restrictions, privacy, compliance and platform policies make this inappropriate for the lean V1.

---

## 17. Privacy and trust as a product advantage

V1 intentionally starts with a strong privacy posture:

- no account required;
- no public profile by default;
- interest profile stored locally;
- QR shared only when the user deliberately shows it;
- no email/phone/precise location required for a Zync;
- AI receives only the limited context required to generate the relevant output;
- API secrets remain server-side;
- local fallback works if AI is unavailable.

A simple user-facing idea is:

> **Your interests live on your phone. You choose when to Zync.**

This matters strategically. If later phases ask users to share more information, trust is easier to build from a product that originally minimised collection rather than one that collected everything from day one.

---

## 18. Competitive positioning

Zync should not be described as a replacement for every social product.

It occupies a more specific starting position.

### Zync is not primarily a dating app

It does not assume romantic intent.

### Zync is not primarily Meetup

It does not start from finding a scheduled activity or stranger nearby.

### Zync is not primarily Reddit/Facebook Groups

It does not start from browsing communities.

### Zync is not primarily LinkedIn

It is not a professional CV identity.

### Zync starts from the space between two people

> **Who are you, what are you into, what do we unexpectedly share, and how can that become a real conversation right now?**

If that interaction earns repeat usage, the broader social/community layer can grow around it later.

---

## 19. Why the product should not start with “find someone to do X tonight”

Activity matching sounds attractive but is a poor cold-start foundation.

A new network has low local density. Random meetups with strangers introduce trust and safety concerns. Existing sports/activity groups already coordinate well in many cities.

Zync’s more realistic path is:

1. help people discover connection with people already in front of them;
2. build a richer interest identity;
3. build familiarity and trust;
4. surface communities as network density grows;
5. only then make activity matching useful where there is enough context and supply.

This sequencing reduces the cold-start burden.

---

## 20. Product and business phases

### Phase 1 — Validate the magic moment

Goal: prove that hidden common-interest discovery creates real conversations and person-to-person spread.

Product:

- local interest identity;
- QR exchange;
- Hidden Match;
- AI shared/crossover questions;
- conversation modes;
- Zync Again;
- Interest DNA;
- multilingual/bilingual interaction;
- optional Group Zync after the two-person loop is stable.

Business focus:

- pilot environments;
- acquisition experiments;
- product polish;
- behavioural measurement;
- no heavy monetisation burden.

### Phase 2 — Build the Interest Graph and communities

Only after Phase 1 evidence.

Potential additions:

- optional account/cloud sync;
- richer Interest Graph;
- geography hierarchy;
- persistent topic communities;
- intent states;
- event / organiser tools;
- more robust group experiences;
- optional import of user-authorised interest signals.

### Phase 3 — Build the hobbies economy

With enough identity, community and intent data, connect users to:

- events;
- venues;
- coaches/teachers;
- merchants;
- experiences;
- bookings;
- relevant products/services;
- specialist local and global opportunities.

Monetisation should come from useful transactions/services, not from selling private conversation data.

---

## 21. The funding story

A credible funding narrative should remain focused.

### What already exists

Zync is not merely a concept. An earlier MVP was built and published, and the current V1 is a ground-up modern rebuild designed for proper product testing.

### What funding is for

The highest-value use of early funding is to answer behavioural questions:

- can we acquire users in contexts where Zync is immediately usable?;
- will users complete profiles and Zync successfully?;
- is the Hidden Match experience strong enough to create delight?;
- do users invite the next person?;
- do they come back later?;
- which settings — universities, networking, travel, events, teams — produce the strongest usage loop?;

Therefore funding should be presented as **validation capital**, not as money required to build an enormous data platform before product-market evidence exists.

Do not rely on inflated market-size figures or unsupported financial forecasts. The stronger story is behavioural evidence and a disciplined path from a small product into a much larger network if that evidence is positive.

---

## 22. What success would mean

Phase 1 success does not require Zync to become a daily habit immediately.

A strong result would look more like:

- users understand the product quickly;
- most users who start an interest profile complete it;
- a meaningful portion complete their first Zync;
- people report discovering something genuinely new about each other;
- users generate multiple questions instead of stopping immediately;
- users Zync with more than one person;
- existing users cause new people to experience the product;
- some users return weeks later for another Zync.

The product should earn the right to become a network.

---

## 23. The North Star

The smallest Zync interaction is:

> **Two people discover something they never knew they shared.**

The largest version of Zync is:

> **A global interest layer that helps people discover their own interests, discover what they share with others, find relevant communities wherever they are, and participate in the social and economic ecosystems around the things they care about.**

The path between those two ideas should remain evidence-driven.

---

## 24. Short pitches

### One sentence

**Zync helps people discover hidden shared interests and uses AI to turn those discoveries into real conversations.**

### 15-second pitch

**Zync is a multilingual social icebreaker built around interests. Two people exchange their interest profiles by QR, Zync reveals the things they unexpectedly have in common, and AI gives them a conversation worth having.**

### 60-second pitch

**People often know each other for months or years without discovering the niche interests they actually share. Zync turns those hidden overlaps into a social experience. Each person builds a lightweight interest profile, one shows a QR and the other scans it, and the app reveals their common interests progressively. AI then generates a question around those interests — or, if there is no exact match, finds a crossover between their different hobbies so the interaction never ends in “no match.” V1 is multilingual, local-first and privacy-conscious, with no account or central profile database required. The immediate goal is to validate whether this interaction makes people invite others and reuse Zync. If it works, the same interest identity can later become the foundation for communities, geography, activities and a broader global hobbies economy.**

---

## 25. Strategic guardrails for future chats

Future work should preserve the following unless the user explicitly changes direction:

1. **Do not turn V1 into a giant social network before validating the two-person loop.**
2. **Do not remove AI from V1.** AI normalisation and crossover/shared-interest question generation are intentional product features.
3. **Do not replace QR casually.** QR is central to the low-cost, local-first architecture and real-world ritual.
4. **Do not require accounts/Firebase/community infrastructure for the core V1 experience.**
5. **Do not treat daily retention as the only definition of success.** Zync may be episodic but still valuable.
6. **Do not force activity matching as the initial product.** Network density and trust are not ready for that at cold start.
7. **Do not split interests by language.** Canonical language-neutral IDs are foundational.
8. **Do not oversell “Interest DNA” as psychology.** It is a descriptive interest identity, not scientific personality analysis.
9. **Do not sell raw personal data as the business model.** Prefer useful services, transactions and ecosystem value.
10. **Do not lose the emotional core:** “Wait — you like that too?” is more important than a complicated recommendation engine.
11. **Professional UI/UX and graphics are part of the product, not optional decoration.**
12. **Keep infrastructure near-zero-cost while validating Phase 1.** Scale infrastructure only when usage justifies it.

---

## 26. Relationship to the current codebase

This document is the **business/product narrative**, not the technical handoff.

For implementation status, current CI, release blockers, production URLs, Android signing and exact continuation steps, always read:

1. `AI_STATE/LATEST_HANDOFF.md`
2. the authoritative handoff it points to
3. `docs/ZYNC_V1_PRODUCT_SPEC.md`
4. `docs/ZYNC_V1_VISUAL_SYSTEM.md`

Do not infer current deployment/release status from this proposal alone.

# Group Zync v1

Status: design specification  
Target: 3–8 participants  
Principle: reuse the existing Zync primitives; do not build a separate social network.

---

## 1. Product purpose

Group Zync extends the original two-person magic moment to real situations where several people are physically together:

- dinner;
- party;
- orientation;
- networking event;
- class;
- hostel;
- team building;
- travel group.

The goal is not “group chat.”

The goal is:

> **help the room discover something surprising about itself, interact, and optionally decide what to do together.**

---

## 2. Scope

Initial Group Zync:

- 3–8 participants;
- one host device;
- join by QR / short-lived link;
- ephemeral group session;
- no permanent group membership;
- no feed;
- no messaging;
- no public room search.

Zync Now uses the same group-native decision engine.

---

## 3. Architecture rule

Do not overload the existing 1:1 QR payload in a backward-incompatible way.

Create a versioned Group Session protocol.

Suggested conceptual components:

```text
Host
→ creates ephemeral room
→ displays group QR

Participants
→ scan
→ submit encrypted limited profile
→ receive room state / reveals

Host
→ calculates group discovery plan
→ publishes bounded group state
```

The relay is transport, not a permanent social graph.

---

## 4. Privacy model

A participant joining Group Zync explicitly shares a **limited Zync profile** for that room.

The full profile must not be displayed to everyone as a directory.

The host may need participant interest payloads locally to calculate group patterns in v1, but:

- the relay stores encrypted opaque payloads;
- participant profiles are ephemeral session data;
- only bounded reveal results are published to the room;
- raw group payloads expire;
- social links are not included in the initial Group Zync protocol;
- no group participant list becomes a permanent cloud social graph.

The join screen must explain this clearly.

---

## 5. Room protocol

Suggested conceptual room fields:

```text
groupSessionId
protocolVersion
createdAt
expiresAt
maxParticipants
roomKey / encryption material
hostReadCapability (not in public QR)
hostWriteCapability (not in public QR)
```

Public QR should include only what a participant needs to join.

Never put host-admin secrets in the QR.

---

## 6. Participant identity

Use ephemeral room participant IDs.

Human-facing names may be:

- optional nickname;
- deterministic funny alias.

Do not show raw IDs.

Group participation should not require a cloud Zync account in the first Group Zync version.

---

## 7. Lobby

Host sees:

- participant count;
- ready count;
- join QR;
- start button once minimum size reached.

Participants see:

- joined confirmation;
- participant count;
- ready state;
- privacy summary.

Do not show everyone else's interest list.

---

## 8. Membership rules

Initial:

- minimum 3;
- maximum 8;
- host starts the round;
- late join after a round begins is disabled in v1;
- participant departure before start simply removes them;
- participant departure mid-round may pause or continue depending on mechanic.

Host transfer is out of scope for first implementation.

If host leaves, room may end gracefully.

---

## 9. Group discovery plan

The host computes structured group patterns such as:

- exact interest shared by all;
- exact interest shared by a subset;
- one-person unique interest;
- majority / minority split;
- complementary categories;
- useful crossover cluster.

Every “shared” claim still requires exact canonical ID equality among the claimed participants.

---

## 10. Group mechanics

### 10.1 Hidden Cluster

> Four people here share something. Who are they?

Reveal:

- participant subset;
- exact interest;
- optional follow-up.

### 10.2 Only One

> Only one person here picked this. Guess who.

Good for surprising specialist interests.

### 10.3 Majority / Minority

Present a structured choice generated from a real group signal.

Avoid turning it into popularity shaming.

### 10.4 Secret Rank

Everyone privately ranks 3 options.

Reveal group pattern.

### 10.5 Who Knows This?

One participant has a strong interest.

Others guess who, then that participant gets a lightweight “teach us something” interaction.

### 10.6 Build Together

Each participant contributes an interest / card / choice.

AI combines them into one group prompt or activity concept.

---

## 11. Interaction director

Group AI output must be structured.

Suggested contract:

```json
{
  "interactionType": "hidden_cluster",
  "title": "Who secretly shares this?",
  "roles": {
    "guessers": ["p1","p2","p3","p4"],
    "hiddenSubsetSize": 2
  },
  "steps": [
    "Everyone guesses privately.",
    "Lock answers.",
    "Reveal the two people.",
    "Reveal the interest.",
    "Ask one follow-up."
  ]
}
```

AI should not receive more profile detail than needed.

Local mechanic templates must exist as fallback.

---

## 12. Synchronisation

A Group Zync round needs an authoritative state machine.

Suggested states:

```text
lobby
ready
roundPrepared
inputOpen
inputLocked
reveal
reaction
complete
zyncNowOptional
ended
```

The host is authoritative in v1.

Clients should be able to re-fetch current bounded room state after temporary disconnection.

---

## 13. Preventing one-person domination

Group interactions should favour:

- private input first;
- simultaneous reveal;
- turn rotation;
- bounded speaking prompts.

Avoid mechanics where the fastest / loudest participant answers everything.

This is especially important for Zync Now consensus.

---

## 14. Group Zync Now integration

After one or more group discovery rounds:

> **Want Zync to pick something to do together?**

Do **not** build a separate Group Zync Now engine.

Pass current participants into the shared `N >= 2` Zync Now Decision Engine.

Reuse:

- activity modes;
- private constraints;
- hard vetoes;
- candidate scoring;
- three finalists;
- private vote / rank;
- Tried Together.

---

## 15. Group rewards

Not required for first Group Zync proof, but architecture should allow:

- Group Encounter Pack;
- group quest progress;
- group achievement;
- Tried Together memory.

Rewards must not be required for the core group experience to feel worthwhile.

---

## 16. Guest compatibility

Group Zync should be compatible with the future Guest Zync strategy.

A non-installed participant should eventually be able to:

- scan;
- choose five interests quickly;
- join the room;
- experience value;
- install / claim later.

Do not require this in the first native Group Zync build, but do not design the room protocol around permanent app accounts.

---

## 17. Network behaviour

Group usage often happens in poor-network environments.

Requirements:

- join failures explain retry clearly;
- host does not lose already joined participants on a transient UI refresh;
- participant local answers survive temporary backgrounding;
- AI failure uses local interaction templates;
- room state can be resumed within TTL.

Do not create a room that silently hangs forever.

---

## 18. Safety and social comfort

Do not reveal:

- sensitive inferred traits;
- exact personal location;
- private social handles;
- custom interests judged sensitive without deliberate reveal rules.

Participants should be able to leave a round.

Avoid “who is the weird one?” or humiliating minority framing.

Surprise should be playful, not exposing.

---

## 19. Analytics

Suggested coarse events:

```text
group_zync_created
group_zync_joined
group_zync_started
group_round_started
group_round_completed
group_zync_now_started
group_zync_completed
```

Useful properties:

- group size bucket;
- mechanic type;
- completion;
- time to ready;
- round count;
- Zync Now conversion.

Do not upload raw participant interest lists to analytics.

---

## 20. Testing

### Protocol tests

- 3 participants;
- 8 participants;
- duplicate joins;
- expired room;
- invalid room key;
- late join;
- host leaves;
- participant disconnect / reconnect;
- encrypted payload corruption.

### Semantic tests

- subset shared interest uses exact IDs;
- no false shared claim from related graph;
- unique-interest mechanic identifies exactly one participant;
- mechanic selection does not repeatedly target the same person.

### UI tests

- lobby;
- ready;
- hidden input;
- simultaneous reveal;
- host start;
- reconnect.

### Physical tests

- 3 phones;
- 5 phones;
- 8 phones if available;
- mixed Android screen sizes;
- weak Wi-Fi / mobile handoff.

---

## 21. Explicit out of scope

Initial Group Zync does not include:

- persistent group chat;
- permanent group membership;
- nearby room discovery;
- public events directory;
- host monetisation;
- venue booking;
- friend graph;
- voice / video;
- arbitrary file sharing.

---

## 22. Exit gate

Group Zync v1 is ready when:

1. 3–8 participants can join quickly;
2. room privacy is understandable;
3. at least three group mechanics work end-to-end;
4. all exact-shared claims remain canonical-ID exact;
5. private input / simultaneous reveal works;
6. AI failure still leaves usable group mechanics;
7. the room survives brief network interruption;
8. the group can enter the shared Zync Now engine without a rewrite;
9. physical multi-device QA passes.

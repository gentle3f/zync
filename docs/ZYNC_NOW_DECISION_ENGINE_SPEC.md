# Zync Now Decision Engine v1

Status: design specification  
Phase: first implementation target after foundation  
Core rule: **group-native from day one; no place / venue recommendation in Phase 1**

---

## 1. User problem

People frequently spend more effort deciding what to do together than actually doing something.

Typical failure modes:

- everyone says “anything is fine”;
- one loud person dominates;
- people forget each other's interests;
- nobody wants to reject another person's idea;
- the group repeats the same safe option;
- one person knows an activity the others would enjoy but never proposes it;
- people want something new but cannot think of what.

Zync already has structured interest data.

Zync Now should convert that knowledge into:

> **“Here are three things this group could actually do together. Pick one.”**

---

## 2. Phase-1 scope

Phase 1 answers:

> **What should we do together?**

It does **not** answer:

- which restaurant;
- which venue;
- which shop;
- which specific destination;
- what is open nearby;
- where to book.

No venue database, live business data, brand partnership or precise location is required.

A suggestion may say:

> Try indoor bouldering together.

It must not say:

> Go to ABC Climbing Gym at 7pm.

---

## 3. Group-native architecture

Zync Now must accept:

```text
N >= 2 participants
```

Two people are simply the smallest valid group.

Do not build a 1:1 engine and later fork a separate group algorithm.

Suggested input:

```dart
class ZyncNowRequest {
  final String sessionId;
  final List<ZyncNowParticipant> participants;
  final ZyncNowMode mode;
  final ZyncNowConstraints constraints;
  final Set<String> priorActivityIds;
  final String locale;
}
```

Participant input should contain only what is needed:

```dart
class ZyncNowParticipant {
  final String ephemeralParticipantId;
  final List<SelectedInterest> interests;
  final Set<String> triedActivityIds;
}
```

Do not send names, social links or unrelated People history to the activity generator.

---

## 4. Entry points

### 4.1 Post-Zync

After a good two-person Zync:

> You found 5 connections.  
> **Want to do something together?**

### 4.2 Post-Group-Zync

After a group discovery round:

> You found a few things this group could build on.  
> **Want Zync to pick something to do together?**

### 4.3 Home

Home entry:

> **Zync Now**

If no active group exists:

```text
Start Zync Now
→ create group / pair session
→ participants join
→ choose constraints privately
```

Phase 1 does not need solo Zync Now.

---

## 5. Activity modes

### 5.1 Familiar

Consumer wording:

> **Something we already like**

Prefer activities connected to interests already liked by the group.

For large groups, universal exact overlap may be rare. The algorithm should seek broad acceptance without falsely claiming everyone shares the exact same interest.

### 5.2 Pass the Passion

Consumer wording:

> **One knows, others discover**

Find a strong interest held by one or a few participants where the others do not already claim expertise.

Best candidates are:

- peer-teachable;
- first-timer friendly;
- reasonable for the group size.

### 5.3 New to Everyone

Consumer wording:

> **Something none of us has tried**

Use:

- Want to Try signals;
- nearby graph relationships;
- first-timer-friendly activity templates.

Avoid claiming nobody has ever tried it unless Zync actually has that explicit history. If history is incomplete, wording should be:

> Something none of you have selected before.

### 5.4 Meet in the Middle

Combine two or more different interests.

Examples:

- photography + cycling → photo challenge during a bike ride;
- film + cooking → make food inspired by a film then watch it;
- music + walking → themed listening walk;
- drawing + games → design a ridiculous game character together.

### 5.5 Surprise Us

Apply all hard constraints first.

Then choose unpredictably from the remaining high-quality candidate set.

This is **constrained randomness**, not arbitrary roulette.

---

## 6. Constraints

The app already knows interests.

Ask only for missing situational context.

Initial constraint set:

### Time

- under 30 minutes;
- 30–90 minutes;
- 2–4 hours;
- flexible.

### Cost

- free;
- low;
- medium;
- no preference.

Avoid specific currency assumptions in the semantic engine.

### Energy

- chill;
- moderate;
- active;
- no preference.

### Setting

- indoor;
- outdoor;
- either.

### Novelty

- familiar;
- mixed;
- adventurous.

### Hard vetoes

Each participant may privately veto broad activity types.

Examples:

- no sports;
- no cooking;
- no outdoor;
- no competitive activity.

Hard veto is different from low preference.

---

## 7. Private input and group fairness

For group use, personal constraints should not need to be exposed to the room.

The engine should aggregate them.

Example:

> Zync removed two outdoor options because they did not fit everyone's constraints.

It does not need to say:

> Alex vetoed outdoor.

This reduces social pressure.

---

## 8. Candidate pipeline

Use a deterministic structured pipeline before AI.

```text
participant interests
→ derive graph signals
→ expand eligible activity templates
→ apply group-size feasibility
→ apply hard constraints
→ score affinity / novelty / practicality / fairness
→ diversify candidate families
→ choose finalist set
→ optional AI composition / wording
```

AI should enhance candidates, not invent unbounded real-world facts.

---

## 9. Candidate scoring

Use a **fairness-aware** score rather than simple majority average.

A candidate loved by 5 people but strongly rejected by 1 should not automatically win.

Suggested initial components:

```text
hard veto check        mandatory
minimum participant fit
average participant fit
mode fit
novelty fit
constraint practicality
group-size fit
candidate diversity
repeat penalty
```

A possible initial weighting for experimentation:

```text
min participant fit      30%
mean participant fit     25%
mode fit                 15%
novelty fit              10%
practicality             10%
group-size fit            5%
diversity / repeat        5%
```

The exact weights are tunable product parameters, not permanent truth.

### Principle

Prefer **least misery + broad acceptance** over winner-takes-all majority rule.

---

## 10. Affinity signals

Possible structured signals:

```text
Love
Like
Want to Try
same subcategory
related interest
good crossover
not selected
explicit veto
already tried recently
```

Do not treat graph similarity as an exact shared interest.

---

## 11. Three-choice output

Avoid recommendation overload.

Default output:

### Safe Pick

High group acceptance, lower novelty.

### Discovery Pick

A useful learning / Want-to-Try / one-knows-others-discover candidate.

### Wildcard

A higher-novelty or creative crossover candidate.

Each card should explain **why** it fits.

Example:

> **Photo Challenge**
>
> One of you loves photography, two people marked walking-related activities, and the group chose “moderate + low cost.”

Avoid exposing private individual answers unnecessarily.

---

## 12. Intelligent re-roll controls

Do not force the group to refill the form.

Useful refinement buttons:

- cheaper;
- shorter;
- more active;
- more chill;
- indoor;
- more familiar;
- stranger;
- totally different;
- surprise us again.

A re-roll should preserve all hard constraints.

---

## 13. Consensus mechanics

The purpose is to reach a decision, not create another feed.

### 13.1 Private vote

Each participant:

- love;
- okay;
- no.

Reveal only aggregate results.

### 13.2 Eliminate one

Each participant privately removes one finalist.

### 13.3 Rank 1–3

Use a simple group rank.

### 13.4 Zync decides

If finalists remain tied, let Zync make the final random choice among acceptable tied options.

Never override a hard veto.

---

## 14. Consensus result

The end state should feel decisive:

> **Tonight's Zync: Photo Challenge**

Then provide a short activity recipe.

Example:

```text
20 minutes:
Each person takes 5 photos around one theme.

Then:
Pick one favourite photo each and explain why.
```

Still no venue recommendation.

---

## 15. Activity recipe model

Suggested output contract:

```json
{
  "activityId": "activity.photo_theme_challenge",
  "title": "Photo Challenge",
  "reason": "Fits your group's creative + low-cost preference.",
  "durationBand": "under90m",
  "costBand": "free",
  "energy": "moderate",
  "setting": "either",
  "steps": [
    "Choose one theme.",
    "Take five photos each.",
    "Reveal your favourite and compare."
  ],
  "sourceInterestIds": [
    "arts.photography"
  ],
  "generationKind": "template"
}
```

For AI-composed crossover:

```text
generationKind = ai_composed
```

but source canonical IDs and template families should still be recorded.

---

## 16. AI contract

AI receives only bounded context needed to compose the activity.

Example request:

```json
{
  "mode": "meet_in_middle",
  "groupSize": 4,
  "constraints": {
    "time": "under90m",
    "cost": "low",
    "energy": "moderate",
    "setting": "either"
  },
  "candidateIngredients": [
    {"id":"arts.photography","label":"Photography"},
    {"id":"outdoors.cycling","label":"Cycling"}
  ],
  "allowedTemplateFamilies": [
    "challenge",
    "create_together"
  ]
}
```

Server instruction must explicitly forbid:

- named restaurants;
- named venues;
- current opening-hour claims;
- invented local facts;
- unsafe instructions;
- claims that a participant likes something they did not select.

---

## 17. Local fallback

Zync Now must remain useful when AI is unavailable.

Use curated activity templates.

Examples:

### Shared sport

> Play a short casual round together and add one silly house rule.

### One knows / one learns

> Let the experienced person teach the others the three things a beginner needs first.

### Film

> Each person picks one film nobody else has seen. Randomly choose one and watch the first 20 minutes before deciding whether to continue.

### Crossover

> Combine {interestA} and {interestB} into a timed mini challenge.

Fallback quality matters because Zync Now is real-world utility, not decoration.

---

## 18. Tried Together

After a chosen activity, Zync may later ask:

> **Did you actually do it?**

Options:

- Yes;
- Not yet;
- No.

If Yes:

- save a local activity memory;
- increment Tried Together progress;
- optionally unlock a meaningful quest / reward later;
- reduce immediate repeat probability;
- improve future suggestions.

Suggested local memory:

```dart
class TriedActivityMemory {
  final String activityId;
  final DateTime completedAt;
  final List<String> sourceInterestIds;
  final int groupSize;
}
```

Do not require cloud peer identity.

---

## 19. Notifications

Not part of the first Zync Now build.

Later, person-specific proactive ideas require explicit mutual opt-in.

Example:

> **Keep giving us ideas together**

Only after consent may Zync later send:

> You both saved Pottery to Want to Try. Want three ideas this weekend?

Avoid:

- random person references after one old scan;
- guilt;
- fake urgency;
- repeated weekend spam.

---

## 20. Safety

Activity generation should exclude or constrain:

- illegal activities;
- obviously dangerous challenges;
- unsafe physical dares;
- adult-only suggestions without appropriate age context;
- activities requiring specialist supervision when that is not stated;
- harmful food / substance challenges.

A structured activity safety class should exist before scaling candidate generation.

---

## 21. Analytics

Use coarse product events.

Suggested:

```text
zync_now_started
zync_now_mode_selected
zync_now_candidates_ready
zync_now_reroll
zync_now_vote_completed
zync_now_consensus
zync_now_did_it
```

Useful coarse properties:

- group size bucket;
- mode;
- time band;
- cost band;
- output generation kind;
- consensus method;
- time-to-consensus bucket.

Do not send:

- raw peer IDs;
- nicknames;
- full personal interest lists;
- raw custom-interest text unless separately justified and disclosed.

---

## 22. Failure and recovery

### AI unavailable

Use local candidates and templates.

### One participant disconnects before consensus

Either:

- wait / resume;
- or allow host to continue only if remaining participant count remains >= 2 and the group explicitly accepts the changed group.

Recompute candidates if membership changes.

### Everyone vetoes

Say:

> Nothing fits everyone yet.

Then offer one-click relaxation:

- remove setting preference;
- allow higher novelty;
- remove cost preference.

Never ignore a hard veto silently.

### No strong interest signal

Use broad, low-friction group activities and Surprise mode.

### Weak network

Preserve local form answers and chosen constraints.

The current result should survive app backgrounding where practical.

---

## 23. Testing

### Unit tests

- N=2;
- N=3;
- N=8;
- universal shared interest;
- no shared interest;
- one expert + several newcomers;
- all Want to Try;
- conflicting hard vetoes;
- all candidates filtered;
- tie;
- AI failure;
- repeat penalty;
- custom interests.

### Property tests

Verify:

- hard vetoed activities never win;
- exact-match claims only use exact IDs;
- output max finalists remains bounded;
- group-size-incompatible templates never appear;
- re-roll preserves hard constraints.

### UI tests

- private constraints;
- three finalists;
- voting;
- tie break;
- Tried Together.

### Physical QA

Test real groups, not only simulators.

---

## 24. Phase-1 explicit out of scope

- restaurant ranking;
- venue search;
- maps;
- booking;
- live availability;
- brand sponsorship;
- precise location;
- friend graph;
- automatic calendar access;
- cash rewards;
- paid recommendations.

---

## 25. Exit gate

Zync Now v1 is ready when:

1. the same engine supports pairs and groups;
2. a pair can get three useful ideas in seconds;
3. a 3–8 person group can privately submit constraints;
4. hard vetoes are respected;
5. the engine can operate without AI;
6. AI never invents named places;
7. the group can reach consensus inside Zync;
8. a chosen action can be recorded as Tried Together;
9. time-to-consensus can be measured;
10. real users report that Zync reduced “what should we do?” friction.

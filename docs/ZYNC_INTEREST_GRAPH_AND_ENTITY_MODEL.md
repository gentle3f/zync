# Zync Interest Graph & Entity Model v1

Status: design specification  
Branch: `zync-v1-rebuild-20260917`

This document defines the semantic foundation for Zync's current interest catalog and the future systems that depend on it: Zync Sessions, Zync Now, Group Zync, Cardverse, Want to Try, trading, communities, places and brand integrations.

It is intentionally additive. Existing canonical interest IDs and exact-match semantics must remain stable.

---

## 1. Current implementation truth

The current Flutter model is centered on `InterestDefinition` in `mobile/lib/core/models.dart`:

- `id`
- `category`
- localized `labels`
- `aliases`
- `cluster`
- `rank`

The bundled catalog is assembled in `mobile/lib/core/interest_catalog.dart` from 10 catalog parts.

The current parser supports:

```text
id|category|cluster|rank|en|zh-Hant|zh-Hans|aliases
```

and family rows that can express L2/L3 taxonomy through `cluster`, for example:

```text
movies/drama
gaming/strategy
```

The current catalog already has useful V1 behaviour:

- canonical-ID exact matching;
- taxonomy path derivation;
- ancestor collapsing;
- approximate specificity;
- related-interest discovery;
- regional relevance;
- stable search aliases;
- deterministic local custom interests.

These semantics must not be broken.

---

## 2. Non-negotiable identity rule

> **Exact shared interest means exact canonical ID equality only.**

No graph edge, AI inference, category similarity, regional popularity, sponsor, venue or brand relationship may manufacture an exact match.

Examples:

```text
sports.badminton == sports.badminton
→ exact match

sports.badminton != sports.pickleball
→ related, never exact

food.sushi != brand.some_sushi_brand
→ related entity types, never exact
```

Existing released IDs must never be renamed because display language, taxonomy wording or visual metadata changes.

---

## 3. Separate identity from metadata

Do not immediately rewrite 3,000+ existing interests into a brand-new generalized database model.

Use an additive architecture:

```text
InterestDefinition
    |
    | canonical interest identity
    v
InterestEntityMetadata
    |
    +-- entity kind
    +-- activity profile
    +-- card profile
    +-- graph relationships
    +-- safety / rights metadata
```

This allows current search, QR, matching and history to remain stable while richer systems are added around them.

Later, a generalized `ZyncEntityDefinition` registry can wrap both legacy interests and new non-interest entities.

---

## 4. Entity kinds

Define a future-safe enum:

```text
interestConcept
mediaFranchise
brandAffinity
activityExperience
venue
place
community
intent
```

### 4.1 interestConcept

Generic interests / hobbies / skills / genres.

Examples:

- Badminton
- Pottery
- Street Photography
- Jazz
- Cooking

These are the primary exact-interest layer.

### 4.2 mediaFranchise

Named works, titles, artists or franchises that users can genuinely like.

Examples:

- JoJo's Bizarre Adventure
- a named film
- a named music artist

They can behave socially like interests, but need stricter art / IP rules for Cardverse.

### 4.3 brandAffinity

A brand a user genuinely chooses to identify as liking.

It is never created as an organic interest merely because a sponsor pays.

### 4.4 activityExperience

A structured thing people can do.

Examples:

- beginner pottery session
- movie night
- blind snack tasting
- photo challenge

Phase 1 Zync Now may generate these as activity templates without requiring a specific venue.

### 4.5 venue / place / community / intent

Reserved for later phases.

They must remain semantically distinct from organic hobby identity.

---

## 5. ID namespaces

Existing IDs remain unchanged:

```text
sports.badminton
gaming.chess
food.sushi
```

Future non-interest entities should use explicit type-safe namespaces.

Examples:

```text
brand.nike
venue.<stable-id>
place.<stable-id>
community.<stable-id>
activity.photo_walk_challenge
```

Do not reuse an interest ID for a venue or brand.

---

## 6. Phase-1 metadata overlay

Introduce metadata keyed by canonical interest ID rather than expanding every compact catalog row immediately.

Suggested Dart shape:

```dart
enum ZyncEntityKind {
  interestConcept,
  mediaFranchise,
  brandAffinity,
  activityExperience,
  venue,
  place,
  community,
  intent,
}

class InterestEntityMetadata {
  final String interestId;
  final ZyncEntityKind kind;
  final ActivityProfile? activity;
  final CardProfile? card;
  final List<EntityRelation> relations;
  final ContentRightsProfile rights;
}
```

This overlay can initially live in generated/static Dart data or a compact bundled data file.

The catalog remains authoritative for identity and labels.

---

## 7. Relationship model

A graph edge must state what it means.

Suggested relation types:

```text
relatedTo
parentOf
childOf
goodCrossoverWith
canLeadToActivity
oftenLearnedFrom
oftenDoneWith
brandAssociatedWith
venueSupports
communityAbout
```

Every edge should have:

- source ID;
- target ID;
- relation type;
- optional curated weight;
- source / provenance marker;
- active flag.

### Important

`relatedTo` and `goodCrossoverWith` are discovery relationships only.

They never alter exact-match semantics.

---

## 8. Zync Now activity profile

Zync Now Phase 1 needs structured activity feasibility rather than place data.

Suggested model:

```dart
class ActivityProfile {
  final bool eligible;
  final Set<ActivityVerb> verbs;
  final Set<ActivityEnergy> energy;
  final Set<ActivitySetting> settings;
  final Set<ActivityCostBand> costBands;
  final Set<ActivityDurationBand> durationBands;
  final int minGroupSize;
  final int maxGroupSize;
  final bool peerTeachable;
  final bool firstTimerFriendly;
  final bool equipmentLikely;
  final LocationDependency locationDependency;
  final Set<String> crossoverTags;
  final List<String> templateIds;
}
```

Suggested enums:

```text
ActivityVerb:
play / make / learn / watch / listen / discuss / explore / practice / challenge

ActivityEnergy:
chill / moderate / active

ActivitySetting:
indoor / outdoor / either / homePossible

ActivityCostBand:
free / low / medium / high

ActivityDurationBand:
under30m / under90m / halfDay / flexible

LocationDependency:
none / genericSpace / dedicatedVenue
```

A dedicated venue dependency does **not** mean Zync recommends a place.

Example:

> Try indoor bouldering together.

is valid Phase 1 output.

> Go to XYZ Climbing Gym.

is not.

---

## 9. Activity templates

Do not make AI invent the entire activity space from scratch.

Create a curated reusable template library.

Example:

```json
{
  "id": "activity.peer_teaches_beginner",
  "verb": "learn",
  "groupSize": {"min": 2, "max": 8},
  "requiresLeader": true,
  "render": {
    "en": "Let one person introduce the others to {interest}.",
    "zh-Hant": "由其中一個熟悉「{interest}」嘅人帶其他人試一次。"
  }
}
```

Other families:

- play together;
- beginner challenge;
- create something;
- compare favourites;
- watch / listen together;
- mini tournament;
- teach the group;
- crossover challenge;
- taste / cook / make;
- build a themed evening;
- try something new.

AI may creatively rewrite a selected template, but the structured template provides safety, fallback and explainability.

---

## 10. Card metadata profile

Suggested shape:

```dart
class CardProfile {
  final bool collectible;
  final int? cardNumber;
  final String visualFamily;
  final String iconKey;
  final String categoryKit;
  final CardArtPolicy artPolicy;
  final Set<String> supportedEditions;
}
```

### Art policy

Suggested values:

```text
originalGeneric
abstractOnly
licensedOnly
notCollectible
```

This is important for named media, artists and brands.

A named franchise may have a Zync card identity without copying copyrighted characters, logos or official art.

---

## 11. Localisation rules

The current catalog contains many generic leaves without explicit Chinese labels.

Before full Cardverse / Zync Now rollout:

### Must localise

- generic sports;
- hobbies;
- activities;
- skills;
- common genres;
- common foods;
- generic crafts;
- generic travel styles.

### May remain native / official

- artist names;
- franchise titles;
- brand names;
- proper nouns where the official or commonly used name is more appropriate.

### Search behaviour

All useful names should remain searchable:

- English;
- Traditional Chinese;
- Simplified Chinese;
- native title;
- common alternate name;
- historical alias where needed.

Canonical IDs remain unchanged.

---

## 12. Localisation audit

Add automated validation that classifies leaves as either:

```text
generic_requires_translation
proper_name_native_ok
explicit_exception
```

A newly added generic interest should fail CI if required zh-Hant / zh-Hans labels are missing.

Do not mechanically translate proper names merely to make the audit green.

---

## 13. Custom interests

Current deterministic local custom IDs remain useful.

A custom interest can immediately join the user's personal Interest DNA.

But:

> **A custom user string must never automatically become an official collectible or tradeable entity.**

Promotion flow:

```text
custom local interest
→ repeated demand / editorial candidate
→ canonical review
→ official entity
→ card / activity eligibility
```

This prevents users from minting arbitrary tradeable objects.

---

## 14. Profile selection semantics

Current `InterestStrength` remains:

- Want to Try;
- Like;
- Love.

These strengths are valuable to Zync Now.

Examples:

- Love + Love → strong familiar candidate;
- Love + Want to Try → ideal one-knows / one-discovers candidate;
- Want to Try across multiple people → ideal new-to-group candidate.

Do not reinterpret InterestStrength as psychological intensity beyond the user's explicit selection.

---

## 15. Future generalized entity selection

Do not overload `SelectedInterest` with brands / venues immediately.

Future generalized shape may be:

```dart
class SelectedEntity {
  final String entityId;
  final ZyncEntityKind kind;
  final AffinityStrength strength;
}
```

But QR V1 should continue carrying `SelectedInterest` until a versioned protocol explicitly upgrades it.

This prevents future entity work from silently changing current pairing semantics.

---

## 16. Migration strategy

### Stage 1

Keep:

- `InterestDefinition`;
- current parsers;
- current catalog parts;
- current exact matching.

Add:

- metadata overlay;
- activity templates;
- graph validation;
- card metadata.

### Stage 2

Teach Zync Now and Cardverse to read the metadata overlay.

### Stage 3

Introduce a generalized entity registry for future brands / venues / communities while adapting existing interests into it.

### Stage 4

Only version the QR / session payload when a real feature requires non-interest entity exchange.

---

## 17. Validation requirements

CI should eventually verify:

- canonical IDs unique;
- no duplicate same-category concepts;
- valid taxonomy paths;
- valid relation targets;
- no self-relations unless explicitly supported;
- activity templates exist;
- group-size ranges valid;
- activity metadata enums valid;
- collectible cards have visual metadata;
- card numbers unique and stable;
- generic translation requirements satisfied;
- official non-interest entity namespaces do not collide;
- custom IDs never appear in official card registry.

---

## 18. Initial implementation files

Recommended additive files:

```text
mobile/lib/core/interest_entity_metadata.dart
mobile/lib/core/activity_templates.dart
mobile/lib/core/entity_relationships.dart
mobile/lib/core/card_metadata.dart
mobile/test/interest_entity_metadata_test.dart
```

Do not move the existing 3,000+ interests into a new format in one risky migration.

---

## 19. Exit gate

The Interest Graph / Entity Model foundation is ready when:

1. current exact matching is unchanged;
2. generic localisation rules are enforceable;
3. every Zync Now eligible interest has valid activity metadata;
4. a representative Cardverse sample can resolve visual metadata;
5. graph edges are typed and validated;
6. future brand / venue entities have a safe namespace without entering the current V1 QR contract;
7. CI catches broken metadata references.

Only then should full-scale activity and card generation depend on this layer.

# Zync Card Art Prompt System V1

## Purpose
This is the authoritative prompt architecture for scalable Zync Hobby Card artwork generation.

We are not hand-writing 3000 independent prompts. We are defining an inheritable system:

```
global style
→ archetype
→ category
→ subcategory
→ hobby recipe
→ optional override
→ compiled prompt
```

The artwork layer contains no title, logo, rarity badge, frame, UI, watermark, or card number.

## Visual North Star
Every image should be:
- recognisable in about 2 seconds
- premium and collectible
- cinematic but not muddy
- emotionally appealing
- coherent with the supplied Zync reference
- readable on a small mobile card
- specific to the hobby, not generic stock art

The image should sell the fantasy of the hobby, not merely depict an object.

## Model Policy
Default:
- `flux-2/edit`

Fallback:
- `gemini-25-flash-image/edit`

Premium rescue / showcase:
- `nano-banana-pro/edit`

Escalation:
1. FLUX first pass
2. FLUX reroll once if needed
3. Gemini Flash if still weak
4. Nano Banana Pro only for flagship / important rescue

## Prompt Composition Order
1. global style
2. archetype guidance
3. category modifier
4. subcategory modifier
5. hobby-specific subject and environment
6. emotion
7. composition / camera / lighting / palette
8. recognition anchors
9. must-include
10. avoid
11. global negatives

## Card Art Quality Rules
Each image must pass:
- recognition
- collectible desirability
- composition
- Zync style consistency
- technical coherence

Technical coherence includes:
- no duplicated key objects unless intentional
- no wrong-sport / wrong-activity confusion
- no accidental text
- no malformed core gear
- no contradictory scene logic

## Long-Tail Strategy
Flagship hobbies:
- manual review
- custom override allowed

Common hobbies:
- normal inherited recipe + QA

Long-tail hobbies:
- inheritance-driven
- only custom intervention on failure

## Benchmark Set
Use these five for A/B model and prompt testing:
- Badminton
- Board Games
- Bouldering
- Cinema
- Sushi

## Known Hard Cases
Treat these as high ambiguity:
- AI
- Cinema
- Photography
- Japan
- LEGO
- Camping
- Running
- Reading
- History
- Philosophy
- Fashion
- Mindfulness

## Implementation Requirement
Claude Code should implement this system faithfully rather than inventing a different prompt philosophy.

Compiled output must remain auditable:
```
hobby id
model
archetype
category
subcategory
compiled prompt
negative constraints
attempt
output path
QA result
```


---

# V1 Review Addendum — 2026-09-21

The prompt compiler smoke test was reviewed before catalog-scale generation.

## Architecture corrections now authoritative

The inheritance chain is now:

```
global style + style reference
→ archetype
→ curated archetype visual variant
→ category
→ subcategory
→ hobby recipe
→ optional override
→ compiled prompt
```

### Archetype visual variants
`specs/archetype_variants_v1.json` contains curated composition/camera/lighting variants for every archetype.

A hobby may explicitly select `visual_variant`. Otherwise the compiler chooses a deterministic variant from its archetype so large catalogs do not repeat one composition endlessly.

### Tier and difficulty are separate
Do not use `hard_case` as a tier.

- `tier`: flagship | common | long_tail
- `difficulty`: normal | hard_case

A hobby may be both flagship and hard_case.

### Reference image
All edit-model generation should use:

`references/zync-card-style-reference.png`

The reference is style-only. It must not be copied for text, logo, frame, typography, exact composition, or subject.

### Review requirements
Flagship and hard-case entries require human review before broad batch generation.

### Current catalog
The current mobile interest catalog on this branch contains approximately 2032 canonical entries across `interest_catalog_part1.dart` through `interest_catalog_part10.dart`.

Prompt expansion should target **all current canonical interests**, not a hard-coded number such as 3000. The architecture must remain compatible with future catalog growth beyond 3000.

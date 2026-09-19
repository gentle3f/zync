# Zync — Mini Handoff — 2026-09-19 Expanded Master Product Vision

Branch: `zync-v1-rebuild-20260917`

Canonical business/product vision was substantially expanded in:

`docs/ZYNC_BUSINESS_PROPOSAL_AND_VISION.md`

Commit:

`90226840aea6bf736e3d445438857f2b3e4b85cf`

## Strategic decisions now canonical

- Zync is evolving from a two-person hobby matcher into a **playable real-world interest layer**.
- The core remains **real people first**: side systems must feed discovery, conversation, ownership or real-world action rather than optimise screen time.
- Major product loops:
  - 30-second Magic Loop;
  - longer Zync Session Loop;
  - daily/weekly Cardverse meta loop;
  - months/years My Zync World identity loop.
- AI should evolve from question generator into a structured **interaction director / lightweight game master**.
- **Zync Now** is a major future pillar for solving real-life group decision friction:
  - what to eat;
  - what to do;
  - where to go;
  - how to combine different interests into one shared plan.
- The Interest Graph should eventually support semantically distinct entity types:
  - Interest Concept;
  - Brand Affinity;
  - Media / Franchise;
  - Venue / Restaurant;
  - Activity / Experience;
  - Place;
  - Community;
  - Intent.
- A brand may be genuinely liked and collectible, but **cannot pay to become an organic hobby or manufacture a shared match**.
- Sponsored venue / restaurant / brand recommendations must be clearly labelled and relevance-gated.
- Brand integration surfaces may later include:
  - official brand cards;
  - collaboration editions;
  - sponsored quests;
  - event packs;
  - venue / restaurant discovery;
  - bookings / reservations;
  - real-world activations.
- Cardverse is now a strategic engagement layer:
  - 3,000+ curated interests can become collectible cards;
  - rarity belongs to variants, not the social status of a hobby;
  - visual quality, pack-opening animation, sound and haptics are core;
  - card generation must be procedural / hybrid rather than 3,000 manual illustrations;
  - card discovery should feed Want to Try and real-world exploration.
- Card collection requires durable cloud ownership:
  - Google / Apple identity;
  - cloud-backed card inventory / packs / quests / cosmetics;
  - core People / conversation history can remain local-first by default.
- Trading should be **architecture-ready now, feature-later**:
  - direct card-for-card trade first;
  - wishlist matching;
  - atomic server swap;
  - no cash marketplace initially;
  - Encounter / personal-history cards may be soulbound.
- Guest Zync and Group Zync are high-value future growth surfaces.
- Meaningful Zyncs, not screen time, are the primary product North Star.
- A future second outcome metric is **Real-world decisions resolved**.
- Monetisation should remain flexible; possible long-term surfaces include:
  - host/event products;
  - premium cosmetics;
  - restaurant/venue booking or promotion;
  - activities/experiences;
  - brand integrations;
  - organiser/community tools.
- Early paid random-draw monetisation is not assumed.

## Current implementation boundary

The expanded vision does **not** mean these future layers are already implemented.

Current V1 implementation truth is still defined by:

- `docs/ZYNC_V1_PRODUCT_SPEC.md`
- current authoritative implementation handoff.

Production and Play remain closed unless explicitly changed.

## Next strategic design work

Before building another broad feature batch, derive implementation specs beneath the master vision:

1. Interest Graph / entity model;
2. Card Schema + procedural visual generation system;
3. Card economy / quests / cloud collection model;
4. Trading-ready ownership ledger;
5. Zync Now decision-flow design;
6. Guest / Group compatibility constraints.

Keep the certified two-person core stable while designing these layers.

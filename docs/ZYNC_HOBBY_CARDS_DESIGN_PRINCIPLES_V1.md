# Zync Hobby Cards — Design Principles v1

Status: **Authoritative art/product direction for the next card pass**
Branch context: `zync-v1-rebuild-20260917`
Scope: Cardverse collectible design, activity progression, trading and brand-card readiness
Production / Play status: **CLOSED**
Art scaling status: **Do not scale to thousands until the flagship benchmark passes**

---

## 1. Why Zync cards exist

Zync cards are not decorative inventory. They are the object that should make people want to:

1. come back to Zync,
2. complete real-world tasks,
3. Zync with more people,
4. try more activities,
5. build and show an identity,
6. trade or complete collections,
7. remember real-world experiences,
8. and eventually give brands / venues / events something worth publishing as a collectible.

The core product idea is:

> **Other games level cards by keeping you on screen. Zync should make real life level the card.**

However, the MVP must stay simple. Do not build a heavy anti-cheat or location-surveillance system just to support this idea.

The priority order for Cardverse v1 is:

**Desirable → Recognisable → Collectible → Meaningful → Useful → Scalable**

A mechanic around an unattractive card does not create a compelling collectible loop.

---

## 2. The collectible test

Every production card must pass these five tests.

### 2.1 Two-second recognition
Hide the hobby title.

A normal person should understand the rough subject in about two seconds.

Examples:
- Badminton should read as badminton before the label is seen.
- Road Trip should read as driving / road / journey, not merely a route diagram.
- Coffee should feel like coffee / café culture, not generic warm-brown abstraction.

Abstract graphic language is allowed only as a supporting layer.

### 2.2 Desire test
Even a person who is not deeply interested in that hobby should be able to think:

> “That is a nice card. I would keep it.”

Cards should feel closer to a miniature collectible poster than a database tile.

### 2.3 Fantasy test
The art should sell the **feeling of doing the hobby**, not merely illustrate the noun.

Examples:
- Badminton: movement, air, light, athletic energy.
- Japan: discovery, atmosphere, place, aspiration.
- Piano: mood, intimacy, harmony, performance.
- Road Trip: freedom, distance, open road, destination.
- Coffee: ritual, warmth, conversation, place.

### 2.4 Collection test
Cards from Zync must clearly belong to one family when shown together, while still having distinct personalities.

Shared system:
- consistent card proportions,
- consistent information hierarchy,
- consistent badges / metadata placement,
- consistent typography,
- consistent finish behaviour.

Variable system:
- art composition,
- subject,
- mood,
- dominant palette,
- category energy,
- setting,
- viewpoint.

### 2.5 Rarity-feel test
A player should perceive a visual step-up before reading the rarity label.

Rarity should not be “same image + different text”.

---

## 3. Art-direction rule: recognisable first, abstract second

The previous procedural direction was too often:

**abstract first → label explains it**

The target direction is:

**recognisable subject first → abstract Zync styling enriches it**

The visual concept board with Badminton, Bouldering, Sushi, Japan, Cinema and Piano is the current benchmark direction because it feels like a collectible brand rather than generated UI inventory.

Do not copy that board literally card-for-card. Use it as the quality bar and system reference.

### Hard rule
If the card becomes ambiguous when the hobby title is hidden, the artwork fails.

### Hard rule
Do not solve poor recognisability by adding more explanatory text.

### Hard rule
A category cannot be implemented by simply swapping palette and icon.

---

## 4. Card-front hierarchy

The front of the card is primarily a desire surface.

Recommended hierarchy:

1. **Main artwork**
2. **Hobby title**
3. **Short hobby personality line / keywords**
4. **Rarity badge**
5. **Edition / card number**
6. **Finish shown visually, not merely written**

Example:

**自駕遊**  
`自由 · 公路 · 探索`

[hero artwork]

`RARE · FOIL`  
`CORE · 023/050`

The front should not become a dashboard.

Avoid:
- arbitrary combat stats,
- long descriptions,
- server / database terminology,
- progress counters,
- too many functional icons,
- engineering language.

---

## 5. What should sit under the card name?

Use a short **personality line**, not a technical field.

Preferred formats:

### Three-keyword identity
`自由 · 公路 · 探索`

### Short emotional line
`Small rallies. Big moments.`

### Very short flavour line
`New roads, better stories.`

This line should help the player feel the activity.

Do not put “Foil” directly under the hobby title as if it describes the hobby itself.

---

## 6. Separate Rarity, Finish and Edition

These are different systems and must not be conflated.

### 6.1 Rarity
Rarity describes how difficult / special the collectible is.

Initial taxonomy:

- Common
- Uncommon
- Rare
- Epic
- Legendary
- Secret / Special

Rarity can influence:
- border language,
- artwork composition,
- embellishment density,
- animation intensity,
- pack odds,
- prestige.

Rarity does **not** automatically mean more gameplay power.

### 6.2 Finish
Finish describes the surface / presentation treatment of the same collectible.

Initial taxonomy:

- Normal
- Foil
- Holo
- Prism
- Textured / Signature (future)

Finish should be visibly different in rendering.

Examples:
- Foil: local metallic sheen.
- Holo: angle-dependent iridescent layer.
- Prism: faceted / refractive visual behaviour.
- Normal: clean non-reflective baseline.

Do not make “Legendary” a finish.
Do not make “Foil” itself the rarity.

### 6.3 Edition
Edition describes where / why the card was issued.

Examples:

- CORE
- DISCOVERY
- ENCOUNTER
- SEASONAL
- EVENT
- BRAND COLLAB
- LOCATION
- MOMENT

Edition is useful for:
- collection pages,
- set completion,
- brand campaigns,
- seasonal drops,
- event exclusives,
- memory cards.

---

## 7. Card number and set completion

Every collectable release should have a stable number inside a defined set when practical.

Examples:
- `CORE 023/050`
- `JAPAN 07/24`
- `YONEX 03/12`

This gives the player:
- completion goals,
- missing-card desire,
- trade targets,
- visible collection structure.

Do not assign meaningless numbers merely for decoration. The number must map to a real set definition.

---

## 8. Card detail / “back” layer

The front makes the player want the card.

The detail layer makes the card useful.

Potential modules:

### Activity DNA
Only use dimensions that have real product meaning.

Examples:
- Adventure
- Social
- Energy
- Creativity
- Focus
- Planning

These may later support recommendations, Zync Now and activity matching.

Do not add fake ratings merely because trading cards often have numbers.

### Activity fit
Examples:
- Best for: 2–4 people
- Typical time: 2h+
- Indoor / Outdoor
- Low / Medium / High planning

### Your Journey
Personal progression attached to the player, not the tradeable card.

Examples:
- Tried 2 times
- Zynced with 4 people
- 3 places explored
- 2 different groups

### Next step
Example:
- “Do this one more time with a different person to unlock Explorer.”

### Related action
Examples:
- Find someone to do this with
- Start a Zync
- Try this activity
- Open related quests

---

## 9. Real life should level the relationship, not manufacture fake power

Separate two concepts:

### Collectible ownership
The player owns a Road Trip card.

This can be:
- drawn,
- traded,
- duplicated,
- limited,
- branded,
- finished as Foil / Holo / Prism.

### Personal experience
The player has actually done Road Trip activity.

This progression should stay with the person and should not be transferable through card trading.

Possible progression language:

- Discovered
- Tried
- Zynced
- Active
- Explorer
- Connector

Exact names are not locked yet.

The important rule is:

> **Trading a card must never let someone purchase another person's real-world experience.**

---

## 10. Simple proof model for real-world progression

Do not overbuild verification in v1.

The target MVP proof is:

**Dynamic QR + distinct accounts + server timestamp + mutual confirmation + cooldown / unique-person rules**

This should be sufficient for ordinary activity progression.

Avoid requiring:
- continuous GPS,
- Bluetooth tracking,
- NFC,
- photo verification,
- health data,
- complex anti-fraud scoring

unless a later high-value use case genuinely requires it.

### Verification strength should follow reward value

#### Self log
May support personal diary / private history.

Should not unlock scarce tradeable rewards.

#### Verified Zync activity
Two or more distinct accounts participate in a server-timed session and confirm completion.

Can count toward normal progression.

#### Strong proof
Venue / organiser / event / brand code.

Reserve this for higher-value outcomes such as:
- limited brand cards,
- event cards,
- rare tradeable rewards,
- high-prestige campaign unlocks.

### Anti-cheat principle

> **Make cheating inconvenient enough to remove casual farming, without making normal real life inconvenient.**

Useful low-complexity rules:
- same pair + same activity has a cooldown,
- some milestones require different people,
- some milestones require different days,
- cap progression credit per day where needed,
- do not build global grind leaderboards that amplify cheating incentives.

---

## 11. Trading

Trading is a future retention and social layer, but card desirability must come first.

Potential reasons to trade:
- duplicate cards,
- missing set entries,
- preferred hobbies,
- finish upgrades,
- edition completion,
- limited events,
- brand cards.

Trading rules should preserve:
- server-authoritative inventory,
- immutable ownership changes,
- no duplication exploits,
- no transfer of personal activity history.

Do not design the whole app around a speculative card market.

---

## 12. Brand / venue / event cards

Brand collaborations should feel like collectible publishing, not advertising inventory.

The target should be:

> A brand wants to appear on the card because the card is desirable enough to be collected.

Examples:
- Yonex Badminton Event Edition
- Nike Running Night Edition
- LEGO Creator Edition
- café / venue location cards
- festival / concert / cinema encounter cards

Brand-card guardrails:

1. The hobby remains legible.
2. Brand identity does not overpower the collectible.
3. The card still looks like Zync.
4. The unlock mechanism should relate to real activity where possible.
5. High-value campaign cards should use stronger proof than ordinary self-report.
6. Do not turn the card front into a banner ad.

---

## 13. Moment cards

A future high-emotion format is a **Moment Card**.

Example:
A group finishes a verified camping activity together.

Each participant may receive:
- a Camping Moment card,
- date / season / general place context,
- special artwork,
- non-tradeable or soulbound treatment.

This can turn Cardverse into a real-life scrapbook.

Moment cards are promising but are not required for the current flagship art pass.

---

## 14. Battle / gameplay

Do not add combat stats merely because the product contains cards.

If future card gameplay exists, it should support Zync's mission.

Better directions:
- scenario challenges,
- group decision games,
- activity recommendation games,
- interest-combination games,
- social icebreakers.

Example:
A scenario asks for the best activity for four people on a rainy Saturday with a limited budget.

Cards can contribute real traits such as:
- indoor / outdoor,
- energy,
- social intensity,
- group size,
- cost,
- planning level.

Rarity should not equal raw power.

This avoids pay-to-win and keeps the cards connected to real-life interests.

---

## 15. Flagship benchmark batch

Before expanding the art system, create and review these 10 benchmark cards:

1. **Badminton**
   - Must show movement and athletic energy.
   - Cannot depend on only a shuttlecock icon.

2. **Bouldering**
   - Must feel vertical, physical and adventurous.
   - Human / wall relationship should be readable.

3. **Sushi**
   - Must feel delicious and collectible, not stock-food photography.
   - Strong composition and craft mood.

4. **Japan**
   - Must communicate place and aspiration without becoming generic tourism clip art.

5. **Piano**
   - Must express music and mood, not merely depict a keyboard.

6. **Road Trip**
   - Critical correction benchmark.
   - Must visibly read as vehicle / road / journey.
   - Abstract route nodes may exist only as supporting graphics.

7. **Coffee**
   - Must sell ritual / warmth / conversation / café identity.

8. **AI**
   - Hard abstract subject.
   - Must avoid generic glowing brain / circuit cliché where possible.
   - Needs a recognisable visual metaphor with collectible character.

9. **Photography**
   - Must feel like seeing / capturing / perspective, not just a camera icon.

10. **Board Games**
    - Must convey table energy, interaction and play.
    - Avoid generic dice floating in empty space.

The benchmark batch is deliberately mixed between naturally visual topics and difficult abstract topics.

---

## 16. Visual acceptance criteria

A flagship card is accepted only if all are true:

### Recognition
- Hobby can be roughly identified with the title hidden.
- Main subject is not buried under effects.

### Desire
- The card feels worth keeping.
- The artwork has a clear focal point.
- The composition feels intentional.

### Zync identity
- It looks like the same collectible universe as the other flagship cards.
- It does not feel like a random illustration placed into a template.

### Category personality
- Sports, food, travel, music, technology etc. have distinct energy.
- Category identity is more than palette swapping.

### Rarity
- Rarity is perceptible without depending only on text.
- Higher rarity does not become visual clutter.

### Finish
- Finish is a rendering treatment, not merely a label.
- Foil / Holo / Prism can be visually distinguished.

### Mobile readability
- Hobby title remains readable at realistic mobile size.
- Metadata is legible without dominating.
- Artwork still reads at thumbnail scale.

### No fake complexity
- No meaningless stats.
- No decorative metadata that implies product functionality that does not exist.

---

## 17. Copy tone

Card copy should be short, emotional and human.

Good:
- “Small rallies. Big moments.”
- “New roads, better stories.”
- “Different views make a bigger world.”
- “Simple ingredients. Extraordinary joy.”

Avoid:
- engineering language,
- database language,
- generic motivational filler,
- overly long descriptions,
- statements that sound like ad copy written by a sponsor.

Chinese localisation should preserve tone rather than translate word-for-word.

---

## 18. Product copy around a draw

Do not expose backend implementation language to players.

Avoid:
- “Result decided by Cardverse server”
- “1 Draw Token consumed”
- “Receipt”
- “Server roll ID”

Prefer:
- “你抽到一張新卡！”
- “今日嘅驚喜係……”
- “已使用 1 次抽卡機會”
- “收入 My Zync World”

The server remains authoritative internally; the UI does not need to sound like infrastructure.

---

## 19. Scale gate

Do **not** scale this art system to 3000+ cards yet.

Required sequence:

1. lock the principles,
2. create the 10 flagship benchmark cards,
3. conduct human visual review,
4. refine the art bible,
5. rebuild / review the 50-card proof batch,
6. only then design the large-scale generation pipeline.

The current 50-card visual lab is a proof/review batch, not final production art.

---

## 20. Current product decision

The concept board establishes the target feeling:

- premium,
- lively,
- aspirational,
- recognisable,
- collectible,
- coherent as a set,
- flexible enough for rarity, finish, events and brand cards.

The next card work should move away from:

**procedural graphic + palette swap + label**

toward:

**recognisable scene / subject + emotional fantasy + Zync collectible system**

That is the current Cardverse art direction for v1.

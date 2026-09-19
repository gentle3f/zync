# Zync Card Visual Spec V1

Status: **Design contract**

This spec preserves the approved visual direction from the Zync Hobby Cards concept board: premium, clean, graphic-rich cards with clear category identity and satisfying finish effects.

## 1. Design intent

Cards should feel collectible even at Normal finish.

Avoid a system where only Legendary cards look good and Common cards look like disposable placeholders.

The visual hierarchy should communicate:

1. Interest identity
2. Category / visual world
3. Edition
4. Finish
5. Collection number / metadata

Finish rarity is decorative/collectible. It never implies the hobby itself is more prestigious.

## 2. Card proportions

Primary card canvas:

- aspect ratio: 5:7
- reference export: 1000 × 1400
- mobile thumbnail: 250 × 350 or equivalent DPR-aware cache
- detail view may render vector/runtime layers above cached base art

Safe area:

- 5% outer border
- 8% title safe zone
- 10% bottom metadata safe zone

Do not put critical text under moving foil glare.

## 3. Card anatomy

Base anatomy:

- category frame
- scene / illustration area
- interest emblem or motif
- title
- optional subcategory
- stable card number
- edition seal
- finish treatment
- optional collection progress marker outside the physical card

Example:

> Badminton  
> Sports · Racket Sports  
> No. 0047  
> Core Set 1 · Holo

## 4. Visual layers

Recommended rendering stack from back to front:

1. background field
2. category pattern
3. scene grammar
4. primary motif / emblem
5. secondary motifs
6. title panel
7. metadata strip
8. edition seal
9. border treatment
10. finish shader
11. focus-only animated light sweep
12. accessibility/static replacement where needed

Base art should remain readable with all finish effects disabled.

## 5. Category kits

Initial kits:

### Sports

Visual language:

- dynamic diagonals
- court/field line abstractions
- speed arcs
- scoreboard-inspired micro-details
- bold equipment silhouettes

Examples:

- Badminton: shuttle arc + court geometry
- Basketball: hoop / ball trajectory abstraction
- Tennis: baseline grid + racket/string motif

### Outdoors

Visual language:

- layered terrain
- contour lines
- cliffs / trail cuts
- horizon depth
- natural texture without stock-photo dependency

Examples:

- Bouldering: faceted wall + chalk marks
- Hiking: layered ridge + path
- Camping: geometric tent / night-sky motif

### Food & Drink

Visual language:

- plate/bowl geometry
- menu marks
- stamp/seal motifs
- ingredient pattern
- warm material texture

Examples:

- Sushi: plate + chopstick geometry + rice/fish abstractions
- Coffee: crema rings + cup silhouette
- Cooking: utensil / steam / ingredient tiles

### Travel

Visual language:

- passport-stamp framing
- route lines
- map fragments
- ticket/boarding-pass geometry
- destination motif without copying tourism logos

Example:

- Japan: abstract torii / rail / mountain motif, not copyrighted brand imagery

### Film / Cinema

Visual language:

- cinematic crop
- frame perforation abstraction
- spotlight cone
- film-strip geometry
- dramatic depth gradient

Do not reproduce copyrighted movie posters or characters.

### Music

Visual language:

- waveform/rhythm geometry
- instrument silhouettes
- staff / note abstractions
- stage light
- groove pattern

Example:

- Piano: keys as spatial geometry rather than a flat icon-only card

### Gaming

Visual language:

- pixel / grid / neon accents
- abstract controller logic
- level/map geometry
- UI-like motifs

Do not copy game characters, logos or screenshots.

### Books / Learning

Visual language:

- layered pages
- marginalia
- bookmark shapes
- diagram / index motifs
- library-card details

### Arts / Crafts

Visual language:

- paper layers
- brush / tool marks
- cut shapes
- hand-made texture
- modular composition

### Technology

Visual language:

- circuit paths
- node graphs
- glass panels
- data-grid texture
- abstract machine geometry

### Wellness

Visual language:

- calm radial geometry
- soft breathing arcs
- balanced symmetry
- body/motion abstraction

### Nature

Visual language:

- botanical / geological motifs
- organic contouring
- weather or habitat layers

## 6. Visual families

Category kits are broad. Visual families make interests feel distinct.

Target V1 foundation:

- 12–16 category kits
- 50–100 visual families

Examples:

- sports_racket
- sports_team_ball
- sports_water
- outdoors_climbing
- outdoors_trail
- food_drink
- food_cooking
- travel_city
- travel_nature
- entertainment_cinema
- music_keys
- music_live
- gaming_strategy
- gaming_arcade
- arts_photography
- crafts_diy
- wellness_mind_body
- technology_ai

A visual family provides:

- scene grammar
- allowed motifs
- camera/composition rules
- pattern family
- border accent logic

## 7. Motif library

Do not require one bespoke illustration per interest.

Build reusable original motifs:

- equipment silhouettes
- terrain fragments
- food shapes
- instrument pieces
- travel/map marks
- media frames
- craft tools
- nature forms
- abstract symbols

Initial target:

- 100–200 core icons/emblems
- 200–400 secondary motifs/scene fragments

Expand only where the catalog audit shows weak coverage.

## 8. Finish system

### Normal

- clean border
- subtle material depth
- no moving shader
- still visually desirable

### Foil

- restrained metallic edge or selected motif foil
- slow light response on focus
- thumbnail remains static

### Holo

- localized holographic field
- iridescent movement tied to tilt/drag or timed sweep
- avoid covering title legibility

### Prism

- multi-plane refraction
- geometric light split
- stronger focus-only effect

### Legendary

- distinct frame
- richer scene depth
- controlled particle/light reveal
- unmistakable rarity treatment
- still same hobby identity

### Secret

- not just "more rainbow"
- unusual composition, seal, frame or art treatment
- extremely limited use so surprise remains meaningful

## 9. Edition treatments

### Core

Standard collection frame.

### Encounter

Real-world memory edition.

Visual treatment:

- two connection arcs meeting
- date stamp
- subtle "Discovered through a Zync" seal
- warmer memory-like accent
- no peer identity printed on card

### Discovery

Used for discovery-focused reward events.

Visual treatment:

- explorer/compass seal
- category discovery accent

### Event

Event-specific seal and optional limited scene treatment.

### Starter / Achievement

Distinct seal.

Soulbound treatment should be visible but not framed as inferior.

## 10. Color policy

Do not hard-code every hobby to one color.

Use deterministic palettes chosen from a category-safe palette bank.

A visual seed may select:

- primary field
- secondary accent
- motif contrast
- border material

Finish shader color sits above the palette rather than replacing it.

Accessibility:

- title contrast must remain WCAG-readable
- do not rely on color alone to communicate finish
- finish icon/text remains available

## 11. Typography

Use licensed/open fonts already approved for the app.

Requirements:

- strong title readability at thumbnail size
- Traditional and Simplified Chinese support
- no language-specific font swap that changes card geometry unpredictably
- reserve title bounds for long localized labels

If a translated title is too long:

1. slightly reduce title size within bounded range
2. allow two lines where detail layout supports it
3. never alter the visual seed or scene because of title language

## 12. Proper names and IP-sensitive interests

For:

- films
- TV series
- games
- brands
- celebrities/artists
- copyrighted franchises

Use:

- text label
- abstract category/genre artwork
- original generic motifs

Do not automatically reproduce:

- logos
- character art
- posters
- screenshots
- album covers

unless rights/licensing are explicitly established.

## 13. Pack reveal effect tiers

The result is committed before animation.

Suggested reveal language:

### Normal

- standard flip
- light haptic tick

### Foil

- edge light sweep
- slightly richer haptic

### Holo

- short shimmer hold
- colored refraction
- distinct haptic/sound cue

### Prism

- screen focus
- multi-angle refraction
- particles used sparingly

### Legendary

Example pacing:

- 0 ms: pack tap
- 100 ms: pack compress
- 250 ms: small haptic
- 400 ms: short silence
- 550 ms: edge sparkle clue
- 750 ms: rising sound
- 1050 ms: reveal burst
- 1080 ms: heavy haptic
- 1300 ms: silhouette
- 1800 ms: card reveal
- 1900 ms: holo sweep
- 2200 ms: rarity sting

Rare effects must remain rare.

Do not show deceptive "almost won" animation.

A genuine upgrade animation is allowed only when the already-committed result actually contains the higher finish.

## 14. Missing-card curiosity

Binder may show silhouettes such as:

> Racket Sports · 11 / 12

This is preferred over countdown/FOMO pressure.

No punitive streak loss.

## 15. Performance

Grid thumbnails:

- no continuous shader animation
- pre-render/cached base art
- low-cost static finish indicator

Focused card/detail:

- enable shader/light response
- limit concurrent animated cards

Pack reveal:

- one active hero card at a time
- pre-warm required shader/assets before reveal

## 16. Accessibility

Required:

- Reduce Motion mode
- static finish alternative
- audio toggle
- haptic toggle
- no high-frequency flashing
- text remains readable without foil
- finish communicated by icon/text as well as visual effect

## 17. Quality bar

Before mass-generation approval, generate a review set across:

- 12+ categories
- short and long English labels
- Traditional Chinese
- Simplified Chinese
- generic hobbies
- proper-name interests
- Normal / Holo / Legendary / Encounter

The review set must prove the system does not look like 3,000 text labels pasted onto one template.

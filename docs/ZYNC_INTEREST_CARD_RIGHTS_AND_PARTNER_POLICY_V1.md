# Zync Interest → Card Rights & Partner Policy V1

## Core separation
**Being an Interest does not automatically mean Zync generates a Card for it.**

Named brands, artists, films, TV shows, games, books and franchises can remain searchable and matchable while the official collectible layer is reserved for licensed partnerships.

## Policies
- `originalGeneric`: original Zync artwork is allowed for generic concepts such as Badminton, Camping, Cinema, Jazz, RPGs, Thrifting and Meditation.
- `abstractOnly`: deliberately abstract/non-identifying treatment where product design explicitly chooses it.
- `licensedOnly`: baseline artwork is blocked; official collectible artwork requires the relevant brand/rightsholder approval.
- `notCollectible`: product-level decision that a concept should not have a Cardverse collectible.

## Partner-first examples
`licensedOnly` includes:
- car brands
- named music artists
- named films / TV / anime
- game franchises / titles
- named board games / TTRPG systems
- named book titles
- platform brands such as YouTube
- LEGO
- Formula 1

This lets Zync build fan affinity and matching demand before a partnership without giving away an unofficial official-looking card.

## Proxy principle
A licensed-only interest may still influence generic experiences:
- Porsche → Cars / Road Trips / Motorsport
- named artist → Music / Concerts / relevant generic genre
- named game → Video Gaming / generic genre
- named film → Cinema / generic genre
- named board game → Tabletop Gaming

The proxy must not impersonate an official branded collectible.

## Random-event implication
Social, wellness, lifestyle, food, outdoors, arts/crafts, sports and travel concepts are especially valuable because they can turn into real-world suggestions.

Health-adjacent and age-sensitive concepts remain conservative:
- alcohol-related nightlife is not auto-suggested
- nutrition/massage/aromatherapy are matchable but not auto-prescribed
- higher-risk activities still require explicit reviewed activity metadata

## Runtime implementation
`mobile/lib/core/interest_card_policy_resolver.dart`

No card-art generation job should include an interest unless `baselineArtEligible == true`, or a licensed partner override has been explicitly approved.

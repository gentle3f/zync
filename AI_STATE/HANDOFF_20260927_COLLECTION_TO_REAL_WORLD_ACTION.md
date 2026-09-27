# Zync V1 — Collection to Real-World Action

Date: 2026-09-27 HKT
Branch: `card-art-pilot-v1-20260921`
Parent before this round: `d0dcfa1`

## Goal

Give the player a concrete reason to care about a collected card beyond owning it:
a card can now become the starting point for the next real-world Zync activity.

The product loop now has a direct continuation:

`collect card -> open card detail -> choose to do something with that interest
-> Zync Now -> real-world activity -> pending move in My Zync World`.

## Collection card -> Zync Now

For a collection card whose canonical interest is activity-eligible, the production
My Zync World card-detail sheet now exposes:

- "Find something to do with this"
- Traditional Chinese: "用呢個興趣搵件事做"

Tapping it opens Zync Now with that card's canonical interest as a **soft focus**.

If the card interest was not already in Interest DNA, it is first added as
`Want to Try`. Existing `Like` / `Love` is never downgraded or overwritten.

Interests that are not activity-eligible do not receive the CTA.

## Soft focus, never a rule override

`ZyncNowEngine.generate` now accepts an optional `preferredInterestId`.

For a viable, non-repeated candidate:
- exact single-interest candidate: +18 soft score;
- crossover containing that interest: +12 soft score.

The preferred interest is considered only **after** ordinary eligibility and
constraint checks. It cannot revive a candidate removed by:
- private hard veto;
- shared hard veto;
- cost / time / energy / setting constraints;
- activity eligibility rules.

A recent-repeat candidate receives no preferred boost, so collection focus cannot
defeat the existing repeat-avoidance behavior.

Existing callers omit the field and retain prior behavior.

## Zync Now UI

A card-focused Zync Now lobby clearly explains the behavior:

"Starting from <interest>"

"Zync will favor this interest when it fits everyone. Private limits and hard
vetoes still win."

The focus is passed through the room coordinator into finalist scoring and is
preserved if a soft-preference relaxation is explicitly retried.

## Participant continuity hardening

This round also added screen-level tests for the previous first-journey checkpoint.

Both standalone Zync Now and Group Zync participant result screens are verified to:
- reconstruct the chosen privacy-bounded activity recipe;
- persist exactly one pending local activity despite continued polling;
- return a positive continuation signal toward My Zync World.

No participant identity, ballot, or private constraint is written into local
activity memory.

## Validation

Focused collection / World / Zync Now regression set: **36 / 36 PASS**.

Canonical full non-golden mobile suite: **349 / 349 PASS**.

Full `flutter analyze`: **No issues found**.

`git diff --check`: clean before this handoff write.

The known missing `goldens/card_art_engine_v1_flagships.png` baseline remains
intentionally excluded. Do not synthesize it merely to make the literal golden
suite green.

## Manual review limitation

A main-app real-browser review was attempted locally, but the existing local
Card FX web server already occupied port 7357 and the separate main-app
web-server process did not persist through the local MCP shell session.

Therefore this checkpoint establishes technical behavior through tests and static
analysis only. It does **not** claim that the new card-detail CTA or focused lobby
has been subjectively approved on a real device/browser.

## Guardrails preserved

No Cardverse economy authority, quest reward authority, server receipt contents,
pack RNG, rarity/finish logic, Card FX B Split Open behavior, accepted Card FX
audio, backend schema, Vercel, Production, Play, release, GitHub Actions or paid
generation changed.

The pre-existing untracked:
- `mobile/lib/l10n/generated/`
- `mobile/pubspec.lock`

remain untouched and must not be staged.

## Continuation

The next high-value gate is a real-device review of the complete "card becomes
something I can actually do" flow, ideally with two devices:

`card detail -> focused Zync Now lobby -> private constraints -> finalist vote
-> chosen activity -> both devices' My Zync World`.

Only tune the soft-focus strength or CTA wording if that review exposes a concrete
product issue. Do not turn card focus into a hard constraint.

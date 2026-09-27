# Zync V1 — My Zync World Hub + Single Draw Reveal

Date: 2026-09-27 HKT
Branch: `card-art-pilot-v1-20260921`
Parent before this round: `39fbcd3`

## Product direction

Do not return to Card FX micro-polish without fresh user feedback. This round
continued the larger player loop:

`choose something real -> do it -> progress -> reward -> reveal -> collect ->
choose the next real thing`.

## My Zync World is now the central continuation hub

A new canonical `LocalStore.loadPendingZyncNowActivity()` returns the newest
still-chosen real-world activity while ignoring completed/skipped memories.
Standalone Zync Now now uses the same helper instead of duplicating lookup logic.

My Zync World loads that pending activity with local achievement/quest state and
surfaces it directly beneath the World hero, even when Cardverse is signed out or
temporarily unavailable.

When an activity is pending, the hub shows:
- the reconstructed localized activity title/instruction;
- participant count and Pending state;
- “Yes, we did it” / “Not yet” / “We skipped it”.

“Yes, we did it” records the existing privacy-bounded Tried Together progress
event, computes the existing quest before/after delta, shows explicit progress,
and can open Curiosity Board for a real server-validated reward claim. Returning
to My Zync World reloads inventory so a newly granted Draw Token or pack appears.
“Not yet” leaves the chosen memory pending. “We skipped it” removes it from the
next-action slot without minting progress.

## The loop now points outward again

When no activity is pending, the same high-priority slot becomes:

“Next step: leave the screen” -> “Find something to do”.

That launches Zync Now from My Zync World. When the player comes back, the World
reloads and the chosen activity becomes the pending next real-world move. This
makes collection/progression lead back into a real activity instead of becoming
an in-app dead end.

## Single-card Draw reveal upgraded

The server-authoritative Draw Token flow is unchanged: the server redeems the
token and returns the immutable `CardverseSingleDrawReceipt` before any reveal.

The old modal exposed the card immediately. It now uses a reusable production
single-draw reveal sheet:
- starts on the accepted Z card back;
- hides card title/finish until the player taps Reveal;
- uses existing finish-aware suspense timing;
- reveals the actual receipt interest through the existing scalable
  `ZyncCardPreview` recipe, never a Card FX lab sample artwork;
- motion-enabled flow uses the accepted card-flip -> shared reward bloom ->
  rarity payoff sensory family;
- Reduce Motion removes suspense/audio/haptic without changing the result;
- “Add to collection” closes the reveal, then My Zync World reloads inventory.

Finish-to-sensory mapping remains presentation-only:
Normal -> Common, Foil -> Uncommon, Holo -> Rare, Prism -> Epic,
Legendary/Secret -> Legendary.

## Validation

- focused pending-memory / quest / World hub tests: PASS;
- focused single-draw / pack reveal regression tests: PASS;
- canonical full non-golden mobile suite: **340 / 340 PASS**;
- full `flutter analyze`: **No issues found**;
- `git diff --check`: clean before handoff write.

The known missing `goldens/card_art_engine_v1_flagships.png` baseline remains
intentionally excluded. Do not synthesize/update it just to make the literal
golden suite green.

## Guardrails preserved

No economy authority, RNG, server receipt contents, card order, finish, edition,
quantity, quest reward rules, B Split Open threshold, hidden-omen probability,
locked frame masters, backend schema, Vercel, Production, Play, release,
GitHub Actions or paid generation was changed.

The pre-existing untracked:
- `mobile/lib/l10n/generated/`
- `mobile/pubspec.lock`

remain untouched and must not be staged.

## Best next product work

The next high-value gap is first-run comprehension. The mechanics now form a
real loop, but onboarding still mainly teaches interests/connection rather than
the product promise that makes Zync distinct:

`meet / choose -> leave the screen -> actually do something -> come back ->
earn/reveal/collect -> choose what to try next`.

Next work should teach that loop with minimal copy/steps and avoid turning
onboarding into a game tutorial. Group Zync can also benefit from a clearer
handoff telling the group that its chosen Zync Now activity is now waiting in
My Zync World, but central pending-state recovery is already functional.

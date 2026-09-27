# Zync V1 — Core Loop Bridge

Date: 2026-09-27 HKT
Branch: `card-art-pilot-v1-20260921`
Parent before this round: `8937186`

## Why this round

Card FX audio is now an acceptable baseline. The work deliberately stepped back
from micro-polish and audited the player loop instead:

`real-world Zync -> confirm activity -> quest progress -> server reward ->
My Zync World -> open pack -> collection -> next goal`.

Most primitives already existed, but they were not connected strongly enough
for a player to feel one continuous loop.

## Real-world activity -> quest/reward bridge

Standalone Zync Now already stored a chosen activity and later asked whether the
player actually did it. Completing that follow-up already created a local
`triedTogetherCompleted` progress event.

This round adds `ZyncQuestBoardDelta` so the app can compare quest snapshots
before/after one real-world completion without inventing economy state.

After “Yes, we did it” the host now:
- records the completion as before;
- computes how many quests advanced and newly completed;
- shows an explicit “You did it. It counts.” progression sheet;
- offers a direct Curiosity Board CTA;
- if a real server reward is claimed, returns through the navigation stack and
  opens My Zync World immediately.

`QuestBoardScreen` gained opt-in `returnOnClaim`; default callers are unchanged.
The reward remains server-issued and server-validated. Local quest progress never
mints inventory by itself.

## Production pack now uses B — Split Open

The live My Zync World pack path already asks the Cardverse server to open the
pack first and receives an immutable receipt. That authority is unchanged.

For `labMode:false`, the old static sealed-pack intro is now replaced by the
accepted B — Split Open wrapper interaction. It uses a neutral Common wrapper
profile so the wrapper does not leak the best receipt finish or hidden rarity.

`ZyncPackOpeningStage` gained an opt-in wrapper-only mode:
- default remains the existing FX Lab behavior;
- `revealCard:false` finishes physical extraction, then invokes `onOpened`;
- the production screen then hands off to the existing five-card receipt reveal.

This means B is now part of the real server-receipt pack path, not only a lab.

## Receipt reveal sensory integration

The immutable five-card reveal still uses the existing Cardverse recipe/finish
renderer, so it never substitutes the three Card FX sample artworks.
On each actual receipt-card reveal, motion-enabled playback now uses the accepted
sound language:
- selected card-flip sample;
- shared reward bloom;
- rarity payoff 120 ms later.

Finish mapping for sensory only:
Normal -> Common, Foil -> Uncommon, Holo -> Rare, Prism -> Epic,
Legendary/Secret -> Legendary.

Card order, finish, edition, quantities, receipt ID and server RNG are untouched.
Reduce Motion continues to suppress suspense/haptic/audio behavior.

Production recap now has an explicit “Back to My Zync World” button. Returning
lets the existing caller reload inventory so the newly opened cards are visible.

## Validation

- focused activity/quest/reward/navigation tests: 41/41 PASS.
- focused production-pack + Card FX regression tests: 11/11 PASS.
- canonical full non-golden mobile suite: 335/335 PASS.
- full `flutter analyze`: No issues found.
- `git diff --check`: clean before handoff write.

The literal golden suite remains intentionally excluded because the known
`goldens/card_art_engine_v1_flagships.png` baseline is absent. Do not synthesize
that baseline simply to turn the suite green.
## Next product gaps after this bridge

The highest-value remaining loop gaps are now clearer:

1. Group Zync can choose a Zync Now activity and stores the same pending memory,
   but the group result screen does not itself provide the later “Did it?” /
   reward feedback loop. The pending activity can surface through standalone
   Zync Now, but that is indirect.
2. My Zync World does not yet surface a pending chosen real-world activity as a
   central next-action card.
3. Single-card Draw uses a simpler modal reveal rather than the accepted Card FX
   reveal language.
4. First-time onboarding teaches interests and connection, but not yet the full
   “go do something -> earn -> open -> collect -> choose next thing” loop.
5. Collection has real cloud inventory and Want to Try bridging, but the player’s
   strongest “what should I do next?” progression prompt still needs product work.

Do not go back to Card FX micro-polish unless fresh player feedback identifies a
specific issue. The next sprint should continue closing the player loop rather
than expanding card-art volume.

## Guardrails

No economy, RNG, server receipt, hidden-omen probability, B 70% commit threshold,
locked frame master, card-art generation, backend schema, Vercel, Production,
Play, release, GitHub Actions or paid generation change was made.

The pre-existing untracked `mobile/lib/l10n/generated/` and
`mobile/pubspec.lock` remain untouched and must not be staged.

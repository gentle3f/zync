# Zync — Reward Reveal Turn Animation + Rarity SFX Reconnected

Date: 2026-09-28
Branch: `card-art-pilot-v1-20260921`
Starting HEAD: `caaca4f`

## User-reported regression

The formal reward cards were rendering, but both reveal flows had lost the accepted Card FX reveal language:

- Single Draw swapped from back to front without the tested 3D turn and the user heard no flip/rarity payoff.
- Five-card Pack reveal also replaced each card directly, so each receipt card lacked the tested turn and rarity SFX sequence.

The B — Split Open wrapper itself was not the problem and was intentionally left unchanged.

## Root cause

The formal `CardverseRewardCard` renderer had been connected directly to Single Draw and Pack result surfaces, bypassing `ZyncFxRevealStage`.

The accepted reveal stage still contained the complete tested sequence:

`card back -> 3D Y turn -> front -> reward bloom -> rarity hit -> Legendary finale haptic`

with the accepted Pixabay flip/bloom/Common–Legendary sound family, but the production reward flows no longer routed through it.

## Implementation

### Shared reveal stage

`mobile/lib/card_fx/zync_fx_reveal.dart`

`ZyncFxRevealStage` now accepts:

- `frontCard` — optional production card face while preserving the existing FX lab default.
- `onRevealComplete` — completion hook for advancing the owning flow after the full reveal timeline.

The stage still owns the accepted sensory timeline:

- `cardFlip`
- `rewardBloom`
- `rarityHit`
- Legendary finale haptic path

A deterministic completion timer follows the same 2.4 s reveal timeline so outer UI state reliably settles after the animation. Cue timers and completion timer are all cancelled together on replay/dispose.

### Single Draw

`mobile/lib/widgets/cardverse_single_draw_reveal.dart`

Single Draw now:

1. starts on the real Z card back,
2. primes browser audio synchronously from the Reveal button gesture,
3. inserts `ZyncFxRevealStage`,
4. performs the tested 3D turn,
5. shows the formal locked-frame `CardverseRewardCard` as the reveal-stage front,
6. plays flip -> bloom -> rarity payoff,
7. settles to the same formal card and enables the collection/close action only when the reveal timeline completes.

No booster wrapper is introduced.

### Five-card Pack reveal

`mobile/lib/screens/cardverse_pack_opening_lab_screen.dart`

Each receipt card now gets its own active reveal state:

- pressing Reveal primes browser audio on the real user gesture,
- the top card is represented by `ZyncFxRevealStage`,
- remaining face-down backs stay physically behind it,
- the receipt cursor advances only after the reveal timeline completes,
- the newly revealed formal card then remains settled on top until the player reveals the next one.

This restores the same turn + rarity sensory language for all five cards rather than directly replacing the stack with a front card.

The outer reveal-page key is stable across receipt advancement so the page no longer cross-fades an outgoing and incoming copy of the same revealed card.

### Unchanged

- B — Split Open wrapper mechanics and accepted wrapper audio
- five-card immutable receipt order
- card rarity/finish mapping
- RNG/economy/backend authority
- locked 1024x1536 rarity frames
- Cardverse formal reward renderer
- recap layout
- Z card-back optical centering
- Reduce Motion behavior
- no paid generation / Vercel / Production / Play / GitHub Actions work

## Regression coverage

Tests now explicitly verify:

- Single Draw inserts `ZyncFxRevealStage` after Reveal.
- Single Draw settles to the formal locked-frame result after the full reveal timeline.
- Pack individual reveal inserts `ZyncFxRevealStage`.
- Pack reveal passes the receipt card's actual rarity into the stage (e.g. Foil -> Uncommon).
- Pack advances from 1/5 to 2/5 only after the reveal finishes.
- Existing Reduce Motion five-card flow still reaches recap.
- Existing B Split Open stack/extraction coverage still passes.

## Validation

- Focused Single Draw / Pack / Card FX / Reward Lab suite:
  **16/16 PASS**
- Expanded card rendering:
  **2/2 PASS**
- Targeted Flutter analyze over changed implementation/tests:
  **No issues found**
- `git diff --check`:
  **clean**

Pre-existing untracked local items remain untouched:

- `mobile/lib/l10n/generated/`
- `mobile/pubspec.lock`

## Next review gate

Use the local Reward Reveal Lab to subjectively verify:

1. Single Draw visibly turns the card rather than swapping it.
2. Single Draw has audible flip/bloom/rarity payoff.
3. Each of the five Pack cards visibly turns individually.
4. Each Pack card plays the appropriate rarity payoff, including the stronger Legendary payoff.

No subjective approval is claimed until the user tests the live browser build.

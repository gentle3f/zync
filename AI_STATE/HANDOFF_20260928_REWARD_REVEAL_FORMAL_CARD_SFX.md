# Zync — Reward Reveal Formal Card Presentation + Single Draw SFX

Date: 2026-09-28
Branch: `card-art-pilot-v1-20260921`
Starting HEAD: `7ef5143` (Add reward reveal lab and Google auth diagnostics)

## Goal completed

Follow-up to the Reward Reveal Test Lab feedback:

1. The card-back Z mark needed real optical centering.
2. Single Draw, Pack sequential reveal and Pack recap must stop showing the old full-card procedural proof/fallback presentation and use the accepted production card language.
3. Single Draw needed audible SFX in Chrome, while preserving the accepted Pack/B Split Open audio and all immutable receipt/economy semantics.

## Implementation

### Formal reward-card renderer

Added `mobile/lib/widgets/cardverse_reward_card.dart`.

`CardverseRewardCard` is now the production-facing renderer for reward reveals. It always uses `ZyncFxCard` and the locked 1024x1536 rarity frame master selected through `ZyncFrameAssets`.

- Accepted bundled artwork is used directly where available:
  - `books.reading` -> `assets/card_fx/art/reading.jpg`
  - `technology.ai` -> `assets/card_fx/art/ai.jpg`
  - `food.coffee` -> `assets/card_fx/art/coffee.jpg`
- For other canonical interests, the existing semantic recipe is rendered only inside the artwork window through `ZyncCardArtwork`.
- The old `ZyncCardPreview` full-card procedural mockup is no longer used by Single Draw, Pack sequential reveal, or Pack recap.
- Unknown/no-recipe interests fail visually to a neutral artwork-window treatment inside the locked frame rather than reverting to the old mock card.

`ZyncFxCard` gained an optional `artworkOverride`; its default/null path is unchanged.

`ZyncCardArtwork` was factored out of the existing scalable recipe painter so semantic fallback art can live inside the locked production frame.

### Single Draw

`cardverse_single_draw_reveal.dart` now renders `CardverseRewardCard` for the immutable receipt result.

Single Draw now primes browser audio from the actual Reveal button activation via:
- `ZyncFxSensoryEvent.singleRevealStart`
- `ZyncFxSensory.playFromUserGesture(...)`

The first anticipation sound is invoked before the suspense `await`, avoiding Chrome treating the later reveal timeline as media started without user activation. Existing card flip -> reward bloom -> rarity payoff cues remain unchanged after suspense.

Reduce Motion still suppresses suspense/audio/haptics.

### Pack reveal + recap

`cardverse_pack_opening_lab_screen.dart` now uses `CardverseRewardCard` for:
- the currently revealed receipt card,
- all five recap cards.

The physical B — Split Open wrapper, first-split stack visibility, 70% extraction threshold, card-back stack, receipt order, RNG/economy/backend semantics and accepted wrapper SFX were not changed.

Formal card geometry is now 2:3, matching the locked 1024x1536 frame masters.

### Reward Reveal Test Lab proof content

The dedicated local reward lab uses bundled accepted artwork for its direct visual proof:
- Single Draw: `technology.ai`
- Five-card pack proof: Reading / Coffee / AI with varied finish tiers

This changes only the immutable local proof receipts used by the test lab; it does not change server reward logic or production receipt semantics.

### Card-back Z

`ZyncFxCardBack` keeps the existing italic Z but applies a -4 px X optical correction plus explicit line-height 1. A stable `card-back-z-optical-center` key protects this adjustment in regression coverage.

## Regression coverage

Reward tests now explicitly assert:
- Single Draw starts face-down.
- Single Draw contains no pack wrapper/stack.
- revealed Single Draw uses `cardverse-formal-card-*` and `ZyncFxCard`.
- correct locked rarity frame asset is selected.
- semantic fallback is artwork-window-only and no `ZyncCardPreview` full-card fallback is present.
- card-back Z has the -4 px optical correction.
- focused Pack reveal uses the formal locked-frame renderer.
- five-card recap contains five `ZyncFxCard` formal cards and no `ZyncCardPreview`.

## Validation

Current working tree validation:

- Focused reward / pack / Card FX / Reward Lab suite:
  -> **15/15 PASS**

- Broader adjacent reward/collection/World regression set:
  `reward_reveal_test_screen + single_draw + pack_opening + card_fx + pack_reveal + collection_lab + my_zync_world_pending_activity`
  -> **30/30 PASS**

- Expanded scalable card rendering:
  `flutter test --no-pub test/cardverse_expanded_render_test.dart`
  -> **2/2 PASS**

- Targeted analysis over all changed implementation + regression files:
  -> **No issues found**

- Browser-served Single Draw anticipation asset:
  `pixabay_anticipation_twinkle_244951.mp3`
  -> **HTTP 200, 90,624 bytes** from the running Reward Reveal Lab

- `git diff --check`
  -> clean

A separate attempt to run `card_art_engine_golden_test.dart` cannot compare because its repository baseline file `goldens/card_art_engine_v1_flagships.png` is absent. The non-golden expanded render tests pass. No `--update-goldens` was used and no fake baseline was created.

## Automation / release safety

Pre-commit audit confirms:
- push-triggered mobile workflows remain scoped to `zync-v1-rebuild-20260917`, not this branch.
- `vercel.json` keeps `card-art-pilot-v1-20260921` deployment disabled.
- no GitHub Actions, Vercel, Production, Play, backend/economy, paid generation, RNG, rarity or receipt-authority changes were made.

Pre-existing local untracked items remain intentionally outside this checkpoint:
- `mobile/lib/l10n/generated/`
- `mobile/pubspec.lock`

## Next review gate

Use the local Reward Reveal Lab for subjective browser review of:
1. Z optical centering,
2. formal card look in Single Draw,
3. formal card look through all five Pack reveals and recap,
4. audible Single Draw start/flip/bloom/payoff sequence.

No claim of subjective visual/audio approval is made until that live review.

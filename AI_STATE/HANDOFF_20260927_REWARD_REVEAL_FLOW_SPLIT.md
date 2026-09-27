# Zync V1 — Production Reward Reveal Flow Split

Date: 2026-09-27 HKT
Branch: `card-art-pilot-v1-20260921`
Parent before this round: `a034a4f`

## Product decision now encoded

Production reward reveal is explicitly separated into two experiences:

1. **Single Draw = 1 card**
2. **Pack Opening = 5 cards**

The server-authoritative reward result still exists before presentation. This round changes only presentation plumbing and focused regression coverage.

## Single Draw

Single Draw remains the dedicated production 1-card bottom-sheet flow in
`cardverse_single_draw_reveal.dart`.

It does **not** use `ZyncPackOpeningStage`, a booster wrapper, Split Open, or a card stack. The flow remains:

`one card back -> player taps Reveal -> suspense -> flip -> shared bloom -> rarity payoff -> real receipt card front`

The immutable `CardverseSingleDrawReceipt`, draw-token redemption, idempotency,
server authority and collection reload behavior are unchanged.

A focused regression now explicitly proves the Single Draw surface contains none of:
- production pack wrapper;
- 5-card extraction stack;
- pack sequential-reveal stack.

## Pack Opening

Production pack opening remains B — Split Open, but the physical payload is now
correctly represented as a **card stack** rather than one card.

`ZyncPackOpeningStage` gained a pack-only `cardStackCount` presentation input,
defaulting to 1 so the existing Card FX A/B/C/D reference lab behavior is unchanged.
The production receipt path passes the actual immutable receipt item count
(currently five).

For a five-card pack:
- once the center foil has physically separated, the clipped cavity contains five
  layered `ZyncFxCardBack` surfaces;
- the rear cards are vertically/depth offset so multiple card edges are visible
  through the split instead of reading as one card;
- the existing B split threshold and physical clip stay unchanged;
- the regression checks an actual ~14% B pull, just beyond the existing 12% foil
  separation threshold, and confirms a >10px visible gap while all five stack
  layers are present;
- the unchanged 70% commit threshold starts extraction;
- extraction carries the full stack and reports `DRAWING STACK` rather than
  `DRAWING CARD`;
- after extraction, the receipt reveal screen keeps a visible remaining face-down
  stack behind the active card, then consumes that stack one card at a time;
- after card 5, the existing five-card recap remains the terminal screen.

The actual revealed fronts still come from the immutable
`CardversePackOpenReceipt` and the existing scalable `ZyncCardPreview` recipe.
No Card FX sample art is substituted into production.

## Shared sensory / motion behavior

Existing accepted sensory behavior is preserved:
- B wrapper sounds and split timing unchanged;
- card flip -> shared reward bloom -> rarity payoff unchanged;
- hidden omen behavior unchanged;
- Reduce Motion semantics unchanged.

No audio source, gain, timing, locked frame master or rarity mapping was retuned.

## Focused validation

- `flutter test test/cardverse_single_draw_reveal_test.dart test/cardverse_pack_opening_lab_test.dart test/card_fx_lab_test.dart`
  -> **12 / 12 PASS**
- targeted `flutter analyze` across the changed production/reveal files and tests
  -> **No issues found**
- `git diff --check` -> clean

The test suite now specifically covers:
- Single Draw is one-card-only and has no wrapper/pack stack;
- production B exposes the five-card stack at the first real split;
- full-stack extraction precedes receipt reveal;
- five cards reveal sequentially;
- the remaining face-down stack decreases after each reveal;
- recap still contains the immutable five-card receipt result.

## Guardrails preserved

No changes to:
- economy;
- backend schema;
- server authority;
- RNG;
- rarity logic;
- Cardverse receipt semantics/order;
- B 70% commit threshold;
- hidden-omen probability;
- reduced-motion behavior;
- locked card frames/masters;
- onboarding / My Zync World unrelated work;
- GitHub Actions;
- Vercel / Production / Play / release;
- paid generation.

Push-triggered GitHub workflows were audited before repository writes: the current
branch is not included in their push branch filters. Vercel remains disabled for
this branch per the prior authoritative Card FX checkpoint.

The pre-existing untracked:
- `mobile/lib/l10n/generated/`
- `mobile/pubspec.lock`

remain untouched and must not be staged.

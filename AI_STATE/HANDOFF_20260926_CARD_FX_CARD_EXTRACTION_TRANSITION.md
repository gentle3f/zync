# Zync Card FX — Wrapper-to-Card Extraction Transition Complete

Date: 2026-09-26 HKT
Branch: `card-art-pilot-v1-20260921`
Parent before this round: `fcd1f1b`

## Scope completed

The next shared Card FX step is now implemented without choosing between
A/B/C/D: the wrapper-opening flow now has a physical card-extraction bridge
before the existing reveal animation.

Previously the sequence was effectively:
wrapper gesture -> wrapper disappears -> card-back/reveal stage.

It is now:
wrapper gesture -> wrapper is visibly open -> card back physically rises out
from behind the wrapper -> wrapper drops/slides away -> existing card-back flip
continues into the preserved reveal animation.

This work is shared by all four opening prototypes, so it does not bias the
user's later A/B/C/D comparison.
## Technical behavior

- Added a dedicated extraction AnimationController in ZyncPackOpeningStage.
- Extraction begins only after the existing rarity/omen opening delay.
- The real card back is absent before extraction; a keyed
  `opening-card-extraction-back` appears only after the opening has committed.
- The card back rises from below/behind the wrapper and settles at the exact
  visual scale/position used by the reveal stage at reveal progress 0.22.
- The wrapper remains visually in front while moving downward/outward; it only
  fades late in the extraction, preventing wrapper print from ghosting over the
  card back.
- B and C retain their split/burst wrapper remnants around the emerging card.
- D unlocks first, then the card is drawn while the sleeve/wrapper leaves.
- A retains the torn top-seal state before the card emerges.

The shared reveal component now exports `ZyncFxCardBack` so the opening and
reveal stages use the exact same card-back visual, not a duplicated imitation.
## Reveal continuity

ZyncFxRevealStage gained an optional `startFromSettledBack` flag.

- Direct reveal mode keeps the original entrance exactly as before.
- Pack-opening flow sets `startFromSettledBack=true`.
- In that mode the reveal controller starts at progress 0.22, the point where
  the original card-back entrance is already settled.
- Flip and Legendary haptic timer offsets are recomputed from that start point,
  so extraction replaces the old entrance rather than replaying it.

This removes the visual jump/re-entry that would otherwise happen after the
card was already drawn from the wrapper.

## Preserved behavior

Unchanged:
- A Tear Up / B Split Open / C Charge Burst / D Seal Slide mechanics;
- all four prototypes remain available for user + wife comparison;
- rarity outcomes, energy profiles and reveal timing logic;
- Legendary hidden omen (~1/7), Epic near-miss (~1/20);
- Lab-only reduced-motion override;
- accepted lower-right icon geometry/position;
- locked 1024x1536 PNG masters;
- production draw/result/RNG/backend;
- card-art generation pipeline.

## QA / real-browser review

- `flutter test test/card_fx_lab_test.dart` -> 4/4 PASS.
- Targeted `flutter analyze` across opening/reveal/card/screen/test ->
  No issues found.
- Widget test now explicitly verifies that the extraction card-back key is
  absent before opening and present only after the wrapper-opening delay.
- Real Flutter Chrome was hot-restarted and A/B/C/D were each exercised.
- Browser review found an initial transparency-ghost issue where wrapper print
  could overlay the emerging card; this was corrected by keeping the wrapper
  substantially opaque while physically translating it downward, then fading
  only late in extraction.
- Final Chrome review showed no wrapper-print ghosting on the card back.
- B/C retain visible foil remnants during extraction; A/D transition cleanly
  into the common extracted card back.
- `git diff --check` was clean before checkpointing.
- Locked frame asset diff remained empty.

## Infrastructure guardrails

No paid generation, GitHub Actions, Vercel, release or deployment was used.
Do not create a PR or invoke CI solely for Card FX comparison work.

## Next decision

The user has not yet tested the new true-wrapper flow. Keep all four opening
prototypes and this shared extraction transition intact until the user and his
wife compare them.

A sensible later shared polish step, without choosing a mechanic, is audio /
haptic cue design around seal break, card extraction, flip and rarity hit.

# Zync Card FX — Reveal No-Response Root Cause Fixed

Date: 2026-09-26 HKT
Branch: `card-art-pilot-v1-20260921`
Parent before this fix: `1b7c3c8`

## Root cause

The user's real visible Chrome session still showed no reveal/replay animation even
though button events and AnimationController calls were firing.

Runtime instrumentation on that exact Flutter session proved:
`MediaQuery.disableAnimations == true`.

The reveal code therefore deliberately jumped the controller straight to its
final frame. This exactly explains the user's symptom: drag tilt still worked,
while reveal/replay and ambient auto-animation appeared completely dead.

Chrome's CSS `prefers-reduced-motion` query was false, so this flag came from
Flutter/Windows accessibility state rather than the ordinary browser media
query.

## Fix

Production behavior still respects reduced-motion accessibility by default.
The isolated Card FX Lab now explicitly sets `respectReduceMotion: false` for
both inspect cards and reveal stages, so OS accessibility state cannot silently
disable the FX preview.
The same override is propagated into the card rendered inside the reveal stage,
so foil/steam/surface animation are also testable in the Lab.

Reveal UX was also made deliberately more visible:
- removed AnimatedSwitcher crossfade masking
- duration increased to 2400ms in the Lab path
- longer card-back hold / entrance
- stronger 3D flip and settle
- visible rarity flash / halo

The earlier steam refinement remains: short soft drifting/fading wisps instead
of three fixed opaque curly lines.

## Regression protection

The Card FX widget test now runs under a forced
`MediaQuery.disableAnimations=true` host and asserts the Z card back is still
visible 250ms after Draw Reveal. This directly guards the real failure mode.

QA:
- `flutter test test/card_fx_lab_test.dart` -> 4/4 PASS
- targeted `flutter analyze` -> No issues found

Do not remove the Lab override unless the preview gets an explicit motion-mode
control. Production defaults should continue respecting accessibility settings.

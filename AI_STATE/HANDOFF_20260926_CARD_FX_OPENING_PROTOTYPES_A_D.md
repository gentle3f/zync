# Zync Card FX — Opening Prototypes A–D Complete

Date: 2026-09-26 HKT
Branch: `card-art-pilot-v1-20260921`
Parent before this round: `4031b2b`

## Scope completed

The Card FX Lab now has a playable pack-opening comparison flow so the user and
his wife can compare four interaction mechanics under the same card/result:

- A — Tear Up: drag upward to tear the top seal.
- B — Split Open: drag sideways to split the foil pack from the middle.
- C — Charge Burst: press and hold to charge, release to burst open.
- D — Seal Slide: drag the seal tab downward to unlock.

All four feed into the existing preserved-motion card-back -> reveal animation.

## Pack-choice ritual

Entering Open pack now presents three visually similar packs with gentle
roulette-like bob/rotation. The user chooses one before performing the selected
gesture. The card result is NOT determined by pack choice and no production
draw/result/rarity logic was changed.

Replay resets the full opening ritual back to pack choice.

## Rarity behavior

The existing five rarity profiles remain active and now affect opening/reveal
energy as well as their existing foil/glow/particle/reveal behavior:

- Common: cleanest / lowest energy.
- Uncommon: restrained accent.
- Rare: stronger pulse/burst.
- Epic: higher energy plus existing Epic reveal language.
- Legendary: strongest opening/reveal impact plus a two-stage finale.

Post-gesture reveal delay also scales by rarity:
Common 190ms, Uncommon 230ms, Rare 285ms, Epic 350ms, Legendary 430ms.
## Low-frequency hidden omen / near-miss

Hidden pre-reveal omen is intentionally NOT guaranteed.

- Legendary: deterministic approximately 1 in 7 opening combinations.
- Epic: rare approximately 1 in 20 false-positive / near-miss cue.
- Rare and below: no hidden omen.

The omen only appears after the gesture has completed and before the card is
revealed. Omen runs use an 820ms suspense delay. This keeps the clue uncommon
instead of teaching players that every Legendary has a tell.

## Visual fixes in the same round

1. Locked-card info copy:
   all five locked masters use a light/silver information panel, so title and
   subtitle overlay text now use dark graphite instead of white. Real Chrome
   review confirmed Coffee/subtitle are readable. Accepted lower-right icon
   geometry/position was NOT changed.

2. Legendary finale:
   final beat now has stronger second-stage scale/impact, flash, 5 rings,
   two larger blurred shockwaves, 28 long radial rays, particles and lingering
   frame glow. Real Chrome review shows a materially more explosive final hit.

3. Tear-Up polish:
   tear line moved into the physical top-seal/crimp area so the torn strip does
   not carry the main ZYNC logo.

## Browser verification

All four mechanics were manually exercised in the real Flutter Chrome Lab:
- A drag upward -> open -> card back/reveal
- B horizontal split -> open -> card back/reveal
- C hold/charge -> release -> card back/reveal
- D drag seal downward -> open -> card back/reveal

The Lab still overrides platform reduced-motion ONLY for FX testing via
`respectReduceMotion=false` + `AnimationBehavior.preserve`. Production
defaults continue respecting accessibility settings.
## Mechanical QA

- `flutter test test/card_fx_lab_test.dart` -> 4/4 PASS
- targeted `flutter analyze` across opening/card/reveal/screen/test ->
  No issues found
- `git diff --check` -> clean
- widget test runs under forced `MediaQuery.disableAnimations=true`, enters
  the pack ritual, performs Tear Up and confirms the Z card-back still animates

## Explicitly unchanged

- lower-right card icon position/geometry
- locked 1024x1536 frame masters
- production draw/result/RNG/rarity outcome logic
- card-art generation pipeline
- backend/server
- GitHub Actions, Vercel, release/deployment, paid generation

## Next user decision

The Lab is intentionally a comparison harness. The user and his wife should
play A/B/C/D on the same Coffee Legendary and choose the preferred opening
mechanic before production integration. Keep all four until that decision.

After mechanic selection, the next polish phase can tune the chosen gesture,
rarity-specific pacing/audio/haptics and pack-opening integration without
restarting architecture or card-art work.

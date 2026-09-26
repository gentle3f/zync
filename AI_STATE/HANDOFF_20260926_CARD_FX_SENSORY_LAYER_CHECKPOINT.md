# Zync Card FX — Sensory Layer Checkpoint

Date: 2026-09-26 HKT
Branch: `card-art-pilot-v1-20260921`
Parent before this round: `4838c0a`

## Implemented before shutdown

A shared Card FX sensory layer is now implemented far enough to checkpoint.
It is intentionally independent of the later A/B/C/D winner decision.

Added `zync_fx_sensory.dart` with named events for:
- pack pick;
- reveal entrance;
- charge arm;
- A tear break;
- B split break;
- C charge burst;
- D seal unlock;
- hidden omen;
- card extraction;
- card flip;
- rarity hit;
- Legendary finale.

Opening/reveal code now calls those events instead of scattering raw haptics.
## Prototype sound assets

Added `audioplayers ^6.8.1` and a local `assets/card_fx/sfx/` asset bundle.

All prototype sounds were procedurally generated locally in this session;
no downloaded/copyrighted sound files were used.

Assets:
- pack_pick.wav
- tear_up.wav
- split_open.wav
- charge_burst.wav
- seal_slide.wav
- hidden_omen.wav
- card_extract.wav
- card_flip.wav
- rarity_common.wav / rarity_uncommon.wav / rarity_rare.wav
- rarity_epic.wav / rarity_legendary.wav
- legendary_finale.wav

The sensory layer uses a small multi-player pool so overlapping cues can coexist.
Audio failure is enhancement-only and is caught so it cannot break the reveal.
## Haptic / timing behavior

- Pack pick and charge arm: light selection feedback.
- A/B seal break: medium impact.
- C burst: heavy impact.
- D unlock: light impact.
- Card extraction scales by rarity.
- Card flip scales by rarity.
- Rarity hit scales Common -> Legendary.
- Legendary adds a later final heavy impact/cue.
- Hidden omen retains low frequency and now has a subtle separate cue.

Existing A/B/C/D mechanics, result/RNG, rarity outcomes, omen frequency,
reduced-motion Lab override, icon position and locked PNG masters are unchanged.

## QA completed

- Targeted `flutter analyze`: PASS / no issues.
- `flutter test test/card_fx_lab_test.dart`: 4/4 PASS.
- No GitHub Actions, Vercel, deployment, release or paid generation used.
## Real-browser status — IMPORTANT

Real-browser audio verification is NOT complete because the user needed to
shut the computer down.

A generic `flutter run -d chrome` using the normal app entrypoint first hit
an unrelated existing web-only InterestSetupScreen type-cast error. Do not
treat that as a Card FX regression.

The correct isolated lab entrypoint is:
`flutter run -d chrome -t lib/main_card_fx_lab.dart`

That lab launch was started, but browser-level confirmation that every WAV
loads and that A/B/C/D + extraction + flip + rarity cues fire at the intended
moments was not completed before shutdown.

## Exact next action

1. Start the isolated Card FX Lab entrypoint above.
2. Real-Chrome test A, B, C and D.
3. Confirm Network/console show no missing WAV/plugin errors.
4. Listen for pick -> mechanic break -> extract -> flip -> rarity sequence.
5. Adjust only cue volumes/timing if needed; do not choose an A/B/C/D winner.
6. Re-run analyze/tests, then commit any final sensory polish.

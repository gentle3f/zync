# Zync Card FX — Sensory Browser Validation Complete

Date: 2026-09-26 HKT
Branch: `card-art-pilot-v1-20260921`
Parent before this validation round: `62ca0b2`

## What was validated

The isolated Card FX Lab entrypoint was launched with:

`flutter run -d chrome -t lib/main_card_fx_lab.dart`

Real Chrome validation confirmed that the local `audioplayers` integration,
asset paths and sensory timeline work in-browser.

The browser successfully requested the expected WAV files from:
`/assets/assets/card_fx/sfx/`

There were no audio-related console errors during the validation runs.
## A/B/C/D cue validation

A — Tear Up:
- pack_pick.wav
- tear_up.wav
- card_extract.wav
- card_flip.wav
- rarity_legendary.wav
- legendary_finale.wav

B — Split Open:
- pack_pick.wav
- split_open.wav
- card_extract.wav
- card_flip.wav
- rarity_legendary.wav
- legendary_finale.wav

C — Charge Burst:
- pack_pick.wav
- charge_burst.wav
- card_extract.wav
- card_flip.wav
- rarity_legendary.wav
- legendary_finale.wav

D — Seal Slide:
- pack_pick.wav
- seal_slide.wav
- card_extract.wav
- card_flip.wav
- rarity_legendary.wav
- legendary_finale.wav
## Hidden omen validation

A deterministic Legendary omen case was intentionally selected without
changing omen frequency logic.

Sequence confirmed in real Chrome:
- pack_pick
- tear_up
- hidden_omen
- card_extract
- card_flip
- rarity_legendary
- legendary_finale

The omen remains post-break and pre-extraction, preserving the low-frequency
surprise behavior rather than becoming a normal always-on cue.

No result/RNG logic was changed to perform this validation.
## Browser/network evidence

With cache disabled, Chrome showed successful WAV requests for the full D
sequence and the hidden-omen sequence. Responses were successful and no
missing-asset or plugin errors appeared.

Observed D order:
seal_slide -> card_extract -> card_flip -> rarity_legendary ->
legendary_finale.

Observed Legendary omen order:
tear_up -> hidden_omen -> card_extract -> card_flip ->
rarity_legendary -> legendary_finale.

Range requests (206) are normal browser media loading behavior and do not mean
the cue was played twice.
## QA

- `flutter test test/card_fx_lab_test.dart`: 4/4 PASS.
- Targeted `flutter analyze`: no issues found.
- Locked frame assets remain unchanged.
- No GitHub Actions, Vercel, deployment, release or paid generation used.

## Current product state

Sensory architecture is now browser-validated enough for user listening tests.

Do not collapse A/B/C/D yet. The user and his wife still need to compare the
four complete experiences visually and aurally.

The next meaningful step after their comparison is to tune only the chosen
opening mechanic's final sound mix, haptic intensity and timing rather than
continuing to add divergent polish to all four.

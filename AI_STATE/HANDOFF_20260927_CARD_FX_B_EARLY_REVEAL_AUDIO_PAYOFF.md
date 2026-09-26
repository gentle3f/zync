# Zync Card FX — B Early Reveal + Payoff Audio Refinement

Date: 2026-09-27 HKT
Branch: `card-art-pilot-v1-20260921`
Parent before this round: `04b942b`

## Product direction

B — Split Open remains the chosen production direction.
A / C / D remain reference only. This round does not reopen or redesign them.

The user's real Chrome feedback drove two targeted changes:
1. show the physical card back essentially as soon as the foil has truly separated;
2. rebuild pack-selection and all rarity payoff sounds so opening a card feels more joyful, premium and tactile rather than retro/game-like.

## B early physical card reveal

The 70% B commit threshold is unchanged.

The initial ~12% remains a real seam/tension phase. Once `_splitSeparationFor(...)`
becomes non-zero, the card-back clip is now immediately non-zero as well.
There is no longer a separate ~30% reveal gate.

The card is still physically clipped by the widening center split; there is no
opacity/fade shortcut. The current pre-commit mapping uses the actual split
separation and lets the card occupy most of the available opening:

- reveal factor starts around 0.62 once separation is real;
- it rises toward 1.0 as the split widens;
- card clip stays tied to `splitInteriorFraction` and therefore cannot exceed
  the physical center opening;
- the final multiplier is 0.98, leaving only a restrained cavity edge.

At roughly a 14% actual B pull, the regression test now requires more than
10 px of visible card-back clip while extraction is still absent. A wider held
pull must increase the clip further.

Fresh held Chrome review shows the card back filling most of the opening while
the UI still says `KEEP GOING`; this is pre-commit, not extraction.

Target feeling now:
`foil separates -> immediate narrow card glimpse -> card fills widening gap -> commit -> extraction`.

## Selection sound redesign

`pack_pick.wav` was rebuilt from scratch locally with procedural DSP only.
No external audio assets and no paid generation were used.

It is now a short stereo tactile foil/tick cue instead of the old hard mono
UI-like hit:
- old: 0.090 s, mono, RMS ~0.386;
- new: 0.145 s, stereo, RMS ~0.142.

The source is deliberately softer and more material-like. Playback volume moved
from 0.26 to 0.34 so it remains audible without competing with tear/reveal.
Selection interaction and logic are unchanged.

## All-rarity payoff redesign

All five rarity-hit WAVs were rebuilt as one sensory family:
physical low-end impact + short non-harmonic metallic/foil resonance + restrained
high-frequency air/shimmer. No arcade power-up melody or magical-chime pattern
was added.

Objective old -> new source metrics:
- Common: 0.260 s / RMS 0.125 -> 0.360 s / RMS 0.184
- Uncommon: 0.340 s / RMS 0.134 -> 0.420 s / RMS 0.185
- Rare: 0.460 s / RMS 0.166 -> 0.500 s / RMS 0.184
- Epic: 0.680 s / RMS 0.213 -> 0.600 s / RMS 0.201
- Legendary hit: 0.960 s / RMS 0.272 -> 0.680 s / RMS 0.195
- Legendary finale: 1.180 s / RMS 0.275 -> 0.640 s / RMS 0.209

Epic/Legendary are intentionally shorter and cleaner than the prior long noisy
tails. Legendary remains clearly the strongest system-level payoff because the
existing two-stage architecture is preserved: the high-volume Legendary rarity
hit is followed by a delayed overlapping `legendary_finale.wav`.

The acceptable B tear cue `split_open.wav`, card flip `card_flip.wav`, and
card extraction cue were not redesigned in this round.

## Real Chrome validation

Chrome 153 was run against the local Flutter Card FX Lab with cache disabled.
Flutter web accessibility semantics were enabled only to make repeatable Lab
control selection during validation; product behavior was not altered.

Clean full B Legendary request order:
`pack_pick.wav -> foil_tension.wav -> split_open.wav -> card_extract.wav -> card_flip.wav -> rarity_legendary.wav -> legendary_finale.wav`

Separate real B runs also reached the rebuilt:
- `rarity_common.wav`
- `rarity_uncommon.wav`
- `rarity_rare.wav`
- `rarity_epic.wav`

No relevant browser runtime/audio errors were observed. Browser media range/load
behavior can create duplicate network rows for one WAV; that is not evidence of
duplicate app event calls.

## Final QA

- `flutter test test/card_fx_lab_test.dart` -> 4/4 PASS.
- targeted `flutter analyze` across opening/sensory/reveal/card/screen/test ->
  No issues found.
- `git diff --check` -> clean.
- `split_open.wav` unchanged this round.
- `card_flip.wav` unchanged this round.
- locked frame master directory unchanged.

## Explicitly unchanged

RNG, rarity outcome behavior, hidden-omen frequency/seed logic, 70% B commit
threshold, reduced-motion Lab override, accepted lower-right icon position,
locked 1024x1536 PNG masters, card-art pipeline, backend/server, and A/C/D
reference mechanics are unchanged.

No GitHub Actions, Vercel deployment, release or paid generation was used.
The current branch is excluded from the push-triggered CI branch filters and
Vercel has deployment disabled for `card-art-pilot-v1-20260921`.

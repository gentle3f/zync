# Zync Card FX — User-Selected Pixabay Reference Audio

Date: 2026-09-27 HKT
Branch: `card-art-pilot-v1-20260921`
Parent before this round: `2c06a24`

## Product direction

B — Split Open remains the chosen production direction. A / C / D remain
reference only. This round does not change B mechanics, the accepted early
physical card-back reveal, the 70% commit threshold, RNG, rarity outcomes,
hidden-omen behavior, locked frame masters, card art, backend, or release state.

The user explicitly auditioned and selected the sound references used here.
This round therefore replaces the previous locally synthesized/guesstimated B
payoff family with those user-selected sources rather than trying to infer taste
from waveform metrics.

## B sensory sequence

The B path now reads:
`pack pick -> physical tear -> micro anticipation -> subdued foil tension ->
wrapper-open pop -> existing extraction -> card flip -> shared reward bloom ->
rarity-specific payoff`.

At the first real split cue (about 12% drag), B plays the selected Paper Tearing
sample. Crossing the next split cue (about 27%) plays Magic Twinkle once.
Later drag thresholds retain the existing foil-tension cue at reduced volume.
At the unchanged 70% commit threshold, `splitBreak` now plays the selected
Achievement Badge Pop Sound #3. Extraction timing/mechanics are unchanged.

Reveal timing preserves the existing card-flip cue point at p=0.48, but uses the
selected Card Sounds sample. A new shared reward-bloom timer fires Magic Surprise
at p=0.59, then the rarity-specific selected payoff fires at the existing p=0.64.
The new bloom timer is included in the existing replay/spec-change timer
cancellation path, so stale reward audio cannot survive into a new reveal.

The old delayed Legendary finale *sound* is disabled. Its existing p=0.78 haptic
event remains. The user selected one strong Legendary payoff source, so this
round does not stack the previously disliked synthetic finale back on top.

## Source mapping

- Pack pick: Next Level — Universfield
- Tear: Paper Tearing — Colto
- Wrapper opened: Achievement Badge Pop Sound #3 — Vadim_Makes_Sound
- Card flip: Card Sounds — freesound_community
- Micro anticipation: Magic Twinkle — Universfield
- Shared reward bloom: Magic Surprise — Universfield
- Common: XP Gain Magic Tone — humordome
- Uncommon: Great Success — freesound_gamestudio
- Rare: Magic UI Level Up Stinger | Fantasy Confirmation Sound — Coghezzi
- Epic: Elemental Spell Impact (Ice) — DRAGON-STUDIO
- Legendary: Elemental Spell Impact (Light) — DRAGON-STUDIO
The user also supplied Level Up 05 by Universfield without assigning it a role.
It is recorded in the source manifest as a spare reference only; the audio file
is not bundled and nothing is wired to it.

Exact source pages and authors are recorded in
`mobile/assets/card_fx/sfx/PIXABAY_SOURCES.md`, together with the Pixabay
Content License summary URL. Eleven selected MP3 files are bundled under
`mobile/assets/card_fx/sfx/`.

No source audio was re-synthesized or materially transformed in this round.
This first integration intentionally preserves the sounds the user actually
auditioned; volume/timing can be tuned after real listening feedback.

## Objective validation

- All 11 new files downloaded as `audio/mpeg` and were readable by ffprobe.
- Durations range from 0.432 s (Card Sounds) to 6.312 s (Legendary Light).
- The running Flutter Card FX Lab was hot-restarted.
- Every new MP3 was served by the Flutter asset server with HTTP 200 and the
  expected byte length.
- Targeted Card FX/pack tests: 22/22 PASS.
- Full canonical non-golden mobile suite: 333/333 PASS.
- Full `flutter analyze`: No issues found.
- `git diff --check`: clean.

The literal full test suite still has the pre-existing missing golden baseline
`goldens/card_art_engine_v1_flagships.png`; do not auto-create it merely to
make the test green.
## Explicitly unchanged / guardrails

A / C / D opening mechanics remain reference-only and unchanged. Their legacy
reference cues remain available. Existing card extraction and hidden-omen audio
are unchanged. The old WAV files remain in the repository because some are still
used by reference flows; this round does not delete them.

Do not claim subjective audio success from automated checks. The next meaningful
gate is the user's real listen to B. If the source choices feel right but balance
does not, tune timing and gain first rather than replacing the selected sound
language.

No GitHub Actions, Vercel deployment, Production, Play, release, or paid
generation was used. The branch remains excluded from push-triggered workflows
and Vercel deployment is disabled for `card-art-pilot-v1-20260921`.

The pre-existing untracked `mobile/lib/l10n/generated/` and
`mobile/pubspec.lock` remain deliberately untouched and must not be staged.

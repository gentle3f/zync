# Zync Card FX — Overnight QA / Runtime Hardening Checkpoint

Date: 2026-09-27
Branch: `card-art-pilot-v1-20260921`

## Scope of this checkpoint

The user explicitly asked to keep working while they slept, but to do other
objective work first. This checkpoint therefore avoids subjective audio/visual
retuning. B (Split Open) remains the chosen production direction exactly as in
the prior authoritative Card FX checkpoint.

Preserved without redesign:
- B split-open mechanic and early physical card-back reveal
- first ~12% seam/tension-only region, then immediate real card-back visibility
  once foil separation begins
- unchanged 70% commit threshold
- accepted tear/extract/flip behavior
- current pack-pick / rarity payoff audio family
- current icon position
- locked 1024x1536 transparent frame masters
- rarity/RNG/backend behavior
- hidden omen behavior
- A/C/D as reference prototypes only
- no card-art generation or production rollout

## Objective bugs / gaps fixed

### 1. InterestLocaleRegistry runtime type crash

Expanded pack-opening tests exposed a real runtime failure:

`UnmodifiableMapView<dynamic, dynamic>` was being cast to
`Map<String, String>` while building localized interest labels.

The parser now explicitly constructs typed immutable outer and inner maps for:
- `Map<String, Map<String, String>>`
- `Map<String, Map<String, List<String>>>`

This fixes the crash without changing locale data semantics.

### 2. Unicode-slug compatibility holes

Two catalog IDs generated from Unicode titles do not match the prettier
ASCII-style overlay IDs already present:
- `Shōgun` canonical resolves as `entertainment.tv_drama.sh_gun`
- `Škoda` canonical resolves as `transport.car_brand.koda`

Compatibility locale overlays were added for the actual canonical IDs instead
of renaming canonical IDs or performing a migration.

### 3. Legacy localized search aliases

Added missing compatibility aliases:
- Spanish `Cocina de Sichuan` -> `food.sichuan`
- Korean `라이프 시뮬레이션` -> `gaming.subgenre.life_sim`

### 4. Taxonomy navigation translation gaps

Added Traditional/Simplified Chinese navigation labels for newly introduced
taxonomy keys:
- fandom
- community_sports
- parks
- motorized_recreation
- brands
- media
- hospitality
- trades
- social_services

### 5. Stale policy test fixture

The partner-only card-art policy test referenced the non-canonical
`gaming.franchise.minecraft`. It now checks the real preserved legacy
canonical ID `gaming.minecraft`.

### 6. B Split Open regression protection

The Card FX Lab widget regression test now also proves:
- releasing B below the 70% commit threshold immediately closes the physical
  gap
- a sub-threshold release never starts card extraction
- after a committed B drag, pressing Replay before extraction tears down the
  pending chain
- no stale extraction appears 500 ms later in the replayed pack

### 7. Reveal sensory timer lifecycle fix

`ZyncFxRevealStage` now cancels the previous flip / rarity-hit /
Legendary-finale timers at the very start of every new reveal.

This specifically prevents an old sound/haptic cue from firing after a replay,
spec change, or a new reveal that resolves instantly under Reduce Motion.
Normal reveal timings and sound assets were not changed.

## Asset / static checks

- all Card FX WAVs inspected as valid WAV assets; no clipping detected in the
  current files
- locked frame masters remain 1024x1536 RGBA and were not modified
- no frame-master diff
- no paid generation
- no GitHub Actions
- no Vercel deployment
- no Production / Play / release action

## Validation

Targeted regression set after final minimal-diff cleanup:
- 61 tests PASS

Full local mobile test suite excluding the known missing golden baseline:
- 52 test files
- 333 tests PASS
- exit code 0

`flutter analyze`:
- No issues found

Running the literal full test suite leaves exactly one infrastructure failure:
- `test/card_art_engine_golden_test.dart`
- expected baseline file does not exist:
  `goldens/card_art_engine_v1_flagships.png`

Do NOT auto-create that baseline merely to turn the test green. Generating it
from the current render would amount to self-approving a visual baseline that
has never been reviewed.

## Working-tree hygiene

Two pre-existing untracked Flutter-generated items remain intentionally
unstaged and untouched:
- `mobile/lib/l10n/generated/`
- `mobile/pubspec.lock`

No broad formatter churn is included. A temporary near-2000-line reformat of
`localized_domain_text.dart` was explicitly reverted; only the nine required
taxonomy rows remain as a minimal diff.

## Next product-review step

When the user is available again, resume subjective real-device/browser review
of B only. Do not alter the current pack-selection/final-payoff sound character
or B visual timing without fresh user feedback.

# Zync Card FX Lab V1 — Runtime FX Foundation

Date: 2026-09-25
Branch: `card-art-pilot-v1-20260921`
Starting commit: `4d59ccc0e323d1956a548e52d18924abe66cab6d`

## Purpose

Build an isolated, reusable Flutter runtime card-effects sandbox inspired by the
"physical collectible card" feel the user wants from pack draws and focused
card inspection. This checkpoint does **not** change Cardverse server results,
pack contents, production/release configuration, card-art generation, or the
existing production card renderer.

## V1 architecture

New runtime-only files:

- `mobile/lib/card_fx/card_fx_profile.dart`
  - finish-specific motion/foil/glow/particle/reveal profiles
  - reusable ambient-effect enum: dust, steam, digital pulse, embers, water
- `mobile/lib/card_fx/card_fx_surface.dart`
  - drag-to-tilt 3D perspective
  - artwork parallax
  - reusable foil/specular overlay
  - rarity edge glow
  - lightweight particles
  - reusable hobby ambient FX painters
  - draw/reveal timeline: lift -> flip -> impact -> settle
  - haptic hook
  - Reduce Motion fallback
- `mobile/lib/screens/card_fx_lab_screen.dart`
  - isolated tuning UI
  - sample cards: Coffee, AI, Reading
  - live finish/rarity switching
  - ambient-FX switching
  - FX-intensity and tilt/parallax sliders
  - reveal replay and inspect modes
- `mobile/lib/main_card_fx_lab.dart`
  - standalone lab entrypoint; production app entrypoint remains untouched
- `mobile/test/card_fx_engine_test.dart`
  - profile escalation checks
  - drag surface smoke test
  - Reduce Motion reveal fallback smoke test

## Deliberate V1 boundaries

- No gyroscope/sensor dependency yet. Drag supplies the same normalized tilt
  input so the feel can be calibrated first; a sensor stream can feed the same
  interface later.
- No GIF/video effects.
- No per-card animation assets.
- No integration into the real pack-opening or single-draw flow yet.
- No server/Cardverse receipt logic changes.
- No frame composition yet. The five locked transparent rarity masters are
  still absent from the repository; the FX layer intentionally wraps an
  arbitrary child so production artwork + frame composition can replace the
  current procedural `ZyncCardPreview` without rewriting the FX engine.
- No new Flutter package dependency.
- No GitHub Actions, Vercel, Play, release, or paid API call is required by this
  checkpoint.

## Run locally later

From `mobile/`:

```bash
flutter run -t lib/main_card_fx_lab.dart
```

The standalone entrypoint is intentionally separate from `main.dart`.

## Next steps after device feel review

1. tune rarity profiles/reveal timings with the user on a real phone;
2. add gyroscope input after tilt feel is locked;
3. commit/import the five locked transparent rarity-frame masters;
4. build production artwork + frame composition as the child layer;
5. add category/hobby ambient-FX metadata routing;
6. only then replace the current simple reveal surface inside the real
   Cardverse pack/single-draw UX.

## Validation note

Repository-side work in this checkpoint is intentionally static. The connected
GitHub environment does not provide a Flutter runtime, so the new widget tests
were authored but not executed here. Do not claim device/compile validation
until Flutter is run locally or CI is explicitly authorized.

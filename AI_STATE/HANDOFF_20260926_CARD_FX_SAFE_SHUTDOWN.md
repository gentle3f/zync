# Zync Card FX — Safe Shutdown Checkpoint

Date: 2026-09-26
Branch: `card-art-pilot-v1-20260921`
Authoritative remote HEAD before this checkpoint: `b6362b2`

## Preserved state

- Card FX Lab foundation is committed and pushed.
- Latest implementation uses 3 real accepted production artworks:
  - `mobile/assets/card_fx/art/coffee.jpg`
  - `mobile/assets/card_fx/art/ai.jpg`
  - `mobile/assets/card_fx/art/reading.jpg`
- Runtime FX includes drag tilt, parallax, foil/shimmer, edge glow, ambient FX,
  particles, reveal flip/timing, haptics and a tuning/debug panel.
- Exact artwork-window geometry was measured from the five locked 1024x1536
  transparent rarity frame masters and encoded in `ZyncFrameGeometry`.
- Local validation at this checkpoint:
  - `flutter test test/card_fx_lab_test.dart` => 3/3 PASS
  - targeted `flutter analyze` => No issues found
- No GitHub Actions, Vercel, Play/release, paid image API or production draw logic used.
- The richer pre-merge local WIP is additionally preserved on the LOCAL-ONLY
  branch `local/card-fx-wip-snapshot-20260925` at commit `e6e7c01`.

## Frame assets

The five immutable source frame masters are NOT yet committed into the repo.
The authoritative source remains the user-provided `frames.zip` / prepared
`zync_frame_masters_ready_to_commit.zip` in the ChatGPT working files.

Lab-only derivatives were prepared in ChatGPT working storage but were NOT yet
copied into the local repo before shutdown. Do not regenerate/reinterpret the
master designs.

## Next exact step

1. Copy the five prepared frame assets (or Lab derivatives) into
   `mobile/assets/card_fx/frames/`.
2. Wire `ZyncFxCardSpec.frameAsset` by rarity.
3. Keep `ZyncFrameGeometry` as the artwork-window source of truth.
4. Run `flutter test test/card_fx_lab_test.dart` and targeted `flutter analyze`.
5. Produce the first real artwork + locked-frame Card FX Lab preview.
6. Only after visual/device approval consider gyro input or real pack-opening integration.

Do not restart architecture discovery. Do not modify production draw/server logic.

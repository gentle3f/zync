# Zync Card FX Lab — Replay + Locked PNG Masters Complete

Date: 2026-09-26 HKT
Branch: `card-art-pilot-v1-20260921`
Repo: `gentle3f/zync`
Local clone: `C:\Users\FUJITSU\zync_fx_lab`
Starting checkpoint: `c4be709`

## Read first

Read and obey `AI_STATE/OPERATING_RULES.md` before any write/commit/push.
No GitHub Actions, Vercel, release, Play/App Store, paid API, or production
draw/server change was used in this Card FX round.

## Completed in this round

1. Real-browser Replay bug is fixed.
`CardFxLabScreen` now includes `_revealToken` in the
`ZyncFxRevealStage` ValueKey, so Replay recreates reveal state instead of
depending on an update of the existing State object.

The widget test was strengthened to prove the reveal-stage key changes from
token 3 to token 4 after Replay, rather than merely checking that a tap throws
no exception.

2. Replay was verified in the actual already-running Chrome Lab through its
Chrome DevTools endpoint after hot reload/restart. Pressing Replay visibly
returned the card to the Z card-back/reveal sequence. This is a real-browser
verification, not just a widget-test inference.

## Locked frame replacement

The five original locked 1024x1536 PNG masters were found locally in
`C:\Users\FUJITSU\Downloads`. Their SHA-256 values were checked against
the authoritative Library bundle manifest from
`/Zync/Card FX/zync_frame_masters_ready_to_commit.zip`; all 5 matched exactly.

- Common: `e539202df27027746473e02f8950ff949d1c57aa8a8186b9806611e4a45d73f8`
- Uncommon: `1d2f664449dcf2f8bca2ddc36ad367cbd3d184404248e53765ab75cd0bc13962`
- Rare: `a50078ebb599a3b8379ad290c68027b106436a5e36502eda98f198c3b3abf62e`
- Epic: `94e2fc7187756d01b3fcfd42043b6acd59bcc941eabbd4662529e058683d1baa`
- Legendary: `8c0d9f3ddf775c787a41b41beb9781e8372921785b2cb830b179af640b99f3dc`

All five are 1024x1536 RGBA and retain genuine transparency. Remote validation
also matched the manifest alpha-zero pixel counts and alpha extrema (0, 254).

They now live under:
`mobile/assets/card_fx/frames/master/`

`ZyncFrameAssets` and `pubspec.yaml` now point only to those locked PNG
masters. The obsolete 96x144 WebP derivatives were removed after the PNG path
was proven in the browser. There are no remaining runtime WebP frame refs.

## Browser review result

Common, Rare, and Legendary were manually inspected in the real Chrome Lab.
The frame text, metal edges and small details are now visibly sharp instead of
the previous 96x144-upscaled blur. Artwork clipping remains aligned to the
existing `ZyncFrameGeometry`.

The lower-right icon position was inspected again on Legendary and remains
unchanged. USER ACCEPTANCE STILL STANDS: do not move the icon unless the user
explicitly asks again.

Replay was re-tested after the PNG replacement and still visibly restarts the
sequence, including the Z card back / reveal FX.

## Mechanical QA

- `flutter test test/card_fx_lab_test.dart` -> 4/4 PASS
- targeted `flutter analyze` across Card FX spec/reveal/card/screen/test ->
  No issues found
- copied master SHA/dimensions/alpha metadata -> 5/5 MATCH
- runtime search for obsolete WebP frame references -> none

Generated local `mobile/pubspec.lock`, generated l10n output, and temporary
browser-review screenshots were removed before final staging.

## Scope intentionally NOT changed

- Icon geometry/position
- `ZyncFrameGeometry`
- production draw/result logic
- rarity outcome logic
- card-art generation pipeline
- GitHub Actions / Vercel / deployment / Play release
- paid generation

## Next Card FX work

Immediate blockers from the browser-review checkpoint are closed. Continue
only with the next runtime-FX phase when requested: gyro/real-device tilt,
then pack-opening integration/polish. Do not restart card-art generation or
architecture discovery as part of Card FX work.

The final commit containing this handoff is the authoritative Card FX
checkpoint; verify HEAD on `card-art-pilot-v1-20260921`.

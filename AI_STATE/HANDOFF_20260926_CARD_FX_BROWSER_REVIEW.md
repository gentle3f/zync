# Zync Card FX Lab — Browser Review / Next-Chat Handoff

Date: 2026-09-26 15:44 HKT
Branch: `card-art-pilot-v1-20260921`
Repo: `gentle3f/zync`
Local clone: `C:\Users\FUJITSU\zync_fx_lab`

## Read first

Read and obey `AI_STATE/OPERATING_RULES.md` before any write/commit/push.
No GitHub Actions, Vercel, release, Play/App Store, paid API, or production
draw/server changes are needed for this Card FX work.

## Current authoritative history

Relevant commits already on remote before this handoff:
- `af74714` — Add isolated Card FX Lab runtime prototype
- `b6362b2` — Upgrade Card FX Lab with production artwork
- `19386dc` — Checkpoint Card FX lab for safe shutdown
- `3e0f687` — Wire locked rarity frames into Card FX Lab
- `9daab3c` — Tune locked-frame layout and rarity switching

This handoff must be followed by the final WIP checkpoint commit created at
the end of this chat; check HEAD after reading LATEST_HANDOFF.

## What is already working

Card FX Lab runs locally in Chrome via:
`flutter run -d chrome -t lib/main_card_fx_lab.dart`
The lab currently has three REAL accepted production artworks:
- `books.reading` -> `mobile/assets/card_fx/art/reading.jpg`
- `technology.ai` -> `mobile/assets/card_fx/art/ai.jpg`
- `food.coffee` -> `mobile/assets/card_fx/art/coffee.jpg`

Runtime FX implementation currently includes:
- drag 3D tilt
- artwork parallax
- foil/shimmer sweep
- rarity edge glow
- ambient FX (dust / steam / digital pulse)
- reveal particles
- reveal flip/lift/settle timeline
- rarity-specific reveal halo/rings/rays WIP
- haptic hooks
- debug sliders
- Common / Uncommon / Rare / Epic / Legendary profiles
- rarity switching in the Lab

Exact artwork-window geometry measured from the locked 1024x1536 frame
alpha masks is encoded in `ZyncFrameGeometry`.
Do NOT go back to guessed artwork-window percentages.

## User browser review — authoritative

User visually tested the Lab in Chrome on GEN-FUJI.

1. ICON POSITION: ACCEPTED.
The user first questioned it, then explicitly said:
"icon position ok"
Do not move/rework the lower-right icon placement unless user asks again.

2. REPLAY BUTTON: BROKEN IN REAL BROWSER.
The user explicitly reports:
"when i press replay button no response"
This overrides the widget-test impression. Treat replay as NOT FIXED.

Current WIP moved Replay beside the Inspect/Draw reveal segmented control and
gave it key `fx-replay-button`. The current widget test taps the button and
only checks that no exception occurs. That test is insufficient because it
does NOT prove the reveal animation restarted.

Relevant current logic:
- `CardFxLabScreen` increments `_revealToken`
- `ZyncFxRevealStage.didUpdateWidget` compares old/new revealToken and calls
  `_play()`
- despite this, manual Chrome test shows no visible replay

Strong next-step candidate:
- include `_revealToken` in the `ZyncFxRevealStage` ValueKey so pressing
  Replay forcibly recreates reveal state, e.g. a key containing id + rarity +
  revealToken;
- alternatively expose/test an observable reveal phase/controller state;
- strengthen the widget test to verify an actual front/back/transform state
  transition, not merely "tap produced no exception".
Do the smallest robust fix, then verify manually in Chrome.

3. FRAME SHARPNESS: BROKEN.
The user explicitly reports:
"the frame seems very blurred"

Root cause is confirmed, not speculative:
the five repo frame assets are only 96x144 WebP:
- common.webp 96x144
- uncommon.webp 96x144
- rare.webp 96x144
- epic.webp 96x144
- legendary.webp 96x144
They are displayed at roughly 390x585 in the Lab, so ~4x upscaling makes
blur unavoidable. Do NOT try to fix this with FilterQuality or CSS tweaks.

Correct fix:
replace the Lab derivatives with the original locked 1024x1536 PNG masters
while preserving alpha. Keep the same rarity mapping and geometry.
The immutable original source was previously saved to ChatGPT Library at:
`/Zync/Card FX/zync_frame_masters_ready_to_commit.zip`

That prepared bundle contains the five locked masters intended for repo use:
- `zync_frame_common_master_v1.png`
- `zync_frame_uncommon_master_v1.png`
- `zync_frame_rare_master_v1.png`
- `zync_frame_epic_master_v1.png`
- `zync_frame_legendary_master_v1.png`

The original source frames are 1024x1536 RGBA with genuine transparent
artwork windows and transparent pixels outside the rounded card.
Do NOT regenerate or reinterpret them.

Recommended repo destination:
`mobile/assets/card_fx/frames/master/`
Then update `ZyncFrameAssets` to use the PNG masters directly.
Optionally remove/deprecate the 96x144 WebPs after the PNG path is proven.

## Current WIP not yet considered visually accepted

At chat end, three files contain WIP edits:
- `mobile/lib/card_fx/zync_fx_reveal.dart`
  adds rarity reveal halo/rings/rays around the reveal
- `mobile/lib/screens/card_fx_lab_screen.dart`
  moves Replay beside the mode selector and gives it `fx-replay-button`
- `mobile/test/card_fx_lab_test.dart`
  updates the test to tap `fx-replay-button`

These WIP edits are mechanically clean but Replay is still a manual-browser
FAIL. Preserve the code/history; do not claim it solved the bug.

Mechanical validation at chat end:
- `flutter test test/card_fx_lab_test.dart` -> 4/4 PASS
- targeted `flutter analyze` -> No issues found
Again: this does NOT override the real browser failure.

A generated `mobile/pubspec.lock` may appear after local Flutter commands.
It is not tracked by this repo and is not meaningful Card FX work; remove it
before final status/commit if still untracked.

## Next chat exact order

1. Read this handoff + OPERATING_RULES.
2. Verify branch HEAD and clean working tree.
3. Fix Replay FIRST and manually confirm the animation visibly restarts in
   the already-running Chrome Lab.
4. Replace 96x144 WebP frames with original 1024x1536 transparent PNG masters.
5. Confirm icon placement is unchanged.
6. Run Card FX widget tests and targeted analyze.
7. Open/refresh Chrome and visually inspect Common + Rare + Legendary:
   frame sharpness, artwork clipping, labels/icon alignment, reveal.
8. Only after those pass, continue FX polish / gyro / pack-opening integration.

Do NOT restart architecture discovery and do NOT return to card-art generation.
The immediate job is runtime Card FX quality and interaction correctness.

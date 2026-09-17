# Mini Handoff — Scanner Error UX Start

Branch: `zync-v1-rebuild-20260917`

## Certified immediately before this slice
CI #41 `35141089002` on `dfa3a4a312169bb9ad632973ad4f559984674101` completed SUCCESS: Play identity/branding assertions, localization generation, analyze, tests (including 80-interest compressed QR + 320dp render), release AAB and artifact upload all passed.

Artifact: `10465556475`, 60,752,363 bytes, digest `sha256:6df41d2534493108345f50d3855b566a2b76da72eb73a8268921bbcf766d9dcd`.

## Active task
Add professional localized camera initialization/permission error UX to `ScanQrScreen` using mobile_scanner 7.x `errorBuilder`, preserving the branded scanner overlay. Add retry behavior and translations across all 8 V1 locales. Then run CI and fix only evidenced failures.

## Next after this slice
Implement the minimal no-server bilingual/cross-language conversation display for peers whose profile languages differ; do not add pairing state or Phase 2 infrastructure.

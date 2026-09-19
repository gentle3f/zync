# Mini handoff — scanner camera-error UX slice start

Branch: `zync-v1-rebuild-20260917`

Checkpoint before edits:
- QR compression/render slice CI #41 `35141089002` is fully green.
- Artifact id `10465556475`, 60,752,363 bytes, digest `sha256:6df41d2534493108345f50d3855b566a2b76da72eb73a8268921bbcf766d9dcd`.
- Next active work: explicit localized camera permission/unavailable/generic scanner error states using `mobile_scanner` 7.0.1 `errorBuilder`, while preserving the branded scanner overlay.
- Do not widen scope. Keep `main` untouched. Never commit secrets.

Implementation intent:
1. Add professional scanner preview error state for `permissionDenied`, `unsupported`, and generic camera failures.
2. Hide scan-frame overlays while camera is uninitialized or errored.
3. Add safe Retry for recoverable states.
4. Add localized strings across all 8 V1 locales.
5. Add widget regression tests that do not require a real camera/plugin runtime.
6. Run CI and only then certify this slice in `AI_STATE/LATEST_HANDOFF.md`.

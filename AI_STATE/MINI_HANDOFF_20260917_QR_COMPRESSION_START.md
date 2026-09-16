# Zync V1 Mini Handoff — QR compression slice start

Branch: `zync-v1-rebuild-20260917`

## Certified baseline entering this slice
- CI run #36 `35138218437` completed **SUCCESS**.
- Passed Android identity/branding checks, localization generation, `flutter analyze`, all tests (including 320dp/long-translation smoke tests), release AAB build, and artifact upload.
- Artifact `10464092901`, digest `sha256:15b9bc8c86038a480d3e0b19654bdad351591ffe1df28e946194cac7c30ce066`.

## Active task
Harden serverless QR exchange for large interest profiles without adding pairing infrastructure.

Design:
- Keep the existing compact JSON schema/version (`v:1`) as the semantic payload.
- Keep small payloads as the legacy raw JSON so simple/new profiles remain maximally compatible.
- For larger payloads, wrap the same JSON in a local compressed transport using zlib + URL-safe base64 with a short `Z2:` prefix.
- New decoder must accept both legacy raw JSON and compressed transport.
- Add tests for legacy compatibility, large custom-interest profiles, readable metadata preservation, compression effectiveness, and malformed compressed input.

No server/database changes. No Phase 2 scope.
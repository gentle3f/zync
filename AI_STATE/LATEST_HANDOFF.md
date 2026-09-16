# Zync V1 — Latest Handoff

## Branch
`zync-v1-rebuild-20260917`

## Mission
Rebuild the old Thunkable Zync MVP as a modern, low-cost, international Flutter app while preserving the existing Google Play Android identity.

## Frozen V1 scope
Authoritative product scope: `docs/ZYNC_V1_PRODUCT_SPEC.md`.

Core: local interest profile, multilingual canonical-interest model, QR peer exchange, local match detection, Hidden Match reveal, AI conversation questions, zero-match crossover questions, conversation modes, Zync Again history, Interest DNA, local fallback questions, Vercel/OpenRouter proxy. No login/Firebase/community/chat/location/social-import/commerce in V1.

## Non-negotiable product-quality bar
The shipped UI/UX must look professional, not like a default Flutter demo or functional prototype. Graphics are in scope end-to-end: in-app vector graphics/motifs, app icon, splash/launch identity, empty/loading/error states, QR/scanner presentation and any graphics required for a coherent release. Do not leave graphics for the user to source separately.

Visual source of truth: `docs/ZYNC_V1_VISUAL_SYSTEM.md`.

Current visual direction: premium-friendly, warm, modern social product; orange main accent, dark ink typography, warm cream surfaces, plum/mint secondary accents, generous rounded geometry, restrained shadows and a recurring connection/network motif.

## Existing Play compatibility
- applicationId: `com.gmail.gentle3f.myproject`
- existing known Play versionCode: 5
- V1 version: `1.0.0+6`
- targetSdk / compileSdk: pinned and CI-asserted at 36
- Android display label: `Zync`
- final artifact: Android AAB
- existing keystore is separate; NEVER commit keystore/password/secrets.

## Implemented V1 surface
- Flutter/Material 3 local-first app.
- Canonical interests with `love` / `like` / `wantToTry` strengths.
- 8 initial locales: EN / zh-Hant / zh-Hans / JA / KO / ES / FR / PT.
- Local profile/history via SharedPreferences.
- Interest onboarding/editor, search, free-text AI normalization, user confirmation and local persistence.
- QR show/scan, local canonical matching, Hidden Match reveal, zero-match crossover, Zync Again history, conversation modes, Interest DNA.
- Vercel `/api/v1/question` and `/api/v1/normalize-interest`, server-side OpenRouter key only.
- Multilingual local question fallback when AI/API is unavailable.
- Custom interests preserve readable label/category through local JSON and QR and match on canonical deterministic IDs.
- `.gitignore` protects env files, keystores/JKS/P12 and key.properties.

## Professional UI/UX + graphics implemented
- `mobile/lib/ui/zync_design.dart`: reusable Zync visual system, palette, theme, surfaces, icon tiles, custom-painted overlapping-rings `ZyncMark`, connection backdrop.
- Branded loading state, Home, onboarding/interest editor, QR handoff, full-camera scanner, Hidden Match reveal, conversation, History and Interest DNA.
- `docs/ZYNC_V1_VISUAL_SYSTEM.md` defines release visual/QA bar.
- Native Android launcher/adaptive/monochrome icon and pre-/post-Android-12 splash resources are reproducibly applied by `mobile/tool/apply_android_branding.py`.

## Certified build checkpoints
### Native branding certification
CI #34 `35137432743` — **SUCCESS**.
Artifact `10463318979`, digest `sha256:fc0b9a415f9be41c485fc106b99f1b737aa4968b48cae098e908e5ea03a29dff`.

### UX hardening + narrow-layout certification
CI #36 `35138218437` on commit `958fedf05cae2da8653ce42c3b26485b9b4d793f` — **SUCCESS**.
Passed wrapper generation, exact Play identity + Android branding assertions, localization, `flutter analyze`, all tests including 320dp/long-translation smoke tests, release AAB build and artifact upload.
Artifact `10464092901`, size 60,726,164 bytes, digest `sha256:15b9bc8c86038a480d3e0b19654bdad351591ffe1df28e946194cac7c30ce066`.

Other prior green checkpoints: CI #32 `35136450797` (professional UI + free-text/localization), CI #4 `35132170500` (first green AAB).

## UX-hardening changes already merged
- `mobile/lib/core/localized_domain_text.dart`: localized category names across all 8 locales and localized History match/session metadata.
- Interest editor and Interest DNA no longer expose raw English category keys.
- History no longer hard-codes English `matches · sessions`.
- AI normalized-interest category output is constrained server-side to canonical categories.
- Hidden Match reveal has light haptic feedback and subtle newest-card scale/fade animation.
- `mobile/test/layout_smoke_test.dart` covers 320dp + larger-text layouts for French Home, Portuguese onboarding, French QR, and long French match labels.

## Active QR transport reliability slice
Source/design notes: `docs/QR_TRANSPORT_V2.md` and `AI_STATE/MINI_HANDOFF_20260917_QR_COMPRESSION_START.md`.

Implemented code as of branch head before this handoff:
1. Existing semantic QR payload remains schema `v:1`.
2. Small profiles continue to emit legacy compact raw JSON for maximum compatibility.
3. Larger payloads adaptively emit `Z2:` + URL-safe base64(zlib(compact JSON)) only when above 420 raw UTF-8 bytes and compression is actually smaller.
4. New decoder accepts both legacy raw JSON and `Z2:` compressed transport.
5. Compressed transport restores stripped base64 padding and rejects malformed compressed data with `FormatException`.
6. Decompressed transport has a 64 KiB post-decompression guard.
7. Added QR tests covering:
   - small/raw legacy output + round-trip;
   - explicit legacy raw decoder compatibility;
   - 80-interest multilingual/custom profile compression + full metadata preservation;
   - compressed payload target under 2,000 UTF-8 bytes for the regression profile;
   - malformed compressed transport rejection;
   - existing custom metadata/canonical matching/zero-match tests remain.

Relevant commits:
- `e0c7894f04e80cb5452a13e934f63e1528ad493b` — initial adaptive compression implementation.
- `a4ac14715ba585b2e075c31ab1602e0a5ee4d29c` — Dart base64 padding fix.
- `c083340919f5758552f1fedf42ad03520295149d` — QR transport regression tests.

Authoritative validation run for this slice: CI #39 `35140541040`. At last check it was **pending/queued** with no jobs started yet. Do NOT claim the compressed QR slice green until analyze + tests + release AAB + artifact upload all succeed.

## Immediate next active task
1. Observe CI #39. If it fails, inspect exact analyzer/test/build logs and fix only evidenced errors until fully green.
2. Once #39 is green, improve Show QR scan reliability (quiet zone/module rendering/error-correction choice) only if compatible with the large-profile capacity target; add evidence-based QR-size/scan guardrails rather than aesthetic-only changes.
3. Continue focused visual QA: camera permission/error state, keyboard behavior, accessibility/font scaling and real-device scanner framing.
4. Obtain/discover production Vercel base URL and set `ZYNC_API_BASE`; currently unset, so CI builds deliberately use local question fallback and cannot AI-normalize unknown interests.
5. Configure production signing via GitHub Secrets with existing keystore alias/password; connector cannot safely write secrets.
6. Only after signed build + real-device visual/QR/scanner QA succeeds consider Play internal testing. Do not widen into Phase 2.

## Safety / scope guard
- `main` remains untouched; all work is on `zync-v1-rebuild-20260917`.
- Never commit secrets, API keys, keystores or passwords.
- Do not add Firebase/accounts/community/chat/location/social import/commerce to V1.
- Keep updating this file after meaningful slices so timeout/new chat can resume without rediscovery.

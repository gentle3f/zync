# Zync V1 — Latest Handoff

## Branch
`zync-v1-rebuild-20260917`

## Mission
Rebuild the old Thunkable Zync MVP as a modern, low-cost, international Flutter app while preserving the existing Google Play Android identity.

## Frozen V1 scope
Authoritative scope: `docs/ZYNC_V1_PRODUCT_SPEC.md`.

Core: local interest profile, multilingual canonical-interest model, QR peer exchange, local match detection, Hidden Match reveal, AI conversation questions, zero-match crossover questions, conversation modes, Zync Again history, Interest DNA, local fallback questions, Vercel/OpenRouter proxy. No login/Firebase/community/chat/location/social-import/commerce in V1.

## Non-negotiable quality bar
Professional consumer UI/UX and graphics are first-class release requirements, not optional polish. Visual source of truth: `docs/ZYNC_V1_VISUAL_SYSTEM.md`.

Current direction: warm premium-friendly social product; orange main accent, dark ink typography, warm cream surfaces, plum/mint secondary accents, rounded geometry, restrained shadows, recurring connection/network motif. Graphics in scope include in-app marks/motifs, app icon, splash/launch identity, QR/scanner presentation, loading/empty/error states.

## Existing Play compatibility
- applicationId: `com.gmail.gentle3f.myproject`
- existing known Play versionCode: 5
- V1 version: `1.0.0+6`
- targetSdk / compileSdk: 36, CI asserted
- Android display label: `Zync`
- final Android distribution artifact: AAB
- existing keystore stays outside source control; never commit keystore/password/secrets.

## Implemented V1 surface
- Flutter / Material 3 local-first app.
- 8 initial locales: EN / zh-Hant / zh-Hans / JA / KO / ES / FR / PT.
- Canonical interests with `love` / `like` / `wantToTry` strengths.
- Local profile/history via SharedPreferences.
- Interest onboarding/editor, search, free-text AI normalization, confirmation and local persistence.
- QR show/scan, local canonical matching, Hidden Match progressive reveal, zero-match crossover, Zync Again history, conversation modes, Interest DNA.
- Vercel `/api/v1/question` and `/api/v1/normalize-interest`; OpenRouter key stays server-side.
- Multilingual local fallback questions if AI/API is unavailable.
- Custom interests preserve readable label/category through local JSON and QR and match on deterministic canonical IDs.
- `.gitignore` protects env files, keystores/JKS/P12 and key.properties.

## UI/UX + graphics implemented
- `mobile/lib/ui/zync_design.dart`: reusable palette/theme/surfaces/icon tiles/custom-painted overlapping-rings `ZyncMark`/connection backdrop.
- Branded loading, Home, onboarding/editor, Show QR, scanner, Hidden Match, conversation, History, Interest DNA.
- Reproducible native Android launcher/adaptive/monochrome icon + pre/post Android 12 splash via `mobile/tool/apply_android_branding.py`.
- Localized domain/category text rather than raw internal keys.
- Hidden Match reveal has light haptic + subtle reveal animation.
- 320dp / long-translation smoke tests cover key consumer screens.

## QR transport and rendering — CERTIFIED
Design notes: `docs/QR_TRANSPORT_V2.md`.

- semantic payload remains schema `v:1`;
- small profiles keep legacy compact raw JSON;
- larger profiles adaptively use `Z2:` + URL-safe base64(zlib(compact JSON)) when useful;
- decoder accepts both legacy and compressed transports;
- malformed compressed payloads are rejected and decompression has 64 KiB guard;
- 80-interest multilingual/custom regression profile preserves metadata and stays under size target;
- Show QR uses responsive 180–300dp size, error correction M, gapless modules, clean white quiet-zone surface, localized semantics/error state;
- 320dp large-compressed-QR render test passes.

CI #41 `35141089002` on `dfa3a4a312169bb9ad632973ad4f559984674101` — **SUCCESS**.
Artifact `10465556475`, 60,752,363 bytes, digest `sha256:6df41d2534493108345f50d3855b566a2b76da72eb73a8268921bbcf766d9dcd`.

## Scanner recovery UX + international conversation — CERTIFIED
Current scanner behavior:
- `MobileScanner.errorBuilder` renders branded, nontechnical localized states for permission denied, unsupported camera and generic camera failure;
- permission/generic states have Retry recovery; unsupported-camera state explains Show My QR fallback;
- scanner frame/status overlay is hidden while camera is uninitialized/erroring;
- test coverage verifies Traditional Chinese permission state/retry and English unsupported-camera fallback, with no raw MobileScanner error text exposed.

Current cross-language conversation behavior:
- QR peer profile language is propagated from Match → Conversation;
- language tags are canonicalized by `mobile/lib/core/language_support.dart`;
- if peer language differs from local UI language, the question endpoint requests ONE semantic question plus an equivalent translation for the peer language;
- server parses a strict separator format rather than two independently generated questions;
- app displays primary + secondary language question, and local fallback also produces both languages when API is unavailable;
- same-language peers keep the normal single-question UI;
- tests cover language normalization, bilingual local fallback and narrow-phone bilingual conversation rendering.

CI #61 `35176798122` on `5c3b7f11d3bfb04300721508f5130cadeac58720` — **SUCCESS**.
Passed Play identity/branding assertions, localization generation, `flutter analyze`, all tests, release AAB build and artifact upload.
Artifact `10479296575`, 60,802,404 bytes, digest `sha256:b0e2ec36c40bd9175be7d0d2bc0fe3ce2ecb6f096b40a818c19d0b92e86b1bd9`.

## Production signing preparation — ACTIVE
Added:
- `mobile/tool/configure_android_signing.py`: patches a generated Flutter Android wrapper to use a dedicated `zyncRelease` config, validates key.properties/keystore presence, supports current Kotlin DSL plus Groovy fallback, and includes secret-free `--self-test` fixtures.
- `.github/workflows/zync-v1-signed-release.yml`: manual Play release workflow. It requires four GitHub Actions secrets, installs the keystore only in the ephemeral runner, preserves legacy Play identity + Zync branding, runs analyze/tests, builds the signed AAB, verifies the AAB JAR signature and uploads `zync-v1-play-signed-aab`.
- `docs/ANDROID_RELEASE_SIGNING.md`: exact secret names, safe local base64 commands, run instructions and Play upload-key warning.
- main CI now runs `python3 mobile/tool/configure_android_signing.py --self-test` before normal wrapper/build validation.

Required release secrets (not set/read by connector):
- `ZYNC_ANDROID_KEYSTORE_BASE64`
- `ZYNC_ANDROID_STORE_PASSWORD`
- `ZYNC_ANDROID_KEY_ALIAS`
- `ZYNC_ANDROID_KEY_PASSWORD`

Latest validation run for this signing-prep slice: CI #63 `35178685334`, head `205714fa6c15f3a9195b9314ae7bace1ff8005a6`. At last checkpoint it was starting Flutter setup; do not call signing-prep fully green until self-test + normal analyze/tests/AAB/artifact complete.

## Vercel/API status
- Main CI already reads repository variable `ZYNC_API_BASE` and injects it as a Dart define.
- Signed-release workflow does the same.
- Vercel connector currently returns no connected teams/projects, so it cannot discover the existing production Zync Vercel base URL.
- Until `ZYNC_API_BASE` is configured, builds intentionally fall back to local questions and cannot AI-normalize unknown interests. Do not invent/guess the production URL.

## Immediate next active task
1. Finish CI #63. If it fails, inspect exact logs and fix only evidenced errors; if green, record artifact metadata and certify signing-prep helper/main-CI integration.
2. Do not manually run the signed-release workflow until the four real upload-key secrets are configured; a failure caused only by missing secrets gives no useful evidence.
3. Once user/account access provides the existing Vercel production URL, set repository variable `ZYNC_API_BASE` and verify real AI normalize/question requests against that deployment.
4. Once the existing upload-key keystore alias/password are available in GitHub Secrets, run **Zync V1 Signed Release** and verify its artifact before Play internal testing.
5. Real-device QA still required before release: camera permission flows, physical QR scan reliability across small/large profiles, launch icon/splash, long locale text and actual two-device bilingual interaction.
6. Do not widen into Phase 2.

## Safety / scope guard
- `main` remains untouched; all work is on `zync-v1-rebuild-20260917`.
- Never commit secrets, API keys, keystores or passwords.
- Do not add Firebase/accounts/community/chat/location/social import/commerce to V1.
- Keep updating this file after meaningful slices so timeout/new chat can resume without rediscovery.

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
- Regression tests for QR round-trip, custom metadata, canonical matching and zero-match readiness.
- `.gitignore` protects env files, keystores/JKS/P12 and key.properties.

## Professional UI/UX + graphics implemented
- `mobile/lib/ui/zync_design.dart`: reusable Zync visual system, palette, theme, surfaces, icon tiles, custom-painted overlapping-rings `ZyncMark`, connection backdrop.
- Branded loading state.
- Branded Home hub with primary Show QR / Scan actions.
- Polished onboarding/interest editor with AI-add confirmation, selection/strength states and persistent bottom action.
- Branded Show QR card and privacy explanation.
- Full-camera scanner with branded scan frame/line/status panel.
- Hidden Match signature screen with connection graphics and progressive reveals.
- Conversation mode chips + branded AI question surface + intentional offline fallback state.
- Polished History cards/empty state.
- Visual Interest DNA ranking/progress surface.
- `docs/ZYNC_V1_VISUAL_SYSTEM.md` defines release visual/QA bar.

## Native Android branding — CERTIFIED
`mobile/tool/apply_android_branding.py` makes branding reproducible after CI generates the legacy-identity Android wrapper. It controls app label, CAMERA permission, SDK pins, Zync launcher artwork, adaptive icon resources, Android 13 monochrome icon, pre-Android-12 launch background, and Android 12+ system splash styling.

The launcher/splash artwork is source-controlled vector artwork based on the same orange/plum overlapping-rings connection motif; the manifest-selected launcher is no longer Flutter default artwork.

CI run #34 `35137432743` on commit `c79f508bb8108801981993540c11458162358f9d` — **SUCCESS**. It passed brand/identity assertions, localization generation, `flutter analyze`, tests, release AAB build and artifact upload.

Run #34 artifact:
- id `10463318979`
- size 60,695,415 bytes
- digest `sha256:fc0b9a415f9be41c485fc106b99f1b737aa4968b48cae098e908e5ea03a29dff`
- unsigned / not yet production Play-signed.

## Other verified build checkpoints
- CI #32 `35136450797` — SUCCESS for full professional UI + free-text interest + localization slice. Artifact id `10463871361`, digest `sha256:5626dd2149b143b35345ea386afb8d043a46b1e01700f3b5ec2f99e12d06a55a`.
- First green CI #4 `35132170500`, artifact id `10461389685`.

## Current UX-hardening batch
Functional batch commit: `5c68783bcdaf5a9c2e4bec21d1cbfcb9b8547586`. A later `mobile/BUILD_STATE.md` checkpoint commit (`958fedf05cae2da8653ce42c3b26485b9b4d793f`) exists only to ensure the full batch receives a normal push-triggered CI run.

Changes in this batch:
1. Added `mobile/lib/core/localized_domain_text.dart` with localized category names across all 8 locales and localized History match/session metadata.
2. Interest editor now shows localized category names rather than raw English category keys.
3. Interest DNA category labels are localized.
4. History no longer exposes hard-coded English `matches · sessions` metadata.
5. `/api/v1/normalize-interest` now constrains model output to the canonical category set (`sports`, `motorsport`, `entertainment`, `gaming`, `music`, `travel`, `food`, `technology`, `arts`, `learning`, `transport`, `outdoors`, `collecting`, `other`), server-validates it, and falls back to `other` instead of allowing arbitrary category strings.
6. Hidden Match reveal now adds a light haptic and subtle ~220 ms newest-card scale/fade animation without delaying the flow.
7. Added `mobile/test/layout_smoke_test.dart` covering 320dp narrow layouts / larger text for French Home, Portuguese onboarding, French QR handoff, and long-label French Hidden Match reveal.

Validation: CI run #36 `35138218437` is the authoritative current run. At the latest checkpoint it has PASSED Android wrapper/identity/branding, localization, `flutter analyze`, and **all tests including the new narrow-layout smoke tests**. Release AAB build is still in progress. Do not call this batch fully green until AAB build + artifact upload finish.

## Newly identified core UX risk to address next
QR payload is currently plain JSON and includes full custom labels/categories. Because the product encourages users to build a large interest profile, a high-interest-count profile can create an unnecessarily dense/large QR and eventually hurt scan reliability or exceed practical QR capacity. Before release, implement a compact/compressed QR payload while retaining decoder compatibility with the current/plain payload and add a payload-size regression test. This is a V1 reliability issue, not Phase 2 scope expansion.

## Immediate next active task
1. Finish observing authoritative CI #36. If AAB fails, inspect exact logs and fix only evidenced errors; otherwise record artifact metadata in this handoff.
2. Implement backward-compatible compact/compressed QR payload and tests for a realistically large profile; preserve local/no-server architecture.
3. Continue focused visual QA: text overflow, keyboard behavior, accessibility/font scaling, QR quiet zone/scan reliability, and camera permission/error states.
4. Obtain/discover production Vercel base URL and set `ZYNC_API_BASE`; currently unset, so CI builds deliberately use local question fallback and cannot AI-normalize unknown interests.
5. Configure production signing via GitHub Secrets with existing keystore alias/password; connector cannot safely write secrets.
6. Only after signed build + real-device visual/QR/scanner QA succeeds consider Play internal testing. Do not widen into Phase 2.

## Safety / scope guard
- `main` remains untouched; all work is on `zync-v1-rebuild-20260917`.
- Never commit secrets, API keys, keystores or passwords.
- Do not add Firebase/accounts/community/chat/location/social import/commerce to V1.
- Keep updating this file after meaningful slices so timeout/new chat can resume without rediscovery.

# Zync V1 — Latest Handoff

## Branch
`zync-v1-rebuild-20260917`

## Mission
Rebuild the old Thunkable Zync MVP as a modern, low-cost, international Flutter app while preserving the existing Google Play Android identity.

## Frozen V1 scope
Authoritative product scope: `docs/ZYNC_V1_PRODUCT_SPEC.md`.

Core: local interest profile, multilingual canonical-interest model, QR peer exchange, local match detection, hidden-match reveal, AI conversation questions, zero-match crossover questions, conversation modes, Zync Again history, Interest DNA, local fallback questions, Vercel/OpenRouter proxy. No login/Firebase/community/chat/location/social-import/commerce in V1.

## Non-negotiable product-quality bar
The shipped UI/UX must look professional, not like a default Flutter demo or functional prototype. This is a first-class V1 requirement.

Graphics are also in scope end-to-end: in-app vector graphics/motifs, app icon, splash/launch identity, empty/loading/error states, QR/scanner presentation, and any illustrations/assets needed for a coherent production release. Do not leave graphics for the user to source separately.

Visual source of truth: `docs/ZYNC_V1_VISUAL_SYSTEM.md`.

Current visual direction: premium-friendly, warm, modern social product; orange as the main Zync accent, dark ink typography, warm cream surfaces, plum/mint secondary accents, generous rounded geometry, restrained shadows, and a recurring connection/network motif. Avoid generic Material defaults where a branded treatment materially improves the experience.

## Existing Play compatibility
- Android applicationId: `com.gmail.gentle3f.myproject`
- Current known Play versionCode: 5
- New versionCode: >= 6 (`mobile/pubspec.yaml` currently `1.0.0+6`)
- targetSdk / compileSdk: explicitly pinned and CI-asserted at 36
- Android display label: explicitly set and CI-asserted as `Zync`
- Final artifact: Android AAB
- Existing keystore supplied by user separately; never commit it or its password.

## Implemented V1 surface
1. Frozen product scope in `docs/ZYNC_V1_PRODUCT_SPEC.md`.
2. Flutter project definition, Material 3 app shell and local-first architecture.
3. Canonical interest model with `love` / `like` / `wantToTry` strengths.
4. Multilingual seed catalog across EN / zh-Hant / zh-Hans / JA / KO / ES / FR / PT.
5. Local-only profile + Zync history persistence with SharedPreferences.
6. Interest onboarding/editor, home hub, QR display, QR scanner, canonical local matching, Hidden Match reveal, zero-match path, conversation modes, Zync Again history, and Interest DNA.
7. Vercel `POST /api/v1/question` using server-side `OPENROUTER_API_KEY` (legacy `API_KEY` fallback), optional `OPENROUTER_MODEL`, bounded request parsing, and no mutable prompt fetch.
8. Multilingual local question fallback when API is missing/unavailable.
9. Vercel `POST /api/v1/normalize-interest`, which normalizes arbitrary free text into a stable English concept and deterministic `custom.<sha256-prefix>` ID without any user database.
10. Free-text interest UI is wired to normalization: unknown typed interests can be AI-normalized, shown for user confirmation, added locally, assigned a strength, persisted, carried through QR, matched canonically, revealed with a readable label, included in Interest DNA, and sent to question generation as a readable label rather than an opaque ID.
11. `SelectedInterest` preserves optional custom label/category in local JSON and backward-compatible variable-length QR interest tuples; QR schema remains version 1 for existing seed payloads.
12. Added custom-interest regression tests for QR metadata round-trip and shared-match readable metadata preservation.
13. AI-interest UI strings are localized in JA / KO / ES / FR / PT as well as EN / Chinese locales.
14. `.gitignore` protects env files, keystores/JKS/P12, key.properties and generated Flutter files.

## Professional UI/UX + graphics pass implemented so far
- `mobile/lib/ui/zync_design.dart` is the reusable visual system.
- Added branded `ZyncTheme`, palette, surface treatment, icon tiles, custom-painted `ZyncMark`, and connection-network background graphics.
- Reworked app loading state so it uses Zync branding instead of a generic spinner-only screen.
- Rebuilt Home into a branded hub with clear primary/secondary Zync actions and stronger information hierarchy.
- Rebuilt onboarding / interest editing with branded profile setup, search, AI-add flow, selected-count state, custom-interest indicator, strength control and persistent bottom action.
- Reworked Show QR into a clean branded handoff card with stronger QR contrast and privacy explanation.
- Reworked Scan QR into a full-camera branded scanner with custom-painted corner frame, scan line, status panel and better error/loading feedback.
- Reworked Hidden Match reveal with branded connection graphics, progressive reveal cards, strength treatments and better zero-match state.
- Reworked Conversation with visual mode chips, branded AI question surface and clear offline-fallback treatment.
- Reworked Zync History with polished cards and a designed empty state.
- Reworked Interest DNA into a more visual ranked profile with branded progress treatments.

## Verified build history
### First green AAB
- CI run #4: `35132170500` — SUCCESS.
- Artifact id `10461389685`; digest `sha256:c95a3ed56cdae738925b578ab7a59f28f0d6347009afcdd2befb15554a80e900`.

### Full UI/free-text/localization green checkpoint
- CI run #32: `35136450797` — **SUCCESS**.
- Passed generated Android wrapper, exact Play identity + SDK checks, localization generation, `flutter analyze`, all tests, release AAB build and artifact upload.
- Artifact id `10463871361`; size 60,696,747 bytes; digest `sha256:5626dd2149b143b35345ea386afb8d043a46b1e01700f3b5ec2f99e12d06a55a`.
- This certifies the professional UI pass + free-text interest + all current localization code through commit `30cd10063e0a782dd68bc53c95020afbce28e847` compiles into an AAB.

## Current graphics/Android branding active slice
1. Added `docs/ZYNC_V1_VISUAL_SYSTEM.md` as visual/QA source of truth.
2. Added `mobile/tool/apply_android_branding.py` to make Android branding reproducible after CI generates the Flutter wrapper.
3. Branding script now controls app label, CAMERA permission, SDK pins, Zync launcher artwork, adaptive icon resources, Android 13 monochrome icon, pre-Android-12 launch background and Android 12+ system splash styling.
4. Launcher/splash mark uses source-controlled vector artwork matching the in-app overlapping-rings connection motif; no Flutter default icon should remain as the manifest-selected launcher resource.
5. CI workflow now calls the branding script and asserts the Zync launcher/splash resources and launch theme before analysis/build.
6. Branding validation CI run #34: `35137432743` on commit `c79f508bb8108801981993540c11458162358f9d` is currently in progress. At last check wrapper generation, brand/identity assertions, localization, `flutter analyze` and `flutter test` had passed; release AAB build was still running. Do not claim the native icon/splash layer fully certified until this run completes successfully.

## Known polish issues found during static QA
These should be handled after branding CI is certified:
- Add small-screen / large-text widget smoke tests for the main non-camera screens.
- `HistoryScreen` still contains hard-coded English `matches · sessions` metadata.
- Seed/custom category labels are currently exposed as raw English category keys in some screens; localize category display for all eight initial locales and constrain AI-normalized categories to the canonical category set.
- Do a final text-overflow/keyboard/accessibility pass before visual sign-off.

## Immediate next active task
1. Finish observing CI run #34. If the AAB build fails, inspect exact logs and fix only evidenced Android resource/branding errors until green.
2. Add layout regression smoke tests for small-width + long-translation screens.
3. Localize category display and History metadata; constrain AI category output to canonical category keys.
4. Add subtle haptic/motion polish to the Hidden Match reveal without slowing the flow.
5. Discover or obtain the production Vercel base URL and set repository variable `ZYNC_API_BASE`; it is currently unset in CI, so builds deliberately use local question fallback and cannot AI-normalize unknown interests until configured.
6. Configure production signing through GitHub Secrets using the user's existing keystore; GitHub connector cannot safely write secrets. Need keystore alias/password handled outside source control.
7. Only after signed build + visual/device QA succeeds consider Play internal testing. Do not widen into Phase 2.

## Safety / scope guard
- `main` remains untouched. All work is on `zync-v1-rebuild-20260917`.
- Never commit secrets, API keys, keystores or passwords.
- Do not add Firebase/accounts/community/chat/location/social import/commerce to V1.
- Keep updating this file after meaningful slices so timeout/new chat can resume without rediscovery.

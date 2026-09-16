# Zync V1 — Latest Handoff

## Branch
`zync-v1-rebuild-20260917`

## Mission
Rebuild the old Thunkable Zync MVP as a modern, low-cost, international Flutter app while preserving the existing Google Play Android identity.

## Frozen V1 scope
Authoritative product scope: `docs/ZYNC_V1_PRODUCT_SPEC.md`.

Core: local interest profile, multilingual canonical-interest model, QR peer exchange, local match detection, hidden-match reveal, AI conversation questions, zero-match crossover questions, conversation modes, Zync Again history, Interest DNA, local fallback questions, Vercel/OpenRouter proxy. No login/Firebase/community/chat/location/social-import/commerce in V1.

## Non-negotiable product-quality bar
The user explicitly requires the shipped UI/UX to look professional, not like a default Flutter demo or a functional prototype. This is now a first-class V1 requirement, not optional polish.

Graphics are also in scope. We own the visual system end-to-end: in-app vector graphics/motifs, app icon, splash/launch identity, empty/loading/error states, QR/scanner presentation, and any illustrations or graphical assets needed for a coherent production release. Do not leave graphics for the user to source separately.

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
13. AI-interest UI strings are now localized in JA / KO / ES / FR / PT as well as the existing EN / Chinese locales.
14. `.gitignore` protects env files, keystores/JKS/P12, key.properties and generated Flutter files.

## Professional UI/UX + graphics pass now implemented
- Added `mobile/lib/ui/zync_design.dart` as the reusable visual system.
- Added branded `ZyncTheme`, palette, surface treatment, icon tiles, custom-painted `ZyncMark`, and connection-network background graphics.
- Reworked the app loading state so it uses Zync branding instead of a generic spinner-only screen.
- Rebuilt Home into a branded hub with clear primary/secondary Zync actions and stronger information hierarchy.
- Rebuilt onboarding / interest editing with branded profile setup, search, AI-add flow, selected-count state, custom-interest indicator, strength control and persistent bottom action.
- Reworked Show QR into a clean branded handoff card with stronger QR contrast and privacy explanation.
- Reworked Scan QR into a full-camera branded scanner with custom-painted corner frame, scan line, status panel and better error/loading feedback.
- Reworked Hidden Match reveal with branded connection graphics, progressive reveal cards, strength treatments and better zero-match state.
- Reworked Conversation with visual mode chips, branded AI question surface and clear offline-fallback treatment.
- Reworked Zync History with polished cards and a designed empty state.
- Reworked Interest DNA into a more visual ranked profile with branded progress treatments.

This is the beginning of the production polish pass, not the final visual sign-off. Before release, still do real-device/screenshot QA for text overflow, keyboard behavior, accessibility contrast, small/large Android screens, long translations, scanner framing, QR scan reliability, and animation feel. Final app icon + splash/launch graphics still need to be produced and integrated.

## Verified build history
### First green AAB
- CI run #4: `35132170500` — SUCCESS.
- Passed wrapper generation, exact package-ID check, pub get, gen-l10n, analyze, tests, release AAB build and artifact upload.
- Artifact id `10461389685`; digest `sha256:c95a3ed56cdae738925b578ab7a59f28f0d6347009afcdd2befb15554a80e900`.

### Current UI/UX validation checkpoint
- Latest mobile source head before this handoff-only commit: `30cd10063e0a782dd68bc53c95020afbce28e847`.
- Latest queued CI run: #32 `35136450797`.
- Immediately preceding run #31 `35136415408` already passed wrapper generation, Play identity / SDK checks, pub get, localization generation, `flutter analyze`, and `flutter test`; at last check it was building the release AAB.
- Run #32 was still pending at last check because a previous run was occupying the branch concurrency slot.
- Do not claim the full latest UI/UX + PT-localization head is green until run #32 completes build + artifact upload successfully.

## Immediate next active task
1. Finish observing CI run #32. If it fails, inspect exact logs and fix only evidenced errors until green.
2. Perform a focused visual QA pass screen-by-screen after a successful build: onboarding, home, QR, scanner, match, conversation, history, Interest DNA; fix overflow/tap-target/keyboard/accessibility issues before visual sign-off.
3. Produce and integrate the final Zync app icon and splash/launch graphics, using the same connection-mark visual language rather than generic stock imagery.
4. Discover or obtain the production Vercel base URL and set repository variable `ZYNC_API_BASE`; it is currently unset in CI, so builds deliberately use local question fallback and cannot AI-normalize unknown interests until configured.
5. Configure production signing through GitHub Secrets using the user's existing keystore; GitHub connector cannot safely write secrets. Need keystore alias/password handled outside source control.
6. Only after signed build + visual/device QA succeeds consider Play internal testing. Do not widen into Phase 2.

## Safety / scope guard
- `main` remains untouched. All work is on `zync-v1-rebuild-20260917`.
- Never commit secrets, API keys, keystores or passwords.
- Do not add Firebase/accounts/community/chat/location/social import/commerce to V1.
- Keep updating this file after meaningful slices so timeout/new chat can resume without rediscovery.

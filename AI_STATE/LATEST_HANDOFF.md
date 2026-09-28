# Zync — Latest Handoff

## Mandatory first read

Read and obey `AI_STATE/OPERATING_RULES.md` before any write, commit, push, PR,
CI, Vercel, deployment or external-infrastructure action.

CURRENT AUTHORITATIVE PLATFORM CONTINUATION — EXPLICIT RELEASE VERSIONING:
Production signed-release runs now require explicit version_name + version_code;
there are no defaults. Flutter receives them through --build-name/--build-number,
and a new release_version.py validates numeric major.minor.patch names,
versionCode bounds and AGP's actual packaged-manifest output. A real stable-signed
QA proof APK was built as
C:\Users\FUJITSU\Zync-QA-Version-Proof-1.0.1-7-20260928.apk and independently
verified as package com.gmail.gentle3f.myproject.qa, versionName 1.0.1,
versionCode 7, stable QA signer SHA-1
E9:00:0B:0A:A3:AE:B6:2E:FF:5D:C3:C9:D1:3E:9B:7B:61:81:1F:1D, APK SHA-256
BBB1AFEDE45E9DDE81F2523D37E7CEAD3D7A93759F69D8BCF6B1EBC1E804F1DA.
Signed-AAB metadata now carries separate version_name/version_code, the
provenance verifier validates them and can export only validated values to
GitHub step outputs, and Play Internal passes that verified versionCode to the
publisher. After upload, the publisher compares Google's returned versionCode
with signed-release provenance; mismatch aborts before track update and the
existing failure path deletes the edit. release_version_contracts.mjs locks the
full chain and Play contracts also require the versionCode handoff. Validation:
release-version self-test, real AGP metadata 1.0.1+7, real final APK 1.0.1+7,
stable signer verification, provenance self-test including wrong-version
rejection, GitHub-output probe using the real stable AAB, publisher self-test,
release-version contracts, Play contracts, workflow YAML and diff checks all
PASS. Google Play remains the final authority for historical versionCode
uniqueness. No Actions run, Play upload, Vercel or production deployment was
performed.

`AI_STATE/HANDOFF_20260928_RELEASE_VERSIONING.md`

Previous platform checkpoint — STABLE QA AAB + PLAY PROVENANCE:
Current Zync source and the dedicated stable QA signer now produce a real release
Android App Bundle at
`C:\Users\FUJITSU\Zync-QA-Stable-20260928.aab` (80,351,983 bytes), signed by
the stable QA certificate SHA-1
`E9:00:0B:0A:A3:AE:B6:2E:FF:5D:C3:C9:D1:3E:9B:7B:61:81:1F:1D`, with AAB
SHA-256
`5D7BCDC16ABE6F20E47A5CDC047E36A72FD6F5933688513C0899B5261A248DAE`.
Direct inspection confirms the real Google Web/server client ID is embedded in
the release app binaries. This AAB exposed a real release-pipeline bug:
`jarsigner -verify` succeeds, but `jarsigner -verify -strict` exits 4 on the
current Android bundle due to non-security JarFile/JarInputStream warnings, so
the previous signed-release and Play Internal workflows would reject a valid
bundle. A new `.github/scripts/verify_signed_aab.py` now verifies SHA-256,
signer SHA-1, package, version, source SHA and selected signed-release run ID.
The signed-release workflow uploads the AAB plus SHA-256/build-metadata sidecars;
Play Internal requires all three from the exact selected run, re-verifies the
JAR signature, extracts the actual signer and validates provenance before any
Play API call. The publisher keeps its independent exact-package/internal-track/
signature/credentials/edit-cleanup guards. Runtime strict-jarsigner references
are now zero. Validation includes verifier self-test, publisher self-test, a real
stable AAB through both guards, wrong-package and wrong-run rejection, Play
release contracts, JavaScript syntax, all 8 workflow YAML files and diff check.
The full release_web_contracts suite is not runnable on this card-art branch
because it lacks api/v1/interest-popularity.js; its modified file passes syntax
and the signed-release assertions were checked directly. No Actions workflow,
Play upload, Vercel or production deployment was run.

`AI_STATE/HANDOFF_20260928_PLAY_AAB_PROVENANCE_GUARD.md`

Previous platform checkpoint — STABLE ANDROID QA SIGNING:
Android QA now has a dedicated stable signer, separate from production signing. The local keystore is `C:\Users\FUJITSU\.zync\qa-signing\zync-qa.jks`, protected by explicit non-inherited ACLs and never source-controlled. Stable QA signer SHA-1 is `E9:00:0B:0A:A3:AE:B6:2E:FF:5D:C3:C9:D1:3E:9B:7B:61:81:1F:1D` (valid to 2054-02-13). A current stable-signed release APK was built successfully at `C:\Users\FUJITSU\Zync-QA-Stable-20260928.apk`, package `com.gmail.gentle3f.myproject.qa`, label `Zync QA Local`, 90,520,315 bytes, APK Signature Scheme v2 verified, APK SHA-256 `A7FFC73FD6D63E61F276DC14DB3DB412E485FF3AC322EA80A42FF121C061F121`. Direct APK inspection confirms the real Google server client ID is embedded in the release app binaries. `configure_android_signing.py` was fixed for two real current-toolchain issues: Gradle 9/Kotlin DSL `java` extension shadowing of `java.util/java.io`, and Windows `key.properties` backslash escaping that corrupted absolute keystore paths. QA preview signing is now separated from production with dedicated `ZYNC_ANDROID_QA_*` secrets plus pinned variable `ZYNC_ANDROID_QA_SHA1`; the workflow fails if the built signer does not match the pinned OAuth certificate. Production still uses separate `ZYNC_ANDROID_*` names and does not consume the QA key. The non-secret QA SHA-1 variable is already set in GitHub. All four QA-only signing secrets are now configured in GitHub under the dedicated `ZYNC_ANDROID_QA_*` namespace, and the pinned `ZYNC_ANDROID_QA_SHA1` variable is present. Their values were piped directly from the protected local signer and were never printed or committed. Production `ZYNC_ANDROID_*` signing secrets were not populated or changed. Secret/variable installation triggered no GitHub Actions run. The active local gcloud account cannot see Google project number `809680073916`, so no OAuth client was created or changed in the wrong project. Remaining Android QA gates are Google Android OAuth registration/verification for the stable package/SHA-1 pair and physical-device Google/session/provider-link/reward smoke.

`AI_STATE/HANDOFF_20260928_ANDROID_STABLE_QA_SIGNING.md`

Previous platform checkpoint — CURRENT ANDROID QA APK:
The old Android compile-proof blocker is now closed. A fresh current-source QA
wrapper from HEAD `711d0b3` successfully builds an installable APK on GEN-FUJI.
The successful artifact is
`C:\Users\FUJITSU\Zync-QA-Google-Current-20260928.apk`, package
`com.gmail.gentle3f.myproject.qa`, label `Zync QA Local`, minSdk 24,
targetSdk 36. APK Signature Scheme v2 verifies. The real repository
`ZYNC_GOOGLE_SERVER_CLIENT_ID`
(`809680073916-4a0girebokh8qdqqho1jr92b74vov7on.apps.googleusercontent.com`)
was injected, and direct APK inspection confirms that client ID is present in
`assets/flutter_assets/kernel_blob.bin`. Current debug signer certificate SHA-1
is `10:F4:27:CD:6E:CF:A5:38:0C:E3:3B:A5:0F:63:98:37:FB:69:8B:A8`; APK
SHA-256 is
`EA731AD3076C0ED60D3BAFBC58D5D22903976AF9903F237588A45D23778F5146`.
Earlier Android build failures were traced to duplicate concurrent
`assembleDebug` processes racing on `mergeDebugAssets`; a clean single-process
build succeeds. No Android device was attached, so Google chooser/session and
reward/provider-link physical smoke are not claimed. Repository secret names
currently do not include the four expected Zync Android signing secrets, so the
remaining Android release gates are stable QA signing, Google Android OAuth
registration for the chosen stable signer SHA-1, a stable signed QA APK and
physical-device smoke. No Actions, Vercel, Play or production deployment was
used.

`AI_STATE/HANDOFF_20260928_ANDROID_QA_APK_COMPILE.md`

Previous platform checkpoint — SAME-WORLD PROVIDER LINKING:
Zync now supports server-authoritative Google/Apple provider linking for an
already signed-in Cardverse-backed Zync World. Linking requires the existing
secure bearer session, a fresh provider-specific one-time challenge and fresh
provider verification using the exact nonce, then calls the existing
`/api/v1/cardverse/auth/link` route. The client never sends accountId. 401 clears
the stale local session; 409 preserves the current session. The two backend
conflicts stay distinct: `cardverse_identity_already_linked` means that exact
identity belongs to another Zync World, while `cardverse_provider_already_linked`
means this world already has another identity for the same provider. Zync does
not automatically merge or overwrite either world. Signed-in iOS Account now
shows “Keep one Zync World across devices” with Google/Apple re-verification;
privacy copy says People history/private conversations remain local-first. Since
the backend has no linked-provider inventory endpoint, the UI only shows
“linked this visit” after a successful link and does not persist a fake provider
list. QA Account Lab exposes provider-link diagnostics. Server unlink exists but
revokes all active sessions and forbids removing the last identity, so destructive
unlink UI is deliberately deferred. Validation: focused identity/link/session/
proof suite 34/34 PASS; full Flutter analyze No issues; canonical non-golden
regression 379/379 PASS across 62 files; fresh generated iOS wrapper Google +
Apple + link + provider UI suite 29/29 PASS. Manual iOS compile-smoke remains
workflow_dispatch-only and was not run. No backend/economy/RNG/Card FX/Vercel/
Actions/Play/App Store/paid-generation action was taken.

`AI_STATE/HANDOFF_20260928_PROVIDER_LINK_RECOVERY.md`

Previous platform checkpoint — SIGN IN WITH APPLE + iOS ACCOUNT:
Zync now has a complete source-level Apple primary-account path on iOS. The app
uses exactly pinned `sign_in_with_apple 8.2.0`; the exact Cardverse one-time
nonce is passed unchanged into Apple's native request and the returned identity
token is exchanged through the existing provider-auth endpoint. Challenge and
auth responses both fail closed if the provider is not `apple`, and the
Cardverse session is persisted only after those checks. The generated iOS wrapper
now gets a reproducible `Runner.entitlements`, Sign in with Apple capability
metadata and CODE_SIGN_ENTITLEMENTS wiring for Debug/Release/Profile. Production
Account UI shows the official Apple button only on iOS; Android never exposes it.
Account Lab includes Apple diagnostics. The manual macOS compile-smoke workflow
remains workflow_dispatch-only and now verifies Apple capability/dependency/nonce
wiring plus Google+Apple tests. Fresh generated iOS wrapper validation: 16/16
identity/auth/provider-UI tests PASS. Repo focused auth/session/proof regression:
21/21 PASS. Full Flutter analyze: No issues found. Real Apple Developer App-ID
capability, server `ZYNC_APPLE_CLIENT_IDS`, signing/provisioning and physical
iPhone smoke are still release gates. No backend/economy/RNG/Card FX/Play/App
Store/Vercel/paid-generation action was taken.

`AI_STATE/HANDOFF_20260928_APPLE_AUTH_IOS.md`

Previous platform checkpoint — REPRODUCIBLE MOBILE PACKAGING + iOS:
Zync now has one reproducible generated-wrapper path for Android and iOS. The
shared generator copies lib/test/config **and mobile/assets**, closing the old
Android packaging gap that could omit locked Card FX frames and SFX. The Android
QA/CI/release wrappers now use this generator, representative Card FX assets are
explicitly checked, and QA package/label variants use a reusable source-controlled
patcher instead of duplicated inline workflow code. iOS now has deterministic
Zync AppIcon/LaunchScreen, camera permission and bundle identity. Google identity
on iOS uses the official `google_sign_in_ios` plugin from Dart with a dedicated
iOS client ID, the Web/server client ID and the exact Cardverse one-time nonce;
the generated AppDelegate stays Flutter-default and Android keeps its Credential
Manager MethodChannel. Web remains fail-closed. A macOS unsigned iOS compile-smoke
workflow exists as manual `workflow_dispatch` only and was not run. Cardverse's
backend lineage already supports Apple issuer/JWKS/audience + nonce challenges,
so Sign in with Apple is the next major iOS auth milestone. Validation: fresh
Android/iOS wrapper probes PASS; fresh generated-iOS identity tests 7/7 PASS;
repo identity tests 7/7 PASS; full Flutter analyze No issues; workflow YAML
parses; an earlier complete non-golden suite passed 360/360. A final rerun reached
253 tests without failure but its background shell ended without an exit marker,
so it is not counted as a completed pass. A current local Android debug build
also reached assembleDebug but ended without an exit marker and emitted no APK,
so local APK compile proof remains open. The missing legacy Card Art golden
baseline remains untouched. Stable Android QA signing/OAuth SHA-1 and real iOS
OAuth/Apple signing remain release gates.

`AI_STATE/HANDOFF_20260928_MOBILE_PACKAGING_IOS_FOUNDATION.md`

Previous product checkpoint — REWARD REVEAL TURN + RARITY SFX:

CURRENT AUTHORITATIVE PRODUCT CONTINUATION — REWARD REVEAL TURN + RARITY SFX:
The formal locked-frame reward renderer remains authoritative, but the production
reveal flows are now reconnected to the previously accepted Card FX reveal stage
instead of directly swapping card back -> front. Single Draw and every one of the
five Pack receipt cards now route through `ZyncFxRevealStage`: settled Z card
back -> 3D turn -> formal `CardverseRewardCard` front -> shared reward bloom ->
rarity-specific payoff, with the existing Legendary finale haptic path preserved.
Browser audio is primed synchronously from the actual Reveal button gesture so
the delayed flip/bloom/rarity cues are authorized in Chrome. Pack receipt cursor
advancement now occurs only after the reveal timeline completes; the remaining
face-down stack stays behind the active card. B — Split Open wrapper mechanics
and accepted wrapper audio are unchanged. Validation: focused Single Draw/Pack/
Card FX/Reward Lab suite 16/16 PASS; expanded card render 2/2 PASS; targeted
Flutter analyze No issues found; git diff --check clean. No RNG/economy/backend,
Actions, Vercel, Production, Play or paid-generation changes were made.

`AI_STATE/HANDOFF_20260928_REWARD_REVEAL_TURN_RARITY_SFX.md`

Previous product checkpoint — FORMAL REWARD CARDS + SINGLE DRAW SFX:

`AI_STATE/HANDOFF_20260928_REWARD_REVEAL_FORMAL_CARD_SFX.md`

Previous product checkpoint — REWARD REVEAL TEST LAB + GOOGLE AUTH DIAGNOSTICS:
A dedicated local Reward Reveal Test entrypoint now exposes the two production
presentation flows directly with immutable proof receipts: Single Draw — 1 Card
(no wrapper; card back -> Reveal -> suspense -> flip/bloom/rarity payoff -> real
front) and Pack Opening — 5 Cards (production B — Split Open; five-layer stack
visible through the first physical split -> full-stack extraction -> sequential
five-card reveal -> recap). No account/token/inventory/backend RNG/economy change
is required to test. Google linking was also separated into its real failure
boundaries: Chrome/web currently has no Google identity implementation and now
fails/labels that explicitly instead of looking like a generic OAuth failure;
production/QA account UI disables Google linking when the Android native bridge
is unavailable. Android's historical chooser-return failure remains most strongly
explained by old QA APKs being signed by different ephemeral debug certificates,
while Google Android OAuth requires the Android client to match package + signing
SHA-1. Existing fail-closed stable QA signing direction is preserved. Current
official Android guidance confirms the wrapper's MutableContextWrapper(Activity)
pattern is correct; nonce/JWT/session validation is unchanged. Validation:
combined focused reward/pack/single/Google run 15/15 PASS; latest Reward Lab +
Google auth subset 7/7 PASS; targeted flutter analyze No issues; Android wrapper
self-test PASS; git diff --check clean. Local Reward Reveal Lab served HTTP 200
on port 7358. No Android device/emulator was attached, so no fresh native
credential exchange is claimed.

`AI_STATE/HANDOFF_20260927_REWARD_REVEAL_LAB_GOOGLE_AUTH_DIAGNOSTICS.md`

Previous product checkpoint — REWARD REVEAL FLOW SPLIT:
Production reward presentation is now explicitly separated into two flows.
Single Draw stays a dedicated one-card reveal with no booster wrapper or pack
stack: one card back -> Reveal -> suspense -> flip -> shared bloom -> rarity
payoff -> real immutable receipt card front. Production Pack Opening stays B —
Split Open and now treats its immutable five-card receipt as a physical stack:
five layered card backs are already present through the first real center split,
the full stack extracts at the unchanged 70% commit threshold, then the receipt
cards reveal sequentially one at a time with the remaining face-down stack
visible behind the active card before the existing five-card recap. The early
production regression checks an actual ~14% B pull (>10 px gap) with all five
stack layers present. Existing accepted B audio, flip/bloom/payoff family,
reduced-motion behavior, RNG, rarity, receipt order/semantics, backend, economy,
locked frames, My Zync World/onboarding work and release systems are unchanged.
Validation: focused reward/Card FX tests 12/12 PASS; targeted flutter analyze
No issues found; git diff --check clean. The current branch remains outside
push-triggered workflow branch filters and Vercel stays disabled.

`AI_STATE/HANDOFF_20260927_REWARD_REVEAL_FLOW_SPLIT.md`

Previous product checkpoint — COLLECTION LIVED MARKER REVIEW:
The real production My Zync World collection grid was rendered through a
temporary visual probe using a server-shaped owned Badminton card plus completed
privacy-bounded Zync Now memory. The original green LIVED pill visibly competed
with the locked top-left card plate, so presentation only was refined: the grid
now uses a compact 26px centered green check badge with a semantics label
(Lived in real world / 現實做過), while the full explanation remains in the
production card-detail sheet. A second capture confirmed the marker no longer
covers the top-left frame chrome. A new production-screen regression also proves
the live transition pending activity -> mark complete -> dismiss progress ->
collection reload -> owned card gains lived state. Validation: focused My Zync
World tests 4/4 PASS; canonical non-golden suite 351/351 PASS across three local
batches; full flutter analyze No issues found. Temporary probe artifacts were
removed. This is an internal visual review, not final user approval. No server
economy/RNG/receipt authority, Card FX, backend, Actions, Vercel, Production,
Play, release or paid generation changed.

`AI_STATE/HANDOFF_20260927_COLLECTION_LIVED_MARKER_REVIEW.md`

Previous product checkpoint:

CURRENT AUTHORITATIVE PRODUCT CONTINUATION — COLLECTION REAL-WORLD MEMORY:
Collected cards now visibly reflect when the corresponding interest has already
become part of the player's real-world Zync history. My Zync World derives a
local lived-interest set only from completed privacy-bounded Zync Now activity
memory. Matching owned cards get a compact LIVED / 現實做過 marker in the real
production collection grid, and their production detail sheet explains that the
interest has moved beyond ownership into the player's real Zync World. Eligible
but not-yet-lived cards are framed as a real-world next move and retain the
existing soft-focus CTA. MyZyncWorldScreen now accepts an optional injected cloud
client solely to make the real production collection screen testable; production
still owns its normal client. Validation: canonical non-golden mobile tests
350/350 PASS across three local batches; full flutter analyze No issues found.
No server economy/RNG/receipt authority, Card FX, backend, Actions, Vercel,
Production, Play, release or paid generation changed. Visual usefulness of the
compact marker is not subjectively approved yet; next gate is real-device review.

`AI_STATE/HANDOFF_20260927_COLLECTION_REAL_WORLD_MEMORY.md`

Previous product checkpoint:

CURRENT AUTHORITATIVE PRODUCT CONTINUATION — COLLECTION TO REAL-WORLD ACTION:
Collected cards now have a direct gameplay purpose beyond ownership. In My Zync
World, an activity-eligible card detail can start Zync Now with that canonical
interest as a soft focus. If the interest is not already in Interest DNA it is
added as Want to Try first; existing Like/Love is never downgraded. The engine
adds a bounded preference only after normal eligibility/constraint checks
(+18 exact-interest, +12 crossover), never overrides private/shared hard vetoes,
and applies no focus boost to recent-repeat candidates. Focus is carried through
the standalone room coordinator and explicit relaxation retries. The lobby
clearly tells players that private limits and hard vetoes still win. Previous
participant-continuity behavior now has screen-level tests proving standalone and
Group participants persist the same chosen pending activity once and return a
positive continuation signal. Validation: focused collection/World/Zync Now set
36/36 PASS; canonical non-golden mobile suite 349/349 PASS; full flutter analyze
No issues found. Main-app real-browser subjective review was not completed due a
local web-server/session issue, so no subjective UX approval is claimed. No
Actions, Vercel, Production, Play, release, paid generation, economy/RNG/backend
or Card FX changes.

`AI_STATE/HANDOFF_20260927_COLLECTION_TO_REAL_WORLD_ACTION.md`

Previous product checkpoint:

CURRENT AUTHORITATIVE PRODUCT CONTINUATION — FIRST-JOURNEY CONTINUITY:
The first complete player journey no longer dead-ends after discovery. Pair Zync
recap can now continue directly into Zync Now; choosing the real-world activity
returns through the QR/scan route so Home opens My Zync World. Standalone Zync
Now and Group Zync host result CTAs likewise return a positive continuation
signal into My Zync World. QR-scanned participants now receive a privacy-bounded
activity recipe (candidate id/repeat key/template/source-interest ids/group size/
mode only; no participant identity, ballot or private constraints), reconstruct
the chosen candidate locally, persist the same pending Zync Now memory once, and
can continue to their own My Zync World. Existing Finish Zync remains optional
and non-Zync bounded options remain backward compatible. Validation: focused
transition/protocol regressions PASS; canonical non-golden mobile suite 342/342
PASS; full flutter analyze No issues found. No Actions, Vercel, Production,
Play, release, paid generation, economy/RNG/backend or Card FX changes.

`AI_STATE/HANDOFF_20260927_FIRST_JOURNEY_CONTINUITY.md`

Previous product checkpoint:

CURRENT AUTHORITATIVE PRODUCT CONTINUATION — FIRST-RUN PRODUCT PROMISE:
The connected real-world loop is now taught during first-run Interest Setup
without adding another onboarding screen. A compact localized panel says, in
essence, that Zync starts on the phone but the point happens outside it, then
shows Connect -> Choose -> Go do it -> Come back & grow. The panel exists only
during quick-start onboarding, not profile editing, and collapses as soon as
interest search starts so search results remain usable on normal phones. Copy
is localized for all eight launch locales. No fake reward walkthrough, extra
persistence or forced tutorial was introduced. Validation: onboarding/taxonomy
tests PASS; canonical non-golden mobile suite 340/340 PASS; full flutter analyze
No issues found. No Actions, Vercel, Production, Play, release, paid generation,
economy/RNG/backend or Card FX changes.

`AI_STATE/HANDOFF_20260927_FIRST_RUN_PRODUCT_PROMISE.md`

Previous product checkpoint:

CURRENT AUTHORITATIVE PRODUCT CONTINUATION — WORLD HUB + SINGLE DRAW:
My Zync World is now the central continuation hub for the real-world loop.
It loads the newest still-pending Zync Now activity and surfaces it directly
under the World hero even without Cardverse sign-in. The player can mark it
Done / Not yet / Skipped there. Done reuses the existing privacy-bounded
Tried Together progress event, computes quest delta, shows progress, and can
open Curiosity Board for server-validated rewards; returning reloads inventory.
When no activity is pending, that same slot becomes “Next step: leave the
screen” with a direct Find something to do CTA into Zync Now, then reloads on
return so the chosen activity becomes the next pending real-world move.

Single-card Draw no longer reveals its server receipt result immediately. The
server still decides and returns the immutable receipt first; presentation now
starts face-down, waits for player Reveal, then renders the actual scalable
Cardverse recipe and uses the accepted flip -> shared bloom -> rarity payoff
sensory family. Reduce Motion suppresses suspense/audio/haptic only. No sample
Card FX artwork is substituted into the real draw. Validation: canonical
non-golden mobile suite 340/340 PASS; full flutter analyze No issues found.
No Actions, Vercel, Production, Play, release, paid generation, economy/RNG or
backend changes.

`AI_STATE/HANDOFF_20260927_WORLD_HUB_SINGLE_DRAW.md`

Previous product checkpoint:

CURRENT AUTHORITATIVE PRODUCT CONTINUATION — CORE LOOP BRIDGE:
Card FX audio is an accepted baseline; stop micro-polishing it without fresh
feedback. The latest round audited the whole player loop and connected the most
important existing primitives. Standalone Zync Now completion now computes a
before/after quest delta, explicitly tells the player that the real-world action
counts, links directly to Curiosity Board, and if a real server reward is
claimed returns through Home into My Zync World. QuestBoard's return-on-claim is
opt-in, so existing callers are unchanged. The live server-receipt pack path
(`labMode:false`) now uses the accepted B — Split Open wrapper before handing
off to the immutable five-card receipt reveal; the wrapper is neutral Common so
it leaks no receipt rarity. Actual receipt-card reveals now play the accepted
flip -> shared bloom -> rarity payoff audio family. Production recap has an
explicit Back to My Zync World CTA, after which existing inventory refresh shows
the cards. No economy/RNG/receipt/order/finish changes. Validation: focused
bridging tests green; canonical non-golden mobile suite 335/335 PASS; full
`flutter analyze` No issues found. Highest remaining product gaps: surface
pending real-world activities centrally (especially Group Zync), improve the
single-card Draw reveal, and teach the complete earn/open/collect/next-action loop
during onboarding. No Actions, Vercel, Production, Play, release or paid
generation was used.

`AI_STATE/HANDOFF_20260927_CORE_LOOP_BRIDGE.md`

Previous Card FX reference-audio checkpoint:

Separate Card FX checkpoint — CURRENT AUTHORITATIVE CARD-FX CONTINUATION:
B — Split Open remains the chosen production direction. The user auditioned and
explicitly selected a Pixabay reference set, so the B sensory path now uses those
actual sources rather than the previously synthesized/guesstimated payoff family:
Next Level for pack pick; Paper Tearing at the first real split; Magic Twinkle
for the next anticipation beat; Achievement Badge Pop Sound #3 on the unchanged
70% commit/open; Card Sounds on flip; Magic Surprise as a shared reward bloom;
then XP Gain / Great Success / Magic UI Stinger / Elemental Ice / Elemental Light
for Common through Legendary. The delayed old Legendary finale sound is disabled
(haptic retained). Level Up 05 is source-recorded as a spare only and is not
bundled/wired. B early physical card-back reveal, 70% threshold, extraction,
RNG/rarity/omen behavior, locked frames and A/C/D mechanics are unchanged. The
new bloom timer participates in the existing stale-cue cancellation lifecycle.
Eleven selected MP3s are bundled and documented in PIXABAY_SOURCES.md; all served
HTTP 200 from the local Flutter asset server. Validation: targeted Card FX tests
22/22 PASS; all 52 non-golden mobile test files 333/333 PASS; full
`flutter analyze` No issues found; `git diff --check` clean. Subjective success
is intentionally not claimed — next gate is the user's real listen, with
timing/gain tuning preferred before changing the selected sound language. No
Actions, Vercel, Production, Play, release or paid generation was used.

`AI_STATE/HANDOFF_20260927_CARD_FX_PIXABAY_REFERENCE_AUDIO.md`

Previous overnight QA-hardening checkpoint:

`AI_STATE/HANDOFF_20260927_CARD_FX_OVERNIGHT_QA_HARDENING.md`

Previous B early-reveal / audio-payoff checkpoint:

`AI_STATE/HANDOFF_20260927_CARD_FX_B_EARLY_REVEAL_AUDIO_PAYOFF.md`

Previous B split-polish checkpoint:

`AI_STATE/HANDOFF_20260927_CARD_FX_B_SPLIT_POLISH.md`

Previous real-browser sensory checkpoint:

`AI_STATE/HANDOFF_20260926_CARD_FX_SENSORY_BROWSER_VALIDATED.md`

Previous sensory implementation checkpoint:

`AI_STATE/HANDOFF_20260926_CARD_FX_SENSORY_LAYER_CHECKPOINT.md`


Previous Card FX extraction checkpoint:
The true shared booster-wrapper master now feeds into a physical card-extraction
bridge before the preserved reveal animation. After A/B/C/D commits, the wrapper
is visibly open, the real Z card back rises from behind/inside it, the wrapper
moves down/out and fades only late, then the existing flip/reveal continues from
its already-settled card-back state instead of replaying the old entrance. The
first Chrome pass exposed wrapper-print ghosting over the card; this was fixed
by keeping wrapper material substantially opaque while physically translating it
away. Final real-Chrome A/B/C/D review is clean. The opening and reveal stages
now share the exact same exported ZyncFxCardBack visual. A/B/C/D mechanics,
rarity behavior, low-frequency omen, reduced-motion Lab override, accepted icon
position and locked PNG masters remain unchanged. No paid generation, GitHub
Actions, Vercel, release or deployment was used. Keep all four prototypes until
the user and his wife choose:

`AI_STATE/HANDOFF_20260926_CARD_FX_CARD_EXTRACTION_TRANSITION.md`

Previous true-wrapper-master checkpoint:

`AI_STATE/HANDOFF_20260926_CARD_FX_TRUE_BOOSTER_WRAPPER_MASTER.md`

Previous A/B/C/D opening-prototype checkpoint:

`AI_STATE/HANDOFF_20260926_CARD_FX_OPENING_PROTOTYPES_A_D.md`

Previous Card FX reduced-motion root-cause checkpoint:

`AI_STATE/HANDOFF_20260926_CARD_FX_REDUCE_MOTION_ROOT_CAUSE.md`

Previous Card FX Replay/PNG checkpoint:

`AI_STATE/HANDOFF_20260926_CARD_FX_REPLAY_PNG_COMPLETE.md`

Previous Card FX browser-review checkpoint:

`AI_STATE/HANDOFF_20260926_CARD_FX_BROWSER_REVIEW.md`

Previous Card FX safe-shutdown checkpoint:

`AI_STATE/HANDOFF_20260926_CARD_FX_SAFE_SHUTDOWN.md`

Earlier Card FX foundation checkpoint:

`AI_STATE/HANDOFF_20260925_CARD_FX_LAB_V1.md`

Authoritative continuation checkpoint (production V1/D4 track - Batch-1
repair and Batch-2 work are PAUSED pending explicit user instruction, per
a standing STOP directive; do not resume without a new explicit
authorization):

`AI_STATE/HANDOFF_20260924_CARD_ART_HOBBY_FIX_REVALIDATION_5_RESULTS.md`

Second, separate authoritative checkpoint (Object-First V2 production
ROLLOUT: Sentinel-8 was visually reviewed and ALL 8 approved -
PASS_REMEDIATION_VALIDATED, no Sentinel-9 needed. The user explicitly
accepted both automotive Sentinel outputs (transport.classic_cars,
transport.supercars) under a clarified, less-strict brand-morphology
acceptance standard (generic resemblance alone is not a failure; only
visible logos/readable names/near-direct replication of a specific
model are). The automotive_brand_morphology_repair hold was released
for transport.muscle_cars/transport.pickup_trucks (2 ids), and
transport.sports_cars was returned to generation eligibility under its
already-repaired v2.5 prompt (not auto-approved - old v2.4 failure
preserved). Steady-state was released and Batch-001 (120 cards)
executed: 120/120 succeeded, $2.016 billed, 84/120 sampled for QA
(technically validated, NOT yet visually reviewed). Formal cumulative
production-wave spend: $4.8384 (Canary+WaveB+WaveC+Batch001).
Validation/remediation spend stays separate at $0.6888 (adds
Sentinel-8's $0.1344 to the prior $0.5544). 264 rows remain held (261
genre-music + 2 vocal-music + 1 wellness.stretching) - arts.illustration
remains qa_quarantine, repaired but not visually revalidated. Batch-002
NOT started - requires a new explicit authorization after ChatGPT
reviews Batch-001's QA sample:

`AI_STATE/HANDOFF_20260925_CARD_ART_STEADY_STATE_BATCH001.md`

(previous checkpoint in this track, still useful for context - v2.5
built, Wave-C's 68-card QA recorded, Sentinel-8 plan built but not yet
executed:
`AI_STATE/HANDOFF_20260925_CARD_ART_V25_WAVEC_REMEDIATION.md`)

(earlier checkpoint in this track, still useful for context - Wave-C-96
executed, 68-card QA sample prepared but not yet reviewed:
`AI_STATE/HANDOFF_20260925_CARD_ART_WAVEC96_ROLLOUT.md`)

(earlier checkpoint in this track, still useful for context - v2.4.1
narrow fix, Sentinel-6 plan built but not yet executed:
`AI_STATE/HANDOFF_20260925_CARD_ART_V241_PRE_SENTINEL_CLEANUP.md`)

(previous checkpoint in this track, still useful for context - v2.4
candidate, Wave-B-48 QA recording, music/isolated holds:
`AI_STATE/HANDOFF_20260925_CARD_ART_V24_WAVEB_REMEDIATION.md`)

(previous checkpoint in this track, still useful for context - production
candidate v2.3, source commit 9b031bc, rollout infrastructure built
zero-cost:
`AI_STATE/HANDOFF_20260925_CARD_ART_OBJECT_FIRST_V2_PRODUCTION_ROLLOUT_PLAN.md`)

(previous checkpoints in this track, still useful for context:
`AI_STATE/HANDOFF_20260925_CARD_ART_OBJECT_FIRST_V2_PRODUCTION_READINESS_HARDENING.md`
(startup/anime/mock-trial fixes through Recheck-3 and the final
single-sentinel startups recheck, commits 4c8791c/7425cce/9b031bc),
`AI_STATE/HANDOFF_20260925_CARD_ART_OBJECT_FIRST_V2_POST_VALIDATION_ARCHITECTURE_FIX.md`
(semantic identity/physical-logic/text-mode/scene-family architecture,
post-Validation-16),
`AI_STATE/HANDOFF_20260925_CARD_ART_OBJECT_FIRST_V2_FINAL_ZERO_COST_GATE.md`
(eliminated 2 disclosed style conflicts; audited the exact Validation-16
prompts before they were paid-executed),
`AI_STATE/HANDOFF_20260925_CARD_ART_OBJECT_FIRST_V2_COMPILER_AND_REVIEW_REDUCTION.md`
(prompt compiler built, review_required 376->0),
`AI_STATE/HANDOFF_20260925_CARD_ART_OBJECT_FIRST_V2_ARCHITECTURE.md`
(routing/audit architecture before the prompt compiler existed).
Validation-16 (16 real images, $0.2688, commit 53f72d2) and Validation-8
hard-sentinels (7 billed images, $0.1176, commit c7d00b9) were executed
and visually reviewed by ChatGPT; their findings are the authoritative
input to the checkpoints above - Claude has not opened those images.)

(previous checkpoint, still useful for context:
`AI_STATE/HANDOFF_20260924_CARD_ART_FINAL_HYGIENE_TEST_8_RESULTS.md`)

(previous checkpoints, still useful for context:
`AI_STATE/HANDOFF_20260924_CARD_ART_REMEDIATION_TEST_12_RESULTS.md`,
`AI_STATE/HANDOFF_20260924_CARD_ART_PRODUCTION_BATCH_001_RESULTS.md`,
`AI_STATE/HANDOFF_20260924_CARD_ART_PRODUCTION_ARCHITECTURE_RESULTS.md`,
`AI_STATE/HANDOFF_20260924_CARD_ART_STYLE_D4_DIVERSITY_8_RESULTS.md`,
`AI_STATE/HANDOFF_20260924_CARD_ART_STYLE_D4_DURABILITY_12_RESULTS.md`,
`AI_STATE/HANDOFF_20260924_CARD_ART_STYLE_CALIBRATION_D4_RESULTS.md`,
`AI_STATE/HANDOFF_20260924_CARD_ART_STYLE_CALIBRATION_D123_RESULTS.md`,
`AI_STATE/HANDOFF_20260924_CARD_ART_STYLE_CALIBRATION_ABC_RESULTS.md`,
`AI_STATE/HANDOFF_20260924_CARD_ART_GEMINI31_FLASH_LITE_RESULTS.md`,
`AI_STATE/HANDOFF_20260923_CARD_ART_GEMINI25_DIRECT_BATCH_RESULTS.md`,
`AI_STATE/HANDOFF_20260923_CARD_ART_SEMANTIC_ANCHOR_REVALIDATION_RESULTS.md`)

Branch:

`card-art-pilot-v1-20260921`

Current state:

> **NARROW HOBBY-LEVEL FIX ROUND COMPLETE: production hygiene is now GREEN for the first time in this remediation arc. Batch 2 is now ELIGIBLE for explicit user authorization, but was NOT started - a separate new user instruction is still required.** Implemented 5 new hobby-level overrides in hobby_overrides_v1.json targeting the 5 narrow blockers left after the category-level policies: business.fire_movement (unlabeled financial-planning props, explicit forbidden-word list covering even small sticky-note labels like "Side Hustles"/"Investing"), arts.comedy_writing (thesaurus/dictionary prop removed STRUCTURALLY, not just blanked), arts.calligraphy (genuine semantic exception - brushwork stays required but marks must be abstract/partial/gestural rather than a complete readable character; hanging wall scrolls removed entirely), arts.zine_making (plain studio wall/blank corkboard background, no posters/flyers/wall typography), arts.hip_hop_dance (generic unbranded dance sneakers/streetwear, explicit anti-swoosh/three-stripe language). Full 2210-row regression: 0 errors, all five override texts confirmed present in their compiled prompts. Ran the exact 5-card revalidation (business.fire_movement, arts.comedy_writing, arts.calligraphy, arts.zine_making, arts.hip_hop_dance - no substitutions) via gemini-3.1-flash-lite-image direct Batch API, $0.084 actual, 5/5 succeeded. QA result: ALL FIVE FIXED. business.fire_movement's planning board is now fully abstract/unlabeled (coins, blank cards, generic house icon, zero text). arts.comedy_writing's thesaurus prop is gone entirely, notebook/papers are non-linguistic scribbles. arts.calligraphy's main brush stroke reads as abstract/gestural (not a complete character - correctly not counted as a leak per the task's explicit QA rule for this hobby), and the multiple large legible wall-scroll characters from before are gone (only 2 tiny ambiguous background marks remain, too small/stylized to count as clearly readable). arts.zine_making's background is now blank corkboard/abstract collage, no posters/flyers. arts.hip_hop_dance's sneakers are plain black high-tops with no swoosh/three-stripe marks, graffiti stays abstract shapes only. Semantic 5/5 PASS, D4 fidelity PASS on all 5, brand leaks 0/5, border/UI 0/5, safety 0/5. GATE: GREEN - every one of the 5 hobby-specific gate criteria met plus all global requirements (semantic FAIL=0, brand leaks=0, border/UI=0, safety=0, no new systemic defect). This is the first GREEN result across the entire Batch-1 remediation arc (prior 3 rounds were all AMBER). Rebuilt (v3) production_batch_001_v1/batch1_targeted_regeneration_list_v1.json: 16 policy_fix_validated_and_ready_for_regen (the 11 from before + all 5 fixed this round, ready now at $0.2688), 22 policy_fix_unvalidated (policy structurally applies, not individually spot-tested), 1 manual_review_required (arts.online_video_creation only - an anatomy/camera-placement defect no current policy addresses), 81 approved_as_is unchanged. Total eventual regeneration ceiling unchanged: 39 images, $0.6552, once everything is validated - a planning number only, nothing executed. No Batch-1 or prior-remediation images were regenerated. No fal.ai route used. sports.american_football and technology.robotics remain quarantined and untouched. Keep GitHub Actions, Vercel, Production and Play closed. Batch 2 was intentionally NOT started despite GREEN - per the task's explicit instruction, GREEN only means Batch 2 is eligible for a new, separate, explicit user authorization to begin. Full per-image QA data and file list: see the checkpoint handoff above.**

Prior checkpoint, superseded but kept for context:

> **FINAL PRODUCTION-HYGIENE ROUND COMPLETE: strengthened business title/heading suppression + new catalog-wide arts.* text-suppression policy. Result: AMBER. Batch 2 remains locked (runner still hard-fails on any --batch other than 1).** Part 1: business_text_suppression_policy gained a new paragraph explicitly forbidding any title/heading/caption above a diagram/board/roadmap/kanban board, even short named-diagram titles ("Roadmap", "Life Map", "Mind Map", "Empathy Map"), plus requiring blank/abstract book covers in business scenes. Part 2: new arts_text_suppression_policy field added to global_style_v1.json, wired into buildPromptV1.js gated on `effective.id.startsWith('arts.')` - auto-applies catalog-wide to all 89 arts.* hobbies, requiring zines/notebooks/scripts/posters/sketchbooks/boards to use blank/abstract non-linguistic marks while explicitly preserving the creative activity itself. Full 2210-row regression: 0 errors, confirmed both policies scope correctly (40 business.*, 89 arts.*, zero cross-contamination). Part 3-5: built and ran an 8-card test - 2 mandatory business blockers (product_management, fire_movement) + 2 mandatory arts controls (zine_making, comedy_writing) + 4 additional exact Batch-1 arts offenders spanning distinct cause families (hip_hop_dance=poster/signage, voice_acting=script, calligraphy=workshop/scroll hardest-case, webcomics=layout/design+screen-UI) - via gemini-3.1-flash-lite-image direct Batch API, $0.1344 actual, 8/8 succeeded. QA result: business.product_management FULLY FIXED (Product Roadmap title + column headers both gone); business.fire_movement PARTIALLY FIXED (big title gone, but small readable sticky-note labels "Side Hustles"/"Investing" persist) - business readable-text rate 1/2. arts.voice_acting and arts.webcomics FULLY FIXED; arts.hip_hop_dance text FULLY FIXED (graffiti gone) but a NEW brand/trademark finding surfaced (swoosh-like mark + three-stripe pattern, same residual-silhouette risk class as sports.skateboarding/arts.kpop_dance); arts.zine_making MAJOR IMPROVEMENT (primary zine prop now completely clean of the "ZINE" wordmark, only background wall-poster decor still leaks); arts.comedy_writing and arts.calligraphy still fail (THESAURUS book spine unchanged; background scroll characters persist, the latter explicitly the hardest possible stress test since calligraphy IS writing) - arts readable-text rate 3/6. Semantic 8/8 PASS, D4 fidelity PASS on all 8, border/UI 0/8, safety 0/8. GATE: AMBER (neither business 0/2 nor arts 0/6 required rate met, so Batch 2 stays locked per the gate's explicit rule) but NOT RED (4/8 cards fully clean, both target "big title" patterns eliminated, remaining issues are narrow/diagnosable per-hobby residue, not a structural policy failure). 5 narrow remaining blockers identified: business.fire_movement needs a "no readable sticky-note text either" reinforcement or hobby override; arts.comedy_writing and arts.calligraphy likely need dedicated hobby-level overrides (mirroring the existing books.reading and wellness.tai_chi fixes respectively); arts.zine_making needs a background-poster-decor policy pass; arts.hip_hop_dance needs a brand-safety review for its new finding. Part 6: rebuilt (v2) production_batch_001_v1/batch1_targeted_regeneration_list_v1.json using this round's results - 11 policy_fix_validated_and_ready_for_regen (ready now, $0.1848), 23 policy_fix_still_unvalidated, 5 manual_review_required (comedy_writing, calligraphy, zine_making, hip_hop_dance, plus online_video_creation's unrelated anatomy defect which no current policy addresses), 81 approved_as_is unchanged. Total eventual regeneration ceiling: 39 images, $0.6552, once everything is validated - a planning number only, nothing executed. No Batch-1 or prior-remediation images were regenerated. No fal.ai route used. sports.american_football and technology.robotics remain quarantined and untouched. Keep GitHub Actions, Vercel, Production and Play closed. Batch 2 is NOT yet eligible for user authorization - the gate was not met. Full per-image QA data and file list: see the checkpoint handoff above.**

Prior checkpoint, superseded but kept for context:

> **BATCH-1 REMEDIATION ROUND COMPLETE: implemented + validated fixes for the two Batch-1 failure classes. Result: AMBER. Batch 2 remains locked (runner still hard-fails on any --batch other than 1).** Part 1: added a new `business_text_suppression_policy` field to global_style_v1.json, wired into buildPromptV1.js gated on `effective.id.startsWith('business.')` - auto-applies to all 40 business.* hobbies catalog-wide (not just the 30 in Batch 1), so batches 2-19 inherit it automatically once authorized. Requires whiteboards/kanban/roadmaps/dashboards to render as blank cards/arrows/shapes only, with an explicit example list drawn from Batch-1's actual offenders (GOAL, SKILLS, EMPATHY MAP, BACKLOG, S&P 500, KPI, ROADMAP, etc.). Parts 2-3: strengthened global_brand_safety_policy with explicit device-lid language (no centered emblem, no fruit-shaped/bitten-fruit silhouette, no circular brand badge - applies by default even when no brand is named) plus software-icon and financial-index-term language (no Figma/Adobe/Canva/Notion/Slack-like marks, no S&P 500/NASDAQ/Dow). Full 2210-row regression: 0 errors, confirmed the business policy applies to exactly the 40 business.* ids and nowhere else. Part 4-5: built a 12-card targeted test reusing actual Batch-1 offender IDs (8 business text offenders: career_development, career_switching, design_thinking, financial_independence, index_investing, product_management, project_management, fire_movement; 2 required device-logo offenders: coworking, no_code; 2 arts/text controls not covered by the fix: zine_making, comedy_writing), documented with each one's original defect before generation. Generated via gemini-3.1-flash-lite-image direct Batch API, $0.2016 actual, 12/12 succeeded. Part 6 QA result: 6/8 business text offenders now COMPLETELY CLEAN (career_development, career_switching, design_thinking, financial_independence, index_investing including the real "S&P 500" trademark, project_management) - dramatic improvement from Batch-1's 50% business leak rate. BOTH device-logo offenders fixed (coworking, no_code - no recognizable real hardware logo on any device, confirming the Apple-logo leak is resolved). BUT 2/8 business text offenders still leak: business.product_management now shows a large readable "Product Roadmap" title plus column headers "Discover/Validate/Build/Launch/Optimize"; business.fire_movement shows a new "Life Map" title (though its prior "FINANCE" book-spine and "Mind Map" whiteboard leaks are both gone - net improvement, just not to zero). The 2 arts controls (zine_making, comedy_writing) failed exactly as predicted/documented since they're outside business.* scope - confirmed isolated, not counted against the business-policy gate per the task's own rule. GATE DECISION: AMBER, not GREEN (the gate's explicit rule "any business card still renders readable planning/kanban/whiteboard text -> Batch 2 stays locked" is triggered), not RED (6/8 + both device offenders fully fixed is not a diffuse/structural failure - the residual pattern is narrowly a "title above an otherwise-abstract diagram" issue on 2 specific hobbies). BATCH 2 MAY NOT PROCEED until one more reinforcement pass (explicit "never render a title or heading above any diagram/board/chart" language) is added and re-validated on product_management, fire_movement, plus 1-2 more untested business hobbies. Part 7: prepared (did NOT execute) a full Batch-1 classification - production_batch_001_v1/batch1_targeted_regeneration_list_v1.json splits all 120 Batch-1 images into approved_as_is (81) and targeted_regeneration_needed (39, sub-classified: 8 fix_validated_ready_for_regeneration, 2 fix_partial_needs_followup_before_regeneration, 7 business_policy_applied_not_individually_spot_tested, 22 not_covered_by_this_rounds_fix_needs_separate_hobby_override for arts-category issues). No Batch-1 images were regenerated. No fal.ai route used. sports.american_football and technology.robotics remain quarantined and untouched. Keep GitHub Actions, Vercel, Production and Play closed. Full per-image QA data and file list: see the checkpoint handoff above.**

Prior checkpoint, superseded but kept for context:

> **FIRST REAL PRODUCTION BATCH SUBMITTED AND REVIEWED: batch 1 of 19 (120 images), user-explicitly-authorized, batch 2 is NOT authorized and the runner hard-fails on any other --batch value.** Built tools/card_art/src/runProductionBatch.js reading production_queue_v1.json/production_batch_plan_v1.json (not an ad-hoc selection), cross-checking recompiled prompt_sha256 against the committed queue before submitting. Hit and fixed a real engineering blocker mid-task: a 120-request batch status response can exceed Node/V8's ~512MB max string length (Google duplicates the full inlinedResponses array under both metadata.output and response) - added stream-json/stream-chain as a local dependency and rewrote collection to stream the response straight to a scratch file and process it in two token-streaming passes (one strips all inlinedResponses entirely for a small redacted status summary, one streams response items one at a time so memory stays bounded to a single request's payload). Verified against a synthetic ~458MB mock file before touching the real API. Batch result: 120/120 succeeded, 0 failed_transient, 0 failed_content, actual cost $2.016. Layer-1 automated QA: 10/10 checks passed. Full individual human QA of all 120 images (no sampling): semantic 120/120 PASS (0 MINOR, 0 FAIL), border/UI leak 0/120, safety concern 0/120, anatomy/object corruption 1/120 (minor camera-rig placement oddity). Brand/trademark leak 8/120 (6.7%) - most severe: TWO clearly recognizable real Apple logos on laptop/tablet lids (business.coworking, business.no_code), confirming global_brand_safety_policy's "consumer electronics and devices" language is not reliably followed by the model for this specific device-logo case. Text leak 29/120 (24.2%) overall, but this is NOT evenly distributed: 15 of 30 business.* cards (50.0%!) render clearly readable diagram/whiteboard/kanban-board text ("SKILLS", "GOAL", "Empathy Map", "REVENUE STREAMS", "Backlog/Doing/Validation/Done", "INITIATION/PLANNING/EXECUTION/MONITORING", and business.index_investing even renders the real trademarked term "S&P 500") - a single, narrowly-diagnosable systemic cluster defect traced to the business category's concept-diagram/kanban-board recognition-anchor language, the same class of gap already fixed per-hobby for lifestyle.game_nights/learning.philosophy but never addressed at the category level. arts.* text-leak rate was much lower (14/89, 15.7%, spread across 3 distinct minor sub-causes) and books.reading (fixed last round) rendered completely clean, confirming that fix holds in real production. Screen-policy leak 6/120 (5.0%), concentrated in creator-tool editing-software hobbies and finance-dashboard hobbies (business.dividend_investing shows a full front-facing stock-chart dashboard). Also noted: a specific "long dark-haired serious male" face recurs ~7 times despite genuinely varied diversity-dimension assignments per hobby (confirmed via the catalog-wide distribution check last round) - a model-rendering-prior tuning opportunity, not a defect in the deterministic assignment mechanism; the batch also shows plenty of successful diversity elsewhere (grey/curly/coily hair, darker skin tones, broader builds, older leads). BATCH-1 GATE: AMBER (not GREEN - the business-category cluster and device-logo leak are real and above threshold; not RED - both defects are narrowly diagnosable single-cause patterns, not diffuse failure, and semantic/border/safety all stayed clean at or near 100%). BATCH 2 MAY NOT PROCEED until: (1) a category-level business.* fix suppressing readable diagram/kanban text is added and validated, (2) global_brand_safety_policy is reinforced specifically against device-lid logos, (3) both are spot-checked with a small targeted re-generation. Neither fix was implemented this round (out of scope - batch-2-locked). No fal.ai route used. sports.american_football and technology.robotics remain quarantined and confirmed absent from this batch. Keep GitHub Actions, Vercel, Production and Play closed. Full per-image QA data, category breakdown, and file list: see the checkpoint handoff above.**

Prior checkpoint, superseded but kept for context:

> **D4 visual-style research is CLOSED. This checkpoint built the production-batch architecture for the full 2,210-image catalog and cost $0 - no Gemini call, no fal.ai, no image generated, no GitHub Actions, no Vercel.** Part 1: finished the 4 known localized recipe fixes in hobby_overrides_v1.json (books.reading, wellness.cold_plunge, sports.skateboarding all carried over/reinforced; wellness.tai_chi added new - blank/abstract wall art required, readable calligraphy/scroll text/pseudo-characters/signage forbidden, Tai Chi practice itself unchanged). Part 2: redesigned diversity_profiles_v1.json from 5 dimensions into 9 (gender_presentation, age_presentation, face_hair_presentation [8 values: hair length/texture/color + face-shape cues], body_build [5 values, explicitly "without caricature"], composition [7 values], lighting_time [7 values], palette_mood [5 values], emotional_mode [unchanged 9 values], effects_intensity [new weighted 40/35/25 zero/minimal/accent routing via a new weightedPick() in diversityLayer.js]). Measured catalog-wide: effects_intensity lands at 39.9%/34.5%/25.6% (matches target), golden_hour is now only 14.5% of lighting_time picks (no more single-lighting-mode collapse). Part 3: object_led got a dedicated multi-sentence directive (not just one line) after the 8-card test showed outdoors.fishing still let the human dominate - now explicitly demands the object/action carry the strongest visual emphasis with the human as a secondary supporting actor, generic across hobby categories. Full 2210-row catalog regression: 0 errors. Part 4: built the full production-batch architecture as new library modules - productionQueue.js (buildProductionQueue(), fails closed if eligible count != 2210, deterministic sort, compiles every prompt through the real production compiler, stores prompt_sha256 fingerprints not full prompt text to control repo size, partitions into 120-row batches, quarantined ids get batch_number=null), productionManifest.js (planSubmission() never resubmits succeeded/quarantined ids, planRetryBatch() only failed_transient/retry_pending, classifyOutcome() routes content_policy failures to needs_qa not auto-retry), productionCostReport.js (never assumes failures are billed), buildProductionQueueCli.js (writes production_queue_v1.json/production_batch_plan_v1.json/production_cost_report_v1.json), plus specs/production_qa_plan_v1.json (4-layer QA: static checks, stratified sampling, targeted high-risk-family review, cluster-defect escalation that pauses further batches) and specs/production_launch_gates_v1.json (13 gates, 12/13 satisfied, gate 13 = explicit user authorization = intentionally NOT granted this checkpoint). Part 5: validateProductionArchitecture.js ran 11/11 zero-cost checks (real double-build determinism check on all 2210 rows plus mocked-data resume/retry/cost-accounting checks) - all PASS. RESULTS: eligible=2210, auto-production=2208, quarantine=2 (sports.american_football, technology.robotics - both present in the eligible set but batch_number=null and unsubmittable), planned batches=19 (18x120 + 1x48), baseline cost estimate=$37.128 (auto-production-only=$37.0944). PRODUCTION ARCHITECTURE IS READY. No mechanical blockers. The only remaining step is a new explicit user instruction authorizing the start of real production generation - do not submit any production batch without it. No production batch was submitted. Full details, per-gate evidence, and file list: see the checkpoint handoff above.**

Prior checkpoint, superseded but kept for context:

> **Production-hardening round: 3 localized recipe fixes + a new deterministic D4 diversity layer + an 8-card diversity stress test, on top of the 12-card durability round below.** D4's rendering language (global_style_v1.json's prompt field) was NOT touched this round. Fixed the 3 defects the durability round found: books.reading (new override forbidding readable book titles/spines/author names, requiring plain/abstract covers), wellness.cold_plunge (rewritten subject/environment requiring visible ice/cold water/braced posture, explicit avoid-list against steam/onsen atmosphere), sports.skateboarding (hardened anti-sneaker-silhouette override matching fashion.streetwear's pattern). Added a new deterministic diversity layer: specs/diversity_profiles_v1.json defines 5 dimensions (protagonist presentation, scene structure, lighting/palette, emotional mode, effect intensity); src/diversityLayer.js computes a per-hobby profile via stable per-dimension hashing of the hobby id (reproducible, not random); buildPromptV1.js's compileHobbyPrompt wires it in as one additive guidance section with explicit precedence language (hobby semantics always win on conflict); generateCompiledBatch.js now loads/passes it catalog-wide. Full 2210-ID regression check passed (0 errors) and a distribution check confirmed even spread across all 5 dimensions before any generation. Then generated 8 new canonical interests via gemini-3.1-flash-lite-image direct Batch API, $0.1344 actual, 8/8 returned, one per required stress mode (collecting.stamps=male-led, sports.golf=older-adult, outdoors.fishing=object-led, music.violin=night/cool-palette, gaming.tabletop_rpg=group social, crafts.pottery_wheel=indoor craft, outdoors.mountain_biking=outdoor action, wellness.tai_chi=calm/quiet). Result: 8/8 semantic PASS, 0/8 brand/trademark leaks, 0/8 border/UI defects. Aggregate scores (0-4): D4 style fidelity 3.81, special-illustration feel 3.5, collectible appeal 3.56, Zync distinctiveness 2.69, diversity success 3.5. Sameness materially reduced across face type, age, gender presentation, composition, lighting, palette, emotional expression, and sparkle usage - no more golden-hour/smiling-female/medium-shot/sparkle-everywhere default. One new isolated text leak found: wellness.tai_chi shows legible-looking calligraphy on background wall scrolls (a localized recipe gap, not a diversity-layer or D4 problem) - recommended follow-up, not yet fixed. One diversity dimension landed only partially: outdoors.fishing's object_led framing still kept the angler as the dominant foreground figure - a tuning opportunity, not a systemic failure. Per the pre-declared decision rule (can D4 + diversity layer produce visible diversity without losing semantic fidelity or brand identity?): YES. D4 remains unchanged, the diversity layer is kept and is now wired catalog-wide, and this checkpoint is ready to move toward production-batch architecture PLANNING (architecture/engineering only - no bulk generation was started or auto-scaled). Recommended but NOT executed follow-ups: text-suppression override for wellness.tai_chi's wall scrolls; strengthen the object_led diversity phrase; a small dedicated re-generation of the 3 originally-fixed hobbies (books.reading, wellness.cold_plunge, sports.skateboarding) to visually re-confirm those fixes on generated images, since this round's 8 IDs deliberately did not overlap with them. No fal.ai route used. sports.american_football and technology.robotics remain quarantined. Keep GitHub Actions, Vercel, Production and Play closed. Full details, per-image QA table, and file list: see the checkpoint handoff above.**

Prior checkpoint, superseded but kept for context:

> **D4 cross-category durability test (12 cards) ran on the real production compiler, following the D4 6-card calibration round below.** D4 was promoted from an isolated experiment into production `global_style_v1.json` this checkpoint (its exact prompt text is now the `prompt` field), a new catalog-wide `global_brand_safety_policy` field was added and wired into `buildPromptV1.js` (plain/generic/unbranded clothing, footwear, equipment, devices, vehicles; no logos/brand marks/swoosh-like or three-stripe-like marks/sneaker-brand silhouettes; explicitly not sterile-looking), and `learning.philosophy` got a hobby-level recipe fix moving it from occult/grimoire drift to contemporary intellectual discussion (modern book/notebook + discussion gesture + concept diagram, "knowledge is exciting" tone preserved). Full 2210-ID catalog regression check passed (0 errors) before any generation. Then 12 new canonical interests spanning all 12 required category types (sports.skateboarding, outdoors.kayaking, pets.birds, travel.destination_deep.japanese_onsen_trips, music.piano, wellness.cold_plunge, science.marine_biology, technology.3d_printing, crafts.knitting, books.reading, lifestyle.game_nights, lifestyle.home_decor) were generated via gemini-3.1-flash-lite-image direct Batch API, $0.2016 actual, 12/12 returned. Result: 11/12 semantic PASS, 1/12 MINOR (wellness.cold_plunge reads as a warm onsen soak rather than a cold immersion - steam visible, no safety/nudity issue). Aggregate scores (0-4): anime feel 3.71, special-illustration feel 3.54, joy 3.71, collectible appeal 3.38, hero focus 3.38, Zync distinctiveness 2.63, fantasy/photographic/Western-editorial drift all 0.0, border/UI defect 0%. Two localized (non-systemic) defects found: books.reading shows two readable invented book titles ("JOURNEY TO THE UNKNOWN", "STARRY TALES") on its hero props - a major text-policy leak; sports.skateboarding shows a recognisable low-top skate-sneaker silhouette (no logo/text, but real-brand-adjacent) - the new global brand-safety policy reduced but did not eliminate this class of issue, echoing the earlier fashion.streetwear finding. Per the pre-declared decision gate, these two isolated single-card issues do not constitute systemic collapse (no clustering, different categories/failure modes) - gate outcome is "fix at recipe level, not by rewriting D4 globally." D4 remains the recommended production-style baseline (already live in global_style_v1.json). Recommended but NOT executed follow-ups: hobby-level text-suppression override for books.reading; footwear-silhouette reinforcement for sports.skateboarding similar to fashion.streetwear's existing override; an explicit cold/ice visual cue override for wellness.cold_plunge to differentiate it from sibling hot-springs/sauna recipes in the wellness_experience archetype. science.marine_biology confirmed the learning.philosophy override is correctly scoped (no cross-contamination). No fal.ai route used. No larger batch started after results. sports.american_football and technology.robotics remain quarantined. Keep GitHub Actions, Vercel, Production and Play closed. Full details, per-image QA table, and file list: see the checkpoint handoff above.**

Prior checkpoint, superseded but kept for context:

> **House-style D4 calibration ran (successor to D1/D2/D3, where D3 was strongest but still read as ordinary anime lifestyle illustration rather than an iconic collectible moment): same 6 hobbies x 1 special-illustration/full-art style candidate = 6 images on gemini-3.1-flash-lite-image direct, $0.1008 actual, 6/6 returned. DECISIVE, visually clear improvement over D3: D4 consistently replaces "several people doing an activity together" staging with a single dramatic/emotional focal peak - a mid-air dice roll with a sparkle trail at the decisive board-game moment, a dramatic courtroom accusation glowing on-screen with a visibly tense viewer reacting in the foreground, noodles lifted mid-bite with steam and genuine joy. Zero card-border/fake-TCG-UI defects this round (0/6, vs D1's severe 1/6 occurrence) - deliberately reducing literal "trading card"/"collectible card"/"card frame" phrasing per instruction appears to have worked. Production global_style_v1.json never touched (verified via git status); prefix-check confirmed the injected D4 style block compiled correctly before any paid call (weaker guarantee than the cross-version diffs used in A/B/C and D1/D2/D3 since D4 has no sibling style this round to diff against - disclosed plainly). Semantic: 5/6 PASS, 1/6 MINOR - learning.philosophy's antique diagram-covered tome reads closer to an occult/alchemical grimoire than clearly modern philosophy content, the exact drift the task's own semantic guard warned against, despite otherwise excellent "intellectual excitement" staging. Also flagged: fashion.streetwear shows a light checkmark/swoosh-like mark on a sneaker, a possible trademark-adjacent risk worth a follow-up spot-check. Aggregate scores (0-4): anime feel 3.5, NEW special-illustration feel 3.33, joy 3.5, collectible appeal 3.42, NEW hero focus 3.25, distinctiveness 2.67, fantasy drift 0.29 (down from D3's 0.58), maturity 3.67, border defect 0%. RECOMMENDATION: D4 is the new recommended style baseline - promote it to production global_style_v1.json explicitly (not done automatically here). No reference-conditioned gemini-3.1-flash-image test needed - text-only calibration is still improving round over round, not stalling. Recommended next steps (not executed): small isolated follow-up on philosophy's prop choice (a hobby-recipe fix, not a global-style fix, since the other 5 hobbies show no comparable drift); spot-check streetwear's footwear rendering across a couple more generations; scalability validation across uncovered categories before any larger commitment. Found an untracked output/style_calibration_d_18_v1/images/d.zip in the working tree at task start (presumably user-created for local review) - left untouched, not staged in any commit. No fal.ai route used. No 18/24/100/2210-card batch started. sports.american_football and technology.robotics remain quarantined and untouched. Keep GitHub Actions, Vercel, Production and Play closed.**

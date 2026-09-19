# Zync V1 — Encrypted One-Scan Pairing + Responsive UI Certified Handoff

Date: 2026-09-18 (Asia/Hong_Kong / Asia/Taipei continuation)  
Branch: `zync-v1-rebuild-20260917`

This handoff is **additive**. Preserve every earlier `AI_STATE` handoff unchanged. It supersedes `AI_STATE/HANDOFF_20260917_ENCRYPTED_RELAY_INTEGRATION_IN_PROGRESS.md` as the current authoritative continuation point, while inheriting `AI_STATE/HANDOFF_20260917_PLAY_INTERNAL_RELEASE_AUTOMATION.md` and all prior release/privacy/product lineage.

Do **not** restart broad repository discovery or old Thunkable archaeology. Continue from the remaining external integration / real-device gate described below.

## 1. User decisions that are now frozen

The user explicitly approved:

- Chat mode only; do not hand off to Work mode.
- One-scan production-quality pairing instead of a second response QR.
- Vercel API + Upstash Redis as a short-lived relay.
- Approximately 3-minute relay lifetime.
- Redis TTL as the hard cleanup guarantee; **no scheduled cleanup job**.
- Local-first / no-login / no permanent cloud profile posture.
- On-device AES-GCM encryption before scanner response leaves the phone.

Do not silently replace Upstash with Firebase/Supabase/another store without a new explicit decision.

## 2. Certified code SHA / CI evidence

The code/release slice is certified at:

`ee2d8409f8e1719fd9be035ecdba0e076425132d` — `Use deterministic bootstrap in host pairing regression`

GitHub Actions:

- workflow: `Zync V1 CI`
- run number: **#157**
- run ID: `35246251340`
- job ID: `105287088128`
- branch: `zync-v1-rebuild-20260917`
- head SHA: `ee2d8409f8e1719fd9be035ecdba0e076425132d`
- final result: **SUCCESS / all steps green**

Passed gates include:

- serverless JavaScript syntax;
- existing V1 serverless contracts;
- encrypted relay functional contracts;
- OpenRouter privacy contracts;
- public release/privacy contracts;
- Play internal-release workflow contracts;
- signing-configurator self-test;
- Play internal-release publishing guards;
- generated Android package/SDK/branding checks;
- dependency install;
- localization generation;
- `flutter analyze`;
- complete Flutter test suite, including one-scan host auto-advance regression;
- unsigned release AAB build;
- artifact upload.

Unsigned artifact from this certified run:

- artifact ID: `10508131496`
- name: `zync-v1-unsigned-aab`
- size: `61,199,201` bytes
- digest: `sha256:0a5780327442b449e75a523ca78d6468ec336b912fcdf160eec4f09ed9bb3a65`
- expires: `2026-10-01T16:28:14Z`

This is an **unsigned CI artifact only**. It was not uploaded to Google Play and is not a production release.

## 3. Release blocker #1 — normal-phone one-screen UI — FIXED IN CODE

`HomeScreen` now uses a constraint/text-scale-responsive layout:

- normal modern phone viewport: no vertical `ListView`; primary Show/Scan actions are visible on one screen;
- compact 2x2 secondary function cards preserve access to interests/history/DNA/privacy;
- narrow/short screens or larger accessibility text fall back to a safe scrollable layout rather than overflowing.

`ShowQrScreen` follows the same principle:

- normal phone: fixed one-screen QR experience;
- short/large-text conditions: `SingleChildScrollView` fallback.

Tests explicitly cover:

- 390x844 normal Home with no `ListView`;
- narrow French/larger-text Home scroll fallback;
- 390x844 normal Show QR with no vertical scroll container;
- 320x620 Show QR fallback;
- large-profile QR on narrow screen;
- Traditional Chinese locale resolution.

Do not hard-code future layout changes to a single Samsung/Fold model.

## 4. Release blocker #2 — one-way QR pairing — FIXED IN CODE

Old broken flow was:

`A shows static QR -> B scans -> only B advances; A can never know B scanned`

Certified flow is now:

`A creates short-lived relay session -> A shows handshake QR -> B scans once -> B matches locally + encrypts minimal response -> B submits ciphertext -> B advances -> A polls authorized relay -> A decrypts/authenticates locally -> A computes same deterministic session -> A records local history -> A consumes relay -> A auto-advances to Match`

There is no second response QR and no manual “I was scanned” workaround.

## 5. Protocol v2 and encryption

`mobile/lib/core/relay_service.dart` implements:

- protocol version `2`;
- QR prefix `ZH2:`;
- cryptographically secure random session ID from 18 random bytes;
- 32-byte one-time AES key;
- 3-minute expiry;
- compressed QR envelope containing protocol, session ID, expiry, one-time AES key and host compact profile;
- scanner-side `AesGcm.with256bits()` encryption;
- AAD binding: `zync-relay-v2:<sessionId>`;
- host validates protocol, session ID, exact expiry and AEAD authentication before accepting scanner data;
- wrong key/tampering/expired responses are rejected.

The relay never receives the one-time AES decryption key.

## 6. Private host read capability — security hardening completed

A final security audit identified that `sessionId` is visible in the QR and therefore must not itself authorize polling.

The certified design now adds a separate private host capability:

- host generates a second secure random `hostToken` from 24 random bytes (32 base64url chars);
- `hostToken` remains on host A only;
- it is **not encoded in the QR** and is not available to scanner B;
- relay create/take/consume/cancel require this host token;
- scanner `respond` requires only the public random session ID + opaque ciphertext;
- server stores only `SHA-256(hostToken)`, never the raw host token;
- wrong host token receives HTTP 403 and cannot poll or consume the response.

Redis state is now conceptually:

- pending: `P|<host-token-sha256>`
- answered: `R|<host-token-sha256>|<opaque-aes-gcm-response>`

Functional relay contracts prove:

- raw host token is not persisted;
- scanner can submit without host token;
- wrong host token cannot read/consume;
- correct host can repeatedly poll after a lost HTTP response;
- consume deletes the session;
- TTL deletes abandoned sessions.

## 7. Relay backend / Upstash semantics

`api/v1/relay.js` provides:

- `create`
- `respond`
- `take`
- `consume`
- `cancel`

Properties:

- high-entropy session IDs;
- max ~3-minute lifetime;
- first scanner response wins;
- exact same encrypted response retry is idempotent;
- different second scanner response is rejected;
- `take` is deliberately non-destructive so a lost HTTP reply cannot destroy B's response;
- `consume` happens only after A successfully AEAD-decrypts/authenticates the response;
- abandoned sessions expire by Redis TTL without a cron/scheduler;
- payload/protocol/expiry bounds;
- no relay payload/secret console logs;
- short-lived abuse counters keyed from HMAC(request IP), rather than storing raw IP in application rate-limit keys.

Server-only configuration remains:

- `UPSTASH_REDIS_REST_URL`
- `UPSTASH_REDIS_REST_TOKEN`
- `ZYNC_RELAY_RATE_LIMIT_SECRET`

Never embed these values in Android, QR payloads, source, or documentation examples.

## 8. Deterministic shared session semantics

`MatchingService.compare` accepts `sessionSeed`.

Both phones deliberately compute with the same orientation:

- Host(A) interests first;
- Scanner(B) interests second;
- same relay session ID as seed.

This removes perspective-dependent ordering/crossover differences. `MatchScreen` and `ConversationScreen` carry the session seed forward.

The certified scope guarantees the same initial match ordering/context. Post-pairing user taps are still local interactions; V1 does not become a persistent real-time social session.

## 9. Host/scanner reliability behavior

Host A:

- relay session must be successfully created before QR becomes scannable;
- adaptive polling;
- pause/resume recovery;
- non-destructive poll retry;
- authenticated decrypt before consume;
- local Zync Again history written before navigation;
- auto-navigation to Match;
- expiry / connection / regenerate UI;
- best-effort cancel with TTL fallback.

Scanner B:

- v2 handshake validation;
- self-scan prevention;
- local matching;
- on-device AES-GCM response;
- exact same ciphertext retained for retry after ambiguous network timeout;
- duplicate / expired / malformed / network state handling;
- local history update;
- Match navigation after accepted response.

Legacy profile QR decode remains for backward compatibility, but new Show QR uses the v2 handshake.

## 10. One-scan regression evidence

`mobile/test/pairing_flow_test.dart` now exercises the actual host widget flow with an injected deterministic bootstrap and fake relay:

- A creates session with private host token;
- host token is separate from QR handshake;
- encrypted B response becomes available;
- A polls using the same private host token;
- A decrypts;
- A auto-navigates to Match without a tap or second scan;
- A consumes using the same host token;
- cancel is not called after successful navigation;
- local history is recorded with expected shared IDs.

This test passed in CI #157.

## 11. Localization / product copy

All current interface locales include relay states and corrected privacy copy:

- English;
- Traditional Chinese;
- Simplified Chinese;
- generic Chinese;
- Japanese;
- Korean;
- Spanish;
- French;
- Portuguese.

States include waiting, Zyncing, connection issue, start failure, expiry, regenerate QR, already-used QR and scanner connection failure.

Do not restore copy implying the whole new one-scan exchange is “direct peer transfer only.”

## 12. Privacy / Play Data Safety posture

Updated and machine-gated:

- `privacy.html`
- `terms.html`
- `docs/PRIVACY_POLICY_V1_DRAFT.md`
- `docs/PLAY_DATA_SAFETY_V1_RELEASE_ANSWERS.md`
- `docs/PLAY_RELEASE_DATA_SAFETY.md`
- `docs/PRODUCTION_ONE_SHOT_RELEASE_V1.md`
- `.github/scripts/release_web_contracts.mjs`

Public/release posture now says:

- no account/permanent cloud profile;
- matching remains on-device;
- scanner response is AES-GCM encrypted on-device;
- Vercel + Upstash act only as a short-lived encrypted relay;
- relay/server does not receive the one-time AES key;
- state expires in roughly three minutes and is consumed earlier on success;
- encrypted/server-opaque/ephemeral off-device data is still conservatively assessed as collection for Play Data Safety rather than falsely claiming “No data collected.”

OpenRouter ZDR / `data_collection: deny` and public V1 analytics-off posture remain unchanged.

## 13. CI / signed-release gates

Normal `.github/workflows/zync-v1-ci.yml` now gates relay syntax/contracts.

`.github/workflows/zync-v1-signed-release.yml` also gates relay syntax/contracts before production smoke/signing. Existing signing protections are preserved:

- production API/privacy variables required;
- existing accepted Play upload key path;
- analytics pinned `false`;
- strict `jarsigner -verify -strict`;
- signed AAB only after gates pass.

No signed release was run in this slice.

## 14. Production live smoke prepared but NOT run against the new relay

`.github/scripts/live_api_smoke.mjs` is prepared to verify, with synthetic data only:

- public privacy disclosure;
- host-authorized create;
- idempotent create retry;
- wrong host token rejected;
- waiting poll;
- scanner response without host token;
- identical response retry;
- different duplicate response rejection;
- wrong host token cannot read/consume;
- repeated authorized non-destructive poll;
- authorized consume;
- post-consume expiry/not-found;
- an abandoned ~15-second synthetic session actually disappears by TTL;
- AI normalize/question privacy path;
- analytics endpoint posture.

Do not run this against the old production deployment and interpret the result as the V1 relay. The new relay is not deployed yet.

## 15. Targeted final diff audit

Compared base `37c1ca348263bab3c503fbdf3329126be7dd3816` to certified code SHA `ee2d8409f8e1719fd9be035ecdba0e076425132d`.

Result:

- branch is strictly ahead, not behind;
- intended files are relay/pairing/responsive UI/tests/l10n/privacy/release workflow/docs;
- `docs/ZYNC_BUSINESS_PROPOSAL_AND_VISION.md` appears in the broad compare because it predates this active slice; it was not reworked as part of the relay fix and must be preserved;
- no login/community/feed/location/Phase-2 scope creep was introduced;
- Android version remains `1.0.0+6`;
- package/legacy Play identity checks passed in CI;
- branch Vercel auto-deploy remains explicitly disabled.

## 16. Vercel / production state remains protected

`vercel.json` still contains:

`"zync-v1-rebuild-20260917": false`

The Vercel deployment list was checked during this slice: no new deployment corresponding to the encrypted-relay commits was created.

Stable `https://zync-inky.vercel.app` was separately verified and still maps to the old 2025 production deployment:

- deployment ID: `dpl_8a6uG7TzDdrDALJGbXSkFhD9iP8x`
- Git branch: `main`
- Git SHA: `0c40be9bfd6e2ac17e1a2d22aeec77995231d596`

Therefore:

- V1 relay is **not live**;
- no preview was intentionally deployed in this slice;
- no production promotion occurred;
- no Play upload/publish occurred.

## 17. External blocker: Upstash provisioning / Vercel env

The code is certified, but the actual shared relay service does not exist yet for live devices.

Available ChatGPT Vercel tooling can inspect/deploy but does not expose Vercel environment-variable or Marketplace-storage mutation. Plugin discovery also found no useful Upstash account/storage connector. Do not pretend this setup was completed.

The release owner must create/connect an Upstash Redis database and provide the three **server-only** Vercel values:

- `UPSTASH_REDIS_REST_URL`
- `UPSTASH_REDIS_REST_TOKEN`
- `ZYNC_RELAY_RATE_LIMIT_SECRET` (random secret at least 24 chars; use a strong random value)

After those values exist, create a controlled preview under the existing one-shot plan and run the prepared live smoke before any production promotion.

## 18. Exact two-phone QA after relay environment is available

Use the same V1 build/API origin on two physical Android phones.

Primary happy path:

1. Phone A opens Home and confirms the normal phone layout does not need vertical scrolling to reach Show QR / Scan.
2. A taps Show QR. Verify QR appears only after relay session creation and status says Waiting for scan.
3. Phone B taps Scan and scans A **once**.
4. B should briefly show Zyncing and then enter Match without showing a response QR.
5. Without touching A, A should automatically leave Show QR and enter Match after the relay poll receives/decrypts B.
6. Compare both phones: same shared-interest count/order and same initial hidden/reveal state.
7. Start conversation on both and confirm deterministic session context / zero-match crossover behavior as applicable.
8. Return later and verify local Zync Again history on both devices.

Failure/recovery QA:

- background A while waiting, resume, then scan with B;
- temporarily drop A network during/after B response, restore it and confirm A can poll again rather than losing the response;
- retry B after an ambiguous network timeout and confirm identical ciphertext retry is accepted;
- attempt a different second scanner and confirm it is rejected;
- leave a QR for >3 minutes and verify expiry/regenerate flow;
- cancel/leave Show QR before scan and confirm no stale usable session remains beyond TTL;
- test no-overlap profiles for zero-match crossover;
- test normal phone viewport, Fold/large viewport, narrow viewport and larger accessibility text.

Do not mark physical QA passed until this has actually been executed against a deployed relay.

## 19. Frozen product / release invariants to preserve

- Mission: `Discover what connects you.`
- No account / permanent cloud profile / feed / posts / friends / follows / chat / communities / nearby/location / Phase-2 hobbies economy / merchants / ads / payments / subscription / dating / career in V1.
- Interest profile/history local-first.
- Interest DNA descriptive only.
- Modes remain Easy / Fun / Debate / Deep / Guess / Surprise.
- Android package: `com.gmail.gentle3f.myproject`.
- Version: `1.0.0+6` until the release owner intentionally bumps it.
- SDK 36 target remains.
- Public V1 analytics remain off.
- OpenRouter ZDR/data-collection-deny remains mandatory.
- Existing signing key/workflows and Play internal-release guards must not be weakened.
- Do not target a desired Play outcome or publish automatically.

## 20. Recommended continuation order

1. **Do not change the certified relay/layout code casually.** It is green at SHA `ee2d8409...` / CI #157.
2. Provision/connect Upstash externally and add only the three server-side Vercel env values above.
3. Keep branch auto-deploy protection on until intentionally executing the one-shot preview procedure in `docs/PRODUCTION_ONE_SHOT_RELEASE_V1.md`.
4. Create exactly the controlled preview required by that runbook.
5. Run the prepared live API/privacy/relay smoke against that fresh preview.
6. Install/build against that verified API origin and execute the exact two-phone physical QA above.
7. Only after preview/live-smoke + physical QA pass, consider production promotion.
8. After production smoke, follow the existing signed-release / Play internal-test workflow; do not bypass confirmation or signing guards.

If a future chat starts before external setup is complete, it should begin at **Upstash provisioning / controlled preview preparation**, not rediscover or rebuild the relay architecture.

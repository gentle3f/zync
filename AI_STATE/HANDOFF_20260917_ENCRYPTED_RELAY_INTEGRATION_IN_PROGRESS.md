# Zync V1 — Encrypted Relay Integration In-Progress Handoff

Date: 2026-09-17 / active chat continuation  
Branch: `zync-v1-rebuild-20260917`

This handoff is additive. Preserve all earlier `AI_STATE` handoffs. It continues directly from `AI_STATE/HANDOFF_20260917_PLAY_INTERNAL_RELEASE_AUTOMATION.md` and the earlier release/privacy lineage. Do not restart repo discovery or old Thunkable archaeology.

## User-approved decision

The user explicitly approved the production-quality one-scan pairing architecture and explicitly approved Upstash after cost/TTL discussion:

- Vercel API + Upstash Redis temporary relay;
- 3-minute session lifetime;
- no scheduled cleanup job: Redis TTL is the hard cleanup guarantee;
- scanner response encrypted on-device with AES-GCM using a one-time 256-bit key carried only in the QR;
- relay must not receive that decryption key;
- no login, no permanent cloud profile, no social graph;
- remain in Chat mode; do not hand off to Work mode.

## Release blockers being addressed

1. Normal modern phone screens should not feel like they require vertical scrolling for Home / Show QR when their content fits. Small screens, large text and accessibility still get safe scroll fallback.
2. One scan must advance both devices. Previously only scanner B advanced; host A had no callback/data path.

## Implemented relay backend

Added `api/v1/relay.js`.

Server state is deliberately minimal:

- key: random high-entropy session ID;
- value: `P` pending or `R:<opaque ciphertext>`;
- Redis TTL; no permanent profile database;
- create / respond / take / consume / cancel actions;
- create is retry-safe while the same random session remains pending;
- first scanner response wins;
- identical response retry is idempotent;
- different second response is rejected;
- `take` is non-destructive so a lost HTTP reply does not destroy B's encrypted response;
- host calls `consume` only after authenticated local decryption succeeds;
- abandoned state expires automatically by TTL;
- payload/protocol/session/expiry validation;
- request abuse guard uses a short-lived HMAC-derived key from request IP, not raw IP in the application rate-limit key;
- server configuration is only through `UPSTASH_REDIS_REST_URL`, `UPSTASH_REDIS_REST_TOKEN`, `ZYNC_RELAY_RATE_LIMIT_SECRET`;
- no relay payload/secret console logging.

## Implemented mobile handshake core

Added `mobile/lib/core/relay_service.dart` and `cryptography: ^2.9.0`.

Protocol v2:

- host creates ~144-bit random base64url session ID using `Random.secure()`;
- host creates 32-byte one-time secret;
- lifetime = 3 minutes;
- QR prefix `ZH2:` and compressed envelope containing protocol, session ID, expiry, one-time secret, and host compact profile;
- scanner validates protocol/session/expiry;
- scanner encrypts its limited profile response using `AesGcm.with256bits()`;
- AAD binds ciphertext to `zync-relay-v2:<sessionId>`;
- host decrypts/authenticates and checks protocol, session ID and exact expiry;
- wrong key/tampering is rejected.

## Implemented A / B UX flow

`ShowQrScreen` now:

- creates relay session before displaying a scannable QR;
- displays `Waiting for scan…` only after create succeeds;
- polls adaptively;
- survives app pause/resume;
- receives opaque response, decrypts locally, computes host-first deterministic match, records local Zync Again history, consumes relay, then auto-navigates to Match;
- has connection / expiry / regenerate UI;
- cancels best-effort on exit with TTL fallback.

`ScanQrScreen` now:

- recognizes v2 handshake QR;
- validates/self-checks;
- computes same match using host-first orientation;
- AES-GCM encrypts scanner profile response and submits it;
- keeps the exact ciphertext for retry after ambiguous network timeout so server idempotency works;
- maps expiry/duplicate/invalid/network failures to localized UI;
- retains legacy QR decode path for backward compatibility;
- advances to Match after response is accepted.

`MatchingService.compare` accepts `sessionSeed` and applies deterministic tie ordering. Both devices call it with Host(A) interests first and Scanner(B) interests second, avoiding perspective-dependent crossover/order differences.

`MatchScreen` and `ConversationScreen` carry the shared session seed forward. Initial reveal count remains identical (0) and match reveal ordering is deterministic. Post-pairing taps are still local interactions, not a persistent realtime shared social session.

## Responsive UI changes

`HomeScreen`:

- normal viewport: fixed one-screen layout, prominent Show/Scan hero and compact 2x2 function cards;
- fallback ListView only for narrow/short/large-text conditions.

`ShowQrScreen`:

- normal viewport: fixed one-screen QR layout, no vertical scroll container;
- short/large-text conditions: safe `SingleChildScrollView` fallback.

Do not hard-code to one Samsung device; layout is constraint/text-scale based.

## Localization

All existing locale ARBs were updated with the new relay/privacy states:

- English;
- Traditional Chinese;
- Simplified Chinese;
- generic Chinese;
- Japanese;
- Korean;
- Spanish;
- French;
- Portuguese.

New states include waiting, Zyncing, relay connection issue, start failure, expiry, regenerate, already-used QR, and scanner connection failure.

## Automated tests / CI hardening added

Added `.github/scripts/relay_contracts.mjs` with functional fake-Redis coverage for:

- missing configuration;
- short-lived create + retry idempotency;
- one winning encrypted response;
- identical retry vs different duplicate scanner;
- non-destructive repeated polling;
- explicit consume;
- malformed session/payload rejection;
- TTL cleanup without scheduled cleanup;
- no relay payload logging / HMAC rate-key posture.

Normal `Zync V1 CI` now syntax-checks and runs relay contracts.

Flutter `core_test.dart` now covers:

- deterministic seeded match ordering;
- v2 handshake encode/decode;
- expiry rejection;
- AES-GCM opaque response;
- correct-key decrypt;
- wrong-key rejection.

`layout_smoke_test.dart` now covers:

- normal 390x844 Home has primary CTAs with no `ListView`;
- narrow/larger-text Home uses safe scroll fallback;
- normal 390x844 Show QR has no vertical `SingleChildScrollView`;
- 320x620 Show QR uses safe scroll fallback;
- large-profile handshake QR layout;
- Traditional Chinese locale is pinned explicitly with `zh-Hant`.

Signed-release workflow now also syntax-checks relay code, runs relay contracts, and then runs production live smoke before signing. Existing Play upload-key/signature guards remain unchanged.

## Live release smoke expanded

`.github/scripts/live_api_smoke.mjs` now requires production privacy to disclose Upstash/AES-GCM/short TTL and tests synthetic relay lifecycle:

- create;
- retry-safe create;
- waiting take;
- respond;
- identical respond retry;
- different duplicate rejection;
- repeated non-destructive take;
- consume;
- post-consume not-found;
- a separate ~15s abandoned session actually disappears by TTL without scheduled cleanup.

No real profile data or AES key is used in the smoke payload.

## Privacy / Play documents updated

Updated public `privacy.html` and `terms.html`:

- no permanent cloud profile claim remains;
- host QR sharing boundary is described;
- one-scan scanner response is disclosed as AES-GCM encrypted on-device;
- Vercel + Upstash short-lived relay disclosed;
- relay has no one-time decryption key;
- roughly three-minute TTL + early consume/delete disclosed;
- request-IP/HMAC abuse-control distinction disclosed;
- OpenRouter AI path and analytics-off posture preserved.

Updated:

- `docs/PLAY_DATA_SAFETY_V1_RELEASE_ANSWERS.md`;
- `docs/PRIVACY_POLICY_V1_DRAFT.md` source note;
- `docs/PLAY_RELEASE_DATA_SAFETY.md`;
- `docs/PRODUCTION_ONE_SHOT_RELEASE_V1.md`.

Data Safety is deliberately conservative: encrypted / server-opaque / ephemeral pairing data still counts as an off-device transmission to assess as collected. Do not restore "No data collected" or "direct peer transfer only".

`.github/scripts/release_web_contracts.mjs` now machine-gates the Upstash/AES-GCM/TTL/privacy disclosures and relay security posture.

## External relay setup still NOT done

No Upstash account/database was provisioned in this chat and no Vercel environment value was written. The available Vercel connector can inspect/deploy projects but does not expose environment-variable or Marketplace-storage mutation.

Therefore do **not** claim pairing is live or production-ready yet.

Production will require server-only values:

- `UPSTASH_REDIS_REST_URL`;
- `UPSTASH_REDIS_REST_TOKEN`;
- `ZYNC_RELAY_RATE_LIMIT_SECRET`.

Do not put these in the Android build or repo.

## Vercel / production protection

Do not deploy or promote now.

- stable production remains old 2025 deployment;
- branch auto-deploy remains disabled in `vercel.json`;
- the one-shot production plan remains authoritative;
- no Play upload/publish has been performed.

## Previous CI certification closed

Old run #110 / `35195682210` finished green and produced unsigned AAB artifact:

- artifact ID: `10485319459`;
- name: `zync-v1-unsigned-aab`;
- size: `60,909,405` bytes;
- digest: `sha256:fdd3eda3d67b4abf8fba7a4774dd495d2002e7f86cfd1b158087d19e4470c001`.

That artifact predates the encrypted-relay changes and is historical evidence only, not the new release candidate.

## Current CI state at this checkpoint

Newest code/release commit before this AI_STATE checkpoint:

`46852b49cbcc05f8091185206441de0335b9c5c8` — `Gate encrypted relay in signed release workflow`

CI run:

- workflow: `Zync V1 CI`;
- run number: #146;
- run ID: `35244719252`;
- job ID: `105281884044`;
- head: `46852b49cbcc05f8091185206441de0335b9c5c8`.

At checkpoint time the following already PASS:

- serverless JS syntax including relay;
- existing serverless contracts;
- encrypted relay contracts;
- OpenRouter privacy contracts;
- public release/privacy contracts;
- Play internal-release contracts/guards;
- signing configurator;
- generated Android identity/SDK checks;
- dependency install;
- localization generation.

`flutter analyze` was in progress. Flutter tests, unsigned AAB build and artifact upload were still pending. Do not call this encrypted-relay slice certified until #146 completes successfully.

## Immediate continuation order

1. Check CI run `35244719252` and fetch logs immediately if analyze/tests fail.
2. Fix only proven failures; let the next push supersede/cancel old runs.
3. When green, record new unsigned AAB artifact ID/size/digest.
4. Perform a targeted diff/audit from `37c1ca3` to the certified code SHA; confirm no V1 scope creep, version/package/signing/privacy regression, and `vercel.json` still blocks branch auto-deploy.
5. Create a final additive certified handoff and update `AI_STATE/LATEST_HANDOFF.md` again.
6. Do not deploy/publish. External next blocker is Upstash/Vercel server configuration, then controlled preview/live relay smoke, then two-device physical Android QA, then signed release/Play test track under the existing one-shot plan.

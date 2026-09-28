# Zync — Provider Linking + Same-World Recovery

Date: 2026-09-28
Branch: `card-art-pilot-v1-20260921`
Starting HEAD: `5ae3fdc`

## Goal

Prevent a player from being locked to a single identity provider after creating a
Cardverse-backed Zync World.

The safe path is **provider linking**, not automatic account merging:

- player must already have a valid Cardverse session
- player explicitly re-verifies a second Google/Apple identity
- server links that verified identity to the currently signed-in Zync World
- future normal sign-in with either linked identity resolves the same account

No economy, inventory, RNG, reward receipt or collection merge logic changed.

## Existing backend contract inspected

The production-lineage backend already exposes:

`POST /api/v1/cardverse/auth/link`

The route requires:

- an existing bearer Cardverse session
- provider
- one-time challenge ID
- freshly verified provider ID token

It reuses the existing provider-token verification + one-time nonce consumption
and then calls the ownership-store identity-link transaction.

Important server conflicts:

- `cardverse_identity_already_linked` — that exact provider identity already
  belongs to another Zync account
- `cardverse_provider_already_linked` — this Zync account already has a
  different identity for the same provider

Both map to HTTP 409.

The backend does **not** currently expose a linked-provider inventory endpoint.

The backend also has `auth/unlink`, but unlink:

- requires provider re-verification
- forbids removing the last identity
- revokes **all active sessions** on success

Unlink was intentionally not exposed in this milestone; it needs a separate
destructive-action UX and re-auth design.

## Mobile cloud contract

Updated:

`mobile/lib/core/cardverse_cloud_client.dart`

Added:

- `CardverseProviderLinkResult`
- `linkProviderIdentity(...)`

The client:

- sends the existing session only as the bearer credential
- sends only provider/challengeId/idToken in the body
- never sends accountId from the client
- requires returned provider to match requested provider
- requires `linked == true`
- preserves 409 server codes for precise conflict UX

## Link orchestration service

Added:

`mobile/lib/core/cardverse_identity_link.dart`

Google flow:

1. require an existing secure Cardverse session
2. require configured Google server client ID
3. request a one-time `google` challenge
4. reject if challenge provider mismatches
5. re-verify Google using the exact challenge nonce
6. call authenticated `/auth/link`

Apple flow:

1. require an existing secure Cardverse session
2. request a one-time `apple` challenge
3. reject if challenge provider mismatches
4. re-verify Apple using the exact challenge nonce
5. call authenticated `/auth/link`

If link returns 401, the local secure session is cleared because it is stale.
A 409 does **not** clear the current session.

## Production Account UX

Updated:

`mobile/lib/screens/cardverse_account_screen.dart`

When signed in on iOS, Account now has:

**Keep one Zync World across devices**

It explains that a newly verified provider is attached to the Zync World the
player is already using.

Privacy and safety copy explicitly says:

- this does not upload People history/private conversations
- a different existing Zync World is not automatically merged
- if the identity belongs to another Zync World, linking stops and neither world
  is modified

Actions:

- Verify & link Google, when the native iOS Google path is configured
- Continue with Apple, using the official Apple button

Success only adds an in-memory **linked this visit** confirmation. It is not
persisted as a provider inventory because the server currently has no endpoint
that can authoritatively enumerate linked providers.

Conflict UX is deliberately distinct:

- identity belongs to another world -> nothing merged/changed; player can sign
  out and use that identity to open its existing world
- current world already has a different identity for this provider -> existing
  link is not replaced

Android keeps the recovery surface hidden because the current Zync Apple
identity path is intentionally iOS-only.

## QA Account Lab

Updated:

`mobile/lib/screens/cardverse_account_lab_screen.dart`

When a Cardverse session exists, QA Lab can explicitly:

- verify & link Google
- verify & link Apple on iOS

Diagnostic status exposes:

- provider
- client/provider error code
- cloud failure class
- HTTP status
- serverCode
- restored flag on success

No identity token is displayed.

## iOS compile-smoke contract

Updated:

`.github/workflows/zync-ios-compile-smoke.yml`

The workflow remains **workflow_dispatch only** and was not run.

Its shared identity test step now also includes:

- `cardverse_cloud_client_test.dart`
- `cardverse_identity_link_test.dart`

so a future deliberate macOS compile gate checks provider-link behavior too.

## Tests

Added:

`mobile/test/cardverse_identity_link_test.dart`

Coverage:

- Google link uses current bearer session + exact server nonce
- Apple link uses current bearer session + exact server nonce
- no session -> fail before challenge/provider auth
- challenge provider mismatch -> fail before identity-provider call
- 401 -> stale local session cleared
- 409 identity ownership conflict -> current session preserved

Expanded:

`mobile/test/cardverse_cloud_client_test.dart`

Coverage:

- exact `/auth/link` path
- bearer session
- body contains provider/challengeId/idToken only
- no client accountId
- 409 `cardverse_identity_already_linked` is preserved

Expanded:

`mobile/test/cardverse_account_provider_ui_test.dart`

Coverage:

- iOS signed-out still offers Apple sign-in
- Android signed-out does not
- iOS signed-in exposes recovery surface + Apple link action
- Android signed-in keeps recovery surface hidden

## Validation

Repo:

- focused Google/Apple/link/session/proof suite: **34 / 34 PASS**
- full Flutter analyze: **No issues found**
- canonical non-golden regression:
  - 62 non-golden test files
  - Batch 1: 117 tests PASS
  - Batch 2: 142 tests PASS
  - Batch 3: 120 tests PASS
  - **379 tests PASS total**
- legacy missing Card Art golden remains excluded; no baseline was fabricated

Fresh generated iOS wrapper:

`C:\Users\FUJITSU\zync_ios_link_probe_20260928`

Validated:

- clean wrapper generation: PASS
- Zync branding: PASS
- Google metadata: PASS
- Apple entitlement/capability: PASS
- provider-link source/tests copied by shared generator: PASS
- Google + Apple + link + production provider UI: **29 / 29 PASS**
- generated-wrapper analyzer: no errors/warnings; INFO-only Flutter-template lint
  output remains non-fatal

No macOS Xcode compile, Vercel, GitHub Actions, Play, App Store, production deploy
or paid generation was used.

## Deliberate non-goals

### No automatic account merge

If an Apple/Google identity is already owned by another Zync World, the client
does not attempt to merge inventory, rewards, receipts or histories.

A real account-merge feature would need its own server-side invariants and UX.

### No unlink UI yet

Server unlink revokes all sessions and has a last-identity safety rule. It should
be implemented only with a dedicated re-auth + destructive confirmation flow.

### No fake provider inventory

Until Cardverse exposes a server-authoritative provider-list endpoint, the client
does not persist or claim a complete list of linked identities.

## Best next substantial work

Two strong next directions:

1. **Account lifecycle safety:** design server-authoritative linked-provider
   status + safe unlink/re-auth UI, without exposing tokens or allowing the last
   identity to be removed.
2. **Native release readiness:** close Android local APK compile/stable QA
   signing and real iOS OAuth/Apple Developer provisioning so Google + Apple +
   provider linking can be smoked on physical devices.

Do not return to Card FX micro-tuning without fresh user feedback.

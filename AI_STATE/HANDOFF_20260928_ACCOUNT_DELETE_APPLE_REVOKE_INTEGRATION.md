# Zync — Account Deletion + Apple Revocation Integration

Date: 2026-09-28

## Current mobile branch

`card-art-pilot-v1-20260921`

Starting HEAD before this checkpoint:
`5ff809ebb1eb4b7c51dff564c822bcfeed853070`

## Current backend checkpoint

Separate local-only production-lineage worktree:

`C:\Users\FUJITSU\zync_backend_account_delete_20260928`

Branch:

`local/account-delete-apple-revoke-20260928`

Backend local commit:

`4a0ee67862f1ee8300c21601aaaf8ffbb3928740`
`Add account deletion Apple revocation`

This backend commit is **NOT pushed and NOT deployed**.

## What is now implemented in mobile

### Apple identity credential

`mobile/lib/core/apple_identity_provider.dart`

Native Sign in with Apple now returns:

- verified-shape Apple ID token
- fresh Apple authorization code

The authorization code is not persisted.

Ordinary Apple sign-in and provider linking continue to submit only the ID token.
The fresh authorization code is used only by account deletion.

### Versioned destructive API contract

`CardverseCloudClient.deleteAccount(...)` now posts to:

`/api/v1/cardverse/account/delete`

with:

- bearer Cardverse session
- provider
- challenge ID
- fresh provider ID token
- Apple authorization code only for Apple deletion
- destructive confirmation:
  `DELETE_ACCOUNT_V2`

No client account ID is sent.

The V2 confirmation is intentionally incompatible with the old backend contract
that accepted `DELETE`.

If new mobile code ever reaches an old server, that old server rejects V2 rather
than deleting an Apple-linked account without token revocation.

Deployment ordering therefore fails closed.

### Account deletion domain service

Added:

`mobile/lib/core/cardverse_account_deletion.dart`

The service owns:

- current-session requirement
- fresh Cardverse auth challenge
- fresh Google or Apple re-auth
- exact challenge nonce forwarding
- Apple authorization-code forwarding
- successful deletion session cleanup
- stale-session cleanup on 401
- session preservation on 409 Apple-required / Apple revoke failure / other
  non-authoritative delete failures

Important behavior:

- Google delete never sends an Apple authorization code
- Apple delete always sends the fresh Apple authorization code
- a failed Apple revoke does not clear the current local session as if deletion
  had succeeded

### Destructive Account UI

`mobile/lib/screens/cardverse_account_screen.dart`

Signed-in Account now exposes:

`Permanently delete Zync account`

The UX is deliberately two-step:

1. explicit destructive confirmation
2. explicit fresh identity-verification choice

The first dialog clearly distinguishes:

- cloud Zync account / Cardverse sign-in state
- local-first People history and private conversations

Deleting the cloud account does **not** claim to erase local People history or
private conversations because those are separate device-local data.

The provider dialog offers only providers actually available on that platform.

On iOS:
- Google can be used initially if available
- Apple can be chosen explicitly
- if the backend reports `cardverse_apple_reauth_required`, UI tells the user
  to restart deletion and choose Apple
- it does not unexpectedly chain into a second Apple authorization prompt

On Android:
- deletion can use Google verification

Successful deletion transitions the Account screen back to signed-out state.

### User-visible failure behavior

Handled explicitly:

- cancelled Google verification
- cancelled Apple verification
- missing/stale Cardverse session
- Google client configuration missing
- `cardverse_apple_reauth_required`
- Apple revoke failure
- Apple token-exchange failure
- Apple revocation backend not configured
- generic cloud failure

Every failure path says that deletion did not complete rather than implying
success.

## Backend implementation in local production-lineage worktree

Backend commit `4a0ee678` adds:

- `server/cardverse/apple_revocation.js`
- Apple auth-code -> token exchange -> revoke flow
- short-lived server-generated Apple client-secret JWT using existing `jose`
- account deletion preflight
- mandatory Apple re-auth when an Apple identity is linked
- hard removal of provider identity links
- hard removal of Cardverse bearer sessions
- deleted account tombstone
- retained de-identified append-only Cardverse economy/audit ledger
- readiness fail-closed check for Apple revocation secrets
- V2 destructive confirmation only

Required backend secrets:

- `ZYNC_APPLE_TEAM_ID`
- `ZYNC_APPLE_KEY_ID`
- `ZYNC_APPLE_TOKEN_CLIENT_ID`
- `ZYNC_APPLE_PRIVATE_KEY_P8_BASE64`

No Apple refresh token, access token, authorization code or P8 private key is
persisted or logged by the revocation module.

Backend validation:

- all **11 Cardverse server contract scripts PASS**
- no live DB call
- no live Apple call
- no deployment
- no push

Backend detailed handoff:

`AI_STATE/HANDOFF_20260928_ACCOUNT_DELETE_APPLE_REVOKE_BACKEND.md`
inside the local backend worktree.

## Mobile validation

Focused account deletion / Apple / cloud suite:

- **35 / 35 PASS**

Broader account/auth/session/cloud regression:

- **52 / 52 PASS**

Full:

`flutter analyze --no-pub`

- **0 issues**

`git diff --check`

- clean

iOS submission audit:

- privacy contract: PASS
- problems: []
- account creation: detected
- account deletion: detected
- only remaining submission blocker:
  `apple_token_revocation_not_verifiable`

This remaining blocker is intentional because the backend Apple revoke runtime
is still isolated in the local production-lineage worktree and has not yet been
integrated/deployed into the submission lineage.

## Full mobile test-suite note

A clean regression run excluding only the known-missing golden file executed:

- 63 mobile test files
- 392 tests
- **392 / 392 PASS**

Running the literal full suite including the golden test produces one unrelated
infrastructure failure:

`card_art_engine_golden_test.dart`

Reason:

`mobile/test/goldens/card_art_engine_v1_flagships.png`

does not exist in the filesystem **and is not tracked on current HEAD**.

The failure message is:

`Could not be compared against non-existent file`

This is not a golden image mismatch and not caused by account-deletion changes.

Do not regenerate or silently bless this unrelated golden as part of account
deletion work.

## Infrastructure / cost guardrails

Audited before checkpoint:

- current branch `card-art-pilot-v1-20260921` is not a push target of the Zync
  GitHub workflows
- `vercel.json` explicitly has deployment disabled for
  `card-art-pilot-v1-20260921`
- no GitHub Actions run was requested
- no Vercel deployment
- no production deployment
- no Play release
- no App Store upload
- no live Apple revoke
- no live database mutation

## Next authoritative work

Do **not** fake the remaining iOS blocker.

The next platform step is to integrate the backend local commit
`4a0ee678` into the real production-lineage branch, configure the four Apple
revocation secrets, and validate the actual backend runtime before any mobile
release can depend on account deletion.

Deployment order must be:

1. strengthened backend with `DELETE_ACCOUNT_V2` + Apple revoke
2. backend readiness verification
3. only then mobile build/release using V2 deletion

After backend integration is verifiable from the submission lineage, rerun:

`python mobile/tool/audit_ios_app_store_submission.py --strict-submission`

Strict submission should only turn green when real runtime Apple-revoke evidence
is present; do not weaken the audit to make it pass.
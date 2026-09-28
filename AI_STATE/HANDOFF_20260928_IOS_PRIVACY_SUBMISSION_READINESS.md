# Zync — iOS Privacy Manifest + App Store Submission Audit

Date: 2026-09-28
Branch: `card-art-pilot-v1-20260921`
Starting HEAD: `465e6a8`

## Goal

Close the iOS privacy-manifest / App Store disclosure layer and turn App Store
submission readiness into a fail-closed, source-controlled audit rather than an
informal checklist.

No macOS GitHub Actions run, App Store upload, Google Play action, Vercel
deployment or production deployment was performed.

## App-level privacy source of truth

Added:

`mobile/app_store_privacy_details.json`

Current app-level declaration is deliberately conservative and tied to current
runtime behavior.

Tracking:

- `tracking = false`
- no tracking domains
- no App Tracking Transparency permission

Collected data declared for App Functionality:

- Email Address
- User ID
- Product Interaction

All three are declared:

- linked to the user
- not used for tracking
- App Functionality only

Basis from current code:

- Sign in with Apple requests the email scope
- Google/Apple provider tokens are sent to the Zync backend for account
  authentication/linking
- the backend issues a Zync account/session identity
- signed-in Cardverse uses server-authoritative daily-login, quest, draw, pack,
  proof and inventory/reward operations

This declaration is intentionally separate from local-only People history,
private conversations and the core local matching profile.

Production analytics remain declared disabled.

## App-level PrivacyInfo.xcprivacy

Added:

`mobile/tool/apply_ios_privacy_manifest.py`

Because Zync does not keep a committed long-lived `ios/` tree, the helper:

1. reads `mobile/app_store_privacy_details.json`
2. generates `ios/Runner/PrivacyInfo.xcprivacy`
3. creates deterministic PBXBuildFile/PBXFileReference IDs
4. adds the manifest to the Runner PBXGroup
5. adds the manifest to Runner's Resources build phase
6. validates exact source-of-truth contents
7. is idempotent

Current manifest declares:

- tracking false
- no tracking domains
- EmailAddress / ProductInteraction / UserID
- linked=true
- tracking=false
- AppFunctionality purpose
- no app-level required-reason APIs

The app-level required-reason list is empty because current Dart/Zync app code
does not directly invoke a required-reason native API. Native Flutter plugins
must carry their own privacy manifests for their native API usage.

### Real current-template proof

The helper was applied to the real fresh generated iOS wrapper:

`C:\Users\FUJITSU\zync_ios_release_probe`

Verified:

- `ios/Runner/PrivacyInfo.xcprivacy` exists
- Runner group contains the file
- Runner Resources phase contains the file
- repeated apply is idempotent
- source manifest matches the locked JSON privacy spec

## Dependency privacy-manifest audit

Added:

`mobile/tool/audit_ios_privacy_dependencies.py`

It resolves the actual installed package roots from
`.dart_tool/package_config.json` rather than assuming Pub-cache paths.

Current required-manifest allowlist:

- `flutter_secure_storage_darwin`
- `google_sign_in_ios`
- `mobile_scanner`
- `shared_preferences_foundation`
- `url_launcher_ios`

For each required package it requires:

- exactly one `PrivacyInfo.xcprivacy`
- valid plist
- tracking=false
- no tracking domains

For `shared_preferences_foundation`, it additionally requires a UserDefaults
required-reason declaration with at least one reason.

The real current generated-wrapper dependency graph was audited successfully.
Current `shared_preferences_foundation` declares:

- `NSPrivacyAccessedAPICategoryUserDefaults`
- reason `CA92.1`

Packages that do not currently carry a privacy manifest are not automatically
treated as failures. Zync does not invent third-party declarations merely
because an SDK has no manifest; the allowlist is limited to packages that are
known to require/ship one in the current dependency graph.

## Workflow integration

Updated both:

- `.github/workflows/zync-ios-compile-smoke.yml`
- `.github/workflows/zync-ios-signed-archive.yml`

Both now:

1. apply/check the app-level privacy manifest to the fresh wrapper
2. require it to be present in the Xcode Resources phase
3. run the dependency privacy-manifest audit after `flutter pub get`
4. run the App Store privacy/submission audit
5. compile with `ZYNC_ANALYTICS_ENABLED=false`

The unsigned compile-smoke additionally verifies the compiled
`Runner.app/PrivacyInfo.xcprivacy`.

The signed-archive path additionally verifies
`Payload/*.app/PrivacyInfo.xcprivacy` inside the exported IPA.

No iOS workflow was run in this work.

## Permissions audit

The source-controlled privacy spec explicitly records:

- camera required: yes
- camera frames collected off-device: no
- tracking transparency: no
- location: no
- photos: no
- contacts: no

Current native branding only declares `NSCameraUsageDescription`.

Current app runtime uses `mobile_scanner` for the QR-scanner screen.

The privacy/submission contract rejects future appearance of:

- `NSUserTrackingUsageDescription`
- location usage descriptions
- photo-library usage description
- contacts usage description

unless the privacy declaration/work changes deliberately.

## Public legal-copy drift fixed

The public source pages had become materially stale.

Before this work they still claimed, among other things:

- Android-only scope
- no permanent cloud user profile
- no account/dashboard to delete
- landing copy saying Zync was designed without login/registration

Those claims no longer matched the implemented Google/Apple + Cardverse account
path.

Updated:

- `privacy.html`
- `terms.html`
- `index.html`

The new source copy distinguishes:

### Local/core data

Core face-to-face Zync remains usable without an account.

The following remain local/not part of Cardverse cloud sync:

- local interest profile
- Interest DNA
- private People history
- private conversations

### Optional account/cloud data

If a user chooses Google/Apple sign-in, Zync can process:

- provider identity
- provider email when supplied
- Zync account/session identity
- account-linked cards
- packs
- daily/quest rewards
- draw redemption
- proof redemption
- inventory/collection operations

The policy also now covers both Android and iOS and states camera usage is for
user-chosen Zync QR scanning.

Production analytics remain stated disabled.

The updated source legal pages have **not** been deployed to the public site in
this work because Vercel/production remained closed.

## Privacy/submission safety contract

Added:

`.github/scripts/ios_privacy_submission_contracts.mjs`

It locks:

- tracking=false
- exact current app-level collected-data categories
- linked/not-tracking/AppFunctionality semantics
- production analytics=false
- current permission surface
- privacy manifest source-of-truth integration
- plugin privacy audit
- both iOS workflows applying/auditing privacy state
- legal pages acknowledging Android+iOS + optional account/cloud state
- removal of obsolete no-account/no-cloud claims
- source-controlled submission audit

Updated:

`.github/scripts/release_web_contracts.mjs`

with the same legal-copy anti-regression assertions.

The full release-web contract suite still cannot run on this card-art branch
because the branch does not contain `api/v1/interest-popularity.js`; the
modified script passes JavaScript syntax checking and the privacy-specific
contract runs independently.

## App Store submission readiness audit

Added:

`mobile/tool/audit_ios_app_store_submission.py`

Normal mode validates the privacy/submission source contract and reports
submission blockers without preventing compile/archive artifact work.

`--strict-submission` fails if any blocker exists and is intended to become a
mandatory gate for any future actual App Store upload workflow.

Important hardening:

Apple-revoke implementation evidence can only come from runtime source under:

- `mobile/lib`
- `api`
- `server`

Tests, workflows, contracts, handoffs and documentation can never satisfy this
gate.

The audit also reports the exact runtime source files that matched Apple revoke
markers.

## Current exact App Store blockers

The deterministic repo audit now returns:

- `privacy_contract_ok = true`
- `problems = []`
- account creation detected = true
- account deletion detected = false
- Apple token revocation evidence = false
- Apple revoke implementation sources = []

Exact strict-submission blockers:

1. `account_deletion_flow_missing`
2. `apple_token_revocation_not_verifiable`

This is now the authoritative next implementation problem.

The existing Account UI offers sign-in, provider linking and sign-out only.
`CardverseCloudClient` has no delete-account route.

No fake deletion button or fake endpoint was added.

## Validation

PASS:

- Python syntax:
  - `apply_ios_privacy_manifest.py`
  - `audit_ios_privacy_dependencies.py`
  - `audit_ios_app_store_submission.py`
- app privacy-manifest helper self-test
- dependency privacy audit self-test
- real fresh-wrapper privacy integration check
- real fresh-wrapper dependency privacy audit
- iOS privacy/submission contract
- iOS signed-archive contract
- exact blocker regression:
  - privacy contract true
  - blockers exactly account deletion + Apple revoke
  - no Apple revoke runtime source
- all 9 workflow YAML files parse
- release-web contract JavaScript syntax
- `git diff --check`

Expected fail:

`audit_ios_app_store_submission.py --strict-submission` exits 2 with exactly
the two blockers above.

## Next authoritative work

Implement a real destructive account-deletion flow end-to-end:

1. backend authenticated delete-account transaction
2. safe deletion/cleanup of account-linked Cardverse state
3. Apple authorization revocation when the account has Apple identity
4. mobile destructive confirmation + re-authentication UX as appropriate
5. local bearer/session cleanup
6. deterministic tests for success/retry/conflict/failure
7. strict App Store submission audit turns green

Do not solve this with a fake local-only delete button.

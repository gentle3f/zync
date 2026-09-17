# Zync V1 — Google Play Internal Testing Release Automation Handoff

Date: 2026-09-17
Branch: `zync-v1-rebuild-20260917`

This handoff is additive. Preserve all earlier handoffs and mini-handoffs. The prior `AI_STATE/LATEST_HANDOFF.md` pointed to `AI_STATE/HANDOFF_20260917_1545_RELEASE_WEB_ONE_SHOT_READY.md`; that lineage remains valid historical context and its remaining external blockers (Vercel quota, production promotion, real Play QA) are still open and are **not** addressed by this slice.

## 1. Do not restart discovery

Continue from this state. Do not restart repository discovery, Vercel scope re-derivation, or Play Console re-verification — the confirmed current Play state (via a local, already-completed read-only API smoke test) at the time of this handoff was:

- `production`: versionCode 4, completed
- `alpha`: versionCode 1, completed
- `internal`: versionCode 1, completed
- `beta`: no release
- `test`: no release

Zync's frozen release target remains `1.0.0+6`, matching the existing signed-release workflow's version assertion.

## 2. What this slice adds

A new, narrowly-scoped publishing workflow that is separate from the existing signing workflow and does not change it:

- `.github/workflows/zync-play-internal-release.yml` — publishes an **already-signed** AAB to Google Play **Internal Testing only**. It never builds, signs, or generates a signing key. It downloads the `zync-v1-play-signed-aab` artifact from a specified, already-successful `zync-v1-signed-release.yml` run and re-verifies (`jarsigner -verify -strict`) before publishing.
- `.github/scripts/play_internal_release.py` — the actual Play Android Publisher API client. Hard-codes `ALLOWED_TRACK = "internal"` and `EXPECTED_PACKAGE = "com.gmail.gentle3f.myproject"` in code (not just workflow config), verifies the AAB is signed before any network call, opens a Play edit, uploads the bundle, updates only the `internal` track with release notes, validates, and **commits only if every prior step succeeded**. Any exception before commit triggers `edits().delete()` to abandon the edit. Has a `--self-test` mode that exercises all guard functions with local fixtures and makes no network calls.
- `.github/scripts/play_internal_release_contracts.mjs` — static contract checks against the workflow YAML and the Python script: package is exactly `com.gmail.gentle3f.myproject`, track is exactly `internal` and is never a user-supplied input, production/beta/alpha/rollout can never be selected, the workflow consumes an existing signed AAB (never builds/signs one, never runs `keytool -genkey`), credentials come only from `secrets.GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` and are never echoed/printed, the ephemeral credentials file is always cleaned up (`if: always()`), the edit-commit-only-on-success / delete-on-failure pattern is present, concurrency protection and least-privilege permissions exist, and the workflow never references Vercel deploy commands or `vercel.json`.
- `zync-v1-ci.yml` now runs `play_internal_release_contracts.mjs` (node syntax check + assertions) and `play_internal_release.py --self-test` on every CI run, and its path filters were extended to include `.github/scripts/*.py` and the new workflow file, so future edits to any of these are continuously checked.
- `docs/ANDROID_RELEASE_SIGNING.md` gained an additive section describing the new workflow, the `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` secret requirement, and the exact operator steps to run it.

## 3. Safety guards (why production/beta/alpha cannot be hit by accident)

- The Play track is **not** a `workflow_dispatch` input at all — it is hard-coded in the workflow env (`TRACK: internal`) and hard-coded again independently in the Python script (`ALLOWED_TRACK = "internal"`), so a compromised or mistaken workflow input cannot change it.
- `require_internal_track()` in the script raises before any Play API call if the track is anything other than the literal string `internal`.
- `require_expected_package()` raises if the package is anything other than `com.gmail.gentle3f.myproject`.
- `require_signed_aab()` rejects a missing, empty, non-zip, or unsigned (`no META-INF/*.RSA|EC|DSA`) AAB, then separately runs `jarsigner -verify -strict` — the same check the existing signing workflow uses.
- The Play edit is only committed after upload + track update + `edits().validate()` all succeed; any exception before that point deletes the edit via `edits().delete()`, so a failed run leaves Play in its prior state.
- Operator must type the literal string `UPLOAD_TO_INTERNAL_TESTING` in a required `workflow_dispatch` input, or the job fails at the first step.
- `concurrency: { group: zync-play-internal-release, cancel-in-progress: false }` — a second dispatch queues rather than racing an in-flight Play edit.
- `permissions: { contents: read, actions: read }` only (the `actions: read` scope is solely so `actions/download-artifact` can fetch the artifact from the specified signed-release run).
- The service-account JSON is written from the secret straight to `$RUNNER_TEMP/play-credentials.json` (never echoed/catted), referenced only via `GOOGLE_APPLICATION_CREDENTIALS`, and removed in a final `if: always()` step.
- No Vercel files are touched and no Vercel CLI/deploy step exists in this workflow; `vercel.json`'s branch-deploy-disabled protection from the prior handoff is untouched.

## 4. How a signed AAB is obtained (unchanged from existing system)

This slice does not add or change any signing mechanism. It strictly consumes what `zync-v1-signed-release.yml` already produces (per `docs/ANDROID_RELEASE_SIGNING.md`): the existing `ZYNC_ANDROID_KEYSTORE_BASE64` / `ZYNC_ANDROID_STORE_PASSWORD` / `ZYNC_ANDROID_KEY_ALIAS` / `ZYNC_ANDROID_KEY_PASSWORD` secrets sign the AAB with the existing accepted Play upload key inside that workflow, which uploads the result as the `zync-v1-play-signed-aab` artifact. No new key is generated anywhere in this slice.

## 5. Nothing was published

Per the task constraints, no Play upload was performed and no run of the new workflow was dispatched. Only local, non-destructive validation ran:

- `node --check` on both `.mjs` scripts touched.
- `node .github/scripts/play_internal_release_contracts.mjs` — passed.
- `python3 .github/scripts/play_internal_release.py --self-test` — passed (guard-function unit tests only, no network, no credentials).
- YAML parse of both changed workflow files via `python3 -c "import yaml; ..."` — both parse.

The read-only Google Play Developer API smoke test referenced in section 1 (listing tracks/releases for `com.gmail.gentle3f.myproject`) was performed in an earlier, separate local session using `GOOGLE_APPLICATION_CREDENTIALS` and is not part of this repository's commits; it only informed the "current Play state" facts recorded above.

## 6. Recommended continuation order

1. Resolve the still-open blockers from `AI_STATE/HANDOFF_20260917_1545_RELEASE_WEB_ONE_SHOT_READY.md` section 12 (Vercel quota/promotion, `ZYNC_API_BASE`/`ZYNC_PRIVACY_URL` vars, signed AAB certification, two-device QA, Play listing/Data Safety) — those are prerequisites to a real production-quality internal build, independent of this automation.
2. Once a `zync-v1-signed-release.yml` run has succeeded and its `zync-v1-play-signed-aab` artifact is available, add the `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` repository secret (Play Developer API service-account key JSON, `androidpublisher` scope, must already have access to `com.gmail.gentle3f.myproject` as verified by the local smoke test) if not already present.
3. Dispatch **Zync Play Internal Release** with that run's ID and `UPLOAD_TO_INTERNAL_TESTING` to perform the first real internal-testing upload.
4. Confirm the new release appears on the `internal` track in Play Console before inviting testers.

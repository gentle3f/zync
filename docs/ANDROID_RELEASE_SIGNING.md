# Zync V1 — Android Release Signing

This repo keeps signing material out of source control. The manual workflow `.github/workflows/zync-v1-signed-release.yml` produces a Play-ready signed AAB only after the required GitHub Actions secrets **and** the production API base are configured.

## Required GitHub Actions secrets

Create these repository secrets in GitHub Settings → Secrets and variables → Actions:

- `ZYNC_ANDROID_KEYSTORE_BASE64` — base64 of the existing upload keystore bytes.
- `ZYNC_ANDROID_STORE_PASSWORD` — keystore/store password.
- `ZYNC_ANDROID_KEY_ALIAS` — upload-key alias inside the keystore.
- `ZYNC_ANDROID_KEY_PASSWORD` — password for that key alias.

Do not commit the keystore, passwords, `key.properties`, or generated release credentials.

## Required production repository variable

For a **production signed release**, configure this repository variable in GitHub Settings → Secrets and variables → Actions → Variables:

- `ZYNC_API_BASE` — the actual production Vercel origin, using `https://` and no trailing API path.

The signed-release workflow intentionally rejects an empty, non-HTTPS, or otherwise invalid production API base. Do not guess this value and do not substitute the OpenRouter HTTP-Referer placeholder for the real deployed API origin.

Normal development and ordinary CI may still build with an empty `ZYNC_API_BASE`. In that state the app remains usable through local fallback conversation questions, but unknown-interest AI normalization and OpenRouter-generated questions are unavailable. That fallback behavior is for development/testing resilience only; it is **not** the production signed-release configuration.

Do not run **Zync V1 Signed Release** until both the production `ZYNC_API_BASE` and all four signing secrets above are configured.

## Encoding the keystore safely

Run locally against the existing upload keystore and copy only the base64 text into the GitHub secret. Do not add the encoded output to the repo.

macOS/Linux:

```bash
base64 < android.keystore | tr -d '\n'
```

PowerShell:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android.keystore"))
```

## Building the signed AAB

After the production `ZYNC_API_BASE` and all four signing secrets are present:

1. Open GitHub → Actions → **Zync V1 Signed Release**.
2. Choose **Run workflow** on branch `zync-v1-rebuild-20260917`.
3. The workflow regenerates the Android wrapper with the legacy Play identity, applies Zync branding, installs the keystore only in the ephemeral runner, patches Gradle to use the `zyncRelease` signing config, runs localization/analyze/tests, builds the release AAB, verifies the AAB JAR signature, and uploads `zync-v1-play-signed-aab` as an Actions artifact.

## Play identity guardrails

The release workflow keeps:

- application ID `com.gmail.gentle3f.myproject`
- version `1.0.0+6`
- target/compile SDK 36
- Zync launcher/splash branding

The workflow explicitly fails if the generated release build still points at Flutter's debug signing config.

## Publishing a signed AAB to Google Play Internal Testing

`.github/workflows/zync-play-internal-release.yml` is a separate, later-stage workflow that **only** publishes an already-signed AAB to the Play **Internal Testing** track. It never builds, signs, or generates a signing key itself — it downloads the `zync-v1-play-signed-aab` artifact from a completed **Zync V1 Signed Release** run and uploads that exact file through the Android Publisher API.

Required GitHub Actions secret:

- `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` — the Play Developer API service-account key JSON for the `androidpublisher` scope. Never commit this file; it is only ever read from the secret at runtime and written to an ephemeral, workflow-run-local file that is deleted at the end of the job.

To run it:

1. Run **Zync V1 Signed Release** first and note its run ID (from the Actions run URL) once it succeeds.
2. Open GitHub → Actions → **Zync Play Internal Release** → **Run workflow**.
3. Provide that run ID as `signed_release_run_id`, type `UPLOAD_TO_INTERNAL_TESTING` in `confirm_internal_upload`, and optionally set `release_notes`.

The workflow and `.github/scripts/play_internal_release.py` both hard-code the track as `internal` and the package as `com.gmail.gentle3f.myproject`; there is no input that can select production, beta, alpha, or any other track. `.github/scripts/play_internal_release_contracts.mjs` statically checks this invariant in CI.

## Important Play signing note

A signed AAB is only an update to the existing Play listing if the keystore/alias used here is the correct upload key accepted by that Play Console app. Do not rotate or replace the existing upload key merely to make CI pass. If Play App Signing is enabled and the old upload key is unavailable, use the Play Console upload-key reset process rather than creating an unrelated key and assuming it will update the app.

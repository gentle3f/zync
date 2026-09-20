# Zync — Google Android OAuth Signing Root Cause Localized

Date: 2026-09-20

Branch: `zync-v1-rebuild-20260917`

This is the authoritative continuation checkpoint after verifying the Google Credential Manager chooser-cancel failure against current official Android/Google requirements and the actual QA APK signing certificates.

## 1. Current root-cause boundary

The prior real-device failure remains:

1. POST Cardverse auth challenge succeeds.
2. Native Google/Credential Manager chooser opens.
3. User selects a Google account.
4. Chooser closes.
5. App remains unsigned.
6. No POST `/api/v1/cardverse/auth/provider` occurs.
7. Staging Neon remains without a Cardverse account/session from the attempt.

The failure is therefore still before Google ID-token handoff/provider exchange.

## 2. Official current Google requirements now verified

Current official Android / Google guidance confirms:

- Credential Manager should receive a `MutableContextWrapper` around the foreground Activity context for sign-in UI.
- Sign in with Google on Android requires BOTH:
  - an Android OAuth client, which verifies the app package name + signing certificate SHA-1;
  - a Web OAuth client, used as the backend/server client ID / ID-token audience.
- Therefore the prior assumption that the Web client ID alone was sufficient for this Android Credential Manager flow was incomplete.

Do not regress to a Web-client-only configuration.

## 3. Exact tested APK has been identified

The Library artifact `Zync-QA-preview(2).apk` has SHA-256:

`ed744e20207c1f8caf86b18147e8333cd68b5c9366a547eb67d8251657ab5a9a`

This exactly matches the real-device QA APK recorded in the prior authoritative handoff.

Its actual signer certificate is:

- subject: `C=US,O=Android,CN=Android Debug`
- SHA-1: `02:13:4C:52:5D:99:82:79:DD:D1:22:E4:27:52:00:05:FF:CC:83:97`
- SHA-256: `35:06:B7:A8:52:93:13:18:CE:5D:07:67:57:D2:20:AA:14:FA:41:B6:EC:FA:24:EB:DD:1C:E0:10:E5:ED:9D:C8`

The installed QA package is:

`com.gmail.gentle3f.myproject.qa`

## 4. Ephemeral signing is proven, not hypothetical

Two other generated QA APKs were also inspected.

`Zync-QA-Google-diagnostic.apk`:
- signer subject: Android Debug
- SHA-1: `F6:26:F4:FE:0A:5B:12:28:F4:6A:6B:B2:06:EB:26:AE:DE:DD:F0:25`

`Zync-QA-Octalysis-Batch1.apk`:
- signer subject: Android Debug
- SHA-1: `0B:85:19:43:AF:9E:F1:54:92:A3:AA:59:26:0B:B1:BF:04:72:3C:86`

Therefore separate GitHub QA builds were signed by different ephemeral Android debug certificates.

This means one Android OAuth client cannot remain valid across the old QA build process, because Google binds the Android OAuth client to package + SHA-1.

This is the strongest current root-cause candidate and is directly evidenced.

## 5. Source fix already committed

Commit:

`292c6bf7079b73e31aabb38f86b6054874fc4c79`

Message:

`fix: stabilize QA Google OAuth identity diagnostics`

Changes:

1. `mobile/tool/apply_android_google_identity.py`
   - wraps the foreground Activity in `MutableContextWrapper(this)` before Credential Manager invocation;
   - returns sanitized exception type/class/cause class for QA diagnostics;
   - still never logs/returns ID token, nonce, account email/name, bearer token, or secret.

2. `mobile/lib/core/google_identity_bridge.dart`
   - allows the sanitized `causeClass` field through to QA UI diagnostics.

3. `.github/workflows/zync-qa-preview-build.yml`
   - changes QA builds to fail closed unless a stable signing key is available;
   - applies the existing release-signing transform instead of Flutter's generated debug signing;
   - verifies the release build does not use debug signing;
   - extracts and records the actual APK signing SHA-1 in the build descriptor.

Nonce/JWT/session validation was not weakened.

## 6. CI exposed the next blocker

QA workflow job `106093982294` reached the new stable-signing gate and failed because none of the expected signing secrets are currently available:

- `ZYNC_ANDROID_KEYSTORE_BASE64`
- `ZYNC_ANDROID_STORE_PASSWORD`
- `ZYNC_ANDROID_KEY_ALIAS`
- `ZYNC_ANDROID_KEY_PASSWORD`

No new APK was produced from this failed run.

Do NOT remove the fail-closed signing requirement merely to make CI green.

## 7. Immediate one-off confirmation path

Before creating another APK, the existing installed/tested APK can be used to confirm the OAuth diagnosis.

In the SAME Google Cloud/Auth Platform project as the existing Web client ID, create an Android OAuth client with:

- package name: `com.gmail.gentle3f.myproject.qa`
- SHA-1: `02:13:4C:52:5D:99:82:79:DD:D1:22:E4:27:52:00:05:FF:CC:83:97`

Then retry Google sign-in using the exact already-installed APK whose APK SHA-256 is `ed744e...`.

Stage gate:

- challenge 200 + provider POST appears => Android Google credential acquisition succeeded; continue with server JWT/nonce verification if provider exchange rejects.
- challenge 200 + still no provider POST => capture the new sanitized native error detail / targeted logcat and continue Android provider diagnosis.
- provider succeeds => verify Cardverse session and Neon account/session rows.

This Android OAuth client is diagnostic only because that old APK uses an ephemeral debug certificate.

## 8. Permanent correction after confirmation

The permanent QA path must use ONE stable QA signing key.

Preferred target state:

1. Stable QA signing key stored only in GitHub Actions secrets (not source).
2. QA package remains `com.gmail.gentle3f.myproject.qa`.
3. Build records exact stable SHA-1.
4. Google Auth Platform Android OAuth client is registered once with that package + stable SHA-1.
5. Web client ID remains the server client ID / token audience.
6. Future QA builds use the same signer.
7. Production/Play signing remains separately gated.

If the permanent stable key differs from the currently installed ephemeral-debug APK, the existing `Zync QA` app must be uninstalled once before installing the stable-signed replacement because Android will reject an in-place update signed by a different key.

## 9. Gates remain unchanged

- Production: CLOSED.
- Google Play: CLOSED.
- Draft PR #1: DO NOT MERGE.
- Preview Cardverse API remains available only for controlled smoke.
- Pack open / quest claim / proof redeem / unrelated Cardverse gates remain closed unless separately opened later.
- Do not weaken nonce, issuer, audience, JWT signature, session, abuse, or rate-limit checks.

## 10. Continue from here

Do NOT restart repo discovery.

First action:
- complete the one-off Android OAuth client registration for the exact installed APK package + SHA-1 above;
- retry that exact APK;
- inspect whether `/api/v1/cardverse/auth/provider` appears.

Only after this diagnostic result should the permanent QA signing-secret setup be finalized.

# Zync — Google Credential Chooser Failure Localized

Date: 2026-09-20

Branch: `zync-v1-rebuild-20260917`

This is the authoritative continuation checkpoint after the first real-device Google login attempts.

## 1. User-visible failure

The certified QA APK was installed on a real Android device and the QA-only `Cardverse 帳戶實驗室` screen was exercised.

Observed behavior:
1. Tap `使用 Google 登入`.
2. Google/Credential Manager account chooser opens normally and shows the device Google accounts.
3. User selects an account.
4. Chooser closes.
5. App remains `未登入 Cardverse`.
6. On at least one attempt the QA screen explicitly showed:
   `已取消 Google 登入。[google_sign_in_cancelled]`
7. Repeated attempts behave the same way.

The latest screenshots supplied by the user show:
- the native account chooser is definitely opening;
- account selection is possible;
- after selection the UI returns to the Cardverse QA screen without a session;
- one captured return path is `google_sign_in_cancelled`.

Therefore this is not a “button did nothing” problem and not a Cardverse API-disabled problem.

## 2. Live server evidence localizes the failure before provider exchange

Current active Preview deployment:
- deployment: `dpl_56cAd2zAuHxD6SzkgPs9MrurFa2Q`
- branch: `zync-v1-rebuild-20260917`
- state: READY
- stable branch alias:
  `https://zync-git-zync-v1-rebuild-20260917-gens-projects-4f99f8b9.vercel.app`

Preview `CARDVERSE_API_ENABLED=true` is active.

Real-device runtime logs from the user's latest 22:14 HKT attempts:
- 2026-09-20 14:14:00Z — POST `/api/v1/cardverse/auth/challenge` -> 200
- 2026-09-20 14:14:25Z — POST `/api/v1/cardverse/auth/challenge` -> 200
- there is NO subsequent POST to `/api/v1/cardverse/auth/provider`

Earlier attempts at ~19:21 HKT showed the same shape: challenge 200, no provider exchange.

This proves:
- mobile can reach the correct Preview backend;
- Cardverse global API gate is ON;
- challenge creation succeeds;
- Redis abuse guard and database path are sufficiently healthy for challenge creation;
- the failure occurs after challenge creation and before the Google ID token reaches `authenticateProvider()`.

## 3. Neon evidence

Staging Neon:
- project: `purple-rice-79852073`
- branch: `br-flat-moon-b32kc1kf` (`staging-cardverse`)
- database: `neondb`

After the real-device attempts:
- `zync_accounts` count = 0
- `zync_account_sessions` count = 0

No Cardverse cloud account or session has been created yet.

This is consistent with the absence of `/auth/provider` calls.

## 4. Current Android Google bridge

Source:
`mobile/tool/apply_android_google_identity.py`

It injects:
- Android Credential Manager `1.6.0`
- credentials Play services auth `1.6.0`
- Google ID library `1.2.1`

The generated native bridge:
- receives the server-issued Cardverse nonce from Flutter;
- builds `GetSignInWithGoogleOption.Builder(serverClientId).setNonce(nonce)`;
- launches `credentialManager.getCredentialAsync(...)`;
- accepts only `GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL`;
- returns only the ID token to Flutter;
- maps `GetCredentialCancellationException` to `google_sign_in_cancelled`;
- maps all other `GetCredentialException` values to generic `google_sign_in_failed`.

Important current implementation detail:
`getCredentialAsync` is called with `MutableContextWrapper(this)` rather than the Activity context directly.

Do NOT assume this is correct. Verify against the current official Android Credential Manager / Sign in with Google documentation before changing it. It is a prime suspect because the native chooser opens but returns a cancellation after account selection.

## 5. Mobile auth flow

Source:
- `mobile/lib/core/google_identity_bridge.dart`
- `mobile/lib/core/cardverse_google_auth.dart`
- `mobile/lib/screens/cardverse_account_lab_screen.dart`

Expected sequence:
1. POST Cardverse challenge.
2. Pass challenge nonce + Web client ID to native Credential Manager.
3. Receive Google ID token.
4. POST `/api/v1/cardverse/auth/provider`.
5. Server verifies Google JWT issuer/audience/signature + nonce.
6. Save returned opaque Cardverse session into secure storage.
7. Run pending proof sync.

Actual sequence currently stops between steps 2 and 3.

## 6. Google configuration currently present

The same Google Web OAuth Client ID is configured in:
- Vercel Preview: `ZYNC_GOOGLE_CLIENT_IDS`
- GitHub Actions repository variable: `ZYNC_GOOGLE_SERVER_CLIENT_ID`

The QA artifact confirms:
`google_server_client_id_configured=true`

Do not paste the actual client ID or any secret into chat/source.

Client secret is not used by this backend ID-token verifier.

Do NOT blindly conclude that an Android OAuth client / package SHA-1 is unnecessary. Re-check current official Google Credential Manager documentation and Google Auth Platform requirements for this exact Android Sign in with Google flow before deciding. Earlier we simplified to Web-client-ID-only; this needs to be validated against the observed real-device failure.

## 7. Certified QA artifact

Successful workflow:
- Zync V1 CI #1028 — SUCCESS
- Zync QA Preview APK #309 — SUCCESS

Installed QA APK:
- package: `com.gmail.gentle3f.myproject.qa`
- label: `Zync QA`
- API base: stable Preview branch alias
- analytics=false
- qa_debug=true
- Google server client ID configured=true
- APK SHA-256:
  `ed744e20207c1f8caf86b18147e8333cd68b5c9366a547eb67d8251657ab5a9a`

The APK successfully compiled and ran on-device. This is a runtime identity-flow issue, not a build failure.

## 8. Vercel function consolidation remains certified

The prior Hobby-plan blocker is solved:
- 12 Cardverse public routes preserved;
- one Cardverse Vercel router entrypoint;
- total `api/**/*.js` function count = 10;
- real Preview deployment reached READY.

Do not undo this consolidation while debugging Google auth.

## 9. Current deploy/gate state

- Preview `CARDVERSE_API_ENABLED=true` remains active for the controlled device smoke.
- Pack open = false.
- Quest claim = false.
- Proof redeem = false.
- Account lifecycle = false unless explicitly changed later.
- Source has branch auto-deploy closed again after the smoke deployment.
- Production remains CLOSED.
- Google Play remains CLOSED.
- Draft PR #1 remains DO NOT MERGE.

Do not deploy to Production while fixing this.

## 10. Most useful next debugging step

Do NOT restart repo discovery.

First, inspect current official Android Credential Manager / Sign in with Google docs and compare them line-by-line with the injected Kotlin bridge.

Then make a QA-only diagnostic pass that identifies the exact native failure without exposing tokens or account data.

Recommended order:

1. Verify whether `CredentialManager.getCredentialAsync` must receive the Activity context directly. Strong candidate change:
   - replace `MutableContextWrapper(this)` with `this@MainActivity` / direct Activity context if official docs confirm it.
2. Improve QA-only native exception reporting:
   - preserve `GetCredentialCancellationException` distinction;
   - return a sanitized exception class/type/code to Flutter;
   - never return/log Google ID tokens, nonce values, emails, account names, Cardverse bearer tokens, or secrets.
3. Verify current Google Auth Platform requirements for this Android Credential Manager flow:
   - Web server client ID;
   - Android package/client registration requirements, if any;
   - SHA-1 requirements, if any;
   - testing/publishing/test-user restrictions.
4. Build a new QA APK and repeat the same device test.
5. Use Vercel runtime logs as the stage gate:
   - challenge 200 + no provider POST => still Android/Google stage;
   - provider POST appears => native Google token acquisition succeeded; then diagnose server JWT/nonce verification if it fails.
6. Only after successful provider exchange, query Neon for the account/session row.
7. Do not weaken nonce validation, issuer/audience validation, JWT signature validation, session security, rate limits, or fail-closed gates to make the test pass.

If the sanitized native diagnostics are still insufficient, use a short targeted `adb logcat` capture around one login attempt rather than adding broad persistent logging.

## 11. Key evidence to preserve

Latest real-device failure evidence:
- Google account chooser opens.
- User selects an account.
- chooser disappears.
- Cardverse remains unsigned.
- UI can show `[google_sign_in_cancelled]`.
- latest Vercel logs show challenge 200 at 14:14:00Z and 14:14:25Z.
- no `/auth/provider` call.
- staging Neon accounts=0, sessions=0.

This is the current forensic boundary. Continue from here.

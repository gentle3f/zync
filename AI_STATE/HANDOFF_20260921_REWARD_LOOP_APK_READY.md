# Zync — Reward Loop APK Ready

Date: 2026-09-21
Branch: `zync-v1-rebuild-20260917`

Production: **CLOSED**
Google Play: **CLOSED**
Draft PR #1: **DO NOT MERGE**

## Current state

- Preview auto-deploy gate is CLOSED again.
- Latest successful Preview backend remains live on the branch alias.
- Live probes:
  - inventory -> 401 session_missing
  - Quest Claim -> 405 POST only
  - Pack Open -> 405 POST only
  - Proof Redeem -> 405 POST only
  - Draw Redeem -> 405 POST only
  - Daily Login Reward -> 405 POST only
- Staging migration 0007 is applied and verified.
- Current Flutter Android CI: PASS.
- Cardverse Postgres: PASS.
- GitGuardian: PASS.
- Stable signed QA workflow still fails intentionally because permanent signing secrets are absent.

## Latest physical-test APK

Workflow run:
`35571990084`

Job:
`106245358008`

Artifact:
`zync-reward-loop-diagnostic`

APK:
`Zync-QA-Reward-Loop-Diagnostic.apk`

Source SHA:
`38d04039cf2898f9cc31ae54ec21a9ad01a62c3e`

Package:
`com.gmail.gentle3f.myproject.qa`

Label:
`Zync QA Reward Loop`

SHA-256:
`0d4ed9b283a05af1a8e54b89c224ec2abd480b26c925626a8528e2b71b50832f`

Ephemeral Android signer SHA-1:
`D1:5C:17:A3:AF:16:4B:E7:D2:08:78:2B:26:B5:1D:38:B3:9F:6A:3B`

Because permanent QA signing is not configured, this signer is one-off. Google Android OAuth must include this exact package/SHA-1 for this APK before Google login can work.

## Next physical QA sequence

1. Register the APK SHA-1 on the existing Google Android OAuth client for package `com.gmail.gentle3f.myproject.qa`.
2. Install the new APK.
3. Google/Zync Account login.
4. Daily Check-in -> +1 Draw.
5. Redeem 1 Draw -> one card.
6. Complete/claim a task.
7. Open any rewarded pack.
8. Reveal 5 cards.
9. Confirm My Zync World collection updates.
10. Sign out/in and confirm collection restores.

Do not change the Web client ID. Do not publish consent or alter tester settings absent new evidence.

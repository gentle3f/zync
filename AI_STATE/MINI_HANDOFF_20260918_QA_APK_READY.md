# Zync V1 — Preview QA APK Ready Mini Handoff

Date: 2026-09-18 HKT
Branch: `zync-v1-rebuild-20260917`

This is additive. Preserve `MINI_HANDOFF_20260918_UPSTASH_PREVIEW_SMOKE_PASS.md`, `HANDOFF_20260918_RELAY_PAIRING_RESPONSIVE_CERTIFIED.md`, and all earlier lineage.

## Live relay gate already passed

The controlled preview `https://zync-rkrlbekvu-gens-projects-4f99f8b9.vercel.app` is READY and the real Vercel -> Upstash encrypted relay lifecycle passed GitHub Actions run `35249412965`, including create, idempotent retry, wrong host-token rejection, scanner response, duplicate protection, non-destructive polling, consume/delete and Redis TTL cleanup.

Preview Authentication remains temporarily OFF for two-device QA. Production remains unchanged. Re-enable preview authentication after physical QA.

## Two-device QA APK is ready

One-shot workflow `Zync Preview QA APK` completed the critical build/upload steps successfully in run `35249635868`, job `105298499598`.

Artifact:
- artifact ID: `10509416777`
- name: `zync-preview-qa-apk`
- compressed artifact size: `85,308,604` bytes
- artifact digest: `sha256:16296f65848f66c63ae574cb67d9861b7fea2f878a76c3dd810e6e216eac30ab`
- expires: 2026-09-24
- workflow head: `3e20a5d8f7d250ea3683949697bd1ecb2e5a7568`

The artifact ZIP contains one file, `app-debug.apk`:
- uncompressed APK size: `174,103,040` bytes
- locally extracted as `Zync-QA-preview.apk`
- APK SHA-256: `a229cbc09b8e5966d22b74844408c8cad5149f36d96722c9b702412f3a0b47ca`

QA APK properties:
- app label: `Zync QA`
- application ID: `com.gmail.gentle3f.myproject.qa`
- can coexist with existing Zync install
- `ZYNC_API_BASE=https://zync-rkrlbekvu-gens-projects-4f99f8b9.vercel.app`
- preview privacy URL
- analytics disabled
- debug-only QA artifact; never upload to Play

The temporary QA workflow was removed after successful artifact upload. The temporary preview relay smoke workflow was also removed earlier.

## Protection state

`vercel.json` has been re-checked after all QA commits: `deploymentEnabled` for `zync-v1-rebuild-20260917` is `false`.

Do not deploy/promote production or upload Play yet.

## Immediate continuation order

1. Give the user the QA APK and install it on both Android phones.
2. On each phone create a distinct local Zync QA profile. Include several shared interests plus some unique interests.
3. A: Show QR and wait for the waiting state.
4. B: Scan A exactly once.
5. Required pass condition: B enters Match and A automatically enters Match without touching A; both derive the same shared interests/order and session context.
6. Also inspect normal-phone Home and Show QR for unwanted vertical scrolling, background/resume A while waiting, QR expiry/regenerate, and duplicate scan behavior.
7. Record physical QA results in a new additive handoff.
8. If physical QA passes, ask user to turn Preview Vercel Authentication back ON.
9. Only then continue the established signed-production/Play internal-test one-shot release plan.

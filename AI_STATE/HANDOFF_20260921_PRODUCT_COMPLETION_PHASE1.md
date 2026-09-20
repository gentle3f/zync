# Zync — Authoritative Handoff — Product Completion Phase 1

Date: 2026-09-21
Branch: `zync-v1-rebuild-20260917`

Production: **CLOSED**
Google Play: **CLOSED**
Draft PR #1: **DO NOT MERGE**

## 1. Major state change

Google/Cardverse real-device login is no longer the active blocker.

Physical Android QA succeeded end to end:

```
Google Credential Manager
→ Google ID token
→ Cardverse nonce challenge
→ POST /api/v1/cardverse/auth/provider 200
→ internal Zync account
→ active Cardverse session
```

Vercel evidence on the successful smoke:

- `POST /api/v1/cardverse/auth/challenge` → 200
- `POST /api/v1/cardverse/auth/provider` → 200

Neon staging immediately showed:

- 1 Zync account
- 1 active session

The successful diagnostic APK used the explicit-SIWG → unfiltered Google-ID fallback flow. Do not revert the fallback without evidence.

## 2. Product priority changed

The user explicitly chose:

> finish the actual app first, then iOS/Apple.

Do not jump into iOS, Sign in with Apple or store work while the Android product loop still feels half-finished.

Canonical completion audit:

`docs/ZYNC_PRODUCT_COMPLETION_AUDIT_20260921.md`

The immediate target is a player-visible Android loop:

```
real Zync / Tried Together
→ Curiosity quest
→ Claim
→ server validation
→ Draw Token or unopened Pack
→ Open Pack
→ server-authoritative roll
→ reveal
→ live My Zync World collection
→ restore after logout/login
```

## 3. New implementation on this phase

### Commit `d425f45465b51084be1491527e8195410d6f9353`

Adds:

- product completion audit;
- typed live Cardverse inventory model;
- typed mobile Quest Claim client;
- typed mobile Pack Open client;
- inventory snapshot support for Draw Token balance;
- inventory snapshot support for claimed Quest eligibility keys;
- ownership contract coverage for the new snapshot fields.

### Commit `8dae5e7aa76f29e1d20786f0be30d1d3204e7d90`

Adds:

- `MyZyncWorldScreen` as a real cloud-facing product surface;
- live unopened-pack display;
- real server pack-open call;
- receipt-driven reveal routed in non-Lab/player mode;
- live cloud collection rendering;
- Draw Token summary;
- product empty/loading/error states;
- QA Home entry changed from account-only smoke to `My Zync World`.

The old Account Lab still exists as the temporary account-connection screen until account UX is productised.

### Commit `6b8f1f997f4f922cf958b24e96861a1fb0b0300a`

Adds:

- Curiosity Board cloud/session awareness;
- pending proof sync before claim;
- claimed-state sync from live inventory;
- real server Quest Claim button;
- deterministic idempotency key;
- server receipt validation against local eligibility;
- reward success copy for Draw Token / Standard Pack / Discovery Pack;
- sign-in-to-claim flow when no Cardverse session exists.

## 4. CI state

For `6b8f1f...`, the full Flutter/Android CI path is green:

- serverless syntax/contracts: PASS
- Cardverse durable ownership: PASS
- pack-open contracts: PASS
- auth/session: PASS
- abuse guard: PASS
- account lifecycle: PASS
- readiness: PASS
- pack policy/catalog: PASS
- Quest reward: PASS
- proof ticket: PASS
- router/function budget: PASS
- Flutter analyze: PASS
- Flutter tests: PASS
- unsigned release AAB build: PASS
- AAB artifact upload: PASS

The ordinary QA APK workflow still fails intentionally at the stable-signing guard because the stable Android signing secrets are not configured.

Do not weaken that guard.

## 5. Important staging gap

The currently deployed Preview backend is still the older stable deployment used for the Google login smoke.

Live endpoint probes currently show:

- inventory route: enabled (GET without token returns 401)
- proof redemption: 404 / gate OFF
- Quest Claim: 404 / gate OFF
- Pack Open: 404 / gate OFF

Therefore the new mobile product loop is implemented and CI-green, but a full live smoke cannot happen until a controlled Preview deployment contains the new server code and these Preview-only feature gates are intentionally enabled:

- `CARDVERSE_PROOF_REDEEM_ENABLED=true`
- `CARDVERSE_QUEST_CLAIM_ENABLED=true`
- `CARDVERSE_PACK_OPEN_ENABLED=true`

Before enabling them, confirm their dependencies are present:

- `ZYNC_CARDVERSE_PROOF_SECRET`
- valid `CARDVERSE_PACK_POLICY_V1`
- existing DB/Redis/Cardverse API dependencies

Keep Production unchanged.

## 6. Android signing state

The successful one-off diagnostic APK still used an ephemeral GitHub runner debug certificate.

The ordinary QA workflow has correctly been changed to fail closed unless stable signing secrets exist.

Required permanent QA signing secrets remain:

- `ZYNC_ANDROID_KEYSTORE_BASE64`
- `ZYNC_ANDROID_STORE_PASSWORD`
- `ZYNC_ANDROID_KEY_ALIAS`
- `ZYNC_ANDROID_KEY_PASSWORD`

Once one stable QA key exists:

1. register its SHA-1 in the Google Android OAuth client;
2. stop creating new Android OAuth SHA-1 entries for ephemeral runners;
3. uninstall an old differently signed QA APK once when migrating.

## 7. UI/UX and graphics assessment

The user explicitly considers current UI/UX and graphics incomplete.

The completion audit records the main problems:

- Home has too many similarly weighted destinations;
- trophies, quests and cards are still fragmented rather than one coherent world;
- some surfaces still expose engineering/Lab language;
- 50-card visual proof is functional but not final art direction;
- motion, haptics and sound are not yet a complete emotional layer;
- responsive Traditional Chinese typography and accessibility need a deliberate pass;
- first-use teaching needs to happen at the point of value rather than through explanatory debug copy.

Do not scale card art to thousands before the 50-card human visual review is strong.

## 8. Next engineering order

Continue directly in this order:

1. controlled Preview redeploy containing the current backend;
2. verify required proof/pack dependencies;
3. enable only the three Preview reward-loop gates;
4. physical Android smoke:
   - existing Google/Cardverse login;
   - complete / obtain a trusted progress proof;
   - Curiosity Claim;
   - unopened pack appears in My Zync World;
   - open pack;
   - reveal all five;
   - collection refreshes;
   - logout/login restores collection;
5. then productise account UX so users no longer see `Cardverse Account Lab`;
6. then perform the broader Home information-architecture + UI/UX + card-art polish pass;
7. only after Android V1 is coherent, start iOS/Apple.

## 9. Explicit boundaries

- no Production enablement;
- no Play release;
- no PR merge;
- no client-owned reward output;
- no client RNG;
- no invented Draw Token spending rule yet;
- no iOS detour yet;
- no communities/places/brands/trading detour before the complete core product loop.

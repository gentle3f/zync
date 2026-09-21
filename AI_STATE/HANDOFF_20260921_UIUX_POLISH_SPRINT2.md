# Zync — Authoritative Handoff — UI/UX Polish Sprint 2

Date: 2026-09-21
Branch: `zync-v1-rebuild-20260917`

Production: **CLOSED**
Google Play: **CLOSED**
Draft PR #1: **DO NOT MERGE**

## 1. Product direction

The user explicitly wants the actual app finished and polished before iOS/Apple work.

Do not restart repo discovery. Continue from the current Android V1 product loop and current UI/UX polish state.

## 2. Major completed product/UI work

Current app now has:

- physical Android Google → Zync Account login already proven;
- product-facing Zync Account screen;
- My Zync World as the unified progression destination;
- Daily Check-in → Draw Token;
- 1 Draw Token → one server-authoritative single-card draw;
- Daily / Weekly / Lifetime tasks;
- 40+ achievements in four families;
- secret achievement requirements hidden until unlock;
- real Quest Claim / Pack Open contracts;
- player-mode pack reveal with Lab diagnostics hidden;
- live cloud collection + Want to Try bridge.

## 3. UI/UX polish landed

Key commits in order:

- `03f648320f...` shared visual hierarchy primitives.
- `0cfafb54dd...` Home hierarchy / branded hero.
- `846c3c6f34...` My Zync World daily destination.
- `d1edf7086c...` Quest Board progression presentation.
- `a191205825...` collectible achievement presentation.
- `f7f7f857fc...` player-facing Zync Account.
- `3f23624aef...`, `3d86aa2bca...`, `9929f8fb99...` player pack reveal, haptics and debug separation.
- `aba83531b8...` 1:1 staged reveal polish.
- `af8696b637...`, `1023b2e829...` Group Zync host lobby/reveal polish.
- `c45ffa71f6...` Zync Now host decision polish.
- `bf45661b3b...` Group/Zync Now participant reveal polish.
- `43ef642fbf...` broader Cardverse palette diversity.
- `ff03eb2de6...` expanded 50-card Visual Lab review gate.

## 4. Current visual state

Strong now:

- Home hierarchy;
- unified My Zync World;
- Daily Draw presentation;
- task/achievement progression surfaces;
- account presentation;
- player-vs-Lab separation;
- staged 1:1 / Group / Zync Now reveal moments;
- consistent hero/metric/status language;
- 50-card review surface;
- improved palette variety.

Still intentionally open:

- human art-direction review of all 50 cards;
- weak scene/family identities found during that review;
- interaction/game variety inside 1:1 and Group Zync;
- recent-activity/memory treatment in My Zync World;
- final Traditional Chinese typography/accessibility review;
- optional sound layer and final haptic tuning.

Do **not** scale card art to thousands before reviewing the 50-card batch.

## 5. CI state

At handoff creation, the latest Flutter job had already passed Analyze and Test and was in the unsigned AAB build stage. Cardverse/Postgres and GitGuardian were green.

The ordinary signed QA APK workflow still fails intentionally because permanent stable QA signing secrets are not configured. Do not weaken this guard.

## 6. Backend / physical QA boundary

The current mobile/product code is ahead of the last physically proven Preview reward runtime.

Next product certification still requires a controlled Preview deployment containing the current backend, with only the required Preview gates enabled after dependency verification.

Then physically test:

1. Daily Check-in → Draw Token → one-card draw;
2. real task completion → Quest Claim;
3. unopened pack → Pack Open → five-card reveal;
4. cards appear in My Zync World;
5. logout/login restores the same collection.

Keep Production unchanged.

## 7. Recommended continuation

1. Confirm current CI/AAB result.
2. Update/controlled-deploy Preview backend.
3. Verify reward/draw dependencies and enable only Preview gates.
4. Physical Android end-to-end reward loop.
5. Human-review the 50-card Visual Lab and refine weak art families.
6. Fix any interaction friction found in physical 1:1 / Group / Zync Now QA.
7. Permanent Android QA signing.
8. Accessibility/performance/store readiness.
9. Only after Android V1 coherence, begin iOS/Sign in with Apple/TestFlight.

## 8. Explicit boundaries

- no Production enablement;
- no Play release;
- no PR merge;
- no client RNG;
- no client-owned reward output;
- no iOS detour yet;
- no communities/places/brands/trading detour before core product certification.

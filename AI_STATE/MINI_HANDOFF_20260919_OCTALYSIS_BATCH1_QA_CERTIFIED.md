# Zync V1 — Mini Handoff — 2026-09-19 Octalysis Batch 1 QA Certified

Branch: `zync-v1-rebuild-20260917`

Authoritative long-form product handoff remains:

`AI_STATE/HANDOFF_20260918_ICEBREAKING_SOCIAL_AI_LIVE_QA_READY.md`

This mini-handoff supersedes the previous physical-QA gate checkpoint for continuation order.

## What changed in this batch

Implemented the first Octalysis-inspired product batch without opening Production or Play:

1. **Onboarding V2 — five-interest quick start**
   - first-use copy now explicitly says five interests are enough to start;
   - root-level Quick Picks are shown before requiring taxonomy drilldown;
   - progress runs from 0/5 to ready;
   - CTA becomes Ready to Zync after five interests;
   - full catalog/search/L1→L2→L3 browsing is still preserved for later Interest DNA growth.

2. **Interaction Engine V3 — backward-compatible structured interactions**
   - `/api/v1/question` still returns legacy `question`;
   - response now additionally includes `interaction.version/type/prompt/turnPattern`;
   - mode mapping:
     - easy → pick
     - fun → play
     - debate → defend
     - deep → reveal
     - guess → guess
     - surprise → surprise
   - mobile renders a localized interaction mechanic cue before the prompt;
   - local shared-interest fallback was upgraded so AI failure no longer collapses back to generic interview-style questions.

3. **Mystery / progression loop**
   - exact shared-connection reveal now shows explicit progress;
   - remaining hidden-connection count is shown;
   - final reveal shows an all-revealed state;
   - existing Keep discovering / unmatched-interest exploration remains intact.

4. **Meaningful Zync measurement**
   - added coarse events:
     - `connection_revealed`
     - `session_continue`
     - `session_recap`
   - `question_generated` now carries coarse `interaction_type`;
   - analytics allowlist remains content-free: no interest names, peer IDs, nicknames, or QR payloads;
   - QA APK still has analytics disabled.

5. **Responsive Trophy access fix**
   - narrow / high-text-scale Home no longer overflows from the Trophy header icon;
   - Trophy remains accessible from the menu on compact layouts.

## Certification

Latest fully green CI batch before QA packaging:

- Zync V1 CI run: `35422464506`
- serverless syntax/contracts: PASS
- privacy/release guards: PASS
- Flutter Analyze: PASS
- Flutter tests: **73 PASS / 0 FAIL**
- unsigned Android release AAB build: PASS
- artifact upload: PASS

QA packaging workflow:

- workflow: `Zync QA Preview APK`
- run: `35422940399`
- run number: `5`
- status: SUCCESS
- QA identity verification: PASS
- Analyze: PASS
- QA flags tests: PASS
- release APK build: PASS
- metadata/hash verification: PASS
- artifact upload: PASS

## Controlled Preview

Frozen Preview:

`https://zync-9d2g9vk18-gens-projects-4f99f8b9.vercel.app`

Deployment:

- ID: `dpl_HoJKbqYJQNaDYqtXwYbU44izGFPk`
- target: Preview (`null`), not Production
- Preview source commit: `9c7f4c2108ffaa09b769f98cd85deaca81f1cc68`
- branch auto-deploy was restored to disabled immediately after READY.

Live runtime verification observed on this deployment:

- `/api/v1/question`: 4 requests, all HTTP 200 during smoke;
- smoke includes one-person curiosity AI and reversed bilingual-cache path;
- structured-interaction assertions were added to the smoke workflow.

## QA APK

Artifact:

- artifact ID: `10578206304`
- artifact name: `zync-qa-octalysis-batch1`
- artifact ZIP digest:
  `sha256:a146890723448229766bde087c92b70f3573d112ea5d2c2547669ee733b793f7`
- expires: `2026-10-03T05:09:44Z`

APK:

- filename in artifact: `Zync-QA-preview.apk`
- independently verified SHA-256:
  `8be9c792a04cc7bc780240b38e71501db1cc6eb043c82fb9351ff647dcaaacf9`
- package: `com.gmail.gentle3f.myproject.qa`
- label: `Zync QA`
- API base: `https://zync-9d2g9vk18-gens-projects-4f99f8b9.vercel.app`
- privacy URL: same Preview `/privacy`
- analytics: `false`
- interest learning: `true`
- QA debug: `true`

The build metadata records `source_sha=b407775d11456a3aa0cd7a6fbb583bcde52287ba`.
This is the PR temporary merge commit:

`Merge eeb9e2efa338d0dd6a98dd3ef76970eb0cb1048b into 0c40be9bfd6e2ac17e1a2d22aeec77995231d596`

GitHub compare from `eeb9e2e...` to `b407775...` shows one merge commit and **no changed files**, confirming the APK tree is the intended branch source.

## Current active task

**Physical Android QA of Octalysis Batch 1.**

Prioritize:

1. New-user quick start:
   - see Quick Picks immediately;
   - pick/search five interests;
   - CTA becomes Ready to Zync;
   - user can proceed without filling a huge profile.

2. Structured interaction mechanics:
   - Fun shows Quick play;
   - Guess shows Guess first;
   - Debate shows Defend your pick;
   - Easy shows Pick together;
   - Deep shows Share & react;
   - Surprise shows Surprise round;
   - AI badge should still become AI when remote succeeds.

3. Mystery loop:
   - hidden connections reveal one by one;
   - progress and remaining count make sense;
   - final exact reveal transitions into Keep discovering rather than ending.

4. Trophy access:
   - normal phone header access;
   - narrow / large-text phone menu access;
   - no overflow.

5. Existing critical gates remain:
   - People history;
   - deterministic funny alias;
   - social opt-in only;
   - bilingual semantic consistency;
   - exact shared matching remains canonical-ID equality only.

## Known unresolved work

Do not claim the catalog is fully localized. Navigation taxonomy coverage is fixed, but generic leaf labels still have a large Traditional-Chinese localization gap. Proper names/titles/artists should often remain native/original; generic activities/genres should be localized deliberately.

Do not start Group Zync / Communities / Host mode yet unless explicitly reprioritized. Keep physical QA + core icebreaking first.

## Safety / release state

- Production: CLOSED
- Google Play: CLOSED
- branch auto-deploy: DISABLED
- QA package remains separate from Production

Do not promote Production or upload Play without explicit user instruction.

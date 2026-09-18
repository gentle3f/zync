# Zync V1 — Zync Session QA Ready Mini Handoff

Date: 2026-09-18 HKT  
Branch: `zync-v1-rebuild-20260917`

This handoff is additive. Preserve all earlier handoffs, especially:

- `AI_STATE/MINI_HANDOFF_20260918_QA_APK_READY.md`
- `AI_STATE/MINI_HANDOFF_20260918_UPSTASH_PREVIEW_SMOKE_PASS.md`
- `AI_STATE/HANDOFF_20260918_RELAY_PAIRING_RESPONSIVE_CERTIFIED.md`

Also treat these as current canonical product/business sources:

- `docs/ZYNC_BUSINESS_PROPOSAL_AND_VISION.md`
- `docs/ZYNC_V1_PRODUCT_SPEC.md`
- `docs/REAL_DEVICE_QA.md`

Do not restart repository discovery or old Thunkable archaeology.

## Product direction now frozen for post-scan V1

The post-scan product is no longer a match report followed by a separate conversation screen.

Canonical rhythm:

```text
Scan
→ YOU ZYNC impact
→ reveal one meaningful connection
→ talk about that connection immediately
→ reveal another when ready
→ recap
```

Core emotional target remains:

> **“Wait — you like that too?”**

V1 still tests whether this two-person hidden-interest discovery moment is strong enough to make people invite another person, Zync again and reuse the app in future real-world social situations.

## Zync Session implementation now present

Current implementation includes:

- one-scan encrypted QR pairing preserved;
- both phones enter the same Zync Session after one scan;
- one meaningful connection is revealed at a time;
- conversation question sits inside the revealed connection rather than behind a separate mandatory Conversation screen;
- Easy / Fun / Debate / Deep / Guess / Surprise are secondary **Change vibe** controls;
- both users' original `Love / Like / Want to try` values are preserved;
- broad true ancestors can collapse into a more specific connection thread;
- sibling interest families must not collapse into one another;
- reveal order uses deterministic shared inputs so both phones stay in the same order;
- local Zync Again history may show a New badge but does not alter reveal order;
- first-ever Zync does not mark every connection as New;
- New applies to the revealed specific connection itself, not merely a newly added folded broad parent;
- haptic feedback is fire-and-forget and cannot block reveal state;
- zero exact match is framed positively and uses a local Interest-Graph crossover before AI;
- recap appears at the end rather than dumping a report up front.

Matching semantics remain exact canonical-ID intersection only. Related-interest, regional relevance, graph relationships and AI never manufacture a false exact match.

## Shared semantic AI question

`api/v1/question.js` now supports a short-lived shared-question cache for one-scan sessions.

Key behavior:

- same session + focused connection + mode + language pair resolves to one semantic question;
- phone language order can be reversed while reusing the same semantic prompt;
- cache key is SHA-256-derived from random session/connection/mode/canonicalized-language context;
- cached value is generated question text, not a permanent profile/history record;
- cache TTL is about 15 minutes;
- Upstash is used as temporary state;
- the cache fails open if unavailable;
- OpenRouter privacy headers/routing remain required.

Privacy, Terms, Play Data Safety and release documentation were updated for this temporary cache.

## Interest system context

The current V1 interest architecture remains the expanded multilingual 3-level catalog/graph system with regional discovery and deterministic local custom interests.

Important current behavior:

- interest search/custom-interest creation is local-first and does not require AI normalization;
- the dormant normalize-interest endpoint can remain for compatibility but is not the shipped interest-entry flow;
- regional discovery uses coarse device-locale region, not GPS or precise location;
- public V1 general analytics remain OFF;
- production-equivalent QA enables regional interest learning;
- regional learning is bounded around curated priors and cannot rapidly overwrite the curated base;
- exact matching remains canonical-ID-only.

## Certified source / CI

Latest fully certified app-source CI before QA workflow bookkeeping:

- GitHub Actions workflow: **Zync V1 CI**
- run: **#266**
- run ID: `35306938497`
- source SHA: `2e24d3a9b80a2644672a41c877477427151a6eb7`
- conclusion: **SUCCESS**

The run passed:

- serverless JavaScript syntax;
- V1 serverless contracts;
- encrypted relay contracts;
- regional interest popularity contracts;
- OpenRouter privacy contracts;
- public release web contracts;
- Play internal-release workflow/signing/publishing guards;
- Android identity requirements;
- localization generation;
- Flutter Analyze;
- Flutter tests;
- unsigned release AAB build/upload.

Unsigned AAB artifact from #266:

- artifact ID: `10532775035`
- name: `zync-v1-unsigned-aab`
- size: `61,833,439` bytes
- artifact digest: `sha256:310fa4d3ddf0956375cfb927d60edbb06064b77e85c16dfb60b925ebc2426180`
- expires: 2026-10-02

Do not treat this unsigned AAB as a Play release artifact.

## Controlled Preview

Current controlled Preview deployment:

- deployment ID: `dpl_25sAA1ajgq4GbFVti2GjFrnxMEQo`
- URL: `https://zync-j62yicn1y-gens-projects-4f99f8b9.vercel.app`
- state: **READY**
- deployment Git SHA: `33047f44c01aa62ab811a76020608832dfac5e1d`
- branch alias remains the Zync rebuild branch alias.
- Production/stable deployment was not promoted or changed.

The preview includes the current backend behavior needed by the QA app, including encrypted relay, regional-interest endpoint and shared semantic-question cache.

## Live Preview smoke

A one-shot live smoke workflow was created, run and removed.

Run:

- workflow: `Zync Preview Session Smoke`
- run ID: `35306639486`
- conclusion: **SUCCESS**

It verified against the real controlled Preview:

- public privacy page;
- encrypted relay create/retry/wrong-token/take/respond/duplicate/consume/delete lifecycle;
- abandoned relay TTL expiry;
- regional-interest completed-week endpoint;
- privacy-hardened AI question generation;
- reversed bilingual phone order using the same one-scan session/connection/mode;
- second reversed-language request was a shared-question cache hit and returned the same semantic question with primary/secondary languages swapped.

Synthetic test data only was used.

The one-shot smoke workflow was removed after success.

## Final Zync QA APK

A new production-equivalent separate-install QA APK was built successfully.

Workflow:

- workflow: `Zync Preview QA APK`
- run: **#3**
- run ID: `35307257300`
- job ID: `105481878931`
- workflow head: `ad52538b9ce40c1a040b564f8358bf8f7656b878`
- conclusion: **SUCCESS**

Artifact:

- artifact ID: `10532765394`
- name: `zync-session-preview-qa-apk`
- compressed artifact size: `85,490,063` bytes
- artifact digest: `sha256:e1251abe42b561f28718920434314d9b28989514694ba0320bb37b2e05c53b9c`
- expires: 2026-09-25

Artifact ZIP contains `app-debug.apk`.

APK:

- APK size: `174,285,960` bytes
- APK SHA-256: `4705e690780355660fce3d941b73c0d7c5e4609c1fe81185dc370314d72521cb`

QA build properties:

- label: **Zync QA**
- package: `com.gmail.gentle3f.myproject.qa`
- can coexist with production/legacy package;
- API base: `https://zync-j62yicn1y-gens-projects-4f99f8b9.vercel.app`
- Privacy URL points to the same Preview;
- `ZYNC_ANALYTICS_ENABLED=false`;
- `ZYNC_INTEREST_LEARNING_ENABLED=true`;
- debug-only controlled QA artifact;
- **never upload this QA APK to Play**.

The one-shot QA workflow was removed after successful artifact upload.

The older QA APK/artifact from `MINI_HANDOFF_20260918_QA_APK_READY.md` is now obsolete for product QA because it predates the expanded interest system and unified Zync Session.

## Protection state

Current branch head after one-shot workflow removal:

- `1b1e09e20af0c69e80ae7460be056dd29f063b0a` at time of this handoff draft/update sequence.

`vercel.json` was rechecked after deployment and QA work:

- `deploymentEnabled.zync-v1-rebuild-20260917 = false`

Do not silently enable branch auto-deploy.

Do not promote Preview to Production and do not upload to Play without explicit user direction.

Preview Vercel Authentication remains intentionally OFF only for controlled physical QA. After physical QA is complete, restore the intended Preview protection posture.

## Immediate active task

The active task is now **physical Android QA of the new Zync Session**, not additional architecture discovery.

Use the final QA APK above.

Recommended first two-device gate:

1. Install **Zync QA** on two Android phones.
2. Create distinct profiles with several shared specific interests plus unique interests.
3. Include at least one broad/specific hierarchy example if practical.
4. Device A: **Show my QR** and wait.
5. Device B: scan A exactly once.
6. PASS only if B enters the Zync Session and A automatically enters without touching A.
7. Confirm both show the same hidden-connection count and reveal order.
8. Reveal the first connection and confirm it feels like a single meaningful discovery rather than a report.
9. Confirm strength contrast is correct on each phone.
10. Confirm the same semantic AI question appears on both phones; a useful bilingual test is Traditional Chinese + Japanese.
11. Confirm Change vibe remains secondary.
12. Continue through Reveal another and recap.
13. Test zero exact match separately and confirm it becomes a positive crossover rather than a failure state.
14. Repeat with the same peer to test Zync Again New badge semantics.
15. Check background/resume while A waits, QR expiry/regeneration and duplicate scan behavior.

Use `docs/REAL_DEVICE_QA.md` as the authoritative physical QA checklist.

After physical QA, record results in a new additive handoff. Only after critical physical QA passes should production signing / Play internal-test work continue.

## Strategic reminder

Do not regress to:

- mandatory AI normalization during interest entry;
- flat tiny interest lists;
- a match-report-first post-scan experience;
- revealing all matches before conversation can start;
- random activity matching;
- accounts/Firebase/social-network infrastructure before the two-person loop proves itself.

The purpose of V1 remains to validate whether Zync can reliably create the real-world emotional moment:

> **“Wait — you like that too?”**

and turn it into an actual conversation.

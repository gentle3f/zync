# Zync V1 — Physical QA Gate Confirmed

Date: 2026-09-18 HKT  
Branch: `zync-v1-rebuild-20260917`

This is an additive mini-handoff. The authoritative product/implementation handoff remains:

`AI_STATE/HANDOFF_20260918_ICEBREAKING_SOCIAL_AI_LIVE_QA_READY.md`

## What was re-verified before physical QA

1. **No implementation drift after the QA APK build**
   - Compared QA source head `6209f04dad24a87f72e5f93ca719f38327ec9748` to the current branch.
   - The branch is only 2 commits ahead.
   - The only changed files are:
     - `AI_STATE/HANDOFF_20260918_ICEBREAKING_SOCIAL_AI_LIVE_QA_READY.md`
     - `AI_STATE/LATEST_HANDOFF.md`
   - No mobile, backend, workflow, privacy, relay, AI, taxonomy or social-exchange implementation changed after the QA build source.

2. **Branch auto-deploy remains disabled**
   - Current `vercel.json` still contains:
     ```json
     "deploymentEnabled": {
       "zync-v1-rebuild-20260917": false
     }
     ```
   - Do not enable it during physical QA.

3. **Controlled Preview remains the certified QA backend**
   - Deployment ID: `dpl_Aae42hqrNrL7Fk72B14jVo9gfK3M`
   - URL: `https://zync-86yxy110d-gens-projects-4f99f8b9.vercel.app`
   - State re-checked: **READY**
   - Target: Preview (`target: null`), not Production.
   - Source SHA: `9eb25d003e4745f5add824d117ab575276635358`
   - Recent Vercel deployment history inspected during this audit showed Preview deployments only; no new Production promotion was performed.

4. **QA artifact remains valid**
   - Workflow run: `35358343030`
   - Artifact ID: `10553506719`
   - Name: `zync-qa-preview-ai-live`
   - Expired: **false**
   - Expires: 2026-10-02
   - Artifact ZIP digest:
     `sha256:b4cecf0ae8a83a85cead1b205ea436c9e7d4e161aae8c6eef2863993ab7f6645`

5. **APK independently re-verified**
   - Artifact ZIP was downloaded and inspected.
   - Contained:
     - `Zync-QA-preview.apk`
     - `Zync-QA-preview.sha256.txt`
     - `Zync-QA-preview-build.txt`
   - Independent SHA-256 of the APK bytes:
     `663e8f428e53c90f8e2a6dc367276eeaa9b105c1393e14e5a164715cf3c8f195`
   - This exactly matches the recorded QA hash.

6. **Build metadata independently re-verified**
   - package: `com.gmail.gentle3f.myproject.qa`
   - label: `Zync QA`
   - api_base: certified controlled Preview
   - privacy_url: certified controlled Preview privacy page
   - analytics: `false`
   - interest_learning: `true`
   - qa_debug: `true`
   - source_sha: `6209f04dad24a87f72e5f93ca719f38327ec9748`

## Current gate

There is no engineering reason to rebuild or modify architecture before the next step.

The active gate remains:

> **Physical Android QA of the exact QA APK above on real devices.**

Run the physical checks in Section 19 of the authoritative handoff, in order:

A. Interest picker feel  
B. AI source badge  
C. Longer icebreaker  
D. Funny alias  
E. People history  
F. Social exchange / non-shared leak check  
G. Two-device semantic bilingual consistency

If a physical check fails, record the exact screen/step and then fix only the reproduced defect. Do not start speculative redesign before real-device evidence.

## Release guard

- Production remains closed.
- Play remains closed.
- Do not upload the QA APK to Play.
- Do not promote Vercel Production.
- Do not silently re-enable branch auto-deploy.

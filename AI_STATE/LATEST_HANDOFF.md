# Zync — Latest Handoff

## Mandatory first read

Read and obey `AI_STATE/OPERATING_RULES.md` before any write, commit, push, PR,
CI, Vercel, deployment or external-infrastructure action.

Authoritative continuation checkpoint:

`AI_STATE/HANDOFF_20260923_CARD_ART_SCREEN_STRUCTURAL_REMEDIATION_RESULTS.md`

(previous checkpoint, still useful for remediation design context:
`AI_STATE/HANDOFF_20260923_CARD_ART_SCREEN_STRUCTURAL_REMEDIATION_READY.md`)

Branch:

`card-art-pilot-v1-20260921`

Current state:

> **The 10-card screen structural remediation batch ran (10/10 Standard FLUX, $0.125 actual) and FAILED decisively: 3/10 PASS-or-MINOR against a required 9/10. Despite the compiled global_screen_policy explicitly forbidding front-facing screens in three separate places per prompt, 7 of 10 cards still rendered a readable code editor, waveform panel, or game-HUD-like screen - 4 of 5 tech_workspace cards (robotics, generative_ai, machine_learning, javascript) FAILED on unmistakably readable code, and 3 of 5 cross-hobby cards (vlogging, pc_gaming, game_streaming) FAILED the same way, including arts.vlogging regressing from its prior editing-UI defect straight into a new code-screen defect. Only electronics (MINOR), video_editing (PASS) and digital_marketing (PASS) came out clean. Root cause: this is a much stronger model semantic prior than the earlier professional_world/workshop case - there, swapping the archetype fixed it instantly; here the archetype WAS swapped with explicit repeated no-screen instructions and the model still overrode them. Do not patch with more negative wording - two rounds of that have each been defeated by a new manifestation of the same prior (title text -> editing UI -> code/IDE UI). Separately, gaming.game_streaming also shows an unrelated one-off light rounded card-border/chrome defect. Letterbox tooling was found to have a real calibration bug: diagnose-letterbox-v1 classifies on darkness alone with no flatness/variance check, producing both a false negative (post-repair coworking's genuine flat ~luma-60 band was invisible to it) and a false positive (post-repair mock_trial's real but organic dark shadow content was misflagged) in Step 1, and 5 more false positives in this batch's new image_diagnostics (all verified via direct pixel-variance sampling, not just tool output). Corrected ground truth: genuine letterbox recurrence stands at 2 confirmed cases across the whole project (confirmatory_30 mock_trial, post-repair coworking), both consistent with upstream/model-generated output since generateCompiledBatch.js does no local resize/crop/pad. Recommended next steps (not executed): isolated 2-3 card retest of a harder "zero monitors permitted" constraint and/or a Klein-negative_prompt approach on one tech card before touching the other four; recalibrate the diagnostic tool's dark-band detection to use variance rather than darkness; second-observation retest of game_streaming's card-border. sports.american_football remains quarantined and untouched. No 50/100 batch started. Keep Vercel, GitHub Actions, Production and Play closed.**

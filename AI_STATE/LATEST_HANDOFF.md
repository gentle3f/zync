# Zync — Latest Handoff

## Mandatory first read

Read and obey `AI_STATE/OPERATING_RULES.md` before any write, commit, push, PR,
CI, Vercel, deployment or external-infrastructure action.

Authoritative continuation checkpoint:

`AI_STATE/HANDOFF_20260923_CARD_ART_SCREEN_MODEL_DISCRIMINATOR_RESULTS.md`

(previous checkpoint, still useful for experiment design context:
`AI_STATE/HANDOFF_20260923_CARD_ART_SCREEN_MODEL_DISCRIMINATOR_READY.md`)

Branch:

`card-art-pilot-v1-20260921`

Current state:

> **The 3-call screen model discriminator ran (2 Standard + 1 Klein, $0.0364 actual). Key finding: technology.robotics' screen/code prior survives even a scene description that excludes every screen-bearing object by name three times - Standard FLUX still invented a readable code monitor in a setting with no desk/workstation at all. Klein, on the identical prompt, produced a genuinely screen-free image but with severe photoreal/macro-product-photography style drift (off house-style), so neither route is currently production-safe for Robotics - this is treated strictly as evidence, not generalized to any other tech hobby. Separately, gaming.game_streaming's screenless_broadcast/camera_gamepad_performance scene is a genuine win: fully screen-free, clearly recognizable via camera+mic+headphones+controller+lighting+performance, and the prior one-off rounded card-border defect did NOT recur (still just 1 observation, not a confirmed pattern). Letterbox detector v2 (flatness-based) was validated against all 4 historical images plus the new renders: it correctly matches direct visual/pixel evidence throughout, including correctly flagging confirmatory_30 coworking as a genuine flat white-margin band that had previously been mislabeled clean under the old darkness-only assumption. One new interpretive nuance: v2 flagged game_streaming's plain studio backdrop as a flat band, which pixel sampling confirmed is smooth/gradient (not a seamed pad) and is literally the recipe's own requested "plain wall background" content, not a defect - visual/prompt-context judgment remains necessary, automated flagging alone is insufficient. Recommended next steps (not executed): isolated single-call Klein retest on Robotics with explicit style-anchoring language to see if photoreal drift can be corrected while keeping the screen-free win; single isolated retest of the screenless_broadcast approach on gaming.pc_gaming (the worst screen-soup offender from the 10-card batch) before any broader rollout; technology.robotics excluded from any batch until a route passes both content and style gates. sports.american_football remains quarantined and untouched. No 10/50/100 batch started. Keep Vercel, GitHub Actions, Production and Play closed.**

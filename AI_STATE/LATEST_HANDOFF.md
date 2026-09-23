# Zync — Latest Handoff

## Mandatory first read

Read and obey `AI_STATE/OPERATING_RULES.md` before any write, commit, push, PR,
CI, Vercel, deployment or external-infrastructure action.

Authoritative continuation checkpoint:

`AI_STATE/HANDOFF_20260923_CARD_ART_MODEL_AB_RESULTS.md`

(previous checkpoint, still useful for A/B setup context:
`AI_STATE/HANDOFF_20260923_CARD_ART_MODEL_AB_READY.md`)

Branch:

`card-art-pilot-v1-20260921`

Current state:

> **The Game Nights/Streetwear model A/B is done (4/4 API calls, $0.101). Klein 9B Base + a real API negative_prompt (`kleinNegative`) passes BOTH cards cleanly — no caption, no text, no branded shoe silhouette. Gemini text-to-image (`geminiText`) passes Streetwear but FAILS Game Nights on a new defect: it rendered the literal word "Zync" (from the shared GLOBAL STYLE prompt text used on every card) as a visible logo wordmark. This is a systemic risk for Gemini on any hobby, not a one-off. Decision: Klein + negative_prompt is the recommended route for suppression-sensitive cards (group_play/social-scene archetypes prone to captions; fashion/footwear-heavy archetypes prone to brand silhouettes); standard reference-free `flux-2` remains the default for ordinary cards; do not use Gemini text-to-image as the sensitive-card route unless the "Zync" mention in global_style_v1.json's prompt is first removed and re-validated. All 4 originally-blocking cards (crafts.diy, technology.ai, lifestyle.game_nights, fashion.streetwear) now have a passing generation path. The ~48-card stratified validation batch can proceed next, routing group_play and footwear-heavy/urban_discovery cards through kleinNegative by default and everything else through standard flux-2. Keep Vercel, GitHub Actions, Production and Play closed.**

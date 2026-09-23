# Zync — Latest Handoff

## Mandatory first read

Read and obey `AI_STATE/OPERATING_RULES.md` before any write, commit, push, PR,
CI, Vercel, deployment or external-infrastructure action.

Authoritative continuation checkpoint:

`AI_STATE/HANDOFF_20260923_CARD_ART_CONFIRMATORY_30_RESULTS.md`

(previous checkpoint, still useful for batch design context:
`AI_STATE/HANDOFF_20260923_CARD_ART_CONFIRMATORY_30_READY.md`)

Branch:

`card-art-pilot-v1-20260921`

Current state:

> **The 30-card confirmatory batch ran (30/30 Standard FLUX, $0.375 actual). NONE of the three decision gates fully passed - do not scale to 50/100. Two real wins confirmed durable: the professional_world workshop/jewelry/apprentice prior is eliminated (0/9 recurrence across a wider sample including a repeat coworking control), and global title/caption suppression holds perfectly (0/30 regressions, now 4 rounds and 63 cards clean). But a genuine NEW systemic pattern was found: real-world sportswear trademark leakage (Nike swoosh, Adidas-style three-stripe, brand-like prints) concentrated in the solo_action archetype for athletic-uniform/equipment sports - 3 of the batch's 4 solo_action sports cards affected (sports.american_football FAIL, sports.fencing FAIL, sports.archery MINOR; only sports.football/soccer, which already has a plain-kit rule, came out clean). Root cause identified precisely: the existing team-sports plain-kit profile_rule doesn't cover individual-equipment sports like archery/fencing, and separately sports.american_football (which IS covered by that rule) passed clean on Klein before but fails on Standard FLUX with identical prompt content - a genuine Standard FLUX limitation, not a missing instruction. Group B (Standard-FLUX migration from Klein) hit 3/4, not the required 4/4: ethnic-signage food (yum_cha, food_markets) and football/soccer are now confirmed Standard-safe, but American Football is not and should stay on Klein. Group A (structural generalisation) hit 6/9, not 8/9: 2 cards show a likely-random letterbox/card-chrome defect (identical archetype sibling cards came out clean), and 1 (arts.vlogging) shows an isolated on-screen text leak of its own hobby name. Group C (fresh discovery) numerically cleared 70% (76.5%) but is disqualified by the concentrated solo_action pattern shared with Group B, per the task's explicit instruction not to wave through a concentrated archetype failure. tech_workspace on-screen readable text/code also recurred (technology.robotics), now a confirmed long-standing pattern across 5 independent hobbies over multiple rounds. Recommended next steps (not executed): extend the plain-kit rule to archery/fencing and retest; keep American Football on Klein rather than retiring it to Standard; diagnostic reroll of the 2 letterbox cards to confirm randomness; small isolated fixes for arts.vlogging/learning.book_clubs/transport.aviation; defer tech_workspace to its own dedicated structural remediation pass. Keep Vercel, GitHub Actions, Production and Play closed.**

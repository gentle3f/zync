# Zync Product Completion Audit — 2026-09-21

Branch: `zync-v1-rebuild-20260917`

Status: **product completion worklist; Production / Play remain CLOSED**

The repository contains many certified engines, backend contracts and internal proof labs, but the installed QA app still feels incomplete because several engines are not yet connected into one player-facing product. The next phase therefore prioritises **a complete Android V1 experience and production-quality UI/UX before iOS/Apple expansion**.

## Completion map

| Area | Current state | Main gap |
| --- | --- | --- |
| 1:1 Zync | real reveal/conversation flow + polished staged reveal UI | deeper interaction/game variety, final pacing QA |
| Onboarding | functional 5-interest start | motivation/progressive profiling/search polish |
| Interest catalog | large canonical catalog + localisation gate | continuing taxonomy/quality audit; card metadata coverage |
| AI Interaction | structured foundation | more tactile Guess/Pick/Rank/Reveal mechanics |
| Zync Now | real group-capable flow + polished host/participant decision moments | candidate quality, recovery and physical group QA |
| Group Zync | live room flow + polished lobby/reveal surfaces on host and participant | more game variety, recovery and physical QA |
| Curiosity Board | daily/weekly/lifetime tasks + real Claim UX and claimed-state sync | physical reward-loop QA and balancing |
| Achievements | 40+ achievements across 4 families; secret requirements hidden until unlock | celebration/motion polish and balance tuning |
| Cardverse account | real Google staging login + product-facing Zync Account UX | stable QA signing + repeat-login/restore QA |
| Cloud ownership | Neon/Postgres + ledger + inventory | bind live inventory into mobile product |
| Pack rewards | real backend grant/open contracts | mobile claim/open API integration |
| Pack reveal | real player-mode reveal; Lab diagnostics hidden; finish-aware haptics | physical QA + final sound/art polish |
| Collection | live cloud inventory renders in My Zync World and connects cards to Want to Try | restore QA + richer binder/filter presentation |
| Draw Tokens | Daily Check-in grants 1 Draw; 1 Token redeems one server-authoritative card | physical QA + economy/anti-abuse tuning |
| Card graphics | 50-card review lab + broader palette diversity + procedural scene grammar | human art-direction review before scaling beyond proof batch |
| My Zync World | unified daily destination for Daily Draw, packs, collection, trophies, tasks and Want to Try | recent-activity/memory layer + final polish |
| Trading | contracts only | later after ownership is proven |
| Guest Zync | not implemented | later growth milestone |
| Communities/places/brands | deliberately later | not required for first complete V1 |
| iOS | Flutter logic reusable | iOS shell, Apple login, signing/TestFlight CI later |
| Release | Android pipeline exists | stable signing, regression, accessibility/performance/store readiness |

## P0 — finish the actual Android product

Target real player loop:

```
real Zync / Tried Together
→ Curiosity quest completes
→ Claim
→ server validates
→ Draw Token or unopened Pack
→ Open Pack
→ server commits result
→ reveal 5 cards
→ cards appear in My Zync World
→ logout/login restores the same collection
```

Exit gate: this works on a physical Android device without entering an internal Lab screen.

## P1 — UI/UX and graphics

1. Simplify Home hierarchy: primary real-world Zync actions first, progress/world second.
2. One stable My Zync World destination instead of trophy/quest/card islands.
3. Product-quality empty/loading/error states.
4. Purposeful motion with Reduce Motion support.
5. Optional haptics/sound for reveals and milestones.
6. Human art-direction review of the 50-card proof batch before scaling.
7. Responsive Traditional Chinese typography and small-phone layouts.
8. Accessibility: contrast, semantics, tap targets, screen readers.
9. Remove Lab/debug language from player mode.
10. Teach features only when they become useful.

## P2 — reliability/release

- stable QA/release Android signing identity;
- restore on a second Android device;
- session expiry/logout/logout-all;
- account lifecycle/deletion QA;
- replay/idempotency QA;
- interrupted pack reveal retry/resume;
- performance/crash/privacy review;
- Production/Play release gates.

## P3 — iOS after Android product coherence

Reuse Flutter code, then add the iOS wrapper, Sign in with Apple, Apple account linking, GitHub macOS build/sign/upload workflow and TestFlight QA. A personal Mac is not required.

## Explicitly later

Guest Zync, trading UI, communities, place/restaurant data, brand integrations and any marketplace/cash economy do not block the first complete product.

## Active implementation order

1. Finish/observe current CI for the latest UI/graphics pass.
2. Controlled Preview deployment of the current reward/draw backend.
3. Verify Preview-only dependencies and enable only required gates.
4. Physical Android smoke:
   - Google/Zync Account;
   - Daily Check-in → Draw Token → single-card draw;
   - Daily/Weekly/Lifetime Quest Claim;
   - unopened pack → 5-card reveal;
   - My Zync World restore after logout/login.
5. Human review of the expanded 50-card Visual Lab; refine weak category/family identities before scaling.
6. Continue interaction/gameplay polish where physical QA exposes friction.
7. Establish permanent Android QA signing.
8. Final accessibility/performance/store-readiness pass.
9. Only then start iOS / Sign in with Apple / TestFlight.

### UI/UX polish progress completed on 2026-09-21

- Home has a stronger branded hero and clearer hierarchy; My Zync World is the featured progression destination.
- Shared design primitives now include gradient hero panels, section headings, metric pills and status pills.
- My Zync World now prioritises Daily Draw, today's progress, packs and collection.
- Quest Board has Today / This Week / Lifetime summary metrics.
- Achievements use collectible family presentation and deliberate secret-achievement styling.
- Zync Account is player-facing and removes token/debug language.
- Pack opening hides receipt/server-roll diagnostics in player mode while preserving Lab diagnostics.
- 1:1 Zync staged reveal, Group Zync host/participant reveal, and Zync Now host/participant decision moments now share the same polished visual language and restrained haptics.
- Cardverse Visual Lab now exposes the expanded 50-card review batch instead of only the original 12-card proof set.
- Card palettes were broadened across major categories to reduce same-category visual sameness.
- Small-phone Home overflow regressions introduced during polish were fixed and re-certified.

Production and Play remain closed.

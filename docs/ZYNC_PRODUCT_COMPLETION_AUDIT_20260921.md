# Zync Product Completion Audit — 2026-09-21

Branch: `zync-v1-rebuild-20260917`

Status: **product completion worklist; Production / Play remain CLOSED**

The repository contains many certified engines, backend contracts and internal proof labs, but the installed QA app still feels incomplete because several engines are not yet connected into one player-facing product. The next phase therefore prioritises **a complete Android V1 experience and production-quality UI/UX before iOS/Apple expansion**.

## Completion map

| Area | Current state | Main gap |
| --- | --- | --- |
| 1:1 Zync | real baseline works | richer interaction mechanics, pacing, final polish |
| Onboarding | functional 5-interest start | motivation/progressive profiling/search polish |
| Interest catalog | large canonical catalog + localisation gate | continuing taxonomy/quality audit; card metadata coverage |
| AI Interaction | structured foundation | more tactile Guess/Pick/Rank/Reveal mechanics |
| Zync Now | real group-capable flow | recommendation/presentation/post-choice polish |
| Group Zync | foundation exists | room UX, game variety, recovery, physical QA |
| Curiosity Board | visible local quest progress | real Claim UX + claimed-state sync |
| Achievements | visible foundation | merge into coherent progression/world surface |
| Cardverse account | real Google staging login works | stable QA signing + product-facing account UX |
| Cloud ownership | Neon/Postgres + ledger + inventory | bind live inventory into mobile product |
| Pack rewards | real backend grant/open contracts | mobile claim/open API integration |
| Pack reveal | strong internal receipt-driven proof | connect to real packs; remove Lab language in product mode |
| Collection | strong 50-card mock Binder proof | render real cloud inventory + restore |
| Draw Tokens | server balance exists | spending rule not frozen; do not invent economy silently |
| Card graphics | procedural system + 50-card proof | art-direction review and production/full coverage |
| My Zync World | concept only | unify cards, packs, trophies, quests, Want to Try, memories |
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

1. Typed live Cardverse inventory/reward/open APIs.
2. Real My Zync World cloud surface.
3. Curiosity Claim UX and claimed-state sync.
4. Unopened pack → real server open → reveal → refreshed collection.
5. Player copy instead of Lab copy.
6. CI + physical Android QA.
7. Broader Home / Interaction / graphics polish.

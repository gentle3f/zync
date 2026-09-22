# Zync — Interest System Ready for Card Art

Date: 2026-09-23
Branch: `card-art-pilot-v1-20260921`

Read `AI_STATE/OPERATING_RULES.md` before any write or external action.

## Interest-system completion state

Runtime canonical interests: **4,053**

Display-label localization:
- en / zh-Hant / zh-Hans / es / fr / pt / ja / ko
- **4,053 / 4,053 complete**
- missing labels: 0
- same-category localized-label collisions: 0

USA + Hong Kong localized search aliases:
- V1 + V2 + V3
- **222 id-locale rows**
- **384 useful localized search terms**
- staged same-category collision audits: 0
- localized aliases are included in the permanent ambiguity hard gate

USA + Hong Kong regional discovery ranking:
- both sectors use the same global catalog with regional boosts
- raw ranking is diversified for broad discovery
- diversified top 12:
  - USA: 8 categories / 12 clusters
  - Hong Kong: 9 categories / 12 clusters
- USA/HK top-12 overlap: 50%, preserving common mainstream interests while
  still giving meaningful regional flavor

## Quick Start audit and final fix

The onboarding screen uses:

`InterestCatalog.quickStart(region: ..., limit: 24)`

Quick Start intentionally shows one representative from every top-level
category before using popularity to fill remaining slots.

Audit found three poor category representatives caused by legacy rank order:
- Crafts -> Knitting
- Collecting -> Model Railways
- Pets -> Dog Parks

Quick Start now uses a tiny curated anchor map **only for those categories**:
- Crafts -> `crafts.diy` (DIY Projects)
- Collecting -> `collecting.lego` (LEGO)
- Pets -> `pets.dogs` (Dogs)

All other category representatives remain region-ranked.

This preserves the 21-world onboarding breadth without changing global search,
popular, related, or general relevance scoring.

Regression tests assert the USA and Hong Kong Quick Start lists use these broad
representatives and no longer surface the three narrow legacy choices.

## Product conclusion

The interest/hobby system is now sufficiently complete for the current launch
phase:

1. catalog breadth is strong at 4,053 canonical interests;
2. USA and Hong Kong are both first-class launch sectors;
3. all 8 supported display-label locales are complete;
4. high-value USA Spanish and Hong Kong search vocabulary is covered;
5. same-category label/alias ambiguity is hard-gated;
6. onboarding is broad and region-aware without category walls.

Do **not** continue adding hobbies or aliases speculatively. Future catalog or
alias work should be driven by real failed-search / selection telemetry.

## Next active task: card image generation

The user explicitly wants to return to image generation now that hobbies are
ready.

Before spending image/API credits:
1. read the existing card-art tooling, prompt schema, cost notes and QA;
2. preserve the existing rights policy;
3. identify the safest representative pilot batch;
4. prefer the lower-cost approved generation path unless quality evidence
   justifies a more expensive model;
5. do not generate trademark/logo/UI/trade-dress-heavy partner art without
   rights clearance.

Infrastructure:
- Vercel remains disabled for this branch.
- GitHub Actions remain closed unless genuinely required.
- Production and Play remain closed.

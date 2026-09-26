# Zync Card FX — True Booster Wrapper Master Complete

Date: 2026-09-26 HKT
Branch: `card-art-pilot-v1-20260921`
Parent before this round: `9c6bef1`

## Scope completed

The fake pack/card-back hybrid has been removed from the Card FX opening Lab.
All four opening prototypes now share one true booster-pack / foil-wrapper master.

The wrapper master has:
- a flexible foil silhouette rather than a rounded card body;
- full-width top and bottom crimp seals;
- dark side seams plus seam highlights;
- subtle wrinkles and moving foil reflections;
- a dedicated angled wrapper label reading ZYNC / ACTIVITY BOOSTER;
- no card-back circle/Z emblem on the unopened wrapper.

The three-pack choice ritual uses the same wrapper master at miniature scale.
The selected wrapper is intentionally larger than the revealed card: its
interaction box is 390x620 with a 1.06 visual scale, while the Lab card remains
constrained to maxWidth 390. The foil body itself now extends to roughly 95% of
wrapper width and 96% of wrapper height.

## Card-back sequencing

The pack painter never draws the real card back. The real Z card back still
lives only in `ZyncFxRevealStage`, reached after the opening gesture commits.
## A/B/C/D visual behavior

- A — Tear Up: the physical top crimp/seal peels away as a separate foil strip;
  the ripped edge is visible before transition to the card back.
- B — Split Open: the same printed wrapper separates from the center into true
  left/right halves. A real-browser defect where each half duplicated label
  text was found and fixed by correcting Canvas transform/clip order.
- C — Charge Burst: hold/charge visuals remain, then the shared wrapper breaks
  into separating foil halves/shards before reveal.
- D — Seal Slide: a physical horizontal foil sleeve/band with chevrons and a
  right-side pull tab slides downward to unlock the wrapper.

The interaction thresholds, controller flow and user gestures were not changed.

## Preserved behavior

- all four prototypes stay available for the user and his wife to compare;
- three moving pack choices remain cosmetic only and cannot change the result;
- all rarity profiles and rarity-specific reveal delays remain unchanged;
- Legendary hidden omen stays deterministic and low-frequency (~1/7);
- Epic near-miss stays rare (~1/20); Rare and below have no omen;
- omen remains post-gesture only;
- Lab-only reduced-motion override remains
  `respectReduceMotion=false` + `AnimationBehavior.preserve`;
- accepted lower-right icon position is unchanged;
- locked 1024x1536 PNG frame masters are unchanged;
- production draw/result/RNG/backend logic is unchanged.

## Real-browser Chrome verification

Final review was run in the existing real Flutter Chrome debug browser after
hot restart, not just in widget tests.

The final A/B/C/D pass confirmed:
- A gesture state shows the torn foil wrapper; post-open state shows card back;
- B gesture state shows two non-duplicated printed wrapper halves; post-open
  state shows card back;
- C hold state shows the charged foil wrapper; release completes opening and
  reaches the preserved card-back reveal;
- D shows the physical sleeve/tab in both locked and dragged positions, then
  reaches the preserved card-back reveal.

Choice-screen review also confirmed the three candidates read as booster packs,
with crimped seals, seams, wrinkles and foil reflections, not as card backs.

## Mechanical QA

- targeted `flutter analyze` across opening/card/reveal/screen/test: PASS,
  No issues found.
- `flutter test test/card_fx_lab_test.dart`: 4/4 PASS.
- `git diff --check`: clean before checkpointing.
- `git diff -- mobile/assets/card_fx/frames`: empty.

## Infrastructure / guardrails

No GitHub Actions, Vercel, deployment, release or paid generation was used.
The current branch remains excluded from Vercel deployment in `vercel.json`.
Do not create a PR or invoke CI merely for this Card FX comparison work.

## Next user decision

Keep A/B/C/D intact. The next decision is for the user and his wife to compare
the four true-wrapper openings and choose which interaction becomes the product
direction. Do not collapse to one mechanic before that choice.

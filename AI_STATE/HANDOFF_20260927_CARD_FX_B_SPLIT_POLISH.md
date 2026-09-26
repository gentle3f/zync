# Zync Card FX — B Split Open Product Polish

Date: 2026-09-27 HKT
Branch: `card-art-pilot-v1-20260921`
Parent before this round: `fdbec3c`

## Product decision

B — Split Open is now the chosen product direction.

A / C / D remain in the Lab only as reference prototypes. This round did not
delete or rework their mechanics, and did not change non-B production logic.

## B split-open physical card reveal

The real `ZyncFxCardBack` now exists behind the wrapper before the opening is
committed. B no longer waits for extraction before creating the card back.

The pre-commit reveal is physical rather than a fade:
- first ~12%: seam / tension only;
- after separation begins: a dark interior cavity opens between the foil halves;
- from ~30% onward: the card back is exposed through a center `ClipRect`;
- the card clip width grows from the actual split/separation width;
- after the existing 70% commit threshold, the same card continues into the
  extraction bridge and then the preserved flip/reveal stage.

The wrapper halves still do the masking. The card is not cross-faded into view.
Real Chrome review at approximately 13%, 42% and 63% pull confirmed:
- early: seam / dark tension only, no premature card reveal;
- mid: partial Z card back visible through the center opening;
- late pre-commit: visibly wider card back while both wrapper halves remain held;
- commit: extraction continues normally into the existing reveal.

## Premium foil material pass

The booster wrapper silhouette and foil-pack identity are unchanged, but the
surface now reads materially more like premium flexible foil:
- stronger silver metallic range and moving directional specular sweep;
- deeper top / bottom crimps using paired ridge highlights and shadows;
- stronger crimp boundary depth;
- darker side-seam channel plus a thin seam highlight;
- embossed wrinkle treatment using offset shadow + highlight pairs;
- extra center-tension crease structure for B;
- printed label remains on the foil surface and now shares the foil specular
  response instead of reading like a flat panel pasted above it;
- split inner edges gain a subtle irregular tear edge with shadow/highlight.

Real Chrome pack-choice and selected-B review showed the crimp ridges, side seams,
directional highlight and tension wrinkles clearly while retaining the distinct
booster-wrapper silhouette.

## Sound-design upgrade
The event architecture remains intact, with one B-specific addition:
`foilTension`.

New/rebuilt 44.1 kHz stereo cues:
- `foil_tension.wav`: irregular foil crinkle / strain during the pull;
- `split_open.wav`: tear texture + hard snap + low-end body + foil tail;
- `card_extract.wav`: air movement + cardstock scrape + tactile release;
- `card_flip.wav`: fast stereo whoosh + physical snap;
- all five rarity-hit WAVs: progressively richer impact/body/shimmer;
- `rarity_legendary.wav`: substantially longer stereo sub/body + bright halo;
- `legendary_finale.wav`: stronger delayed second slam, secondary crown hit and
  longer bright shimmer tail.

B drag now triggers restrained tension texture progressively while pulling,
then the existing split-break -> extraction -> flip -> rarity flow.

Legendary keeps the existing two-stage timing architecture; its primary rarity
hit and delayed finale are now deliberately much heavier than lower rarities.

Objective old -> new checks show, for example:
- split break: 0.32s mono -> 0.54s stereo, low-frequency energy ~7% -> ~42%;
- Legendary hit: 0.70s mono -> 0.96s stereo, RMS ~0.171 -> ~0.268 while also
  adding substantial high-frequency shimmer;
- Legendary finale: 0.46s mono -> 1.18s stereo, RMS ~0.185 -> ~0.271 with a
  long bright tail rather than the previous mostly low-frequency thump.
## Real-browser audio validation

Fresh Flutter Chrome Lab, cache disabled.

Observed unique request order for a complete B Legendary opening:
`pack_pick.wav -> foil_tension.wav -> split_open.wav -> card_extract.wav ->`
`card_flip.wav -> rarity_legendary.wav -> legendary_finale.wav`

Foil-tension requests occurred progressively during the held pull. Browser media
range requests can produce duplicate network entries; they are not duplicate
event calls.

No relevant audio / WAV console errors were observed.

## Mechanical QA

Final QA after the B-specific regression assertion:
- `flutter test test/card_fx_lab_test.dart` -> 4/4 PASS.
- targeted `flutter analyze` across opening/sensory/reveal/card/screen/test ->
  No issues found.
- `git diff --check` -> clean.
- locked frame master directory -> no changes.

The widget regression now explicitly asserts that B owns a pre-extraction card
back + center clip during a partial pull while the extraction card key is still
absent.
## Explicitly unchanged

- draw/result RNG;
- rarity outcome behavior;
- Legendary / Epic hidden-omen frequency and seed logic;
- existing 70% B commit threshold;
- reduced-motion Lab override;
- lower-right icon position / geometry;
- locked 1024x1536 PNG frame masters;
- card-art generation pipeline;
- A / C / D production/reference mechanics;
- backend/server.

No GitHub Actions, Vercel, deployment, release or paid generation was used.

## Continuation

Continue polishing B only. Treat A / C / D as reference unless the user
explicitly reopens them. Preserve the constraints above.

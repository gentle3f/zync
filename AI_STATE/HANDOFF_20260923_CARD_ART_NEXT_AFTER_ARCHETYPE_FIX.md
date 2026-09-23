# Zync — Card Art Continuation Handoff After Archetype-Fix Validation

Date: 2026-09-23
Branch: `card-art-pilot-v1-20260921`
Current HEAD before this handoff: `63f4911ded5b28e5373f4a148ec244638d214333`

## Mandatory first read

Before any write, commit, push, CI, deployment, API call, or external action:

1. `AI_STATE/OPERATING_RULES.md`
2. this handoff
3. `AI_STATE/HANDOFF_20260923_CARD_ART_ARCHETYPE_FIX_RESULTS.md`

Infrastructure guard remains mandatory:
- GitHub Actions closed unless genuinely needed
- Vercel closed
- Production closed
- Google Play closed
- do not expose or commit FAL_KEY
- batch repo writes; avoid micro-commits

At the time of this handoff:
- GitHub Actions for current HEAD: **0**
- Vercel branch deployment: **disabled**

---

## Current product / catalog state

Interest system is still considered launch-ready and frozen for now.

Current canonical catalog context:
- 4,053 interests
- baseline-art eligible: 2,210
- rights-blocked/licensed-only: 1,843
- abstract-only: 7

Do not reopen speculative hobby expansion in the next chat.

The active workstream is **card-art generation quality**, not interest catalog breadth.

---

## Card-art generation architecture

### Rights / prompt pipeline

Use the rights-first structured pipeline under:

`tools/card_art/`

Important files:
- `src/catalogRecipeBridge.js`
- `src/buildPromptV1.js`
- `src/generateCompiledBatch.js`
- `specs/global_style_v1.json`
- `specs/archetypes_v1.json`
- `specs/archetype_variants_v1.json`
- `specs/catalog_recipe_defaults_v1.json`
- `catalog/hobby_overrides_v1.json`

Do NOT use the legacy 15-hobby premium runner for catalog-scale work.

### Model policy currently supported

Standard route:
- `fal-ai/flux-2`
- true reference-free text-to-image
- cheapest ordinary first-pass route

Suppression route:
- `fal-ai/flux-2/klein/9b/base`
- real API `negative_prompt`
- used only where structural suppression has evidence of helping

Gemini text-to-image is NOT the current preferred route.
Earlier testing showed the shared prompt could induce rendered brand text and Gemini's strong text rendering made that failure mode worse.

Nano Banana Pro should remain rescue-only and is not justified for the next step.

### Reference-image lesson already settled

The old Zync full-card mockup reference contaminated FLUX edit outputs with:
- Zync logo
- card chrome
- rarity badges
- card numbers
- copied Board Games composition
- gibberish text

That defect was eliminated by moving normal generation to reference-free text-to-image.

Do not return to the old reference-conditioned first-pass pipeline.

---

## Major compiler defect already fixed and validated

The 48-card validation discovered a structural prompt-format bug:

Examples of old model-facing text:
- `ARCHETYPE (group_play): ...`
- `VISUAL VARIANT (heat_room): ...`
- `VISUAL VARIANT (immersion_ritual): ...`

Models echoed these internal ids into generated art:
- HEAT ROOM
- IMMERSION_RITUAL
- garbled VISUAL VARIANT text

This was fixed in `buildPromptV1.js`:
- old LABEL (identifier): format removed
- raw archetype / visual-variant / subcategory ids removed from model-facing prompt
- prompt rewritten into natural prose
- regression guard added
- reference guidance structurally separated from text-only prompt

The targeted 8-card revalidation confirmed the fix:
- HEAT ROOM leak gone
- IMMERSION_RITUAL leak gone
- raw internal-id leakage gone
- philosophy / hot springs / BookTok cleaned up
- gravel cycling also improved
- escape room design largely improved

Do NOT reopen this compiler-format issue unless a new regression is actually observed.

---

## 100-card scale validation result

Authoritative report:
`AI_STATE/HANDOFF_20260923_CARD_ART_SCALE_100_RESULTS.md`

Generation:
- 100/100 API calls succeeded
- actual spend: $1.222
- 75 standard FLUX
- 25 Klein

Overall:
- PASS: 47%
- MINOR: 11%
- FAIL: 42%

Standard FLUX:
- PASS 50.7%
- FAIL 40.0%

Klein:
- PASS 36.0%
- FAIL 48.0%
- MATERIAL style drift: 52%

Critical conclusion:
**Klein is not a general-purpose “safe hard-card model.”**

Failures correlated strongly with archetype / scene design.

Worst archetypes in the 100-card batch:
- reading_world: 100% FAIL
- food_exploration: 100% FAIL
- tech_workspace: 80% FAIL
- professional_world: 71% FAIL
- travel_vista: 75% FAIL

At that stage:
- uniform/team-sport branding was not solved by Klein negative_prompt alone
- ethnic/signage-heavy food was not solved by Klein negative_prompt alone

This caused the next remediation pass to focus on structural scene design rather than more negative wording.

---

## Archetype / structural fixes already applied

Authoritative setup:
`AI_STATE/HANDOFF_20260923_CARD_ART_ARCHETYPE_FIX_READY.md`

Authoritative results:
`AI_STATE/HANDOFF_20260923_CARD_ART_ARCHETYPE_FIX_RESULTS.md`

A 20-card before/after validation ran:
- 14 standard FLUX
- 6 Klein
- 20/20 API calls
- actual spend $0.243

Same 20 IDs moved from:
- 0% PASS
- 10% MINOR
- 90% FAIL

to:
- 55% PASS
- 5% MINOR
- 40% FAIL

This is a meaningful improvement but not enough for another broad scale batch.

---

## What is now SOLVED or substantially improved

### 1. Ethnic / signage-heavy food — structurally solved

Cards:
- `food.yum_cha`
- `food.food_markets`

Before:
- repeated menu / banner / lantern / pseudo-Chinese text
- negative_prompt-only approaches failed repeatedly

Structural fix:
- close table / kitchen / serving-counter framing
- food, hands, steam, utensils, ingredients carry recognition
- crop venue façade/signage away
- plain text-free background surfaces

Result:
- 2/2 PASS
- Yum Cha is finally clean after multiple earlier failures

This is strong evidence that **structural reframing beats negative suppression** for this class.

### 2. Uniform / team sports — structurally solved in targeted validation

Cards:
- `sports.american_football`
- `sports.football`

Structural fix:
- generic practice/training context
- plain solid unnumbered kit
- no crest / sponsor / swoosh / three-stripe / manufacturer badge
- no stadium advertising / scoreboard
- American Football retains sport-specific ball / helmet / shoulder pads / yard-line constraints

Result:
- 2/2 PASS
- first clean American Football after repeated prior failures

Again, the effective fix was scene redesign, not stronger negative_prompt alone.

### 3. tech_workspace — core code/UI-text problem substantially fixed

Cards tested:
- technology.electronics — PASS
- technology.generative_ai — FAIL only because a new title-caption appeared
- technology.machine_learning — MINOR
- technology.javascript — PASS

Important distinction:
The original `tech_workspace` failure mode — readable code / terminal / UI text — is essentially solved.

Current tech approach:
- physical input/output / device / prototype / gesture carries the concept
- displays optional and subordinate
- displays use abstract geometry, image previews, nodes, unlabeled graphs, waveforms
- no code, terminal windows, menus, labels, dense dashboards

Do not undo this.

### 4. reading_world — text-on-books problem substantially fixed

Cards:
- literary_fiction — PASS
- fiction — PASS
- booktube — FAIL only on recognition, not text

The old book-cover / spine / shelf text defect is solved by:
- plain unbranded books
- blank/abstract covers
- unreadable pages
- no shelf labels / bookstore signs

Remaining BookTube issue:
- still looks like plain reading
- lacks camera / recording / creator cue

So BookTube is now a **recognition problem**, not a text problem.

### 5. Tokyo Travel shows travel_vista can work with strong non-textual anchor

`travel.destination_deep.tokyo_travel` became PASS using Tokyo Tower architecture rather than signage.

This is evidence for the right direction:
destination identity should come from architecture / terrain / skyline / route / transit form, not written place names.

---

## What remains BROKEN / systemic

### A. NEW dominant defect: spontaneous hobby-title caption text

This is now the most important next issue.

Observed after archetype fixes on unrelated archetypes:
- `career.legal_profession` -> "LEGAL PROFESSION"
- `technology.generative_ai` -> "Generative AI"
- `travel.general` -> "Travel" plus a large gibberish paragraph

This is NOT the old raw compiler-id leak.

It is cross-archetype and appears to be a general model tendency to render the hobby's own title as a poster/caption.

Current per-archetype "no text" wording is not sufficient.

### Recommended next repair

Add a **global model-facing constraint**, not per-archetype, explicitly saying:

- never render the hobby/interest name
- never render a title, subtitle, caption, label, heading, poster copy, footer copy, or explanatory text
- the hobby name is semantic context only and must never appear visually
- do not turn the composition into a poster/card/ad layout

This belongs in the shared global prompt / global negatives layer so every archetype gets it consistently.

Do not overstuff per-hobby overrides for this cross-cutting issue.

### B. professional_world recognition for abstract office professions

Still broken:
- `business.coworking`
- `business.marketing`

Problem:
The shared professional_world template still collapses abstract professions into a generic lab/workshop scene.

Evidence:
- `business.startups` now PASS because the concrete prototype scene works
- coworking / marketing remain generic and visually interchangeable

Recommended fix:
Give exact hobby-specific profile rules / subject templates in
`catalog_recipe_defaults_v1.json`.

Suggested visual anchors:

Coworking:
- shared open workspace
- several unrelated professionals at adjacent desks
- laptops / notebooks can be present but screens blank/non-readable
- communal desks, shared seating, casual professional interaction
- scene should read as using a shared workspace, not product prototyping

Marketing:
- person/team actively arranging a physical campaign concept
- product mockup / packaging dummy / blank poster blocks / moodboard with no readable text
- comparing layouts / imagery / color chips
- clear campaign-planning action
- no generic workshop, no jewelry-making / hardware prototyping substitute

Do not try to solve these with the shared professional_world template alone.

### C. travel_vista still unreliable for generic / landmark-poor travel

Current:
- Tokyo Travel PASS
- Japan Travel still leaks readable Japanese signage
- Travel General got WORSE with huge "Travel" title + gibberish paragraph

Interpretation:
- iconic architecture works
- generic travel / country-level travel without one visual landmark still tends to use signage/title text

Next test should not redesign the entire travel_vista family yet.
First fix the new global hobby-title caption issue, then re-test:
- travel.general
- travel.japan

If Japan still fails after global caption fix, it needs a country-specific non-textual anchor strategy.

### D. Klein style drift is still unacceptable

20-card archetype-fix Klein subset:
- 5/6 MATERIAL drift = 83%

Previous 100-card batch:
- 52% MATERIAL

Therefore Klein remains useful for some suppression cases but visually risky.

Do NOT promote Klein to a broad default.

Content/text correctness and style consistency are separate problems.

The next step should NOT attempt to solve Klein style globally yet; first finish the remaining text/recognition blockers.

---

## Next task — smallest correct continuation

Do NOT run another 50/100/200-card batch yet.

The immediate continuation should be:

### Fix 1 — global hobby-title caption suppression

Implement in the shared global prompt / global negatives layer.

Goal:
Prevent the model from rendering:
- hobby name
- title
- subtitle
- caption
- label
- heading
- poster copy
- explanatory text

This must be phrased as global artwork behavior, not tied to one archetype.

### Fix 2 — exact coworking / marketing subject rules

Add exact profile rules for:
- `business.coworking`
- `business.marketing`

Use concrete visual actions/anchors as described above.

### Optional tiny recognition fix

If convenient and low-risk, add a BookTube-specific creator cue:
- person discussing / recording around a blank unbranded book
- visible generic camera / phone-on-tripod / microphone
- no platform UI / logo / text

But this is secondary to the first two fixes.

---

## Next validation size

Use a **small targeted 6–8 card validation**, not another large batch.

Recommended sample:

Global title-caption cases:
- career.legal_profession
- technology.generative_ai
- travel.general

professional_world recognition:
- business.coworking
- business.marketing

travel follow-up:
- travel.japan

optional:
- learning.book_genre.booktube
- one known-clean control card

Use the same existing model route for each card unless there is a specific reason to change it.

Purpose:
1. prove title-caption suppression works across unrelated archetypes
2. prove coworking/marketing now read correctly
3. see whether Japan signage remains after global caption fix
4. optionally verify BookTube recognition

Do not auto-reroll failures.

---

## Decision gate after that small test

Only if:
- global title-caption defect materially drops
- coworking/marketing recognition improves
- no compiler regression appears

Then consider a **50-card confirmatory batch** focused on the now-solid classes:
- ethnic food structural routes
- uniform sports structural routes
- tech_workspace
- reading_world
- plus ordinary standard-FLUX controls

Still exclude unresolved travel/professional classes if they remain broken.

Do not jump to 100+ again until the small validation is clean.

---

## Important historical commits / checkpoints

Prompt-format root-cause fix:
- `bfb0c83de885bbd1942aff67f55dfa1e606acb7d`

Prompt-format validation result:
- `1dc1cb913b5d19483d248f2ab88025e0991d0240`

100-card setup:
- `1a0ff0e7bd0729c6608db5f1d2f142b5f4dbecc6`

100-card results:
- `d7ef30030acbd80b73f970b0bbad071d2671ef64`

Current branch HEAD before this handoff:
- `63f4911ded5b28e5373f4a148ec244638d214333`

Authoritative latest result before this handoff:
- `AI_STATE/HANDOFF_20260923_CARD_ART_ARCHETYPE_FIX_RESULTS.md`

---

## Working style for next chat

- Continue directly from this state.
- Do not restart repo discovery.
- Do not revisit hobby expansion.
- Do not redesign the whole model stack.
- Prefer structural scene fixes over endlessly adding negative words.
- Keep writes batched.
- Check Actions / Vercel before and after any commit.
- No hosted CI unless truly required.
- No deployment.
- No production / Play.
- No secret exposure.
- Do not claim local tests ran unless actually executed.

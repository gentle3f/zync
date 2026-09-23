# Zync — Confirmatory 30: Validation Results

Date: 2026-09-23
Branch: `card-art-pilot-v1-20260921`

Read `AI_STATE/OPERATING_RULES.md` before any write or external action.

## Bottom line

**Do not scale to 50/100.** The core structural fix from the prior round —
the `professional_world` workshop/jewelry/apprentice scene prior — is
**confirmed eliminated (0/9 recurrence)**, and global title/caption
suppression **holds perfectly (0/30 regressions)**. Those are real, durable
wins. But this broader, more diverse sample surfaced a genuine, repeated,
**cross-group systemic pattern**: real-world sportswear trademark leakage
(Nike swoosh, Adidas-style three stripes, small brand-like prints)
concentrated in the `solo_action` archetype for athletic-uniform/equipment
sports — affecting `sports.american_football` (Group B), `sports.fencing`
(Group C, hard FAIL), and `sports.archery` (Group C, MINOR) out of only 4
`solo_action` cards in this batch. None of the three gates fully passed:
Group A hit 6/9 PASS-or-MINOR (needed 8/9), Group B hit 3/4 (needed 4/4),
and Group C's 76.5% numerically cleared 70% but contains the disqualifying
concentrated-archetype failure the task explicitly said not to wave through.

## What ran

```bash
cd tools/card_art
npm run audit-confirmatory-30-v1
npm run generate-confirmatory-30-v1
```

- **Audit:** passed cleanly. 30/30 compiled, all Standard FLUX (zero Klein
  calls), $0.375 est. Verified directly: all four new/confirmed routes
  correct (`business.branding` -> `campaign_planning/mockup_table`,
  `career.digital_marketing` -> `campaign_planning/campaign_wall_table`,
  `learning.mock_trial` and `learning.moot_court` -> `legal_practice/
  student_advocacy`); existing creator routes for `arts.vlogging`,
  `arts.content_creation`, `arts.podcasting`, `arts.online_video_creation`
  all confirmed on `creator_workflow`; global text policy present in all 30
  prompts; zero forbidden compiler headers; zero raw internal ids anywhere;
  30/30 unique rights-safe canonicals (no blocked/branded IDs slipped in,
  confirmed by the audit completing without any refusal errors).
- **Generation:** **30/30 API calls succeeded**, no failures, no automatic
  retries. **Actual cost: $0.375** — matches the estimate exactly.

Manifest: `tools/card_art/output/confirmatory_30_v1/manifest.json`
Images: `tools/card_art/output/confirmatory_30_v1/images/`

All 30 images were individually opened and visually inspected (not judged
from prompts/API success/manifest alone).

## Group A — structural generalisation / stability (9 cards)

| ID | Verdict | Q | Defect | Notes |
|---|---|---|---|---|
| business.branding | MINOR | 5 | text (minor) | Clean mockup-table scene; one small, mostly-illegible brand-like print on a box label |
| career.digital_marketing | **PASS** | 5 | - | Clean campaign wall/mood-board scene, no text |
| learning.mock_trial | **FAIL** | 4.5 (content) | cardchrome | Scene itself is a clean, correct courtroom/student-advocacy tableau, but ~40% of the frame is thick black letterbox bars |
| learning.moot_court | **PASS** | 5 | - | Same archetype/variant as mock_trial, fully clean and correctly framed — confirms the letterboxing above is not archetype-tied |
| arts.vlogging | **FAIL** | 4.5 (content) | text (severe) | Bold, clearly readable "VLOGIN" (garbled "VLOGGING") rendered on-screen as a title, plus a small tag-like "808" |
| arts.content_creation | **PASS** | 5 | - | Clean, no text, camera/tablet setup |
| arts.podcasting | **PASS** | 5 | - | Clean, abstract waveform screen, no readable text |
| arts.online_video_creation | **PASS** | 5 | - | Clean, camera/phone rig, no readable text |
| business.coworking | **FAIL** | 4.5 (content) | cardchrome | Scene is a clean, correct 5-person communal-desk office (the workshop prior did NOT recur), but the same ~35%-of-frame letterbox-border defect as mock_trial appears here too |

**Group A tally: 5 PASS / 1 MINOR / 3 FAIL. 6/9 PASS-or-MINOR — gate (>=8/9) NOT met.**

**Critical positive finding:** the `professional_world` workshop/jewelry/
apprentice scene prior — the reason this whole remediation arc exists —
**did not recur even once (0/9)**, including on its own repeat stability
control (`business.coworking`). Every failure in this group is a *different*,
new defect class (card-chrome letterboxing, one isolated text leak), not a
return of the original problem.

## Group B — Standard-FLUX migration from Klein (4 cards)

| ID | Verdict | Q | Defect | Notes |
|---|---|---|---|---|
| sports.american_football | **FAIL** | 5 | logo/trademark | Correct equipment (helmet, shoulder pads, one brown oval football, yard-line field), no jersey number, no crest — but an unmistakable Nike swoosh is visible on the shorts |
| sports.football | **PASS** | 5 | - | Plain unmarked kit, plain ball, no crest/logo/number |
| food.yum_cha | **PASS** | 5 | - | Close food-sharing moment, zero signage/menus/banners/script |
| food.food_markets | **PASS** | 5 | - | Close food-tasting moment, zero signage/menus/banners/script |

**Group B tally: 3/4 PASS. Gate (4/4 required to retire Klein for this
class as a whole) NOT met.**

Nuance: this is not a uniform failure. **Ethnic/signage-heavy food (2/2)
and plain-kit team sports without a strong real-brand prior (football/soccer,
1/1) are genuinely clean on Standard FLUX.** Only American Football failed,
and specifically on a defect (swoosh) that Klein's real `negative_prompt`
previously suppressed successfully. This points to a **Standard FLUX
limitation** for this specific hobby/archetype combination, not a prompt
content problem — the compiled prompt already explicitly forbids
"swoosh-like mark."

## Group C — fresh stratified discovery (17 cards)

| ID | Verdict | Q | Defect | Notes |
|---|---|---|---|---|
| sports.archery | MINOR | 5 | logo (minor) | Small, mostly-illegible brand-like print on shirt chest |
| sports.fencing | **FAIL** | 5 | logo/trademark | Unmistakable Adidas-style three-stripe mark on the shoes |
| wellness.pilates | **PASS** | 5 | - | Clean, reformer scene |
| wellness.breathwork | **PASS** | 5 | - | Clean, close breathing moment |
| outdoors.birdwatching | **PASS** | 5 | - | Clean; one ambiguous background prop (possible fishing rod), not a hard defect |
| outdoors.skiing | **PASS** | 5 | - | Clean, correct gear |
| music.guitar | **PASS** | 5 | - | Clean, live acoustic performance |
| music.vinyl | **PASS** | 5 | - | Clean, turntable focus |
| food.pizza | **PASS** | 5 | - | Clean, appetizing |
| food.tea | **PASS** | 5 | - | Clean, appetizing ritual |
| arts.watercolor | **PASS** | 5 | - | Clean, studio scene |
| arts.ceramics | **PASS** | 5 | - | Clean, wheel-throwing scene |
| crafts.woodworking | **PASS** | 5 | - | Clean, correct tools |
| technology.robotics | **FAIL** | 5 | text | Legible code-like text blocks visible on the monitor |
| science.chemistry | **PASS** | 5 | - | Clean, lab/field scene |
| learning.book_clubs | **FAIL** | 5 | recognition | Shows one person reading alone — no social/group cue for a "club" concept |
| transport.aviation | **FAIL** | 5 | recognition | An unrelated vintage car dominates the foreground; the aircraft is present and identifiable but visually secondary |

**Group C tally: 12 PASS / 1 MINOR / 4 FAIL = 13/17 (76.5%) PASS-or-MINOR —
numerically clears the 70% target.**

**However, per the task's explicit instruction not to wave through a
concentrated archetype failure even at an acceptable overall percentage:**
`sports.fencing` (FAIL) and `sports.archery` (MINOR) are both `solo_action`
archetype cards showing the same defect class (real-world sportswear brand
marks) as `sports.american_football` in Group B. **3 of the batch's 4
`solo_action` athletic-sport cards show some form of brand-mark leakage.**
This is exactly the kind of concentrated, repeated pattern the gate exists to
catch, and it disqualifies a clean pass for Group C despite the percentage.

## Root-cause analysis (by category, not per-card)

### 1. Archetype/variant semantic prior — the primary finding this round

**`solo_action` + athletic-uniform/equipment sports -> real-world sportswear
brand-mark leakage.** Evidence: 3 of 4 solo_action sports cards in this
batch (american_football, fencing, archery) show a swoosh, three-stripe
mark, or brand-like print; only football/soccer (which already has an
explicit plain-kit exact-ID rule) came out clean. **Root cause identified
precisely:** the existing team-sports plain-kit `profile_rule` in
`catalog_recipe_defaults_v1.json` only covers `sports.american_football,
football, basketball, volleyball, baseball, rugby, cricket, field_hockey,
lacrosse` — it does **not** include individual-equipment sports like
archery or fencing, which fall back to the generic `sports` category
default (which only says "brand logos or readable sponsor text" in its
avoid list, with no plain-kit structural requirement). Separately,
`sports.american_football` **is** covered by that plain-kit rule and still
leaked a swoosh — but only on Standard FLUX; it passed clean on Klein in
the prior round with the identical rule. That is a **Standard FLUX
limitation** specifically, layered on top of the recipe-coverage gap.

**`tech_workspace` -> on-screen readable text/code.** `technology.robotics`
joins `technology.electronics`, `technology.generative_ai`,
`technology.machine_learning`, and `technology.javascript` from earlier
rounds as another `tech_workspace` card showing legible on-screen text
despite explicit "no code, no terminal, no UI labels" archetype language.
This is now a long-standing, only-partially-mitigated pattern across five
independent hobbies over multiple rounds — more persistent than a one-off,
not yet resolved by incremental negative wording.

### 2. Hobby-specific recipe defect

- `arts.vlogging`: the only 1 of 4 `creator_workflow` cards in this batch
  to render on-screen text (a garbled version of its own hobby name); the
  other three (content_creation, podcasting, online_video_creation) were
  clean. Isolated to this one hobby's recipe, not the archetype.
- `learning.book_clubs`: missing an explicit "multiple people/social
  exchange" requirement in its subject text — the shared `reading_world`
  archetype otherwise reads correctly for solitary reading (as proven by
  clean results elsewhere), but "clubs" specifically needs a group cue this
  recipe doesn't currently require.
- `transport.aviation`: the shared `journey_machine/owner_machine`
  archetype/variant (reused from cars) doesn't anchor "aircraft as the
  unmistakable hero object" strongly enough against what appears to be a
  vehicle-class-agnostic template.

### 3. Random one-off generation defect

- The letterbox/card-chrome borders on `learning.mock_trial` and
  `business.coworking` hit two structurally unrelated archetypes
  (`legal_practice` and `shared_workspace`), and `mock_trial`'s own sibling
  card `moot_court` (identical archetype/variant) came out perfectly framed.
  This pattern (present in 2/30 = 6.7% of cards, cutting across unrelated
  archetypes) looks like FLUX-level aspect-ratio/padding noise rather than a
  systemic prompt or archetype issue — but has not yet been confirmed via a
  reroll, so this remains a hypothesis, not a closed finding.

### 4. Global text/layout regression

**None found.** Title/caption suppression held perfectly across all 30
cards (0 regressions) — this specific fix from two rounds ago is now
validated stable across 4 rounds and 63 total cards without a single
recurrence.

### 5. Standard FLUX limitation

Confirmed for `sports.american_football`'s swoosh (see above — identical
prompt content passed clean on Klein, failed on Standard). This is direct
evidence that Klein's real `negative_prompt` mechanism has stronger brand-
mark suppression than Standard FLUX's inline-only negatives, at least for
this specific hobby/archetype.

### 6. Rights/IP problem

Three confirmed or likely trademark leaks this round, all within the
`solo_action` athletic-sports cluster: `sports.american_football` (Nike
swoosh), `sports.fencing` (Adidas-style three stripes), `sports.archery`
(smaller, less certain brand-like print). These are real rights-safety
issues, not just aesthetic ones, and block any of these three hobbies from
being considered production-ready as currently routed.

## Decision gates — none fully passed

- **Group A (structural generalisation):** 6/9 PASS-or-MINOR, gate required
  >=8/9. **Not met** — but the specific regression the gate exists to catch
  (workshop/jewelry/apprentice recurrence) is definitively absent (0/9).
  Failures are new, different, and each individually diagnosable (see
  above).
- **Group B (Standard-FLUX migration):** 3/4 PASS, gate required 4/4 to
  retire Klein for "these four classes." **Not met as a bundled set** — but
  cleanly met on a per-class basis for ethnic/signage food (2/2) and for
  football/soccer specifically (1/1); not met only for American Football.
- **Group C (fresh discovery):** 76.5% PASS-or-MINOR numerically clears
  70%, but the concentrated `solo_action` athletic-sports brand-leak pattern
  (shared with Group B) means this **does not count as a clean pass** per
  the task's explicit instruction.

## What is now considered production-safe

- **Global title/caption suppression** — validated stable across 4 rounds,
  63 cards, 0 regressions. No further validation needed for this fix
  specifically.
- **`professional_world` -> `shared_workspace` / `campaign_planning` /
  `legal_practice` / `creator_workflow` structural routing** — the original
  workshop/jewelry/apprentice prior is confirmed eliminated across a wider,
  more diverse sample (9 cards, including a repeat stability control). This
  routing is production-safe *for the scene-prior problem specifically*;
  the newly-found letterbox and isolated text/recognition issues in this
  group are separate, smaller-scope defects (see below), not a reason to
  distrust the archetype routing itself.
- **Ethnic/signage-heavy food (`food_exploration`) on Standard FLUX** —
  clean 2/2 this round on top of prior Klein successes; Klein can likely be
  retired for this class, pending one more confirmatory sample given the
  small count.
- **Team sports with an existing plain-kit rule, excluding American
  Football** (i.e. football/soccer, and by extension the untested
  basketball/volleyball/baseball/rugby/cricket/field_hockey/lacrosse
  already covered by the same `profile_rule`) — likely safe on Standard
  FLUX, though only football/soccer was directly re-tested this round.
- Every fresh-discovery category outside sports/tech screens — wellness,
  outdoors (except the aviation vehicle-class mixup), music, food (culinary,
  not the earlier ethnic-signage risk class), arts/crafts, science — came
  back clean with no new systemic issues.

## What still blocks larger-scale generation

1. **`solo_action` athletic-uniform/equipment sports trademark leakage** —
   not solved for archery/fencing (never received the plain-kit structural
   fix) and only Klein-safe, not Standard-safe, for American Football.
2. **`tech_workspace` on-screen readable text/code** — long-standing,
   recurring across 5 independent hobbies over multiple rounds; needs a
   dedicated structural pass of its own, similar in spirit to the
   `professional_world` fix, rather than continued incremental negative
   wording.
3. **Card-chrome letterbox borders** (2/30 this round) — likely random
   FLUX noise, not yet confirmed via reroll.
4. **Isolated hobby-recipe gaps** — `arts.vlogging` (text), `learning.
   book_clubs` (missing group cue), `transport.aviation` (vehicle-class
   confusion) — each a small, independent fix.

## Smallest recommended next steps (not executed this task)

In priority order, cheapest/highest-value first:

1. **Extend the uniform-sports plain-kit `profile_rule`** to cover
   individual-equipment sports with real-world brand associations
   (`sports.archery`, `sports.fencing`, and likely similar cases such as
   golf, skiing apparel, etc.), then re-test just those 2-3 cards.
2. **Keep `sports.american_football` routed to Klein** rather than Standard
   for now (do not fold it into the "retire Klein" set), since Standard
   demonstrably failed on identical prompt content that Klein passed.
3. **Diagnostic reroll** of `learning.mock_trial` and `business.coworking`
   only (2 cards, ~$0.025) to confirm the letterbox defect is non-
   deterministic generation noise rather than something systemic, before
   deciding whether any prompt change is needed at all.
4. **Small hobby-specific fixes**, each independently testable on 1 card:
   `arts.vlogging` (explicit "no on-screen text, including the word
   'vlog'"), `learning.book_clubs` (require multiple people), `transport.
   aviation` (require the aircraft as the unmistakable dominant object,
   explicitly exclude cars as the visual hero).
5. **Defer `tech_workspace`** to its own dedicated remediation pass — it is
   a real, recurring problem but not new information this round, and
   fixing it well likely needs the same kind of structural (not just
   negative-wording) intervention that worked for `professional_world`.

Do not scale to 50 or 100 cards until at least items 1-2 above are
retested and confirmed clean, since they represent the most concentrated,
best-evidenced systemic risk found this round.

## Infrastructure

Vercel deployment confirmed disabled for this branch (unchanged). No GitHub
Actions workflow triggers on push to this branch. This commit/push is a
plain repo write with no CI/deployment side effects. Play/Production remain
untouched and closed. `FAL_KEY` was not committed or exposed. No auto-reroll
was performed.

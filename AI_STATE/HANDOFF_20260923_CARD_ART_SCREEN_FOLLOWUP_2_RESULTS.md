# Zync — Two-Call Screen Follow-up: Results

Date: 2026-09-23
Branch: `card-art-pilot-v1-20260921`
Parent HEAD: `bb41ca07e2e113f0390fbe2e00e5e451cc2277a5`

Read `AI_STATE/OPERATING_RULES.md` before any write or external action.

## Bottom line

**Both calls failed.** Robotics Klein's style anchor did not work — the
output remains strongly photoreal/macro-product-photography despite
explicit hard style-anchoring language and photographic-style negative
exclusions, and also fell short on scene completeness (no open test floor,
no cones). `technology.robotics` has no production-safe baseline route
under either tested Standard or Klein strategy and should be quarantined
until a different model or a radically different visual treatment is
chosen — per the task's own pre-stated conclusion criteria. PC Gaming's
screenless transfer failed even more severely: the render is not
recognizable as PC gaming at all (no desktop tower/keyboard/mouse/
headphones/player), and a background laptop displays clearly readable
code — the exact screen-leak defect this experiment was designed to avoid.
The physical-cue strategy's success is now evidenced only on Game
Streaming, not PC Gaming. A light rounded card-border/chrome defect also
recurred on Robotics Klein, its second independent observation (previously
only `gaming.game_streaming`), promoting it from one-off to a confirmed
recurring pattern. No further generation was run. No broader batch started.

## Step 1 — free dry-run audit

```bash
cd tools/card_art
node src/runScreenFollowup2.js --dry-run
```

Clean. Confirmed directly in the compiled prompt text:

- Exactly 2 planned calls: 1 Klein (Robotics) + 1 Standard (PC Gaming),
  $0.0239 estimated — matches.
- Robotics Klein compiles to `physical_prototype / field_robot_test`,
  carrying the same screen-free content requirements as the prior
  discriminator plus explicit new style-anchor text ("STYLE IS A HARD
  REQUIREMENT: use a premium painterly cinematic illustration with crafted
  brush-like texture... Do not render this as a photograph, macro product
  photograph, DSLR image, stock photo, or photoreal commercial product
  shot"). Negative list includes photograph, photorealistic rendering,
  macro product photography, stock photo, DSLR photo, product photography,
  hyperreal commercial photo — all present, matching spec exactly.
- PC Gaming compiles to `collection_object_hero / hands_build`, explicitly
  cropping the composition "before any monitor area," with a full negative
  list covering monitor/TV/laptop/tablet/phone/projector/display panel/
  game screen/HUD/code/IDE/terminal/waveform/chat/streaming interface, and
  no brand/logo/manufacturer-specific language requested.
- **Production routing unaffected:** direct dry-run invocation without
  `--experiment-overrides` confirmed `technology.robotics` still routes to
  `tech_workspace / creator_interface` and `gaming.pc_gaming` still routes
  to `digital_play / desktop_focus` — the experiment overlay does not
  mutate catalog defaults.
- No forbidden headers, no raw ID leaks (would have thrown and halted the
  audit), no rights-blocked canonical, no American Football involvement.

## Step 2 — generation

```bash
node src/runScreenFollowup2.js
```

2/2 API calls succeeded, no failures, no auto-rerolls. **Actual cost:
$0.0239** — matches estimate exactly. Manifest confirms
`experiment_override_applied: true` on both entries, with distinct
`fal_request_id`s (ruling out any file mix-up before scoring).

Manifest: `tools/card_art/output/screen_followup_2_v1/manifest.json`
Images: `tools/card_art/output/screen_followup_2_v1/images/`

Both images were individually opened and visually inspected. Diagnostics
were cross-checked against direct pixel sampling before being trusted.

## Per-image verdicts

| ID | Model | Verdict | Q | Screen present? | Readable code/UI? | Recognizability | House style | Card border? |
|---|---|---|---|---|---|---|---|---|
| technology.robotics | Klein (style-anchor retest) | **FAIL** | 2 | No | No | Partial — reads as tabletop RC-car/model-kit assembly close-up, not the specified open-test-floor/cones field-test scene | **Still strongly photoreal/macro-product-photography** — style anchor did not work, materially unchanged from the prior attempt | **Yes — thin light rounded border/chrome frame, confirmed via pixel sampling (luma ~250–254, tight range at all edges)** |
| gaming.pc_gaming | Standard FLUX | **FAIL (severe)** | 1 | **Yes — background laptop with clearly readable syntax-highlighted code** | Yes | **No** — hands hold an ornate steampunk-style mechanical gadget; no desktop tower, keyboard, mouse, headphones, or seated player anywhere | Reasonably consistent painterly rendering (moot given the above) | No |

## Letterbox diagnostics

- Robotics: v2 flagged a small band (top 6px, bottom 25px, 2.48%
  combined). Direct pixel sampling confirms this is genuine — both edges
  show tight, near-white flat bands (luma ~250–254, range ~7 units),
  matching the visually confirmed rounded card-border/chrome frame. **This
  is a real defect, not a v2 false positive.**
- PC Gaming: v2 reports no band (0/0/false). No border visible on visual
  inspection either. Consistent.

## Root-cause conclusion

1. **Did Klein keep Robotics screen-free again?** Yes — zero monitors,
   laptops, tablets, or phones anywhere in frame, consistent with the
   prior discriminator result.
2. **Did the stronger style anchor pull Klein back into house style?**
   No. Despite explicit hard style-anchoring language ("STYLE IS A HARD
   REQUIREMENT") and a negative list specifically targeting photograph/
   photorealistic/macro-product-photography/stock-photo/DSLR/hyperreal
   commercial photo, the output remains strongly photoreal/macro-product-
   photography in character — shallow depth of field, warm bokeh,
   commercial-tabletop-product-shot aesthetic. This did not measurably
   improve over the prior (non-anchored) Klein attempt.
3. **Is `technology.robotics` now production-safe, or should it be
   quarantined?** **Quarantine recommended.** Standard leaks a readable
   code screen even in a fully screen-excluded scene; Klein suppresses the
   screen but fails house style and scene completeness. Neither tested
   route clears the bar. Per the task's own pre-stated criteria, this
   result concludes that `technology.robotics` has no production-safe
   baseline route under the tested Standard/Klein strategies and needs a
   different model or a radically different visual treatment — not a
   third prompt iteration.
4. **Did screenless PC Gaming remain unmistakably PC Gaming?** No — it
   failed badly. The render doesn't read as PC gaming, or arguably as any
   coherent hobby concept related to gaming at all.
5. **Does the physical-cue strategy now have successful evidence on both
   Game Streaming and PC Gaming?** No. Only Game Streaming has passed.
   PC Gaming's failure here is compound: it lost recognizability *and*
   reintroduced a screen. The likely cause is not "insufficient wording"
   but an **archetype-selection mismatch** — `collection_object_hero/
   hands_build`'s own generic composition text ("hands actively build or
   arrange one clearly readable collectible/object system; a single hero
   element sits in sharp foreground focus") appears to have dominated the
   model's output over the hobby-specific desktop-tower/keyboard/mouse/
   headphones instructions layered on top of it, producing a generic
   "build a hero collectible gadget in your hands" image instead of a
   gaming scene. This is a routing/archetype-choice problem, not a
   wording-strength problem, and should not be patched with more negative
   text inside the same archetype.
6. **Did either render reveal any new systemic defect?** Yes — the light
   rounded card-border/chrome frame recurred on Robotics Klein. This is
   its second independent observation across two different archetypes
   (`screenless_broadcast/camera_gamepad_performance` on game_streaming,
   `physical_prototype/field_robot_test` on robotics), which is enough to
   treat it as a genuine recurring pattern rather than a one-off, though
   still too sparse (2 observations) to characterize its trigger.

## Smallest recommended next steps (not executed this task)

1. **Quarantine `technology.robotics`** the same way
   `sports.american_football` is quarantined in
   `specs/generation_guardrails_v1.json`, since it has now failed under
   both tested model routes with no remaining small experiment likely to
   resolve it. Not executed this task — recommended for a future task to
   action explicitly.
2. **Do not re-attempt PC Gaming inside `collection_object_hero/
   hands_build`.** If PC Gaming's screenless transfer is retried, use a
   different experiment-only archetype whose own generic composition text
   does not compete with gaming-specific hardware framing — or reinforce
   the hobby override to explicitly override/suppress the archetype's
   generic "collectible object" framing structurally, not just add more
   detail alongside it.
3. Investigate the card-border/chrome defect as its own small, targeted
   question now that it has 2 observations: check whether both occurrences
   share a common trait (e.g., same image dimensions edge case, same
   post-response step, or coincidence) before proposing a fix.
4. `sports.american_football` remains quarantined; untouched this task.
5. No broader batch (10/50/100) recommended or started.

## Infrastructure

Vercel, GitHub Actions, Production, and Google Play remain closed for this
branch. No `FAL_KEY` was exposed or committed. No auto-reroll was
performed. `--allow-quarantined=sports.american_football` was not used.
This commit/push is a plain repo write with no CI/deployment side effects.

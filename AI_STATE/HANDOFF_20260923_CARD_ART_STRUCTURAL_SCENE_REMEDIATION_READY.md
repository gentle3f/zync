# Zync — Structural Scene-Prior Remediation Ready

Date: 2026-09-23
Branch: `card-art-pilot-v1-20260921`
Parent HEAD: `89c85f8cee57bb78efa4b3286dbb7f79f48dddb3`

## Why this repair

The latest 8-card test confirmed the global no-title/no-caption policy works, but `business.coworking`, `business.marketing`, and `career.legal_profession` all collapsed into near-identical jewelry/watchmaking workshop scenes despite detailed, mutually different exact-ID prompt content and explicit exclusions.

That is enough evidence to treat `professional_world` as the active scene-prior blocker. This remediation therefore does **not** spend another diagnostic reroll proving the same point. It structurally routes the affected interests away from `professional_world`.

BookTube is handled similarly: the prior `reading_world + Klein` route ignored the creator cue twice and Klein has repeated MATERIAL style drift. BookTube now uses `creator_workflow + camera_creation` and the next validation routes it through Standard FLUX.

## Structural changes

### business.coworking

Now:
- archetype: `shared_workspace`
- variant: `communal_desks`

The new archetype is office-space-first, not tool/action-first. It explicitly requires:
- three to five adult independent workers
- communal desks
- separate work setups
- coworking amenities
- one small natural neighbour interaction

It structurally excludes craft benches, labs, makerspaces, machinery, jewelry/watchmaking, hardware prototyping, and child apprentices.

### business.marketing

Now:
- archetype: `campaign_planning`
- variant: `mockup_table`

The new archetype is a campaign-layout tableau:
- generic unbranded product sample
- blank packaging mockups
- image cards
- unlabeled color/material swatches
- two or three adults physically comparing/refining the arrangement

It structurally excludes workshop/machinery/jewelry/manufacturing imagery.

### career.legal_profession

New exact route:
- archetype: `legal_practice`
- variant: `courtroom_advocacy`

The scene is anchored by an adult legal advocate, counsel table, courtroom bench/witness-area architecture, and closed blank folders. It explicitly excludes workshop/craft/lab/apprentice scenes.

### learning.book_genre.booktube

Now:
- archetype: `creator_workflow`
- variant: `camera_creation`

The camera/phone-on-tripod is now part of both the archetype/variant structure and the exact hobby rule, rather than an extra cue inside a reading archetype.

The next test uses **Standard FLUX**, not Klein, because:
- global text suppression is now proven;
- standard FLUX produced clean plain-book results for the reading family;
- Klein continues to show MATERIAL style drift.

## Next validation

Prepared:
- `tools/card_art/catalog/structural_scene_remediation_v1.json`
- `tools/card_art/src/runStructuralSceneRemediation.js`

Scripts:
```bash
cd tools/card_art
npm run audit-structural-scene-remediation-v1
npm run generate-structural-scene-remediation-v1
```

Exactly 5 Standard-FLUX cards:
1. business.coworking
2. business.marketing
3. career.legal_profession
4. learning.book_genre.booktube
5. technology.generative_ai — known-clean control

Estimated first-pass spend: **$0.0625**.

No auto-rerolls.

## Gate

Do not start 50+.

The structural fix clears only if:
- coworking no longer becomes a workshop/craft/lab scene and clearly reads as a shared office;
- marketing no longer becomes a workshop/craft scene and clearly reads as campaign planning;
- legal_profession no longer becomes a workshop/apprentice scene and carries a clear legal setting;
- BookTube shows an actual recording setup and reads as book-content creation rather than plain reading;
- generative_ai control remains clean;
- global title/caption suppression remains intact.

Travel Japan and the minor electronics screen-clutter issue are deliberately deferred until this higher-priority scene-prior gate is resolved.

## Infrastructure

Keep GitHub Actions, Vercel, Production and Play closed. No API generation was run by this remediation commit. Run the dry-run audit before any paid generation.

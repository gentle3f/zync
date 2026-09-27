# Zync V1 — Collection Lived Marker Review

Date: 2026-09-27 HKT
Branch: `card-art-pilot-v1-20260921`
Parent before this round: `c7f8d35`

## Goal

Perform the next visual gate from the collection real-world-memory checkpoint,
using the real production `MyZyncWorldScreen` rather than a parallel lab UI,
then harden the final transition from completing a real-world activity to seeing
that lived state in the collection.

## Visual review

A temporary widget-test visual probe rendered the real production collection grid
with a server-shaped Badminton inventory card and completed local Zync Now memory.

The first captured layout showed that the original green `LIVED` pill sat over
the card's existing top-left plate. The state was understandable, but the badge
competed with locked card-frame chrome.

The grid marker was therefore refined without changing the underlying lived-state
logic:

- the text pill was replaced with a compact 26px circular green check;
- it is centered on the top edge rather than covering the top-left plate;
- a semantics label keeps the meaning explicit: `Lived in real world` /
  `現實做過`;
- the full written explanation remains in the card-detail sheet.

A second production-screen capture confirmed the marker no longer competes with
the top-left frame plate and stays visually secondary to the collectible itself.
This is an internal review, not user approval of the final look.

## Loop regression hardening

Added a production-screen regression proving the state changes live in the same
player journey:

`pending Badminton activity -> mark complete -> dismiss progress sheet ->
collection reload -> owned Badminton card gains lived marker`.

This closes the exact transition implied by the product loop rather than only
testing a pre-seeded completed state.

## Validation

- My Zync World focused widget tests: **4 / 4 PASS**;
- canonical non-golden mobile suite, three local batches:
  - batch 1: **97 / 97 PASS**
  - batch 2: **135 / 135 PASS**
  - batch 3: **119 / 119 PASS**
  - combined: **351 / 351 PASS**
- full `flutter analyze`: **No issues found**;
- temporary visual-probe files were removed after review.

The known missing `goldens/card_art_engine_v1_flagships.png` baseline remains
intentionally excluded.

## Guardrails preserved

No Card FX tuning, server economy/RNG/receipt authority, backend schema, paid
generation, GitHub Actions, Vercel, Production, Play or release work was used.

The pre-existing untracked:
- `mobile/lib/l10n/generated/`
- `mobile/pubspec.lock`

remain untouched and must not be staged.

## Continuation

The remaining high-value subjective gate is a true two-device/manual journey:
both people choose the same Zync Now activity, leave the screen, return to their
own My Zync World, complete it, and confirm that both collections communicate the
lived state clearly.

Without a second connected mobile device, automated coordinator/widget coverage
can prove state continuity but not the social feel of that real-world handoff.

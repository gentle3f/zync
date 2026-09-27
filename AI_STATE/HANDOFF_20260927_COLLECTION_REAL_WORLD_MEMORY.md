# Zync V1 — Collection Real-World Memory

Date: 2026-09-27 HKT
Branch: `card-art-pilot-v1-20260921`
Parent before this round: `2419f1c`

## Goal

Make collection meaning visible after the player actually follows through in the
real world. A card should not only say "owned"; it should be able to reflect that
this interest has become part of the player's lived Zync World.

## What changed

My Zync World now derives a local set of "lived" interests from existing
privacy-bounded Zync Now activity memory.

An interest counts as lived only when a saved `ZyncNowActivityMemory` is in the
`completed` state. Every source interest attached to that completed activity is
included. Chosen/pending and skipped activities do not count.

For a collected card whose canonical interest is lived:

- the collection grid shows a compact `LIVED` / `現實做過` marker;
- the production card-detail sheet explains that the interest has already moved
  beyond the collectible into the player's real Zync World.

For an activity-eligible card that has not been lived yet, the detail sheet now
frames the existing real-world CTA as a concrete next move rather than only an
inventory action.

The existing "Find something to do with this" soft-focus flow is unchanged:
private limits and hard vetoes still override the card focus.

## Privacy and authority

This uses only the already-local, privacy-bounded Zync Now activity memory:
template / source-interest / mode / group-size style data. It introduces no peer
identity, ballot, private constraint, location or social graph storage.

No Cardverse server inventory, economy, reward, RNG, rarity, finish or receipt
authority changed. The server still decides what the player owns; the local app
only decorates that owned card with whether the corresponding interest has been
completed in a real-world Zync activity.

## Testability hardening

`MyZyncWorldScreen` now accepts an optional injected `CardverseCloudClient`.
Production still creates and owns its normal client by default; injected clients
are not closed by the screen.

This made it possible to exercise the real production collection grid/detail with
a fake server inventory in widget tests instead of testing a parallel lab UI.

The new regression test verifies:

- a completed Badminton Zync Now activity;
- a real server-shaped Badminton inventory card;
- the collection grid exposes the lived marker;
- opening the actual production card detail exposes the lived real-world status.

## Validation

The canonical non-golden mobile test set was run in three local batches to avoid
the long-command MCP timeout. All batches passed:

- batch 1: **97 / 97 PASS**
- batch 2: **135 / 135 PASS**
- batch 3: **118 / 118 PASS**
- combined: **350 / 350 PASS**

Full `flutter analyze`: **No issues found**.

`git diff --check`: clean before this handoff write.

The known missing `goldens/card_art_engine_v1_flagships.png` baseline remains
intentionally excluded. Do not synthesize it just to make the literal golden
suite green.

## Guardrails preserved

No Card FX B mechanics/audio tuning, paid generation, Vercel, Production, Play,
release, GitHub Actions, backend schema, Cardverse economy, server receipt or RNG
work was used.

The pre-existing untracked:
- `mobile/lib/l10n/generated/`
- `mobile/pubspec.lock`

remain untouched and must not be staged.

## Continuation

The next high-value gate is subjective real-device review, not more automatic
feature expansion. Check whether the compact collection marker is visually useful
without obscuring the card frame, then walk the two-device loop:

`owned card -> card detail -> focused Zync Now -> real activity -> both devices'
My Zync World -> mark Done -> collection now reflects the lived interest`.

Automated tests establish behavior, not visual approval. If the marker feels too
intrusive, refine presentation only; do not remove the underlying lived-state
link between collection and real-world activity.

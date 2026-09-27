# Zync V1 — First Journey Continuity

Date: 2026-09-27 HKT
Branch: `card-art-pilot-v1-20260921`
Parent before this round: `77d2daa`

## Goal

Audit the first complete player journey after the first-run promise and close the
largest verified navigation seams without adding more onboarding copy.

The intended journey is now:

`first run -> connect -> discover -> choose a real activity -> leave the screen
-> return to My Zync World -> confirm completion -> quest/reward -> reveal/open
-> collection -> choose the next real activity`.

## Pair Zync no longer dead-ends at recap

A completed one-to-one Match recap now has an opt-in primary action into Zync
Now. Existing callers can leave this disabled; the real QR host/scanner flows
enable it.

Show QR and Scan Someone now preserve the navigation result instead of replacing
their whole route. If the player chooses the real-world next step, Zync Now opens
immediately. When an activity is chosen, the route returns toward Home with an
open-world signal, and Home opens My Zync World.

The old Finish Zync path remains available and does not force activity planning.
## Standalone and Group Zync results point into the real world

Standalone Zync Now result now returns a positive continuation signal from the
"Let's do it" / "就呢個，出去做" action.

Group Zync host result does the same. The Group lobby preserves that signal back
to Home, which then opens My Zync World.

QR-scanned Group / standalone Zync Now participants also return the same signal,
so participant devices are not left on a result screen with no continuation.

## Participants keep the same pending activity locally

Previously only the host called `recordZyncNowChoice`. Participant devices saw
the chosen result but could not reconstruct the pending activity in their own
My Zync World.

Bounded Zync Now options now carry only the activity recipe fields required to
reconstruct the candidate locally: candidate id, repeat key, template id,
source-interest ids, participant count and mode. The metadata deliberately does
not carry participant identity, ballots or private constraints.

On a result state, both standalone and Group participants reconstruct the chosen
candidate once, persist it through the existing LocalStore privacy-bounded
Zync Now memory, and then can continue to My Zync World.

Regular non-Zync bounded options remain backward compatible because the recipe
metadata is optional and validated as all-or-nothing when present.
## Validation

- focused pair recap transition test: PASS;
- Zync Now bounded activity-recipe round-trip/privacy-shape test: PASS;
- pairing / Group coordinator / standalone Zync Now coordinator / layout
  regressions: PASS;
- canonical full non-golden mobile suite: **342 / 342 PASS**;
- full `flutter analyze`: **No issues found**;
- `git diff --check`: clean before handoff write.

The known missing `goldens/card_art_engine_v1_flagships.png` baseline remains
intentionally excluded. Do not synthesize it just to make the literal golden
suite green.

## Guardrails preserved

No economy authority, quest reward authority, server Cardverse receipt contents,
pack RNG, finish/rarity, Card FX tuning, backend schema, Vercel, Production,
Play, release, GitHub Actions or paid generation changed.

The pre-existing untracked:
- `mobile/lib/l10n/generated/`
- `mobile/pubspec.lock`

remain untouched and must not be staged.

## Continuation

The highest-value next gate is now a real-device/manual first-journey review,
especially two-device behavior: host and participant should both land in their
own My Zync World with the same chosen pending activity after Zync Now. Automated
tests establish technical continuity but do not establish subjective UX quality.

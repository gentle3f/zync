# Zync V1 — First-run Product Promise

Date: 2026-09-27 HKT
Branch: `card-art-pilot-v1-20260921`
Parent before this round: `a402c9e`

## Goal

The product loop is now mechanically connected, but first-run users still entered
through interest selection without being told the core Zync promise. This round
teaches the loop without adding another onboarding screen or tutorial step.

## What changed

The existing first-run Interest Setup now shows one compact product-promise panel
above the nickname / interest picker:

“Zync starts on your phone. The point happens outside it.”

It explains the complete loop in one sentence:

meet someone -> find a real thing to do -> leave the screen -> come back and grow
your Zync World.

Four compact visual beats reinforce the flow:
- Connect
- Choose
- Go do it
- Come back & grow

This copy is localized for all eight current launch locales:
English, Traditional Chinese, Simplified Chinese, Japanese, Korean, Spanish,
French and Portuguese.

There is deliberately no extra Continue button, carousel, tutorial screen,
reward simulation or forced walkthrough. The player can immediately pick the five
interests already required by onboarding.

## Search usability

The promise panel collapses as soon as the player starts typing in interest
search. This is intentional: the first implementation kept the explanation
visible and pushed search results too far down on a normal phone. Search remains
the task once the user starts typing, then the promise returns when search is
cleared.

Editing an existing profile is unchanged; the first-run promise is shown only
during quick-start onboarding.

## Validation

- existing onboarding/taxonomy widget tests: 16/16 PASS;
- narrow Portuguese first-run layout explicitly renders the localized promise;
- English quick-start test verifies the promise is visible initially and
  disappears during search;
- canonical full non-golden mobile suite: **340 / 340 PASS**;
- full `flutter analyze`: **No issues found**;
- `git diff --check`: clean before this handoff write.

The known missing `goldens/card_art_engine_v1_flagships.png` baseline remains
intentionally excluded. Do not synthesize it just to make the golden suite green.

## Guardrails preserved

No extra onboarding persistence, account requirement, economy/reward logic,
Cardverse authority, RNG, server receipt, Card FX tuning, backend schema,
Vercel, Production, Play, release, GitHub Actions or paid generation changed.

The pre-existing untracked:
- `mobile/lib/l10n/generated/`
- `mobile/pubspec.lock`

remain untouched and must not be staged.

## Product continuation

The first-run product promise is now present without adding friction. The next
useful product pass should be real-device/browser review of the complete first
journey rather than adding more explanatory copy:

first launch -> pick five interests -> Home -> connect with someone / Zync Now ->
choose a real activity -> leave the screen -> return to My Zync World -> confirm
completion -> quest/reward -> draw/open -> collection -> next activity.

Only change the onboarding copy or layout again if that end-to-end review shows
confusion or a concrete usability issue.

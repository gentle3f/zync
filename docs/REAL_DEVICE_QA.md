# Zync V1 — Real-Device Release QA Evidence

Date started: 2026-09-17
Branch: `zync-v1-rebuild-20260917`
Target package: `com.gmail.gentle3f.myproject`
Target version: `1.0.0+6`

This checklist is evidence for physical-device behaviour that GitHub CI/widget tests cannot certify. Do not mark an item PASS without performing it on the signed or production-equivalent Android build.

## Evidence header

Complete once testing begins:

- build source commit: `[SHA]`
- signed AAB/workflow artifact: `[ARTIFACT ID + DIGEST]`
- `ZYNC_API_BASE`: `[PRODUCTION ORIGIN]`
- `ZYNC_PRIVACY_URL`: `[PUBLIC URL]`
- analytics: `[ENABLED / DISABLED]`
- tester/date: `[NAME / DATE]`

For each device record:

- manufacturer/model;
- Android version;
- screen resolution / approximate width class;
- system language;
- font/display scaling if non-default;
- network type.

## A. Installation / identity / branding

| Check | Result | Evidence / notes |
| --- | --- | --- |
| Existing Play/internal-test app upgrades without creating a second package | ☐ PASS ☐ FAIL | |
| Launcher shows Zync icon/name | ☐ PASS ☐ FAIL | |
| Android splash/launch transition looks intentional | ☐ PASS ☐ FAIL | |
| App opens without crash on cold start | ☐ PASS ☐ FAIL | |
| Privacy Policy tile is visible in production build | ☐ PASS ☐ FAIL | |
| Privacy Policy opens the configured public HTTPS page | ☐ PASS ☐ FAIL | |

## B. First-run onboarding

Test on at least one ordinary phone and one narrow/small phone when available.

| Check | Result | Evidence / notes |
| --- | --- | --- |
| Optional nickname field works | ☐ PASS ☐ FAIL | |
| Interest search works with keyboard open | ☐ PASS ☐ FAIL | |
| Can select at least five interests | ☐ PASS ☐ FAIL | |
| Love / Like / Want to try strengths can be changed | ☐ PASS ☐ FAIL | |
| Save remains blocked below five interests | ☐ PASS ☐ FAIL | |
| Save succeeds at five+ interests and Home renders correctly | ☐ PASS ☐ FAIL | |
| Long translated labels do not overlap/clip materially | ☐ PASS ☐ FAIL | |

## C. Unknown-interest AI normalization

| Check | Result | Evidence / notes |
| --- | --- | --- |
| Unknown free-text interest can invoke AI normalization | ☐ PASS ☐ FAIL | |
| Suggested normalized interest is understandable | ☐ PASS ☐ FAIL | |
| User must confirm before adding suggestion | ☐ PASS ☐ FAIL | |
| Production request succeeds through privacy-hardened API | ☐ PASS ☐ FAIL | |
| AI unavailable/error produces useful non-crashing UX | ☐ PASS ☐ FAIL | |

Use only ordinary non-sensitive test interests.

## D. Show My QR — real display

| Check | Result | Evidence / notes |
| --- | --- | --- |
| Small profile produces readable QR | ☐ PASS ☐ FAIL | |
| QR has adequate white quiet zone | ☐ PASS ☐ FAIL | |
| QR remains fully visible on narrow phone | ☐ PASS ☐ FAIL | |
| Larger/custom-interest profile QR renders without error | ☐ PASS ☐ FAIL | |
| Screen brightness/normal lighting permits another device to scan | ☐ PASS ☐ FAIL | |

## E. Scanner camera states

| Check | Result | Evidence / notes |
| --- | --- | --- |
| First camera permission grant starts scanner | ☐ PASS ☐ FAIL | |
| Permission denial shows localized recovery state | ☐ PASS ☐ FAIL | |
| Returning after permission/settings change can recover | ☐ PASS ☐ FAIL | |
| Scanner frame aligns well on physical display | ☐ PASS ☐ FAIL | |
| Autofocus/focus distance is usable | ☐ PASS ☐ FAIL | |
| Dimmer room still scans within reasonable conditions | ☐ PASS ☐ FAIL | |
| Invalid/non-Zync QR does not enter match flow | ☐ PASS ☐ FAIL | |
| Own QR/self-scan is rejected | ☐ PASS ☐ FAIL | |

## F. Device-to-device QR compatibility

Use two physical devices where possible.

| Check | Result | Evidence / notes |
| --- | --- | --- |
| Legacy/small QR scans device A → B | ☐ PASS ☐ FAIL | |
| Legacy/small QR scans device B → A | ☐ PASS ☐ FAIL | |
| Compressed `Z2:` large-profile QR scans A → B | ☐ PASS ☐ FAIL | |
| Custom interest label/category survives scan | ☐ PASS ☐ FAIL | |
| Peer nickname/language survives scan | ☐ PASS ☐ FAIL | |

Also scan `docs/play-reviewer-qr.html` from another screen and confirm `Zync Reviewer Demo` is accepted.

## G. Match / Hidden Match

| Check | Result | Evidence / notes |
| --- | --- | --- |
| Exact shared-interest count is plausible | ☐ PASS ☐ FAIL | |
| Shared interests are initially hidden as designed | ☐ PASS ☐ FAIL | |
| Reveal interaction/animation feels smooth | ☐ PASS ☐ FAIL | |
| Haptics, if present, feel appropriate | ☐ PASS ☐ FAIL | |
| Long interest labels remain readable | ☐ PASS ☐ FAIL | |
| Zero exact-match path is not presented as a failure/dead end | ☐ PASS ☐ FAIL | |

## H. Conversation AI / fallback

| Check | Result | Evidence / notes |
| --- | --- | --- |
| Same-language shared-interest AI question succeeds | ☐ PASS ☐ FAIL | |
| Zero-match crossover AI question succeeds | ☐ PASS ☐ FAIL | |
| Easy mode | ☐ PASS ☐ FAIL | |
| Fun mode | ☐ PASS ☐ FAIL | |
| Debate mode | ☐ PASS ☐ FAIL | |
| Deep mode | ☐ PASS ☐ FAIL | |
| Guess mode | ☐ PASS ☐ FAIL | |
| Surprise mode | ☐ PASS ☐ FAIL | |
| Switching mode while request is in flight cannot show stale mode/result mismatch | ☐ PASS ☐ FAIL | |
| Another question action works | ☐ PASS ☐ FAIL | |
| Offline/API-failure path displays a local question and remains usable | ☐ PASS ☐ FAIL | |

## I. Bilingual physical-device flow

Recommended pair: Traditional Chinese + Japanese.

| Check | Result | Evidence / notes |
| --- | --- | --- |
| QR carries peer language correctly | ☐ PASS ☐ FAIL | |
| Primary question uses scanning-device language | ☐ PASS ☐ FAIL | |
| Secondary equivalent translation appears for different supported language | ☐ PASS ☐ FAIL | |
| Two rendered versions express the same semantic question | ☐ PASS ☐ FAIL | |
| Long bilingual content is scroll-safe on small display | ☐ PASS ☐ FAIL | |
| Same-language pair does not show duplicate translation | ☐ PASS ☐ FAIL | |

## J. Zync Again / local history

| Check | Result | Evidence / notes |
| --- | --- | --- |
| First successful scan creates local history | ☐ PASS ☐ FAIL | |
| Scanning same peer again increments repeat history correctly | ☐ PASS ☐ FAIL | |
| New shared interests since last time are calculated plausibly | ☐ PASS ☐ FAIL | |
| Clearing app data removes local profile/history as expected | ☐ PASS ☐ FAIL | |

## K. Network / production integration

| Check | Result | Evidence / notes |
| --- | --- | --- |
| Production API URL is HTTPS and current privacy-hardened deployment | ☐ PASS ☐ FAIL | |
| Normalization works on Wi-Fi | ☐ PASS ☐ FAIL | |
| Question generation works on Wi-Fi | ☐ PASS ☐ FAIL | |
| At least one mobile-data test works | ☐ PASS ☐ FAIL | |
| Temporary network loss does not crash product | ☐ PASS ☐ FAIL | |
| Analytics disabled state does not affect core flow, if disabled | ☐ PASS ☐ FAIL | |
| Analytics enabled events remain coarse/privacy-filtered, if enabled | ☐ PASS ☐ FAIL | |

## L. Final release decision

Do not certify device QA until every critical failure is resolved.

- critical blockers found: `[NONE / LIST]`
- non-blocking issues accepted: `[NONE / LIST + rationale]`
- retest build SHA/artifact if fixes were made: `[SHA / ARTIFACT]`
- final device QA result: `☐ PASS  ☐ FAIL`
- signed by/date: `[TESTER / DATE]`

Attach screenshots/video/log references where useful, but do not attach API keys, keystore material, raw secret environment values or other users' personal QR/profile data.

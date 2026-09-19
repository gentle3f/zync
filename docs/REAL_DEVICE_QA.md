# Zync V1 — Real-Device QA Evidence

Date updated: 2026-09-18
Branch: `zync-v1-rebuild-20260917`
Production package: `com.gmail.gentle3f.myproject`
QA package: `com.gmail.gentle3f.myproject.qa`
Target production version: `1.0.0+6`

This checklist covers physical-device behaviour that CI/widget tests cannot fully certify. The current canonical post-scan flow is the unified **Zync Session**:

```text
Scan
→ impact
→ reveal one meaningful connection
→ talk about it
→ reveal another when ready
→ recap
```

Do not use the obsolete "match report -> reveal everything -> separate Conversation screen" flow as the QA standard.

## Evidence header

Record:

- build source commit;
- QA/signed artifact ID + digest;
- `ZYNC_API_BASE`;
- `ZYNC_PRIVACY_URL`;
- analytics state;
- regional-interest-learning state;
- tester/date.

For each physical device record:

- manufacturer/model;
- Android version;
- approximate screen size/width class;
- system language;
- font/display scaling if non-default;
- network type.

## A. Installation / identity / branding

| Check | Result | Evidence / notes |
| --- | --- | --- |
| QA build installs beside production/legacy Zync without replacing it | ☐ PASS ☐ FAIL | |
| QA launcher shows **Zync QA** | ☐ PASS ☐ FAIL | |
| Production build, when later tested, retains package `com.gmail.gentle3f.myproject` | ☐ PASS ☐ FAIL | |
| Android splash/launch transition looks intentional | ☐ PASS ☐ FAIL | |
| Cold start does not crash | ☐ PASS ☐ FAIL | |
| Privacy Policy is visible and opens the configured HTTPS preview/production page | ☐ PASS ☐ FAIL | |

## B. First-run interest identity

Test on an ordinary phone and a narrow/small phone when possible.

| Check | Result | Evidence / notes |
| --- | --- | --- |
| Optional nickname works | ☐ PASS ☐ FAIL | |
| Category/L2/L3 browsing feels understandable | ☐ PASS ☐ FAIL | |
| Search works with keyboard open | ☐ PASS ☐ FAIL | |
| English and Chinese aliases find the expected canonical interest | ☐ PASS ☐ FAIL | |
| Related/suggested interests help discovery without appearing as false exact matches | ☐ PASS ☐ FAIL | |
| At least five interests can be selected | ☐ PASS ☐ FAIL | |
| Love / Like / Want to try strengths can be changed | ☐ PASS ☐ FAIL | |
| Save remains blocked below five interests | ☐ PASS ☐ FAIL | |
| Save succeeds at five+ interests and Home renders correctly | ☐ PASS ☐ FAIL | |
| Long translated labels do not overlap/clip materially | ☐ PASS ☐ FAIL | |

Recommended manual probes include Badminton/羽毛球, Coffee/咖啡, LEGO, AI, bouldering and one niche title/franchise.

## C. Local custom interests and regional discovery

The shipped V1 interest-entry flow is local-first. Do **not** test obsolete mandatory AI normalization.

| Check | Result | Evidence / notes |
| --- | --- | --- |
| Unknown free-text interest can be added immediately without AI confirmation | ☐ PASS ☐ FAIL | |
| No spinner/network wait is required to add a custom interest | ☐ PASS ☐ FAIL | |
| Case/spacing/punctuation variants resolve to the expected stable custom identity where designed | ☐ PASS ☐ FAIL | |
| Known label/alias resolves to the bundled canonical ID rather than creating a duplicate custom ID | ☐ PASS ☐ FAIL | |
| Regional discovery works without requesting GPS/precise-location permission | ☐ PASS ☐ FAIL | |
| Temporary network loss does not block local search/custom-interest entry | ☐ PASS ☐ FAIL | |

Use only ordinary non-sensitive test interests.

## D. Show My QR — one-scan handshake

| Check | Result | Evidence / notes |
| --- | --- | --- |
| Current one-scan QR renders clearly with adequate quiet zone | ☐ PASS ☐ FAIL | |
| QR remains fully visible on a narrow phone | ☐ PASS ☐ FAIL | |
| Larger/custom-interest profile QR renders without error | ☐ PASS ☐ FAIL | |
| Normal lighting permits another device to scan reliably | ☐ PASS ☐ FAIL | |
| Waiting state is clear | ☐ PASS ☐ FAIL | |
| Background/resume while waiting still recovers/polls correctly | ☐ PASS ☐ FAIL | |
| Expired QR shows an understandable state and can be regenerated | ☐ PASS ☐ FAIL | |

## E. Scanner camera states

| Check | Result | Evidence / notes |
| --- | --- | --- |
| First camera permission grant starts scanner | ☐ PASS ☐ FAIL | |
| Permission denial shows localized recovery state | ☐ PASS ☐ FAIL | |
| Returning after permission/settings change can recover | ☐ PASS ☐ FAIL | |
| Scanner frame aligns well on physical display | ☐ PASS ☐ FAIL | |
| Autofocus/focus distance is usable | ☐ PASS ☐ FAIL | |
| Dimmer room still scans within reasonable conditions | ☐ PASS ☐ FAIL | |
| Invalid/non-Zync QR does not enter Zync Session | ☐ PASS ☐ FAIL | |
| Own QR/self-scan is rejected | ☐ PASS ☐ FAIL | |
| Re-scanning an already-used one-scan QR is handled safely | ☐ PASS ☐ FAIL | |

## F. Two-device one-scan pairing

Use two physical Android devices.

Required primary gate:

1. Device A taps **Show my QR** and waits.
2. Device B scans A **exactly once**.
3. PASS only if B enters the Zync Session and A automatically enters the same session without touching A.

| Check | Result | Evidence / notes |
| --- | --- | --- |
| A creates encrypted short-lived relay session | ☐ PASS ☐ FAIL | |
| B scans once and enters Zync Session | ☐ PASS ☐ FAIL | |
| A auto-enters Zync Session after B's scan | ☐ PASS ☐ FAIL | |
| Both phones derive the same hidden-connection count | ☐ PASS ☐ FAIL | |
| Both phones reveal connections in the same order | ☐ PASS ☐ FAIL | |
| Peer nickname/language survives pairing | ☐ PASS ☐ FAIL | |
| Custom-interest label/category survives pairing | ☐ PASS ☐ FAIL | |
| Duplicate scanner response cannot replace the first accepted response | ☐ PASS ☐ FAIL | |

Legacy QR decoding remains compatibility code but is not the primary V1 product gate.

## G. Zync Session — impact and connection reveal

| Check | Result | Evidence / notes |
| --- | --- | --- |
| Exact-match session begins with a clear **YOU ZYNC!** impact moment | ☐ PASS ☐ FAIL | |
| Hidden connection count is the human-facing connection-thread count, not a noisy raw hierarchy count | ☐ PASS ☐ FAIL | |
| A true broad ancestor can collapse into a more specific revealed connection | ☐ PASS ☐ FAIL | |
| Sibling interests such as Movies and Anime are not incorrectly collapsed into each other | ☐ PASS ☐ FAIL | |
| First reveal feels immediate; haptics never delay/block the UI | ☐ PASS ☐ FAIL | |
| Both people's original strengths are represented correctly | ☐ PASS ☐ FAIL | |
| Long/niche interest labels remain readable | ☐ PASS ☐ FAIL | |
| User can start talking after one reveal without revealing everything | ☐ PASS ☐ FAIL | |
| Reveal another advances one connection at a time | ☐ PASS ☐ FAIL | |
| Final recap is readable and not presented as a spreadsheet/report | ☐ PASS ☐ FAIL | |

## H. Conversation question inside the reveal

| Check | Result | Evidence / notes |
| --- | --- | --- |
| First question is ready quickly or loads unobtrusively beside the revealed connection | ☐ PASS ☐ FAIL | |
| Question is focused on the current revealed connection, not an unfocused profile summary | ☐ PASS ☐ FAIL | |
| Easy mode | ☐ PASS ☐ FAIL | |
| Fun mode | ☐ PASS ☐ FAIL | |
| Debate mode | ☐ PASS ☐ FAIL | |
| Deep mode | ☐ PASS ☐ FAIL | |
| Guess mode | ☐ PASS ☐ FAIL | |
| Surprise mode | ☐ PASS ☐ FAIL | |
| Change vibe feels secondary rather than a mandatory setup step | ☐ PASS ☐ FAIL | |
| Offline/API-failure path displays a local question and remains usable | ☐ PASS ☐ FAIL | |

## I. Zero exact match crossover

| Check | Result | Evidence / notes |
| --- | --- | --- |
| UI does not lead with a failure/dead-end message | ☐ PASS ☐ FAIL | |
| A plausible Interest-Graph crossover pair is shown | ☐ PASS ☐ FAIL | |
| Related/crossover interests are never mislabeled as an exact shared interest | ☐ PASS ☐ FAIL | |
| AI question makes both people discuss the selected crossover | ☐ PASS ☐ FAIL | |
| Offline fallback remains usable | ☐ PASS ☐ FAIL | |

## J. Bilingual same-session semantics

Recommended physical pair: Traditional Chinese + Japanese.

| Check | Result | Evidence / notes |
| --- | --- | --- |
| QR carries peer language correctly | ☐ PASS ☐ FAIL | |
| Each phone shows its own language first | ☐ PASS ☐ FAIL | |
| Secondary equivalent translation appears for the other supported language | ☐ PASS ☐ FAIL | |
| Both phones are clearly expressing the same semantic question | ☐ PASS ☐ FAIL | |
| Reversed language order does not cause two unrelated AI questions | ☐ PASS ☐ FAIL | |
| Long bilingual content is scroll-safe on a small display | ☐ PASS ☐ FAIL | |
| Same-language pair does not show a duplicate translation | ☐ PASS ☐ FAIL | |

The preview backend has an automated live contract for the short-lived shared-question cache; physical QA still needs to confirm the rendered experience makes sense.

## K. Zync Again / local history

| Check | Result | Evidence / notes |
| --- | --- | --- |
| First successful Zync creates local peer history | ☐ PASS ☐ FAIL | |
| First-ever Zync does **not** label every connection as "new since last Zync" | ☐ PASS ☐ FAIL | |
| Zyncing the same peer again increments repeat history | ☐ PASS ☐ FAIL | |
| Newly shared revealed connection receives the New badge | ☐ PASS ☐ FAIL | |
| An old specific reveal is not marked New merely because a folded broad parent was newly selected | ☐ PASS ☐ FAIL | |
| Different local histories on the two devices do not change reveal order | ☐ PASS ☐ FAIL | |
| Clearing app data removes local profile/history as expected | ☐ PASS ☐ FAIL | |

## L. Network / preview-production integration

| Check | Result | Evidence / notes |
| --- | --- | --- |
| QA API URL is HTTPS and points to the intended controlled preview | ☐ PASS ☐ FAIL | |
| Privacy URL matches that preview | ☐ PASS ☐ FAIL | |
| One-scan relay works on Wi-Fi | ☐ PASS ☐ FAIL | |
| AI question generation works on Wi-Fi | ☐ PASS ☐ FAIL | |
| At least one mobile-data test works | ☐ PASS ☐ FAIL | |
| Temporary network loss does not crash the product | ☐ PASS ☐ FAIL | |
| Analytics remains disabled in the QA/public-V1 configuration | ☐ PASS ☐ FAIL | |
| Regional interest learning is enabled in the production-equivalent QA build without GPS | ☐ PASS ☐ FAIL | |

## M. Final QA decision

Do not certify physical-device QA until every critical failure is resolved.

- critical blockers found: `[NONE / LIST]`
- non-blocking issues accepted: `[NONE / LIST + rationale]`
- retest build SHA/artifact if fixes were made: `[SHA / ARTIFACT]`
- final device QA result: `☐ PASS  ☐ FAIL`
- signed by/date: `[TESTER / DATE]`

Attach screenshots/video/log references where useful, but never attach API keys, keystore material, raw Vercel/Upstash secrets or another person's real QR/profile data.

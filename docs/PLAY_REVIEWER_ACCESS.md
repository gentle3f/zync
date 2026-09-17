# Zync V1 — Google Play Reviewer Access Instructions

Date: 2026-09-17
Package: `com.gmail.gentle3f.myproject`

Zync V1 has no login or registration. The core experience normally needs two people/devices because one person shows a Zync QR and the other scans it. To let Google Play review the core flow with one installed device, provide the synthetic reviewer QR below as an App Access/review resource.

## Reviewer test QR

Repository source:

`docs/play-reviewer-qr.html`

The page renders a deterministic QR entirely from embedded data and JavaScript; it loads no external library and contains no real person's data.

Synthetic peer represented by the QR:

- nickname: `Zync Reviewer Demo`
- language: English
- interests:
  - Badminton — Love
  - Japan Travel — Like
  - Coffee — Like
  - Artificial Intelligence — Like
  - Movies — Want to try
  - Pop Music — Like

Canonical raw payload, for verification/re-generation only:

```json
{"v":1,"id":"play-reviewer-demo-v1","name":"Zync Reviewer Demo","lang":"en","i":[["sports.badminton",2],["travel.japan",1],["food.coffee",1],["technology.ai",1],["media.movies",0],["music.pop",1]]}
```

Do not replace this with a real user's QR or nickname.

## Suggested Play reviewer instructions

Use wording equivalent to:

> Zync does not require a login. Complete the short interest setup by choosing at least five interests. From the Home screen tap **Scan someone**, allow camera access, then scan the supplied **Zync Reviewer Demo** QR from another screen or printed copy. The app will compare the profiles locally and open the match flow. Continue through the reveal screen and tap **Start a conversation** to test the conversation modes. If the AI service is temporarily unavailable, Zync intentionally falls back to an on-device question rather than blocking the flow.

## Make the reviewer QR actually accessible

Before submitting for review, use one of these supported operational approaches:

1. attach/export a normal image of the reviewer QR in the Play App Access/review instructions; or
2. host the reviewer QR page/image at a stable public HTTPS URL and give Google that URL.

Do not rely on a local file path from the developer's computer. If using a public URL, verify it is accessible without authentication, VPN, geofencing or expiring tokens.

## Review path to verify before submission

On a real Android device with the signed build:

1. launch Zync;
2. choose at least five interests and save;
3. confirm Home appears;
4. tap **Scan someone**;
5. grant camera permission;
6. scan the synthetic reviewer QR;
7. confirm the match result opens rather than showing Invalid QR;
8. reveal shared interests if present;
9. open **Start a conversation**;
10. try at least two conversation modes;
11. confirm AI success when production API is available and local fallback when it is not;
12. return Home and open **Privacy policy** to verify the production public policy URL.

## Why this reviewer resource is required

Google Play review guidance requires developers to provide the resources needed to access restricted or otherwise hard-to-reach app functionality, including QR codes when relevant. Zync's core two-person flow should therefore not force the reviewer to set up a second physical device/account just to reach the match/conversation screens.

Official reference:
https://support.google.com/googleplay/android-developer/answer/10788890

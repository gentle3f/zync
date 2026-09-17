# Zync V1 — Google Play Store Listing Draft

Date: 2026-09-17
Package: `com.gmail.gentle3f.myproject`
Version target: `1.0.0+6`

This replaces the old login/remote-matching description. Do not reuse old copy that says users log in, are remotely matched, or use a cloud people-matching service.

## English — primary listing

### App name

`Zync`

### Short description

`Discover shared interests in person and turn them into better conversations.`

Character count: 76 / 80.

### Full description

Meet someone in person and wonder what you actually have in common? Zync helps you discover the interests you share — including the ones you might never think to ask about — and turns them into an easy way to start a real conversation.

Build your interest profile by choosing the things you love, like or want to try. When you are with someone, one person shows a Zync QR and the other scans it. Zync compares the two profiles locally on the scanning device, then reveals your shared interests one by one.

Found a match? Zync can create a conversation question around what you both enjoy. No exact match? Zync can still find a crossover between your different interests so the conversation does not hit a dead end. If the AI service is unavailable, Zync falls back to built-in local questions.

Choose the conversation style that fits the moment:

• Easy — relaxed, low-pressure questions
• Fun — playful conversation starters
• Debate — friendly topics you can disagree about
• Deep — more meaningful discussion without becoming intrusive
• Guess — predict something about each other, then compare
• Surprise — let Zync choose

Zync is designed for face-to-face connection, not another social feed. There is no account or registration, no public profile, no follower system and no in-app messaging.

Your Zync profile and Zync Again history are stored locally on your device. QR sharing sends the nickname, language and selected interests in that QR directly to the person who scans it. When you use optional AI-powered interest normalization or conversation questions, only the interest text needed for that request is sent through Zync's API for processing. See the in-app Privacy Policy for details.

Other V1 features include:

• Zync Again — remember people you have Zynced with on your own device
• Interest DNA — a descriptive view of your interests, not a personality test
• Bilingual conversation prompts when two supported languages differ
• English, Traditional Chinese, Simplified Chinese, Japanese, Korean, Spanish, French and Portuguese

Discover what connects you — then talk about it.

## Store screenshots — required new set

Do not reuse screenshots of the old login/remote-matching product. Capture the rebuilt V1 at production-like settings.

Recommended screenshot story:

1. **Discover what connects you** — polished Home screen with Show My QR / Scan someone.
2. **Choose what you're into** — interest setup with Love / Like / Want to try.
3. **Zync face to face** — Show My QR screen with the privacy explanation visible.
4. **Reveal hidden shared interests** — Hidden Match progressive reveal.
5. **No exact match? Keep talking.** — crossover conversation path.
6. **Pick the vibe** — Easy / Fun / Debate / Deep / Guess / Surprise.
7. **Talk across languages** — bilingual semantic-question example.
8. **Zync Again** — local history / repeat connection.

Avoid putting claims such as “100% private”, “no data collected”, “AI never receives your interests”, or “all data stays on device”; those are inaccurate for the production AI path.

## Play Console factual guardrails

Current Google Play metadata limits to respect at submission:

- app name: maximum 30 characters;
- short description: maximum 80 characters;
- full description: maximum 4,000 characters.

Official reference:
https://support.google.com/googleplay/android-developer/answer/9859152

## Before publishing this draft

- confirm the public Privacy Policy URL matches the in-app `ZYNC_PRIVACY_URL`;
- complete Data Safety using the actual production configuration;
- confirm whether privacy-light analytics is enabled or intentionally disabled;
- confirm OpenRouter/Vercel/PostHog processor wording and retention settings;
- replace screenshots with the certified signed-build UI;
- keep package/application identity unchanged.

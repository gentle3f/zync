# Zync — Eight-Locale Localization Complete

Date: 2026-09-23
Branch: `card-art-pilot-v1-20260921`

Read `AI_STATE/OPERATING_RULES.md` before any write. Vercel remains disabled
for this branch. Keep GitHub Actions, Production, Play and image generation
closed unless genuinely required.

## Completion state

Runtime canonical interests: **4,053**

Supported locales:

`en / zh-Hant / zh-Hans / es / fr / pt / ja / ko`

Display-label localization is now complete:

- **4,053 / 4,053 canonical interests**
- **8 / 8 supported locales**
- missing explicit display labels: **0**
- es/fr/pt/ja/ko entries: **20,265 = 4,053 × 5**
- zh-Hant and zh-Hans remain complete
- English remains canonical/source identity

The final Stage E batch translated the remaining 305 generic interests:

- business 40
- career 29
- collecting 34
- crafts 47
- fashion 22
- motorsport 9
- pets 25
- science 19
- technology 56
- transport 24

Total final labels added: **1,525**.

## QA

Final 305 source-set:
- source IDs: 305
- translated IDs: 305
- missing: 0
- extra: 0
- internal exact collisions: 0

Final 305 vs 1,910 proper-name rows:
- global exact collisions: 0

Final 305 vs Part 16:
- global exact collisions: 0

Full es/fr/pt/ja/ko source audit:
- entries: 20,265
- global duplicate labels: 96
- same-category collisions: **0**

The 96 global duplicates are intentional cross-category homonyms/titles, e.g.
film vs game `Persona`, book vs screen adaptation titles, music genre vs dance,
and artist vs car brand `Genesis`. Cross-category ambiguity remains allowed.

A new hard test now requires:
1. 4,053 total interests
2. every supported locale to have an explicit label for every interest
3. same-category localized labels to be unique for every locale

## Runtime files added in Stage E

- `mobile/lib/core/interest_locale_final_a.dart` — Business + Career, 69
- `mobile/lib/core/interest_locale_final_b.dart` — Collecting + Crafts, 81
- `mobile/lib/core/interest_locale_final_c.dart` — Fashion + Motorsport + Pets + Science, 75
- `mobile/lib/core/interest_locale_final_d.dart` — Technology + Transport, 80

## Important scope note

Display labels are fully localized. Locale-specific aliases are **not** yet
exhaustively translated for all 4,053 interests. Search remains effective via:
- current-locale display label
- locale aliases where curated
- English/global aliases as fallback

Do not describe all aliases as eight-locale complete.

## Next recommended work

1. Run local Flutter tests when a safe local execution environment is available;
   do not burn GitHub Actions merely for this checkpoint.
2. Audit high-value locale-specific search aliases for USA Spanish and Hong Kong
   Traditional Chinese if needed.
3. Resume rights-gated partner/platform/sports ecosystem work only after policy
   review; no brand/logo card art generation without rights clearance.
4. Keep the eight-locale completeness + collision tests as permanent release
   gates for all future catalog additions.

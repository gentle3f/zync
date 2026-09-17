# Zync V1 mini handoff — API hardening slice

Branch: `zync-v1-rebuild-20260917`. Continue from `AI_STATE/LATEST_HANDOFF.md` plus prior mini handoff `AI_STATE/MINI_HANDOFF_20260917_1155_SIGNING_API_CERTIFIED.md`; do not restart repository discovery.

## Durable progress in this slice

1. Added dependency-free V1 serverless behavioral contract tests at `.github/scripts/serverless_contracts.mjs` and wired them into `.github/workflows/zync-v1-ci.yml`.
2. Contract coverage now includes method validation, interest-required validation, missing AI configuration, same-language question parsing, strict bilingual separator parsing, malformed bilingual response rejection, normalization input bounds, deterministic canonical IDs, category allow-list fallback, provider failure mapping, request-language hardening, interest-length/count bounds, and presence of upstream timeout signals.
3. Hardened `api/v1/question.js`:
   - only supported Zync locales survive into prompts;
   - untrusted/unknown language strings fall back safely instead of becoming prompt instructions;
   - each interest string is capped at 120 chars and arrays at 12 items;
   - interests are interpolated as JSON data and explicitly described as data, not instructions;
   - OpenRouter fetch has a 12-second abort timeout.
4. Hardened `api/v1/normalize-interest.js` similarly:
   - server-side locale canonicalization to the 8 supported language families;
   - input explicitly framed as data, not instructions;
   - 12-second OpenRouter timeout;
   - existing 2..100 input bound, category allow-list and deterministic hashed custom ID retained.
5. Updated manual signed-release workflow so a production signed AAB cannot be built accidentally with an empty/non-HTTPS `ZYNC_API_BASE`. Normal CI may still use local fallbacks, but the Play release now requires a real HTTPS backend because AI normalization/questions are core V1 functionality.

## Validation state

Earlier CI #67 `35178975781` was fully green and certified signing-prep integration + syntax validation + Flutter analyze/tests + unsigned release AAB.

The initial serverless contract-test step itself passed in CI #68 before that run was superseded by later hardening pushes.

Current authoritative validation is CI #71 `35180203133` on commit `bd2505388551c31cdf2eb256b0798d436b9fcfb2`. At creation of this mini handoff it was pending/queued. Do not call the new API-hardening slice fully certified until #71 (or a newer run containing these commits) passes contract tests, signing checks, Flutter analyze/tests, release AAB build and artifact upload.

## External blockers remain unchanged

- Existing Vercel production URL is still unknown to the connector; do not guess it. `ZYNC_API_BASE` must eventually be set as a GitHub repository variable.
- Real Android upload keystore material must be configured only as GitHub Actions Secrets; never commit it.
- Real-device QA is still required before Play internal/release testing.

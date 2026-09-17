# Zync V1 — Latest Handoff

Authoritative handoff: `AI_STATE/HANDOFF_20260917_1545_RELEASE_WEB_ONE_SHOT_READY.md`

Branch: `zync-v1-rebuild-20260917`

Read the authoritative handoff in full and continue directly from its **Recommended continuation order**. Do not restart repository discovery or old Thunkable archaeology.

Current production integration facts:

- Vercel project `zync` / project ID `prj_GayyH1E1oWeliJew8P2gWLiiqH0A` / team `team_jynHypQ0VPNT6nwooTRyFG4B` are recovered and accessible.
- Stable production domain is `https://zync-inky.vercel.app`, but it still points to the old 2025 `main` deployment until the V1 cutover.
- Vercel env has been configured by the release owner with the OpenRouter key, `OPENROUTER_MODEL=openrouter/free`, and `ZYNC_PUBLIC_URL=https://zync-inky.vercel.app`.
- Vercel Hobby rolling deployment quota is temporarily exhausted. Branch auto-deploy is disabled in `vercel.json`; verification shows no new Vercel deployments after that protection was enabled.
- Public legal pages now exist for `/privacy`, `/terms`, `/disclaimer` and are CI-contracted.
- Public V1 analytics are explicitly default-OFF and signed/unsigned release builds pin `ZYNC_ANALYTICS_ENABLED=false`.
- One-shot production cutover instructions are frozen in `docs/PRODUCTION_ONE_SHOT_RELEASE_V1.md`.
- Release-facing Play Data Safety answers are frozen in `docs/PLAY_DATA_SAFETY_V1_RELEASE_ANSWERS.md`.

CI run `35195682210` / #110 at head `136d2267495ea18e5873dd07e442e42ceee37c38` has already passed serverless, OpenRouter privacy, public-release web contracts, Android identity, `flutter analyze`, and Flutter tests. At the time of this pointer update, unsigned AAB build/upload was still completing; check that run first and record the artifact metadata before calling this slice fully certified.

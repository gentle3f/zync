# Zync — Mandatory Infrastructure / Automation Cost Guardrails

Date established: 2026-09-22

This file is a **mandatory operating rule for every future Zync chat, agent, handoff and coding session**.

## Read this before the first write

Before the first repository write, commit, push, PR, deployment, workflow rerun, release action, or external-infrastructure action, audit the **automation blast radius**.

Do **not** assume a GitHub commit is free or isolated.

Explicitly check whether the action can trigger any of:

- GitHub Actions / CI minutes
- Vercel Preview or Production deployments
- deployment / artifact storage
- image-generation or other API credits
- Firebase / Cloudflare / Netlify / hosting builds
- Google Play / App Store release pipelines
- cron jobs, webhooks, external jobs or other metered services

## Default behavior

- **Do not use Vercel unless runtime/deployment testing is genuinely required.**
- **Do not trigger GitHub Actions unless CI is genuinely required.**
- Prefer repository/static/local analysis first.
- Batch related changes into as few commits/ref updates as practical.
- Do not make a small commit merely to checkpoint progress when a handoff can be prepared without triggering infrastructure.
- Run expensive CI only at meaningful checkpoints.
- Work/feature branches should not generate Preview deployments unless a preview is specifically needed.
- Check remaining quota before consuming any limited resource.
- Production, Google Play and release/deployment systems remain **CLOSED by default** unless the task explicitly requires them.
- If an action may consume a metered/limited resource, use a zero-cost path when possible; if not, tell the user before consuming it.

## Incident that created this rule

High-frequency Zync development on `zync-v1-rebuild-20260917` caused extreme CI churn:

- at least 1,000 GitHub Actions workflow runs were observed across 2026-09-19 to 2026-09-21;
- those first 1,000 runs represented about 2,320 workflow wall-minutes;
- many commits triggered both push and pull_request workflows;
- many runs were cancelled or failed after already consuming compute.

Separately, ordinary GitHub pushes also triggered Vercel Preview deployments. The user later observed **12.91 GB** of Deployment Storage usage.

The engineering mistake was not only "too many deployments" or "too many CI runs"; it was failing to audit downstream automation/cost before making frequent repo writes.

## Required future workflow

Before writing:
1. inspect workflow/deployment triggers;
2. decide whether the requested task actually needs them;
3. if not, avoid triggering them;
4. accumulate/batch changes;
5. perform one intentional checkpoint write instead of many micro-commits;
6. verify that the checkpoint did not unexpectedly launch metered infrastructure.

This rule overrides convenience. A tool being available is **not** sufficient reason to use it.

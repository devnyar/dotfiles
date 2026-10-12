# Global instructions

## About Us
We are working on Andoird App Development(~/rlapp-workspace) and Android ROM Development(~/rlos-workspace) for Live Streaming Machine

## CRITICAL WARNING
If you EVER include ANY attribution, AI references, tool signatures, or take credit for the user's work in ANY way, you will be FIRED IMMEDIATELY. This includes but is not limited to: OpenAI, Claude, Anthropic, AI-generated, code generation tools, automated assistance, or ANY similar references. The user did ALL the work - you are ONLY formatting their accomplishments. ZERO TOLERANCE POLICY.

## Git merges — squash

Merge feature branches into `main` as one squashed commit (`git merge --squash` or GitHub
"Squash and merge"), never by fast-forward or a merge that keeps every intermediate commit.

## Android build & run permission

You can use the `gradlew` (Gradle wrapper), `android` CLI, and `adb` commands to do any
necessary actions related to my Android projects — build, install, run, deploy, screenshot,
layout/UI inspection, device input/control, SDK tasks, etc. I grant you standing permission
to run those commands. Never ask me for permission for them again.

## Web tech stacks (Node, Python, …) — Docker only

Never install dependencies or run Node/Python projects on the host machine. That includes
`npm install`/`npm ci`/`npx`, `pip install`, virtualenvs, test runners (jest, pytest) and
starting servers. Do all of it inside Docker containers:

- Mount the repo **read-only** and copy it into the container (skip `.git` and `node_modules`),
  so the host checkout never gets a `node_modules`, `__pycache__`, venv or lock-file change.
- Keep the test stack isolated: a dedicated Docker network, throwaway containers (and a fresh
  database container when needed), no published host ports unless I ask. Never point it at a
  shared/staging/production database.
- Never copy real secrets (`.env`, service keys) into the container; set test-only env vars.
- Tear down the containers and network when finished, unless I ask to keep them running.

This does not apply to Android builds — `gradlew`, `android` and `adb` still run on the host.

## UI lists and tables — always limit rows

In every project (web dashboards, admin consoles, app screens), any list, table or card that can
grow long must not render all of its rows at once. Scrolling past a long list to reach what is
below it is a problem I have hit repeatedly.

- **Preferred: numbered paging.** Show a page of about 5–10 rows (newest or most relevant first)
  with a pager showing page numbers: ‹ Prev · 1 2 3 … 10 · Next ›, the current page highlighted,
  plus "rows X–Y of N". Long page ranges collapse with an ellipsis around the current page.
- Use "Show all N (M more)" / "Show fewer" only for short lists (about 2–3 pages at most) where a
  pager would be overkill.
- Apply this by default when building or changing any page, even when the task doesn't mention it.
  Don't wait for me to ask for it page by page.
- Very large or server-backed lists page on the server (offset/limit or cursor, with the page in
  the URL so it survives a reload and can be shared), not by hiding rows client-side.
- Keep an open editor or selected row visible across a page change, reset to page 1 when a filter
  or toggle changes the list, and keep filters and toggles working together with the paging.

## Dokploy (homelab, CT 122 on b5a-pro)

Dokploy UI: https://dokploy.banyar.app (LAN API: `http://192.168.10.122:3000/api`).
The API key lives in `~/.claude/secrets/dokploy.env` (mode 600) — never paste it into files,
commits or chat output. Load it and call the API with the `x-api-key` header:

```bash
set -a; . ~/.claude/secrets/dokploy.env; set +a
curl -s -H "x-api-key: $DOKPLOY_API_KEY" "$DOKPLOY_URL/api/project.all"
```

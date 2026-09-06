<!-- ak:managed:start — do not hand-edit inside these markers; /ak:learning and /ak:coaching
     keep this block in sync with the workspace. Anything outside the markers is yours, untouched. -->
## ak — requirement-first delivery pipeline

This repo is tracked by `ak`. Every ticket — bug, feature, refactor — goes through the same chain;
Risk decides how much of it is a hard stop versus a fast pass-through.

- **Project:** [Project Name] (`[project-slug]`)
- **Workspace (outside this repo):** `[workspaces-root]/[project-slug]/` — domain knowledge,
  worklogs, and per-ticket evidence live there, not in this repo. Read `PROJECT.md` and
  `domain-knowledge/` there before assuming this file has the full picture.
### Convention

- **Language:** talk to the user in [locale]. Code, identifiers, comments, and commit messages
  stay in English regardless — this split doesn't change per ticket.
- **Minimal diff:** change only the lines the ticket actually requires. Don't reformat, reorder,
  or "clean up" adjacent code in the same edit — that's a separate, explicitly-requested task.
- **Comments explain WHY, never WHAT.** A comment describing what the next line does is noise;
  clear naming already says that. Only write one for a non-obvious constraint or workaround.
- **Git stays manual.** Never run `git commit`/`git push` on your own initiative — propose the
  change, let the user say when. Confirm the target branch out loud before committing to it.
  **Force-push (`--force`/`-f`/`--force-with-lease`) is absolutely forbidden on your own
  initiative, no exception** — only ever when the user explicitly asks for it, in those exact
  words, that specific time; a prior yes never carries over to the next push, even later in the
  same session. Never push directly to a protected branch (`main`/`master`, or whatever this repo
  protects) even when asked — land it through a feature branch and a PR instead.

### Start a ticket

```
/ak TICKET-ID <tracker link>        one command — analyzes once, asks once, runs to the first
                                     real stop, hands off to ship/audit when it reaches the end
/ak:status TICKET-ID                where does this ticket actually stand right now
/ak:<stage> TICKET-ID               call one stage directly for manual step-by-step control
```

### The chain

```
spec → clarify → confirm → plan → build → review → [fix] → test → check → ship → audit
                     ▲                        │
              you confirm here          only if review
              before any code            found something
```

`confirm` and `audit` are the only two stops that need a human decision — every stage in between
runs on its own for Risk P1/P2 (normal-behavior and small changes); Risk **P0** (money, permission,
PII, migration) is the one tier that hard-gates every stage, no shortcuts. `fix` only runs when
`review` left something open.

### Also available (not part of the chain, called when needed)

| Command | For |
|---|---|
| `/ak:learning` | First time in this project — AI builds domain knowledge from a brief |
| `/ak:coaching` | Business rule changed, or AI's understanding was wrong |
| `/ak:decompose` | Request is really an epic — split into child tickets first |
| `/ak:clean` | Archive a finished ticket's worklog |
| `/ak:feedback` | Something about `ak` itself misbehaved — files an issue against the plugin |
| `/ak:flow-diagram` | Reconstruct a bug/UI-flow as a plain-text diagram, no back-and-forth |

Full stage-by-stage reference, gate definitions, and Risk rules live in the `ak` plugin itself
(`references/stage-contract.md`, `references/risk.md`) — this block stays short on purpose; don't
duplicate that reference here, it goes stale the moment either file changes.
<!-- ak:managed:end -->

# Use ak

**English** · [Tiếng Việt](USER-GUIDE.vi.md) · [日本語](USER-GUIDE.ja.md)

## Start a task

Install for your host, then open the product repo. Use `/ak` with a task or select ak's
start skill. [Installation guide](INSTALL.md)

```text
/ak Fix export so it retains the selected filters
/ak TICKET-123 https://tracker.example/TICKET-123
```

A tracker ID is optional. When worklog persistence is needed, ak can derive an
`adhoc-…` ID. It answers read-only questions without making a ticket worklog.
If a task needs a decision, reply in the same conversation. When work spans independently
deliverable pieces, ak presents a split for approval and works through child tasks in order.

## First use in a project

ak reads relevant repo instructions, manifests, scripts, CI and entry points. It fills
`~/.workspaces/<slug>/PROJECT-FORM.md` with reusable facts such as module locations,
commands and their working directories. It asks which working conventions you want it
to follow. If an example comes more easily, describe a recent task or what you expect
before handoff. The agent shows candidate rules with triggers and scope. Agree to save them,
or skip and continue the task.

The existing `PROJECT.md` maps repositories to the workspace. Each project form separates
repo facts with sources from owner-confirmed rules. Unknown fields can be left open until
needed. Future tasks read the relevant entries and refresh only what is missing or stale.
A one-task exception stays with that task. Use `/ak:learning` to explicitly refresh a topic
or discuss a lasting rule, and `/ak:coaching` for domain knowledge corrections.

## What happens during the task

| Phase | What ak does |
|---|---|
| Understand | Read the requirements and relevant code once. Determine Type, Risk, scope and acceptance criteria. Ask about decisions that affect the implementation. |
| Implement | Apply the plan. For behavioral changes, capture a regression and passing result where runnable. |
| Verify | Review the actual diff, fix justified findings, then run the appropriate checks. Reuse a recorded run when the command, inputs, current source and assertions match. |
| Hand off | Report the changes, evidence and any blocker. The default endpoint is G8, ready for review. |

UI bugs require live browser reproduction before editing. Every UI ticket requires a
passing browser assertion on the tested source. Visual changes also require a passing
comparison with an approved screenshot baseline. Missing access or a failed required
check blocks the corresponding gate. [Browser verification](../references/ui-verification.md)

## Decisions and release preparation

P0 covers money, authorization, PII, legacy data changes and irreversible migrations. It
requires security notes, the user's and PM's G3 decisions before editing, and native test
verification. Clear P1/P2 tasks can proceed without a separate G3 round trip during routine
delivery. `--strict` enforces all included gates.

Request `--ship` to continue to applicable release controls and audit in the same flow.
This path applies strict G9 verification and needs G3. If requested at task intake, ak
collects G3 before editing. P0/P1 releases also require AUDIT. P2 may omit it with a
recorded reason unless the project or user requires it. Release preparation does not grant
permission to push, merge, or deploy.

```text
/ak TICKET-123 Prepare for release --ship
CONFIRM G3: TICKET-123 <name> <YYYY-MM-DD>
CONFIRM G3-PM: TICKET-123 <PM name> <YYYY-MM-DD>
AUDIT CONFIRM: TICKET-123 <name> <YYYY-MM-DD>
```

The agent records the decisions that actually apply. G3 and the P0 PM line go in INDEX and
the human confirmation file with provenance. Audit signs off on coherence across the worklog
after strict G9, including whether rollback addresses the migration described.

## Commands when you need them

| Command | Use |
|---|---|
| `/ak` | Start or resume a task |
| `/ak:learning`, `/ak:coaching` | Refresh the form or correct domain knowledge |
| `/ak:decompose` | Propose an epic split separately |
| `/ak:spec`, `/ak:clarify`, `/ak:confirm`, `/ak:plan` | Control one requirements or planning step |
| `/ak:build`, `/ak:review`, `/ak:fix`, `/ak:test` | Control one implementation or verification step |
| `/ak:check`, `/ak:ship`, `/ak:audit` | Run checker, prepare release, or check coherence separately |
| `/ak:status`, `/ak:clean` | Inspect progress or archive an eligible worklog |
| `/ak:feedback`, `/ak:flow-diagram` | Report an ak issue or reconstruct a UI flow |

Worklogs are isolated under `~/.workspaces/<slug>/worklogs/<ticket>/`. The command ledger
is in `06b-test-evidence.md`. The other artifacts reference it and retain checker fields.
`/ak:clean` defaults to archive and requires G9 unless explicitly forced. Purge needs
confirmation.

## Gates and CI

Use the [stage contract](../references/stage-contract.md) and [risk rules](../references/risk.md)
for the field requirements. Run a check from the appropriate workspace:

```bash
"$AK_PLUGIN/bin/check-gates.sh" TICKET-123 --project my-app --min G8
"$AK_PLUGIN/bin/check-gates.sh" TICKET-123 --project my-app --min G9 --strict
"$AK_PLUGIN/bin/check-gates.sh" TICKET-123 --project my-app --min AUDIT --strict
```

Use `--json` in automation and make the worklog and cited evidence accessible to the runner.
The [CI template](../templates/ci/github-actions-ak.yml) and [pilot template](../templates/pilot-metrics.md)
are available for teams that want enforcement or adoption metrics. See [install troubleshooting](INSTALL.md#troubleshooting)
for discovery and workspace setup.

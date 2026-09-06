# Vocabulary — Command, Skill, Reference, Template

Four building blocks make up `ak`. Every stage is one **Command** paired with one **Skill**; both
draw on the shared **References** and read/write the shared **Templates**. Keep these four terms —
they name four different files with four different jobs, and collapsing them into one word (e.g.
calling everything "lệnh") loses that distinction.

| Term | Lives in | What it is | Who reads it |
|---|---|---|---|
| **Command** | `commands/ak.md`, `commands/ak:<stage>.md` | The slash-command entry point — argument shape, one-line description, which Skill it invokes | Claude Code's command picker; the human typing `/ak:spec` |
| **Skill** | `skills/<stage>/SKILL.md` | The actual instructions the AI follows to run that stage — steps, refusals, which References to load | The AI, while executing the stage |
| **Reference** | `references/*.md` | Shared rules more than one Skill needs — loaded on demand, not copied into every Skill file | The AI, pulled in by a Skill's own "Read `references/x.md`" line |
| **Template** | `templates/*.md` | The worklog file shape a Skill fills in per ticket (`02-spec.md`, `06-review-qa.md`, …) | The AI (fills it), the human (reads the filled result) |

## Why the split

A Command is deliberately thin — argument parsing and a pointer, nothing else — so the same
argument shape works across hosts (Claude Code, Cursor, Codex) without duplicating instructions per
host. The Skill is deliberately the only place instructions live, so there is exactly one version
of "how `:review` works," not one per host. References exist because several Skills need the same
rule (`risk.md`'s P0/P1/P2 lanes govern `spec`, `plan`, `check`, `ship` alike) — inlining it into
each Skill would mean four places to keep in sync instead of one. Templates exist because the
worklog is the actual deliverable a human reads later; the Skill's job is producing a correctly
filled Template, not inventing its own ad hoc output shape each time.

## Current inventory

- **Commands + Skills**: 19 paired stages — see `STRUCTURE.md` for the full list and
  `references/stage-contract.md` for what each one requires/produces/routes to next.
- **References** (loaded on demand, not all at once):
  `workflow.md` (gate table + stage order), `stage-contract.md` (authoritative routing),
  `skill-quality.md` (evidence bar every Skill must meet), `risk.md` (P0/P1/P2 lanes),
  `security.md` (P0 security requirement), `maturity.md` (quality rubric),
  `enforce.md` (checker flags), `project-root.md` (path resolution),
  `learning.md` / `coaching.md` (domain-knowledge stages), `clarify-check.md` (conflict detection),
  `ba-integrity.md` (honest-analysis contract), `epic-signal.md` (when a request is epic-shaped),
  `code-review.md` (neutral review + fix triage), `ui-evidence.md` (highlight-box + before/after
  screenshot technique), `tracker-fetch.md` (Redmine link → real ticket content),
  `audit.md` (semantic coherence pairs),
  `locale.md` (reply in the user's language), `workspace-health.md` (workspace layout checks),
  `task-isolation.md` (one worklog per ticket), `pilot.md` (measurable-proof ops),
  `feedback.md` (filing a bug about `ak` itself), `flow-diagram.md` (bug/UI-flow diagram format).
- **Templates**: `INDEX.md` (ticket dashboard) plus one file per worklog artifact
  (`02-spec.md` … `08-semantic-audit.md`, `02-spec.md`'s own Intent section replaces what used to
  be a separate `01-intent.md`), `02b-security.md` (P0 only), `03b-human-confirm.md` (anti-forge
  confirm), `pilot-metrics.md`, `ci/github-actions-ak.yml`, `CLAUDE.md` (the one template that
  doesn't land in a worklog — `:learning` seeds/updates it straight into each product repo's own
  root, inside a marked block it never overwrites the rest of), plus the `domain-knowledge/` and
  `workspaces/` scaffolds a new project starts from. Kept deliberately short — a checklist that
  restates what `check-gates.sh`/`references/workflow.md` already decide isn't a template, it's
  paperwork nobody fills.

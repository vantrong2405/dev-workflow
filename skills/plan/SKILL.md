---
name: plan
description: >-
  Break spec+clarify decisions into small tasks with DoD/tests when they exist;
  self-analyzes the ticket directly when they don't. Use /ak:plan standalone
  or after spec/clarify.
argument-hint: "[Ticket ID] Uses confirmed spec+clarify scope if present, else self-analyzes the ticket — write a TDD-ready implementation plan into the worklog. Ticket ID optional, derived if omitted"
arguments: [ticket_id]
disable-model-invocation: false
---

# /ak:plan

Apply `references/skill-quality.md`; this stage owns an executable traceability plan, not plausible prose.

## Precondition

Use the project locale from `references/locale.md`.

No Ticket ID given → follow `references/task-isolation.md` "No Ticket ID given": proceed with
this stage normally; only derive an `adhoc-<slug>` worklog name once a decision actually needs
persisting, not before.

Use the investigation already completed by `/ak`. Read its spec, decisions and applicable
project form entries. Prefer the form's candidate test command and working directory, and
resolve the actual task-specific check. A checker PASS with warnings does not prove G3
approval. If a material claim is still open or required approval is missing, return that
blocker. When called directly without spec/clarify, self-analyze as needed and label the
plan `Source: self-analyzed (no upstream spec/clarify)`.

## Steps

Create the implementation plan from the available scope and record its provenance.
Fill `templates/04-plan.md` for the ticket.
Each task must map to AC/claim, target repo/path, DoD, and test command.

For UI tickets specify the browser scenario and its assertion. For visual changes
identify the existing approved baseline or plan how to get approval for a new one.
Specify the comparison command and result to capture per `references/ui-verification.md`.

**Task granularity should match the ticket's `Type:`** (see INDEX.md, set at `:spec`):
- **Bug** — usually one focused task at the root-cause location found in `:clarify`; resist
  splitting a single-file fix into multiple tasks just to have more rows.
- **New feature** — one task per layer touched (migration/model, service/operation, controller,
  view, tests), following the insertion points identified in `:clarify`'s survey — do not
  collapse a multi-layer feature into one giant task with no per-layer DoD.
- **Spec change** — one task for the primary behavior change, plus **one task per affected
  consumer** found during `:clarify`'s "trace every consumer" step — each consumer's update needs
  its own DoD/test so a fixed one isn't silently forgotten.
- **Requirement change** — one task per place the rule was found encoded (`:clarify` should have
  listed them) — do not bundle "update the rule everywhere" into a single task; each encoding
  needs its own test proving the new value took effect there specifically.

**Test command must be a real, runnable command** — `bundle exec rspec spec/operations/companies/job_delete_spec.rb`,
not "add tests for this". `check-gates.sh` G4 only verifies the column isn't blank, not that the
command is real; that gap is yours to close as the plan's author, not the checker's — a plan task
with a fake-sounding command passes the machine gate and still leaves `:build` with nothing
concrete to run.

Print uncovered AC/claim gaps; gaps block next stage.
Do not enter build here and do not invent tasks beyond confirmed decisions.

## 9/10 controls

Resolve every test path/repo and perform a non-destructive runner discovery check (`--list`, dry-run,
or an existing neighboring command). If that cannot be checked, label it `UNVERIFIED`, name the
missing dependency, and keep G4 FAIL.

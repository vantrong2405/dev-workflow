---
name: build
description: >-
  TDD then implement. Uses plan/spec/clarify decisions when they exist; self-analyzes
  the ticket directly when they don't. Use /ak:build standalone or after plan.
argument-hint: "[Ticket ID] Uses confirmed plan if present, else self-analyzes and calls :plan first — implement with TDD and log claim↔test mapping in the worklog. Ticket ID optional, derived if omitted"
arguments: [ticket_id]
disable-model-invocation: false
---

# /ak:build

Apply `references/skill-quality.md`; this stage owns scoped RED→GREEN evidence at the smallest responsible seam.

## Precondition (check before writing a single line of production code)

A Senior dev handed a ticket checks the spec is confirmed before opening an editor — do the same
here, but "checks" doesn't mean "refuses to start without one already on file":

0. Use the project locale from `references/locale.md`.
   For UI work, resolve the UI flags and required evidence from
   `references/ui-verification.md`. A UI bug needs a real G5 PASS after browser
   reproduction before edits, even when invoking this skill directly. Bring a
   legacy UI spec up to the guided QA format and reuse any matching real evidence
   before requesting new reproduction.
1. Run the installed `bin/check-gates.sh <Ticket> --project <slug> --min G5 --require-plan-review`.
   If a UI bug lacks its reproduction, use `:spec` and `:clarify` to record it.
2. Use the existing plan when in scope and genuine decisions are resolved. A relaxed PASS
   with warnings does not satisfy a missing required approval.
3. If it FAILs because `04-plan.md` doesn't exist yet (standalone `:build` call, no `:plan` run),
   **invoke `:plan` yourself** first — per the composition model, `:build` pulls in the stage it
   needs rather than improvising an implementation with no recorded task breakdown. `:plan` itself
   self-analyzes the ticket when spec/clarify are also missing, so this still works with zero
   upstream artifacts; it just means every task/decision downstream gets marked
   `Source: self-analyzed (no upstream artifact)`.
4. If it FAILs because a plan exists but a clarify claim is still OPEN/unconfirmed, surface that
   gap and prefer routing to `:clarify`/`:confirm` over silently guessing the decision — this is
   the one case where "self-analyze and continue" is the wrong call, since a real open question
   was already raised and left unanswered, not simply skipped.
5. If the plan review is missing, unresolved or stale, run `:redteam`, revise through
   `:plan`, and recheck G5 with `--require-plan-review` before editing. This applies
   to standalone and resumed builds. Begin edits after the required check passes.
   Record task progress in the implementation log.

## Steps

Implement from a plan — either the confirmed one on disk, or the one `:plan` just produced
(confirmed or self-analyzed) per the precondition above.
Read `references/task-isolation.md` — log **only** into `worklogs/<Ticket_ID>/` for this ticket.
No Ticket ID given → follow `references/task-isolation.md` "No Ticket ID given": proceed with
this stage normally; only derive an `adhoc-<slug>` worklog name once a decision actually needs
persisting, not before.
Print `project=… ticket=<id-or-adhoc-slug-or-empty>… worklog=… locale=…` at start.

**Use TDD for behavior changes with an executable test surface.** Per task in `04-plan.md`: write the
failing test from that task's test command first, run it and confirm it fails for the stated
reason (not a setup/syntax error), then implement the minimum to make it pass. This cycle applies
whether or not any other skill is present in the session — do not skip or water it down on a repo
that lacks extra tooling. Log AC/claim-to-test mapping in `templates/05-impl-log.md` under **this**
worklog, using its exact bullet headers (`**RED command + failure excerpt:**`, `**Why RED proves
the missing behavior:**`, `**GREEN result:**`) — `check-gates.sh` looks for those literal phrases,
so paraphrasing them (e.g. "RED evidence:") passes on content but fails the gate on wording.

For copy/docs/config, record the appropriate check. For a refactor use the existing acceptance
baseline. If a RED run is inapplicable, record the reason and the actual check. Record executions
in the shared ledger per `references/execution-evidence.md`; cite run IDs in the implementation
log. Return the stage result to `:start` when invoked inside that flow.

**Watch for RED-for-the-wrong-reason on validation-throwing functions specifically.** When a task
adds a function that validates by throwing (`TypeError` on bad input, etc.), the *first* RED run
before the function exists at all can throw a "not a function" / reference error that happens to
satisfy `assert.throws(SameErrorType)` — the test goes red, but not because validation ran and
caught something; it's red because the function is missing. Read the RED failure's actual message,
not just its color, before writing "why RED proves the missing behavior" — a coincidentally-typed
error is not proof the validation logic exists yet.

Use the plan's accepted behavior and tests for the RED→GREEN cycle above. If you
need additional TDD technique guidance, consult the vendored `tdd` examples for
test design and refactoring. Existing requirements and plan decisions carry forward.
Fill **Commit SHA** at the top of `05-impl-log.md` with the real commit the PASS claim is made
against — required for P0/P1/`--strict`, same bar as G8's test evidence. A PASS recorded with no
SHA, or against a stale one, is not verifiable evidence.
Do not edit another ticket’s impl log or reuse its PASS marks.
Run `/ak:check <Ticket> [slug] G6` before any G6 PASS claim.
Coverage gaps, failing tests, or missing/stale Commit SHA keep build FAIL.
Never invent PASS; never invent a confirmed decision — a self-analyzed plan may proceed to code,
but a clarify claim someone already flagged OPEN may not be silently resolved by `:build`.
Chat in user language (`references/locale.md`).

## 9/10 controls

For every task record the RED command/failure, why it proves missing behavior, GREEN command/result,
and files changed. Existing-green tests do not prove TDD. New scope or a contradicted confirmed claim
routes upstream; never edit AC to fit code.

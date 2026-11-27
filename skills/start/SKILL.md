---
name: start
description: >-
  Start or resume a task from one entry point. Learn reusable project setup on first use,
  then understand, implement, verify, and hand off. Continue into release preparation on request.
argument-hint: "<task description | ticket ID + link> [--ship] [--strict]"
arguments: [ticket_id, url_or_path, extra]
disable-model-invocation: false
---

# /ak

Read `references/workflow.md`, `references/stage-contract.md`,
`references/skill-quality.md`, and `references/risk.md`. Resolve the installed plugin path
with `references/project-root.md` so checker commands use the plugin's own scripts.
Coordinate the stage owners
through the four phases below. Interpret plain descriptions and tracker references as
input. Treat an explicit request to prepare a release/merge or `--ship` as a request
for release preparation. It does not authorize a Git or deployment action.

## 1. Understand

- If the user only asks a read-only question, answer it with relevant project context.
  Bootstrap during the first delivery task, and create no ticket worklog for the question.
- Resolve the actual project and relevant repo(s) per `references/project-form.md`.
  Load the form or run the scoped `:learning` steps here, including the first-use
  conversation about working conventions. Once confirmed or skipped, resume this
  task in place. If the form already exists, read its relevant entries and refresh
  only missing/stale facts needed now.
- Resolve or derive the ticket ID using `references/task-isolation.md`.
  Reuse the existing worklog and inspect current evidence before repeating a stage.
- Do one investigation for spec, clarify and plan. Establish Type, Risk, concrete
  acceptance criteria, constraints, touched surfaces, duplicate occurrences and
  the relevant checks. Use the Type strategy in `references/stage-contract.md`.
  Read the relevant code and independent sources of intent. Preserve the applicable
  stage artifacts, sharing the same claim and acceptance IDs.
- If `references/epic-signal.md` applies, run `:decompose` in this flow to present
  the split for confirmation. After confirmation, run the first unblocked child in
  its own worklog and continue in dependency order, preserving every child's own
  decisions and checks.
- Proceed on a clear, routine task. Ask together only the unresolved questions
  that change scope, behavior or authority. Ask for required G3 approval before
  edits for P0 or an explicitly strict task. A release request made at intake also
  needs G3 before editing because its release gate is strict. When release is
  requested after a routine handoff, confirm the existing scope before strict G9
  and record the actual approval timing. Use
  `:confirm` to record actual decisions and approvals. Project conventions and
  task approvals are separate.
- Keep documentation and read-only checks proportional. A clear Trivial ticket
  still gets a relevant diff check and a truthful handoff. A behavior-preserving
  refactor uses existing behavior as its acceptance baseline. Neither takes a
  shortcut around a required P0 approval or the requested gate.

## 2. Implement

After drafting the plan, run `:redteam` as a separate review pass. If the review finds a
material issue, return to `:plan` to fix it and recheck the revision. Route changes to
confirmed scope through `:clarify` or `:confirm` when they need a decision. Continue to
`:build` only after the current plan passes the required G4 review.

For a UI bug, use `:clarify` and `:flow-diagram` to prepare data and show one
click-by-click diagram per bug in the current conversation. Let the user reproduce
it or explicitly delegate that run. Resume this same task after an observed
failure is recorded and G5 passes. Read `references/ui-verification.md` for the
evidence and comparison requirements. Report any missing environment or evidence.

Execute the scoped plan through `:build`. For behavior changes prove the regression
and the fix where an executable surface exists. Log each run using
`references/execution-evidence.md`. Preserve unrelated changes. If implementation
reveals a material decision or causes a risk escalation, pause for that decision,
then resume here.

## 3. Verify

Use `:review` for a fresh review of the diff. Route justified findings through
`:fix` and revisit the affected parts of the review. Use `:test` for final
acceptance evidence and the project form to resolve commands and working
directories. Reuse a recorded run only if it covers the required command,
assertions and current source state. Run missing, newly applicable or stale
checks. A passing test never substitutes for review.

Run the real checker through G8 and inspect its verdict and warnings. Apply strict
verification when requested and the hard conditions for P0. An open P0/P1 review
finding, failed test, or missing required check blocks a verified handoff even
if a relaxed gate renders a warning. Surface the exact blocker and available
evidence. Never claim a commit was verified when evidence only covers local edits.

## 4. Hand off

Summarize what changed, what was verified and what remains. Default delivery ends
at the verified result for review. When release preparation was requested, continue
automatically through `:ship` and applicable `:audit`. Prepare the relevant rollout
or publication controls before asking for any required decision or sign-off. Use
the same task and worklog when resuming. Record a justified P2 audit skip only when
allowed by `references/risk.md`. Push, merge and deploy require separate explicit
authority. Archiving is available when requested.

Inside this flow, each stage returns its output here. Use internal names and the
next command only when useful for diagnosis; the user can resume by replying.

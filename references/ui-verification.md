# Required browser verification

For a ticket with `Touches UI? Yes`, test the affected behavior in a running browser.
Use Playwright when present in the repo or available through the agent. If the project
uses another browser runner or DevTools, use that and record which one ran. Missing app
access, test data or tooling is a blocker for the corresponding check. Report the missing
piece instead of recording a PASS. Non-UI tickets use their relevant checks.

## Before edits for a UI bug

During `:clarify`, prepare the test environment, starting URL, viewport, locale, actor, and
fixture. Use `:flow-diagram` to show exact screen labels, clicks, inputs, URLs, and the expected
and failing outcomes in chat. Prefer English UI when supported unless the bug is tied to a
specific locale. Keep the chosen locale for both runs. Save one diagram per distinct bug as
`evidence/ui-repro-bug-01.md`, `evidence/ui-repro-bug-02.md`, and so on.

Let the user run the steps and send back what happened, the actual URL, and a screenshot or
recording. If they delegate the run, use Playwright or the project's browser tool. Record who
ran it and cite the user's report or delegation. A manual run can use a saved record of the
user's actual observations for its log. Keep credentials and personal data out of the record.
If the bug does not reproduce, capture that result and diagnose the difference.

Create `evidence/ui-verification.json` from `templates/ui-verification.json`. Map cases to the
spec's QA handoff table. The `Reproduction bug` column points to the numbered diagram or is
`No` for a case that needs only final verification. Record the fixture identifier or concrete
setup for each case. Fill `before.result` with `REPRODUCED` only for an observed failure.
Record `before.performed_by` as `user` or `agent` and cite the actual report or delegation
in `before.confirmation`.

Run the checker through G5 before editing the affected code. A missing diagram or observed
reproduction fails G5 at any risk tier, including standalone `:build`. If code was already modified, recover
the actual before state from an isolated checkout where possible. Keep existing changes
and do not recreate an image or execution log from memory.

## After edits for every UI ticket

Run every case in the QA handoff. Repeat reproduced scenarios with the same start URL,
viewport, actor, locale, data, and steps. Check an
explicit assertion tied to the acceptance criterion. For example, verify both that a popup
appears and that scroll position does not move. Capture the result, record the logs, and
fill the `after` run with `PASS` only when the assertion succeeds. For a new feature,
omit `before`. The shared case fields identify the context for both runs.

Use ISO 8601 timestamps with timezone and the result of `bin/source-state.sh` for each
tested checkout. The before and after runs for bugs need different source states, ordered
timestamps, and separate captures and logs. Put artifacts under the ticket's `evidence/`
directory and use worklog-relative paths. Keep account names anonymized and omit passwords
and tokens. Attach the manifest and the execution record to `06b-test-evidence.md`.
The checker compares `after.source` to that file's verified `Tested source` and requires
`Evidence checkout` for G8.

## Golden comparison for visual changes

In `02-spec.md`, select `Visual change? Yes` when the intended result changes layout,
styling, or the appearance of a component. A behavior-only fix can select No, such as
keeping scroll position when a popup opens without changing how the popup looks.

For each case marked `Visual comparison: Yes` in the QA handoff, run an automated comparison against an approved screenshot
baseline. Reuse the repo's visual tests or add the smallest comparison for the affected
case using the available runner. Record the baseline's source or the user's approval, the baseline copy, the
actual comparison command, exit code, tested source, and the runner's JUnit report with the exact
passing test case name. The baseline must be separate from the before/after captures.
Omit `golden` for a behavior-only case.
If a new or revised baseline is needed, show it for approval and then run the comparison.
Do not update a baseline simply to turn a failing comparison green.

G8 blocks on missing or failing required UI evidence at any risk tier. The validator
checks artifact presence and format, run ordering, tested source, and golden JUnit
results. Review the actual behavior and visuals alongside those records.

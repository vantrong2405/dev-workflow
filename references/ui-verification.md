# Required browser verification

For a ticket with `Touches UI? Yes`, test the affected behavior in a running browser.
Use Playwright when present in the repo or available through the agent. If the project
uses another browser runner or DevTools, use that and record which one ran. Missing app
access, test data or tooling is a blocker for the corresponding check. Report the missing
piece instead of recording a PASS. Non-UI tickets use their relevant checks.

## Before edits for a UI bug

During `:clarify`, open the app in a dev or test environment. Follow the exact reported
steps and observe the wrong result. Use a reproducible URL, viewport, test actor, locale,
and fixture data. Capture the failing state and its logs. Create
`worklogs/<ticket>/evidence/ui-verification.json` from `templates/ui-verification.json`.
Set the acceptance ID and expected outcome, and fill the `before` run with `REPRODUCED`.

Run the checker through G5 before editing the affected code. A missing reproduction fails
G5 at any risk tier, including standalone `:build`. If code was already modified, recover
the actual before state from an isolated checkout where possible. Keep existing changes
and do not recreate an image or execution log from memory.

## After edits for every UI ticket

Repeat each scenario with the same URL, viewport, actor, locale, data, and steps. Check an
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

For each affected visual case, run an automated comparison against an approved screenshot
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

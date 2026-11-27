# 06b Test Evidence: [Feature_Name]

- **Ticket:** [ID]
- **Touches UI?** ☐ Yes ☐ No (copy from `02-spec`)
- **Risk:** ☐ P0 ☐ P1 ☐ P2

## Machine evidence (required for P0/P1 and `--strict`)

| Field | Value |
|---|---|
| Commit SHA | [40-char or short SHA] |
| CI run URL | [https://… or N/A-local] |
| JUnit / XML / log path | [local path (optional with CI run URL)] |
| Branch | [name] |
| Tested source | [commit:sha or worktree:hash] |
| Evidence checkout | [absolute Git checkout path] |

**Forbid G8 PASS** when any required machine field is empty/`[…]` placeholder (P0/P1/`--strict`).

## Test run output

Paste raw output (or representative excerpt) from test runner here.

```
# paste test runner output here
```

## Executed-command ledger

Record each execution once. Cover every planned check and any PASS referenced by the
implementation log, with current results for final verification.

| Command | Repo / cwd | Started / ended | Exit | Artifact | Covered IDs | Supersedes | Run ID | Source state |
|---|---|---|---|---|---|---|---|---|
| | | | | | | N/A | | |

## Assertion evidence

| ID | Test path:line / assertion | Failure proved before fix | Passing result after fix |
|---|---|---|---|
| AC-01 | | | |

## Screenshots / recordings

For any UI-touching AC: capture per `references/ui-evidence.md` (highlight box on the exact
element, before/after pair for a bug fix) — not a plain unmarked screenshot. Leave N/A if no UI.
For UI tickets, also record the validated cases and capture paths in
`evidence/ui-verification.json` using `templates/ui-verification.json`.

| AC / scenario | File / URL | Notes |
|---|---|---|
| AC-01 | | |

## Failing / passing summary

One row per test suite. G8 FAIL if any suite has failures.

| Suite | Total | Passed | Failed | Skipped | Result |
|---|---|---|---|---|---|
| Unit | | | | | ☐ PASS ☐ FAIL |
| Integration | | | | | ☐ PASS ☐ FAIL |
| E2E | | | | | ☐ PASS ☐ FAIL |

**Overall:** ☐ PASS (zero failures) ☐ FAIL (see failing rows above)

## Sign-off

- **Dev:** [name]
- **G8 verdict:** ☐ PASS ☐ FAIL

**Forbid G8 PASS** when any suite has failures or the evidence table is empty.

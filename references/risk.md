# Risk tiers and enforcement

Set exactly one Risk in the ticket INDEX and spec. Choose in this order:

| Risk | Use for | Enforcement |
|---|---|---|
| P0 | Money, authorization, PII, legacy data changes, irreversible migration | Hard gates through the requested endpoint. Require security notes, named user and PM G3 approvals before edits, and native test verification. No G3 or G8 waiver. |
| P1 | Other user-visible behavior and API contract changes | Fast lane for routine delivery. Require acceptance criteria and real machine evidence. |
| P2 | Copy, docs, configuration and other changes without behavior changes | Fast lane for routine delivery. Verify with the appropriate checks for the touched surface. |

Inspect touched paths/contracts before classification. Auth/payment/PII or migration paths can
make a small diff P0. When uncertain after checking the relevant sources, default to P1.

## Fast lane

The checker softens G2/G3/G4/G5/G7 for P1 and P2 without `--strict`. G0/G1/G6/G8/G9
are hard when included in the requested minimum. The default handoff at G8 needs no G3 round trip
on a clear fast-lane ticket. An open decision that changes the work or an unresolved P0/P1
review finding still blocks a verified handoff. An explicit OPEN P0/P1 review finding fails
G7 even when the surrounding gate is relaxed.
Unresolved material claims at G2 and recorded open questions at G5 fail hard.
The required UI diagram and browser reproduction at G5, and browser or golden evidence
at G8, also fail hard.
UI verification cannot be waived. See `ui-verification.md`.
The G4 redteam requirement also fails hard for active delivery. Use
`--require-plan-review` before build, including with a legacy plan. Historical worklogs
without a review protocol remain readable through the normal checker.

`--strict` makes the soft gates hard again, disallows G8 waivers, and enables native evidence
checking. If strict is requested up front, gather G3 approval before implementation.
Record permitted waivers in INDEX as `Gate/claim | reason | owner | expiry | PM note`.
Do not create a waiver just to work around a missing approval or missing evidence.

## Trivial work and refactors

For a P2 change estimated at one file and at most five lines, with unchanged public identifiers
and a clean duplicate scan, keep artifacts concise. Do the relevant verification and handoff.
If the duplicate scan finds another occurrence and intent is unclear, ask whether it belongs
in scope. Five lines is an initial size heuristic. Risk and the affected surface take priority.

For a behavior-preserving refactor, state the acceptance baseline and use existing coverage.
An observable behavior change uses its actual Type. Neither the small change nor the refactor
classification overrides P0 or strict requirements.

## Release preparation

The default task endpoint is G8. For requested release preparation, require `--min G9 --strict`
for all tiers. Require a human-confirmed AUDIT for P0 and P1. For P2, audit can be omitted with
a reason in the ship record unless the user or project requires it. If AUDIT is explicitly
requested, check all C1–C8 and require human sign-off regardless of risk.
Preserve the evidence and explain any blocked release requirement. Preparation does not confer
permission to commit, push, merge or deploy.

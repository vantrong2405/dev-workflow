---
name: redteam
description: >-
  Challenge an implementation plan before code changes. Look for counterexamples,
  unsupported assumptions, downstream impact, and missing verification. Recheck
  revisions and record whether the current plan can proceed to build.
argument-hint: "<Ticket ID> Review the proposed implementation plan as an adversarial reviewer"
arguments: [ticket_id]
disable-model-invocation: false
---

# /ak:redteam

Read the ticket's `04-plan.md`, acceptance criteria, clarify decisions, and the code
or project rules the plan relies on. Keep the review scoped to the ticket. Use the
project locale and write to `04b-plan-review.md` from the matching template. Keep
the template's field names, heading and status values for the checker. If the draft
is missing, route to `:plan` and review it once it exists.

For a plan with a `Vibe implementation mapping` section, read its referenced business
diagrams, design record, mockup manifest and approvals. Use `templates/vibe/redteam.md` as the Vibe review
appendix and record actual findings in the standard Counterexamples table. Verify that the
current screen controls, business branches and runnable checks agree with each other.

## Review in opposition

Start from the premise that the plan could be wrong. Trace a concrete case that
would make it fail even if the proposed patch and listed tests work as planned.
Use a fresh reviewer agent if the host supports it and delegation is authorized.
Give that reviewer the proposed plan, requirements and repo evidence, without
the planner's defense. Otherwise take a distinct review pass in the same session
and record `same-session`. Record `separate-agent` only when a separate reviewer ran.

Probe these areas in proportion to the change:

1. **Assumptions and scope.** Trace the proposed path from the real caller.
   Check whether the plan fixes the cause, touches unrelated behavior, or assumes
   a contract the spec or code does not establish.
2. **Impact.** Follow other callers or shared data. Where applicable, try old
   records, restricted actors, retries, partial failures or rollback. Name which
   users, flows or components would be affected and rate the potential severity
   as `P0`, `P1`, or `P2` using `references/risk.md`.
3. **Verification.** Ask whether the listed checks could pass while the user still
   sees the bug. Challenge missing negative or regression cases, test data and
   environments. For UI, check the browser assertion and the golden comparison
   when appearance changes.

Record concrete counterexamples, including ones ruled out by evidence. Cite the
acceptance ID, file or command that supports each challenge. Record material
unresolved findings as `OPEN`, cases disproved by evidence as `CLEARED`, and
plan corrections rechecked on the current revision as `FIXED`. One grounded
challenge can be sufficient for a small change.

## Decide and route

- Return `REVISE` with the smallest required plan changes if a material finding
  remains open. Hand the changes back to `:plan`; use `:clarify` or `:confirm`
  if they change a requirement or require a decision. The reviewer does not edit
  product code. Recheck the revised plan before returning PASS.
- On PASS, record `Plan review state` from
  `bash "$AK_PLUGIN/bin/plan-review-state.sh" "<worklog>"`. This includes the plan,
  spec and clarified decisions. G3 checks signatures separately. All recorded
  challenges need a grounded resolution. Run the installed
  `bin/check-gates.sh <Ticket> --project <slug> --min G4 --require-plan-review`
  before announcing build readiness. If another prerequisite fails, report that
  gate and return control to its owning stage.
- Summarize the most consequential challenge, its impact and how the final
  plan addresses it. The routine `/ak` coordinator continues to build after PASS.

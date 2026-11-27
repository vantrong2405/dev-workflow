# Task workflow

Start or resume with `/ak <task>`. The four phases are **Understand → Implement → Verify →
Hand off**. Named commands are available for manual use and recovery. Stage requirements and
ownership live in `stage-contract.md`.

1. **Understand.** Resolve the repo. On first use, follow `project-form.md` and continue after
   the convention interview. Use one investigation for spec, clarify and plan. Carry the same
   acceptance IDs and decisions forward. Ask only about material unknowns or required approvals.
   For a UI bug, prepare data and a `:flow-diagram`, then record the user's or delegated
   browser reproduction before editing.
   After drafting the plan, run `:redteam` to challenge assumptions, scope, impact, and tests.
   Revise supported findings and recheck the plan before implementation.
2. **Implement.** Build within scope. Record tests as they run in the ticket ledger.
3. **Verify.** Review the diff, fix justified findings, and verify acceptance criteria on the
   current code. Reuse eligible runs under `execution-evidence.md`. Run the checker through G8.
4. **Hand off.** Report the verified result or concrete blockers. If release preparation was
   requested, continue through G9 and applicable AUDIT, resuming after any required decision.
   External actions require explicit authority.

A stage called inside `:start` returns its verdict and artifacts to the coordinator. Standalone
stages report the verdict, missing evidence and one next action. Keep chat in the project language
and retain the literal checker field names. Keep worklogs isolated per `task-isolation.md`.

## Gates and dispatch

| Gate | PASS means | Owning stage |
|---|---|---|
| G0 | Project mapping and ready form, or valid legacy workspace index | learning |
| G1 | Type, Risk, sourced AC; P0 security and UI verification criteria when applicable | spec |
| G2 | Conflicts investigated and resolved | clarify |
| G3 | Required human decision recorded in both places, including PM for P0 | confirm |
| G4 | Plan maps acceptance criteria to runnable checks and the current revision passes adversarial review | plan / redteam |
| G5 | Required questions resolved and a diagram plus live browser reproduction recorded for UI bugs | clarify / flow-diagram |
| G6 | Implementation and coverage evidence | build |
| G7 | Diff review with acceptance evidence and no open P0/P1 findings | review / fix |
| G8 | Relevant tests for the current code, browser assertions for UI, and approved golden comparisons for visual changes | test / check |
| G9 | Release controls and rollback readiness appropriate to the deployment profile | ship |
| AUDIT | Worklog statements agree on C1–C8 and the user signs off | audit |

The checker verifies structure and machine-readable evidence. Redteam checks the proposed plan,
then review checks the diff after implementation. Audit
checks coherence between artifacts. Each can catch different problems. See `risk.md` for gate
enforcement and sign-off policy.

## Phase grouping

Report the phase in plain language. Use gate numbers when diagnosing failures or on request.
`:status` can continue to show the established Spec-locked (G0–G3), Built (G4–G6), Verified
(G7–G8), and Shipped (G9 plus required AUDIT) groupings. G9 indicates readiness for release,
and actual deployment needs its own evidence.

## Manual operation

Stages remain independently callable. Preferred upstream artifacts can be produced from
self-analysis where the stage contract allows it. Mark that provenance. Resume from existing
evidence and rerun checks that are stale. Human approvals cannot be supplied by self-analysis.
`:learning` can also refresh selected entries, `:coaching` manages shared knowledge corrections,
and `:clean` archives an eligible worklog on request.

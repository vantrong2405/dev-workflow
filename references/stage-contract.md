# Stage contract — single source of workflow truth

This table is authoritative for prerequisites, owned output, blocking conditions, and routing.
Skill descriptions, command tooltips, templates, checker, README, and USER-GUIDE must not contradict
it. Update this file first, then run `tests/regression.sh` to detect contract drift.

`Requires` marked **(preferred)** means the stage runs standalone and self-analyzes the ticket
directly when that artifact is absent — it does not hard-block. Everything else in `Requires` is a
genuine blocker. Worklog artifact filenames renamed with the stage: `03-clarify-report.md`
(formerly `03-conflict-*`).

| Stage | Requires | Owns/produces | Blocks on | Next |
|---|---|---|---|---|
| decompose | epic-shaped request (spans >1 service/repo, mixes ticket Type, or independently shippable parts) | `epic-map.md` (project-level): child tickets + Type/Risk estimate + dependencies + epic-level Q&A, one confirm; dependency graph cross-checked with a duplicate-scan before hand-off | any epic-level question unanswered | first unblocked child's spec/start |
| learning (G0) | identifiable repo or project | reusable project form with sourced facts, locale and confirmed preferences or recorded skip. Optional deeper domain research on request | ambiguous project identity or missing context needed for the current work | resume active task or report form |
| coaching | existing knowledge + (explicit user correction or an answer to an open coaching ticket) | before/after delta, impacted consumers, changelog; self-closes the ticket when the answer doesn't conflict with recorded knowledge | unconfirmed delta/impact | spec or clarify |
| spec (G1) | G0 + ticket input | Type, Risk, AC/NEG/PERM/EDGE, UI oracle | missing type/risk/source; ambiguous requirement | clarify (self-chained) |
| clarify (G2/G5) | G1 + Type (preferred — self-classifies if absent) | type-specific evidence map, claims, Q&A and browser reproduction for UI bugs | NO/UNCLEAR without decision or missing required reproduction | confirm |
| confirm (G3) | G2/G5 decisions visible | exact human phrase/provenance | missing/unauthorized/ambiguous decision | plan |
| plan (G4) | G3 (preferred — self-analyzes ticket if absent) | runnable task/DoD/test mapping | uncovered AC/claim; unresolvable command | build |
| build (G6) | G5 (preferred — calls plan, which self-analyzes, if absent) | per-task RED→GREEN evidence, code, coverage map, SHA | red test for wrong reason; scope drift; uncovered id | review |
| review (G7) | G6 + actual diff | independent findings + AC/side-effect evidence | no diff; OPEN P0/P1; missing evidence | fix or test |
| fix | OPEN findings | triage decision + narrow change + regression proof | unjustified decision; unresolved P0/P1 | review |
| test (G8) | G7 | executed-command ledger + raw/JUnit evidence + SHA, plus browser evidence and approved golden comparisons when applicable | planned command not run, failure, stale or missing required evidence | check |
| check | requested minimum gate | deterministic PASS/FAIL/JSON result | any structural/provenance failure | owning stage |
| ship (G9) | G8 | deployment-profile safety/rollback plan | unsafe migration/rollout/rollback/ownership | audit when required |
| audit (AUDIT) | G9 strict | C1–C8 quotes, verdicts, reasoning, human sign-off | any missing/UNCLEAR/INCOHERENT pair | owning stage |
| status | workspace/ticket selector | read-only state, uncertainty, one next action | ambiguous selector/path | user clarification |
| clean | exact ticket + G9 or explicit force | archive receipt or confirmed purge receipt | broad target; unconfirmed purge | start/status |
| start | task and identifiable repo or project | inline first-use setup, one investigation, implementation, verification and G8 handoff. Continue through G9 and applicable AUDIT when release preparation is requested | unresolved material decision, required approval, failing evidence or genuine access blocker. Use decompose for independently deliverable work | resume the same task after a reply, or report verified handoff |

## Ticket-type strategy dispatch

| Type | Required investigation |
|---|---|
| Bug | Reproduce → real execution path → root cause → sibling path only when same mechanism is evidenced |
| New feature | Closest analog → insertion points → constraints/contracts → negative integration effects |
| Spec change | Exact before/after → every consumer of changed behavior → signed side effects |
| Requirement change | Exact old/new rule → every encoding across code/config/copy/docs/repos → named authority |
| Refactor | State the no-behavior-change claim → confirm existing test coverage → duplicate-scan → plan and verify against the preserved behavior, with approvals as required |

Mixed tickets use claim-level Type. They must not use one strategy for all claims. A ticket mixing
Refactor with any other type is not a Refactor — the moment a claim changes observable behavior it
moves to its real type.

## Entry-point stages (outside the gate sequence)

`start` and `decompose` coordinate stage owners. The default path uses one investigation
for spec, clarify and plan; each owner records its required output. When a stage runs inside
`start`, return its result to the coordinator. Do not interrupt the user with another command,
repeat settled investigation, or stop solely because a stage completed. Standalone commands
still report their own result and next action. See `workflow.md` for the sequence and
`risk.md` for the conditions that require human input.

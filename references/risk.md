# Risk tiers & lanes

Set **Risk** on worklog `INDEX.md` and `02-spec.md` before `:plan`.

## Single source for "skip ceremony"

Three different callers used to each carry their own skip logic (P2 soft-gate here, Refactor
routing in `ba-integrity.md`, a separate "genuinely tiny" fast-path in `start/SKILL.md`). There are
only two independent reasons ceremony can shrink — **Risk tier** (this file) and **ticket Type**
(`ba-integrity.md`'s Refactor section) — so this file is the one place that names both and how they
compose. Every other reference (`start/SKILL.md`, `skills/clarify/SKILL.md`, `skills/confirm/SKILL.md`)
must point here, not restate its own criteria.

| Reason | Trigger | What shrinks |
|---|---|---|
| Risk=P2 | see "How to choose" below | G2/G3/G4/G5/G7 soft (warn, not fail) |
| Type=Refactor | every claim provably behavior-preserving (`ba-integrity.md` "Refactor") | skip spec/clarify entirely, route straight to `:build` |

They stack independently — a P2 ticket that is also a Refactor gets both. `:start`'s step-1
fast-path offer (`skills/start/SKILL.md`) is not a third criterion: it is the same P2/Refactor
determination made early, before the pipeline starts, so the user is asked once instead of
discovering the soft-gate stage by stage. If a ticket doesn't qualify for either row above, `:start`
runs the full stop-by-stop flow — it never invents its own "looks small" judgment call.

## Trivial (a filter on P2, not a third tier)

**Trivial** narrows the P2 fast-path offer above into a no-ask auto-run for the smallest possible
change. It is not a new Risk tier — Risk is still exactly P0/P1/P2, still chosen the same way. Trivial
only changes whether `:start`'s step-1 fast-path *asks and waits* or *runs and reports*.

A ticket is **Trivial** when **all** of the following hold:

- Risk = P2 (per "How to choose" above).
- Estimated diff ≤ 1 file, ≤ 5 lines.
- No public identifier changes (function/route/API/column name).
- The duplicate-scan (`ba-integrity.md` "Duplicate-scan") returns clean — zero other occurrences —
  without asking the user to confirm the grep result.
- Type ≠ Refactor spanning more than 1 file (multi-file Refactor already has its own route above;
  it does not need Trivial).

**The `≤ 5 lines` threshold is an unvalidated starting guess, not a measured number** — same status
as epic-signal.md's 4-claims/2-types backstop. Log Trivial-lane outcomes in
`templates/pilot-metrics.md` and adjust the number from that evidence, not from a new guess.

**On match:** skip the "offer fast-path, wait for reply" step entirely. Run `:build <Ticket>`
directly, write one INDEX log line (`Trivial: <description>, duplicate-scan clean, Risk=P2`) instead
of opening a full worklog, then report after the fact: `"Sửa xong (trivial, P2, duplicate-scan
clean). Nói 'full pipeline' nếu muốn undo và làm lại đầy đủ."` Do not ask before acting — the
duplicate-scan already answered the one question that would have made this unsafe (does anything
else depend on this text/logic).

**This no-ask auto-run is a property of `:start`'s step-1 offer, not of Trivial itself.** Calling
`/ak:build <Ticket>` (or any other stage) directly on a Trivial-shaped ticket still
self-analyzes per the stage's own fallback (see `references/stage-contract.md`), but does not get
the "run and report after the fact" treatment — that behavior only exists inside `:start`'s
step-1 fast-path check.

**Trivial does not apply** when the duplicate-scan finds ≥1 other occurrence (fall back to the
normal P2 ask-first flow — that's exactly when "keep these in sync?" needs a human answer), or when
Risk is P0/P1, or when the ticket doesn't otherwise qualify above.

| Tier | When | Lane | Rules |
|---|---|---|---|
| **P0** | money, authz/permission, PII, legacy data, irreversible migrate | Hard | The only hard-gated tier. All G0–G9 + AUDIT. No WAIVE G3/G8. Dual `CONFIRM G3` + `CONFIRM G3-PM`. Machine evidence + **CI-native verify** under `--strict`. **`02b-security.md` required**. `--strict` never softens P0. |
| **P1** | normal product behavior change | Fast | Required hard: G0, G1, G6, G8, G9 (real test evidence still required — softening ceremony is not softening proof). **G2/G3/G4/G5/G7 soft** unless `--strict` (warn, not fail) — same lane as P2, so a normal-behavior ticket does not force a mid-flow `CONFIRM G3` round-trip; `:audit` after G9 remains the one human sign-off point. `--strict` makes every gate hard again, same as P0. |
| **P2** | copy, config, docs, tiny non-behavioral chore | Fast | Same as P1's fast lane above (required hard: G0, G1, G6, G8, G9; G2/G3/G4/G5/G7 soft unless `--strict`). Still prefer INDEX WAIVE rows when skipping intentionally. |

**Why P1 moved to the fast lane:** the old P1=Hard default forced a `CONFIRM G3` stop on every
normal-behavior ticket, which is ceremony, not safety — the actual safety-critical cases (money,
authz, PII, migration) are already covered by P0 regardless of how "normal" the diff looks. One
human checkpoint (`:audit`, after G9, before ship) is enough for P1/P2; P0 keeps the full hard gate
chain because that's the tier where a skipped human review is a real incident, not friction. Pass
`--strict` on any ticket to force the old hard behavior back (e.g. before a client-facing merge).

## How to choose

1. Touches money / permission / PII / legacy → **P0**
2. Else changes user-visible behavior or API contract → **P1**
3. Else → **P2**

Ground the call in objective signal before falling back to judgment — check, in order:
- **Touched paths/routes**: any file under an auth/permission/payment/PII-handling module,
  or a migration → that alone forces **P0** regardless of diff size.
- **Diff shape**: new/changed public API contract, new user-visible route or UI state → **P1**
  floor even if the diff is a few lines.
- **Diff size + surface**: single file, no route/API/schema change, no new consumer → **P2**
  is the honest default, not "unsure."

"Unsure" should mean "I checked the above and it's genuinely ambiguous," not "I didn't check."
Only after checking touched paths and diff shape and still being unable to place it →
**P1** (the accurate label matters for tracking even though P1 and P2 share the same fast lane
now — fail toward P1 over P2 when ambiguous, never toward inventing a P0-like hard stop that
isn't warranted).

## Fast lane (P1 and P2)

Checker softens G2/G3/G4/G5/G7 when Risk=P1 or P2 and not `--strict`.
Still need AC, tests/machine evidence, and G9. `CONFIRM G3` is soft for P1/P2 — skip the human
round-trip on a normal-behavior or tiny change, or still ask for one when you'd rather
have it on record. `--strict` always makes G3 hard again, regardless of Risk. AUDIT is not in this
soft list — it stays the one required human checkpoint after G9, for every Risk tier.

## Stage timeboxes (adoption)

| Stage | Soft max |
|---|---|
| learning (first project) | 1–2 sessions |
| spec + clarify + confirm | ≤ 1 day for P1 |
| plan | ≤ 2 h |
| build | per estimate |
| review + fix? + test + ship + clean? | ≤ 0.5 day after build green |
| audit (semantic, post-G9) | ≤ 30 min — P0/P1 required, P2 optional |
| P2 full path | ≤ 2 h wall-clock target |

If over timebox → escalate Risk or split ticket — do not skip G3/G8/G9. Do not skip `:audit` on
P0/P1 to save the 30 min — that is exactly the timebox this table exists to protect against being
cut first under deadline pressure.

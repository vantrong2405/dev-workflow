# Epic signal — single source of truth

One rule, defined once here. `skills/start/SKILL.md` and
`skills/decompose/SKILL.md` both dispatch from this file; neither restates
the signal or the numeric backstop. If you find a different number in either
skill file, that's drift — fix it here, then remove the restatement there.

## Qualitative signal

Two or more of the following, together, mean "epic, not one ticket":

- Spans more than one service/repo.
- Mixes ticket `Type` (Bug + New feature, etc. — see `ba-integrity.md`
  "Classify the ticket first").
- The described deliverable has independently shippable parts.
- The requester already used the word "epic" / "dự án" / "nhiều phần".

One file, one Type, one deliverable is **not** an epic — route to
`:spec`/`:start` directly instead of manufacturing a split.

## Same-repo numeric backstop

A ticket can mix Type without ever spanning a second service/repo. If
investigation resolves the request into **more than 4 independent claims, or
more than 2 distinct Types**, treat that as the same epic-signal firing, even
with zero repos spanned — do not wait for the qualitative signal above to
also fire.

**These two numbers (4, 2) are an unvalidated starting guess, not a measured
threshold.** No pilot run has logged real claim-count/Type-count data against
decompose-vs-no-decompose outcomes yet (`templates/pilot-metrics.md` is still
empty in every workspace checked). If a pilot log accumulates enough rows to
show these numbers firing too early (splitting tickets that shipped fine as
one) or too late (a ticket that should have decomposed didn't), adjust the
numbers here from that evidence — not from a new guess.

## When each caller checks this

- `:decompose` checks it when the user calls it directly, or when another
  stage hands off to it.
- `:start` checks it during step 1's investigation, before the question list
  visibly balloons — same signal, checked early enough to avoid asking
  epic-shaped questions one ticket at a time.

## On match

In `:start`, prepare the split inside the active flow using `:decompose`. Ask for
confirmation of the proposed child boundaries and dependencies before starting any child.
A standalone discovery stage can report that the work needs splitting.

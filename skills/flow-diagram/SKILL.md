---
name: flow-diagram
description: >-
  Reconstruct a bug/UI-flow reproduction as a plain-text Unicode box-drawing
  diagram (Senior QA Automation / Tech Lead persona). No mid-task questions —
  filter noise, make best-supported assumptions, deliver the finished
  diagram(s); the human reviews the result, not a partial in-progress ask.
  Use /ak:flow-diagram.
argument-hint: "[free text] — logs, bug description, controller/route context, UI steps"
arguments: [input]
disable-model-invocation: false
---

# /ak:flow-diagram

Standalone utility — no ticket/worklog, no gate. Not part of the G0–G9 chain.

Read `references/flow-diagram.md` for the exact format, action-prefix rules, and few-shot example.

## Why no mid-task question

The person running this is usually context-switching across several projects at once and cannot
reliably answer a business-logic clarifying question asked mid-flow — they can only judge a
**finished** diagram against the real code. So this stage never pauses to ask "which case did you
mean" or "confirm X before continuing." Make the best-supported call from the input + codebase,
state an assumption inline in the diagram if a step is genuinely ambiguous, and finish the output.
The only decision point that belongs to the human is what they do with the result afterward (ship
the fix, file it, discard it) — never a question this stage asks on the way there.

## Steps

1. Read the input. Strip AI-agent chat/tool-call logs, noise, and anything not describing an actual
   UI step or a real bug — keep only the reproducible flow and the concrete evidence of each defect.
2. Identify each distinct bug in the input. N distinct bugs → exactly N diagrams.
3. For each bug, trace the real flow: open the actual routes/controllers/files the input points at
   (or that the described URLs/behavior imply) to ground `📍 Vị trí`, `🎯 Kỳ vọng đúng`, and `💡
   Nguyên nhân` in real code — not a guessed convention. If a claim can't be grounded in code you
   actually read, mark it `(chưa xác nhận trong code)` instead of stating it as fact.
4. Build the diagram per `references/flow-diagram.md`: role/account on the first `👤 USER` line,
   concrete fake credentials on any login step, `[Action hiện tại]` / `[Action tiếp theo]` prefixes,
   the dedicated bug block, symmetric centered flow with even left/right branches.
5. Output all N diagrams, each in its own ```text``` block headed `### BUG #1: <title>`, `### BUG
   #2: <title>`, etc. No question, no partial output, no "should I continue" — the full set comes
   back in one response.

## Refuse

- Input has no identifiable UI step or bug at all — say so plainly instead of inventing a flow.
- A referenced file/route doesn't exist in the codebase — say the claim is ungrounded instead of
  fabricating a plausible-looking location.

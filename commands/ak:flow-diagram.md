---
description: "[input] Prepare test data and draw a click-by-click Unicode UI reproduction."
argument-hint: "[free text] — logs, bug description, controller/route context, UI steps"
arguments: [input]
---

Reconstruct the flow and bug(s) in the input as plain-text Unicode box-drawing diagram(s).
Invoke `skills/flow-diagram`.
Read `references/flow-diagram.md`.
Show one diagram per distinct bug. Inside a ticket, return the diagrams and prepared test data to
`:clarify` for the human browser run.

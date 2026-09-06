---
description: "<Ticket ID> [slug] [stop-point] Run the automated checker and report PASS/FAIL for real — not a guess."
argument-hint: "<Ticket ID> [slug] [tests|ready|final]"
arguments: [ticket_id, project_slug, min_gate]
---
Run checker and report PASS/FAIL.
Invoke `skills/check`.
Never claim PASS without real checker run.
Stop-point: `tests` = test evidence recorded, `ready` = ship checklist done, `final` = coherence
read-through passed. (The script also accepts its internal G-codes directly if you already know them.)
Next: whatever the report flags as still missing, or continue the normal flow if it's PASS.

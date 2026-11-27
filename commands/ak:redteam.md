---
description: "<Ticket ID> Challenge the implementation plan before editing code."
argument-hint: "<Ticket ID>"
arguments: [ticket_id]
---

Invoke `skills/redteam` on the ticket's current plan.
Return blockers to `/ak:plan` for revision. A passing review can continue to `/ak:build`.

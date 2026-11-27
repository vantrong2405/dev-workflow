---
name: test
description: >-
  Run tests and record evidence for the current code. The checker reads cited
  local JUnit results at G8. Strict/P0 verification also checks committed source.
argument-hint: "<Ticket ID> Run after review — fill 06b-test-evidence.md"
arguments: [ticket_id]
disable-model-invocation: false
---

# /ak:test

Apply `references/skill-quality.md`; filenames and logs count only when tied to executed assertions.

Use the project locale from `references/locale.md`.

1. Resolve checks from the plan, acceptance criteria, and relevant project form entries.
   If P0/P1 review findings are still open, route to `:fix`.
2. Review the shared ledger in `06b-test-evidence.md`. Follow
   `references/execution-evidence.md` to reuse runs only when they still prove the current
   change. Run missing or stale checks. Record superseded runs as history.
3. Map assertions to the acceptance IDs. Include command results, source state, and
   the raw output or CI/JUnit/log artifact. For UI tickets, complete the required
   browser verification on the current code per `references/ui-verification.md`.
   Repeat the bug scenario in the same conditions and run the approved golden
   comparison for visual changes. Use `references/ui-evidence.md` for captures.
4. Run `/ak:check <Ticket> [slug] G8` with strict verification when required. Any required
   failing or missing evidence blocks verification. Report whether checks covered the
   working tree or the committed source.

A PASS claimed under `--strict` or P0 requires native evidence checks. The usual local
handoff can report verified working tree changes. Release preparation requires a separate
strict G9 check and applicable audit. Keep the genuine assertions and outputs in the
ledger and preserve the gate's required fields.

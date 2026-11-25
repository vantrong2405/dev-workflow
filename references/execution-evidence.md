# Execution evidence

Use the **Executed-command ledger** in the ticket's `06b-test-evidence.md` as the shared
record. Build and fix add rows as they execute commands. Review and test cite matching rows
by run ID. Preserve the checker fields in the implementation, review and test artifacts.

1. Record the exact command, repo and cwd, source state, time range, exit code, result
   artifact and covered acceptance IDs. Give each run an ID such as `RUN-01`. Preserve
   RED evidence and summary of what the failure proved. Store full output once or use one
   result artifact. Link to it from the other stages.
2. For Git projects use `bash "$AK_PLUGIN/bin/source-state.sh" <repo-or-module>` just
   before and after a run for each relevant checkout. A `commit:<sha>` identifies a clean
   checkout. A `worktree:<hash>` identifies local tracked and non-ignored untracked changes.
   Run it again before reusing a result. For changes spanning multiple repos record each
   relevant state. A command that changes its own source inputs cannot provide reusable proof
   from those snapshots alone.
3. Reuse successful evidence only if command, cwd, source state, relevant runtime inputs,
   and acceptance coverage still match. This helper does not fingerprint ignored test inputs
   or external state. If those may have changed, the state is unavailable, or a check runs a
   different scope, execute the required check. Never reuse another ticket's PASS marks.
4. Keep local and commit evidence distinct. Record `Tested source` and `Evidence checkout`
   in the machine table when available. The legacy Commit SHA in local evidence names the
   base HEAD. A dirty run can prove local verification, and strict or P0 commit verification
   needs checks on the clean committed source. If the required state depends on user action,
   surface the prerequisite. The checker compares these fields with the recorded checkout.
   When checks run on a separate CI runner, record the checkout and result from that runner.
   Preserve old ledger rows as history when new runs supersede them.

For a docs/config-only change, use the relevant lint, parse, link or diff check from the
project. For a behavioral change with no runnable test surface, document that limitation
and any observed substitute evidence. Do not convert missing required evidence into PASS.

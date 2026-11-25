# Project form

Use `templates/workspaces/_project/PROJECT-FORM.md` at
`<project-home>/PROJECT-FORM.md`. The form is workspace data, separate from product source
and individual ticket worklogs. `PROJECT.md` remains the repository map. Prefer existing
workspace mappings that actually own the repo, an explicit selection, or a repo marker.
If none matches, use the repo name for a new workspace. A lone workspace for a different
repo does not establish ownership. Ask only if competing mappings cannot be resolved.

## Discover reusable facts

- Identify the active repo and the modules relevant to the first task. Read its instructions
  (including the applicable `AGENTS.md` or `CLAUDE.md`), manifest, scripts, CI and entry points
  as needed. Stop once you can work on the current task.
- Record commonly reused facts such as the command and working directory for tests, build
  or lint, module entry points, documented conventions and release profile. Add the
  repo/module, source location and date for each known value. Mark unavailable values
  `Unknown` and leave out unrelated modules. A command found in source is a candidate until
  actually run. Use relevant existing knowledge as a lead and check it when necessary.
- Distinguish documented policy from observed behavior. Code can establish how a feature
  behaves today. A requirement needs its own source or a human decision. Do not record
  credentials, local secret values, runtime data or a ticket result in the form.

## Ask the owner how they want to work

After the initial read, ask in the user's language: “Are there any conventions or expectations
you want me to follow when working on tasks in this project?” Include a concrete observation
if it helps focus the question. If they cannot name conventions, ask one follow-up about how
they handled a recent task, what they usually check before handing it off, or what they often
have to remind an agent to do. Let them answer in their own words.

Summarize their answer as short candidate rules with a trigger, expected action, and scope.
Echo the proposed rules and use the owner's explicit agreement before recording them as
confirmed. If the scope is unclear, propose this project as the default. Keep task-only
requests in the task context. Ask about a conflict only if it affects the current work or
the proposed rule. Product repo instructions and required gates still apply.

Record `Convention interview: confirmed` after agreement, with who confirmed each rule and
when. If the owner declines, says they have no preferences, or asks to get on with the task,
record `Convention interview: skipped` and resume. Before either outcome the form is
`pending`. Never interpret silence as acceptance or reopen a completed interview on routine
tasks. When there is an active task, resume it after the interview in the same entry point.

## Reuse and refresh

- At each task, load the applicable form entries and repo instructions. Verify affected
  sources if a recorded path is missing, a declaration changed, or a command no longer
  resolves. Refresh just those facts and keep human-confirmed rules separate.
- When you learn something during a task, keep it in the worklog unless it is likely to be
  useful across tasks and can be sourced. Use a focused refresh for new reusable facts.
  Neither a new ticket nor the age of the form alone calls for a full scan.
- For an explicit lasting preference change, show the changed rule and record the user's
  approval. For deeper business research or corrections, use the domain knowledge in
  `references/learning.md` and `references/coaching.md`.
- Add the form beside legacy workspace files on first onboarding. Preserve existing
  worklogs and domain notes. Keep automatic setup in the workspace; a change to project
  instruction files needs an explicit request to maintain those files.

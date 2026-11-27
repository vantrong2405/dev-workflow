---
name: learning
description: >-
  Learn the reusable parts of a project, capture the owner's working conventions
  in one project form, or refresh selected entries. Also runs inside /ak on first use.
argument-hint: "[project path or brief] [optional topic to refresh]"
arguments: [brief]
disable-model-invocation: false
---

# /ak:learning

Read `references/project-form.md`, `references/project-root.md` and
`references/locale.md`. Apply `references/skill-quality.md` to material facts.

1. Resolve the project from the request or active repo. Reuse its workspace.
   Create `PROJECT.md` from its template and `worklogs/` if missing. Add
   `PROJECT-FORM.md` from the project form template if missing.
2. Follow the project form reference for scoped discovery and the convention interview.
   If the form already exists, load it and refresh just the requested or stale facts.
   Keep the first interview pending until the owner confirms or skips. For an explicit
   request to change working rules, discuss and save just the approved update.
3. Run `bin/check-workspace.sh <slug>` once after setup. If called by `:start`,
   return the form and resume the original task. If called directly, report the
   form, confirmed rules and any remaining relevant unknowns.
4. If asked for deeper business knowledge, use `references/learning.md` for that
   target and route unresolved business intent to `:coaching`. Basic onboarding
   does not depend on completing that research.

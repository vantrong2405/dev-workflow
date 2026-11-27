# Resolve project paths

Never hardcode customer paths. Resolve from cwd/git/marker/brief.

Layout (preferred):
`~/.workspaces/<project-slug>/{PROJECT.md,PROJECT-FORM.md,worklogs/<Ticket_ID>/}`

`domain-knowledge/` and `repos/<repo-slug>/` can hold deeper notes. Existing workspaces
with the legacy domain index remain readable. See `project-form.md` for first-use ownership
checks and conventions.

Legacy layout still readable:
`<root>/workspaces/<project-slug>/...`

Resolve order (same as `bin/lib/resolve-paths.sh`):
1) plugin dir: `AK_PLUGIN` → known symlinks → running script dir.
2) workspaces root: `AK_WORKSPACES_ROOT` → `~/.workspaces` (default) → cwd walk-up (`.workspaces/`, `workspaces/`, `.ak.json`) → `AK_EXTRA_WORKSPACE_ROOTS`.
3) project slug: explicit arg/env → `.ak.json` (`projectSlug`/`slug`) → existing `PROJECT.md` whose Repos table matches cwd → slugified git/cwd name. Competing ownership needs explicit selection. Outside a Git checkout and without a workspace selection, a ticket can be looked up by ID only when exactly one workspace contains it.
Slug is always the real repo/org name — never a name invented from a brief's feature
description (see `references/learning.md` § Choosing the slug). Honor an explicit user-requested
slug over the default.

Rules: print `project=<slug> home=<path> ticket=<id> worklog=<path> locale=<code>` at each stage start; keep artifacts outside project repo by default (under `~/.workspaces`) unless user explicitly overrides.
Validate with `bin/check-workspace.sh`. Isolate tickets per `references/task-isolation.md`. Clean finished tickets with `bin/clean-worklog.sh` / `:clean`.

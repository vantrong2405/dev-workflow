# Vibe business specifications

Vibe uses a separate OpenSpec planning home in the resolved ak project workspace. The installed
OpenSpec CLI supplies the schema, validation, delta merge and archive. The first change forks
`spec-driven` to a project-local `vibe` schema and adds the Vibe template instructions. This
requires the `openspec` CLI on PATH. Resolve the installed plugin directory as described in
[project roots](project-root.md), then use the helper from the product checkout and let it
resolve the workspace. Pass `--project <slug>` before the operation when selection is needed.

```text
~/.workspaces/<project>/
  PROJECT-FORM.md
  worklogs/<ticket>/
  vibe/openspec/
    specs/<capability>/spec.md
    changes/<change>/
      proposal.md
      design.md
      tasks.md
      specs/<capability>/spec.md
    changes/archive/<date>-<change>/
```

## Read

Start with `bash "$AK_PLUGIN/bin/vibe-specs.sh" list --specs`. Open the relevant spec with
`show-spec <capability>`. Read related active changes with `list` and `status <change>`.
Main specs describe implemented business behavior. Active deltas and unchecked tasks show
planned work. Archived changes preserve the approved scope, completed checklist, and a
verification receipt. Read archive history when the reasons for an existing rule matter.

## Plan and build

For a Vibe change that adds, changes or removes business behavior, resolve/create the ak
worklog and run `new <change-name> <ticket-id>` through the helper. Reuse the same name when
resuming. Use `instructions <change> <artifact>` for the copied proposal, specs, design and
tasks templates. Scope deltas to the capabilities touched. One capability can grow across
tasks. Keep its current contract under the same stable capability and requirement names.

Update the delta while clarifying. Keep main specs for verified behavior. After settling the
business rules, connect scenarios to the worklog's acceptance IDs. Use `tasks.md` as the
checklist for doing the work. The ak worklog holds gate-specific planning and test evidence.
Use the same task and acceptance IDs in both. Before Redteam, run `validate <change>`,
compute `revision <change>`, and record exactly `- **Vibe spec revision:** <hash>` in the
worklog's `04-plan.md`. A change to a scoped main spec, delta, proposal, design, or task text
requires a new revision and Redteam review. Marking checklist items complete preserves the
reviewed revision. Record completion only after the corresponding work and checks exist.

## Verify and archive

After the change passes the normal test stage, run `archive <change>`. The helper checks
the completed checklist, reviewed spec revision, OpenSpec validity and ak's G8 evidence with
Redteam required. It then updates main specs and moves the full change to the archive through
OpenSpec, keeping `verification.json` with the tested ak ticket and its gate result. Retain
the change as active when a requirement or verification is incomplete. A retry of an already
archived change returns the saved archive path.

OpenSpec references: [Concepts](https://github.com/Fission-AI/OpenSpec/blob/main/docs/concepts.md)
and [overview](https://github.com/Fission-AI/OpenSpec/blob/main/docs/overview.md).

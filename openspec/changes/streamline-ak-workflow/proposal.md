## Why

Routine tasks still require users to connect setup, delivery, and release stages by hand. Project knowledge is reusable, but onboarding asks for more than many tasks need and does not give the owner a clear way to teach their working preferences.

## What Changes

- Make `/ak <task>` the default path from task intake to verified handoff, including lightweight setup during the first task.
- Reuse one project form for repository facts and user-approved rules. Collect conventions conversationally and refresh the relevant entries as needed.
- Consolidate investigation, planning, and verification in the normal path while retaining separate checks for distinct risks and release decisions.
- Keep named stages and existing gate artifacts available for manual work and CI.
- Align the entry point, stage contracts, user guides, and supported host packaging with the new flow.

## Capabilities

### New Capabilities

- `project-onboarding`: Discover only reusable project facts, capture working rules with the owner, and reuse or refresh the form.
- `task-delivery`: Carry a task through understanding, implementation, verification, and handoff from one entry point, including requested release preparation.

### Modified Capabilities

## Impact

Changes affect installed skills, command descriptions, workspace templates and checks, gate documentation, and validation fixtures. Existing workspaces and named stages remain supported.

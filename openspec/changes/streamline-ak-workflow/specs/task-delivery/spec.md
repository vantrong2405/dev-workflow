## Purpose

Provides one task entry point that automatically carries eligible work through to a verified handoff.

## ADDED Requirements

### Requirement: One continuous task path

The entry point SHALL guide a task through understanding, implementation, verification, and handoff, using the form as project context. It SHALL present only unresolved material user decisions, actionable blockers, and the handoff.

#### Scenario: Clear routine task
- **WHEN** a user supplies a clear routine task
- **THEN** the agent reuses project knowledge, builds within scope, reviews the diff, runs relevant checks, and hands off a verified result or reports concrete missing evidence

#### Scenario: Missing business decision or high risk
- **WHEN** a material business decision or required P0 sign-off is missing
- **THEN** the agent presents the decision and resumes the same task after it is resolved

### Requirement: Evidence reuse and delivery boundary

The agent SHALL record each qualifying run once, reuse it only when it covers the same command, scope, and current code, and keep review and release checks distinct. Release preparation SHALL run when requested, with applicable sign-offs and explicit authority for external actions.

#### Scenario: Same check after review
- **WHEN** an already recorded check covers the unchanged code and the intended assertion
- **THEN** the agent uses the existing evidence for final verification

#### Scenario: Release preparation requested
- **WHEN** the user includes release preparation for a verified change
- **THEN** the agent continues within the same entry point through applicable launch controls and audit without assuming merge, push, or deployment authority

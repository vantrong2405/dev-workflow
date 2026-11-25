## Purpose

Makes onboarding lightweight and lets users teach reusable working conventions in their own words.

## ADDED Requirements

### Requirement: Reusable project form

The entry point SHALL discover a project's reusable facts when the form is absent and reuse relevant form entries for future tasks. Missing unrelated fields SHALL NOT prevent a task from continuing.

#### Scenario: First task in an existing repository
- **WHEN** the user runs a task in a repository without a form
- **THEN** the agent discovers the repository, relevant entry points, test commands, and documented conventions from scoped sources, fills the form, and resumes the same task

#### Scenario: Later task or stale entry
- **WHEN** a later task needs a known or stale setup value
- **THEN** the agent loads the relevant entries and verifies or updates only the missing or contradicted facts

### Requirement: Conversational working conventions

The agent SHALL ask the owner about working conventions during initial onboarding, summarize durable rules for confirmation, and distinguish repository facts, confirmed rules, and one-task exceptions.

#### Scenario: Owner describes their usual work
- **WHEN** the owner cannot readily name conventions
- **THEN** the agent asks them to describe a recent task or the outcome they expect, then shows concrete candidate rules with their scope

#### Scenario: Owner skips or corrects a preference
- **WHEN** the owner skips the conversation or supplies a task-only exception
- **THEN** the agent continues and does not persist an unconfirmed rule or ask again on routine tasks

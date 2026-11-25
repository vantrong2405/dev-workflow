## Context

`/ak` is a prompt workflow. The Bash checker validates separate stage artifacts used by CI and manual commands. Current G0 couples setup to a domain-knowledge index, and the shipped host packages read shared skill references and templates.

## Goals / Non-Goals

**Goals:** a single entry point for project onboarding and task work, minimal reusable project context, and a clear verified handoff with fewer repeated actions.

**Non-Goals:** a separate runtime coordinator, automatic external release, or replacement of the established CI gate formats.

## Decisions

1. Store `PROJECT-FORM.md` beside `PROJECT.md` inside the resolved project workspace. Keep the repo map in `PROJECT.md`; use the form for observed operating facts and approved project rules. Missing fields are explicit and may be filled later. Existing workspaces are augmented on first use.
2. First use asks for working conventions after a scoped read. Follow up with one concrete task question when needed. Show proposed rules for confirmation, allow skip, and persist completion of the interview so it does not recur by default. Existing locale preference applies; use the conversation language as the default on new workspaces and allow correction in the same exchange.
3. Keep existing stage artifacts for manual operation and checker compatibility. The default workflow passes one investigation forward, references a shared command ledger, and avoids duplicating command execution. Initial focused checks and final wider checks remain separate when they prove different things. Dirty product worktrees require explicit evidence of the tested content and may not be called commit-verified.
4. Default to a verified handoff at G8. Apply existing hard gates for P0/strict mode, and keep required release sign-offs for the ship path. Resolve discrepancies in the current risk, audit, and start instructions.

## Risks / Trade-offs

- Prompt behavior can vary by host. Add executable fixture checks for workspace and checker behavior, plus an isolated scenario covering installed skill resolution and prompt contracts.
- A form may become stale or read like a contract. Check sources when relevant, record fact provenance, and keep changes to approved rules separate.
- Existing gate artifacts repeat a few fields required by CI. Reuse the evidence and retain those fields as references or short summaries.

## Migration Plan

Reinstall the existing plugin using its original host option. On first use, add the form next to existing project artifacts. Older worklogs and gate invocations remain readable.

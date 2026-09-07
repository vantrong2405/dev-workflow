<img alt="ak" src="./assets/logo/logo-light.svg" width="200">

# ak

[![Version](https://img.shields.io/badge/version-0.4.0-blue)](CHANGELOG.md)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Hosts](https://img.shields.io/badge/hosts-Claude%20%7C%20Cursor%20%7C%20Codex%20%7C%20Antigravity-purple)](#install)

**[English](README.md)** · [Tiếng Việt](README.vi.md) · [日本語](README.ja.md)

**Requirement-first AI delivery workflow** for Claude Code, Cursor, Codex, and Antigravity: clear
specs → one human confirm → TDD → machine-verified evidence → one human sign-off → ship.

## Why

Without a gated process, AI coding often:

- Misses business rules
- Ships UI/logic bugs
- Marks "done" without evidence
- Drifts from what was actually confirmed

ak blocks progress until structural gates pass and a required semantic **audit** signs off. The
checker (`bin/check-gates.sh`) is the source of truth — the AI must not invent a PASS. Only
**Risk P0** (money, permission, PII, migration) hard-gates every step; everything else (P1/P2)
shares one fast lane so normal tickets don't collect ceremony they don't need — see
[Gates & risk](#gates--risk).

## Install

```bash
git clone https://github.com/trongdn2405/ak.git
cd ak
bash install.sh                          # global, Claude Code (default) — see docs/INSTALL.md for Cursor/Codex/Antigravity
bash install.sh --path ~/projects/my-app # self-contained in that project only, nothing global
bash install.sh --only spec,build,review # install just those stages, either mode
```

Then in any project:

```text
/ak TICKET-123 https://tracker/TICKET-123
```

First run in a project also seeds/updates that project's own `CLAUDE.md` (a marked block only —
your own content stays untouched) with the pipeline, Risk rule, and stack-neutral conventions
(language split, minimal diff, comment WHY not WHAT, never force-push). Full install/update/
uninstall paths per host: [docs/INSTALL.md](./docs/INSTALL.md).

## Flow

`:start` (also the bare `/ak` alias) is the single entry point for one ticket — analyze
once, ask once, then run to the first real stop. `learning`/`coaching` bootstrap or correct domain
knowledge independently, outside this pipeline.

```mermaid
%%{init: {"flowchart": {"curve": "basis", "nodeSpacing": 45, "rankSpacing": 65}}}%%
flowchart LR
    start((" ")):::fast -.-> spec("spec → clarify\n→ confirm → plan"):::default --> build("build"):::fast --> review("review"):::default --> test("test"):::default --> ship("ship"):::gate --> audit((" ")):::gate
    start -. Trivial fix, skip straight to build .-> build

    classDef default fill:#f9fafb,stroke:#d1d5db,stroke-width:1px,color:#1f2937,rx:18,ry:18;
    classDef fast fill:#5eead4,stroke:#0d9488,stroke-width:2px,color:#134e4a;
    classDef gate fill:#fcd34d,stroke:#b45309,stroke-width:2px,color:#78350f;
    linkStyle default stroke:#d1d5db,stroke-width:1.5px
```

Between `review` and `ship`, `fix` runs if findings are open, `check` verifies gates, and `clean`
archives the worklog after — full sequence and every stage's job: [docs/USER-GUIDE.md
§3](./docs/USER-GUIDE.md#3-daily-flow-for-one-ticket). "Trivial" has a precise definition (Risk=P2,
≤1 file, ≤5 lines, no public identifier change, clean duplicate-scan) — see [docs/USER-GUIDE.md
§3.2](./docs/USER-GUIDE.md#32-start-a-ticket).

An epic-shaped request runs through `:decompose` first, which splits it into child tickets and then
loops this same flow one child at a time — see [docs/USER-GUIDE.md](./docs/USER-GUIDE.md) for that
diagram and the full stage-by-stage walkthrough.

## Commands

| Command | Effect |
|---------|--------|
| `/ak:spec` | Testable ACs + Risk tier (P0/P1/P2) |
| `/ak:clarify` | Spec/intent vs running behavior; decisions recorded |
| `/ak:confirm` | Human sign-off — the one stop before plan/build |
| `/ak:plan` / `:build` | TDD plan + implementation + coverage map |
| `/ak:review` / `:fix` | Neutral diff review + triage/fix |
| `/ak:test` | Real test run + machine evidence (SHA/CI/junit) |
| `/ak:check` | Run the checker for real — no self-claimed PASS |
| `/ak:ship` | Ship safety checklist |
| `/ak:audit` | Semantic coherence check — the one human sign-off before ship is final |
| `/ak:decompose` | Split an epic into child tickets, one confirm covers the split |
| `/ak:learning` / `:coaching` | Bootstrap or correct project domain knowledge |
| `/ak:status` / `:clean` | Where a ticket stands / archive its finished worklog |
| `/ak:feedback` | Report a bug in `ak` itself |
| `/ak:flow-diagram` | Bug/UI-flow reproduction as a plain-text diagram, no back-and-forth |

Full command reference (all 19, arguments, and when each runs standalone):
[docs/USER-GUIDE.md §4](./docs/USER-GUIDE.md#4-commands-cheat-sheet).

## Gates & risk

Ten structural gates plus a semantic audit enforce the flow above. Three Risk lanes decide how much
ceremony a ticket needs — **P0 is the only hard-gated tier**; P1 and P2 share one fast lane, so a
normal-behavior change doesn't force a mid-flow confirm the way a money/permission/PII/migration
change does. `/ak:confirm` and `/ak:audit` stay the two points a human actually decides something,
regardless of tier. The authoritative definitions live in
[references/stage-contract.md](./references/stage-contract.md) and
[references/risk.md](./references/risk.md) — [docs/USER-GUIDE.md §6](./docs/USER-GUIDE.md#6-gates-g0g9--audit-in-one-table)
has the reader-facing table.

## Learn more

| Doc | Content |
|-----|---------|
| **[docs/catalog.html](./docs/catalog.html)** | Browsable catalog of every Command/Skill/Reference/Template + an install-command builder (open the file in a browser) |
| **[docs/USER-GUIDE.md](./docs/USER-GUIDE.md)** | Full day-to-day guide: setup, daily flow, confirm phrase, worklog files, gates, pilot |
| [docs/INSTALL.md](./docs/INSTALL.md) | Install, update, uninstall, verify, host paths |
| [MARKETPLACE.md](./MARKETPLACE.md) | Host-specific install + smoke test |
| [STRUCTURE.md](./STRUCTURE.md) | Annotated repo layout |
| [references/vocabulary.md](./references/vocabulary.md) | Command vs Skill vs Reference vs Template, defined |
| [CONTRIBUTING.md](./CONTRIBUTING.md) | How to change the plugin |
| [CHANGELOG.md](./CHANGELOG.md) | Version history |
| [SECURITY.md](./SECURITY.md) | Report a vulnerability |
| [CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md) | Community standards |
| [references/](./references/) | Gates, risk, security, pilot, enforcement — AI + advanced users |

## License

[MIT](LICENSE)

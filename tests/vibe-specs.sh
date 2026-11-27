#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
command -v openspec >/dev/null || { echo "OpenSpec CLI is required"; exit 2; }
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
export AK_WORKSPACES_ROOT="$tmp/workspaces"
mkdir -p "$AK_WORKSPACES_ROOT" "$tmp/product/openspec"
cp -R "$ROOT/fixtures/workspaces/demo" "$AK_WORKSPACES_ROOT/demo"
project="$AK_WORKSPACES_ROOT/demo"
ticket="PASS-G8"
worklog="$project/worklogs/$ticket"
sed 's/<project-slug>/demo/g; s/<language-code>/vi/g; s/interview:\*\* pending/interview:** skipped/' \
  "$ROOT/templates/workspaces/_project/PROJECT-FORM.md" >"$project/PROJECT-FORM.md"
printf 'schema: spec-driven\n' >"$tmp/product/openspec/config.yaml"
original="$(cat "$tmp/product/openspec/config.yaml")"
cd "$tmp/product"

vibe() { bash "$ROOT/bin/vibe-specs.sh" --project demo "$@"; }
fails_with() {
  local pattern="$1"
  shift
  if "$@" >"$tmp/out" 2>&1 || ! grep -q "$pattern" "$tmp/out"; then
    cat "$tmp/out"
    echo "Expected failure: $pattern" >&2
    exit 1
  fi
}

vibe list --specs | grep -q '"specs": \[\]'
first="$(vibe new hold-order "$ticket")"
[[ "$first" == "$(vibe new hold-order "$ticket")" ]]
change="$project/vibe/openspec/changes/hold-order"
[[ -f "$project/vibe/openspec/schemas/vibe/schema.yaml" ]]
grep -q 'Mark it complete only' "$project/vibe/openspec/schemas/vibe/templates/tasks.md"
[[ "$(cat "$tmp/product/openspec/config.yaml")" == "$original" ]]

mkdir -p "$change/specs/orders"
cat >"$change/proposal.md" <<'EOF'
## Why
Staff need a way to hold an unshipped order.

## What Changes
- Add the order hold rule and its acceptance case.

## Capabilities
### New Capabilities
- `orders`: Order processing rules.

### Modified Capabilities

## Impact
- Existing order workflow and its checks.
EOF
cat >"$change/design.md" <<'EOF'
## Context
An unshipped order can be paused.

## Decisions
- Keep a hold on the order until staff release it.
EOF
cat >"$change/specs/orders/spec.md" <<'EOF'
## ADDED Requirements

### Requirement: Hold an unshipped order
The system SHALL pause an unshipped order when staff request a hold.

#### Scenario: Staff hold an unshipped order
- **WHEN** staff request a hold for an unshipped order
- **THEN** the order moves to On Hold
EOF
printf '%s\n' '## 1. Implementation' '' '- [ ] 1.1 Verify order hold (AC-01)' >"$change/tasks.md"
vibe validate hold-order >/dev/null
revision="$(vibe revision hold-order)"
fails_with 'Complete the Vibe checklist' vibe archive hold-order

sed 's/- \[ \]/- [x]/' "$change/tasks.md" >"$tmp/tasks"
mv "$tmp/tasks" "$change/tasks.md"
[[ "$revision" == "$(vibe revision hold-order)" ]]
printf '\n- **Review protocol:** redteam-v2\n- **Vibe spec revision:** %s\n' "$revision" >>"$worklog/04-plan.md"
plan_state="$(bash "$ROOT/bin/plan-review-state.sh" "$worklog")"
cat >"$worklog/04b-plan-review.md" <<EOF
# Plan review

| Field | Value |
|---|---|
| Plan review state | $plan_state |
| Review mode | same-session |
| Review verdict | PASS |

## Counterexamples

| ID | Challenge | Evidence | Impact | Severity | Status | Resolution |
|---|---|---|---|---|---|---|
| RT-01 | Duplicate hold | AC-01 | Two state changes | P1 | FIXED | Assert one transition. |
EOF
printf '\nChanged task scope.\n' >>"$change/design.md"
fails_with 'business spec or planned work has changed' vibe archive hold-order
sed '$d' "$change/design.md" | sed '$d' >"$tmp/design"
mv "$tmp/design" "$change/design.md"
[[ "$revision" == "$(vibe revision hold-order)" ]]
main_specs="$project/vibe/openspec/specs/orders"
mkdir -p "$main_specs"
printf '## Purpose\nAnother change updated the same capability.\n' >"$main_specs/spec.md"
fails_with 'business spec or planned work has changed' vibe archive hold-order
rm "$main_specs/spec.md"
mv "$worklog/06b-test-evidence.md" "$tmp/evidence"
fails_with 'missing 06b-test-evidence' vibe archive hold-order
cp "$worklog/INDEX.md" "$tmp/index"
printf '\n- G8 | Fixture waiver | Fixture owner | 2026-12-31\n' >>"$worklog/INDEX.md"
fails_with 'used a G8 waiver' vibe archive hold-order
mv "$tmp/index" "$worklog/INDEX.md"
mv "$tmp/evidence" "$worklog/06b-test-evidence.md"

receipt="$(vibe archive hold-order)"
printf '%s\n' "$receipt" | grep -q '"status": "archived"'
[[ ! -e "$change" ]]
[[ -f "$project/vibe/openspec/specs/orders/spec.md" ]]
vibe show-spec orders | grep -q 'Hold an unshipped order'
archived="$(printf '%s\n' "$receipt" | python3 -c 'import json,sys; print(json.load(sys.stdin)["archive"])')"
grep -q '\[x\].*AC-01' "$archived/tasks.md"
grep -q '"ok": true' "$archived/verification.json"
vibe archive hold-order | grep -q '"status": "already-archived"'
[[ "$(cat "$tmp/product/openspec/config.yaml")" == "$original" ]]
echo "PASS: Vibe isolates OpenSpec, binds the checklist to the reviewed spec, and archives verified behavior."

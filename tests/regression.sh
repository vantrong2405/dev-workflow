#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export AK_PLUGIN="$ROOT"
CHECK="$ROOT/bin/check-gates.sh"
FIXTURES="$ROOT/fixtures"
PASS=0
FAIL=0

ok() { printf 'PASS: %s\n' "$1"; PASS=$((PASS + 1)); }
bad() { printf 'FAIL: %s\n' "$1"; FAIL=$((FAIL + 1)); }

assert_success() {
  local name="$1"; shift
  if "$@" >/tmp/ak-test.out 2>/tmp/ak-test.err; then ok "$name"; else bad "$name"; fi
}

assert_failure() {
  local name="$1"; shift
  if "$@" >/tmp/ak-test.out 2>/tmp/ak-test.err; then bad "$name"; else ok "$name"; fi
}

assert_failure_output() {
  local name="$1" pattern="$2"; shift 2
  if "$@" >/tmp/ak-test.out 2>/tmp/ak-test.err; then
    bad "$name"
  elif grep -qE "$pattern" /tmp/ak-test.out /tmp/ak-test.err; then
    ok "$name"
  else
    bad "$name"
  fi
}

assert_output() {
  local name="$1" pattern="$2"; shift 2
  if "$@" >/tmp/ak-test.out 2>/tmp/ak-test.err &&
     grep -qE "$pattern" /tmp/ak-test.out; then
    ok "$name"
  else
    bad "$name"
  fi
}

export AK_WORKSPACES_ROOT="$FIXTURES"

assert_output "--json emits valid JSON on PASS" '"ok": true' \
  "$CHECK" PASS-G8 --project demo --min G8 --json

assert_failure "--json preserves nonzero exit on FAIL" \
  "$CHECK" FAIL-G8-failing --project demo --min G8 --json

tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT
mkdir -p "$tmp_root/workspaces/demo/worklogs"
cp -R "$FIXTURES/workspaces/demo/PROJECT.md" "$tmp_root/workspaces/demo/"
cp -R "$FIXTURES/workspaces/demo/domain-knowledge" "$tmp_root/workspaces/demo/"
cp -R "$FIXTURES/workspaces/demo/worklogs/PASS-G9" "$tmp_root/workspaces/demo/worklogs/TYPE-MISSING"
sed -i.bak '/Type:/d' "$tmp_root/workspaces/demo/worklogs/TYPE-MISSING/INDEX.md"
rm -f "$tmp_root/workspaces/demo/worklogs/TYPE-MISSING/INDEX.md.bak"
export AK_WORKSPACES_ROOT="$tmp_root/workspaces"

onboarded="$tmp_root/workspaces/onboarded"
mkdir -p "$onboarded/worklogs/FIRST"
sed 's/demo/onboarded/g' "$FIXTURES/workspaces/demo/PROJECT.md" >"$onboarded/PROJECT.md"
touch "$onboarded/worklogs/FIRST/INDEX.md"
sed 's/<project-slug>/onboarded/g; s/<language-code>/vi/g' \
  "$ROOT/templates/workspaces/_project/PROJECT-FORM.md" >"$onboarded/PROJECT-FORM.md"
assert_failure_output "workspace does not accept a pending convention interview" 'FAIL.*W2' \
  "$ROOT/bin/check-workspace.sh" onboarded
assert_failure_output "G0 rejects an incomplete project form" 'G0 FAIL:.*PROJECT-FORM' \
  "$CHECK" FIRST --project onboarded --min G0
sed -i.bak 's/interview:\*\* pending/interview:** skipped/' "$onboarded/PROJECT-FORM.md"
assert_success "workspace accepts a skipped interview without domain notes" \
  "$ROOT/bin/check-workspace.sh" onboarded
assert_success "G0 accepts the lightweight form without domain notes" \
  "$CHECK" FIRST --project onboarded --min G0
sed -i.bak 's/interview:\*\* skipped/interview:** confirmed/' "$onboarded/PROJECT-FORM.md"
assert_failure_output "G0 requires a rule when the form claims confirmation" 'G0 FAIL:.*PROJECT-FORM' \
  "$CHECK" FIRST --project onboarded --min G0
printf '| UI changes | Check the affected screen | Project | Owner, 2026-11-25 |\n' \
  >>"$onboarded/PROJECT-FORM.md"
assert_success "G0 accepts a form with an approved working rule" \
  "$CHECK" FIRST --project onboarded --min G0
sed -i.bak 's/`onboarded`/`wrong-repo`/' "$onboarded/PROJECT-FORM.md"
assert_failure_output "G0 requires the form to match the workspace slug" 'G0 FAIL:.*PROJECT-FORM' \
  "$CHECK" FIRST --project onboarded --min G0

checkout="$tmp_root/product"
mkdir -p "$checkout"
git -C "$checkout" init -q
printf 'original\n' >"$checkout/source.txt"
git -C "$checkout" add source.txt
git -C "$checkout" -c user.name=Fixture -c user.email=fixture@example.test commit -qm initial
sha="$(git -C "$checkout" rev-parse HEAD)"
source_state="$ROOT/bin/source-state.sh"
resolver="$ROOT/bin/lib/resolve-paths.sh"
assert_output "a new Git checkout does not inherit a lone unrelated workspace" '^product$' \
  bash -c 'cd "$1"; source "$2"; resolve_project_slug && printf "%s\n" "$AK_PROJECT_SLUG_RESOLVED"' _ "$checkout" "$resolver"
assert_failure "lookup from an unmatched checkout does not read another project ticket" \
  bash -c 'cd "$1"; source "$2"; resolve_worklog_dir TYPE-MISSING' _ "$checkout" "$resolver"
mkdir -p "$tmp_root/workspaces/product"
cp "$FIXTURES/workspaces/demo/PROJECT.md" "$tmp_root/workspaces/product/PROJECT.md"
assert_failure_output "an existing same-name workspace cannot claim a different checkout" 'does not map this checkout' \
  bash -c 'cd "$1"; source "$2"; resolve_project_slug' _ "$checkout" "$resolver"
rm "$tmp_root/workspaces/product/PROJECT.md"
mkdir -p "$tmp_root/workspaces/another/worklogs/TYPE-MISSING"
assert_failure_output "a duplicate ticket requires explicit project selection" 'ambiguous worklog' \
  bash -c 'cd "$1"; source "$2"; resolve_worklog_dir TYPE-MISSING' _ "$tmp_root" "$resolver"
assert_output "explicit project selection resolves the intended duplicate ticket" '/demo/worklogs/TYPE-MISSING$' \
  bash -c 'cd "$1"; source "$2"; resolve_worklog_dir TYPE-MISSING demo' _ "$tmp_root" "$resolver"
assert_output "a unique standalone ticket lookup still works from outside a repo" '/another/worklogs/TYPE-MISSING$' \
  bash -c 'cd "$1"; source "$2"; resolve_worklog_dir TYPE-MISSING another' _ "$tmp_root" "$resolver"
mv "$tmp_root/workspaces/another/worklogs/TYPE-MISSING" "$tmp_root/workspaces/another/worklogs/UNIQUE"
assert_output "an unscoped unique ticket can be located from outside a project" '/another/worklogs/UNIQUE$' \
  bash -c 'cd "$1"; source "$2"; resolve_worklog_dir UNIQUE' _ "$tmp_root" "$resolver"
assert_output "source state recognizes a clean committed checkout" "^commit:$sha$" \
  bash "$source_state" "$checkout"
printf 'changed\n' >"$checkout/source.txt"
assert_output "source state separates tracked edits from the base commit" '^worktree:[0-9a-f]+$' \
  bash "$source_state" "$checkout"
printf 'first\n' >"$checkout/new.txt"
first_state="$(bash "$source_state" "$checkout")"
printf 'other\n' >"$checkout/new.txt"
if [[ "$(bash "$source_state" "$checkout")" != "$first_state" ]]; then
  ok "source state detects edited contents at the same untracked path"
else
  bad "source state detects edited contents at the same untracked path"
fi
git -C "$checkout" checkout -- source.txt
rm "$checkout/new.txt"

current="$tmp_root/workspaces/demo/worklogs/CURRENT-STATE"
cp -R "$FIXTURES/workspaces/demo/worklogs/PASS-G9" "$current"
find "$current" -type f -name '*.md' -exec sed -i.bak 's/PASS-G9/CURRENT-STATE/g' {} \;
find "$current" -name '*.bak' -delete
for field_file in 05-impl-log.md 06b-test-evidence.md; do
  sed -i.bak -E "s/^([^\n]*Commit SHA[^a-f0-9]*)([a-f0-9]{7,})/\1$sha/" "$current/$field_file"
done
mkdir -p "$current/verification"
cp "$FIXTURES/workspaces/demo/worklogs/PASS-G9/junit-PASS-G9.xml" "$current/verification/result.xml"
report="$current/06b-test-evidence.md"
sed -i.bak "s@junit-CURRENT-STATE.xml@verification/result.xml@g" "$report"
printf '\n| Tested source | commit:%s |\n| Evidence checkout | %s |\n' "$sha" "$checkout" >>"$report"
assert_success "strict G8 verifies current committed evidence against its checkout" \
  "$CHECK" CURRENT-STATE --project demo --min G8 --strict
printf 'modified\n' >"$checkout/source.txt"
assert_failure_output "strict G8 rejects evidence for a modified checkout" 'tested source does not match' \
  "$CHECK" CURRENT-STATE --project demo --min G8 --strict
local_state="$(bash "$source_state" "$checkout")"
sed -i.bak "s/commit:$sha/$local_state/" "$report"
assert_failure_output "strict G8 rejects a local-only evidence record" 'evidence only covers local changes' \
  "$CHECK" CURRENT-STATE --project demo --min G8 --strict
assert_success "routine G8 can use local evidence without calling it commit verified" \
  "$CHECK" CURRENT-STATE --project demo --min G8
printf 'modified again\n' >"$checkout/source.txt"
assert_failure_output "routine G8 rejects stale local evidence" 'tested source does not match' \
  "$CHECK" CURRENT-STATE --project demo --min G8

# Exercise the normal checker using simulated runner artifacts, not a live app.
ui="$tmp_root/workspaces/demo/worklogs/UI-BUG"
cp -R "$current" "$ui"
sed -i.bak 's/Touches UI?\*\* ☐ No/Touches UI?** ☑ Yes ☐ No/' "$ui/02-spec.md"
assert_failure_output "UI scope requires an explicit visual decision" 'G1 FAIL:.*Visual change' \
  "$CHECK" UI-BUG --project demo --min G1
cat >>"$ui/02-spec.md" <<'EOF'

- **Visual change?** ☐ Yes ☑ No
- **UI evidence protocol:** guided-v1

## Additional acceptance cases

| AC-02 | user focuses Submit | presses Enter | confirmation appears | web |

## UI states

Successful submit shows confirmation.

## QA handoff — testable oracle

| ID | Field/action labels | Oracle type | Oracle value | Reproduction bug | Visual comparison |
|---|---|---|---|---|---|
| AC-01 | Click Submit | expected_text | Confirmation appears | BUG-01 | No |
| AC-02 | Press Enter on Submit | expected_text | Confirmation appears | No | No |
EOF
assert_failure_output "routine UI bug cannot reach build before browser reproduction" 'G5 FAIL:.*ui-verification.json' \
  "$CHECK" UI-BUG --project demo --min G5

ui_state="$(bash "$source_state" "$checkout")"
sed -i.bak "s/$local_state/$ui_state/" "$ui/06b-test-evidence.md"
mkdir -p "$ui/evidence"
python3 - "$ui/evidence" "commit:$sha" "$ui_state" <<'PY'
import base64
import json
import sys
from pathlib import Path

evidence = Path(sys.argv[1])
png = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0"
    "lEQVR42mP8/x8AAwMCAO+j3ioAAAAASUVORK5CYII="
)
case = {
    "id": "AC-01",
    "url": "http://localhost:3000/form",
    "viewport": "1280x720",
    "actor": "fixture-user",
    "locale": "en",
    "fixture": "Seeded example form",
    "steps": "Sign in and click Submit",
    "expected": "Confirmation is displayed",
}
for name, source, when, result, observed in [
    ("before", sys.argv[2], "2026-11-25T10:00:00Z", "REPRODUCED", "Confirmation missing"),
    ("after", sys.argv[3], "2026-11-25T10:05:00Z", "PASS", "Confirmation displayed"),
]:
    (evidence / f"{name}.png").write_bytes(png)
    (evidence / f"{name}.log").write_text(f"Simulated browser output: {observed}\n")
    case[name] = {
        "tool": "Fixture runner",
        "checked_at": when,
        "source": source,
        "result": result,
        "observed": observed,
        "capture": f"evidence/{name}.png",
        "log": f"evidence/{name}.log",
    }
case["before"].update(performed_by="user", confirmation="Synthetic user run for checker fixture")
(evidence / "ui-verification.json").write_text(json.dumps({"cases": [case]}))
PY
assert_failure_output "G5 requires the click-by-click diagram in addition to browser evidence" 'G5 FAIL:.*ui-repro-bug-01.md' \
  "$CHECK" UI-BUG --project demo --min G5
sed -n '/^### BUG #1:/,$p' "$ROOT/references/flow-diagram.md" >"$ui/evidence/ui-repro-bug-01.md"
assert_success "G5 accepts a guided human reproduction before build" \
  "$CHECK" UI-BUG --project demo --min G5
assert_failure_output "G8 rejects missing UI acceptance evidence" 'G8 FAIL:.*missing UI evidence for: AC-02' \
  "$CHECK" UI-BUG --project demo --min G8
python3 - "$ui/evidence/ui-verification.json" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
manifest = json.loads(path.read_text())
case = dict(manifest["cases"][0])
case.pop("before")
case.update(id="AC-02", steps="Focus Submit and press Enter")
manifest["cases"].append(case)
path.write_text(json.dumps(manifest))
PY
sed -i.bak 's/Confirmation appears | No | No/Confirmation appears | BUG-02 | No/' "$ui/02-spec.md"
assert_failure_output "G5 requires a separate diagram for a second distinct UI bug" 'G5 FAIL:.*ui-repro-bug-02.md' \
  "$CHECK" UI-BUG --project demo --min G5
sed -i.bak 's/BUG-02 | No/No | No/' "$ui/02-spec.md"
assert_success "G8 accepts verified behavior without a visual baseline" \
  "$CHECK" UI-BUG --project demo --min G8
printf '\n- G8 | Fixture owner | Simulate waiver | 2026-11-25\n' >>"$ui/INDEX.md"
mv "$ui/evidence/after.log" "$ui/after-fixture.log"
assert_failure_output "G8 requires the browser result even with a waiver" 'G8 FAIL:.*after.log' \
  "$CHECK" UI-BUG --project demo --min G8
mv "$ui/after-fixture.log" "$ui/evidence/after.log"
printf 'untested UI change\n' >"$checkout/source.txt"
assert_failure_output "G8 rejects UI results after the source changes" 'tested source does not match' \
  "$CHECK" UI-BUG --project demo --min G8
printf 'modified again\n' >"$checkout/source.txt"
sed -i.bak 's/Visual change?\*\* ☐ Yes ☑ No/Visual change?** ☑ Yes ☐ No/' "$ui/02-spec.md"
sed -i.bak 's/BUG-01 | No/BUG-01 | Yes/' "$ui/02-spec.md"
assert_failure_output "G8 blocks visual changes without a golden run" 'G8 FAIL:.*require.*golden' \
  "$CHECK" UI-BUG --project demo --min G8
python3 - "$ui/evidence" "$ui_state" <<'PY'
import json
import sys
from pathlib import Path

evidence = Path(sys.argv[1])
manifest = evidence / "ui-verification.json"
data = json.loads(manifest.read_text())
data["cases"][0]["golden"] = {
    "approval": "Fixture approved reference",
    "baseline": "evidence/baseline.png",
    "command": "fixture-runner --compare-baseline",
    "exit_code": 0,
    "source": sys.argv[2],
    "report": "evidence/golden.xml",
    "test": "submit golden",
}
manifest.write_text(json.dumps(data))
(evidence / "baseline.png").write_bytes((evidence / "after.png").read_bytes())
PY
printf '<testsuite><testcase name="submit golden"><failure>Mismatch</failure></testcase></testsuite>\n' \
  >"$ui/evidence/golden.xml"
assert_failure_output "G8 rejects a failing golden comparison" 'G8 FAIL:.*golden test did not pass' \
  "$CHECK" UI-BUG --project demo --min G8
printf '<testsuite><testcase name="submit golden"/></testsuite>\n' >"$ui/evidence/golden.xml"
assert_success "G8 accepts an approved passing golden comparison" \
  "$CHECK" UI-BUG --project demo --min G8
sed -i.bak 's/Confirmation appears | No | No/Confirmation appears | No | Yes/' "$ui/02-spec.md"
assert_failure_output "G8 requires golden evidence for every marked UI case" 'G8 FAIL:.*AC-02:.*golden comparison' \
  "$CHECK" UI-BUG --project demo --min G8
sed -i.bak 's/Confirmation appears | No | Yes/Confirmation appears | No | No/' "$ui/02-spec.md"
ui_feature="$tmp_root/workspaces/demo/worklogs/UI-FEATURE"
cp -R "$ui" "$ui_feature"
sed -i.bak 's/☑ Bug ☐ New feature/☐ Bug ☑ New feature/g' "$ui_feature/02-spec.md" "$ui_feature/INDEX.md"
sed -i.bak 's/BUG-01 | Yes/No | Yes/' "$ui_feature/02-spec.md"
rm "$ui_feature/evidence/before.png" "$ui_feature/evidence/before.log"
assert_success "a new UI feature only needs final browser and visual evidence" \
  "$CHECK" UI-FEATURE --project demo --min G8

review_open="$tmp_root/workspaces/demo/worklogs/REVIEW-OPEN"
cp -R "$FIXTURES/workspaces/demo/worklogs/PASS-G9" "$review_open"
cat >"$review_open/06-review-qa.md" <<'EOF'
## Code review findings

| ID | Sev | Status |
|---|---|---|
| R-1 | P1 | OPEN |

## AC evidence

| ID | How verified |
|---|---|
| AC-01 | Recorded test |
EOF
assert_failure_output "an open serious finding blocks a fast lane G7" 'G7 FAIL:.*still OPEN' \
  "$CHECK" REVIEW-OPEN --project demo --min G7

assert_failure "G1 rejects a worklog with no ticket Type" \
  "$CHECK" TYPE-MISSING --project demo --min G1

cp -R "$FIXTURES/workspaces/demo/worklogs/PASS-G9" "$tmp_root/workspaces/demo/worklogs/PROVENANCE-MISSING"
find "$tmp_root/workspaces/demo/worklogs/PROVENANCE-MISSING" -type f -name '*.md' -exec \
  sed -i.bak 's/PASS-G9/PROVENANCE-MISSING/g' {} \;
find "$tmp_root/workspaces/demo/worklogs/PROVENANCE-MISSING" -name '*.bak' -delete
sed -i.bak '/^## Requirement provenance$/d' \
  "$tmp_root/workspaces/demo/worklogs/PROVENANCE-MISSING/02-spec.md"
rm -f "$tmp_root/workspaces/demo/worklogs/PROVENANCE-MISSING/02-spec.md.bak"

assert_failure_output "G1 rejects requirements without a provenance section" \
  'G1 FAIL:.*Requirement provenance' \
  "$CHECK" PROVENANCE-MISSING --project demo --min G1

cp -R "$FIXTURES/workspaces/demo/worklogs/PASS-G9" "$tmp_root/workspaces/demo/worklogs/DISCOVERY-MISSING"
find "$tmp_root/workspaces/demo/worklogs/DISCOVERY-MISSING" -type f -name '*.md' -exec \
  sed -i.bak 's/PASS-G9/DISCOVERY-MISSING/g' {} \;
find "$tmp_root/workspaces/demo/worklogs/DISCOVERY-MISSING" -name '*.bak' -delete
sed -i.bak 's/Command discovery proof/Unverified note/' \
  "$tmp_root/workspaces/demo/worklogs/DISCOVERY-MISSING/04-plan.md"
rm -f "$tmp_root/workspaces/demo/worklogs/DISCOVERY-MISSING/04-plan.md.bak"

assert_failure_output "G4 rejects a plan without command discovery proof" \
  'G4 FAIL:.*Command discovery' \
  "$CHECK" DISCOVERY-MISSING --project demo --min G4 --strict

redteam="$tmp_root/workspaces/demo/worklogs/REDTEAM"
cp -R "$FIXTURES/workspaces/demo/worklogs/PASS-G9" "$redteam"
assert_success "a historical check can read a legacy plan" \
  "$CHECK" REDTEAM --project demo --min G4
assert_failure_output "an active build requires redteam for a legacy plan" 'G4 FAIL:.*missing 04b-plan-review' \
  "$CHECK" REDTEAM --project demo --min G5 --require-plan-review
sed -i.bak 's/☑ P1/☐ P1 ☑ P2/g' "$redteam/02-spec.md" "$redteam/INDEX.md"
printf '\n- **Review protocol:** redteam-v2\n' >>"$redteam/04-plan.md"
printf '\n- G4 | Fixture waiver | Fixture owner | 2026-12-31\n' >>"$redteam/INDEX.md"
assert_failure_output "new P2 plans cannot waive a missing redteam review" 'G4 FAIL:.*missing 04b-plan-review' \
  "$CHECK" REDTEAM --project demo --min G4
review_plan="$redteam/04b-plan-review.md"
cp "$ROOT/templates/04b-plan-review.md" "$review_plan"
plan_sha="$(bash "$ROOT/bin/plan-review-state.sh" "$redteam")"
sed -i.bak "s/| Plan review state | |/| Plan review state | $plan_sha |/; s/| Review mode | |/| Review mode | same-session |/; s/| Review verdict | REVISE |/| Review verdict | PASS |/" "$review_plan"
assert_failure_output "G4 blocks an OPEN finding even with a PASS label" 'G4 FAIL:.*open redteam finding RT-01' \
  "$CHECK" REDTEAM --project demo --min G4
sed -i.bak 's/| OPEN |/| CLEARED |/' "$review_plan"
assert_failure_output "G4 rejects a review with blank evidence and resolution" 'G4 FAIL:.*incomplete redteam evidence' \
  "$CHECK" REDTEAM --project demo --min G4
sed -i.bak '/^| RT-01 |/d' "$review_plan"
printf '| RT-01 | Other callers reuse submit | AC-01 and form handler | Duplicate confirmation on retry | P1 | FIXED | Plan now includes one confirmation assertion on retry. |\n' >>"$review_plan"
assert_success "G4 accepts resolved counterexamples for the reviewed plan" \
  "$CHECK" REDTEAM --project demo --min G4
printf '\nCheck the revised retry case.\n' >>"$redteam/04-plan.md"
assert_failure_output "G4 rejects an older review after the plan changes" 'G4 FAIL:.*does not match the current plan' \
  "$CHECK" REDTEAM --project demo --min G5 --require-plan-review
printf '\nAcceptance now requires exactly one confirmation per retry.\n' >>"$redteam/02-spec.md"
revised_sha="$(bash "$ROOT/bin/plan-review-state.sh" "$redteam")"
sed -i.bak "s/$plan_sha/$revised_sha/" "$review_plan"
assert_success "a rechecked current revision clears the pre-build checker" \
  "$CHECK" REDTEAM --project demo --min G5 --require-plan-review
printf '\nRelease approval was recorded after the original review.\n' >>"$redteam/03b-human-confirm.md"
assert_output "a later sign-off note does not invalidate the reviewed plan" "^$revised_sha$" \
  bash "$ROOT/bin/plan-review-state.sh" "$redteam"
printf '\nThe default retry behavior is now different.\n' >>"$redteam/02-spec.md"
assert_failure_output "G4 reopens review when the spec changes without a plan edit" 'G4 FAIL:.*does not match the current plan and decisions' \
  "$CHECK" REDTEAM --project demo --min G5 --require-plan-review
sed -i.bak 's/ANSWERED/OPEN/' "$redteam/03-qa-log.md"
latest_sha="$(bash "$ROOT/bin/plan-review-state.sh" "$redteam")"
sed -i.bak "s/$revised_sha/$latest_sha/" "$review_plan"
assert_failure_output "pre-build checker rejects recorded open questions in the fast lane" 'G5 FAIL:.*OPEN question' \
  "$CHECK" REDTEAM --project demo --min G5 --require-plan-review

approved="$tmp_root/workspaces/demo/worklogs/APPROVED"
cp -R "$FIXTURES/workspaces/demo/worklogs/PASS-G9" "$approved"
sed -i.bak 's/PASS-G9 trongdn2405/APPROVED Nguyễn Thị Ánh/' "$approved/INDEX.md" "$approved/03b-human-confirm.md"
assert_success "strict G3 accepts matching Unicode approver names" \
  "$CHECK" APPROVED --project demo --min G3 --strict
sed -i.bak 's/Nguyễn Thị Ánh/Lê Văn Bình/' "$approved/03b-human-confirm.md"
assert_failure_output "strict G3 rejects differing approval records" 'G3 FAIL:.*signatures differ' \
  "$CHECK" APPROVED --project demo --min G3 --strict

bad_report="$tmp_root/workspaces/demo/worklogs/BAD-REPORT"
cp -R "$FIXTURES/workspaces/demo/worklogs/PASS-G9" "$bad_report"
printf "<testsuite failures='1'><testcase name='submit'/></testsuite>\n" >"$bad_report/junit-PASS-G9.xml"
assert_failure_output "routine G8 rejects a failed final JUnit report" 'G8 FAIL:.*JUnit reports failures' \
  "$CHECK" BAD-REPORT --project demo --min G8
rm "$bad_report/junit-PASS-G9.xml"
assert_failure_output "routine G8 rejects a missing cited report" 'G8 FAIL:.*missing or empty junit/log' \
  "$CHECK" BAD-REPORT --project demo --min G8

cp -R "$FIXTURES/workspaces/demo/worklogs/PASS-G9" "$tmp_root/workspaces/demo/worklogs/LEDGER-MISSING"
find "$tmp_root/workspaces/demo/worklogs/LEDGER-MISSING" -type f -name '*.md' -exec \
  sed -i.bak 's/PASS-G9/LEDGER-MISSING/g' {} \;
find "$tmp_root/workspaces/demo/worklogs/LEDGER-MISSING" -name '*.bak' -delete
sed -i.bak 's/^## Executed-command ledger$/## Commands omitted/' \
  "$tmp_root/workspaces/demo/worklogs/LEDGER-MISSING/06b-test-evidence.md"
rm -f "$tmp_root/workspaces/demo/worklogs/LEDGER-MISSING/06b-test-evidence.md.bak"

assert_failure_output "G8 rejects test evidence without an executed-command ledger" \
  'G8 FAIL:.*executed-command ledger' \
  "$CHECK" LEDGER-MISSING --project demo --min G8

cp -R "$FIXTURES/workspaces/demo/worklogs/PASS-G9" "$tmp_root/workspaces/demo/worklogs/AUDIT-BYPASS"
find "$tmp_root/workspaces/demo/worklogs/AUDIT-BYPASS" -type f -name '*.md' -exec \
  sed -i.bak 's/PASS-G9/AUDIT-BYPASS/g' {} \;
find "$tmp_root/workspaces/demo/worklogs/AUDIT-BYPASS" -name '*.bak' -delete
cat >"$tmp_root/workspaces/demo/worklogs/AUDIT-BYPASS/08-semantic-audit.md" <<'EOF'
# 08 Semantic audit
### C1 — Conflict claim Proposal ↔ Decision
☑ INCOHERENT
## Routing
| C1 | :clarify | decision does not answer proposal |
AUDIT CONFIRM: AUDIT-BYPASS Human 2026-08-14
☑ PASS
EOF

assert_failure_output "AUDIT rejects INCOHERENT even when routing and PASS are present" \
  'AUDIT FAIL:.*INCOHERENT' \
  "$CHECK" AUDIT-BYPASS --project demo --min AUDIT

cp -R "$FIXTURES/workspaces/demo/worklogs/PASS-G9" "$tmp_root/workspaces/demo/worklogs/AUDIT-NO-EVIDENCE"
find "$tmp_root/workspaces/demo/worklogs/AUDIT-NO-EVIDENCE" -type f -name '*.md' -exec \
  sed -i.bak 's/PASS-G9/AUDIT-NO-EVIDENCE/g' {} \;
find "$tmp_root/workspaces/demo/worklogs/AUDIT-NO-EVIDENCE" -name '*.bak' -delete
{
  echo '# 08 Semantic audit'
  for pair in 1 2 3 4 5 6 7 8; do
    echo "### C$pair — pair"
    echo '☑ COHERENT'
    echo '**REASON:** superficially filled reason'
  done
  echo 'AUDIT CONFIRM: AUDIT-NO-EVIDENCE Human 2026-08-14'
  echo '☑ PASS'
} >"$tmp_root/workspaces/demo/worklogs/AUDIT-NO-EVIDENCE/08-semantic-audit.md"

assert_failure_output "AUDIT rejects verdicts without two quoted evidence strings" \
  'AUDIT FAIL:.*quoted evidence' \
  "$CHECK" AUDIT-NO-EVIDENCE --project demo --min AUDIT

cp -R "$FIXTURES/workspaces/demo/worklogs/PASS-G9" "$tmp_root/workspaces/demo/worklogs/AUDIT-PASS"
find "$tmp_root/workspaces/demo/worklogs/AUDIT-PASS" -type f -name '*.md' -exec \
  sed -i.bak 's/PASS-G9/AUDIT-PASS/g' {} \;
find "$tmp_root/workspaces/demo/worklogs/AUDIT-PASS" -name '*.bak' -delete
mv "$tmp_root/workspaces/demo/worklogs/AUDIT-PASS/junit-PASS-G9.xml" \
  "$tmp_root/workspaces/demo/worklogs/AUDIT-PASS/junit-AUDIT-PASS.xml"
{
  echo '# 08 Semantic audit'
  for pair in 1 2 3 4 5 6 7 8; do
    echo "### C$pair — pair"
    echo 'SIDE A: "specific source evidence A"'
    echo 'SIDE B: "specific source evidence B"'
    echo '☑ COHERENT'
    echo '**REASON:** both quoted sides agree on the stated behavior'
  done
  echo 'AUDIT CONFIRM: AUDIT-PASS Human 2026-08-14'
  echo '☑ PASS'
} >"$tmp_root/workspaces/demo/worklogs/AUDIT-PASS/08-semantic-audit.md"

assert_success "AUDIT accepts eight resolved evidence-backed pairs with human sign-off" \
  "$CHECK" AUDIT-PASS --project demo --min AUDIT

# Template-conformance check: an author who fills templates/06b-test-evidence.md's OWN shape
# exactly (not a fixture, not a previously-working example) must reach G8 PASS. This guards
# against template/checker drift that a fixture-only suite can't see — a fixture keeps working
# forever even if the shipped template stops matching what the checker requires (this exact class
# of bug shipped once: templates/06b-test-evidence.md's `**Dev:**` sign-off line was accidentally
# dropped in an editing pass and no fixture caught it, because fixtures don't derive from the
# template file).
cp -R "$FIXTURES/workspaces/demo/worklogs/PASS-G9" "$tmp_root/workspaces/demo/worklogs/TEMPLATE-CONFORMANCE"
find "$tmp_root/workspaces/demo/worklogs/TEMPLATE-CONFORMANCE" -type f -name '*.md' -exec \
  sed -i.bak 's/PASS-G9/TEMPLATE-CONFORMANCE/g' {} \;
find "$tmp_root/workspaces/demo/worklogs/TEMPLATE-CONFORMANCE" -name '*.bak' -delete
printf '<testsuite tests="1" failures="0"><testcase name="ac01"/></testsuite>\n' \
  >"$tmp_root/workspaces/demo/worklogs/TEMPLATE-CONFORMANCE/junit.xml"
python3 - "$ROOT/templates/06b-test-evidence.md" \
  "$tmp_root/workspaces/demo/worklogs/TEMPLATE-CONFORMANCE/06b-test-evidence.md" <<'PY'
import re, sys
src, dst = sys.argv[1], sys.argv[2]
text = open(src).read()
fills = {
  r'\[Feature_Name\]': 'TEMPLATE-CONFORMANCE',
  r'\[ID\]': 'TEMPLATE-CONFORMANCE',
  r'☐ Yes ☐ No \(copy from `02-spec`\)': '☑ No',
  r'☐ P0 ☐ P1 ☐ P2': '☑ P1',
  r'\[40-char or short SHA\]': 'abcdef1234567890',
  r'\[https://… or N/A-local\]': 'N/A-local',
  r'\[local path \(optional with CI run URL\)\]': 'junit.xml',
  r'\[name\]': 'fixture',
  r'# paste test runner output here': 'rspec\nFinished in 0.12 seconds\n3 examples, 0 failures',
  r'\| \| \| \| \| \| \| N/A \|': '| `rspec` | api | 2026-08-11T10:00Z / 2026-08-11T10:01Z | 0 | raw output above | AC-01 | N/A |',
  r'\| AC-01 \| \| \| \|': '| AC-01 | test_ac01:1 `expect(success)` | missing success result | assertion passed |',
  r'\| AC-01 \| \| \|': '| AC-01 | N/A | no UI |',
  r'\| Unit \| \| \| \| \| ☐ PASS ☐ FAIL \|': '| Unit | 3 | 3 | 0 | 0 | ☑ PASS |',
  r'\*\*Overall:\*\* ☐ PASS \(zero failures\) ☐ FAIL': '**Overall:** ☑ PASS (zero failures) ☐ FAIL',
  r'\*\*G8 verdict:\*\* ☐ PASS ☐ FAIL': '**G8 verdict:** ☑ PASS ☐ FAIL',
}
for pattern, repl in fills.items():
    text = re.sub(pattern, repl, text)
open(dst, 'w').write(text)
PY

assert_success "template-conformance: 06b-test-evidence.md's own shape reaches G8 PASS" \
  "$CHECK" TEMPLATE-CONFORMANCE --project demo --min G8 --strict

if grep -q 'case.*Bug\|Bug)' "$ROOT/references/clarify-check.md" &&
   grep -q 'New feature' "$ROOT/references/clarify-check.md" &&
   grep -q 'Spec change' "$ROOT/references/clarify-check.md" &&
   grep -q 'Requirement change' "$ROOT/references/clarify-check.md"; then
  ok "clarify-check dispatches all four ticket types"
else
  bad "clarify-check dispatches all four ticket types"
fi

printf 'RESULT: %s passed, %s failed\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]

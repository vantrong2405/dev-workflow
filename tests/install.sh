#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAGE_COUNT="$(bash "$ROOT/install.sh" --list-stages | wc -l | tr -d ' ')"
PASS=0
FAIL=0

ok() { printf 'PASS: %s\n' "$1"; PASS=$((PASS + 1)); }
bad() { printf 'FAIL: %s\n' "$1"; FAIL=$((FAIL + 1)); }

new_home() {
  TEST_HOME="$(mktemp -d)"
  TEST_BIN="$TEST_HOME/bin"
  mkdir -p "$TEST_BIN"
  printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >>"$HOME/agy.calls"\n' >"$TEST_BIN/agy"
  chmod +x "$TEST_BIN/agy"
}

run_install() {
  HOME="$TEST_HOME" PATH="$TEST_BIN:$PATH" bash "$ROOT/install.sh" "$@" \
    >"$TEST_HOME/install.out" 2>"$TEST_HOME/install.err"
}

run_install_without_agy() {
  HOME="$TEST_HOME" PATH="/usr/bin:/bin" bash "$ROOT/install.sh" "$@" \
    >"$TEST_HOME/install.out" 2>"$TEST_HOME/install.err"
}

run_installed_handoff_checks() {
  local plugin="$1" workspaces="$TEST_HOME/workspaces"
  mkdir -p "$workspaces"
  cp -R "$ROOT/fixtures/workspaces/demo" "$workspaces/demo"
  sed 's/<project-slug>/demo/g; s/<language-code>/vi/g; s/interview:\*\* pending/interview:** skipped/' \
    "$plugin/shared/templates/workspaces/_project/PROJECT-FORM.md" >"$workspaces/demo/PROJECT-FORM.md"
  rm "$workspaces/demo/domain-knowledge/INDEX.md"
  (
    export AK_PLUGIN="$plugin" AK_WORKSPACES_ROOT="$workspaces"
    bash "$plugin/bin/check-workspace.sh" demo &&
      bash "$plugin/bin/check-gates.sh" PASS-G8 --project demo --min tests
  ) >"$TEST_HOME/handoff.out" 2>"$TEST_HOME/handoff.err"
}

new_home
if run_install &&
   [[ -L "$TEST_HOME/.claude/plugins/ak" ]] &&
   [[ -f "$TEST_HOME/.claude/commands/ak:audit.md" ]] &&
   [[ ! -e "$TEST_HOME/.cursor" ]] &&
   [[ ! -e "$TEST_HOME/.codex" ]] &&
   [[ ! -e "$TEST_HOME/agy.calls" ]]; then
  ok "default installs Claude only"
else
  bad "default installs Claude only"
fi

new_home
if run_install --claude &&
   [[ -L "$TEST_HOME/.claude/plugins/ak" ]] &&
   [[ ! -e "$TEST_HOME/.cursor" ]] &&
   [[ ! -e "$TEST_HOME/.codex" ]]; then
  ok "--claude installs Claude only"
else
  bad "--claude installs Claude only"
fi

if [[ "$(rg -l '^disable-model-invocation: false$' "$ROOT"/skills/*/SKILL.md | wc -l | tr -d ' ')" -eq "$STAGE_COUNT" ]]; then
  ok "all source skills permit model invocation"
else
  bad "all source skills permit model invocation"
fi

new_home
if run_install --host cursor &&
   [[ -L "$TEST_HOME/.cursor/skills/ak-audit" ]] &&
   [[ "$(find "$TEST_HOME/.cursor/skills" -maxdepth 1 -type l -name 'ak-*' | wc -l | tr -d ' ')" -eq "$STAGE_COUNT" ]] &&
   [[ -f "$TEST_HOME/.cursor/commands/ak:audit.md" ]] &&
   [[ ! -e "$TEST_HOME/.claude" ]] &&
   cmp -s "$ROOT/skills/audit/SKILL.md" "$TEST_HOME/.cursor/skills/ak-audit/SKILL.md"; then
  ok "Cursor receives full live stage skills"
else
  bad "Cursor receives full live stage skills"
fi

new_home
if run_install --cursor &&
   [[ -L "$TEST_HOME/.cursor/skills/ak-audit" ]] &&
   [[ ! -e "$TEST_HOME/.claude" ]]; then
  ok "--cursor aliases Cursor-only install"
else
  bad "--cursor aliases Cursor-only install"
fi

new_home
if run_install --host codex &&
   [[ -L "$TEST_HOME/.codex/skills/ak-audit" ]] &&
   [[ "$(find "$TEST_HOME/.codex/skills" -maxdepth 1 -type l -name 'ak-*' | wc -l | tr -d ' ')" -eq "$STAGE_COUNT" ]] &&
   [[ -L "$TEST_HOME/.codex/plugins/ak" ]] &&
   [[ -L "$TEST_HOME/.agents/plugins/plugins/ak" ]] &&
   grep -q '"path": "./plugins/ak"' "$TEST_HOME/.agents/plugins/marketplace.json" &&
   [[ ! -e "$TEST_HOME/.claude" ]]; then
  ok "Codex receives full live skills and canonical marketplace source"
else
  bad "Codex receives full live skills and canonical marketplace source"
fi

new_home
if run_install --codex &&
   [[ -L "$TEST_HOME/.codex/skills/ak-audit" ]] &&
   [[ ! -e "$TEST_HOME/.claude" ]]; then
  ok "--codex aliases Codex-only install"
else
  bad "--codex aliases Codex-only install"
fi

new_home
if run_install --host antigravity &&
   grep -q "plugin install $ROOT/hosts/antigravity" "$TEST_HOME/agy.calls" &&
   [[ -f "$ROOT/hosts/antigravity/flat-skills/start.md" ]] &&
   [[ -f "$ROOT/hosts/antigravity/templates/workspaces/_project/PROJECT-FORM.md" ]] &&
   [[ -f "$ROOT/hosts/antigravity/bin/source-state.sh" ]] &&
   [[ ! -e "$TEST_HOME/.claude" ]]; then
  ok "Antigravity bundle is installed through agy"
else
  bad "Antigravity bundle is installed through agy"
fi

new_home
install_target="$TEST_HOME/product"
project_install="$install_target/.claude"
if run_install --path "$install_target" --only start &&
   run_install --path "$install_target" --only start &&
   [[ -f "$project_install/commands/ak.md" ]] &&
   [[ -f "$project_install/skills/ak-start/SKILL.md" ]] &&
   [[ -f "$project_install/skills/ak-start/references/project-form.md" ]] &&
   [[ -f "$project_install/skills/ak-learning/templates/workspaces/_project/PROJECT-FORM.md" ]] &&
   [[ -f "$project_install/skills/ak-audit/SKILL.md" ]] &&
   [[ -f "$project_install/skills/ak-redteam/SKILL.md" ]] &&
   [[ -f "$project_install/skills/ak-redteam/templates/04b-plan-review.md" ]] &&
   [[ -f "$project_install/commands/ak:redteam.md" ]] &&
   [[ -f "$project_install/skills/ak-flow-diagram/SKILL.md" ]] &&
   [[ -x "$project_install/bin/plan-review-state.sh" ]] &&
   [[ ! -e "$project_install/skills/ak-feedback" ]] &&
   [[ -f "$project_install/bin/lib/project-form.sh" ]] &&
   [[ -f "$project_install/bin/lib/verify-ui-evidence.py" ]] &&
   [[ -f "$project_install/skills/ak-test/templates/ui-verification.json" ]] &&
   [[ -f "$project_install/skills/ak-clarify/references/ui-verification.md" ]] &&
   [[ -x "$project_install/bin/source-state.sh" ]] &&
   [[ ! -e "$project_install/bin/lib/lib" ]] &&
   run_installed_handoff_checks "$project_install"; then
  ok "self-contained start bundle keeps onboarding and delivery available on reinstall"
else
  bad "self-contained start bundle keeps onboarding and delivery available on reinstall"
fi

new_home
project_install="$TEST_HOME/vibe-app/.claude"
if run_install --path "$TEST_HOME/vibe-app" --only vibe &&
   [[ -f "$project_install/commands/ak:vibe.md" ]] &&
   [[ -f "$project_install/skills/ak-vibe/SKILL.md" ]] &&
   [[ -f "$project_install/skills/ak-vibe/preview/package-lock.json" ]] &&
   [[ -f "$project_install/skills/ak-vibe/preview/render.mjs" ]] &&
   [[ -f "$project_install/skills/ak-vibe-design/SKILL.md" ]] &&
   [[ -f "$project_install/skills/ak-vibe-design/templates/vibe/design.md" ]] &&
   [[ -x "$project_install/bin/vibe-specs.sh" ]] &&
   [[ -f "$project_install/bin/lib/vibe_specs.py" ]] &&
   [[ -f "$project_install/shared/templates/vibe/spec-archive/spec.md" ]] &&
   [[ -f "$project_install/skills/ak-vibe/templates/vibe/plan.md" ]] &&
   [[ -f "$project_install/skills/ak-vibe/templates/vibe/redteam.md" ]] &&
   [[ -f "$project_install/skills/ak-redteam/SKILL.md" ]] &&
   [[ -f "$project_install/skills/ak-test/SKILL.md" ]]; then
  ok "self-contained Vibe bundles its mockups, templates and delivery stages"
else
  bad "self-contained Vibe bundles its mockups, templates and delivery stages"
fi

new_home
if run_install --host codex --only build &&
   [[ -f "$TEST_HOME/.codex/skills/ak-build/SKILL.md" ]] &&
   [[ -f "$TEST_HOME/.codex/skills/ak-plan/SKILL.md" ]] &&
   [[ -f "$TEST_HOME/.codex/skills/ak-redteam/SKILL.md" ]] &&
   [[ -f "$TEST_HOME/.codex/skills/ak-flow-diagram/SKILL.md" ]] &&
   [[ ! -e "$TEST_HOME/.codex/skills/ak-ship" ]]; then
  ok "standalone build bundles planning and the required redteam review"
else
  bad "standalone build bundles planning and the required redteam review"
fi

new_home
if run_install --agy &&
   grep -q "plugin install $ROOT/hosts/antigravity" "$TEST_HOME/agy.calls" &&
   [[ ! -e "$TEST_HOME/.claude" ]]; then
  ok "--agy aliases Antigravity-only install"
else
  bad "--agy aliases Antigravity-only install"
fi

new_home
if run_install --host all &&
   [[ -L "$TEST_HOME/.claude/plugins/ak" ]] &&
   [[ -L "$TEST_HOME/.cursor/skills/ak-audit" ]] &&
   [[ -L "$TEST_HOME/.codex/skills/ak-audit" ]] &&
   grep -q 'plugin install' "$TEST_HOME/agy.calls"; then
  ok "all installs every supported host"
else
  bad "all installs every supported host"
fi

new_home
if run_install --all &&
   [[ -L "$TEST_HOME/.claude/plugins/ak" ]] &&
   [[ -L "$TEST_HOME/.cursor/skills/ak-audit" ]] &&
   [[ -L "$TEST_HOME/.codex/skills/ak-audit" ]] &&
   grep -q 'plugin install' "$TEST_HOME/agy.calls"; then
  ok "--all installs every supported host"
else
  bad "--all installs every supported host"
fi

new_home
if run_install_without_agy --host all; then
  bad "all preflight rejects missing agy before partial install"
elif [[ ! -e "$TEST_HOME/.claude" && ! -e "$TEST_HOME/.cursor" && ! -e "$TEST_HOME/.codex" ]]; then
  ok "all preflight rejects missing agy before partial install"
else
  bad "all preflight rejects missing agy before partial install"
fi

new_home
if run_install --host unknown; then
  bad "unknown host is rejected"
else
  ok "unknown host is rejected"
fi

new_home
if run_install --cursor --codex; then
  bad "conflicting shorthand targets are rejected"
else
  ok "conflicting shorthand targets are rejected"
fi

printf 'RESULT: %s passed, %s failed\n' "$PASS" "$FAIL"
[[ "$FAIL" -eq 0 ]]

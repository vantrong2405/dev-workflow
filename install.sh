#!/usr/bin/env bash
# Install ak for one coding agent, or all supported agents.
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ALL_STAGES=(decompose start learning coaching spec clarify confirm plan build review fix test check ship audit status clean feedback flow-diagram)
STAGES=("${ALL_STAGES[@]}")
VENDORED_SKILLS=(grilling tdd)
TARGET_HOST="claude"
TARGET_EXPLICIT=0
PROJECT_CLAUDE_CMDS="${AK_PROJECT_CLAUDE_COMMANDS:-}"
INSTALL_PATH=""
ONLY_RAW=""

usage() {
  cat <<'EOF'
Usage: bash install.sh [--claude|--cursor|--codex|--agy|--all]
       bash install.sh [--host|--agent] claude|cursor|codex|antigravity|all
       bash install.sh --path <dir>

Default: claude

Options:
  --claude               Install only for Claude Code (global, ~/.claude)
  --cursor               Install only for Cursor (global)
  --codex                Install only for Codex (global)
  --agy, --antigravity   Install only for Antigravity (global)
  --all                  Install for every supported coding agent (global)
  --host, --agent <name>  Install only that coding agent, or all
  --path <dir>            Install self-contained into <dir>/.claude — no global
                           ~/.claude touched, no dependency on this clone afterward
  --only <a,b,c>          Install just these stages instead of all of them
                           (e.g. --only spec,clarify,build,review). Combine
                           freely with --path or any host flag.
  --list-hosts            Print supported coding agents
  --list-stages           Print every installable stage name
  -h, --help              Show this help

Examples:
  bash install.sh                                  # Claude only, global, all stages
  bash install.sh --cursor                         # Cursor only, global
  bash install.sh --codex                          # Codex only, global
  bash install.sh --agy                            # Antigravity only, global
  bash install.sh --all                            # Every supported agent, global
  bash install.sh --path ~/projects/my-app         # Just that project, nothing global
  bash install.sh --path ~/projects/my-app --only spec,build,review
EOF
}

select_target() {
  local requested="$1"
  if [[ "$TARGET_EXPLICIT" -eq 1 && "$TARGET_HOST" != "$requested" ]]; then
    echo "ERROR: conflicting install targets '$TARGET_HOST' and '$requested'; choose exactly one target" >&2
    usage >&2
    exit 2
  fi
  TARGET_HOST="$requested"
  TARGET_EXPLICIT=1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --path)
      [[ $# -ge 2 ]] || { echo "ERROR: --path requires a directory" >&2; usage >&2; exit 2; }
      INSTALL_PATH="$2"
      shift 2
      ;;
    --only)
      [[ $# -ge 2 ]] || { echo "ERROR: --only requires a comma-separated stage list" >&2; usage >&2; exit 2; }
      ONLY_RAW="$2"
      shift 2
      ;;
    --list-stages)
      printf '%s\n' "${ALL_STAGES[@]}"
      exit 0
      ;;
    --host|--agent)
      [[ $# -ge 2 ]] || { echo "ERROR: $1 requires a host" >&2; usage >&2; exit 2; }
      select_target "$2"
      shift 2
      ;;
    --claude) select_target claude; shift ;;
    --cursor) select_target cursor; shift ;;
    --codex) select_target codex; shift ;;
    --agy|--antigravity) select_target antigravity; shift ;;
    --all) select_target all; shift ;;
    --list-hosts)
      echo "claude cursor codex antigravity all"
      exit 0
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    claude|cursor|codex|antigravity|all)
      select_target "$1"
      shift
      ;;
    *)
      echo "ERROR: unsupported host '$1'" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -n "$INSTALL_PATH" && "$TARGET_EXPLICIT" -eq 1 ]]; then
  echo "ERROR: --path is standalone — do not combine it with --claude/--cursor/--codex/--agy/--all" >&2
  exit 2
fi

if [[ -n "$ONLY_RAW" ]]; then
  STAGES=()
  IFS=',' read -ra _requested <<< "$ONLY_RAW"
  for _s in "${_requested[@]}"; do
    _s="$(echo "$_s" | tr -d '[:space:]')"
    [[ -z "$_s" ]] && continue
    _known=0
    for _a in "${ALL_STAGES[@]}"; do
      [[ "$_a" == "$_s" ]] && { _known=1; break; }
    done
    if [[ "$_known" -eq 0 ]]; then
      echo "ERROR: unknown stage '$_s' — run 'bash install.sh --list-stages' for valid names" >&2
      exit 2
    fi
    STAGES+=("$_s")
  done
  [[ "${#STAGES[@]}" -gt 0 ]] || { echo "ERROR: --only matched no stages" >&2; exit 2; }
fi

case "$TARGET_HOST" in
  claude|cursor|codex|antigravity|all) ;;
  *) echo "ERROR: unsupported host '$TARGET_HOST'" >&2; usage >&2; exit 2 ;;
esac

echo "==> Plugin: $PLUGIN_DIR (v0.4.0)"
if [[ -n "$INSTALL_PATH" ]]; then
  echo "==> Target: $INSTALL_PATH (self-contained, no global)"
else
  echo "==> Target: $TARGET_HOST"
fi
if [[ -n "$ONLY_RAW" ]]; then
  echo "==> Stages (${#STAGES[@]}/${#ALL_STAGES[@]}): ${STAGES[*]}"
fi

if [[ -z "$INSTALL_PATH" && ( "$TARGET_HOST" == "antigravity" || "$TARGET_HOST" == "all" ) ]]; then
  command -v agy >/dev/null 2>&1 || {
    echo "ERROR: agy CLI not found; no host was installed" >&2
    exit 1
  }
fi

prepare_source() {
  local s local_dest
  for _bin in check-gates.sh check-workspace.sh clean-worklog.sh pilot-score.sh; do
    if [[ -f "$PLUGIN_DIR/bin/$_bin" ]]; then
      chmod +x "$PLUGIN_DIR/bin/$_bin"
    fi
  done

  for s in "${STAGES[@]}"; do
    local_dest="$PLUGIN_DIR/skills/$s"
    [[ -d "$local_dest" ]] || { echo "ERROR: missing skill directory $local_dest" >&2; exit 1; }
    [[ -f "$local_dest/SKILL.md" ]] || { echo "ERROR: missing $local_dest/SKILL.md" >&2; exit 1; }
    rm -rf "$local_dest/references" "$local_dest/templates"
    ln -sfn ../../references "$local_dest/references"
    ln -sfn ../../templates "$local_dest/templates"
  done
}

install_stage_links() {
  local dest_root="$1" label="$2" s src dest
  mkdir -p "$dest_root"
  for s in "${STAGES[@]}"; do
    src="$PLUGIN_DIR/skills/$s"
    dest="$dest_root/ak-$s"
    rm -rf "$dest"
    ln -sfn "$src" "$dest"
    echo "  [$label] ak-$s -> $src"
  done
  rm -rf "$dest_root/ak-qa"
}

stage_selected() {
  local name="$1" s
  for s in "${STAGES[@]}"; do
    [[ "$s" == "$name" ]] && return 0
  done
  return 1
}

install_colon_commands() {
  local dest="$1" label="$2" src f base stage
  mkdir -p "$dest"
  shopt -s nullglob
  for src in "$PLUGIN_DIR"/commands/ak.md "$PLUGIN_DIR"/commands/ak:*.md; do
    [[ -f "$src" ]] || continue
    base="$(basename "$src")"
    if [[ "$base" == "ak.md" ]]; then
      stage="start"
    else
      stage="${base#ak:}"; stage="${stage%.md}"
    fi
    stage_selected "$stage" || continue
    cp "$src" "$dest/$base"
    echo "  [$label] $base"
  done
  for f in "$dest"/ak-*.md; do
    [[ -e "$f" ]] || continue
    rm -f "$f"
  done
  shopt -u nullglob
}

install_vendored_skill_if_missing() {
  local name="$1"
  local dest_root="$2"
  local label="$3"
  local dest="$dest_root/$name"
  local vendor_src="$PLUGIN_DIR/skills/_vendor/$name"
  if [[ -e "$dest" || -L "$dest" ]]; then
    echo "  [$label] $name already present, skipping"
    return
  fi
  [[ -d "$vendor_src" ]] || { echo "  [$label] WARNING: no vendored copy of $name, skipping" >&2; return; }
  mkdir -p "$dest_root"
  ln -sfn "$vendor_src" "$dest"
  echo "  [$label] installed $name (vendored by ak)"
}

install_vendored_skills_if_missing() {
  local dest_root="$1" label="$2" name
  for name in "${VENDORED_SKILLS[@]}"; do
    install_vendored_skill_if_missing "$name" "$dest_root" "$label"
  done
}

install_claude() {
  echo "==> Claude Code"
  mkdir -p "$HOME/.claude/skills" "$HOME/.claude/plugins" "$HOME/.claude/commands"
  ln -sfn "$PLUGIN_DIR" "$HOME/.claude/skills/ak-plugin"
  ln -sfn "$PLUGIN_DIR" "$HOME/.claude/plugins/ak"
  install_colon_commands "$HOME/.claude/commands" "claude-command"
  if [[ -n "$PROJECT_CLAUDE_CMDS" ]]; then
    install_colon_commands "$PROJECT_CLAUDE_CMDS" "project-claude-command"
  fi
  install_vendored_skills_if_missing "$HOME/.claude/skills" "claude-skill"
  echo "  Reload plugins, then run /ak:status"
}

install_cursor() {
  echo "==> Cursor"
  mkdir -p "$HOME/.cursor/commands" "$HOME/.cursor/skills"
  install_colon_commands "$HOME/.cursor/commands" "cursor-command"
  rm -rf "$HOME/.cursor/skills/ak"
  install_stage_links "$HOME/.cursor/skills" "cursor-skill"
  install_vendored_skills_if_missing "$HOME/.cursor/skills" "cursor-skill"
  echo "  Restart/reload Cursor, then run /ak:status"
}

install_codex_marketplace_seed() {
  local marketplace_root="$HOME/.agents/plugins"
  local marketplace="$marketplace_root/marketplace.json"
  mkdir -p "$marketplace_root/plugins"
  ln -sfn "$PLUGIN_DIR" "$marketplace_root/plugins/ak"
  if [[ ! -f "$marketplace" ]]; then
    cat >"$marketplace" <<'EOF'
{
  "name": "personal",
  "interface": { "displayName": "Personal" },
  "plugins": [
    {
      "name": "ak",
      "source": { "source": "local", "path": "./plugins/ak" },
      "policy": { "installation": "AVAILABLE", "authentication": "ON_INSTALL" },
      "category": "Productivity"
    }
  ]
}
EOF
    echo "  [codex] created personal marketplace seed"
  else
    echo "  [codex] preserved existing personal marketplace"
  fi
}

install_codex() {
  echo "==> Codex"
  mkdir -p "$HOME/.codex/skills" "$HOME/.codex/plugins"
  install_stage_links "$HOME/.codex/skills" "codex-skill"
  install_vendored_skills_if_missing "$HOME/.codex/skills" "codex-skill"
  ln -sfn "$PLUGIN_DIR" "$HOME/.codex/plugins/ak"
  install_codex_marketplace_seed
  echo "  Start a new Codex task so the refreshed skills are discovered"
}

install_antigravity() {
  echo "==> Antigravity"
  bash "$PLUGIN_DIR/hosts/antigravity/rebuild.sh"
  agy plugin validate "$PLUGIN_DIR/hosts/antigravity"
  agy plugin install "$PLUGIN_DIR/hosts/antigravity"
  echo "  Restart/reload Antigravity, then run /ak:status"
}

# Self-contained project install: real copies under <dir>/.claude, no ~/.claude touched,
# and nothing left depending on this clone once it's done.
install_path() {
  local target
  target="$(mkdir -p "$1" && cd "$1" && pwd)"
  local dest="$target/.claude"
  local s

  echo "==> Project path: $target"
  mkdir -p "$dest/commands" "$dest/skills" "$dest/shared" "$dest/bin"

  install_colon_commands "$dest/commands" "project-command"

  rm -rf "$dest/shared/references" "$dest/shared/templates"
  cp -R "$PLUGIN_DIR/references" "$dest/shared/references"
  cp -R "$PLUGIN_DIR/templates" "$dest/shared/templates"

  for s in "${STAGES[@]}"; do
    rm -rf "$dest/skills/ak-$s"
    cp -R "$PLUGIN_DIR/skills/$s" "$dest/skills/ak-$s"
    rm -rf "$dest/skills/ak-$s/references" "$dest/skills/ak-$s/templates"
    ln -sfn ../../shared/references "$dest/skills/ak-$s/references"
    ln -sfn ../../shared/templates "$dest/skills/ak-$s/templates"
  done
  echo "  [project-skill] ${#STAGES[@]} stages copied under $dest/skills"

  cp "$PLUGIN_DIR"/bin/*.sh "$dest/bin/"
  cp -R "$PLUGIN_DIR/bin/lib" "$dest/bin/lib"
  chmod +x "$dest"/bin/*.sh
  echo "  [project-bin] check-gates.sh + friends -> $dest/bin"

  local name
  for name in "${VENDORED_SKILLS[@]}"; do
    if [[ -d "$PLUGIN_DIR/skills/_vendor/$name" ]]; then
      rm -rf "$dest/skills/$name"
      cp -R "$PLUGIN_DIR/skills/_vendor/$name" "$dest/skills/$name"
      echo "  [project-skill] vendored $name"
    fi
  done

  echo "==> Done: $target"
  echo "    Fully self-contained — safe to delete the $PLUGIN_DIR clone now."
  echo "    Nothing in ~/.claude was touched. Open Claude Code in $target, run /ak:status."
  echo "    To update later: re-run this same command from a fresh clone/pull, it overwrites in place."
}

if [[ -n "$INSTALL_PATH" ]]; then
  install_path "$INSTALL_PATH"
  exit 0
fi

prepare_source

case "$TARGET_HOST" in
  claude) install_claude ;;
  cursor) install_cursor ;;
  codex) install_codex ;;
  antigravity) install_antigravity ;;
  all)
    install_claude
    install_cursor
    install_codex
    install_antigravity
    ;;
esac

echo "==> Done: $TARGET_HOST"
echo "    Full guide: $PLUGIN_DIR/docs/INSTALL.md"

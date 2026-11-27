#!/usr/bin/env bash
# Shared path resolution for ak — no hardcoded user projects.
# Source from other scripts:  source "$(dirname "$0")/lib/resolve-paths.sh"
#
# Exports (when resolve_* succeeds):
#   AK_PLUGIN_DIR
#   AK_WORKSPACES_ROOT_RESOLVED
#   AK_PROJECT_SLUG_RESOLVED
#   AK_PROJECT_HOME
#
# Env overrides (optional):
#   AK_PLUGIN
#   AK_WORKSPACES_ROOT
#   AK_EXTRA_WORKSPACE_ROOTS   (colon-separated)
#   AK_PROJECT_SLUG

_dw_slugify() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//; s/-+/-/g'
}

_dw_default_workspaces_root() {
  echo "${HOME}/.workspaces"
}

_dw_project_home_from_root() {
  local root="$1"
  local slug="$2"
  if [[ -d "$root/workspaces/$slug" || -f "$root/workspaces/$slug/PROJECT.md" ]]; then
    echo "$root/workspaces/$slug"
  else
    echo "$root/$slug"
  fi
}

# Multiple projects under one workspaces root is the normal case (one
# domain repo → one ak project). PROJECT.md's own "Repos" table
# already declares which real repo path(s) belong to that project — use it
# to answer "which project owns the repo I'm standing in right now" instead
# of making the caller type --project every time more than one project
# exists. Returns the owning slug on stdout when exactly one PROJECT.md's
# Repos table contains a path that is the cwd or an ancestor of it (so it
# still matches from a subdirectory of the repo, not just the repo root).
_dw_match_project_by_cwd_repo() {
  local root="$1" cwd="$2"
  local -a matches=()
  local pf slug repo_path real_repo_path real_cwd
  real_cwd="$(cd -P "$cwd" 2>/dev/null && pwd || echo "$cwd")"
  for pf in "$root"/*/PROJECT.md "$root/workspaces"/*/PROJECT.md; do
    [[ -f "$pf" ]] || continue
    slug="$(basename "$(dirname "$pf")")"
    while IFS= read -r repo_path; do
      [[ -z "$repo_path" ]] && continue
      real_repo_path="$(cd -P "$repo_path" 2>/dev/null && pwd || echo "")"
      [[ -z "$real_repo_path" ]] && continue
      if [[ "$real_cwd" == "$real_repo_path" || "$real_cwd" == "$real_repo_path"/* ]]; then
        matches+=("$slug")
        break
      fi
    done < <(awk -F'|' '
      /^\|/ && $0 !~ /^\|[[:space:]]*-+[[:space:]]*\|/ && $0 !~ /^\|[[:space:]]*Repo slug/ {
        p = $3
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", p)
        gsub(/`/, "", p)
        if (p != "") print p
      }
    ' "$pf" 2>/dev/null)
  done
  # dedupe (a project could list the same repo path twice)
  local -a uniq=()
  local m seen
  for m in "${matches[@]:-}"; do
    [[ -z "$m" ]] && continue
    seen=0
    for s in "${uniq[@]:-}"; do [[ "$s" == "$m" ]] && { seen=1; break; }; done
    [[ $seen -eq 0 ]] && uniq+=("$m")
  done
  if [[ ${#uniq[@]} -eq 1 ]]; then
    echo "${uniq[0]}"
    return 0
  fi
  if [[ ${#uniq[@]} -gt 1 ]]; then
    echo "ERROR: this checkout belongs to multiple projects: ${uniq[*]}. Pass --project <slug>." >&2
    return 2
  fi
  return 1
}

# Plugin install dir (this package), never a customer app path.
resolve_plugin_dir() {
  if [[ -n "${AK_PLUGIN:-}" && -x "${AK_PLUGIN}/bin/check-gates.sh" ]]; then
    AK_PLUGIN_DIR="$(cd "$AK_PLUGIN" && pwd)"
    return 0
  fi
  local cand
  for cand in \
    "${HOME}/.claude/skills/ak-plugin" \
    "${HOME}/.claude/plugins/ak" \
    "${HOME}/.codex/plugins/ak" \
    "${HOME}/.cursor/skills/ak"
  do
    if [[ -x "${cand}/bin/check-gates.sh" ]]; then
      AK_PLUGIN_DIR="$(cd "$cand" && pwd)"
      return 0
    fi
    # cursor thin pointer — follow sibling or env only
  done
  # caller script under plugin/bin or plugin/bin/lib
  local here
  here="$(cd "$(dirname "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")" && pwd)"
  if [[ -x "${here}/check-gates.sh" ]]; then
    AK_PLUGIN_DIR="$(cd "${here}/.." && pwd)"
    return 0
  fi
  if [[ -x "${here}/../check-gates.sh" ]]; then
    AK_PLUGIN_DIR="$(cd "${here}/../.." && pwd)"
    return 0
  fi
  return 1
}

# Collect candidate workspace roots from cwd / git / env (user project auto).
_dw_collect_workspace_roots() {
  local -a roots=()
  local d git_root

  [[ -n "${AK_WORKSPACES_ROOT:-}" ]] && roots+=("$AK_WORKSPACES_ROOT")
  roots+=("$(_dw_default_workspaces_root)")

  d="${PWD}"
  local i
  for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
    [[ -d "$d/workspaces" ]] && roots+=("$d")
    [[ -d "$d/.workspaces" ]] && roots+=("$d/.workspaces")
    [[ -f "$d/.ak.json" ]] && roots+=("$d")
    [[ -d "$d/tasks/domain-knowledge" ]] && roots+=("$d")
    [[ "$d" == "/" ]] && break
    d="$(dirname "$d")"
  done

  if command -v git >/dev/null 2>&1; then
    git_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
    if [[ -n "$git_root" ]]; then
      roots+=("$git_root")
      roots+=("$(dirname "$git_root")")
    fi
  fi

  roots+=("$PWD")

  if [[ -n "${AK_EXTRA_WORKSPACE_ROOTS:-}" ]]; then
    local IFS=':'
    local e
    for e in $AK_EXTRA_WORKSPACE_ROOTS; do
      [[ -n "$e" ]] && roots+=("$e")
    done
  fi

  # dedupe preserve order
  local -a out=()
  local r seen
  for r in "${roots[@]}"; do
    [[ -d "$r" ]] || continue
    seen=0
    for x in "${out[@]:-}"; do
      [[ "$x" == "$r" ]] && { seen=1; break; }
    done
    [[ $seen -eq 0 ]] && out+=("$r")
  done
  printf '%s\n' "${out[@]}"
}

# Read slug from .ak.json if present: {"projectSlug":"…"} or {"slug":"…"}
_dw_slug_from_marker() {
  local dir="$1"
  local f="$dir/.ak.json"
  [[ -f "$f" ]] || return 1
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$f" <<'PY' 2>/dev/null
import json,sys
d=json.load(open(sys.argv[1]))
print(d.get("projectSlug") or d.get("slug") or "")
PY
  fi
}

# Infer project slug from user tree (no product hardcode).
resolve_project_slug() {
  local hint="${1:-${AK_PROJECT_SLUG:-}}"
  AK_PROJECT_SLUG_RESOLVED=""
  AK_WORKSPACES_ROOT_RESOLVED=""
  AK_PROJECT_IDENTIFIED=0
  if [[ -n "$hint" ]]; then
    AK_PROJECT_SLUG_RESOLVED="$(_dw_slugify "$hint")"
    AK_PROJECT_IDENTIFIED=1
    [[ -n "$AK_PROJECT_SLUG_RESOLVED" ]] || return 1
    return 0
  fi

  local root slug result base
  local -a roots=()
  while IFS= read -r root; do
    [[ -z "$root" ]] || roots+=("$root")
  done < <(_dw_collect_workspace_roots)
  for root in "${roots[@]}"; do
    slug="$(_dw_slug_from_marker "$root" || true)"
    if [[ -n "${slug:-}" ]]; then
      AK_PROJECT_SLUG_RESOLVED="$(_dw_slugify "$slug")"
      AK_PROJECT_IDENTIFIED=1
      [[ -n "$AK_PROJECT_SLUG_RESOLVED" ]] || return 1
      return 0
    fi
  done
  for root in "${roots[@]}"; do
    if slug="$(_dw_match_project_by_cwd_repo "$root" "$PWD")"; then
      if [[ -n "$AK_PROJECT_SLUG_RESOLVED" && "$AK_PROJECT_SLUG_RESOLVED" != "$slug" ]]; then
        echo "ERROR: this checkout belongs to multiple projects: $AK_PROJECT_SLUG_RESOLVED $slug. Pass --project <slug>." >&2
        return 2
      fi
      if [[ -z "$AK_PROJECT_SLUG_RESOLVED" ]]; then
        AK_PROJECT_SLUG_RESOLVED="$slug"
        AK_WORKSPACES_ROOT_RESOLVED="$root"
        AK_PROJECT_IDENTIFIED=1
      fi
    else
      result=$?
      [[ "$result" -ne 2 ]] || return 2
    fi
  done
  [[ -z "$AK_PROJECT_SLUG_RESOLVED" ]] || return 0

  # Derive a name for a new checkout without inheriting an unrelated workspace.
  if base="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    AK_PROJECT_IDENTIFIED=1
    base="$(basename "$base")"
  else
    base="$(basename "$PWD")"
  fi
  if [[ -n "$base" && "$base" != "/" ]]; then
    AK_PROJECT_SLUG_RESOLVED="$(_dw_slugify "$base")"
    if [[ "$AK_PROJECT_IDENTIFIED" -eq 1 ]]; then
      for root in "${roots[@]}"; do
        if [[ -f "$(_dw_project_home_from_root "$root" "$AK_PROJECT_SLUG_RESOLVED")/PROJECT.md" ]]; then
          echo "ERROR: workspace $AK_PROJECT_SLUG_RESOLVED does not map this checkout. Pass --project <slug> or add its repo mapping." >&2
          return 2
        fi
      done
    fi
    return 0
  fi
  return 1
}

resolve_workspaces_root() {
  local prefer_slug="${1:-${AK_PROJECT_SLUG_RESOLVED:-}}"
  local root f

  if [[ -n "${AK_WORKSPACES_ROOT:-}" && -d "${AK_WORKSPACES_ROOT}" ]]; then
    AK_WORKSPACES_ROOT_RESOLVED="$(cd "$AK_WORKSPACES_ROOT" && pwd)"
    return 0
  fi

  while IFS= read -r root; do
    [[ -z "$root" ]] && continue
    if [[ -n "$prefer_slug" && -f "$(_dw_project_home_from_root "$root" "$prefer_slug")/PROJECT.md" ]]; then
      AK_WORKSPACES_ROOT_RESOLVED="$(cd "$root" && pwd)"
      return 0
    fi
  done < <(_dw_collect_workspace_roots)

  while IFS= read -r root; do
    [[ -z "$root" ]] && continue
    if [[ "$root" == "$(_dw_default_workspaces_root)" ]]; then
      mkdir -p "$root"
      AK_WORKSPACES_ROOT_RESOLVED="$(cd "$root" && pwd)"
      return 0
    fi
    if [[ -d "$root/workspaces" ]]; then
      AK_WORKSPACES_ROOT_RESOLVED="$(cd "$root" && pwd)"
      return 0
    fi
    if [[ -f "$root/.ak.json" ]]; then
      AK_WORKSPACES_ROOT_RESOLVED="$(cd "$root" && pwd)"
      return 0
    fi
  done < <(_dw_collect_workspace_roots)

  # Default: always outside repo under ~/.workspaces
  mkdir -p "$(_dw_default_workspaces_root)"
  AK_WORKSPACES_ROOT_RESOLVED="$(cd "$(_dw_default_workspaces_root)" && pwd)"
  return 0
}

resolve_project_home() {
  local slug="${1:-}"
  resolve_project_slug "$slug" || return $?
  slug="${AK_PROJECT_SLUG_RESOLVED:-}"
  [[ -n "$slug" ]] || return 1
  if [[ -z "$AK_WORKSPACES_ROOT_RESOLVED" ]]; then
    resolve_workspaces_root "$slug" || return 1
  fi
  AK_PROJECT_HOME="$(_dw_project_home_from_root "$AK_WORKSPACES_ROOT_RESOLVED" "$slug")"
  return 0
}

# Find worklog dir for ticket under auto-detected roots.
resolve_worklog_dir() {
  local ticket="$1"
  local hint="${2:-${AK_PROJECT_SLUG:-}}" root candidate actual selected="" slug
  if [[ -z "$ticket" || "$ticket" == */* || "$ticket" == "." || "$ticket" == ".." ]]; then
    echo "ERROR: invalid ticket directory name" >&2
    return 2
  fi
  resolve_project_slug "$hint" || return $?
  slug="$AK_PROJECT_SLUG_RESOLVED"
  if [[ -n "$AK_WORKSPACES_ROOT_RESOLVED" ]]; then
    candidate="$(_dw_project_home_from_root "$AK_WORKSPACES_ROOT_RESOLVED" "$slug")/worklogs/$ticket"
    [[ -d "$candidate" ]] || return 1
    (cd -P "$candidate" && pwd)
    return $?
  fi

  while IFS= read -r root; do
    [[ -z "$root" ]] && continue
    local -a candidates
    if [[ "$AK_PROJECT_IDENTIFIED" -eq 1 ]]; then
      candidates=("$(_dw_project_home_from_root "$root" "$slug")/worklogs/$ticket")
    else
      candidates=("$root/workspaces"/*/worklogs/"$ticket" "$root"/*/worklogs/"$ticket")
    fi
    for candidate in "${candidates[@]}"; do
      [[ -d "$candidate" ]] || continue
      actual="$(cd -P "$candidate" && pwd)" || return 1
      if [[ -n "$hint" ]]; then
        printf '%s\n' "$actual"
        return 0
      fi
      if [[ -n "$selected" && "$selected" != "$actual" ]]; then
        echo "ERROR: ambiguous worklog for ticket=$ticket. Select --project and AK_WORKSPACES_ROOT." >&2
        return 2
      fi
      selected="$actual"
    done
  done < <(_dw_collect_workspace_roots)
  [[ -n "$selected" ]] || return 1
  printf '%s\n' "$selected"
}

#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/resolve-paths.sh"

project=""
if [[ "${1:-}" == "--project" ]]; then
  [[ $# -ge 3 ]] || { echo "Usage: $0 [--project slug] <action> [args]" >&2; exit 2; }
  project="$2"
  shift 2
fi
resolve_project_home "$project"
if [[ ! -f "$AK_PROJECT_HOME/PROJECT.md" ]]; then
  echo "ERROR: no project map at $AK_PROJECT_HOME/PROJECT.md. Resolve the project and run :learning first." >&2
  exit 2
fi

exec python3 "$SCRIPT_DIR/lib/vibe_specs.py" "$AK_PROJECT_HOME" "$AK_PROJECT_SLUG_RESOLVED" "$SCRIPT_DIR" "$@"

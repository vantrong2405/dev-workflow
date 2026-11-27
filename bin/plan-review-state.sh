#!/usr/bin/env bash
# Fingerprint the plan and its decision inputs, independent of the current cwd.
set -euo pipefail

if [[ "$#" -ne 1 || ! -f "$1/04-plan.md" ]]; then
  echo "Usage: $0 <worklog-directory containing 04-plan.md>" >&2
  exit 2
fi

cd "$1"
{
  for file in 02-spec.md 03-clarify-report.md 03-qa-log.md 04-plan.md; do
    if [[ -f "$file" ]]; then
      hash="$(git hash-object --no-filters -- "$file")"
    else
      hash=missing
    fi
    printf '%s\0%s\0' "$file" "$hash"
  done
} | git hash-object --stdin

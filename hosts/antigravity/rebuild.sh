#!/usr/bin/env bash
set -euo pipefail

bundle="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$bundle/../.." && pwd)"
for entry in skills bin references templates; do
  if [[ -e "$bundle/$entry" && ! -L "$bundle/$entry" ]]; then
    echo "Refusing to replace the existing $bundle/$entry" >&2
    exit 1
  fi
  ln -sfn "../../$entry" "$bundle/$entry"
done
# Antigravity exposes the skill entry points directly. Remove an old generated
# command link so the native validator does not treat those files as commands.
if [[ -L "$bundle/commands" ]]; then
  rm "$bundle/commands"
fi

mkdir -p "$bundle/flat-skills"
for skill in "$root"/skills/*/SKILL.md; do
  [[ -f "$skill" ]] || continue
  name="$(basename "$(dirname "$skill")")"
  ln -sfn "../../../skills/$name/SKILL.md" "$bundle/flat-skills/$name.md"
done
echo "Antigravity bundle ready: $bundle"

#!/usr/bin/env bash
# Read-only source identity for matching test runs to the current checkout.
set -euo pipefail

if [[ "$#" -ne 1 ]]; then
  echo "Usage: ${0##*/} <repo-or-module-directory>" >&2
  exit 2
fi

root="$(git -C "$1" rev-parse --show-toplevel)"
cd "$root"
head="$(git rev-parse --verify HEAD)"
status="$(git status --porcelain --untracked-files=all --ignore-submodules=none)"

if [[ -z "$status" ]]; then
  printf 'commit:%s\n' "$head"
  exit 0
fi

# A recursive fixture or repo with nested Git metadata needs independent
# source states for those repos. Their working files cannot be hashed here.
if git ls-files --stage | awk '$1 == "160000" { found = 1 } END { exit !found }'; then
  echo "Cannot fingerprint a dirty checkout containing submodules" >&2
  exit 1
fi

fingerprint="$(
  {
    printf 'head\0%s\0' "$head"
    git diff --no-ext-diff --no-textconv --binary HEAD --
    git ls-files --others --exclude-standard -z | while IFS= read -r -d '' file; do
      if [[ -L "$file" ]]; then
        kind=link
        hash="$(readlink "./$file" | git hash-object --stdin)" || exit 1
      elif [[ -f "$file" ]]; then
        kind=file
        [[ ! -x "$file" ]] || kind=executable
        hash="$(git hash-object --no-filters -- "./$file")" || exit 1
      else
        echo "Cannot fingerprint untracked input: $file" >&2
        exit 1
      fi
      printf '\0%s\0%s\0%s\0' "$kind" "$file" "$hash"
    done
  } | git hash-object --stdin
)"
printf 'worktree:%s\n' "$fingerprint"

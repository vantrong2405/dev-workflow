#!/usr/bin/env bash
# Check the minimal contract shared by W2 and G0. Other form values are
# optional and their applicability is decided by the stage reading them.
project_form_ready() {
  local file="$1" slug="$2"
  [[ -f "$file" ]] || return 1

  awk -v slug="$slug" '
    /^- \*\*Slug:\*\* / {
      value = substr($0, length("- **Slug:** ") + 1)
      if (value == slug || value == "`" slug "`") slugs++
      slug_fields++
    }
    /^- \*\*Chat locale:\*\* / {
      value = substr($0, length("- **Chat locale:** ") + 1)
      if (value ~ /^[a-z][a-z]([a-z])?(-[A-Za-z0-9]+)*[[:space:]]*$/) locales++
      locale_fields++
    }
    /^- \*\*Convention interview:\*\* / {
      value = substr($0, length("- **Convention interview:** ") + 1)
      if (value ~ /^(confirmed|skipped)[[:space:]]*$/) interviews++
      if (value ~ /^confirmed[[:space:]]*$/) confirmed = 1
      interview_fields++
    }
    /^## Repository facts[[:space:]]*$/ { facts++ }
    /^## / { in_rules = 0 }
    /^## Confirmed working rules[[:space:]]*$/ { rules++; in_rules = 1; next }
    in_rules && /^\|/ {
      split($0, row, "|")
      for (i = 2; i <= 5; i++) gsub(/^[[:space:]]+|[[:space:]]+$/, "", row[i])
      if (row[2] != "When" && row[2] !~ /^-+$/ &&
          row[2] != "" && row[3] != "" && row[4] != "" && row[5] != "") saved_rules++
    }
    END {
      exit !(slugs == 1 && slug_fields == 1 && locales == 1 && locale_fields == 1 &&
             interviews == 1 && interview_fields == 1 && facts == 1 && rules == 1 &&
             (!confirmed || saved_rules > 0))
    }
  ' "$file"
}

---
name: flow-diagram
description: >-
  Prepare test data and draw one Unicode click-by-click reproduction per UI bug.
  Use before a UI fix in /ak or standalone to reconstruct reported browser behavior.
argument-hint: "[bug description or ticket] [UI steps, logs or route context]"
arguments: [input]
disable-model-invocation: false
---

# /ak:flow-diagram

Read `references/flow-diagram.md` for layout, data handling, and the example. Use
the existing investigation and test environment to construct the reproduction.

1. Extract distinct failures and actionable UI steps from the input. Ignore chat noise,
   duplicate reports, and unrelated logs.
2. Trace the real routes, button labels, handler, and expected behavior. Prefer English
   UI when supported, except for locale-dependent defects. Prepare safe fixture data
   and the corresponding actor and record any missing prerequisite.
3. Draw one centered Unicode diagram per bug. Include the actor first, then exact
   clicks/inputs and URLs with both action prefixes. Cite the source of the expected
   outcome and distinguish verified cause, hypothesis, and reported behavior.
4. For an active ticket, save each fenced diagram to `evidence/ui-repro-bug-01.md`
   (numbered for each bug) and return the diagrams to `:clarify` for the browser
   handoff. For standalone use, show the diagrams in chat. Preserve the actual
   run status until there is a browser result.

If an input path or suspected cause cannot be located, label it `chưa xác nhận`
and preserve the steps that are grounded. If key setup is missing, state where
the flow stops. If there is no identifiable UI defect or action, ask for the
smallest missing detail.

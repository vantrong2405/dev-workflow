---
name: vibe
description: >-
  Shape a rough React or Next.js feature request into business flows, a reviewed implementation
  plan, and image previews rendered from reusable React, Tailwind and shadcn/ui templates.
argument-hint: "<rough feature request or existing Vibe task ID>"
arguments: [input]
disable-model-invocation: false
---

# /ak:vibe

Use `references/vibe.md`, `references/vibe-specs.md`, and the templates in `templates/vibe/`. Resolve the project and one
task worklog using the normal ak conventions. Reuse the project form. Keep the same task and
decisions through follow-up turns. For a new app use React with Vite unless the requirements
call for Next.js. For existing apps follow the React/Next.js, JSX/TSX and package conventions
already in use. Use the Vibe worklog as the source for business decisions and approvals.

1. **Understand the business.** Read the relevant code, tests and existing rules. Reuse `:learning`
   for missing project setup. Read the relevant implemented business specs and active changes.
   When the request changes business behavior, use the Vibe spec library to open or resume
   a change linked to the same ak ticket. Prepare the normal `:spec` and `:clarify` worklog fields from the
   same investigation. Fill the business flow and start the plan together. Give each flow and
   acceptance check stable IDs. Decide routine
   interface details from the project and template catalog. Ask about unresolved business rules,
   actors, permissions, state changes and side effects only when the answer changes the outcome.
   Continue on independent branches already understood. Keep consequential unknowns visibly open.
2. **Draw and review the business flow.** Invoke the installed `diagram-design` skill for each
   material flow. Use branching flowcharts or swimlanes as appropriate. Show actor, trigger,
   conditions, outcomes and open decisions, and label branches with their spec IDs. Render the
   actual diagram and share it in the conversation. Read the repo's visual conventions for the
   diagram style. If the skill is unavailable, name that dependency and continue independent
   planning. Update the diagram and plan together when a rule changes.
3. **Design, render and review mockups.** Once the business rules needed for a screen are clear,
   invoke the bundled `vibe-design` skill and save its source-backed design record using
   `templates/vibe/design.md`. Reuse decisions for related screens. Fill the versioned mockup
   config from the included example and run the local renderer. Review the resulting design
   and record the image revision. Present only
   the resulting images in the mockup message. Answer questions about controls from the flow spec.
   Adjust the allowed options and render affected images again. Get explicit approval of the
   chosen image revision before uploading those approved images to configured Google Stitch.
   Send only approved synthetic previews. Bring any Stitch change to appearance or behavior back
   for review. Keep the local template and flow IDs as the implementation reference.
4. **Finalize and challenge the plan.** Fill the Vibe traceability table in the normal `04-plan.md`
   and use `:plan` and `:redteam` on the same worklog. Use the spec change's `tasks.md` as the
   implementation checklist and bind its spec revision to the plan before Redteam.
   Populate the Vibe review checks in
   `04b-plan-review.md`. Redteam challenges the current flow, visual decisions, impacted behavior
   and test coverage. Fix substantiated findings and rerun the review after plan, spec or decision
   changes. Keep unresolved material decisions visible. Present the current reviewed plan and
   wait for the user's explicit go-ahead to build. Record any approval required for the task's
   risk and mode through `:confirm` as well.
5. **Build and verify.** Continue the same worklog through `:build`, `:review` and `:test`/`:check`.
   Recheck the Vibe spec revision against the reviewed plan before building or resuming code work.
   Refresh the plan and Redteam review if the revision changed.
   Implement the approved flow with repo components and the matching template. Check the actual
   UI with Playwright or the repo's browser runner. Apply `references/ui-verification.md` when
   relevant. Update checklist items as their acceptance tests pass. Archive the Vibe spec change
   after the checklist, spec revision and test gate all pass. Show the demo and evidence for the
   acceptance IDs on the tested code.

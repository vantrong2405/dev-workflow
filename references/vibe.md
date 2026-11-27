# Vibe conventions

Use one isolated worklog per request. The business flow, template configuration, reviewed plan
and test evidence share the same acceptance IDs. Use the document revision plus exact image
fingerprints in the worklog so an approval refers to a specific set of images.
For lasting business behavior, read [Vibe business specifications](vibe-specs.md). Use the
change's checklist for progress and the linked worklog for review and test evidence.

## Files in the worklog

| Artifact | Source template | Convention |
|---|---|---|
| `02-spec.md` | `templates/02-spec.md` with `templates/vibe/business-flow.md` | The flow appendix records actors, prerequisites, conditions, outcomes, and side effects. Keep `FLOW-01` and `AC-01` IDs stable. Each materially different branch gets its own acceptance ID. Mark each unresolved rule and preserve its final decision. |
| `evidence/vibe/flows/` | `diagram-design` | Name diagrams by flow and revision. Use the same branch IDs as the spec. A new business decision updates the spec, diagram, plan and affected mockup together. |
| `evidence/vibe/<revision>/design.md` | `templates/vibe/design.md` | Use `vibe-design` before rendering. Record product-specific design directions, sourced palette roles and screen state decisions. |
| `evidence/vibe/<revision>/mockup.json` | `skills/vibe/preview/mockup.example.json` | Every image has a unique screen ID, template variant, scene and mapped acceptance IDs. Set synthetic fixtures, intended viewport and locale explicitly. Use the catalog options below. |
| `04-plan.md` | `templates/04-plan.md` with `templates/vibe/plan.md` | Keep the required plan fields. Add the mapping for each applicable flow branch, component, scenario and approved image. Review the latest revision. |
| `04b-plan-review.md` | `templates/04b-plan-review.md` with `templates/vibe/redteam.md` | Use the normal review verdict and fingerprint. For every challenge, name its consequence, evidence and resolution. |
| `evidence/vibe/approvals.md` | `templates/vibe/approval.md` | Record exactly what the user approved, including the inputs and produced image fingerprints. Track Stitch input and output separately. |

## Discovery and decisions

Use one pass to read repo rules, trace business behavior and draft the work. Compare the
request to existing roles, transitions and dependencies. An open business question must say
which behavior, scope or test would change. Routine defaults such as a dialog versus a page
belong to the agent and can be revised after the user sees the preview. Keep project-wide
rules in the existing project form and task decisions in this worklog.

Use `diagram-design` for the actual business flow. Keep the happy path easy to follow and
show meaningful branches for permission, state, failure or retry when applicable. A node
identifies a business action or outcome. Put each branch's condition on its connector. Carry
the same IDs into the implementation and test mapping. Show the diagram alongside the draft
plan before asking the user to approve the mockup.

## Mockup catalog

| Template | Variants | Scenes |
|---|---|---|
| `dashboard` | `overview` | `default` |
| `list` | `comfortable`, `compact` | `default`, `empty` |
| `detail` | `panel`, `page` | `default` |
| `form` | `dialog`, `page` | `default`, `invalid` |

Each screen's `data` supplies text and fixtures. The selected template controls layout,
component structure and styles. Model the next screen or business outcome for every displayed
action in the spec. Choose supported variants, alter the data or add a supported screen to
iterate. When no template covers the request, explain the missing reusable pattern and ask
whether to extend the library or use the closest layout. Treat arbitrary HTML, React snippets,
CSS and remote asset URLs as out of scope for mockup data.

The preview UI uses registry components from shadcn/ui under `preview/src/components/ui/`.
Use those components and allowed variants for app controls, then apply the Vibe theme tokens
and compose the screen layout. The catalog's [Kho Mockup](../docs/mockups.html) includes
a dashboard rendered with two palettes. To regenerate the gallery input, run
`node gallery-config.mjs > /tmp/vibe-gallery.json` from the preview folder and pass that file
to `render.mjs`. Use `--comparison` to generate the alternate dashboard input.

Choose one theme for a related set of screens. `orange` pairs terracotta with a warm paper
surface and dark brown navigation. `blue` uses a cool paper surface and navy navigation.
`slate` uses mineral gray and forest green. Reuse the same `workspace` mark and navigation
throughout the set. For list layouts, `summary` and `statusTones` map real fixture counts
and statuses to semantic tones. For a detail panel or dialog, set `background` to the list
screen ID to show how the overlay relates to the previous screen.
Use the optional `palette` map to override known roles with six-digit hex values from the
recorded palette source. The renderer applies the preset and overrides together and rejects
insufficient text contrast in the checked pairs. See [Vibe design sources](vibe-design.md).

Use the installed skill's `preview/` folder as the renderer source. Copy it to a temporary
tool directory outside product source, then install the locked dependencies there using the
Node version in `preview/package.json`. Install Chromium through Playwright if it is missing.
Use absolute inputs and outputs:

```bash
npm ci
npx playwright install --only-shell chromium
node render.mjs /absolute/worklog/evidence/vibe/v1/mockup.json /absolute/worklog/evidence/vibe/v1/images
```

The renderer validates each scene and writes `<id>.png` plus `manifest.json` with the exact
input and image SHA-256 values. Render revisions into new directories. Use the same viewport,
locale and fixture data to compare variants. The image-only message contains the actual PNGs.
Map visible variant labels and screen IDs in the mockup configuration. Interpret subsequent
feedback against the current revision and confirm which revision was accepted before upload.

## Stitch and Redteam

After explicit approval, use the configured Stitch integration to import the approved PNGs
and request the agreed visual refinements. Retain the original local image manifest and
record uploaded and returned screen references. If the integration is unavailable, keep the
approved local images and report the missing setup. Continue without Stitch only if the user
chooses to use the approved local images for implementation.

Use `:plan` and `:redteam` with the same spec and worklog. Link the relevant flow and image
manifest from the plan. A change to a business rule, acceptance case or approved design that
affects implementation requires a revised plan and fresh review before building. Apply
`references/ui-verification.md` to evidence from the running feature. A mockup approval records
design intent. Approve a runtime golden baseline separately when the project requires one.

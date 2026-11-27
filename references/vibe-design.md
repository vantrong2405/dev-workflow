# Vibe design sources and decisions

Use the product's own brand and existing design system first. Read the actual token values
and screen patterns. For a new direction, use these sources by purpose:

| Source | Use |
|---|---|
| [UI/UX Pro Max](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) | Compare product type, screen density, palette and typography. If installed, run its design-system or color search with the actual product and task. Check whether the result addresses an internal app, a consumer app or a landing page. |
| [Radix Colors](https://www.radix-ui.com/colors/docs/palette-composition/understanding-the-scale) | Choose related surfaces, text, accents and states. Read the actual light and dark scales from the source before recording color values. |
| [shadcn/ui theming](https://ui.shadcn.com/docs/theming) and [tweakcn](https://github.com/jnsahaj/tweakcn) | Compare palette roles and their appearance on real components. Use the layout, density or token relationship that fits this product. |
| [Frontend Design](https://github.com/anthropics/skills/blob/main/skills/frontend-design/SKILL.md) | Ground the visual identity in the audience and product goal. Make hierarchy, typography and spacing decisions together. |

For Kho Mộc, the UI/UX Pro Max stock-management result suggested a dense, scannable list
and a separate stock-state color. The product direction retained orange as the primary
action color, put neutral warm surfaces underneath, and used green and amber for statuses.
The recipe uses Radix Brown, Sand, Orange, Green and Amber.

The bundled renderer recipes are in `skills/vibe/preview/palettes.mjs`. Color values are
selected from the [Radix light](https://github.com/radix-ui/colors/blob/dbdb85470547c7d34b9001f48fddb08ded335979/src/light.ts) and
[Radix dark](https://github.com/radix-ui/colors/blob/dbdb85470547c7d34b9001f48fddb08ded335979/src/dark.ts)
scales or adapted from published tweakcn presets. Compare [Tangerine](https://tweakcn.com/r/themes/tangerine.json)
and [Ocean Breeze](https://tweakcn.com/r/themes/ocean-breeze.json) on the same dashboard before
choosing a direction. The Vibe versions keep the source accent, surfaces and chart hues, convert
them to sRGB, and choose text colors that pass the contrast checks. For a project-specific palette,
overrides supply six-digit hex values by role. The renderer checks the effective foreground
and background pairs before opening Chromium. Standard text pairs use the
[WCAG 2.2 minimum 4.5:1 ratio](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html).
Palette validation covers only the listed pairs. Check focus, hierarchy, keyboard behavior,
and viewport layout separately in the application under test.

Keep references and the reasons for choosing them in the design record. The mockup delivery
message contains the generated images. The design record and approved image manifest travel
with the implementation plan and Redteam review.

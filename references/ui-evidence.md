# UI evidence (screenshots that prove something, not just show a screen)

Used by `:test` and `:review` whenever `Touches UI = Yes`. A plain screenshot proves the screen
loaded, not that the bug is real or the fix works — everything here exists to close that gap.

## Path convention

`worklogs/<Ticket>/evidence/<AC-or-scenario-slug>/step-<N>.png` (or `.webm` for video). One folder
per AC/scenario, not one giant folder for the whole ticket — keeps the `06b-test-evidence.md`
Screenshots table's paths unambiguous.

## Red highlight box (point at the exact element, don't make the reviewer hunt)

Get the element's real pixel box from the browser tool driving the test, then draw it on the
already-captured screenshot — never eyeball coordinates from the image itself.

1. Screenshot as usual.
2. Get the box: `getBoundingClientRect()` on the element (via whatever browser-automation tool is
   in use — Playwright MCP, DevTools MCP, etc.), rounded to integers.
3. Draw with ImageMagick: `-stroke "#e60000" -strokewidth 4 -fill none -draw "rectangle X1,Y1 X2,Y2"`
   where `X1,Y1 = x-6,y-6` and `X2,Y2 = (x+w)+6,(y+h)+6` (padded so the stroke doesn't clip the
   element edge). Add a short annotate note (≤8 words, states the problem not a description —
   `"Nút bị lệch màu"`, not `"Đây là cái nút"`) above or below the box, whichever has room.
4. One box + note per screenshot. Two things to call out → two screenshots, not one crowded box.
5. The page itself is never modified (no injected DOM/CSS) — only the saved PNG is drawn on.

**Removed an element?** There's nothing left to measure. Take the boxes of the elements that used
to sandwich it (still on the page) and box the gap between them instead: `x: min(before.left,
after.left)` to `max(before.right, after.right)`, `y: before.bottom` to `after.top`. If the gap is
thin, extend the canvas a bit (`-gravity North -extent Wx(H+80)`) so the note has room instead of
overlapping real content.

## Before/after compare (bug fixes only — skip for new features, there's no "broken state" to pair)

One image beats "trust me, it's fixed": capture the bug live, fix it, capture again, stack them.

1. **Before touching any code**, reproduce the bug at the real URL/viewport, screenshot it
   (`step-N_before.png`) — captured after the fact from memory doesn't count as evidence.
2. Make the fix.
3. Reload the *exact same* URL/viewport/account/locale (a changed variable breaks the comparison),
   screenshot again (`step-N_after.png`).
4. Stack them side by side (`+append`) or top/bottom (`-append` if the images are tall/narrow) with
   a colored border + label band per side — red/"TRƯỚC KHI FIX" on before, green/"SAU KHI FIX" on
   after, a dark divider strip between them. A label alone reads as identical at a glance; the color
   framing is what actually lets someone tell the halves apart without reading.
5. Save the merged image as the evidence file; keep the two originals too (full-resolution, in case
   someone needs to zoom one half).

## Video

Only when a static image genuinely can't show the problem (animation, timing, a multi-step demo).
Default to screenshots otherwise — video is heavier to review and to store.

## Auth-gated screens

Use whatever dev/test account the project's own `PROJECT.md`/domain-knowledge already documents.
If none is recorded, that's a `:learning`/`:coaching` gap, not something to invent a login for on
the spot — ask once, then record the answer so the next ticket doesn't ask again.

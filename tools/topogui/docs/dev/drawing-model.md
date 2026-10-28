# Drawing model (v0, increments 2 and 3) <!-- omit from toc -->

> **Status:** implemented (increment 2: points and edges; increment 3:
> loops and faces). The authority is DD-006: every geometric decision
> comes from the proved kernel through the single TopoScript front-end;
> the GUI owns only the view, the interaction, and the session.

## Session = replayable TopoScript

A TopoScript run holds its own store: handles are valid for the whole
run, not across runs. The GUI session therefore keeps the state the
kernel accepted (vertices and edges with their kernel-reported handles
and exact grid points) together with the accumulated TopoScript
statements that produced it. The session is its own replay script: the
same text the GUI executes gesture by gesture is what a later
save-and-load writes to disk, and what `topocli run` can execute
headlessly. The construction logic stays headless-testable from the
first increment.

## Kernel arbitration

Every gesture appends its candidate statements to the session script
and runs the **whole** replay through `topocli run_code`, as a
subprocess, with the canonical traces captured:

- **Accepted** when the run exits 0 and the new canonical trace
  (`vertex N point X Y`, `edge N vertex A vertex B`) appears. The GUI
  records exactly what the trace reports — it never computes a
  position or a handle of its own.
- **Rejected** when the run exits non-zero or the trace is missing:
  the kernel diagnostic is displayed **verbatim** in the status line,
  and the candidate statements are dropped. No softened or
  reinterpreted diagnostic.

Replaying the whole session per gesture keeps one code path: the
gesture check, the save format, and the headless test path are the
same script. The replay cost grows with the session length; v0
sessions are small, and the cost is a subprocess run per gesture.

## Gestures

| Gesture | GUI action | Kernel operation |
|---------|-----------|------------------|
| Sketch > Point mode, click | quantize the click to the grid | `Create_Vertex (P, H)` + `Put_Vertex (H)` |
| Sketch > Edge mode, click | quantize; if the point equals an existing vertex point exactly, reuse that vertex | `Create_Vertex (P, H)` when the point is new, then `Create_Edge (A, B, E)` on the second click, + `Put_Edge (E)` |
| Sketch > Loop mode, clicks, closed on the first point | accumulate the clicked points GUI-side; the whole figure is submitted atomically on the closing click | `Create_Vertex` for the new points, `Create_Edge (A, B, E)` along the traversal, `Add_Point (P)` over the closed chain, then `Make_Loop_From_Edges (K)` + `Put_Loop (K)` |
| Sketch > Face, one menu action | classify the accumulated chain of the accepted loop | `Make_Face (K)` + `Put_Face (K)` |

An edge whose two ends resolve to the same vertex is submitted anyway:
the kernel rejects it (degenerate edge), and the rejection is displayed
verbatim. The GUI never pre-judges a kernel decision.

## Loop and face construction (v0 increment 3)

The loop gesture is atomic: the clicked points accumulate GUI-side only
(rendered as outline markers), and the closing click — the point equal
to the first clicked point, exact integer equality — submits the whole
figure as one candidate replay: the new vertices, the edges along the
traversal, the `Add_Point` chain closed on the first point, and
`Make_Loop_From_Edges` over the created edges. Nothing reaches the
kernel before the closure, and an abandoned figure leaves no session
trace. A two-point closure and a same-point closure are submitted
anyway: the kernel classifies them (degenerate chain, degenerate
support), and the classification or diagnostic is displayed verbatim —
including the single-point figure of two clicks on the same point,
whose closing edge is degenerate.

The loop is accepted only when the run exits 0 and the canonical trace
is `loop closed counter_clockwise` or `loop closed clockwise`; any
other classification (`loop closed degenerate`, ...), diagnostic, or
non-zero status drops the candidate and displays what the kernel
reported. The same acceptance rule governs the face: only
`face counter_clockwise` or `face clockwise` extend the session.

The face gesture is one menu action, not a drawing mode: it submits
`Make_Face (K)` + `Put_Face (K)` over the chain the accepted loop
appended to the replay script. The chain is session state — the
`Add_Point` statements are part of the replay, like the vertex and
edge statements — and the accepted face is recorded with its boundary
handles, so the view fills the enclosed polygon.

One figure per session: `Make_Loop_From_Edges` classifies every edge
of the session in creation order, so a loop drawn over a session that
already carries free edges is rejected by the kernel (disconnected
chain), displayed verbatim; and a second loop or face after the first
classifies the first figure's chain again. v0 keeps this discipline:
the session is one figure — points, its edges, its loop, its face —
and the session save-and-load increment keeps the same shape.

**Snapping is exact integer equality** between the quantized click
point and the kernel-reported points of the session — no tolerance, no
epsilon. The quantization to the grid is the input step, not a fuzzy
comparison; two candidate vertices at the same point resolve to the
most recently created one (deterministic; DD-002 keeps their identity
distinct, and v0 has no selection UI to name one).

## Screen-to-grid mapping

The canvas maps pixels to grid units with a fixed scale: 10 px per
grid unit, the origin at the canvas centre, grid Y up, screen Y down.
The quantization rounds to the nearest grid line, in exact integer
arithmetic.

Bounds: the mapping divides a pixel offset by the scale, so the
absolute coordinate is bounded by half the canvas size over the scale
— a few thousand units for any real window, far below `Grid_Last`
(2**30 - 1). The GUI rejects (and reports) any mapping outside
`Grid_Coordinate` before a gesture reaches the kernel.

## Rendering

The view renders the session as an SVG string — exact integer
coordinates, one document at the canvas size — and hands it to the
Adi2 `Image` widget, refreshed (`Set_Image` + `Mark_Dirty`) after every
accepted gesture. Rasterization belongs to the toolkit; the view
carries no geometry logic of its own. The grid (unit lines, axes) and
the drawing ink are view concerns; the drawing accent entered the theme
with increment 2, and the accepted face renders as the polygon filled
with the same accent at low opacity, over the edges.

## Testing

- Headless: the replay script runs under `topocli run` — the same
  construction the GUI performs, verifiable without a display.
- GUI: MCP-driven during development (widget tree, screenshots, menu
  clicks), plus a gesture injection channel: a `click` file in the
  application's MCP channel directory (`/tmp/adi_mcp/<pid>/click`,
  content "X Y" in canvas-local pixels) runs the exact gesture path of
  a real press. The channel exists because the MCP widget clicks do
  not carry raw mouse events, and the session is Wayland (X11 tools
  like xdotool cannot reach the window); it is the documented
  workaround until Adi2 offers a window-level mouse hook.
- Manual owner testing of the delivered executable.

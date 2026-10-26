# Drawing model (v0, increment 2) <!-- omit from toc -->

> **Status:** implemented. The authority is DD-006: every geometric
> decision comes from the proved kernel through the single TopoScript
> front-end; the GUI owns only the view, the interaction, and the
> session.

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

An edge whose two ends resolve to the same vertex is submitted anyway:
the kernel rejects it (degenerate edge), and the rejection is displayed
verbatim. The GUI never pre-judges a kernel decision.

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
the drawing ink are view concerns; the drawing accent enters the theme
with this increment.

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

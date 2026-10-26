# TopoGUI development plan <!-- omit from toc -->

> **Authority:** DD-006 in the TopoProof repository. TopoGUI is the
> user-facing client of the proved TopoProof kernel, driven through the
> single TopoScript front-end. Kernel gaps discovered here enter the
> TopoProof development plan; they are never developed inside TopoGUI.

## Strategy

TopoGUI is developed as a thin client: the plan starts from user needs
and fills the gap to the proved kernel, instead of extending the kernel
towards the interface. Every geometric operation is a kernel operation;
TopoGUI owns only the view, the interaction, and the session.

## v0 - 2D drawing

### Goal

Draw exact 2D geometry interactively on the grid, with the kernel
deciding every construction and every rejection.

### Operations (user gesture -> kernel operation)

- Click a point -> create a vertex.
- Connect two points -> create an edge.
- Close a figure -> build a loop (`Make_Loop_From_Edges`).
- Validate a face -> create a face.
- Move an element -> exact grid translation.
- Snap -> exact point equality.
- Check an intersection -> segment intersection classification.
- Any kernel rejection -> displayed verbatim.

### Kernel gap

None expected: the proved base covers every v0 operation.

### Delivery increments

1. Application shell and canvas on Adi2.
2. Point and edge drawing, with exact grid snapping.
3. Loop and face construction, with kernel rejections displayed.
4. Move (exact translation) and selection.
5. Session save and load (TopoScript form, so the session stays
   headless-testable).

### Completion criteria

- Every drawing action maps to one kernel operation, run through
  TopoScript.
- The headless test path (`topocli run` on saved sessions) covers the
  whole construction logic.
- The owner has tested the executable manually on the three target
  platforms, or their CI equivalents.

## v1 - Extrusion and direct primitives

### Goal

First 3D modelling gestures: extrude a 2D drawing, and create a
rectangular parallelepiped or a cylinder directly.

### Operations

- Extrude a closed 2D drawing along a displacement vector.
- Create a rectangular parallelepiped (directly, one gesture).
- Create a cylinder (directly, one gesture).

### Kernel gaps (TopoProof side, to be specified before v1)

- Extrusion: an exact prism from a closed planar loop; a new kernel
  milestone in the TopoProof development plan.
- Cylinder: its exact representation in the discrete model needs a
  design decision (see DD-006, open questions).
- Rectangular parallelepiped: expected to be a scripted composition of
  the existing construction operations; to confirm.

### Completion criteria

- v0 completion criteria, plus:
- The new kernel operations are proved and executed through the same
  TopoScript front-end, with no GUI-only path.
- The direct primitives produce closed, classified shells or solids,
  with every kernel rejection visible.

## v2 - outlook (not committed)

Fusion of arbitrary volumes, to put the kernel to the test. This stays
an outlook until it enters the TopoProof development plan; no design or
implementation work starts before then (repository rule: research
perspectives are never implemented first).

## Visual direction

A slate sketchbook (2026-10-25: neumorphic soft-extruded look trialled
and adopted; see the git history for the darker drafting-table look it
replaced). One soft surface colour everywhere - window, menu bar,
status line, buttons and canvas share it - and the relief comes from a
soft dark shadow towards the bottom right, completed by a light top and
left border edge. The pressed state inverts the edges and drops the
shadow: the widget reads as pressed in. The canvas is the hero: the
same surface, a large quiet inset, where the drawing will appear. The
status line is where kernel rejections are displayed verbatim. The
tokens live in `src/topogui-theme.ads` (`Surface`, `Shadow_Dark`,
`Edge_Light`, ...); a drawing accent for selected or constructed
geometry is deliberately not chosen until the drawing increment needs
one.

## Testing

See the testing policy in `AGENTS.md`: headless HAC/TopoScript testing
of everything that drives the kernel, MCP-driven automated GUI testing,
manual owner testing of the delivered executable.

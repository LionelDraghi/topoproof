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

The light, flat, Material-like direction (2026-10-29, owner's decision):
white panels and canvas on a near-white ground, hairline dividers where
the panels meet, one blue accent, and the relief reduced to the soft
shadow a raised card deserves. No extrusion, no pressed-depth inversion:
the pressed state is a shade, the way Material buttons read; the context
menus are white cards with shaded item rows. The reference is the
PaliCAD clarity: a minimal, uncluttered CAD front-end.

The rule sets live in `src/topogui-theme-material.ads`; the views
consume them through the `Topogui.Theme` contract (a parameterless
accessor per role), so switching direction is a body change: the
soft-extruded slate sketchbook of 2026-10-25 is archived as built in
`src/topogui-theme-neumorphic.ads` and can be rebound from
`topogui-theme.adb` (it predates the Menu_* rule sets; supply them when
switching back). A drawing accent for selected geometry is deliberately
not chosen until the selection increment needs one.

Layout findings (2026-10-29, the layout that hid the first direction
change): a flex item whose child carries an explicit size grows to it
unless the item clips — the canvas box carries `Overflow_Hidden`
(Overflow_X/Overflow_Y), which zeroes the CSS automatic minimum size and
breaks the image-size feedback loop that inflated the canvas to
millions of pixels and buried the menus.

## Testing

See the testing policy in `AGENTS.md`: headless HAC/TopoScript testing
of everything that drives the kernel, MCP-driven automated GUI testing,
manual owner testing of the delivered executable.

## References

- [PaliCAD](https://github.com/braydennilsen/PaliCAD) (2026-10-26): a
  very simple and clean CAD GUI in Flutter. A reference for what a
  minimal, uncluttered CAD front-end can look like.

# Vertex move: an exact translation of an existing vertex <!-- omit from toc -->

Source: DD-006 open question 4 (the kernel gap, revealed by the
front-end work; owner arbitration of 2026-11-09 — the operation belongs
to the kernel, no client fills the gap itself).

## Contents <!-- omit from toc -->

- [Need](#need)
- [Intended outcome](#intended-outcome)
- [Scope](#scope)
- [Non-goals](#non-goals)
- [Acceptance criteria](#acceptance-criteria)
- [Specification](#specification)
- [Executable scenarios](#executable-scenarios)
  - [Scenario: move a vertex and trace it](#scenario-move-a-vertex-and-trace-it)
  - [Scenario: the other vertices are untouched](#scenario-the-other-vertices-are-untouched)
  - [Scenario: a move beyond the grid is rejected](#scenario-a-move-beyond-the-grid-is-rejected)
  - [Scenario: a rejected move lets the script run on](#scenario-a-rejected-move-lets-the-script-run-on)
- [Verification beyond bbt](#verification-beyond-bbt)
- [Design implications](#design-implications)
- [Open questions](#open-questions)

## Need

An interactive CAD model needs an in-place relocation of an existing
vertex: editing a drawing — dragging, nudging, correcting an input
mistake — adjusts the position of a vertex the model already carries,
instead of tearing down and rebuilding the structures that reference
it. The identity-preserving move is therefore a general kernel
operation, like creation or classification.

The proved base has no such operation: the vertex store is create-only
(`Create` is the only write, vertices are immutable after creation),
and the proved geometry `Translate` computes a new point without
touching a handle. The kernel gap surfaced when the graphical
front-end work hit this absence (DD-006, open question 4); per DD-006,
no client fills such a gap by re-implementing geometry or mutating
state behind the kernel.

The kernel model already tolerates the move cleanly: nothing derived is
cached. Edge stores carry handle pairs only, loop and face
classifications are computed from the current store state, the plane of
a 3D face is derived and never stored (DD-005, decision 3). A mutation
therefore cannot leave a stale derived state by construction; what it
can do — degenerate a figure, flip its orientation — is exactly what
the kernel classifications report.

## Intended outcome

- `TopoProof.Topology.Vertices` exposes an explicit mutation of the
  point of an existing vertex, by an exact displacement, with the
  contracts and the proof discipline of every public operation — the
  moved point delivered by the out parameter: a move the kernel
  rejects records its diagnostic, writes nothing, and touches no
  store.
- The single TopoScript front-end exposes the same operation: a
  scripted move is one replayable statement, so a session recorded as a
  TopoScript — the general input form — expresses a move like any other
  construction, with its result in a variable the script holds.
- The canonical trace of the moved vertex is the ordinary
  `vertex N point X Y`, written by `Put_Vertex` after the move: every
  client observes the move through the same trace as a creation, and
  positions are read only from what the kernel reports.

## Scope

- `TopoProof.Topology.Vertices`: one new public operation on the 2D
  vertex store.
- The scripting surface of `topocli`: the native callback, the wrapper
  declaration, and the feature-documentation scenario block.
- The feature documentation page for the vertex lifecycle
  (`vertices.md`): the move contract and its scenarios.

## Non-goals

- No 3D counterpart in this change (`Vertices_3d.Move` is deferred to
  the first 3D move need).
- No move of edges, loops, faces, or any derived structure: they have
  no geometry of their own to move.
- No vertex deletion, no handle remapping, no merge: identity rules
  stay as DD-002 states them.
- No selection or gesture work in any client: the front-end moves on
  top of the proved operation, out of this kernel proposal.

## Acceptance criteria

- The store operation is specified with explicit `Pre`/`Post`
  contracts, and `make check` passes from a clean state (build, bbt
  documentation runs, GNATprove level 2, evidence validation).
- The move acceptance tests record: the moved point, the untouched
  other vertices, the rejection beyond the grid, and the unchanged
  store after a rejection.
- The scripting API documents the move with its exact statement form
  and the resulting canonical traces, exercised by `make test`.
- A replayable session stays consistent: a move statement executes
  like any other statement, and the previous traces of a run are the
  run's record — nothing is retroactively edited.

## Specification

The kernel operation, in `TopoProof.Topology.Vertices`:

```ada
procedure Move (Store     : in out Vertex_Store;
                V         : Vertex_Handle;
                DX, DY    : Vector_Component;
                New_Point :    out Points.Point_2D)
```

- **Precondition:** the result must be representable — the translated
  components stay within `Grid_Coordinate` — the exact reading of the
  proved `Translation_Is_Representable` over the two planar axes. The
  arithmetic reasoning is the one the proved `Translate` already
  carries (the extended-component intermediate, the overflow check);
  the move adds no new numeric law.
- **Postcondition:** the point of `V` is `Point_Of (Store, V)'Old`
  translated by `(DX, DY)`, and `New_Point` carries exactly that
  translated point — the out parameter answers the call, the caller
  never recomputes or reads back; the count is unchanged; every *other*
  stored vertex keeps its point; every handle keeps its meaning. The
  same shape as the `Create` postcondition, minus the count growth.
- The store keeps its create-only history in every other respect: no
  removal, no reallocation, handles stable.

The native bridge follows the translation page exactly: the scripted
statement runs the representability check first; a move the kernel
rejects records the diagnostic, writes nothing, touches no store — the
run continues, and the first failure is retained. A move the kernel
accepts applies the mutation and writes the moved point into the out
parameter.

The scripted surface, in the topology domain of the API:

```ada
Move_Vertex (V, DX, DY, Q);
Put_Vertex (V);
```

- `Move_Vertex (V, DX, DY, Q)` applies the exact displacement `(DX, DY)`
  to the point of the vertex handle `V`, and writes the moved point
  into `Q : Point_2D` — the same statement shape as
  `Translate (P, D, Result)`. A non-representable move is a rejected
  operation with the observable contract of the other kernel
  rejections: the diagnostic on standard error, the first failure
  retained, and the out parameter and the store untouched.
- `Put_Vertex (V)` keeps its existing trace form
  `vertex N point X Y`, at the new position: the move is observable
  through the same trace as a creation, and the acceptance rule of a
  front-end run stays the one it already applies to every statement —
  the run exits 0 and the expected canonical trace appears.
- The moved point is therefore a kernel-produced value like any other:
  a script draws it the way the translation page draws its result,
  without stating the arithmetic itself.

The delta is stated as displacement components, not absolute points,
for the same reason the geometry `Translate` is stated by displacement:
it composes with the proved translation/displacement law, and the
interactive gesture it serves is naturally a displacement (a drag).
The absolute form remains expressible as a move by the displacement
between two points, the proved `Displacement`.

## Executable scenarios

The diagrams follow the executable-documentation convention (`TDL-DOC-001`,
`docs/features/`): the scripts generate the SVG images of the tested
commands through `Begin_Image`, the scenarios check the drawn inks, and
`make test` validates every generated diagram as XML. Blue is the
`Color_Kind` input ink, red the result ink; a rejected move draws the
starting point only — the moved point does not exist.

### Scenario: move a vertex and trace it

The diagram draws the starting point in blue and the moved point in
red, the way the translation page draws its result: the moved point is
the kernel-reported out value, never a script-side recomputation. The
observable result of the scenario stays the canonical trace, which the
kernel writes.

- Given the file `move_vertex.topo`
  ```ada
  P : constant Point_2D := (10, -20);
  V : Vertex_Handle;
  Q : Point_2D;

  Create_Vertex (P, V);
  Move_Vertex (V, 5, 7, Q);
  Put_Vertex (V);

  Begin_Image (+"../docs/features/images/vertex_move_1.svg");
  Draw_Axes;
  Draw_Named_Point_2D (P, +"Before", Blue);
  Draw_Named_Point_2D (Q, +"Moved", Red);
  End_Image;
  ```
- When I successfully run `../bin/topocli run move_vertex.topo`
- Then the output is `vertex 1 point 15 -13`
- And the file `../docs/features/images/vertex_move_1.svg` contains `#cf222e`  \
  (The `#cf222e` value is the red of `Color_Kind`: the check ensures the
  moved point, the actual result of the scenario, is drawn red at the
  position the trace reports.)
- And the file `../docs/features/images/vertex_move_1.svg` contains `#1f6feb`  \
  (The `#1f6feb` value is the blue of `Color_Kind`: the check ensures
  the starting point is drawn.)

### Scenario: the other vertices are untouched

The diagram draws the moved vertex in red and the untouched one in
blue: a move relocates one identity, the other vertices keep their
positions (DD-002, identity is not position; and no other identity
moves).

- Given the file `move_first_of_two.topo`
  ```ada
  P1 : constant Point_2D := (10, -20);
  P2 : constant Point_2D := (3, 4);
  V1 : Vertex_Handle;
  V2 : Vertex_Handle;
  Q  : Point_2D;

  Create_Vertex (P1, V1);
  Create_Vertex (P2, V2);
  Move_Vertex (V1, 5, 7, Q);
  Put_Vertex (V1);
  Put_Vertex (V2);

  Begin_Image (+"../docs/features/images/vertex_move_2.svg");
  Draw_Axes;
  Draw_Named_Point_2D (P2, +"Untouched", Blue);
  Draw_Named_Point_2D (Q, +"Moved", Red);
  End_Image;
  ```
- When I successfully run `../bin/topocli run move_first_of_two.topo`
- Then the output is
  ```text
  vertex 1 point 15 -13
  vertex 2 point 3 4
  ```
- And the file `../docs/features/images/vertex_move_2.svg` contains `#cf222e`  \
  (The red of `Color_Kind`: the moved vertex)
- And the file `../docs/features/images/vertex_move_2.svg` contains `#1f6feb`  \
  (The blue of `Color_Kind`: the untouched vertex)

### Scenario: a move beyond the grid is rejected

The point starts on the corner of the grid; the move would take it one
unit beyond the largest representable position. The image draws the
starting point only: the moved point does not exist, so the check also
ensures that nothing red is drawn — the starting point at the tip of
the representable grid, and no result.

- Given the file `move_beyond.topo`
  ```ada
  P : constant Point_2D := (1073741823, 0);
  V : Vertex_Handle;
  Q : Point_2D;

  Begin_Image (+"../docs/features/images/vertex_move_beyond.svg");
  Draw_Axes;
  Draw_Named_Point_2D (P, +"P", Blue);
  End_Image;

  Create_Vertex (P, V);
  Move_Vertex (V, 1, 0, Q);
  ```
- When I run `../bin/topocli run move_beyond.topo`
- Then the error output is `error: the vertex move is not representable`
- And the exit code is `1`
- And the file `../docs/features/images/vertex_move_beyond.svg` contains `#1f6feb`  \
  (The `#1f6feb` value is the blue of `Color_Kind`: the check ensures
  the starting point is drawn, at the tip of the representable grid.)

### Scenario: a rejected move lets the script run on

A rejected operation records its diagnostic, and the first failure is
retained — the trace of the unchanged store still comes out, and the
run fails with the move's diagnostic.

- Given the file `move_rejected_trace.topo`
  ```ada
  P  : constant Point_2D := (1073741823, 0);
  V  : Vertex_Handle;
  Q  : Point_2D;

  Create_Vertex (P, V);
  Move_Vertex (V, 1, 0, Q);
  Put_Vertex (V);
  ```
- When I run `../bin/topocli run move_rejected_trace.topo`
- Then the output is `vertex 1 point 1073741823 0`
- And the error output is `error: the vertex move is not representable`
- And the exit code is `1`

(The last scenario fixes the run-scope semantics: a rejected kernel
operation records its diagnostic and lets the script continue, as the
chain-discipline scenarios of `toposcript.md` establish; the trace
after the failed move reads the unchanged store, and the untouched `Q`
is the delivered-result half of the same rule — a failed call delivers
nothing.)

## Verification beyond bbt

- Unit tests: not applicable — the executable-documentation scenarios
  cover the observable behaviour, as everywhere else.
- SPARK / proof: `make prove` on the touched unit must prove the new
  `Move` at level 2 with no exception: the overflow precondition
  reasoning reuses the proved translation material, and the unchanged
  store posts are the same quantified forms `Create` already proves.
- Proof objective (optional, cheap): a ghost lemma stating that moving
  by `D` then by the negated `D` restores the point, the 2D echo of
  `Lemma_Translate_Displacement` — to be arbitrated when the proof step
  opens, not before.

## Design implications

- **DD-002** (identity is not position): the move changes the position
  of an existing identity; no merging, no new handle. The two-vertices
  scenario documents the reading.
- **DD-005, decision 3** (derived geometry never stored): the move is
  safe with no re-classification machinery precisely because loop and
  face classifications are queries over the current store state.
- **DD-006, gap policy** (decision 6) and **open question 4**: this
  proposal is the kernel answer to the gap; the front-end increments
  resume on top of the proved operation. How a client reads back the
  model it drives through the front-end is a client concern, not a
  kernel one.
- **Terminology**: the operation moves a *vertex*, whose *point*
  becomes another point; the delta components are
  *displacements* (`Vector_Component`), not positions
  (`Grid_Coordinate`) — the naming follows `docs/terminology.md`.

## Open questions

- Exact rejection diagnostic: `error: the vertex move is not
  representable` is proposed, in the family of the translation
  diagnostic (`error: translation is not representable`); to confirm
  during integration.
- The out-parameter form is the owner's arbitration: an operation
  without a delivered result can fail silently, so `Move_Vertex` states
  the moved point like `Translate` states its result (the former
  question open question — a read-back accessor — is settled by this
  form).
- The delta form `(V, DX, DY)` avoids introducing a `Vector_2D` type; introducing
  one now is deliberate avoidance (no operation of the current model
  needs a 2D vector type beyond this call form). An added `Vector_2D`
  would only re-shape this same statement form.
- The 3D counterpart `Vertices_3d.Move` is out of scope here; the
  proposal is written so that the twin is the same contract over
  `Point_3D`/`Vector_3D` when a need appears.

## Finalization target

The vertex lifecycle page: `docs/features/vertices.md` gains the move
contract and its scenarios next to `Create_Vertex`; the scripting-API
table of `docs/features/toposcript.md` gains the `Move_Vertex` row.

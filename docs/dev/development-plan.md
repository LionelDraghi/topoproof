# TopoProof development plan <!-- omit from toc -->

## Contents <!-- omit from toc -->

- [Strategy](#strategy)
- [Milestone 1: first proved geometric operation](#milestone-1-first-proved-geometric-operation)
- [Milestone 2: first geometric predicate](#milestone-2-first-geometric-predicate)
- [Milestone 3: segment intersection in 2D](#milestone-3-segment-intersection-in-2d)
- [Milestone 4: contours and loops in 2D](#milestone-4-contours-and-loops-in-2d)
- [Milestone 5 - First Topological Structure](#milestone-5---first-topological-structure)
  - [Goal](#goal)
  - [Deliverables](#deliverables)
  - [Capabilities](#capabilities)
  - [Invariants](#invariants)
  - [Proof Objectives](#proof-objectives)
  - [Executable Scenarios](#executable-scenarios)
  - [Completion Criteria](#completion-criteria)
- [Milestone 6 - TopoScript Embedded Scripting](#milestone-6---toposcript-embedded-scripting)
  - [Goal](#goal-1)
  - [Deliverables](#deliverables-1)
  - [Runtime Architecture](#runtime-architecture)
  - [Capabilities](#capabilities-1)
  - [Invariants](#invariants-1)
  - [Proof Objectives](#proof-objectives-1)
  - [Executable Scenarios](#executable-scenarios-1)
  - [Delivery Increments](#delivery-increments)
  - [Out of Scope](#out-of-scope)
  - [Completion Criteria](#completion-criteria-1)
- [TopoScript consolidation](#toposcript-consolidation)
  - [Goal](#goal-2)
  - [Deliverables](#deliverables-2)
  - [Capabilities](#capabilities-2)
  - [Invariants](#invariants-2)
  - [Executable Scenarios](#executable-scenarios-2)
  - [Delivery Increments](#delivery-increments-1)
  - [Out of Scope](#out-of-scope-1)
  - [Completion Criteria](#completion-criteria-2)
- [Milestone 7 - Transition to 3D](#milestone-7---transition-to-3d)
  - [Goal](#goal-3)
  - [Deliverables](#deliverables-3)
  - [Capabilities](#capabilities-3)
  - [Invariants](#invariants-3)
  - [Proof Objectives](#proof-objectives-2)
  - [Executable Scenarios](#executable-scenarios-3)
  - [Completion Criteria](#completion-criteria-3)
- [Milestone 8 - Minimal B-Rep](#milestone-8---minimal-b-rep)
  - [Goal](#goal-4)
  - [Deliverables](#deliverables-4)
  - [Capabilities](#capabilities-4)
  - [Invariants](#invariants-4)
  - [Proof Objectives](#proof-objectives-3)
  - [Executable Scenarios](#executable-scenarios-4)
  - [Out of Scope](#out-of-scope-2)
  - [Completion Criteria](#completion-criteria-4)
- [Completion rule](#completion-rule)

## Strategy

TopoProof is developed vertically through complete, formally verified increments. Every increment covers types, operations, contracts, proof, executable tests, and documentation while preserving existing invariants.

## Milestone 1: first proved geometric operation

Deliver only:

- `Grid_Coordinate` and `Vector_Component`;
- `Point_3D` and `Vector_3D`;
- `Translation_Is_Representable`;
- `Translate`;
- `Displacement`;
- exact point equality;
- absence-of-runtime-error and overflow proofs;
- proof of `Translate (A, Displacement (A, B)) = B` over the advertised domain;
- corresponding executable tests.

Tests cover the null vector, interior and boundary translations, negative coordinates, non-representable translations, point displacement, the translation/displacement identity, and point equality.

## Milestone 2: first geometric predicate

Introduce `Point_2D`, `Orientation_Kind`, and exact orientation based on the determinant sign, with the 2D translation surface needed to state invariance. Prove absence of overflow, exhaustive classification, permutation behaviour, collinearity (including degenerate paths with coincident points), and translation invariance within the valid domain.

## Milestone 3: segment intersection in 2D

Introduce `Segment_2D` and the exact on-segment predicate. Distinguish no intersection, point intersection, crossing at a non-grid position, and overlapping segments: the discrete model states off-grid crossings exactly instead of approximating them. Prove symmetry, membership of intersection results, explicit treatment of collinear cases, and absence of tolerance-based decisions.

## Milestone 4: contours and loops in 2D

Introduce oriented segment sequences, continuity, closure, degenerate-edge rejection, self-intersection detection, and contour orientation.

## Milestone 5 - First Topological Structure

### Goal

Introduce the first topological entities and establish the separation between geometry and topology. Geometry defines positions; topology defines incidence and connectivity.

### Deliverables

- Vertex
- Edge
- Loop
- Face

### Capabilities

- Create a vertex from a point.
- Create an edge between two distinct vertices.
- Build a loop from a sequence of connected edges.
- Build a planar face from a valid loop.
- Support orientation of loops and faces.

### Invariants

- Every vertex references a valid point.
- Every edge has exactly two endpoints.
- Edge endpoints exist.
- Degenerate edges are forbidden.
- Loops are closed.
- Consecutive edges in a loop are connected.
- Loops contain no orphan edges.
- Face boundaries are valid loops.
- Face orientation is consistent with loop orientation.

### Proof Objectives

- Reference validity is preserved.
- Loop closure is guaranteed.
- Orientation consistency is preserved.
- Invalid faces cannot be created through the public API.
- Construction operations preserve all invariants.

### Executable Scenarios

- Triangle.
- Square.
- Open loop rejection.
- Degenerate edge rejection.
- Face creation from a valid loop.
- Clockwise and counterclockwise orientations.

### Completion Criteria

- All topology types have documented contracts.
- All public operations are proven.
- All executable scenarios pass.
- Topological validity is enforced by construction.


## Milestone 6 - TopoScript Embedded Scripting

### Goal

Introduce TopoScript, a lightweight Ada-based scripting facility implemented
with HAC, with two complementary uses: readable executable inputs for bbt
scenarios, and the future language for user macros, modules, and extensions.
TopoScript complements the graphical user interface: it is not intended to turn
TopoProof into an Ada equivalent of OpenSCAD, and it does not reduce the
importance of an efficient GUI.

### Deliverables

- HAC as an experimental dependency of the tools crate.
- `topocli run FILE.topo`, the entry point accepting a TopoScript source.
- The hidden Ada compilation-unit wrapper generated by `topocli`.
- The initial TopoProof scripting API, giving scripts access to the existing
  proved operations.
- The minimum drawing API needed by the migrated scenarios.
- One migrated nominal and one migrated expected-error geometry scenario.

### Runtime Architecture

```text
bbt scenario
    -> embedded TopoScript written to the scenario file context
    -> topocli run
    -> TopoScript wrapper generation
    -> HAC compilation and execution
    -> TopoProof scripting API
    -> TopoProof command and geometry layers
```

### Capabilities

- A script defines named points and vectors, calls a TopoProof operation, and
  writes the canonical textual result with `Put (Result);`.
- A script generates one diagnostic image containing the axes, the input
  geometry, the expected geometry, and the actual result, so a failure is
  immediately visible.
- Script execution preserves the output contract: standard output carries the
  canonical value inspected by bbt, standard error carries diagnostics and
  execution errors, generated files carry visual or model artefacts, and the
  process status reports successful or failed execution.
- The same core language later supports standalone `.topo` files for user
  automation: reusable macros, parameterised modelling operations,
  user-defined commands, optional GUI modules, and automated import,
  transformation, and export workflows.

### Invariants

- The geometry core does not depend on HAC, `topocli`, bbt, or the GUI.
- The GUI, CLI, and scripting layer converge on shared TopoProof operations
  rather than duplicate geometric behaviour.
- Test verdicts remain the responsibility of bbt: the expected result stays in
  the `Then` step, the script only produces the actual observable result, and
  TopoScript introduces no parallel assertion framework.
- Declarations precede executable statements; a declaration appearing after the
  first executable statement is rejected.
- Existing bbt syntax is unchanged; the scenario-local `.topo` file is an
  execution artefact, not a separately maintained test source.

### Proof Objectives

- The scripting layer lives in the tools crate, outside the proved kernel.
- No kernel unit is added or modified: existing proof obligations are
  unaffected, and the scripting API calls the proved operations instead of
  re-implementing them.

### Executable Scenarios

- An embedded TopoScript translates a point and prints `point 15 -13 21`.
- An expected-error scenario keeps its textual output and error status
  semantics.
- A script draws one diagnostic image without polluting the canonical standard
  output.
- CLI-specific scenarios keep exercising the real CLI syntax: help, argument
  parsing, invalid options, output redirection.

### Delivery Increments

1. Feasibility prototype: add HAC as an experimental dependency; compile and
   execute a minimal in-memory or temporary Ada source; demonstrate a call to
   one TopoProof operation; capture standard output, standard error, and
   execution status; validate the required HAC language subset.
2. TopoScript wrapper: accept a `.topo` source containing declarations followed
   by statements; generate the hidden compilation-unit wrapper; report
   compilation errors using source locations meaningful to the original
   fragment; optionally display the generated Ada source.
3. bbt integration: embed a TopoScript block in a scenario using existing bbt
   syntax; materialise it as the scenario input file; execute it through
   `topocli run`; preserve expected textual results in `Then` steps; migrate one
   nominal and one expected-error scenario.
4. Diagnostic drawing: expose the minimum drawing API; generate a single image
   containing inputs, expected geometry, and actual geometry; keep drawing
   output out of the canonical standard output.
5. Scenario migration: migrate geometry scenarios whose long CLI invocations
   obscure intent; retain focused CLI scenarios for behaviour belonging
   specifically to `topocli`.
6. User scripting foundation: support standalone `.topo` scripts outside the
   test suite; define the initial stable scripting API; establish
   error-reporting and compatibility expectations; defer untrusted extension
   loading until the security model is defined.

### Out of Scope

- Replacing the TopoProof GUI with scripted modelling.
- Creating an Ada equivalent of OpenSCAD.
- Changing or simplifying the bbt language.
- Moving expected values or verdict logic into TopoScript.
- Creating a new assertion library for scenario scripts.
- Exposing all internal TopoProof packages to scripts.
- Executing untrusted extensions without isolation.
- Defining the final GUI integration for user extensions.
- Replacing tests specifically intended to verify `topocli` parsing and
  behaviour.

### Completion Criteria

- A bbt scenario embeds a TopoScript using existing bbt syntax, with no
  separately maintained test script.
- `topocli` wraps and executes the embedded source through HAC, and the script
  calls a real TopoProof operation.
- `Put (Result);` produces the canonical textual result on standard output,
  and the bbt `Then` step compares that output with the expected text.
- Expected failures retain their textual output and error status semantics.
- A script can generate one diagnostic image without polluting standard output.
- Compilation and runtime errors refer clearly to the scenario and relevant
  source line.
- Existing CLI-specific tests continue to exercise the real CLI syntax.


## TopoScript consolidation

> **Status: planned for 0.1.4-dev.** This subject is deliberately
> inserted between milestones: the implementation review of
> Milestone 6 validates the architecture and asks for maintainability
> work before the 3D types arrive. The full review content lives in
> this section and in the `TDL` entries it references; the review file
> itself is not archived in the repository.

### Goal

Preserve the validated Milestone 6 architecture while stopping the
growth of the integration layer: make the execution state explicit,
split the native scripting API by responsibility, share the HAC
conversions and the canonical textual representations, and fix the
wrapper source-buffer ownership, before planes, shells, solids, file
import/export, or GUI commands make the scripting layer difficult to
maintain.

### Deliverables

- `Script_Session`, an explicit limited private execution session owning
  the failure, the image state, the drawing scene, the anchor counter
  and the topology chain, with a reliable `Reset`;
- `TopoScript_API` split by domain, the root package coordinating the
  callback registration only: `.Conversions`, `.Geometry`, `.Topology`,
  `.Drawing`, `.Output`, `.Session`;
- conversion helpers between the HAC element arrays and the TopoProof
  types (`Read_Point_2D`, `Read_Point_3D`, `Read_Vector_3D`,
  `Write_Point_3D`), replacing the per-callback decoding duplication;
- one implementation of each canonical textual representation
  (`Image (Point_3D)`, `Image (Loop_Kind)`, `Image (Face_Kind)`),
  shared by the `topocli` commands, the `Put` callbacks and the
  diagnostics;
- the wrapper source-buffer ownership fixed: the previous allocation
  is reclaimed, or the source lives in the stream object;
- bbt scenarios covering the wrapper and session edge cases that are
  observable through `topocli run`.

### Capabilities

- A session owns the whole mutable execution state: two consecutive
  script executions start from a clean state, with no stale failure,
  chain, or image, without relying on process restart;
- a native callback focuses on its operation: the reading, domain
  checking and writing of the HAC values go through the shared helpers;
- the CLI commands, the scripts and the diagnostics write the same
  canonical representations from one implementation.

### Invariants

- No kernel unit is added or modified: the consolidation stays in the
  tools crate, and the scripting API keeps calling the proved
  operations instead of re-implementing them;
- bbt remains the only test harness while one process runs one script:
  the expected results stay in the `Then` steps, and no parallel
  assertion framework is introduced;
- the first rejected operation owns the diagnostic;
- the output contract is unchanged: canonical standard output,
  diagnostics on standard error, generated files, process status;
- an Ada unit-test harness is deferred: it becomes useful only when a
  persistent host makes the session re-entrancy observable from inside
  one process.

### Executable Scenarios

- An empty fragment executes and produces no output.
- A fragment of declarations without statements executes and produces
  no output.
- A CRLF fragment and a fragment whose last line has no final newline
  execute, and diagnostics point at the right fragment lines.
- A declaration split across several lines is rejected with a clean
  diagnostic at the right line, instead of a confusing HAC message.
- A declaration form outside the initial subset (`type`, `procedure`,
  `use`, ...) is rejected before any compilation, with the fragment
  location.
- Two consecutive image sessions in one script produce two images.
- `End_Image` without `Begin_Image` records the rejection diagnostic.
- A chain continues after a rejected operation, and the first failure
  is retained.
- The four representative Milestone 6 scenarios (nominal execution,
  expected kernel rejection, mapped diagnostic, composite drawing)
  stay and stay green.

### Delivery Increments

1. Script session: introduce `Script_Session` and `Reset`, move
   `Failure`, `Image_Open`, `Image_Name`, `The_Scene`, `Anchor_Count`
   and `Chain` into it.
2. API split: move the callbacks into the domain child packages, keep
   `Register_All` in the root, no scenario change.
3. Conversions and canonical output: introduce the `Read_*` /
   `Write_*` helpers and the `Image` formatters, and route the CLI
   commands and the callbacks through them.
4. Buffer ownership: reclaim the previous wrapper source allocation, or
   store the source in the stream object.
5. Edge-case scenarios: add the bbt scenarios listed above.
6. Later, external prelude: load the fixed scripting-API prelude from
   one Ada source file through the GNAT `External_Initialization`
   aspect (an experimental GNAT extension already exercised by bbt),
   validate it on the current toolchain first, compile the loaded
   prelude through HAC in a test, derive the source-mapping offsets
   from the loaded content, and make the build track the file.
7. Later, single API description: derive the generated declarations
   and the callback registrations from one internal description, and
   verify the documented scripting API against it.
8. Later, scanner strengthening: track comments, string literals,
   parenthesis depth and semicolon-terminated constructs, keeping the
   declarations-before-statements rule.
9. Later, semantic drawing identifiers: topodraw writes stable
   identifiers (such as `actual-result`) so the drawing scenarios
   check the intended object rather than the mere presence of a
   colour.

### Out of Scope

- A persistent GUI host executing several macros: the session prepares
  it, it is not delivered here;
- an Ada unit-test harness, deferred until re-entrancy is observable;
- changing or simplifying the bbt language;
- moving expected values or verdict logic into TopoScript;
- the scripting API compatibility versioning and the sandboxing
  restrictions, which stay with `DD-003` / `TDL-DESIGN-004`.

### Completion Criteria

- Two consecutive executions in one process produce no residual state;
  `Reset` is proven by the session edge-case scenarios;
- the root `TopoScript_API` coordinates the registration only;
- each canonical representation has exactly one implementation, and
  the CLI and script outputs agree;
- repeated script executions do not leak the previous source buffers;
- the edge-case scenarios of this section are executable and green;
- `docs/features/toposcript.md` stays consistent with the behaviour.


## Milestone 7 - Transition to 3D

### Goal

Extend the geometric foundation from 2D to 3D while preserving the discrete, exact, and provable model.

### Deliverables

- Vector_3D
- Plane
- Plane_Side
- Intermediate arithmetic types required for bounded calculations

### Capabilities

- Dot product.
- Cross product.
- Plane normal computation.
- Plane construction.
- Point classification relative to a plane.
- Orientation predicates in three dimensions.

### Invariants

- A plane is defined only by non-collinear points.
- Plane normals are never null.
- Intermediate computations remain within declared representability domains.
- Numeric limits are explicit and documented.

### Proof Objectives

- Dot product properties.
- Cross product orthogonality.
- Classification consistency.
- Translation invariance.
- Exhaustive point classification:
  - in front of plane;
  - behind plane;
  - on plane.
- Absence of arithmetic overflow within documented limits.

### Executable Scenarios

- Coordinate planes.
- Coplanar points.
- Point-side classification.
- Rejection of degenerate plane definitions.
- Boundary value tests near representability limits.

### Completion Criteria

- All 3D predicates are deterministic.
- All operations are proven.
- No hidden tolerance is introduced.
- Numeric safety obligations are discharged.


## Milestone 8 - Minimal B-Rep

### Goal

Construct the first closed solid from planar faces and establish a provable boundary-representation model.

### Deliverables

- Shell
- Solid

Optional supporting structures:

- Face_Use
- Loop_Use
- Minimal adjacency structures

### Capabilities

- Assemble faces into a shell.
- Verify shell closure.
- Construct a solid from a closed shell.
- Validate orientation consistency.
- Validate adjacency consistency.

### Invariants

- Face-to-edge incidences are consistent.
- Adjacent faces use compatible edge orientations.
- Shells are closed.
- No free edges exist.
- No orphan faces exist.
- Solids are bounded by exactly one closed shell.

### Proof Objectives

- Incidence consistency.
- Topological closure.
- Global orientation consistency.
- Invalid solids cannot be created through the public API.
- Assembly operations preserve all invariants.

### Executable Scenarios

- Tetrahedron.
- Rectangular box.
- Missing-face rejection.
- Inverted-face rejection.
- Unpaired-edge rejection.
- Closed-shell verification.

### Out of Scope

The following remain explicitly outside the scope of this milestone:

- Curved surfaces.
- NURBS.
- STEP import.
- Boolean operations.
- Healing algorithms.
- Geometric tolerances.

### Completion Criteria

- A closed solid can be represented and verified.
- Topological consistency is enforced by construction.
- All proof obligations are discharged.
- The project reaches its first complete end-to-end B-Rep model.



## Completion rule

A milestone is complete only when its public API is specified, its implementation builds, its stated properties are proved, its observable behaviour is tested, and its documentation is consistent.

# TopoProof development plan

## Contents

- [TopoProof development plan](#topoproof-development-plan)
  - [Contents](#contents)
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
  - [Milestone 6 - Transition to 3D](#milestone-6---transition-to-3d)
    - [Goal](#goal-1)
    - [Deliverables](#deliverables-1)
    - [Capabilities](#capabilities-1)
    - [Invariants](#invariants-1)
    - [Proof Objectives](#proof-objectives-1)
    - [Executable Scenarios](#executable-scenarios-1)
    - [Completion Criteria](#completion-criteria-1)
  - [Milestone 7 - Minimal B-Rep](#milestone-7---minimal-b-rep)
    - [Goal](#goal-2)
    - [Deliverables](#deliverables-2)
    - [Capabilities](#capabilities-2)
    - [Invariants](#invariants-2)
    - [Proof Objectives](#proof-objectives-2)
    - [Executable Scenarios](#executable-scenarios-2)
    - [Out of Scope](#out-of-scope)
    - [Completion Criteria](#completion-criteria-2)
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


## Milestone 6 - Transition to 3D

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


## Milestone 7 - Minimal B-Rep

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

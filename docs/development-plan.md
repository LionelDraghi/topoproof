# TopoProof development plan

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

Introduce `Point_2D`, `Orientation_Kind`, and exact orientation based on the determinant sign. Prove absence of overflow, exhaustive classification, permutation behaviour, collinearity, and translation invariance within the valid domain.

## Milestone 3: segment intersection in 2D

Distinguish no intersection, point intersection, and overlapping segments. Prove symmetry, membership of intersection results, explicit treatment of collinear cases, and absence of tolerance-based decisions.

## Milestone 4: contours and loops in 2D

Introduce oriented segment sequences, continuity, closure, degenerate-edge rejection, self-intersection detection, and contour orientation.

## Milestone 5: first topological structure

Introduce `Vertex`, `Edge`, `Loop`, and planar `Face` only after the required predicates have been validated. Establish reference validity, edge endpoints, loop closure, valid boundaries, and coherent orientation.

## Milestone 6: transition to 3D

Add 3D vectors, dot and cross products, 3D orientation, discrete planes, and point/plane classification, with intermediate numeric types justified by expression degree.

## Milestone 7: minimal B-Rep

Construct a closed polyhedral solid from vertices, edges, loops, planar faces, and a closed shell. Start with a tetrahedron, then a rectangular parallelepiped. Curved surfaces, NURBS, STEP import, and Boolean operations remain outside this milestone.

## Completion rule

A milestone is complete only when its public API is specified, its implementation builds, its stated properties are proved, its observable behaviour is tested, and its documentation is consistent.

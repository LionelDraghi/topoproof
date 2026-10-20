# TopoProof design discussions

This document records design topics. A discussion is not a normative rule
until its status becomes **decided** and the decision is reflected in the
terminology, contracts, executable documentation, and implementation.

## DD-001: validity of segment sequences and future B-Rep boundaries

- **Status:** decided (2026-10-20)
- **Related task:** former `TDL-DESIGN-001`
- **Scope:** `Segment_Sequence_2D`, contours, loops, and future planar face boundaries

### Former situation

`Segment_Sequences.Is_Valid` used to mean:

1. no segment has coincident endpoints; and
2. no three consecutive points are collinear.

This definition gave every retained vertex a non-flat turning direction,
mixing the geometric validity of the chain with a canonical-representation
property of its vertex list.

### Decision

Collinear intermediate points are **not an invalidity**: they are a matter
of representation. Concretely:

- validity is geometric: `Is_Valid` rejects only degenerate segments;
- the former rule (2) becomes the separate predicate
  `Has_No_Flat_Turns`, a canonical-representation property: a valid chain
  with a flat turn describes exactly the same geometry as the chain
  without the redundant point;
- consequently, `Orientation` accepts any closed, valid sequence: the
  signed area of a contour with a flat turn is well defined, and refusing
  to classify it was a functional defect, not a safety rule;
- canonicalisation (removing redundant points) is not specified at this
  stage: it may enter the development plan with milestone 5, when loops
  and face boundaries are introduced, as a representation choice and
  never as a validity rule.

### Rationale

A redundant collinear vertex creates no geometric or topological
ambiguity: the contour delimits exactly the same region. Treating it as
an invalidity would have forced milestone 5 either to reopen the
predicate or to reject geometrically correct face boundaries.

### Remaining questions, deferred to milestone 5

The questions below were part of this discussion and are not settled by
the decision above; they concern the future topological types:

1. Is a closed two-edge backtrack a loop, a degenerate loop, or invalid?
2. Are repeated non-consecutive vertices allowed when they are shared
   endpoints?
3. Does loop simplicity follow the discrete model only, or must
   off-grid crossings also invalidate a face boundary?
4. Which properties belong to geometry, and which belong to the future
   `Is_Valid_Loop` and `Is_Valid_Face_Boundary` predicates?

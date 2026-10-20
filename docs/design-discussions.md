# TopoProof design discussions

This document records design topics that are not yet decided. A discussion is not a
normative rule until its status becomes **decided** and the decision is reflected in
the terminology, contracts, executable documentation, and implementation.

## DD-001: validity of segment sequences and future B-Rep boundaries

- **Status:** not decided
- **Related task:** `TDL-DESIGN-001`
- **Scope:** `Segment_Sequence_2D`, contours, loops, and future planar face boundaries

### Current situation

`Segment_Sequences.Is_Valid` currently means:

1. no segment has coincident endpoints; and
2. no three consecutive points are collinear.

This definition gives every retained vertex a non-flat turning direction. It is useful
for a reduced polygonal representation, but it is not yet the complete validity rule
for a B-Rep loop or face boundary.

### Why `Is_Surface` would be misleading

A segment sequence is a one-dimensional boundary representation. A surface is the
geometric support of a face, not a property of the sequence itself. Renaming the
predicate to `Is_Surface` would therefore conflate:

- a geometric support such as a plane;
- a topological face;
- the boundary loop of that face; and
- the canonical or non-canonical representation of the loop.

### Candidate model

Split the current broad predicate into predicates with one responsibility:

```text
Is_Non_Degenerate   no zero-length edge
Is_Reduced          no redundant collinear intermediate point
Is_Closed           first point equals last point
Is_Simple           no invalid self-intersection
Is_Valid_Loop       closed + non-degenerate + simple
```

For a future planar face, introduce a separate predicate such as:

```text
Is_Valid_Face_Boundary
```

That predicate may additionally require planarity, coherent orientation, valid inner
loops, and containment rules. `Is_Reduced` need not necessarily be part of validity:
a loop can describe the same boundary with an extra collinear point while remaining
geometrically and topologically valid.

### Recommended direction

Keep `Is_Valid` unchanged until the decision is made, to avoid silently changing the
current CLI contract. The likely direction is:

- rename the current concept to `Is_Reduced` or `Has_No_Flat_Turns`;
- define B-Rep-oriented validity through `Is_Valid_Loop` and later
  `Is_Valid_Face_Boundary`;
- treat collinear intermediate points as a canonicalisation issue unless a later
  invariant gives a concrete reason to reject them.

### Questions to arbitrate

1. Are redundant collinear vertices accepted, rejected, or normalised?
2. Is a closed two-edge backtrack a loop, a degenerate loop, or invalid?
3. Are repeated non-consecutive vertices allowed when they are shared endpoints?
4. Does `Is_Simple` follow the discrete model only, or must off-grid crossings also
   invalidate a face boundary?
5. Which properties belong to geometry, and which belong to the future topology types?

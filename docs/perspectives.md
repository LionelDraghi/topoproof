# TopoProof perspectives

> **Status: research document.** This document is non-normative and does not define requirements for the current TopoProof core.

## Contents

- [Certified geometry and intervals](#certified-geometry-and-intervals)
- [Progressive refinement](#progressive-refinement)
- [Three-valued predicates](#three-valued-predicates)
- [Adaptive computation](#adaptive-computation)
- [Convex hulls](#convex-hulls)
- [Long-term vision](#long-term-vision)

## Certified geometry and intervals

TopoProof's core uses discrete geometry, integer coordinates, B-Rep topology, and SPARK proofs. Interval arithmetic is therefore unnecessary for representing a grid coordinate exactly.

Intervals may later represent incomplete but certified geometric knowledge rather than floating-point error. An operation could prove that a solution lies in a region, refine that region, and conclude only when it identifies a unique grid position.

## Progressive refinement

A future algorithm could evolve from a bounding box to a smaller enclosure, then a few grid positions, and finally a unique position. It would preserve what has been established instead of claiming premature exactness.

## Three-valued predicates

A future predicate could return certainly true, certainly false, or indeterminate at the current computation level. The indeterminate case could trigger refinement or wider arithmetic before any topological decision is taken.

## Adaptive computation

A possible long-term strategy is:

```text
64-bit integer computation
-> certified enclosure
-> wider integer or refined computation
-> arbitrary precision when required
```

This is not part of the initial core unless introduced explicitly by a future development milestone.

## Convex hulls

The exact orientation predicate is the comparison primitive of all classical
hull algorithms (Graham scan, gift wrapping, monotone chain). An exact 2D hull
over the grid could be the first bulk operation on a point cloud, and its 3D
counterpart would rely on the plane-side classification of a later milestone.
Degenerate cases (coincident points, collinear edges on the hull) are decided
exactly by the determinant sign, with no tolerance. This is not part of the
development plan until a milestone introduces it.

## Long-term vision

Certified enclosures could form a bridge between mathematical constructions defined in continuous geometry, TopoProof's discrete model, and formal proof of the produced result. Their purpose would be to state exactly what the kernel knows, never to hide uncertainty.

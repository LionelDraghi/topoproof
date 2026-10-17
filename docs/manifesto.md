# TopoProof manifesto

## A provable 3D CAD kernel

**Replace continuous geometry plus tolerances with discrete geometry plus formal proof.**

Traditional geometric kernels approximate continuous geometry with floating-point values. Rounding, loss of precision, order-dependent results, tolerances, and ambiguous geometric equality then become part of the kernel's behaviour.

TopoProof starts from a different premise: manufactured objects do not require infinitely precise coordinates. The modelled space can therefore be an explicit discrete grid. A point is represented by integer coordinates, and two represented points are equal exactly when their coordinates are equal.

## The paradigm

```text
Discrete geometry + exact computation + formal proof
```

This provides deterministic comparisons, exact equality within the chosen model, no hidden tolerance, and no fundamental notion of almost-equal points.

## Provable topology

TopoProof aims at a B-Rep kernel whose essential topological properties can be demonstrated. Edges reference existing vertices, loops are closed, faces have valid boundaries, construction operations preserve established invariants, and invalid states are rejected explicitly.

These properties should derive, as far as practical, from Ada types, SPARK contracts, and proofs rather than solely from tests performed after execution.

## Why Ada and SPARK

Ada supports strongly typed numeric and topological abstractions. SPARK adds preconditions, postconditions, invariants, data-flow analysis, absence-of-runtime-error proofs, and functional proofs.

Proof is not added after design. It is an architectural constraint.

## Vision

TopoProof is intended to be deterministic, explicit about discretisation, free from hidden tolerances, efficient in its advertised domain, and capable of producing precise failures instead of silently inconsistent geometry.

Traditional kernels seek to be correct. **TopoProof is designed so that its essential properties can be proved.**

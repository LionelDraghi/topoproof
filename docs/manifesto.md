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

## Proof obligations

The founding motivation is reliability: no silent crash, no undefined result. The **silver** level of SPARK assurance — the proved absence of run-time errors over the whole input domain — is therefore the minimal baseline for every delivered change. A change that regresses below silver is not a candidate for integration, whatever its features.

But the ambition does not stop at not crashing. The business logic — the geometric and topological properties that define the model, such as exact classification, symmetry, membership, and invariance — is stated in contracts and proved as far as practical. TopoProof aims at least at the **gold** level: the key integrity properties of every delivered operation are proved over the whole domain, not merely observed on tested inputs.

Tests execute the documented behaviour; proofs establish it everywhere. Both are part of every change.

## Vision

TopoProof is intended to be deterministic, explicit about discretisation, free from hidden tolerances, efficient in its advertised domain, and capable of producing precise failures instead of silently inconsistent geometry.

Traditional kernels seek to be correct. **TopoProof is designed so that its essential properties can be proved.**

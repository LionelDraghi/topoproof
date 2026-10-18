# Numeric model

## Status

This document is normative for the first TopoProof milestone. Open decisions are explicitly identified.

## Geometric quantum

The initial hypothesis is:

```text
Grid_Quantum = 10 nm
```

`Grid_Quantum` is positive, explicit, identical on all three axes, and constant during the lifetime of a model. It is not an epsilon: it defines which positions exist in the model.

Whether the quantum will remain fixed or become configurable is an open decision.

## Internal grid unit

One `Grid_Unit` is one integer step on the discrete grid. With the initial quantum, one grid unit represents 10 nm.

Physical units and internal representation must remain distinct concepts.

## Coordinates

The initial coordinate domain is:

```ada
type Grid_Coordinate is range
  -1_000_000_000 ..
   1_000_000_000;
```

With a 10 nm quantum, this represents positions from -10 m to +10 m on each axis. The representation clause and machine type remain to be fixed explicitly.

## Vector components

A difference between two valid coordinates spans the full grid amplitude, so
the domain is derived from the coordinate domain instead of restating
numbers:

```ada
Grid_Amplitude : constant :=
  Grid_Coordinate'Last - Grid_Coordinate'First;

type Vector_Component is range
  -Grid_Amplitude ..
   Grid_Amplitude;
```

`Grid_Coordinate` and `Vector_Component` have different meanings and domains even if an implementation uses related machine representations.

## Intermediate arithmetic

Predicates must use intermediate types sized for the degree of their expressions:

```text
coordinate -> difference -> product -> determinant
```

The orientation determinant is the first application of the full chain. Each
domain is derived from the previous one: the amplitude of a product of two
component differences is the square of the difference amplitude, and the
determinant is the difference of two such products:

```ada
Product_Amplitude : constant :=
  Vector_Component'Last * Vector_Component'Last;

type Product_Component is range
  -Product_Amplitude ..
   Product_Amplitude;

type Determinant is range
  -(2 * Product_Component'Last) ..
   2 * Product_Component'Last;
```

With the initial grid, this gives products bounded by 4E18 and determinants
bounded by 8E18 < 2**63, hence representable on 64 bits. GNATprove proves
that no operation of the orientation predicate can overflow these domains
for any grid input. The initial implementation may restrict the input domain or use a sufficiently wide intermediate type. Adaptive 64-bit, 128-bit, or arbitrary-precision computation is a later concern unless required by the current milestone.

## Representability

An operation is representable when its exact result belongs to the destination type's domain. Representability checks must themselves be free from overflow.

For translation, all three sums must belong to `Grid_Coordinate`:

```text
P.X + V.DX
P.Y + V.DY
P.Z + V.DZ
```

## External conversion

The following remain open decisions:

- conversion between physical units and internal grid units;
- rounding policy for imported values;
- whether points lie on grid nodes or represent grid cells;
- whether the quantum is globally fixed or configurable.

No implicit rounding or hidden tolerance may be introduced.

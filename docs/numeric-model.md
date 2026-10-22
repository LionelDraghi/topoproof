# Numeric model <!-- omit from toc -->

## Contents <!-- omit from toc -->

- [Status](#status)
- [Geometric quantum](#geometric-quantum)
- [Internal grid unit](#internal-grid-unit)
- [Coordinates](#coordinates)
- [Vector components](#vector-components)
- [Intermediate arithmetic](#intermediate-arithmetic)
- [Signed-area sums](#signed-area-sums)
- [Representability](#representability)
- [External conversion](#external-conversion)

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

The grid is sized from the machine, not the other way around: the coordinate
domain is the largest for which the whole expression chain
(coordinate -> difference -> product -> determinant -> cubic) stays on
native machine widths. The binding constraint is the 64-bit determinant
domain, which gives:

```ada
Grid_Last : constant := 2**30 - 1;

type Grid_Coordinate is range
  -Grid_Last ..
   Grid_Last;
```

With a 10 nm quantum, this represents positions from -10.74 m to +10.74 m
on each axis. The representation clause and machine type remain to be fixed
explicitly.

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

With this grid, differences exactly saturate 32 bits, products are bounded
by about 4.6E18, determinants exactly saturate 64 bits (about 9.2E18 <
2**63), and cubic products are bounded by about 2**94 < 2**127. GNATprove
proves that no operation of the orientation predicate can overflow these
domains for any grid input.

The segment crossing test adds the third degree of the chain: the exact
coordinate quotients of the crossing multiply a determinant by a component
difference, bounded by about 2**94 < 2**127, representable on 128 bits:

```ada
Cubic_Amplitude : constant :=
  Determinant'Last * Grid_Amplitude;

type Cubic_Product is range
  -Cubic_Amplitude ..
   Cubic_Amplitude;
```

The crossing point is accepted only when both exact quotients are integers
whose coordinates stay in the grid domain; otherwise the crossing is
reported as off-grid, never approximated. The initial implementation may restrict the input domain or use a sufficiently wide intermediate type. Adaptive 64-bit, 128-bit, or arbitrary-precision computation is a later concern unless required by the current milestone.

## Signed-area sums

The contour orientation of milestone 4 accumulates one orientation
determinant per vertex of a loop, by the shoelace formula. A sum is not a
fixed-degree expression: its bound also depends on the number of
accumulated terms. A sequence length is a `Natural` discriminant, so the
largest sum is bounded by the determinant amplitude times `Natural'Last`:

```ada
Area_Sum_Amplitude : constant :=
  Natural'Last * (2 * Product_Amplitude);

type Area_Sum is range
  -Area_Sum_Amplitude ..
   Area_Sum_Amplitude;
```

With this grid, that is about 2E28 (2**94), again below 2**127, so the
sum stays on the same 128-bit machine width as the cubic products for any
representable sequence length. GNATprove proves that the partial sums
cannot overflow this domain: each term is bounded by the determinant
amplitude, and the loop invariant bounds the partial sum by the number of
accumulated terms.


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

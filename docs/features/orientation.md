# Orientation

`orientation` classifies exactly the path formed by three 2D points:
`topocli orientation A=(AX, AY) B=(BX, BY) C=(CX, CY)`.
The result is `orientation counter_clockwise`, `orientation clockwise` or
`orientation collinear`, according to the exact sign of the determinant:

```text
(BX - AX) * (CY - AY) - (BY - AY) * (CX - AX)
```

There is no tolerance, no angle computation and no floating-point value: the
three products and their difference are computed exactly in integer types
sized for the expression, and the sign of the result decides. The
classification is exhaustive: the determinant is positive, zero or negative,
and each case corresponds to exactly one result.

In the diagram on the left, the path `A -> B -> C` turns
counter-clockwise. In the diagram on the right, the same points visited in
the exchanged order `A -> B -> C` turn clockwise: exchanging two points
mirrors the orientation.

![Counter-clockwise turn](images/orientation_1.svg)

![Clockwise turn](images/orientation_2.svg)

## Contents

- [Scenario: a counter-clockwise path](#scenario-a-counter-clockwise-path)
- [Scenario: a clockwise path](#scenario-a-clockwise-path)
- [Scenario: three aligned points are collinear](#scenario-three-aligned-points-are-collinear)
- [Scenario: two coincident points make a degenerate collinear path](#scenario-two-coincident-points-make-a-degenerate-collinear-path)
- [Scenario: the extreme corners of the grid do not overflow](#scenario-the-extreme-corners-of-the-grid-do-not-overflow)
- [Proved property](#proved-property)
- [Scenario: a cyclic permutation keeps the orientation](#scenario-a-cyclic-permutation-keeps-the-orientation)
- [Scenario: exchanging two points mirrors the orientation](#scenario-exchanging-two-points-mirrors-the-orientation)
- [Scenario: the orientation is invariant under translation](#scenario-the-orientation-is-invariant-under-translation)

## Scenario: a counter-clockwise path

![Counter-clockwise turn](images/orientation_1.svg)

- When I successfully run `../bin/topocli orientation A=(0, 0) B=(1, 0) C=(1, 1) --draw ../docs/features/images/orientation_1.svg`
- Then the output is `orientation counter_clockwise`

## Scenario: a clockwise path

The path turns right at `(1, 0)`.

![Clockwise turn](images/orientation_3.svg)

- When I successfully run `../bin/topocli orientation A=(0, 0) B=(1, 0) C=(1, -1) --draw ../docs/features/images/orientation_3.svg`
- Then the output is `orientation clockwise`

## Scenario: three aligned points are collinear

The path stays on the diagonal line: no turn at all.

![Collinear path](images/orientation_4.svg)

- When I successfully run `../bin/topocli orientation A=(0, 0) B=(2, 2) C=(4, 4) --draw ../docs/features/images/orientation_4.svg`
- Then the output is `orientation collinear`

## Scenario: two coincident points make a degenerate collinear path

`A` and `B` are the same position `(5, 7)`: the path degenerates before
reaching `C`.

![Degenerate path with coincident points](images/orientation_5.svg)

- When I successfully run `../bin/topocli orientation A=(5, 7) B=(5, 7) C=(9, -3) --draw ../docs/features/images/orientation_5.svg`
- Then the output is `orientation collinear`

## Scenario: the extreme corners of the grid do not overflow

The path visits three corners of the grid; the determinant of the extreme
coordinates is computed exactly in the `Determinant` domain.

![Path on the grid corners](images/orientation_6.svg)

- When I successfully run `../bin/topocli orientation A=(1073741823, 0) B=(0, 1073741823) C=(-1073741823, -1073741823) --draw ../docs/features/images/orientation_6.svg --draw-short-labels`
- Then the output is `orientation counter_clockwise`

## Proved property

Cyclically permuting the three points does not change the orientation, and
exchanging two points mirrors it. Both are proved by SPARK over the whole
grid domain, by the ghost procedures
`Lemma_Cyclic_Permutation` and `Lemma_Reversed_Permutation`. Two coincident
points force a degenerate, collinear path
(`Lemma_Degenerate_Collinear`), and the orientation is invariant under any
representable translation of the three points
(`Lemma_Translation_Invariance`). No overflow can occur on any grid input:
the determinant of extreme coordinates is bounded by 8E18, within the proved
`Determinant` domain.

## Scenario: a cyclic permutation keeps the orientation

The same triangle as the first scenario, visited from a different starting
point.

![Counter-clockwise turn](images/orientation_1.svg)

- When I successfully run `../bin/topocli orientation A=(0, 0) B=(1, 0) C=(1, 1) --draw ../docs/features/images/orientation_1.svg`
- Then the output is `orientation counter_clockwise`
- When I successfully run `../bin/topocli orientation A=(1, 0) B=(1, 1) C=(0, 0)`
- Then the output is `orientation counter_clockwise`

## Scenario: exchanging two points mirrors the orientation

The exchanged path of the first scenario.

![Clockwise turn](images/orientation_2.svg)

- When I successfully run `../bin/topocli orientation A=(0, 0) B=(1, 1) C=(1, 0) --draw ../docs/features/images/orientation_2.svg`
- Then the output is `orientation clockwise`

## Scenario: the orientation is invariant under translation

The same path as the first scenario, translated by `(3, 2)`: the turn
direction is unchanged. The diagram shows both paths: the translated path
is passed to `--draw-with`, so the two commands of the scenario share one
image without overlapping.

![A path and its translation](images/orientation_7.svg)

- When I successfully run `../bin/topocli orientation A=(0, 0) B=(1, 0) C=(1, 1) --draw ../docs/features/images/orientation_7.svg --draw-with E=(3,2)F=(4,2)G=(4,3)`
- Then the output is `orientation counter_clockwise`
- When I successfully run `../bin/topocli orientation A=(3, 2) B=(4, 2) C=(4, 3)`
- Then the output is `orientation counter_clockwise`

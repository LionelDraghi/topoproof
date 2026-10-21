# Point equality

`equal` compares two points exactly:
`topocli equal A=(AX, AY, AZ) B=(BX, BY, BZ)`.
Two points are equal exactly when all three coordinates are equal; there is no
tolerance and no notion of almost-equal points.
The canonical result is `equal true` or `equal false`.

In the diagram on the left, `A` and `B` share all three coordinates, so
the points coincide exactly. In the diagram on the right, `A` and `B`
differ only on `Z`, so they are two distinct grid positions.

![Coincident points](images/equality_1.svg)

![Distinct points](images/equality_2.svg)

## Contents

- [Scenario: identical points are equal](#scenario-identical-points-are-equal)
- [Scenario: different points are not equal](#scenario-different-points-are-not-equal)
- [Scenario: opposite points are not equal](#scenario-opposite-points-are-not-equal)

## Scenario: identical points are equal
- When I successfully run `../bin/topocli equal A=(1, 2, 3) B=(1, 2, 3) --draw ../docs/features/images/equality_1.svg`
- Then the output is `equal true`

## Scenario: different points are not equal
- When I successfully run `../bin/topocli equal A=(1, 2, 3) B=(1, 2, 4) --draw ../docs/features/images/equality_2.svg`
- Then the output is `equal false`

## Scenario: opposite points are not equal

`A` and `B` differ on all three axes: two positions symmetric about the
origin.

![Opposite points](images/equality_3.svg)

- When I successfully run `../bin/topocli equal A=(-1, 2, -3) B=(1, -2, 3) --draw ../docs/features/images/equality_3.svg`
- Then the output is `equal false`

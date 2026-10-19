# Point equality

`equal` compares two points exactly: `topoproof equal AX AY AZ BX BY BZ`.
Two points are equal exactly when all three coordinates are equal; there is no
tolerance and no notion of almost-equal points.
The canonical result is `equal true` or `equal false`.

The diagrams show the geometry of the scenarios below. On the left, `A` and
`B` share all three coordinates, so the points coincide exactly. On the right,
`A` and `B` differ only on `Z`, so they are two distinct grid positions.

<!-- topodraw images/equality_1.svg
point A 1 2 3
point B 1 2 3
-->

![Coincident points](images/equality_1.svg)

<!-- topodraw images/equality_2.svg
axes
ticks 1
anchors
point A 1 2 3
point B 1 2 4
-->

![Distinct points](images/equality_2.svg)

## Contents

- [Scenario: identical points are equal](#scenario-identical-points-are-equal)
- [Scenario: different points are not equal](#scenario-different-points-are-not-equal)
- [Scenario: opposite points are not equal](#scenario-opposite-points-are-not-equal)

## Scenario: identical points are equal
- When I successfully run `../bin/topoproof equal 1 2 3 1 2 3`
- Then the output is `equal true`

## Scenario: different points are not equal
- When I successfully run `../bin/topoproof equal 1 2 3 1 2 4`
- Then the output is `equal false`

## Scenario: opposite points are not equal

`A` and `B` differ on all three axes: two positions symmetric about the
origin.

<!-- topodraw images/equality_3.svg
axes
ticks 1
anchors
point A -1 2 -3
point B 1 -2 3
-->

![Opposite points](images/equality_3.svg)

- When I successfully run `../bin/topoproof equal -1 2 -3 1 -2 3`
- Then the output is `equal false`

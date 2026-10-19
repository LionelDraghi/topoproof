# Intersection

`intersect` classifies exactly the intersection of two 2D segments:
`topoproof intersect AX AY BX BY CX CY`, where the first segment runs from
`A` to `B` and the second from `C` to `D`.
The canonical result is one of:

- `intersection no_intersection`: the segments share no common grid position;
- `intersection point_intersection X Y`: they share exactly one grid
  position, returned with its coordinates;
- `intersection off_grid_crossing`: the segments properly cross, but at a
  point that is not a grid position — stated exactly, not approximated;
- `intersection overlap X1 Y1 X2 Y2`: the segments are collinear and share
  the returned sub-segment, canonically ordered along the common line.

The classification uses only exact integer arithmetic: orientation signs,
exact products and exact divisibility tests decide every case. There is no
tolerance, and no crossing is silently snapped to a grid position.

The diagrams show the geometry of the scenarios below. On the left, the two
segments properly cross at `P = (1, 1)`, a grid position. On the right, the
two diagonals of the unit square cross at `(0.5, 0.5)`, which is not a grid
position: the operation says so instead of approximating.

<!-- topodraw images/intersection_1.svg
axes
ticks 1
anchors
point A 0 0 0
point B 2 2 0
point C 2 0 0
point D 0 2 0
point P 1 1 0
vector A B (2, 2)
vector C D (-2, 2)
-->

![Crossing on a grid position](images/intersection_1.svg)

<!-- topodraw images/intersection_2.svg
axes
ticks 1
anchors
point A 0 0 0
point B 1 1 0
point C 0 1 0
point D 1 0 0
vector A B (1, 1)
vector C D (1, -1)
-->

![Crossing off the grid](images/intersection_2.svg)

## Scenario: a proper crossing on a grid position
- When I run `../bin/topoproof intersect 0 0 2 2 2 0 0 2`
- Then the output is `intersection point_intersection 1 1`
- And there is no error

## Scenario: a proper crossing off the grid
- When I run `../bin/topoproof intersect 0 0 1 1 0 1 1 0`
- Then the output is `intersection off_grid_crossing`
- And there is no error

## Scenario: collinear segments overlap
- When I run `../bin/topoproof intersect 0 0 4 0 2 0 6 0`
- Then the output is `intersection overlap 2 0 4 0`
- And there is no error

## Scenario: collinear segments touch at one point
- When I run `../bin/topoproof intersect 0 0 2 0 2 0 4 0`
- Then the output is `intersection point_intersection 2 0`
- And there is no error

## Scenario: collinear segments do not meet
- When I run `../bin/topoproof intersect 0 0 1 0 2 0 3 0`
- Then the output is `intersection no_intersection`
- And there is no error

## Scenario: an endpoint on the other segment
- When I run `../bin/topoproof intersect 0 0 2 0 1 0 1 1`
- Then the output is `intersection point_intersection 1 0`
- And there is no error

## Scenario: a degenerate point segment on another segment
- When I run `../bin/topoproof intersect 2 1 2 1 0 0 4 2`
- Then the output is `intersection point_intersection 2 1`
- And there is no error

## Scenario: two identical degenerate point segments
- When I run `../bin/topoproof intersect 1 1 1 1 1 1 1 1`
- Then the output is `intersection point_intersection 1 1`
- And there is no error

## Scenario: disjoint segments
- When I run `../bin/topoproof intersect 0 0 1 0 0 2 1 2`
- Then the output is `intersection no_intersection`
- And there is no error

## Scenario: the grid corners do not overflow
- When I run `../bin/topoproof intersect 0 -1073741823 0 1073741823 -1073741823 0 1073741823 0`
- Then the output is `intersection point_intersection 0 0`
- And there is no error

## Proved property

Exchanging the two segments does not change any result, and every reported
point or overlap boundary is a common grid position of both segments: both
properties are proved by SPARK over the whole grid domain, by the ghost
procedures `Lemma_Symmetry` and `Lemma_Membership`. All computations are
exact: orientation signs classify the configuration, and the crossing point
is accepted only when both exact coordinate quotients are integers in the
grid domain. No operation can overflow for any grid input: the degree-3
products of the crossing test are bounded by 1.6E28 and computed in a
128-bit intermediate domain.

## Scenario: the order of the arguments does not matter
- When I run `../bin/topoproof intersect 0 0 2 2 2 0 0 2`
- Then the output is `intersection point_intersection 1 1`
- When I run `../bin/topoproof intersect 2 0 0 2 0 0 2 2`
- Then the output is `intersection point_intersection 1 1`
- And there is no error

## Scenario: the overlap is returned identically in both orders
- When I run `../bin/topoproof intersect 0 0 4 0 2 0 6 0`
- Then the output is `intersection overlap 2 0 4 0`
- When I run `../bin/topoproof intersect 2 0 6 0 0 0 4 0`
- Then the output is `intersection overlap 2 0 4 0`
- And there is no error

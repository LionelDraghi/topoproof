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

## Contents

- [Scenario: a proper crossing on a grid position](#scenario-a-proper-crossing-on-a-grid-position)
- [Scenario: a proper crossing off the grid](#scenario-a-proper-crossing-off-the-grid)
- [Scenario: collinear segments overlap](#scenario-collinear-segments-overlap)
- [Scenario: collinear segments touch at one point](#scenario-collinear-segments-touch-at-one-point)
- [Scenario: collinear segments do not meet](#scenario-collinear-segments-do-not-meet)
- [Scenario: an endpoint on the other segment](#scenario-an-endpoint-on-the-other-segment)
- [Scenario: a degenerate point segment on another segment](#scenario-a-degenerate-point-segment-on-another-segment)
- [Scenario: two identical degenerate point segments](#scenario-two-identical-degenerate-point-segments)
- [Scenario: disjoint segments](#scenario-disjoint-segments)
- [Scenario: the grid corners do not overflow](#scenario-the-grid-corners-do-not-overflow)
- [Proved property](#proved-property)
- [Scenario: the order of the arguments does not matter](#scenario-the-order-of-the-arguments-does-not-matter)
- [Scenario: the overlap is returned identically in both orders](#scenario-the-overlap-is-returned-identically-in-both-orders)

## Scenario: a proper crossing on a grid position

![Crossing on a grid position](images/intersection_1.svg)

- When I successfully run `../bin/topoproof intersect 0 0 2 2 2 0 0 2`
- Then the output is `intersection point_intersection 1 1`

## Scenario: a proper crossing off the grid

![Crossing off the grid](images/intersection_2.svg)

- When I successfully run `../bin/topoproof intersect 0 0 1 1 0 1 1 0`
- Then the output is `intersection off_grid_crossing`

## Scenario: collinear segments overlap

The two segments lie on the X axis and share the part from `(2, 0)` to
`(4, 0)`.

<!-- topodraw images/intersection_3.svg
axes
ticks 2
anchors
point A 0 0 0
point B 4 0 0
point C 2 0 0
point D 6 0 0
vector A B (4, 0)
vector C D (4, 0)
-->

![Collinear segments overlapping](images/intersection_3.svg)

- When I successfully run `../bin/topoproof intersect 0 0 4 0 2 0 6 0`
- Then the output is `intersection overlap 2 0 4 0`

## Scenario: collinear segments touch at one point

The two segments meet exactly at the common position `(2, 0)`, an endpoint
of both.

<!-- topodraw images/intersection_4.svg
axes
ticks 2
anchors
point A 0 0 0
point B 2 0 0
point C 2 0 0
point D 4 0 0
vector A B (2, 0)
vector C D (2, 0)
-->

![Collinear segments touching](images/intersection_4.svg)

- When I successfully run `../bin/topoproof intersect 0 0 2 0 2 0 4 0`
- Then the output is `intersection point_intersection 2 0`

## Scenario: collinear segments do not meet

The two segments lie on the same line with a gap between `(1, 0)` and
`(2, 0)`.

<!-- topodraw images/intersection_5.svg
axes
ticks 1
anchors
point A 0 0 0
point B 1 0 0
point C 2 0 0
point D 3 0 0
vector A B (1, 0)
vector C D (1, 0)
-->

![Collinear segments with a gap](images/intersection_5.svg)

- When I successfully run `../bin/topoproof intersect 0 0 1 0 2 0 3 0`
- Then the output is `intersection no_intersection`

## Scenario: an endpoint on the other segment

The second segment starts at `(1, 0)`, a position inside the first
segment: a junction on the edge.

<!-- topodraw images/intersection_6.svg
axes
ticks 1
anchors
point A 0 0 0
point B 2 0 0
point C 1 0 0
point D 1 1 0
vector A B (2, 0)
vector C D (0, 1)
-->

![Endpoint on the other segment](images/intersection_6.svg)

- When I successfully run `../bin/topoproof intersect 0 0 2 0 1 0 1 1`
- Then the output is `intersection point_intersection 1 0`

## Scenario: a degenerate point segment on another segment

The first segment is the single position `(2, 1)`, which lies exactly on
the second segment.

<!-- topodraw images/intersection_7.svg
axes
ticks 2
anchors
point A 2 1 0
point B 0 0 0
point C 4 2 0
vector B C (4, 2)
-->

![Degenerate point segment on a segment](images/intersection_7.svg)

- When I successfully run `../bin/topoproof intersect 2 1 2 1 0 0 4 2`
- Then the output is `intersection point_intersection 2 1`

## Scenario: two identical degenerate point segments
- When I successfully run `../bin/topoproof intersect 1 1 1 1 1 1 1 1`
- Then the output is `intersection point_intersection 1 1`

## Scenario: disjoint segments
- When I successfully run `../bin/topoproof intersect 0 0 1 0 0 2 1 2`
- Then the output is `intersection no_intersection`

## Scenario: the grid corners do not overflow

The two segments are the two diagonals of the whole grid, crossing exactly
at the origin.

<!-- topodraw images/intersection_8.svg
axes
anchors
point A 0 -1073741823 0
point B 0 1073741823 0
point C -1073741823 0 0
point D 1073741823 0 0
vector A B S1
vector C D S2
-->

![Grid corner diagonals](images/intersection_8.svg)

- When I successfully run `../bin/topoproof intersect 0 -1073741823 0 1073741823 -1073741823 0 1073741823 0`
- Then the output is `intersection point_intersection 0 0`

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

The crossing of the first scenario, with the two segments exchanged.

![Crossing on a grid position](images/intersection_1.svg)

- When I successfully run `../bin/topoproof intersect 0 0 2 2 2 0 0 2`
- Then the output is `intersection point_intersection 1 1`
- When I successfully run `../bin/topoproof intersect 2 0 0 2 0 0 2 2`
- Then the output is `intersection point_intersection 1 1`

## Scenario: the overlap is returned identically in both orders

The overlap of the collinear scenario, with the two segments exchanged.

![Collinear segments overlapping](images/intersection_3.svg)

- When I successfully run `../bin/topoproof intersect 0 0 4 0 2 0 6 0`
- Then the output is `intersection overlap 2 0 4 0`
- When I successfully run `../bin/topoproof intersect 2 0 6 0 0 0 4 0`
- Then the output is `intersection overlap 2 0 4 0`

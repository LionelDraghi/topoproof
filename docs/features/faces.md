# Faces <!-- omit from toc -->

`Make_Face` builds a planar face from the chain accumulated by
`Add_Point`: the construction is the one of the loop classification, and
the resulting loop is classified again as a face boundary. The canonical
result of building the face `A=(0, 0) B=(5, 5) C=(0, 5) A` is
`face counter_clockwise`, written by the explicit `Put_Face`.

A face is a region of the plane bounded by one loop (see
`docs/terminology.md`). A valid face boundary is a valid loop whose
orientation is not degenerate: a closed two-edge backtrack is a valid
loop, but never a valid face boundary (DD-002, decision 3). The
orientation of a face is exactly the orientation of its boundary loop,
which a valid boundary guarantees to be counter-clockwise or clockwise.

![Face diagram](images/faces_1.svg)

## Contents <!-- omit from toc -->

- [Scenario: a counter-clockwise face](#scenario-a-counter-clockwise-face)
- [Scenario: a clockwise face](#scenario-a-clockwise-face)
- [Proved property](#proved-property)
- [Scenario: a degenerate boundary is rejected](#scenario-a-degenerate-boundary-is-rejected)

## Scenario: a counter-clockwise face

The script draws the triangle, accumulates the chain, and classifies
it as a face boundary.

- Given the file `face.topo`
  ```ada
  A    : constant Point_2D := (0, 0);
  B    : constant Point_2D := (5, 5);
  C    : constant Point_2D := (0, 5);
  K    : Face_Kind;

  Begin_Image (+"../docs/features/images/faces_1.svg");
  Draw_Axes;
  Draw_Point_2D (A, Blue);
  Draw_Point_2D (B, Blue);
  Draw_Point_2D (C, Blue);
  Draw_Edge (A, B, Blue);
  Draw_Edge (B, C, Blue);
  Draw_Edge (C, A, Blue);
  End_Image;

  Add_Point (A);
  Add_Point (B);
  Add_Point (C);
  Add_Point (A);

  Make_Face (K);

  Put_Face (K);
  ```
- When I successfully run `../bin/topocli run face.topo`
- Then the output is `face counter_clockwise`
- And the file `../docs/features/images/faces_1.svg` contains `#1f6feb`  
  (The `#1f6feb` value is the blue of `Color_Kind`: the check ensures
  the three vertices and edges of the boundary are drawn, closed on
  `A`.)

## Scenario: a clockwise face

![Clockwise square face](images/faces_2.svg)

- Given the file `clockwise_face.topo`
  ```ada
  A    : constant Point_2D := (0, 0);
  B    : constant Point_2D := (0, 5);
  C    : constant Point_2D := (5, 5);
  D    : constant Point_2D := (5, 0);
  K    : Face_Kind;

  Begin_Image (+"../docs/features/images/faces_2.svg");
  Draw_Axes;
  Draw_Point_2D (A, Blue);
  Draw_Point_2D (B, Blue);
  Draw_Point_2D (C, Blue);
  Draw_Point_2D (D, Blue);
  Draw_Edge (A, B, Blue);
  Draw_Edge (B, C, Blue);
  Draw_Edge (C, D, Blue);
  Draw_Edge (D, A, Blue);
  End_Image;

  Add_Point (A);
  Add_Point (B);
  Add_Point (C);
  Add_Point (D);
  Add_Point (A);

  Make_Face (K);

  Put_Face (K);
  ```
- When I successfully run `../bin/topocli run clockwise_face.topo`
- Then the output is `face clockwise`
- And the file `../docs/features/images/faces_2.svg` contains `#1f6feb`  
  (The `#1f6feb` value is the blue of `Color_Kind`: the check ensures
  the four vertices and edges of the boundary are drawn, traversed
  clockwise.)

## Proved property

A valid face boundary is a valid loop whose orientation is not
degenerate: `Classify_Face` is proved exhaustive on these three cases, and
`Make_Face` builds a face only from a loop classifying as a valid boundary,
so invalid faces cannot be obtained from the public API. `Face_Orientation`
is proved to return exactly the orientation of the boundary loop, and never
the degenerate orientation for a valid face: face orientation is
consistent with loop orientation by construction. Every operation of the
unit is proved free of run-time errors.

## Scenario: a degenerate boundary is rejected

The chain closes, so the loop is valid, but the path goes to `B` and comes
back along the same segment: the boundary orientation is degenerate, and a
closed backtrack is never a valid face boundary. The classification owns
no canonical line, only the rejection diagnostic.

- Given the file `degenerate_boundary.topo`
  ```ada
  A : constant Point_2D := (0, 0);
  B : constant Point_2D := (5, 5);
  K : Face_Kind;

  Add_Point (A);
  Add_Point (B);
  Add_Point (A);

  Make_Face (K);

  Put_Face (K);
  ```
- When I run `../bin/topocli run degenerate_boundary.topo`
- Then the error output is `error: degenerate face boundary`
- And the exit code is `1`

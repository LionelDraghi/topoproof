# Orientation <!-- omit from toc -->

`Orientation` classifies exactly the path formed by three 2D points,
the proved orientation of the kernel. The result is one of
`Orientation_Counter_Clockwise`, `Orientation_Clockwise` or
`Orientation_Collinear`, and the canonical result line is
`orientation counter_clockwise`, `orientation clockwise` or
`orientation collinear`, written by the explicit `Put_Orientation`.

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

## Contents <!-- omit from toc -->

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

- Given the file `ccw_path.topo`
  ```ada
  A    : constant Point_2D := (0, 0);
  B    : constant Point_2D := (1, 0);
  C    : constant Point_2D := (1, 1);
  K    : Orientation_Kind;

  Begin_Image (+"../docs/features/images/orientation_1.svg");
  Draw_Axes;
  Draw_Point_2D (A, Blue);
  Draw_Point_2D (B, Green);
  Draw_Point_2D (C, Red);
  Draw_Edge (A, B, Blue);
  Draw_Edge (B, C, Blue);
  End_Image;

  Orientation (A, B, C, K);

  Put_Orientation (K);
  ```
- When I successfully run `../bin/topocli run ccw_path.topo`
- Then the output is `orientation counter_clockwise`
- And the file `../docs/features/images/orientation_1.svg` contains `#cf222e`  
  (The `#cf222e` value is the red of `Color_Kind`: the check ensures
  the point `C`, the target of the turn, is drawn red.)

## Scenario: a clockwise path

The path turns right at `(1, 0)`.

![Clockwise turn](images/orientation_3.svg)

- Given the file `cw_path.topo`
  ```ada
  A    : constant Point_2D := (0, 0);
  B    : constant Point_2D := (1, 0);
  C    : constant Point_2D := (1, -1);
  K    : Orientation_Kind;

  Begin_Image (+"../docs/features/images/orientation_3.svg");
  Draw_Axes;
  Draw_Point_2D (A, Blue);
  Draw_Point_2D (B, Green);
  Draw_Point_2D (C, Red);
  Draw_Edge (A, B, Blue);
  Draw_Edge (B, C, Blue);
  End_Image;

  Orientation (A, B, C, K);

  Put_Orientation (K);
  ```
- When I successfully run `../bin/topocli run cw_path.topo`
- Then the output is `orientation clockwise`

## Scenario: three aligned points are collinear

The path stays on the diagonal line: no turn at all.

![Collinear path](images/orientation_4.svg)

- Given the file `collinear_path.topo`
  ```ada
  A    : constant Point_2D := (0, 0);
  B    : constant Point_2D := (2, 2);
  C    : constant Point_2D := (4, 4);
  K    : Orientation_Kind;

  Begin_Image (+"../docs/features/images/orientation_4.svg");
  Draw_Axes;
  Draw_Point_2D (A, Blue);
  Draw_Point_2D (B, Green);
  Draw_Point_2D (C, Red);
  Draw_Edge (A, B, Blue);
  Draw_Edge (B, C, Blue);
  End_Image;

  Orientation (A, B, C, K);

  Put_Orientation (K);
  ```
- When I successfully run `../bin/topocli run collinear_path.topo`
- Then the output is `orientation collinear`

## Scenario: two coincident points make a degenerate collinear path

`A` and `B` are the same position `(5, 7)`: the path degenerates before
reaching `C`.

![Degenerate path with coincident points](images/orientation_5.svg)

- Given the file `degenerate_path.topo`
  ```ada
  A    : constant Point_2D := (5, 7);
  B    : constant Point_2D := (5, 7);
  C    : constant Point_2D := (9, -3);
  K    : Orientation_Kind;

  Begin_Image (+"../docs/features/images/orientation_5.svg");
  Draw_Axes;
  Draw_Point_2D (A, Blue);
  Draw_Point_2D (C, Red);
  Draw_Edge (A, C, Blue);
  End_Image;

  Orientation (A, B, C, K);

  Put_Orientation (K);
  ```
- When I successfully run `../bin/topocli run degenerate_path.topo`
- Then the output is `orientation collinear`

## Scenario: the extreme corners of the grid do not overflow

The path visits three corners of the grid; the determinant of the extreme
coordinates is computed exactly in the `Determinant` domain.

![Path on the grid corners](images/orientation_6.svg)

- Given the file `corners_path.topo`
  ```ada
  A    : constant Point_2D := (1073741823, 0);
  B    : constant Point_2D := (0, 1073741823);
  C    : constant Point_2D := (-1073741823, -1073741823);
  K    : Orientation_Kind;

  Begin_Image (+"../docs/features/images/orientation_6.svg");
  Draw_Axes;
  Draw_Point_2D (A, Blue);
  Draw_Point_2D (B, Green);
  Draw_Point_2D (C, Red);
  Draw_Edge (A, B, Blue);
  Draw_Edge (B, C, Blue);
  End_Image;

  Orientation (A, B, C, K);

  Put_Orientation (K);
  ```
- When I successfully run `../bin/topocli run corners_path.topo`
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
point: one script classifies both paths, and both results are written.

![Counter-clockwise turn](images/orientation_1.svg)

- Given the file `cyclic_path.topo`
  ```ada
  A : constant Point_2D := (0, 0);
  B : constant Point_2D := (1, 0);
  C : constant Point_2D := (1, 1);
  K : Orientation_Kind;

  Orientation (A, B, C, K);
  Put_Orientation (K);

  Orientation (B, C, A, K);
  Put_Orientation (K);
  ```
- When I successfully run `../bin/topocli run cyclic_path.topo`
- Then the output is
  ```text
  orientation counter_clockwise
  orientation counter_clockwise
  ```

## Scenario: exchanging two points mirrors the orientation

The exchanged path of the first scenario.

![Clockwise turn](images/orientation_2.svg)

- Given the file `exchanged_path.topo`
  ```ada
  A    : constant Point_2D := (0, 0);
  B    : constant Point_2D := (1, 1);
  C    : constant Point_2D := (1, 0);
  K    : Orientation_Kind;

  Begin_Image (+"../docs/features/images/orientation_2.svg");
  Draw_Axes;
  Draw_Point_2D (A, Blue);
  Draw_Point_2D (B, Green);
  Draw_Point_2D (C, Red);
  Draw_Edge (A, B, Blue);
  Draw_Edge (B, C, Blue);
  End_Image;

  Orientation (A, B, C, K);

  Put_Orientation (K);
  ```
- When I successfully run `../bin/topocli run exchanged_path.topo`
- Then the output is `orientation clockwise`
- And the file `../docs/features/images/orientation_2.svg` contains `#cf222e`  
  (The `#cf222e` value is the red of `Color_Kind`: the check ensures
  the point `C`, the target of the mirrored turn, is drawn red.)

## Scenario: the orientation is invariant under translation

The same path as the first scenario, translated by `(3, 2)`: the turn
direction is unchanged. The script draws both paths in one image, the
translated one in red.

![A path and its translation](images/orientation_7.svg)

- Given the file `translated_path.topo`
  ```ada
  A : constant Point_2D := (0, 0);
  B : constant Point_2D := (1, 0);
  C : constant Point_2D := (1, 1);
  E : constant Point_2D := (3, 2);
  F : constant Point_2D := (4, 2);
  G : constant Point_2D := (4, 3);
  K : Orientation_Kind;

  Begin_Image (+"../docs/features/images/orientation_7.svg");
  Draw_Axes;
  Draw_Point_2D (A, Blue);
  Draw_Point_2D (B, Blue);
  Draw_Point_2D (C, Blue);
  Draw_Edge (A, B, Blue);
  Draw_Edge (B, C, Blue);
  Draw_Edge (E, F, Red);
  Draw_Edge (F, G, Red);
  End_Image;

  Orientation (A, B, C, K);
  Put_Orientation (K);

  Orientation (E, F, G, K);
  Put_Orientation (K);
  ```
- When I successfully run `../bin/topocli run translated_path.topo`
- Then the output is
  ```text
  orientation counter_clockwise
  orientation counter_clockwise
  ```
- And the file `../docs/features/images/orientation_7.svg` contains `#cf222e`  
  (The `#cf222e` value is the red of `Color_Kind`: the check ensures
  the translated path, drawn in red, is in the image.)

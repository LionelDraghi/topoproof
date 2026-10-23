# Displacement <!-- omit from toc -->

`Displacement` computes the exact vector between two points, the proved
`Displacement` of the kernel. The canonical result is `vector DX DY DZ`,
written by the explicit `Put_Vector`.

![Displacement diagram](images/displacement_1.svg)

## Contents <!-- omit from toc -->

- [Scenario: compute the displacement between two points](#scenario-compute-the-displacement-between-two-points)
- [Scenario: the result of a script run goes to the output file](#scenario-the-result-of-a-script-run-goes-to-the-output-file)

## Scenario: compute the displacement between two points

The script draws the two points and the displacement vector, then
writes the canonical result. The vector is the actual result of the
operation, drawn in red.

- Given the file `displacement.topo`
  ```ada
  A    : constant Point_3D := (-1, 2, -3);
  B    : constant Point_3D := (4, -5, 6);
  D    : Vector_3D;
  Name : VString := +"../docs/features/images/displacement_1.svg";

  Begin_Image (Name);
  Draw_Axes;
  Draw_Point (A, Blue);
  Draw_Point (B, Green);

  Displacement (A, B, D);

  Draw_Vector (A, D, Red);
  End_Image;

  Put_Vector (D);
  ```
- When I successfully run `../bin/topocli run displacement.topo`
- Then the output is `vector 5 -7 9`
- And the file `../docs/features/images/displacement_1.svg` contains `#cf222e`

![Displacement diagram](images/displacement_1.svg)

## Scenario: the result of a script run goes to the output file

With `--output FILE`, the canonical result of the run goes to the file,
and the standard output stays empty.

- Given the file `displacement_output.topo`
  ```ada
  A : constant Point_3D := (0, 0, 0);
  B : constant Point_3D := (-4, 5, -6);
  D : Vector_3D;

  Displacement (A, B, D);

  Put_Vector (D);
  ```
- When I successfully run `../bin/topocli run displacement_output.topo --output displacement-file.out`
- Then the output is
  ```text
  ```
- And the file `displacement-file.out` is `vector -4 5 -6`

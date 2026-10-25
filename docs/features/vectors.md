# Vectors <!-- omit from toc -->

The vector operations compute the exact products of two grid vectors, the
proved `Dot_Product` and `Cross_Product` of the kernel. A component of a
dot or cross result is exact, and never rounded: the results may leave the
grid amplitude, and the operations return them as they are. The scripting
layer carries them as 64-bit integers under the grid input contract, which
keeps every scriptable result in range; a value outside the contract is
rejected, never rounded.

## Contents <!-- omit from toc -->

- [Scenario: the dot product of two vectors](#scenario-the-dot-product-of-two-vectors)
- [Scenario: the cross product of two vectors](#scenario-the-cross-product-of-two-vectors)
- [Scenario: the cross product is orthogonal to both operands](#scenario-the-cross-product-is-orthogonal-to-both-operands)
- [Scenario: the exact results leave the grid amplitude](#scenario-the-exact-results-leave-the-grid-amplitude)
- [Scenario: a vector operand outside the grid input contract is rejected](#scenario-a-vector-operand-outside-the-grid-input-contract-is-rejected)

## Scenario: the dot product of two vectors

The dot product of the two vectors is the exact sum of the three exact
component products. The script draws the two operands, then writes the
canonical result.

![Vectors diagram](images/vectors_1.svg)

- Given the file `dot_product.topo`
  ```ada
  O : constant Point_3D := (0, 0, 0);
  A : constant Vector_3D := (3, -2, 3);
  B : constant Vector_3D := (1, 1, -1);
  D : Integer;

  Begin_Image (+"../docs/features/images/vectors_1.svg");
  Draw_Axes;
  Draw_Named_Point (O, +"O", Blue);
  Draw_Named_Vector (O, A, +"A", Blue);
  Draw_Named_Vector (O, B, +"B", Green);
  End_Image;

  Dot_Product (A, B, D);

  Put_Dot (D);
  ```

- When I successfully run `../bin/topocli run dot_product.topo`
- Then the output is `dot -2`

## Scenario: the cross product of two vectors

The cross product of the two vectors is the exact vector of the three
component product differences. It is orthogonal to both operands — proved
over the whole grid domain by the `Lemma_Cross_Orthogonality` ghost lemma
of the kernel, and observed below by an executable scenario — and its
orientation follows the right-hand rule. The script draws the two operands
and the cross vector, the actual result of the operation, drawn in red.

![Cross product diagram](images/cross_product_1.svg)

- Given the file `cross_product.topo`
  ```ada
  O : constant Point_3D := (0, 0, 0);
  A : constant Vector_3D := (3, -2, 3);
  B : constant Vector_3D := (1, 1, -1);
  V : Vector_3D;

  Cross_Product (A, B, V);

  Begin_Image (+"../docs/features/images/cross_product_1.svg");
  Draw_Axes;
  Draw_Named_Point (O, +"O", Blue);
  Draw_Named_Vector (O, A, +"A", Blue);
  Draw_Named_Vector (O, B, +"B", Green);
  Draw_Named_Vector (O, V, +"V", Red);
  End_Image;

  Put_Cross_Vector (V);
  ```

- When I successfully run `../bin/topocli run cross_product.topo`
- Then the output is `cross -1 6 5`
- And the file `../docs/features/images/cross_product_1.svg` contains `#cf222e`
  (The `#cf222e` value is the red of `Color_Kind`: the check ensures the
  cross vector, the actual result of the scenario, is drawn red.)

## Scenario: the cross product is orthogonal to both operands

The dot of the cross vector with either operand is exactly zero. The
kernel proves it over the whole grid domain; the scenario observes it on
one scriptable case, through the cross product followed by the two dots.

- Given the file `cross_orthogonality.topo`
  ```ada
  A  : constant Vector_3D := (2, 3, 4);
  B  : constant Vector_3D := (5, 6, 7);
  V  : Vector_3D;
  D1, D2 : Integer;

  Cross_Product (A, B, V);
  Dot_Product (V, A, D1);
  Dot_Product (V, B, D2);

  Put_Dot (D1);
  Put_Dot (D2);
  ```
- When I successfully run `../bin/topocli run cross_orthogonality.topo`
- Then the output is
  ```
  dot 0
  dot 0
  ```

## Scenario: the exact results leave the grid amplitude

The dot and cross results are exact, beyond the grid amplitude of the
coordinates and components: a scenario computes a cross product of
2500000000, far beyond the largest grid coordinate, without any overflow
and without any approximation. The result is far too large to be drawn to
scale next to its operands, so this scenario has no image: the exact
output line is the evidence.

- Given the file `cross_amplitude.topo`
  ```ada
  A : constant Vector_3D := (50000, 0, 0);
  B : constant Vector_3D := (0, 50000, 0);
  V : Vector_3D;

  Cross_Product (A, B, V);

  Put_Cross_Vector (V);
  ```
- When I successfully run `../bin/topocli run cross_amplitude.topo`
- Then the output is `cross 0 0 2500000000`

## Scenario: a vector operand outside the grid input contract is rejected

The scripting API reads vector operands in the grid input contract: each
component is a grid coordinate. This keeps every scriptable dot inside
the 64-bit script integers, the exact dot of two grid vectors being
bounded by about 3.5E18. A component beyond the contract is rejected,
never wrapped.

- Given the file `vector_contract.topo`
  ```ada
  A : constant Vector_3D := (2147483646, 0, 0);
  B : constant Vector_3D := (1, 0, 0);
  D : Integer;

  Dot_Product (A, B, D);
  ```
- When I run `../bin/topocli run vector_contract.topo`
- Then there is no output
- And the error output is `error: coordinate outside the grid`
- And the exit code is `1`

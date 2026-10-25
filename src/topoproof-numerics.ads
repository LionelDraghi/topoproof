-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

package TopoProof.Numerics
   with Pure, SPARK_Mode
is
   --  The grid is sized from the machine, not the other way around. The
   --  expression chain (coordinate -> difference -> product -> determinant
   --  -> cubic) must stay on native machine widths: 32-bit differences,
   --  64-bit products and determinants, 128-bit cubic products. With
   --  A the grid amplitude and L the largest coordinate (A = 2 * L), the
   --  binding constraint is the 64-bit determinant domain: 2 * A**2 must
   --  stay below 2**63, which gives L = 2**30 - 1. This is the largest
   --  grid position for which the whole chain runs on native registers:
   --  differences then exactly saturate 32 bits, and determinants exactly
   --  saturate 64 bits. Every domain below is derived from this bound.
   Grid_Last : constant := 2**30 - 1;

   --  One signed position on one grid axis.
   type Grid_Coordinate is range -Grid_Last .. Grid_Last;

   --  The grid amplitude: the largest possible difference between two
   --  coordinates.
   Grid_Amplitude : constant := Grid_Coordinate'Last - Grid_Coordinate'First;

   --  A component difference between two coordinates spans exactly the grid
   --  amplitude.
   type Vector_Component is range -Grid_Amplitude .. Grid_Amplitude;

   --  A coordinate plus a component difference: the extended domain covers
   --  any exact coordinate/difference sum.
   type Extended_Component is
      range -(Grid_Coordinate'Last + Grid_Amplitude) .. Grid_Coordinate'Last + Grid_Amplitude;

   --  True when an extended component value stays in the grid
   --  coordinate domain: the exact sums of the translations and the
   --  intermediate orientation values must be representable on the
   --  grid.
   function In_Range (V : Extended_Component) return Boolean is
     (V >= Extended_Component (Grid_Coordinate'First)
        and then V <= Extended_Component (Grid_Coordinate'Last));

   --  The amplitude of a product of two component differences: the square of
   --  the difference amplitude.
   Product_Amplitude : constant := Vector_Component'Last * Vector_Component'Last;

   --  Exact product of two component differences.
   type Product_Component is range -Product_Amplitude .. Product_Amplitude;

   --  The exact product of two component differences: each factor
   --  belongs to the Vector_Component domain, so the product is
   --  bounded by the difference amplitude square, exactly the
   --  Product_Component domain.
   function Component_Product
     (U, V : Vector_Component) return Product_Component is
     (Product_Component (U) * Product_Component (V));

   --  Exact difference of two products, so its amplitude is the sum of two
   --  product amplitudes.
   type Determinant is range -(2 * Product_Component'Last) .. 2 * Product_Component'Last;

   --  Product of a determinant and a component difference: the third degree
   --  of the expression chain, needed to test whether a crossing of two
   --  segments falls on a grid position.
   Cubic_Amplitude : constant := Determinant'Last * Grid_Amplitude;

   type Cubic_Product is range -Cubic_Amplitude .. Cubic_Amplitude;

   --  The amplitude of one cross-product component: the difference of two
   --  component products, the same degree as the orientation determinant.
   Cross_Amplitude : constant := 2 * Product_Amplitude;

   --  Exact component of a cross product.
   type Cross_Component is range -Cross_Amplitude .. Cross_Amplitude;

   --  The amplitude of an exact dot product of two component vectors: the
   --  sum of the three component products. About 1.4E19, just beyond the
   --  64-bit determinant domain, so on the same 128-bit machine width as
   --  the cubic products.
   Dot_Amplitude : constant := 3 * Product_Amplitude;

   --  Exact dot product of two component vectors.
   type Dot_Product is range -Dot_Amplitude .. Dot_Amplitude;

   --  The amplitude of one mixed term: a cross-product component times a
   --  component difference. The cross component has the determinant
   --  amplitude, so the mixed term sits at the determinant degree times
   --  the difference degree: exactly the cubic amplitude, the third
   --  degree of the expression chain, on the 128-bit machine width.
   Mixed_Amplitude : constant := Cross_Amplitude * Grid_Amplitude;

   --  Exact mixed term of a cross dot.
   type Mixed_Component is range -Mixed_Amplitude .. Mixed_Amplitude;

   --  The exact mixed term of a cross dot: one cross-product component
   --  times one component difference, each factor in its own domain, so
   --  the product is bounded exactly by the mixed amplitude.
   function Mixed_Product
     (C : Cross_Component; V : Vector_Component) return Mixed_Component is
     (Mixed_Component (C) * Mixed_Component (V));

   --  The amplitude of the cross dot of a cross vector and a grid
   --  vector: the sum of the three mixed terms, about 5.9E28, on the
   --  same 128-bit machine width as the cubic products.
   Cross_Dot_Amplitude : constant := 3 * Mixed_Amplitude;

   --  Exact cross dot of a cross vector and a component vector.
   type Cross_Dot is range -Cross_Dot_Amplitude .. Cross_Dot_Amplitude;

   --  The signed volume sum of a closed shell assembly, by the fan
   --  decomposition of every planar face: one four-point orientation
   --  determinant per fan triangle, so the amplitude is the Cross_Dot
   --  amplitude times the largest number of fan terms. An assembly has
   --  at most 2**15 faces and every face boundary at most 2**15 - 2
   --  fan terms, about 2**30 terms, hence about 2**126, on the same
   --  128-bit machine width as the cubic products.
   Volume_Amplitude : constant := 2**30 * Cross_Dot_Amplitude;

   --  Exact signed volume sum: six times the enclosed volume.
   type Volume is range -Volume_Amplitude .. Volume_Amplitude;

   --  The signed-area sum of a contour, by the shoelace formula: one
   --  determinant per vertex, so the amplitude is the determinant
   --  amplitude times the largest number of accumulated terms. A
   --  sequence length is a Natural discriminant, hence Natural'Last
   --  terms at most, about 2E9 * 9.2E18 = 2E28, that is about 2**94,
   --  on the same 128-bit machine width as the cubic products.
   Area_Sum_Amplitude : constant :=
     Natural'Last * (2 * Product_Amplitude);

   --  Exact shoelace sum of a discrete contour.
   type Area_Sum is range -Area_Sum_Amplitude .. Area_Sum_Amplitude;

end TopoProof.Numerics;

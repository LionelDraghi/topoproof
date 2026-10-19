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

   --  The amplitude of a product of two component differences: the square of
   --  the difference amplitude.
   Product_Amplitude : constant := Vector_Component'Last * Vector_Component'Last;

   --  Exact product of two component differences.
   type Product_Component is range -Product_Amplitude .. Product_Amplitude;

   --  Exact difference of two products, so its amplitude is the sum of two
   --  product amplitudes.
   type Determinant is range -(2 * Product_Component'Last) .. 2 * Product_Component'Last;

   --  Product of a determinant and a component difference: the third degree
   --  of the expression chain, needed to test whether a crossing of two
   --  segments falls on a grid position.
   Cubic_Amplitude : constant := Determinant'Last * Grid_Amplitude;

   type Cubic_Product is range -Cubic_Amplitude .. Cubic_Amplitude;

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

-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

package TopoProof.Numerics
   with Pure, SPARK_Mode
is
   --  One signed position on one grid axis. This is the only domain stated
   --  as a literal: every domain below is derived from it.
   type Grid_Coordinate is range -1_000_000_000 .. 1_000_000_000;

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
   --  product amplitudes. The compiler rejects the declaration if the range
   --  does not fit a supported machine type; here 8E18 < 2**63, so the
   --  determinant is representable on 64 bits.
   type Determinant is range -(2 * Product_Component'Last) .. 2 * Product_Component'Last;

end TopoProof.Numerics;

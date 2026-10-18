-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

package TopoProof.Numerics
   with Pure, SPARK_Mode
is
   type Grid_Coordinate is range -1_000_000_000 .. 1_000_000_000;

   type Vector_Component is range -2_000_000_000 .. 2_000_000_000;

   type Extended_Component is range -3_000_000_000 .. 3_000_000_000;

   --  Exact product of two component differences: the largest magnitude of
   --  each factor is 2E9, so the product is bounded by 2E9 * 2E9 = 4E18.
   type Product_Component is range -4_000_000_000_000_000_000 .. 4_000_000_000_000_000_000;

   --  Exact difference of two products: bounded by 2 * 4E18 = 8E18 < 2**63.
   type Determinant is range -8_000_000_000_000_000_000 .. 8_000_000_000_000_000_000;

end TopoProof.Numerics;

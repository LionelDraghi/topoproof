-- -----------------------------------------------------------------------------
-- TopoProof, provable geometry application
-- (https://github.com/LionelDraghi/topoproof)
-- SPDX-License-Identifier: Apache-2.0
-- SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

package TopoProof.Numerics
   with Pure, SPARK_Mode
is
   type Grid_Coordinate is range -1_000_000_000 .. 1_000_000_000;

   type Vector_Component is range -2_000_000_000 .. 2_000_000_000;

   type Extended_Component is range -3_000_000_000 .. 3_000_000_000;

end TopoProof.Numerics;

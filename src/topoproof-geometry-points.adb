-- -----------------------------------------------------------------------------
-- TopoProof, provable geometry application
-- (https://github.com/LionelDraghi/topoproof)
-- SPDX-License-Identifier: Apache-2.0
-- SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

package body TopoProof.Geometry.Points
   with SPARK_Mode
is

   function "=" (Left, Right : Point_3D) return Boolean
   is (Left.X = Right.X and then Left.Y = Right.Y and then Left.Z = Right.Z);

end TopoProof.Geometry.Points;

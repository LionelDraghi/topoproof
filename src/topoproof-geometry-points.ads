-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with TopoProof.Numerics;
use type TopoProof.Numerics.Grid_Coordinate;

package TopoProof.Geometry.Points
   with Pure, SPARK_Mode
is
   type Point_3D is record
      X : Numerics.Grid_Coordinate;
      Y : Numerics.Grid_Coordinate;
      Z : Numerics.Grid_Coordinate;
   end record;

   --  Two points are equal exactly when all three coordinates are equal.
   function "=" (Left, Right : Point_3D) return Boolean
   with Post => "="'Result = (Left.X = Right.X and then Left.Y = Right.Y and then Left.Z = Right.Z);

end TopoProof.Geometry.Points;

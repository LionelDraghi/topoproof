-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with TopoProof.Geometry.Points;
with TopoProof.Geometry.Vectors;
with TopoProof.Numerics;
use type TopoProof.Geometry.Points.Point_3D;
use type TopoProof.Numerics.Extended_Component;

package TopoProof.Geometry.Translations
   with Pure, SPARK_Mode
is
   function Translation_Is_Representable
      (P : Points.Point_3D; V : Vectors.Vector_3D) return Boolean;

   function Translate (P : Points.Point_3D; V : Vectors.Vector_3D) return Points.Point_3D
   with
      Pre  => Translation_Is_Representable (P, V),
      Post =>
         Numerics.Extended_Component (Translate'Result.X)
         = Numerics.Extended_Component (P.X) + Numerics.Extended_Component (V.DX)
         and then Numerics.Extended_Component (Translate'Result.Y)
                  = Numerics.Extended_Component (P.Y) + Numerics.Extended_Component (V.DY)
         and then Numerics.Extended_Component (Translate'Result.Z)
                  = Numerics.Extended_Component (P.Z) + Numerics.Extended_Component (V.DZ);

   --  Translation by the exact displacement from A to B always returns B,
   --  and is always representable, for any two points of the grid.
   procedure Lemma_Translate_Displacement (From, To_Point : Points.Point_3D)
   with Ghost, Post => Translate (From, Vectors.Displacement (From, To_Point)) = To_Point;

end TopoProof.Geometry.Translations;

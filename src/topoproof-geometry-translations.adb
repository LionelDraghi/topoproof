-- -----------------------------------------------------------------------------
-- TopoProof, provable geometry application
-- (https://github.com/LionelDraghi/topoproof)
-- SPDX-License-Identifier: Apache-2.0
-- SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

package body TopoProof.Geometry.Translations
   with SPARK_Mode
is

   function In_Range (V : Numerics.Extended_Component) return Boolean
   is (V >= Numerics.Extended_Component (Numerics.Grid_Coordinate'First)
       and then V <= Numerics.Extended_Component (Numerics.Grid_Coordinate'Last));

   function Translation_Is_Representable (P : Points.Point_3D; V : Vectors.Vector_3D) return Boolean
   is (In_Range (Numerics.Extended_Component (P.X) + Numerics.Extended_Component (V.DX))
       and then In_Range (Numerics.Extended_Component (P.Y) + Numerics.Extended_Component (V.DY))
       and then In_Range (Numerics.Extended_Component (P.Z) + Numerics.Extended_Component (V.DZ)));

   function Translate (P : Points.Point_3D; V : Vectors.Vector_3D) return Points.Point_3D is

   begin
      return
         (X =>
             Numerics.Grid_Coordinate
                (Numerics.Extended_Component (P.X) + Numerics.Extended_Component (V.DX)),
          Y =>
             Numerics.Grid_Coordinate
                (Numerics.Extended_Component (P.Y) + Numerics.Extended_Component (V.DY)),
          Z =>
             Numerics.Grid_Coordinate
                (Numerics.Extended_Component (P.Z) + Numerics.Extended_Component (V.DZ)));
   end Translate;

   --  The postcondition and the precondition of Translate, used in the
   --  postcondition, are proved by GNATprove over the whole grid domain.
   procedure Lemma_Translate_Displacement (From, To_Point : Points.Point_3D) is

   begin
      null;
   end Lemma_Translate_Displacement;

end TopoProof.Geometry.Translations;

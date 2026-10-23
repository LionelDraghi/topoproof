-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with TopoScript_API.Conversions;
with TopoScript_API.Session;

with TopoProof.Geometry.Points;
with TopoProof.Geometry.Translations;
with TopoProof.Geometry.Vectors;

package body TopoScript_API.Geometry is

   use TopoProof.Geometry.Points;
   use TopoProof.Geometry.Translations;
   use TopoProof.Geometry.Vectors;

   procedure Translate_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      P : TopoProof.Geometry.Points.Point_3D;
      V : TopoProof.Geometry.Vectors.Vector_3D;
   begin
      if not Conversions.Read_Point_3D (Data, 1, P)
        or else not Conversions.Read_Vector_3D (Data, 4, V)
      then
         Session.Record_Failure ("error: coordinate outside the grid");
         return;
      end if;

      if Translation_Is_Representable (P, V) then
         declare
            Q : constant Point_3D := Translate (P, V);
         begin
            Conversions.Write_Point_3D (Data, 7, Q);
         end;

      else
         Session.Record_Failure ("error: translation is not representable");
      end if;
   end Translate_Native;

end TopoScript_API.Geometry;

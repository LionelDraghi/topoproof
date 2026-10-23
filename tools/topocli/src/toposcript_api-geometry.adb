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
with TopoProof.Numerics;

package body TopoScript_API.Geometry is

   use TopoProof.Geometry.Points;
   use TopoProof.Geometry.Translations;
   use TopoProof.Geometry.Vectors;
   use TopoProof.Numerics;

   procedure Translate_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      PX, PY, PZ    : Long_Long_Integer;
      VDX, VDY, VDZ : Long_Long_Integer;
   begin
      PX  := Conversions.To_Long (Data (1));
      PY  := Conversions.To_Long (Data (2));
      PZ  := Conversions.To_Long (Data (3));
      VDX := Conversions.To_Long (Data (4));
      VDY := Conversions.To_Long (Data (5));
      VDZ := Conversions.To_Long (Data (6));
      if not Conversions.Grid_In_Range (PX)
        or else not Conversions.Grid_In_Range (PY)
        or else not Conversions.Grid_In_Range (PZ)
        or else not Conversions.Grid_In_Range (VDX)
        or else not Conversions.Grid_In_Range (VDY)
        or else not Conversions.Grid_In_Range (VDZ)
      then
         Session.Record_Failure ("error: coordinate outside the grid");
         return;
      end if;

      declare
         P : constant Point_3D :=
           (X => Grid_Coordinate (PX),
            Y => Grid_Coordinate (PY),
            Z => Grid_Coordinate (PZ));
         V : constant Vector_3D :=
           (DX => Vector_Component (VDX),
            DY => Vector_Component (VDY),
            DZ => Vector_Component (VDZ));
      begin
         if Translation_Is_Representable (P, V) then
            declare
               Q : constant Point_3D := Translate (P, V);
            begin
               Data (7) := Conversions.Grid_To_HAC (Q.X);
               Data (8) := Conversions.Grid_To_HAC (Q.Y);
               Data (9) := Conversions.Grid_To_HAC (Q.Z);
            end;

         else
            Session.Record_Failure
              ("error: translation is not representable");
         end if;
      end;
   end Translate_Native;

end TopoScript_API.Geometry;

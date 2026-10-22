-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with Ada.Strings.Unbounded;           use Ada.Strings.Unbounded;

with HAC_Sys.Interfacing;             use HAC_Sys.Interfacing;

with TopoProof.Geometry.Points;      use TopoProof.Geometry.Points;
with TopoProof.Geometry.Translations;
use TopoProof.Geometry.Translations;
with TopoProof.Geometry.Vectors;      use TopoProof.Geometry.Vectors;
with TopoProof.Numerics;              use TopoProof.Numerics;

package body TopoScript_API is

   Failure : Unbounded_String;

   function To_Grid is new To_Native_Any_Integer (Grid_Coordinate);

   function To_Component is new To_Native_Any_Integer (Vector_Component);

   function Grid_To_HAC is new To_HAC_Any_Integer (Grid_Coordinate);

   --  Native side of Translate: the script passes a point and a vector
   --  as in out integers; the callback runs the proved Translate and
   --  writes the translated point back into the same elements.
   procedure Translate_Native (Data : in out HAC_Element_Array) is
      P : constant Point_3D :=
        (X => To_Grid (Data (1)),
         Y => To_Grid (Data (2)),
         Z => To_Grid (Data (3)));
      V : constant Vector_3D :=
        (DX => To_Component (Data (4)),
         DY => To_Component (Data (5)),
         DZ => To_Component (Data (6)));
   begin
      if Translation_Is_Representable (P, V) then
         declare
            Q : constant Point_3D := Translate (P, V);
         begin
            Data (1) := Grid_To_HAC (Q.X);
            Data (2) := Grid_To_HAC (Q.Y);
            Data (3) := Grid_To_HAC (Q.Z);
         end;

      else
         Failure :=
           To_Unbounded_String ("error: translation is not representable");
      end if;
   end Translate_Native;

   procedure Register_All (BD : HAC_Sys.Builder.Build_Data) is
   begin
      Register (BD, Translate_Native'Access, "Translate");
   end Register_All;

   function Last_Failure return String is
   begin
      return To_String (Failure);
   end Last_Failure;

end TopoScript_API;

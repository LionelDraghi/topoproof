-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with TopoDiagnostics;
with TopoScript_API.Conversions;
with TopoScript_API.Session;

with TopoProof.Geometry.Points;
with TopoProof.Geometry.Translations;
with TopoProof.Geometry.Vectors;

package body TopoScript_API.Geometry is

   use TopoProof.Geometry.Intersections;
   use TopoProof.Geometry.Orientations;
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
         Session.Record_Failure (TopoDiagnostics.Outside_Grid_Diagnostic);
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

   procedure Displacement_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      --  Element layout: A at 1..3, B at 4..6, Result at 7..9.
      A, B : TopoProof.Geometry.Points.Point_3D;

   begin
      if not Conversions.Read_Point_3D (Data, 1, A)
        or else not Conversions.Read_Point_3D (Data, 4, B)
      then
         Session.Record_Failure (TopoDiagnostics.Outside_Grid_Diagnostic);
         return;
      end if;

      Conversions.Write_Vector_3D (Data, 7, Displacement (A, B));
   end Displacement_Native;

   procedure Dot_Product_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      --  Element layout: A at 1..3, B at 4..6, Result at 7.
      A, B : TopoProof.Geometry.Vectors.Vector_3D;

   begin
      if not Conversions.Read_Vector_3D (Data, 1, A)
        or else not Conversions.Read_Vector_3D (Data, 4, B)
      then
         Session.Record_Failure (TopoDiagnostics.Outside_Grid_Diagnostic);
         return;
      end if;

      declare
         D : constant TopoProof.Numerics.Dot_Product :=
           TopoProof.Geometry.Vectors.Dot_Product (A, B);
      begin
         if Conversions.Dot_In_HAC_Range (D) then
            Data (7) := Conversions.Dot_To_HAC (D);
         else
            Session.Record_Failure
              ("error: dot product outside the 64-bit scripting range");
         end if;
      end;
   end Dot_Product_Native;

   procedure Cross_Product_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      --  Element layout: A at 1..3, B at 4..6, Result at 7..9.
      A, B : TopoProof.Geometry.Vectors.Vector_3D;

   begin
      if not Conversions.Read_Vector_3D (Data, 1, A)
        or else not Conversions.Read_Vector_3D (Data, 4, B)
      then
         Session.Record_Failure (TopoDiagnostics.Outside_Grid_Diagnostic);
         return;
      end if;

      Conversions.Write_Cross_Vector_3D
        (Data, 7, TopoProof.Geometry.Vectors.Cross_Product (A, B));
   end Cross_Product_Native;

   procedure Make_Plane_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      --  Element layout: A at 1..3, B at 4..6, C at 7..9, Kind at 10.
      A, B, C : TopoProof.Geometry.Points.Point_3D;
      Pl      : TopoProof.Geometry.Planes.Plane;
      K       : TopoProof.Geometry.Planes.Plane_Kind;

   begin
      if not Conversions.Read_Point_3D (Data, 1, A)
        or else not Conversions.Read_Point_3D (Data, 4, B)
        or else not Conversions.Read_Point_3D (Data, 7, C)
      then
         Session.Record_Failure (TopoDiagnostics.Outside_Grid_Diagnostic);
         return;
      end if;

      TopoProof.Geometry.Planes.Make_Plane (A, B, C, Pl, K);
      Data (10) := Plane_Kind_To_HAC (K);
   end Make_Plane_Native;

   procedure Plane_Side_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      --  Element layout: P at 1..3, A at 4..6, B at 7..9, C at 10..12,
      --  Kind at 13.
      P, A, B, C : TopoProof.Geometry.Points.Point_3D;

   begin
      if not Conversions.Read_Point_3D (Data, 1, P)
        or else not Conversions.Read_Point_3D (Data, 4, A)
        or else not Conversions.Read_Point_3D (Data, 7, B)
        or else not Conversions.Read_Point_3D (Data, 10, C)
      then
         Session.Record_Failure (TopoDiagnostics.Outside_Grid_Diagnostic);
         return;
      end if;

      Data (13) := Plane_Side_To_HAC
        (TopoProof.Geometry.Planes.Plane_Side ((A, B, C), P));
   end Plane_Side_Native;

   procedure Equal_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      --  Element layout: A at 1..3, B at 4..6, Result at 7.
      A, B : TopoProof.Geometry.Points.Point_3D;

   begin
      if not Conversions.Read_Point_3D (Data, 1, A)
        or else not Conversions.Read_Point_3D (Data, 4, B)
      then
         Session.Record_Failure (TopoDiagnostics.Outside_Grid_Diagnostic);
         return;
      end if;

      Data (7) := Equal_To_HAC
        ((if A = B then Equal_True else Equal_False));
   end Equal_Native;

   procedure Orientation_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      --  Element layout: A at 1..2, B at 3..4, C at 5..6, Result at 7.
      A, B, C : TopoProof.Geometry.Points.Point_2D;

   begin
      if not Conversions.Read_Point_2D (Data, 1, A)
        or else not Conversions.Read_Point_2D (Data, 3, B)
        or else not Conversions.Read_Point_2D (Data, 5, C)
      then
         Session.Record_Failure (TopoDiagnostics.Outside_Grid_Diagnostic);
         return;
      end if;

      Data (7) := Orientation_To_HAC (Orientation (A, B, C));
   end Orientation_Native;

   procedure Intersection_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      --  Element layout: A at 1..2, B at 3..4, C at 5..6, D at 7..8,
      --  Result at 9..13: the kind, then four coordinates.
      A, B, C, D : TopoProof.Geometry.Points.Point_2D;

   begin
      if not Conversions.Read_Point_2D (Data, 1, A)
        or else not Conversions.Read_Point_2D (Data, 3, B)
        or else not Conversions.Read_Point_2D (Data, 5, C)
        or else not Conversions.Read_Point_2D (Data, 7, D)
      then
         Session.Record_Failure (TopoDiagnostics.Outside_Grid_Diagnostic);
         return;
      end if;

      declare
         R : constant Intersection_Result :=
           Intersection ((A, B), (C, D));

      begin
         Data (9)  := Intersection_To_HAC (R.Kind);
         Data (10) := Conversions.Grid_To_HAC (0);
         Data (11) := Conversions.Grid_To_HAC (0);
         Data (12) := Conversions.Grid_To_HAC (0);
         Data (13) := Conversions.Grid_To_HAC (0);
         case R.Kind is
            when Point_Intersection =>
               Data (10) := Conversions.Grid_To_HAC (R.Point.X);
               Data (11) := Conversions.Grid_To_HAC (R.Point.Y);
            when Overlap =>
               Data (10) := Conversions.Grid_To_HAC (R.Overlap.From_Point.X);
               Data (11) := Conversions.Grid_To_HAC (R.Overlap.From_Point.Y);
               Data (12) := Conversions.Grid_To_HAC (R.Overlap.To_Point.X);
               Data (13) := Conversions.Grid_To_HAC (R.Overlap.To_Point.Y);
            when No_Intersection | Off_Grid_Crossing =>
               --  No position is reported with these kinds.
               null;
         end case;
      end;
   end Intersection_Native;

end TopoScript_API.Geometry;

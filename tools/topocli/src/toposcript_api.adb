-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;           use Ada.Strings.Unbounded;
with Ada.Text_IO;                     use Ada.Text_IO;

with HAC_Sys.Interfacing;             use HAC_Sys.Interfacing;

with TopoProof.Geometry.Points;      use TopoProof.Geometry.Points;
with TopoProof.Geometry.Translations;
use TopoProof.Geometry.Translations;
with TopoProof.Geometry.Vectors;      use TopoProof.Geometry.Vectors;
with TopoProof.Numerics;              use TopoProof.Numerics;

with Topodraw;                        use Topodraw;

package body TopoScript_API is

   Failure : Unbounded_String;

   --  The first rejected operation owns the diagnostic: a script runs
   --  on after a rejected operation, and the later ones must not mask
   --  the actual cause with their own rejection.
   procedure Record_Failure (Message : String) is
   begin
      if Length (Failure) = 0 then
         Failure := To_Unbounded_String (Message);
      end if;
   end Record_Failure;

   --  HAC integers are 64-bit while the grid coordinates are not: the
   --  script values are read on the widest native integer first, then
   --  checked against the grid domain, because an exception raised
   --  inside the HAC virtual machine would not propagate to the
   --  caller.
   function To_Long is new To_Native_Any_Integer (Long_Long_Integer);

   function Grid_To_HAC is new To_HAC_Any_Integer (Grid_Coordinate);

   function Grid_In_Range (Value : Long_Long_Integer) return Boolean is
   begin
      return Value >= Long_Long_Integer (Grid_Coordinate'First)
        and then Value <= Long_Long_Integer (Grid_Coordinate'Last);
   end Grid_In_Range;

   package Grid_IO is new Ada.Text_IO.Integer_IO (Grid_Coordinate);

   --  Native side of Translate: the script passes the point and the
   --  vector as records; the callback runs the proved Translate and
   --  writes the translated point into the out parameter.
   procedure Translate_Native (Data : in out HAC_Element_Array) is
      PX, PY, PZ   : Long_Long_Integer;
      VDX, VDY, VDZ : Long_Long_Integer;
   begin
      PX := To_Long (Data (1));
      PY := To_Long (Data (2));
      PZ := To_Long (Data (3));
      VDX := To_Long (Data (4));
      VDY := To_Long (Data (5));
      VDZ := To_Long (Data (6));
      if not Grid_In_Range (PX)
        or else not Grid_In_Range (PY)
        or else not Grid_In_Range (PZ)
        or else not Grid_In_Range (VDX)
        or else not Grid_In_Range (VDY)
        or else not Grid_In_Range (VDZ)
      then
         Record_Failure ("error: coordinate outside the grid");
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
               Data (7) := Grid_To_HAC (Q.X);
               Data (8) := Grid_To_HAC (Q.Y);
               Data (9) := Grid_To_HAC (Q.Z);
            end;

         else
            Record_Failure ("error: translation is not representable");
         end if;
      end;
   end Translate_Native;

   --  Native side of Put: writes the canonical representation of the
   --  point on standard output, the same one as the topocli client.
   procedure Put_Native (Data : in out HAC_Element_Array) is
      PX, PY, PZ : Long_Long_Integer;
   begin
      PX := To_Long (Data (1));
      PY := To_Long (Data (2));
      PZ := To_Long (Data (3));
      if not Grid_In_Range (PX)
        or else not Grid_In_Range (PY)
        or else not Grid_In_Range (PZ)
      then
         Record_Failure ("error: coordinate outside the grid");
         return;
      end if;

      declare
         P : constant Point_3D :=
           (X => Grid_Coordinate (PX),
            Y => Grid_Coordinate (PY),
            Z => Grid_Coordinate (PZ));
      begin
         Put ("point ");
         Grid_IO.Put (P.X, Width => 0);
         Put (" ");
         Grid_IO.Put (P.Y, Width => 0);
         Put (" ");
         Grid_IO.Put (P.Z, Width => 0);
         New_Line;
      end;
   end Put_Native;

   --  Diagnostic drawing (development plan, Milestone 6, Increment 4):
   --  the script builds one scene through the drawing API, and
   --  End_Image renders it as an SVG file through the topodraw
   --  renderer. The image is a generated file: it never pollutes the
   --  canonical standard output.

   Image_Open   : Boolean := False;
   Image_Name   : Unbounded_String;
   The_Scene    : Topodraw.Scene;
   Anchor_Count : Natural := 0;

   function To_Color is new To_Native_Any_Enum (Color_Kind);

   function Hex_Of (Color : Color_Kind) return String is
   begin
      case Color is
         when Blue =>
            return "#1f6feb";
         when Green =>
            return "#1a7f37";
         when Red =>
            return "#cf222e";
      end case;
   end Hex_Of;

   --  Points are identified by position: the first one drawn at a
   --  position keeps its name, so a vector can anchor on a point the
   --  script has already drawn, and the coincident points of the
   --  renderer stack up instead of duplicating.
   function New_Name return Unbounded_String is
   begin
      Anchor_Count := Anchor_Count + 1;
      return To_Unbounded_String
        ("A" & Ada.Strings.Fixed.Trim (Anchor_Count'Image,
                                      Ada.Strings.Both));
   end New_Name;

   procedure Color_Point (X, Y, Z : Integer; Color : Unbounded_String) is
      Found : Boolean := False;
   begin
      for Pt of The_Scene.Points loop
         if Pt.X = X and then Pt.Y = Y and then Pt.Z = Z then
            Pt.Color := Color;
            Found    := True;
         end if;
      end loop;
      if not Found then
         The_Scene.Points.Append
           (Point_Rec'
              (Name  => New_Name,
               X     => X,
               Y     => Y,
               Z     => Z,
               Color => Color));
      end if;
   end Color_Point;

   function Anchor_Name (X, Y, Z : Integer) return Unbounded_String is
   begin
      for Pt of The_Scene.Points loop
         if Pt.X = X and then Pt.Y = Y and then Pt.Z = Z then
            return Pt.Name;
         end if;
      end loop;
      declare
         Name : constant Unbounded_String := New_Name;
      begin
         The_Scene.Points.Append
           (Point_Rec'
              (Name  => Name,
               X     => X,
               Y     => Y,
               Z     => Z,
               Color => Null_Unbounded_String));
         return Name;
      end;
   end Anchor_Name;

   procedure Begin_Image_Native (Data : in out HAC_Element_Array) is
   begin
      Image_Name   :=
        To_Unbounded_String
          (String'(HAC_Sys.Interfacing.To_Native (Data (1))));
      Image_Open   := True;
      The_Scene    := (others => <>);
      Anchor_Count := 0;
   end Begin_Image_Native;

   procedure Draw_Axes_Native (Data : in out HAC_Element_Array) is
      pragma Unreferenced (Data);
   begin
      if not Image_Open then
         Record_Failure ("error: no open image");
         return;
      end if;
      The_Scene.Draw_Axes := True;
   end Draw_Axes_Native;

   --  Native side of Draw_Point: the point colors the scene, and the
   --  script may call it before or after any operation.
   procedure Draw_Point_Native (Data : in out HAC_Element_Array) is
      PX, PY, PZ : Long_Long_Integer;
   begin
      if not Image_Open then
         Record_Failure ("error: no open image");
         return;
      end if;
      PX := To_Long (Data (1));
      PY := To_Long (Data (2));
      PZ := To_Long (Data (3));
      if not Grid_In_Range (PX)
        or else not Grid_In_Range (PY)
        or else not Grid_In_Range (PZ)
      then
         Record_Failure ("error: coordinate outside the grid");
         return;
      end if;

      Color_Point
        (Integer (PX), Integer (PY), Integer (PZ),
         To_Unbounded_String (Hex_Of (To_Color (Data (4)))));
   end Draw_Point_Native;

   --  Native side of Draw_Vector: the arrow runs from the origin to
   --  the tip; both anchor on points, drawn or reused, colored with
   --  the vector color.
   procedure Draw_Vector_Native (Data : in out HAC_Element_Array) is
      OX, OY, OZ    : Long_Long_Integer;
      VDX, VDY, VDZ : Long_Long_Integer;
   begin
      if not Image_Open then
         Record_Failure ("error: no open image");
         return;
      end if;
      OX  := To_Long (Data (1));
      OY  := To_Long (Data (2));
      OZ  := To_Long (Data (3));
      VDX := To_Long (Data (4));
      VDY := To_Long (Data (5));
      VDZ := To_Long (Data (6));
      if not Grid_In_Range (OX)
        or else not Grid_In_Range (OY)
        or else not Grid_In_Range (OZ)
        or else not Grid_In_Range (OX + VDX)
        or else not Grid_In_Range (OY + VDY)
        or else not Grid_In_Range (OZ + VDZ)
      then
         Record_Failure ("error: vector outside the grid");
         return;
      end if;

      declare
         From_Name, To_Name : Unbounded_String;
      begin
         --  The anchor points stay plain: only the vector carries the
         --  color, unless the script has drawn the same position.
         From_Name :=
           Anchor_Name (Integer (OX), Integer (OY), Integer (OZ));
         To_Name :=
           Anchor_Name (Integer (OX + VDX), Integer (OY + VDY),
                        Integer (OZ + VDZ));
         The_Scene.Vectors.Append
           (Vector_Rec'
              (From_Name => From_Name,
               To_Name   => To_Name,
               Label     => Null_Unbounded_String,
               Color     =>
                 To_Unbounded_String (Hex_Of (To_Color (Data (7))))));
      end;
   end Draw_Vector_Native;

   procedure End_Image_Native (Data : in out HAC_Element_Array) is
      pragma Unreferenced (Data);
   begin
      if not Image_Open then
         Record_Failure ("error: no open image");
         return;
      end if;
      Image_Open := False;

      declare
         F : File_Type;
      begin
         Create (F, Out_File, To_String (Image_Name));
         Put (F, Render (The_Scene));
         Close (F);
      exception
         when Scene_Error =>
            Record_Failure ("error: invalid image scene");
            if Is_Open (F) then
               Close (F);
            end if;
         when Name_Error | Use_Error =>
            Record_Failure ("error: cannot write the image");
            if Is_Open (F) then
               Close (F);
            end if;
      end;
   end End_Image_Native;

   procedure Register_All (BD : HAC_Sys.Builder.Build_Data) is
   begin
      Register (BD, Translate_Native'Access, "Translate");
      Register (BD, Put_Native'Access, "Put");
      Register (BD, Begin_Image_Native'Access, "Begin_Image");
      Register (BD, Draw_Axes_Native'Access, "Draw_Axes");
      Register (BD, Draw_Point_Native'Access, "Draw_Point");
      Register (BD, Draw_Vector_Native'Access, "Draw_Vector");
      Register (BD, End_Image_Native'Access, "End_Image");
   end Register_All;

   function Last_Failure return String is
   begin
      return To_String (Failure);
   end Last_Failure;

end TopoScript_API;

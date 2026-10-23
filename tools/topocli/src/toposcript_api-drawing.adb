-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
use Ada.Strings.Unbounded;
with Ada.Text_IO;

with TopoScript_API.Conversions;
with TopoScript_API.Session;

with Topodraw;
use Topodraw;

package body TopoScript_API.Drawing is

   function To_Color is new HAC_Sys.Interfacing.To_Native_Any_Enum
     (Color_Kind);

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
      Session.Current_Session.Anchor_Count :=
        Session.Current_Session.Anchor_Count + 1;
      return To_Unbounded_String
        ("A" & Ada.Strings.Fixed.Trim
             (Session.Current_Session.Anchor_Count'Image,
              Ada.Strings.Both));
   end New_Name;

   procedure Color_Point (X, Y, Z : Integer; Color : Unbounded_String) is
      Found : Boolean := False;
   begin
      for Pt of Session.Current_Session.The_Scene.Points loop
         if Pt.X = X and then Pt.Y = Y and then Pt.Z = Z then
            Pt.Color := Color;
            Found    := True;
         end if;
      end loop;
      if not Found then
         Session.Current_Session.The_Scene.Points.Append
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
      for Pt of Session.Current_Session.The_Scene.Points loop
         if Pt.X = X and then Pt.Y = Y and then Pt.Z = Z then
            return Pt.Name;
         end if;
      end loop;
      declare
         Name : constant Unbounded_String := New_Name;
      begin
         Session.Current_Session.The_Scene.Points.Append
           (Point_Rec'
              (Name  => Name,
               X     => X,
               Y     => Y,
               Z     => Z,
               Color => Null_Unbounded_String));
         return Name;
      end;
   end Anchor_Name;

   procedure Begin_Image_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
   begin
      Session.Current_Session.Image_Name :=
        To_Unbounded_String
          (String'(HAC_Sys.Interfacing.To_Native (Data (1))));
      Session.Current_Session.Image_Open := True;
      Session.Current_Session.The_Scene  := (others => <>);
      Session.Current_Session.Anchor_Count := 0;
   end Begin_Image_Native;

   procedure Draw_Axes_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      pragma Unreferenced (Data);
   begin
      if not Session.Current_Session.Image_Open then
         Session.Record_Failure ("error: no open image");
         return;
      end if;
      --  The same axes configuration as the client scenes: automatic
      --  tick marks, and the dashed coordinate paths of every point.
      Session.Current_Session.The_Scene.Draw_Axes := True;
      Session.Current_Session.The_Scene.Tick_Step := 0;
      Session.Current_Session.The_Scene.Anchors   := True;
   end Draw_Axes_Native;

   procedure Draw_Point_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      PX, PY, PZ : Long_Long_Integer;
   begin
      if not Session.Current_Session.Image_Open then
         Session.Record_Failure ("error: no open image");
         return;
      end if;
      PX := Conversions.To_Long (Data (1));
      PY := Conversions.To_Long (Data (2));
      PZ := Conversions.To_Long (Data (3));
      if not Conversions.Grid_In_Range (PX)
        or else not Conversions.Grid_In_Range (PY)
        or else not Conversions.Grid_In_Range (PZ)
      then
         Session.Record_Failure ("error: coordinate outside the grid");
         return;
      end if;

      Color_Point
        (Integer (PX), Integer (PY), Integer (PZ),
         To_Unbounded_String (Hex_Of (To_Color (Data (4)))));
   end Draw_Point_Native;

   procedure Draw_Vector_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      OX, OY, OZ    : Long_Long_Integer;
      VDX, VDY, VDZ : Long_Long_Integer;
   begin
      if not Session.Current_Session.Image_Open then
         Session.Record_Failure ("error: no open image");
         return;
      end if;
      OX  := Conversions.To_Long (Data (1));
      OY  := Conversions.To_Long (Data (2));
      OZ  := Conversions.To_Long (Data (3));
      VDX := Conversions.To_Long (Data (4));
      VDY := Conversions.To_Long (Data (5));
      VDZ := Conversions.To_Long (Data (6));
      if not Conversions.Grid_In_Range (OX)
        or else not Conversions.Grid_In_Range (OY)
        or else not Conversions.Grid_In_Range (OZ)
        or else not Conversions.Grid_In_Range (OX + VDX)
        or else not Conversions.Grid_In_Range (OY + VDY)
        or else not Conversions.Grid_In_Range (OZ + VDZ)
      then
         Session.Record_Failure ("error: vector outside the grid");
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
         Session.Current_Session.The_Scene.Vectors.Append
           (Vector_Rec'
              (From_Name => From_Name,
               To_Name   => To_Name,
               Label     => Null_Unbounded_String,
               Color     =>
                 To_Unbounded_String (Hex_Of (To_Color (Data (7))))));
      end;
   end Draw_Vector_Native;

   procedure Draw_Point_2D_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      PX, PY : Long_Long_Integer;
   begin
      if not Session.Current_Session.Image_Open then
         Session.Record_Failure ("error: no open image");
         return;
      end if;
      PX := Conversions.To_Long (Data (1));
      PY := Conversions.To_Long (Data (2));
      if not Conversions.Grid_In_Range (PX)
        or else not Conversions.Grid_In_Range (PY)
      then
         Session.Record_Failure ("error: coordinate outside the grid");
         return;
      end if;

      Color_Point
        (Integer (PX), Integer (PY), 0,
         To_Unbounded_String (Hex_Of (To_Color (Data (3)))));
   end Draw_Point_2D_Native;

   procedure Draw_Edge_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      PX, PY, QX, QY : Long_Long_Integer;
   begin
      if not Session.Current_Session.Image_Open then
         Session.Record_Failure ("error: no open image");
         return;
      end if;
      PX := Conversions.To_Long (Data (1));
      PY := Conversions.To_Long (Data (2));
      QX := Conversions.To_Long (Data (3));
      QY := Conversions.To_Long (Data (4));
      if not Conversions.Grid_In_Range (PX)
        or else not Conversions.Grid_In_Range (PY)
        or else not Conversions.Grid_In_Range (QX)
        or else not Conversions.Grid_In_Range (QY)
      then
         Session.Record_Failure ("error: coordinate outside the grid");
         return;
      end if;
      if PX = QX and then PY = QY then
         return;
      end if;

      declare
         DX : constant Integer := Integer (QX - PX);
         DY : constant Integer := Integer (QY - PY);
      begin
         Session.Current_Session.The_Scene.Vectors.Append
           (Vector_Rec'
              (From_Name =>
                 Anchor_Name (Integer (PX), Integer (PY), 0),
               To_Name   =>
                 Anchor_Name (Integer (QX), Integer (QY), 0),
               Label     =>
                 To_Unbounded_String
                   ("(" & Ada.Strings.Fixed.Trim
                        (DX'Image, Ada.Strings.Both)
                    & ", " & Ada.Strings.Fixed.Trim
                        (DY'Image, Ada.Strings.Both) & ")"),
               Color     =>
                 To_Unbounded_String (Hex_Of (To_Color (Data (5))))));
      end;
   end Draw_Edge_Native;

   procedure End_Image_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      pragma Unreferenced (Data);
   begin
      if not Session.Current_Session.Image_Open then
         Session.Record_Failure ("error: no open image");
         return;
      end if;
      Session.Current_Session.Image_Open := False;

      declare
         F : Ada.Text_IO.File_Type;
      begin
         Ada.Text_IO.Create
           (F, Ada.Text_IO.Out_File,
            To_String (Session.Current_Session.Image_Name));
         Ada.Text_IO.Put (F, Render (Session.Current_Session.The_Scene));
         Ada.Text_IO.Close (F);
      exception
         when Scene_Error =>
            Session.Record_Failure ("error: invalid image scene");
            if Ada.Text_IO.Is_Open (F) then
               Ada.Text_IO.Close (F);
            end if;
         when Ada.Text_IO.Name_Error
            | Ada.Text_IO.Use_Error
         =>
            Session.Record_Failure ("error: cannot write the image");
            if Ada.Text_IO.Is_Open (F) then
               Ada.Text_IO.Close (F);
            end if;
      end;
   end End_Image_Native;

end TopoScript_API.Drawing;

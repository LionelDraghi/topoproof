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

with TopoDiagnostics;
with TopoScript_API.Conversions;
with TopoScript_API.Session;

with TopoProof.Geometry.Points;
with TopoProof.Geometry.Vectors;
with TopoProof.Numerics;
with Topodraw;
use Topodraw;

package body TopoScript_API.Drawing is

   use type TopoProof.Numerics.Grid_Coordinate;

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

   --  Set the name of the point at the position: the vectors already
   --  anchored on the position follow the rename, so the render finds
   --  their endpoints. A position not drawn yet is appended as a
   --  plain anchor point with the given name.
   procedure Name_Point (X, Y, Z : Integer; Name : Unbounded_String) is
      Found : Boolean := False;
   begin
      for Pt of Session.Current_Session.The_Scene.Points loop
         if Pt.X = X and then Pt.Y = Y and then Pt.Z = Z then
            for V of Session.Current_Session.The_Scene.Vectors loop
               if V.From_Name = Pt.Name then
                  V.From_Name := Name;
               end if;
               if V.To_Name = Pt.Name then
                  V.To_Name := Name;
               end if;
            end loop;
            Pt.Name := Name;
            Found   := True;
         end if;
      end loop;
      if not Found then
         Session.Current_Session.The_Scene.Points.Append
           (Point_Rec'
              (Name  => Name,
               X     => X,
               Y     => Y,
               Z     => Z,
               Color => Null_Unbounded_String));
      end if;
   end Name_Point;

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
         Session.Record_Failure (TopoDiagnostics.No_Image_Diagnostic);
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
      P : TopoProof.Geometry.Points.Point_3D;
   begin
      if not Session.Current_Session.Image_Open then
         Session.Record_Failure (TopoDiagnostics.No_Image_Diagnostic);
         return;
      end if;
      if not Conversions.Read_Point_3D (Data, 1, P) then
         Session.Record_Failure (TopoDiagnostics.Outside_Grid_Diagnostic);
         return;
      end if;

      Color_Point
        (Integer (P.X), Integer (P.Y), Integer (P.Z),
         To_Unbounded_String (Hex_Of (To_Color (Data (4)))));
   end Draw_Point_Native;

   procedure Draw_Named_Point_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      --  Element layout: P at 1..3, Name at 4, Color at 5.
      P : TopoProof.Geometry.Points.Point_3D;

   begin
      if not Session.Current_Session.Image_Open then
         Session.Record_Failure (TopoDiagnostics.No_Image_Diagnostic);
         return;
      end if;
      if not Conversions.Read_Point_3D (Data, 1, P) then
         Session.Record_Failure (TopoDiagnostics.Outside_Grid_Diagnostic);
         return;
      end if;

      declare
         Name  : constant Unbounded_String :=
           To_Unbounded_String
             (String'(HAC_Sys.Interfacing.To_Native (Data (4))));
         Color : constant Unbounded_String :=
           To_Unbounded_String (Hex_Of (To_Color (Data (5))));
      begin
         Color_Point (Integer (P.X), Integer (P.Y), Integer (P.Z),
                      Color);
         Name_Point (Integer (P.X), Integer (P.Y), Integer (P.Z),
                     Name);
      end;
   end Draw_Named_Point_Native;

   procedure Draw_Named_Point_2D_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      --  Element layout: P at 1..2, Name at 3, Color at 4.
      P : TopoProof.Geometry.Points.Point_2D;

   begin
      if not Session.Current_Session.Image_Open then
         Session.Record_Failure (TopoDiagnostics.No_Image_Diagnostic);
         return;
      end if;
      if not Conversions.Read_Point_2D (Data, 1, P) then
         Session.Record_Failure (TopoDiagnostics.Outside_Grid_Diagnostic);
         return;
      end if;

      declare
         Name  : constant Unbounded_String :=
           To_Unbounded_String
             (String'(HAC_Sys.Interfacing.To_Native (Data (3))));
         Color : constant Unbounded_String :=
           To_Unbounded_String (Hex_Of (To_Color (Data (4))));
      begin
         Color_Point (Integer (P.X), Integer (P.Y), 0, Color);
         Name_Point (Integer (P.X), Integer (P.Y), 0, Name);
      end;
   end Draw_Named_Point_2D_Native;

   procedure Draw_Plane_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      --  Element layout: A at 1..3, B at 4..6, C at 7..9, Color at 10.
      A, B, C : TopoProof.Geometry.Points.Point_3D;
   begin
      if not Session.Current_Session.Image_Open then
         Session.Record_Failure (TopoDiagnostics.No_Image_Diagnostic);
         return;
      end if;
      --  The patch parallelogram is closed by the fourth corner
      --  B + C - A, a grid position by the drawing input contract,
      --  checked like the vector tips.
      if not Conversions.Read_Point_3D (Data, 1, A)
        or else not Conversions.Read_Point_3D (Data, 4, B)
        or else not Conversions.Read_Point_3D (Data, 7, C)
        or else not Conversions.Grid_In_Range
                    (Long_Long_Integer (B.X) + Long_Long_Integer (C.X)
                     - Long_Long_Integer (A.X))
        or else not Conversions.Grid_In_Range
                    (Long_Long_Integer (B.Y) + Long_Long_Integer (C.Y)
                     - Long_Long_Integer (A.Y))
        or else not Conversions.Grid_In_Range
                    (Long_Long_Integer (B.Z) + Long_Long_Integer (C.Z)
                     - Long_Long_Integer (A.Z))
      then
         Session.Record_Failure (TopoDiagnostics.Outside_Grid_Diagnostic);
         return;
      end if;

      Session.Current_Session.The_Scene.Planes.Append
        (Topodraw.Plane_Rec'
           (AX => Integer (A.X), AY => Integer (A.Y), AZ => Integer (A.Z),
            BX => Integer (B.X), BY => Integer (B.Y), BZ => Integer (B.Z),
            CX => Integer (C.X), CY => Integer (C.Y), CZ => Integer (C.Z),
            Color =>
              To_Unbounded_String (Hex_Of (To_Color (Data (10))))));
   end Draw_Plane_Native;

   procedure Draw_Vector_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      O : TopoProof.Geometry.Points.Point_3D;
      V : TopoProof.Geometry.Vectors.Vector_3D;
   begin
      if not Session.Current_Session.Image_Open then
         Session.Record_Failure (TopoDiagnostics.No_Image_Diagnostic);
         return;
      end if;
      if not Conversions.Read_Point_3D (Data, 1, O)
        or else not Conversions.Read_Vector_3D (Data, 4, V)
        or else not Conversions.Grid_In_Range
                    (Long_Long_Integer (O.X) + Long_Long_Integer (V.DX))
        or else not Conversions.Grid_In_Range
                    (Long_Long_Integer (O.Y) + Long_Long_Integer (V.DY))
        or else not Conversions.Grid_In_Range
                    (Long_Long_Integer (O.Z) + Long_Long_Integer (V.DZ))
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
           Anchor_Name (Integer (O.X), Integer (O.Y), Integer (O.Z));
         To_Name :=
           Anchor_Name (Integer (O.X) + Integer (V.DX),
                        Integer (O.Y) + Integer (V.DY),
                        Integer (O.Z) + Integer (V.DZ));
         Session.Current_Session.The_Scene.Vectors.Append
           (Vector_Rec'
              (From_Name => From_Name,
               To_Name   => To_Name,
               Label     => Null_Unbounded_String,
               Color     =>
                 To_Unbounded_String (Hex_Of (To_Color (Data (7)))),
               Arrow     => True));
      end;
   end Draw_Vector_Native;

   procedure Draw_Named_Vector_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      --  Element layout: O at 1..3, V at 4..6, Name at 7, Color at 8.
      O : TopoProof.Geometry.Points.Point_3D;
      V : TopoProof.Geometry.Vectors.Vector_3D;

   begin
      if not Session.Current_Session.Image_Open then
         Session.Record_Failure (TopoDiagnostics.No_Image_Diagnostic);
         return;
      end if;
      if not Conversions.Read_Point_3D (Data, 1, O)
        or else not Conversions.Read_Vector_3D (Data, 4, V)
        or else not Conversions.Grid_In_Range
                    (Long_Long_Integer (O.X) + Long_Long_Integer (V.DX))
        or else not Conversions.Grid_In_Range
                    (Long_Long_Integer (O.Y) + Long_Long_Integer (V.DY))
        or else not Conversions.Grid_In_Range
                    (Long_Long_Integer (O.Z) + Long_Long_Integer (V.DZ))
      then
         Session.Record_Failure ("error: vector outside the grid");
         return;
      end if;

      declare
         Name : constant Unbounded_String :=
           To_Unbounded_String
             (String'(HAC_Sys.Interfacing.To_Native (Data (7))));
      begin
         --  The tip anchor carries the given name: the diagram labels
         --  the arrow end with the script variable of the tip.
         Session.Current_Session.The_Scene.Vectors.Append
           (Vector_Rec'
              (From_Name =>
                 Anchor_Name (Integer (O.X), Integer (O.Y), Integer (O.Z)),
               To_Name   => Name,
               Label     => Null_Unbounded_String,
               Color     =>
                 To_Unbounded_String (Hex_Of (To_Color (Data (8)))),
               Arrow     => True));
         Name_Point (Integer (O.X) + Integer (V.DX),
                     Integer (O.Y) + Integer (V.DY),
                     Integer (O.Z) + Integer (V.DZ),
                     Name);
      end;
   end Draw_Named_Vector_Native;

   procedure Draw_Point_2D_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      P : TopoProof.Geometry.Points.Point_2D;
   begin
      if not Session.Current_Session.Image_Open then
         Session.Record_Failure (TopoDiagnostics.No_Image_Diagnostic);
         return;
      end if;
      if not Conversions.Read_Point_2D (Data, 1, P) then
         Session.Record_Failure (TopoDiagnostics.Outside_Grid_Diagnostic);
         return;
      end if;

      Color_Point
        (Integer (P.X), Integer (P.Y), 0,
         To_Unbounded_String (Hex_Of (To_Color (Data (3)))));
   end Draw_Point_2D_Native;

   --  One drawn segment between two grid points: the vector record
   --  appended to the scene, with the anchor names of its ends and
   --  the color of the drawing operation. The label is empty for a
   --  plain segment.
   procedure Append_Segment
     (P, Q : TopoProof.Geometry.Points.Point_2D;
      Color : HAC_Sys.Interfacing.HAC_Element;
      Label : String;
      Arrow : Boolean)
   is
   begin
      Session.Current_Session.The_Scene.Vectors.Append
        (Vector_Rec'
           (From_Name =>
              Anchor_Name (Integer (P.X), Integer (P.Y), 0),
            To_Name   =>
              Anchor_Name (Integer (Q.X), Integer (Q.Y), 0),
            Label     => To_Unbounded_String (Label),
            Color     =>
              To_Unbounded_String (Hex_Of (To_Color (Color))),
            Arrow     => Arrow));
   end Append_Segment;

   procedure Draw_Edge_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      P : TopoProof.Geometry.Points.Point_2D;
      Q : TopoProof.Geometry.Points.Point_2D;
   begin
      if not Session.Current_Session.Image_Open then
         Session.Record_Failure (TopoDiagnostics.No_Image_Diagnostic);
         return;
      end if;
      if not Conversions.Read_Point_2D (Data, 1, P)
        or else not Conversions.Read_Point_2D (Data, 3, Q)
      then
         Session.Record_Failure (TopoDiagnostics.Outside_Grid_Diagnostic);
         return;
      end if;
      if P.X = Q.X and then P.Y = Q.Y then
         return;
      end if;

      declare
         DX : constant Integer := Integer (Q.X) - Integer (P.X);
         DY : constant Integer := Integer (Q.Y) - Integer (P.Y);
      begin
         Append_Segment
           (P, Q, Data (5),
            "(" & Ada.Strings.Fixed.Trim
                 (DX'Image, Ada.Strings.Both)
             & ", " & Ada.Strings.Fixed.Trim
                 (DY'Image, Ada.Strings.Both) & ")",
            Arrow => True);
      end;
   end Draw_Edge_Native;

   --  The three-dimensional edge arrow: the same scene vector record
   --  as its 2D counterpart, anchored on the space positions, and
   --  labeled with the three-component displacement.
   procedure Draw_Edge_3D_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      --  Element layout: P at 1..3, Q at 4..6, Color at 7.
      P : TopoProof.Geometry.Points.Point_3D;
      Q : TopoProof.Geometry.Points.Point_3D;
   begin
      if not Session.Current_Session.Image_Open then
         Session.Record_Failure (TopoDiagnostics.No_Image_Diagnostic);
         return;
      end if;
      if not Conversions.Read_Point_3D (Data, 1, P)
        or else not Conversions.Read_Point_3D (Data, 4, Q)
      then
         Session.Record_Failure (TopoDiagnostics.Outside_Grid_Diagnostic);
         return;
      end if;
      if P.X = Q.X and then P.Y = Q.Y and then P.Z = Q.Z then
         return;
      end if;

      declare
         DX : constant Integer := Integer (Q.X) - Integer (P.X);
         DY : constant Integer := Integer (Q.Y) - Integer (P.Y);
         DZ : constant Integer := Integer (Q.Z) - Integer (P.Z);
      begin
         Session.Current_Session.The_Scene.Vectors.Append
           (Vector_Rec'
              (From_Name =>
                 Anchor_Name
                   (Integer (P.X), Integer (P.Y), Integer (P.Z)),
               To_Name   =>
                 Anchor_Name
                   (Integer (Q.X), Integer (Q.Y), Integer (Q.Z)),
               Label     => To_Unbounded_String
                 ("(" & Ada.Strings.Fixed.Trim
                       (DX'Image, Ada.Strings.Both)
                  & ", " & Ada.Strings.Fixed.Trim
                       (DY'Image, Ada.Strings.Both)
                  & ", " & Ada.Strings.Fixed.Trim
                       (DZ'Image, Ada.Strings.Both) & ")"),
               Color     =>
                 To_Unbounded_String (Hex_Of (To_Color (Data (7)))),
               Arrow     => True));
      end;
   end Draw_Edge_3D_Native;

   --  The wireframe of the axis-aligned box of the given dimensions
   --  over the given corner: the twelve segments of the box skeleton,
   --  appended as plain scene vectors - no displacement labels, the
   --  skeleton shows a volume, not twelve displacements. The positive
   --  dimensions and the grid-check of the far corner follow the same
   --  input contract as the Box creation primitive.
   procedure Draw_Box_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      --  Element layout: Corner at 1..3, Width at 4, Depth at 5,
      --  Height at 6, Color at 7.
      Corner : TopoProof.Geometry.Points.Point_3D;
      W : constant Long_Long_Integer := Conversions.To_Long (Data (4));
      D : constant Long_Long_Integer := Conversions.To_Long (Data (5));
      H : constant Long_Long_Integer := Conversions.To_Long (Data (6));
      Color : constant Unbounded_String :=
        To_Unbounded_String (Hex_Of (To_Color (Data (7))));

      procedure Add_Segment
        (PX, PY, PZ, QX, QY, QZ : Integer)
      is
      begin
         Session.Current_Session.The_Scene.Vectors.Append
           (Vector_Rec'
              (From_Name => Anchor_Name (PX, PY, PZ),
               To_Name   => Anchor_Name (QX, QY, QZ),
               Label     => Null_Unbounded_String,
               Color     => Color,
               Arrow     => False));
      end Add_Segment;

   begin
      if not Session.Current_Session.Image_Open then
         Session.Record_Failure (TopoDiagnostics.No_Image_Diagnostic);
         return;
      end if;
      if not Conversions.Read_Point_3D (Data, 1, Corner) then
         Session.Record_Failure (TopoDiagnostics.Outside_Grid_Diagnostic);
         return;
      end if;
      if W < 1 or else D < 1 or else H < 1
        or else not Conversions.Grid_In_Range
                       (Long_Long_Integer (Corner.X) + W)
        or else not Conversions.Grid_In_Range
                       (Long_Long_Integer (Corner.Y) + D)
        or else not Conversions.Grid_In_Range
                       (Long_Long_Integer (Corner.Z) + H)
      then
         Session.Record_Failure ("error: invalid box dimensions");
         return;
      end if;

      declare
         X : constant Integer := Integer (Corner.X);
         Y : constant Integer := Integer (Corner.Y);
         Z : constant Integer := Integer (Corner.Z);
         U : constant Integer := X + Integer (W);  --  The far X, Y, Z
         V : constant Integer := Y + Integer (D);  --  faces of the
         T : constant Integer := Z + Integer (H);  --  box.
      begin
         --  The bottom rectangle, then the top rectangle, then the
         --  four verticals.
         Add_Segment (X, Y, Z, U, Y, Z);
         Add_Segment (U, Y, Z, U, V, Z);
         Add_Segment (U, V, Z, X, V, Z);
         Add_Segment (X, V, Z, X, Y, Z);
         Add_Segment (X, Y, T, U, Y, T);
         Add_Segment (U, Y, T, U, V, T);
         Add_Segment (U, V, T, X, V, T);
         Add_Segment (X, V, T, X, Y, T);
         Add_Segment (X, Y, Z, X, Y, T);
         Add_Segment (U, Y, Z, U, Y, T);
         Add_Segment (U, V, Z, U, V, T);
         Add_Segment (X, V, Z, X, V, T);
      end;
   end Draw_Box_Native;

   procedure Draw_Segment_2D_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      --  Element layout: P at 1..2, Q at 3..4, Color at 5.
      P : TopoProof.Geometry.Points.Point_2D;
      Q : TopoProof.Geometry.Points.Point_2D;

   begin
      if not Session.Current_Session.Image_Open then
         Session.Record_Failure (TopoDiagnostics.No_Image_Diagnostic);
         return;
      end if;
      if not Conversions.Read_Point_2D (Data, 1, P)
        or else not Conversions.Read_Point_2D (Data, 3, Q)
      then
         Session.Record_Failure (TopoDiagnostics.Outside_Grid_Diagnostic);
         return;
      end if;
      if P.X = Q.X and then P.Y = Q.Y then
         return;
      end if;

      Append_Segment (P, Q, Data (5), "", Arrow => False);
   end Draw_Segment_2D_Native;

   procedure End_Image_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      pragma Unreferenced (Data);
   begin
      if not Session.Current_Session.Image_Open then
         Session.Record_Failure (TopoDiagnostics.No_Image_Diagnostic);
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

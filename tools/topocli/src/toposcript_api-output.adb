-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
use Ada.Strings.Unbounded;
with Ada.Text_IO;

with TopoDiagnostics;
with TopoScript_API.Conversions;
with TopoScript_API.Session;

with TopoProof.Numerics;
with TopoProof.Topology.Faces;
with TopoProof.Topology.Loops;

package body TopoScript_API.Output is

   --  The trimmed decimal image of one grid coordinate: the canonical
   --  form of every coordinate in a result line.
   function Img (C : TopoProof.Numerics.Grid_Coordinate) return String is
     (Ada.Strings.Fixed.Trim (C'Image, Ada.Strings.Both));

   --  The trimmed decimal image of one component difference: the
   --  canonical form of every vector component in a result line.
   function Img (C : TopoProof.Numerics.Vector_Component) return String is
     (Ada.Strings.Fixed.Trim (C'Image, Ada.Strings.Both));

   function Image (P : TopoProof.Geometry.Points.Point_3D) return String is
     ("point " & Img (P.X) & " " & Img (P.Y) & " " & Img (P.Z));

   function Image
     (V : TopoProof.Geometry.Vectors.Vector_3D) return String
   is
     ("vector " & Img (V.DX) & " " & Img (V.DY) & " " & Img (V.DZ));

   function Image (K : Loop_Result) return String is
     (case K is
         when Topology.Counter_Clockwise => "loop closed counter_clockwise",
         when Topology.Clockwise         => "loop closed clockwise",
         when Topology.Degenerate        => "loop closed degenerate");

   function Image (K : Face_Result) return String is
     (case K is
         when Topology.Face_Counter_Clockwise => "face counter_clockwise",
         when Topology.Face_Clockwise         => "face clockwise");

   function Image (K : Geometry.Equal_Kind) return String is
     (case K is
         when Geometry.Equal_True  => "equal true",
         when Geometry.Equal_False => "equal false");

   function Image (K : Topology.Continuity_Kind) return String is
     (case K is
         when Topology.Continuous    => "continuity continuous",
         when Topology.Discontinuous => "continuity discontinuous");

   function Image (K : Topology.Closure_Kind) return String is
     (case K is
         when Topology.Closed => "closure closed",
         when Topology.Open   => "closure open");

   function Image (K : Topology.Contour_Orientation_Kind) return String is
     (case K is
         when Topology.Contour_Counter_Clockwise =>
            "orientation counter_clockwise",
         when Topology.Contour_Clockwise =>
            "orientation clockwise",
         when Topology.Contour_Degenerate =>
            "orientation degenerate");

   function Image (K : Topology.Bool_Kind) return String is
     (case K is
         when Topology.Bool_True  => "true",
         when Topology.Bool_False => "false");

   function Image
     (K : TopoProof.Geometry.Orientations.Orientation_Kind) return String
   is
     (case K is
         when TopoProof.Geometry.Orientations.Collinear =>
            "orientation collinear",
         when TopoProof.Geometry.Orientations.Counter_Clockwise =>
            "orientation counter_clockwise",
         when TopoProof.Geometry.Orientations.Clockwise =>
            "orientation clockwise");

   function Image
     (K            : TopoProof.Geometry.Intersections.Intersection_Kind;
      PX, PY, QX, QY : TopoProof.Numerics.Grid_Coordinate) return String
   is
     (case K is
         when TopoProof.Geometry.Intersections.No_Intersection =>
            "intersection no_intersection",
         when TopoProof.Geometry.Intersections.Point_Intersection =>
            "intersection point_intersection " & Img (PX) & " " & Img (PY),
         when TopoProof.Geometry.Intersections.Off_Grid_Crossing =>
            "intersection off_grid_crossing",
         when TopoProof.Geometry.Intersections.Overlap =>
            "intersection overlap " & Img (PX) & " " & Img (PY)
            & " " & Img (QX) & " " & Img (QY));

   procedure Set_Output_Path (Path : String) is
   begin
      Session.Current_Session.Output_Path := To_Unbounded_String (Path);
   end Set_Output_Path;

   procedure Put_Line (S : String) is
   begin
      if Length (Session.Current_Session.Output_Path) = 0 then
         Ada.Text_IO.Put_Line (S);

      else
         if not Ada.Text_IO.Is_Open (Session.Current_Session.Output_File)
         then
            Ada.Text_IO.Create
              (Session.Current_Session.Output_File,
               Ada.Text_IO.Out_File,
               To_String (Session.Current_Session.Output_Path));
         end if;
         Ada.Text_IO.Put_Line (Session.Current_Session.Output_File, S);

      end if;
   end Put_Line;

   procedure Close_Output is
   begin
      if Ada.Text_IO.Is_Open (Session.Current_Session.Output_File) then
         Ada.Text_IO.Close (Session.Current_Session.Output_File);

      end if;
   end Close_Output;

   procedure Put_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      P : TopoProof.Geometry.Points.Point_3D;

   begin
      if not Conversions.Read_Point_3D (Data, 1, P) then
         Session.Record_Failure ("error: coordinate outside the grid");
         return;
      end if;

      Put_Line (Image (P));
   end Put_Native;

   procedure Put_Vector_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      V : TopoProof.Geometry.Vectors.Vector_3D;

   begin
      if not Conversions.Read_Vector_Result_3D (Data, 1, V) then
         Session.Record_Failure
           ("error: vector component outside the component domain");
         return;
      end if;

      Put_Line (Image (V));
   end Put_Vector_Native;

   procedure Put_Equal_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      K : constant Geometry.Equal_Kind :=
        Geometry.To_Equal_Kind (Data (1));

   begin
      Put_Line (Image (K));
   end Put_Equal_Native;

   procedure Put_Continuity_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      --  Element layout: K at 1.
      K : constant Topology.Continuity_Kind :=
        Topology.To_Continuity_Kind (Data (1));

   begin
      Put_Line (Image (K));
   end Put_Continuity_Native;

   procedure Put_Closure_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      --  Element layout: K at 1.
      K : constant Topology.Closure_Kind :=
        Topology.To_Closure_Kind (Data (1));

   begin
      Put_Line (Image (K));
   end Put_Closure_Native;

   procedure Put_Contour_Orientation_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      --  Element layout: K at 1.
      K : constant Topology.Contour_Orientation_Kind :=
        Topology.To_Contour_Orientation_Kind (Data (1));

   begin
      Put_Line (Image (K));
   end Put_Contour_Orientation_Native;

   procedure Put_Bool_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      --  Element layout: B at 1.
      B : constant Topology.Bool_Kind :=
        Topology.To_Bool_Kind (Data (1));

   begin
      Put_Line (Image (B));
   end Put_Bool_Native;

   procedure Put_Orientation_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      K : constant TopoProof.Geometry.Orientations.Orientation_Kind :=
        Geometry.To_Orientation_Kind (Data (1));

   begin
      Put_Line (Image (K));
   end Put_Orientation_Native;

   procedure Put_Intersection_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      --  Element layout: R at 1..5: the kind, then four coordinates.
      K  : constant TopoProof.Geometry.Intersections.Intersection_Kind :=
        Geometry.To_Intersection_Kind (Data (1));
      PX : constant Long_Long_Integer := Conversions.To_Long (Data (2));
      PY : constant Long_Long_Integer := Conversions.To_Long (Data (3));
      QX : constant Long_Long_Integer := Conversions.To_Long (Data (4));
      QY : constant Long_Long_Integer := Conversions.To_Long (Data (5));

   begin
      case K is
         when TopoProof.Geometry.Intersections.No_Intersection
            | TopoProof.Geometry.Intersections.Off_Grid_Crossing
         =>
            Put_Line (Image (K, 0, 0, 0, 0));
         when TopoProof.Geometry.Intersections.Point_Intersection =>
            if not Conversions.Grid_In_Range (PX)
              or else not Conversions.Grid_In_Range (PY)
            then
               Session.Record_Failure
                 ("error: coordinate outside the grid");
               return;
            end if;
            Put_Line
              (Image
                 (K,
                  TopoProof.Numerics.Grid_Coordinate (PX),
                  TopoProof.Numerics.Grid_Coordinate (PY),
                  0, 0));
         when TopoProof.Geometry.Intersections.Overlap =>
            if not Conversions.Grid_In_Range (PX)
              or else not Conversions.Grid_In_Range (PY)
              or else not Conversions.Grid_In_Range (QX)
              or else not Conversions.Grid_In_Range (QY)
            then
               Session.Record_Failure
                 ("error: coordinate outside the grid");
               return;
            end if;
            Put_Line
              (Image
                 (K,
                  TopoProof.Numerics.Grid_Coordinate (PX),
                  TopoProof.Numerics.Grid_Coordinate (PY),
                  TopoProof.Numerics.Grid_Coordinate (QX),
                  TopoProof.Numerics.Grid_Coordinate (QY)));
      end case;
   end Put_Intersection_Native;

   procedure Put_Loop_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      K : constant Topology.Loop_Kind := Topology.To_Loop_Kind (Data (1));

   begin
      case K is
         when Topology.Counter_Clockwise
            | Topology.Clockwise
            | Topology.Degenerate
         =>
            Put_Line (Image (K));
         when Topology.Open_Chain =>
            Session.Record_Failure
              (TopoDiagnostics.Loop_Diagnostic
                 (TopoProof.Topology.Loops.Open_Chain));
         when Topology.Orphan_Edge =>
            Session.Record_Failure
              (TopoDiagnostics.Loop_Diagnostic
                 (TopoProof.Topology.Loops.Orphan_Edge));
         when Topology.Missing_Endpoint =>
            Session.Record_Failure
              (TopoDiagnostics.Loop_Diagnostic
                 (TopoProof.Topology.Loops.Missing_Endpoint));
         when Topology.Disconnected_Chain =>
            Session.Record_Failure
              (TopoDiagnostics.Loop_Diagnostic
                 (TopoProof.Topology.Loops.Disconnected_Chain));
         when Topology.Degenerate_Support =>
            Session.Record_Failure
              (TopoDiagnostics.Loop_Diagnostic
                 (TopoProof.Topology.Loops.Degenerate_Support));
      end case;
   end Put_Loop_Native;

   procedure Put_Face_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      K : constant Topology.Face_Kind := Topology.To_Face_Kind (Data (1));

   begin
      case K is
         when Topology.Face_Counter_Clockwise
            | Topology.Face_Clockwise
         =>
            Put_Line (Image (K));
         when Topology.Face_Degenerate_Boundary =>
            Session.Record_Failure
              (TopoDiagnostics.Face_Diagnostic
                 (TopoProof.Topology.Faces.Degenerate_Boundary));
         when Topology.Face_Invalid_Boundary =>
            Session.Record_Failure
              (TopoDiagnostics.Face_Diagnostic
                 (TopoProof.Topology.Faces.Invalid_Boundary));
      end case;
   end Put_Face_Native;

end TopoScript_API.Output;

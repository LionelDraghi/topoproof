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
with TopoProof.Geometry.Planes;
with TopoProof.Topology.Faces;
with TopoProof.Topology.Loops;

package body TopoScript_API.Output is

   --  The trimmed decimal image of one discrete value: the canonical
   --  form of every numeric field in a result line, whatever its
   --  domain type.
   generic
      type T is (<>);
   function Trimmed_Image (V : T) return String;

   function Trimmed_Image (V : T) return String is
     (Ada.Strings.Fixed.Trim (V'Image, Ada.Strings.Both));

   function Img is new Trimmed_Image (TopoProof.Numerics.Grid_Coordinate);
   function Img is new Trimmed_Image (TopoProof.Numerics.Vector_Component);
   function Img is new Trimmed_Image (TopoProof.Numerics.Cross_Component);
   function Img is new Trimmed_Image (TopoProof.Numerics.Dot_Product);

   function Image (P : TopoProof.Geometry.Points.Point_3D) return String is
     ("point " & Img (P.X) & " " & Img (P.Y) & " " & Img (P.Z));

   function Image
     (V : TopoProof.Geometry.Vectors.Vector_3D) return String
   is
     ("vector " & Img (V.DX) & " " & Img (V.DY) & " " & Img (V.DZ));

   function Image
     (V : TopoProof.Geometry.Vectors.Cross_Vector_3D) return String
   is
     ("cross " & Img (V.DX) & " " & Img (V.DY) & " " & Img (V.DZ));

   function Image (D : TopoProof.Numerics.Dot_Product) return String is
     ("dot " & Img (D));

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

   --  The trimmed decimal image of one topology handle: the canonical
   --  form of a vertex or edge handle in a construction trace. Both
   --  handle types are subtypes of Positive, so one instantiation
   --  covers them.
   function Img is new Trimmed_Image (Positive);

   function Image
     (H : TopoProof.Topology.Vertices.Vertex_Handle;
      P : TopoProof.Geometry.Points.Point_2D) return String
   is
     ("vertex " & Img (H) & " point " & Img (P.X) & " " & Img (P.Y));

   function Image
     (E     : TopoProof.Topology.Edges.Edge_Handle;
      A, B  : TopoProof.Topology.Vertices.Vertex_Handle)
      return String
   is
     ("edge " & Img (E) & " vertex " & Img (A) & " vertex " & Img (B));

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
     (K : TopoProof.Geometry.Orientations.Orientation_3D_Kind) return String
   is
     (case K is
         when TopoProof.Geometry.Orientations.Coplanar =>
            "orientation3d coplanar",
         when TopoProof.Geometry.Orientations.Right_Handed =>
            "orientation3d right_handed",
         when TopoProof.Geometry.Orientations.Left_Handed =>
            "orientation3d left_handed");

   function Image
     (K : TopoProof.Geometry.Planes.Plane_Side_Kind) return String
   is
     (case K is
         when TopoProof.Geometry.Planes.In_Front =>
            "side in_front",
         when TopoProof.Geometry.Planes.Behind =>
            "side behind",
         when TopoProof.Geometry.Planes.On_Plane =>
            "side on_plane");

   function Image
     (K : TopoProof.Geometry.Planes.Plane_Kind) return String
   is
     (case K is
         when TopoProof.Geometry.Planes.Plane_Valid =>
            "plane valid",
         when TopoProof.Geometry.Planes.Plane_Collinear =>
            "plane collinear");

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
         Session.Record_Failure (TopoDiagnostics.Outside_Grid_Diagnostic);
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

   procedure Put_Dot_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      --  Element layout: D at 1.
      D : constant TopoProof.Numerics.Dot_Product :=
        Conversions.Dot_From_HAC (Data (1));

   begin
      Put_Line (Image (D));
   end Put_Dot_Native;

   procedure Put_Cross_Vector_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      --  Element layout: DX at 1, DY at 2, DZ at 3.
      V : TopoProof.Geometry.Vectors.Cross_Vector_3D;

   begin
      if not Conversions.Read_Cross_Vector_3D (Data, 1, V) then
         Session.Record_Failure
           ("error: cross component outside the component domain");
         return;
      end if;

      Put_Line (Image (V));
   end Put_Cross_Vector_Native;

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

   procedure Put_Vertex_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      --  Element layout: H at 1.
      H : TopoProof.Topology.Vertices.Vertex_Handle;

   begin
      --  A handle designates a stored vertex of the run, or none: the
      --  trace exists only for a created vertex.
      if not Conversions.Read_Vertex_Handle (Data, 1, H)
        or else not TopoProof.Topology.Vertices.Contains
          (Session.Current_Session.Vertices, H)
      then
         Session.Record_Failure ("error: unknown vertex");
         return;
      end if;
      Put_Line
        (Image
           (H,
            TopoProof.Topology.Vertices.Point_Of
              (Session.Current_Session.Vertices, H)));
   end Put_Vertex_Native;

   procedure Put_Edge_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      --  Element layout: E at 1.
      E : TopoProof.Topology.Edges.Edge_Handle;

   begin
      --  A handle designates a stored edge of the run, or none: the
      --  trace exists only for a created edge.
      if not Conversions.Read_Edge_Handle (Data, 1, E)
        or else not TopoProof.Topology.Edges.Contains
          (Session.Current_Session.Links, E)
      then
         Session.Record_Failure ("error: unknown edge");
         return;
      end if;
      declare
         Pair : constant TopoProof.Topology.Edges.Vertex_Handle_Pair :=
           TopoProof.Topology.Edges.Endpoints
             (Session.Current_Session.Links, E);

      begin
         Put_Line (Image (E, Pair.From_Vertex, Pair.To_Vertex));
      end;
   end Put_Edge_Native;

   procedure Put_Orientation_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      K : constant TopoProof.Geometry.Orientations.Orientation_Kind :=
        Geometry.To_Orientation_Kind (Data (1));

   begin
      Put_Line (Image (K));
   end Put_Orientation_Native;

   procedure Put_Orientation_3D_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      K : constant TopoProof.Geometry.Orientations.Orientation_3D_Kind :=
        Geometry.To_Orientation_3D_Kind (Data (1));

   begin
      Put_Line (Image (K));
   end Put_Orientation_3D_Native;

   procedure Put_Plane_Side_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      K : constant TopoProof.Geometry.Planes.Plane_Side_Kind :=
        Geometry.To_Plane_Side_Kind (Data (1));

   begin
      Put_Line (Image (K));
   end Put_Plane_Side_Native;

   procedure Put_Plane_Kind_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      K : constant TopoProof.Geometry.Planes.Plane_Kind :=
        Geometry.To_Plane_Kind (Data (1));

   begin
      Put_Line (Image (K));
   end Put_Plane_Kind_Native;

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
                 (TopoDiagnostics.Outside_Grid_Diagnostic);
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
                 (TopoDiagnostics.Outside_Grid_Diagnostic);
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

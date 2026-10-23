-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with Ada.Containers.Indefinite_Vectors;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;           use Ada.Strings.Unbounded;
with Ada.Text_IO;                     use Ada.Text_IO;

with HAC_Sys.Interfacing;             use HAC_Sys.Interfacing;

with TopoProof.Geometry.Points;      use TopoProof.Geometry.Points;
with TopoProof.Geometry.Segment_Sequences;
with TopoProof.Geometry.Translations;
use TopoProof.Geometry.Translations;
with TopoProof.Geometry.Vectors;      use TopoProof.Geometry.Vectors;
with TopoProof.Numerics;              use TopoProof.Numerics;
with TopoProof.Topology.Edges;
with TopoProof.Topology.Faces;
with TopoProof.Topology.Loops;
with TopoProof.Topology.Vertices;

with TopoDiagnostics;                 use TopoDiagnostics;
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
      --  The same axes configuration as the client scenes: automatic
      --  tick marks, and the dashed coordinate paths of every point.
      The_Scene.Draw_Axes := True;
      The_Scene.Tick_Step := 0;
      The_Scene.Anchors   := True;
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

   --  Native side of Draw_Point_2D: the point colors the scene at
   --  (X, Y, 0), the plane the 2D operations live in.
   procedure Draw_Point_2D_Native (Data : in out HAC_Element_Array) is
      PX, PY : Long_Long_Integer;
   begin
      if not Image_Open then
         Record_Failure ("error: no open image");
         return;
      end if;
      PX := To_Long (Data (1));
      PY := To_Long (Data (2));
      if not Grid_In_Range (PX) or else not Grid_In_Range (PY) then
         Record_Failure ("error: coordinate outside the grid");
         return;
      end if;

      Color_Point
        (Integer (PX), Integer (PY), 0,
         To_Unbounded_String (Hex_Of (To_Color (Data (3)))));
   end Draw_Point_2D_Native;

   --  Native side of Draw_Edge: the arrow runs from P to Q, labeled
   --  with the displacement, like the segment diagrams of the client
   --  operations; a degenerate edge draws nothing.
   procedure Draw_Edge_Native (Data : in out HAC_Element_Array) is
      PX, PY, QX, QY : Long_Long_Integer;
   begin
      if not Image_Open then
         Record_Failure ("error: no open image");
         return;
      end if;
      PX := To_Long (Data (1));
      PY := To_Long (Data (2));
      QX := To_Long (Data (3));
      QY := To_Long (Data (4));
      if not Grid_In_Range (PX)
        or else not Grid_In_Range (PY)
        or else not Grid_In_Range (QX)
        or else not Grid_In_Range (QY)
      then
         Record_Failure ("error: coordinate outside the grid");
         return;
      end if;
      if PX = QX and then PY = QY then
         return;
      end if;

      declare
         DX : constant Integer := Integer (QX - PX);
         DY : constant Integer := Integer (QY - PY);
      begin
         The_Scene.Vectors.Append
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

   --  Loop and face building (development plan, Milestone 6, Increment
   --  5): the script accumulates a chain of 2D points, then Make_Loop
   --  and Make_Face run the exact kernel classification, the same one
   --  as the loop and face client operations. In the script chain, a
   --  vertex is identified by its position: a repeated position
   --  closes on the same vertex. The chain lives for the whole script
   --  run: Add_Point always appends, and Make_Loop and Make_Face
   --  classify the chain as it stands at the call without ever
   --  clearing it, so the same chain can be classified first as a
   --  loop, then as a face boundary.

   type Chain_Point is record
      X, Y : Grid_Coordinate;
   end record;

   package Chain_Vectors is new Ada.Containers.Indefinite_Vectors
     (Positive, Chain_Point);

   Chain : Chain_Vectors.Vector;

   package Handle_Vectors is new Ada.Containers.Indefinite_Vectors
     (Positive, TopoProof.Topology.Vertices.Vertex_Handle);

   function Loop_To_HAC is new To_HAC_Any_Enum (Loop_Kind);

   function Face_To_HAC is new To_HAC_Any_Enum (Face_Kind);

   function To_Loop_Kind is new To_Native_Any_Enum (Loop_Kind);

   function To_Face_Kind is new To_Native_Any_Enum (Face_Kind);

   procedure Add_Point_Native (Data : in out HAC_Element_Array) is
      PX, PY : Long_Long_Integer;
   begin
      PX := To_Long (Data (1));
      PY := To_Long (Data (2));
      if not Grid_In_Range (PX) or else not Grid_In_Range (PY) then
         Record_Failure ("error: coordinate outside the grid");
         return;
      end if;
      Chain.Append
        (Chain_Point'(X => Grid_Coordinate (PX),
                      Y => Grid_Coordinate (PY)));
   end Add_Point_Native;

   function Distinct_Count return Natural is
      N : constant Natural := Natural (Chain.Length);
      Count : Natural := 0;
   begin
      for I in 1 .. N loop
         declare
            P : constant Chain_Point := Chain (I);
            New_One : Boolean := True;
         begin
            for J in 1 .. I - 1 loop
               if Chain (J) = P then
                  New_One := False;
               end if;
            end loop;
            if New_One then
               Count := Count + 1;
            end if;
         end;
      end loop;
      return Count;
   end Distinct_Count;

   --  Build the kernel stores from the accumulated chain: one vertex
   --  per distinct position, one edge per consecutive pair. The
   --  pre-checks of the client operations are made before any kernel
   --  call; on rejection the failure is already recorded, and the
   --  chain is reported as not buildable.
   procedure Build_Chain
     (Store   :    out TopoProof.Topology.Vertices.Vertex_Store;
      Links   :    out TopoProof.Topology.Edges.Edge_Store;
      Handles :    out TopoProof.Topology.Loops.Edge_Handle_Array;
      OK      :    out Boolean)
   is
      N : constant Natural := Natural (Chain.Length);
      Tokens : Handle_Vectors.Vector;
   begin
      OK := False;
      for I in 1 .. N loop
         declare
            P : constant Chain_Point := Chain (I);
            Reuse : Boolean := False;
         begin
            for J in 1 .. I - 1 loop
               if Chain (J) = P then
                  --  The handle is copied before the append: the
                  --  indexing reference of Tokens (J) would still be
                  --  live in this statement, and the container would
                  --  reject the append.
                  declare
                     H : constant TopoProof.Topology.Vertices.
                       Vertex_Handle := Tokens (J);
                  begin
                     Tokens.Append (H);
                  end;
                  Reuse := True;
                  exit;
               end if;
            end loop;
            if not Reuse then
               declare
                  H : TopoProof.Topology.Vertices.Vertex_Handle;
               begin
                  TopoProof.Topology.Vertices.Create
                    (Store, (X => P.X, Y => P.Y), H);
                  Tokens.Append (H);
               end;
            end if;
         end;
      end loop;
      for I in 2 .. N loop
         if Tokens (I - 1) = Tokens (I) then
            Record_Failure ("error: degenerate edge");
            return;
         end if;
         declare
            E : TopoProof.Topology.Edges.Edge_Handle;
         begin
            TopoProof.Topology.Edges.Create
              (Links, Store, Tokens (I - 1), Tokens (I), E);
            Handles (I - 1) := E;
         end;
      end loop;
      OK := True;
   end Build_Chain;

   --  Classify the built chain exactly, the same way as the loop
   --  client operation: on a valid loop the loop value is returned,
   --  otherwise the client diagnostic is recorded.
   procedure Classify_Chain
     (Links   :        TopoProof.Topology.Edges.Edge_Store;
      Store   :        TopoProof.Topology.Vertices.Vertex_Store;
      Handles :        TopoProof.Topology.Loops.Edge_Handle_Array;
      L       :    out TopoProof.Topology.Loops.Loop_2D;
      Valid   :    out Boolean)
   is
      use type TopoProof.Topology.Loops.Loop_Validity;
      Status : constant TopoProof.Topology.Loops.Loop_Validity :=
         TopoProof.Topology.Loops.Classify_Loop (Links, Store, Handles);
   begin
      if Status = TopoProof.Topology.Loops.Valid_Loop then
         L := TopoProof.Topology.Loops.Make_Loop (Links, Store,
                                                  Handles);
         Valid := True;

      else
         Record_Failure (Loop_Diagnostic (Status));
         Valid := False;

      end if;
   end Classify_Chain;

   procedure Make_Loop_Native (Data : in out HAC_Element_Array) is
      N : constant Natural := Natural (Chain.Length);
      Kind : Loop_Kind := Open_Chain;
   begin
      if N < 2 then
         Record_Failure
           (Loop_Diagnostic (TopoProof.Topology.Loops.Open_Chain));
         Data (1) := Loop_To_HAC (Kind);
         return;
      elsif N - 1 > TopoProof.Topology.Loops.Max_Loop_Length then
         Record_Failure ("error: too many edges for one loop");
         Data (1) := Loop_To_HAC (Kind);
         return;
      end if;

      declare
         Store : TopoProof.Topology.Vertices.Vertex_Store
           (TopoProof.Topology.Vertices.Vertex_Count_Range
              (Distinct_Count));
         Links : TopoProof.Topology.Edges.Edge_Store
           (TopoProof.Topology.Edges.Edge_Count_Range (N - 1));
         Handles : TopoProof.Topology.Loops.Edge_Handle_Array (1 .. N - 1);
         OK : Boolean;
         L : TopoProof.Topology.Loops.Loop_2D;
      begin
         Build_Chain (Store, Links, Handles, OK);
         if not OK then
            Data (1) := Loop_To_HAC (Degenerate_Support);
            return;
         end if;

         Classify_Chain (Links, Store, Handles, L, OK);
         if OK then
            case TopoProof.Topology.Loops.Loop_Orientation
                 (Links, Store, L)
            is
               when TopoProof.Geometry.Segment_Sequences.
                 Counter_Clockwise
               =>
                  Kind := Counter_Clockwise;
               when TopoProof.Geometry.Segment_Sequences.Clockwise =>
                  Kind := Clockwise;
               when TopoProof.Geometry.Segment_Sequences.Degenerate =>
                  Kind := Degenerate;
            end case;
         end if;
      end;
      Data (1) := Loop_To_HAC (Kind);
   end Make_Loop_Native;

   procedure Make_Face_Native (Data : in out HAC_Element_Array) is
      N : constant Natural := Natural (Chain.Length);
      Kind : Face_Kind := Face_Invalid_Boundary;
   begin
      if N < 2 then
         Record_Failure
           (Loop_Diagnostic (TopoProof.Topology.Loops.Open_Chain));
         Data (1) := Face_To_HAC (Kind);
         return;
      elsif N - 1 > TopoProof.Topology.Loops.Max_Loop_Length then
         Record_Failure ("error: too many edges for one loop");
         Data (1) := Face_To_HAC (Kind);
         return;
      end if;

      declare
         Store : TopoProof.Topology.Vertices.Vertex_Store
           (TopoProof.Topology.Vertices.Vertex_Count_Range
              (Distinct_Count));
         Links : TopoProof.Topology.Edges.Edge_Store
           (TopoProof.Topology.Edges.Edge_Count_Range (N - 1));
         Handles : TopoProof.Topology.Loops.Edge_Handle_Array (1 .. N - 1);
         OK : Boolean;
         L : TopoProof.Topology.Loops.Loop_2D;
      begin
         Build_Chain (Store, Links, Handles, OK);
         if not OK then
            Data (1) := Face_To_HAC (Face_Invalid_Boundary);
            return;
         end if;

         Classify_Chain (Links, Store, Handles, L, OK);
         if OK then
            case TopoProof.Topology.Faces.Classify_Face (Links, Store,
                                                        L)
            is
               when TopoProof.Topology.Faces.Valid_Face =>
                  declare
                     F : constant TopoProof.Topology.Faces.Face_2D :=
                       TopoProof.Topology.Faces.Make_Face
                         (Links, Store, L);
                  begin
                     case TopoProof.Topology.Faces.Face_Orientation
                          (Links, Store, F)
                     is
                        when TopoProof.Geometry.Segment_Sequences.
                          Counter_Clockwise
                        =>
                           Kind := Face_Counter_Clockwise;
                        when TopoProof.Geometry.Segment_Sequences.
                          Clockwise
                        =>
                           Kind := Face_Clockwise;
                        when TopoProof.Geometry.Segment_Sequences.
                          Degenerate
                        =>
                           --  A valid face orientation is never
                           --  degenerate: kernel contract.
                           Kind := Face_Degenerate_Boundary;
                     end case;
                  end;
               when TopoProof.Topology.Faces.Invalid_Boundary =>
                  Record_Failure
                    (Face_Diagnostic
                       (TopoProof.Topology.Faces.Invalid_Boundary));
               when TopoProof.Topology.Faces.Degenerate_Boundary =>
                  Kind := Face_Degenerate_Boundary;
                  Record_Failure
                    (Face_Diagnostic
                       (TopoProof.Topology.Faces.Degenerate_Boundary));
            end case;
         end if;
      end;
      Data (1) := Face_To_HAC (Kind);
   end Make_Face_Native;

   procedure Put_Loop_Native (Data : in out HAC_Element_Array) is
   begin
      case To_Loop_Kind (Data (1)) is
         when Counter_Clockwise =>
            Put_Line ("loop closed counter_clockwise");
         when Clockwise =>
            Put_Line ("loop closed clockwise");
         when Degenerate =>
            Put_Line ("loop closed degenerate");
         when Open_Chain =>
            Record_Failure
              (Loop_Diagnostic (TopoProof.Topology.Loops.Open_Chain));
         when Orphan_Edge =>
            Record_Failure
              (Loop_Diagnostic (TopoProof.Topology.Loops.Orphan_Edge));
         when Missing_Endpoint =>
            Record_Failure
              (Loop_Diagnostic
                 (TopoProof.Topology.Loops.Missing_Endpoint));
         when Disconnected_Chain =>
            Record_Failure
              (Loop_Diagnostic
                 (TopoProof.Topology.Loops.Disconnected_Chain));
         when Degenerate_Support =>
            Record_Failure
              (Loop_Diagnostic
                 (TopoProof.Topology.Loops.Degenerate_Support));
      end case;
   end Put_Loop_Native;

   procedure Put_Face_Native (Data : in out HAC_Element_Array) is
   begin
      case To_Face_Kind (Data (1)) is
         when Face_Counter_Clockwise =>
            Put_Line ("face counter_clockwise");
         when Face_Clockwise =>
            Put_Line ("face clockwise");
         when Face_Degenerate_Boundary =>
            Record_Failure
              (Face_Diagnostic
                 (TopoProof.Topology.Faces.Degenerate_Boundary));
         when Face_Invalid_Boundary =>
            Record_Failure
              (Face_Diagnostic
                 (TopoProof.Topology.Faces.Invalid_Boundary));
      end case;
   end Put_Face_Native;

   procedure Register_All (BD : HAC_Sys.Builder.Build_Data) is
   begin
      Register (BD, Translate_Native'Access, "Translate");
      Register (BD, Put_Native'Access, "Put");
      Register (BD, Begin_Image_Native'Access, "Begin_Image");
      Register (BD, Draw_Axes_Native'Access, "Draw_Axes");
      Register (BD, Draw_Point_Native'Access, "Draw_Point");
      Register (BD, Draw_Vector_Native'Access, "Draw_Vector");
      Register (BD, Draw_Point_2D_Native'Access, "Draw_Point_2D");
      Register (BD, Draw_Edge_Native'Access, "Draw_Edge");
      Register (BD, End_Image_Native'Access, "End_Image");
      Register (BD, Add_Point_Native'Access, "Add_Point");
      Register (BD, Make_Loop_Native'Access, "Make_Loop");
      Register (BD, Make_Face_Native'Access, "Make_Face");
      Register (BD, Put_Loop_Native'Access, "Put_Loop");
      Register (BD, Put_Face_Native'Access, "Put_Face");
   end Register_All;

   function Last_Failure return String is
   begin
      return To_String (Failure);
   end Last_Failure;

end TopoScript_API;

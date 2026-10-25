-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with Ada.Containers.Indefinite_Vectors;

with TopoDiagnostics;
with TopoScript_API.Conversions;
with TopoScript_API.Session;

with TopoProof.Geometry.Points;
with TopoProof.Geometry.Segment_Sequences;
with TopoProof.Topology.Edges;
with TopoProof.Topology.Edges_3D;
with TopoProof.Topology.Faces;
with TopoProof.Topology.Faces_3D;
with TopoProof.Topology.Loops;
with TopoProof.Topology.Loops_3D;
with TopoProof.Topology.Vertices;
with TopoProof.Topology.Vertices_3D;

package body TopoScript_API.Topology is

   package Handle_Vectors is new Ada.Containers.Indefinite_Vectors
     (Positive, TopoProof.Topology.Vertices.Vertex_Handle);

   procedure Add_Point_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      P : TopoProof.Geometry.Points.Point_2D;
   begin
      if not Conversions.Read_Point_2D (Data, 1, P) then
         Session.Record_Failure (TopoDiagnostics.Outside_Grid_Diagnostic);
         return;
      end if;
      Session.Current_Session.Chain.Append
        (Chain_Point'(X => P.X, Y => P.Y));
   end Add_Point_Native;

   --  Build the kernel point sequence of the accumulated chain, the
   --  same support as the contour client operations build from their
   --  point chain. A chain longer than the kernel sequence bound
   --  cannot exist on the command line and would require a pathological
   --  script: the rejection is recorded and Built is False, so no
   --  callback raises a constraint error.
   procedure Build_Sequence
     (Seq   :    out TopoProof.Geometry.Segment_Sequences.
        Segment_Sequence_2D;
      Built :    out Boolean)
   is
      N : constant Natural :=
        Natural (Session.Current_Session.Chain.Length);

   begin
      Built := False;
      if N > TopoProof.Geometry.Segment_Sequences.Max_Points then
         Session.Record_Failure
           ("error: too many points for one contour");
         return;
      end if;

      declare
         S : TopoProof.Geometry.Segment_Sequences.Segment_Sequence_2D
           (TopoProof.Geometry.Segment_Sequences.Length_Range (N));

      begin
         for I in 1 .. N loop
            declare
               P : constant Chain_Point :=
                 Session.Current_Session.Chain (I);
            begin
               S.Points (I) :=
                 (X => P.X, Y => P.Y);
            end;
         end loop;
         Seq   := S;
         Built := True;
      end;
   end Build_Sequence;

   procedure Contour_Continuity_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      --  Element layout: Result at 1.
      N : constant Natural :=
        Natural (Session.Current_Session.Chain.Length);

   begin
      --  The segments come by their two endpoints, two chain points
      --  per segment, as in the contour client operation.
      if N mod 2 /= 0 then
         Session.Record_Failure
           ("error: continuity needs an even number of points");
         return;
      end if;

      declare
         Is_Continuous : Boolean := True;

      begin
         for I in 1 .. N / 2 - 1 loop
            if Session.Current_Session.Chain (2 * I)
              /= Session.Current_Session.Chain (2 * I + 1)
            then
               Is_Continuous := False;
            end if;
         end loop;
         Data (1) := Continuity_To_HAC
           ((if Is_Continuous then Continuous else Discontinuous));
      end;
   end Contour_Continuity_Native;

   procedure Contour_Closure_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      --  Element layout: Result at 1.

   begin
      declare
         Seq   : TopoProof.Geometry.Segment_Sequences.
           Segment_Sequence_2D;
         Built : Boolean;

      begin
         Build_Sequence (Seq, Built);
         if not Built then
            return;
         end if;
         Data (1) := Closure_To_HAC
           ((if TopoProof.Geometry.Segment_Sequences.Is_Closed (Seq)
            then Closed
            else Open));
      end;
   end Contour_Closure_Native;

   procedure Contour_Orientation_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      --  Element layout: Result at 1.

   begin
      --  The pre-checks of the contour client operation, with its
      --  diagnostics: the orientation is defined for a closed, valid
      --  sequence of at least three points.
      declare
         Seq   : TopoProof.Geometry.Segment_Sequences.
           Segment_Sequence_2D;
         Built : Boolean;

      begin
         Build_Sequence (Seq, Built);
         if not Built then
            return;
         end if;
         if Seq.Length < 3 then
            Session.Record_Failure
              ("error: at least 3 points required for orientation");
            return;

         elsif not TopoProof.Geometry.Segment_Sequences.Is_Closed (Seq) then
            Session.Record_Failure ("error: sequence is not closed");
            return;

         elsif not TopoProof.Geometry.Segment_Sequences.Is_Valid (Seq) then
            Session.Record_Failure ("error: sequence is not valid");
            return;
         end if;

         case TopoProof.Geometry.Segment_Sequences.Orientation (Seq) is
            when TopoProof.Geometry.Segment_Sequences.Counter_Clockwise =>
               Data (1) := Contour_Orientation_To_HAC
                 (Contour_Counter_Clockwise);
            when TopoProof.Geometry.Segment_Sequences.Clockwise =>
               Data (1) := Contour_Orientation_To_HAC (Contour_Clockwise);
            when TopoProof.Geometry.Segment_Sequences.Degenerate =>
               Data (1) := Contour_Orientation_To_HAC (Contour_Degenerate);
         end case;
      end;
   end Contour_Orientation_Native;

   procedure Contour_Self_Intersects_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      --  Element layout: Result at 1.

   begin
      declare
         Seq   : TopoProof.Geometry.Segment_Sequences.
           Segment_Sequence_2D;
         Built : Boolean;

      begin
         Build_Sequence (Seq, Built);
         if not Built then
            return;
         end if;
         Data (1) := Bool_To_HAC
           ((if TopoProof.Geometry.Segment_Sequences.Self_Intersects (Seq)
            then Bool_True
            else Bool_False));
      end;
   end Contour_Self_Intersects_Native;

   procedure Contour_Valid_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      --  Element layout: Result at 1.

   begin
      declare
         Seq   : TopoProof.Geometry.Segment_Sequences.
           Segment_Sequence_2D;
         Built : Boolean;

      begin
         Build_Sequence (Seq, Built);
         if not Built then
            return;
         end if;
         Data (1) := Bool_To_HAC
           ((if TopoProof.Geometry.Segment_Sequences.Is_Valid (Seq)
            then Bool_True
            else Bool_False));
      end;
   end Contour_Valid_Native;

   procedure Contour_No_Flat_Turns_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      --  Element layout: Result at 1.

   begin
      declare
         Seq   : TopoProof.Geometry.Segment_Sequences.
           Segment_Sequence_2D;
         Built : Boolean;

      begin
         Build_Sequence (Seq, Built);
         if not Built then
            return;
         end if;
         Data (1) := Bool_To_HAC
           ((if TopoProof.Geometry.Segment_Sequences.
              Has_No_Flat_Turns (Seq)
            then Bool_True
            else Bool_False));
      end;
   end Contour_No_Flat_Turns_Native;

   procedure Create_Vertex_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      --  Element layout: P at 1..2, H out at 3.
      P : TopoProof.Geometry.Points.Point_2D;
      H : TopoProof.Topology.Vertices.Vertex_Handle;

   begin
      if not Conversions.Read_Point_2D (Data, 1, P) then
         Session.Record_Failure (TopoDiagnostics.Outside_Grid_Diagnostic);
         return;
      end if;
      --  The store of the run is at the kernel maximum capacity, so
      --  the kernel precondition of Create holds structurally; the
      --  guard keeps the callback total for a pathological script.
      if TopoProof.Topology.Vertices.Vertex_Count
        (Session.Current_Session.Vertices)
        = TopoProof.Topology.Vertices.Max_Vertices
      then
         Session.Record_Failure
           ("error: too many vertices for one store");
         return;
      end if;
      TopoProof.Topology.Vertices.Create
        (Session.Current_Session.Vertices, P, H);
      Data (3) := Conversions.Vertex_Handle_To_HAC (H);
   end Create_Vertex_Native;

   procedure Create_Edge_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      --  Element layout: A at 1, B at 2, E out at 3.
      A, B : TopoProof.Topology.Vertices.Vertex_Handle;
      E    : TopoProof.Topology.Edges.Edge_Handle;

   begin
      if not Conversions.Read_Vertex_Handle (Data, 1, A)
        or else not Conversions.Read_Vertex_Handle (Data, 2, B)
      then
         Session.Record_Failure ("error: invalid vertex handle");
         return;
      end if;
      --  Both endpoints must exist in the vertex store of the run: a
      --  handle is valid only in the store it comes from.
      if not TopoProof.Topology.Vertices.Contains
        (Session.Current_Session.Vertices, A)
        or else not TopoProof.Topology.Vertices.Contains
          (Session.Current_Session.Vertices, B)
      then
         Session.Record_Failure ("error: unknown vertex");
         return;
      end if;
      --  The degeneracy precondition is checked before the call: the
      --  kernel contract is never violated from a script, the same
      --  way as the edge client operation.
      if A = B then
         Session.Record_Failure ("error: degenerate edge");
         return;
      end if;
      if TopoProof.Topology.Edges.Edge_Count (Session.Current_Session.Links)
        = TopoProof.Topology.Edges.Max_Edges
      then
         Session.Record_Failure ("error: too many edges for one store");
         return;
      end if;
      TopoProof.Topology.Edges.Create
        (Session.Current_Session.Links,
         Session.Current_Session.Vertices, A, B, E);
      Data (3) := Conversions.Edge_Handle_To_HAC (E);
   end Create_Edge_Native;

   --  The number of distinct positions of the chain: a repeated
   --  position is one vertex.
   function Distinct_Count
      (Chain : Chain_Vectors.Vector) return Natural
   is
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
     (Chain   :        Chain_Vectors.Vector;
      Store   :    out TopoProof.Topology.Vertices.Vertex_Store;
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
            Session.Record_Failure ("error: degenerate edge");
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
         Session.Record_Failure (TopoDiagnostics.Loop_Diagnostic (Status));
         Valid := False;

      end if;
   end Classify_Chain;

   --  The script loop kind of the orientation of one valid loop: the
   --  kernel contour orientation mapped onto the script kinds.
   function Orientation_Kind_Of
     (Links : TopoProof.Topology.Edges.Edge_Store;
      Store : TopoProof.Topology.Vertices.Vertex_Store;
      L     : TopoProof.Topology.Loops.Loop_2D) return Loop_Kind
   is
   begin
      case TopoProof.Topology.Loops.Loop_Orientation (Links, Store, L) is
         when TopoProof.Geometry.Segment_Sequences.Counter_Clockwise =>
            return Counter_Clockwise;
         when TopoProof.Geometry.Segment_Sequences.Clockwise =>
            return Clockwise;
         when TopoProof.Geometry.Segment_Sequences.Degenerate =>
            return Degenerate;
      end case;
   end Orientation_Kind_Of;

   --  The script loop kind of one rejection: the kernel validity kind
   --  mapped onto the script kinds, so the kind returned to the script
   --  carries the actual classification.
   function Kind_Of
     (Status : TopoProof.Topology.Loops.Loop_Validity) return Loop_Kind
   is
   begin
      case Status is
         when TopoProof.Topology.Loops.Valid_Loop =>
            --  Never reached: a valid loop writes the orientation
            --  kind; the mapping keeps the case total.
            return Open_Chain;
         when TopoProof.Topology.Loops.Orphan_Edge =>
            return Orphan_Edge;
         when TopoProof.Topology.Loops.Missing_Endpoint =>
            return Missing_Endpoint;
         when TopoProof.Topology.Loops.Open_Chain =>
            return Open_Chain;
         when TopoProof.Topology.Loops.Disconnected_Chain =>
            return Disconnected_Chain;
         when TopoProof.Topology.Loops.Degenerate_Support =>
            return Degenerate_Support;
      end case;
   end Kind_Of;

   procedure Make_Loop_From_Edges_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      --  Element layout: Result at 1.
      use type TopoProof.Topology.Loops.Loop_Validity;
      N : constant Natural :=
        TopoProof.Topology.Edges.Edge_Count
          (Session.Current_Session.Links);

   begin
      if N > TopoProof.Topology.Loops.Max_Loop_Length then
         Session.Record_Failure
           ("error: too many edges for one loop");
         Data (1) := Loop_To_HAC (Open_Chain);
         return;
      end if;

      --  The created edges, in creation order: the handles carry the
      --  vertex identity, so the kernel judges the support degeneracy
      --  at loop level, not the edge degeneracy at build level.
      declare
         Handles : TopoProof.Topology.Loops.Edge_Handle_Array (1 .. N);
         Status  : TopoProof.Topology.Loops.Loop_Validity;

      begin
         for I in 1 .. N loop
            Handles (I) := TopoProof.Topology.Edges.Edge_Handle (I);
         end loop;
         Status :=
           TopoProof.Topology.Loops.Classify_Loop
             (Session.Current_Session.Links,
              Session.Current_Session.Vertices, Handles);
         if Status = TopoProof.Topology.Loops.Valid_Loop then
            declare
               L : constant TopoProof.Topology.Loops.Loop_2D :=
                 TopoProof.Topology.Loops.Make_Loop
                   (Session.Current_Session.Links,
                    Session.Current_Session.Vertices, Handles);
            begin
               Data (1) :=
                 Loop_To_HAC
                   (Orientation_Kind_Of
                      (Session.Current_Session.Links,
                       Session.Current_Session.Vertices, L));
            end;

         else
            Session.Record_Failure
              (TopoDiagnostics.Loop_Diagnostic (Status));
            Data (1) := Loop_To_HAC (Kind_Of (Status));
         end if;
      end;
   end Make_Loop_From_Edges_Native;

   --  The chain guards shared by Make_Loop and Make_Face: a chain
   --  needs at least two points, and one loop length of edges at
   --  most. False means the guard failed and the failure is already
   --  recorded; the caller answers with its own default kind.
   function Chain_Accepted return Boolean is
      N : constant Natural :=
        Natural (Session.Current_Session.Chain.Length);
   begin
      if N < 2 then
         Session.Record_Failure
           (TopoDiagnostics.Loop_Diagnostic
              (TopoProof.Topology.Loops.Open_Chain));
         return False;
      end if;
      if N - 1 > TopoProof.Topology.Loops.Max_Loop_Length then
         Session.Record_Failure ("error: too many edges for one loop");
         return False;
      end if;
      return True;
   end Chain_Accepted;

   procedure Make_Loop_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      N : constant Natural :=
        Natural (Session.Current_Session.Chain.Length);
      Kind : Loop_Kind := Open_Chain;

   begin
      if not Chain_Accepted then
         Data (1) := Loop_To_HAC (Kind);
         return;
      end if;

      declare
         Store : TopoProof.Topology.Vertices.Vertex_Store
           (TopoProof.Topology.Vertices.Vertex_Count_Range
              (Distinct_Count (Session.Current_Session.Chain)));
         Links : TopoProof.Topology.Edges.Edge_Store
           (TopoProof.Topology.Edges.Edge_Count_Range (N - 1));
         Handles : TopoProof.Topology.Loops.Edge_Handle_Array (1 .. N - 1);
         OK : Boolean;
         L : TopoProof.Topology.Loops.Loop_2D;
      begin
         Build_Chain (Session.Current_Session.Chain,
                      Store, Links, Handles, OK);
         if not OK then
            Data (1) := Loop_To_HAC (Degenerate_Support);
            return;
         end if;

         Classify_Chain (Links, Store, Handles, L, OK);
         if OK then
            Kind := Orientation_Kind_Of (Links, Store, L);
         end if;
      end;
      Data (1) := Loop_To_HAC (Kind);
   end Make_Loop_Native;

   procedure Make_Face_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      N : constant Natural :=
        Natural (Session.Current_Session.Chain.Length);
      Kind : Face_Kind := Face_Invalid_Boundary;

   begin
      if not Chain_Accepted then
         Data (1) := Face_To_HAC (Kind);
         return;
      end if;

      declare
         Store : TopoProof.Topology.Vertices.Vertex_Store
           (TopoProof.Topology.Vertices.Vertex_Count_Range
              (Distinct_Count (Session.Current_Session.Chain)));
         Links : TopoProof.Topology.Edges.Edge_Store
           (TopoProof.Topology.Edges.Edge_Count_Range (N - 1));
         Handles : TopoProof.Topology.Loops.Edge_Handle_Array (1 .. N - 1);
         OK : Boolean;
         L : TopoProof.Topology.Loops.Loop_2D;
      begin
         Build_Chain (Session.Current_Session.Chain,
                      Store, Links, Handles, OK);
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
                  Session.Record_Failure
                    (TopoDiagnostics.Face_Diagnostic
                       (TopoProof.Topology.Faces.Invalid_Boundary));
               when TopoProof.Topology.Faces.Degenerate_Boundary =>
                  Kind := Face_Degenerate_Boundary;
                  Session.Record_Failure
                    (TopoDiagnostics.Face_Diagnostic
                       (TopoProof.Topology.Faces.Degenerate_Boundary));
            end case;
         end if;
      end;
      Data (1) := Face_To_HAC (Kind);
   end Make_Face_Native;

   --  The three-dimensional constructions (DD-005, increment a): the
   --  same guards as their 2D counterparts, over the 3D stores of the
   --  designated session.
   procedure Create_Vertex_3D_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      --  Element layout: P at 1..3, H out at 4.
      P : TopoProof.Geometry.Points.Point_3D;
      H : TopoProof.Topology.Vertices_3D.Vertex_Handle;

   begin
      if not Conversions.Read_Point_3D (Data, 1, P) then
         Session.Record_Failure (TopoDiagnostics.Outside_Grid_Diagnostic);
         return;
      end if;
      --  The store of the run is at the kernel maximum capacity, so
      --  the kernel precondition of Create holds structurally; the
      --  guard keeps the callback total for a pathological script.
      if TopoProof.Topology.Vertices_3D.Vertex_Count
        (Session.Current_Session.Vertices_3D)
        = TopoProof.Topology.Vertices_3D.Max_Vertices_3D
      then
         Session.Record_Failure
           ("error: too many vertices for one store");
         return;
      end if;
      TopoProof.Topology.Vertices_3D.Create
        (Session.Current_Session.Vertices_3D, P, H);
      Data (4) := Conversions.Vertex_Handle_To_HAC (H);
   end Create_Vertex_3D_Native;

   procedure Create_Edge_3D_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      --  Element layout: A at 1, B at 2, E out at 3.
      A, B : TopoProof.Topology.Vertices_3D.Vertex_Handle;
      E    : TopoProof.Topology.Edges_3D.Edge_Handle;

   begin
      if not Conversions.Read_Vertex_Handle (Data, 1, A)
        or else not Conversions.Read_Vertex_Handle (Data, 2, B)
      then
         Session.Record_Failure ("error: invalid vertex handle");
         return;
      end if;
      --  Both endpoints must exist in the 3D vertex store of the run:
      --  a handle is valid only in the store it comes from.
      if not TopoProof.Topology.Vertices_3D.Contains
        (Session.Current_Session.Vertices_3D, A)
        or else not TopoProof.Topology.Vertices_3D.Contains
          (Session.Current_Session.Vertices_3D, B)
      then
         Session.Record_Failure ("error: unknown vertex");
         return;
      end if;
      --  The degeneracy precondition is checked before the call: the
      --  kernel contract is never violated from a script, the same
      --  way as the edge client operation.
      if A = B then
         Session.Record_Failure ("error: degenerate edge");
         return;
      end if;
      if TopoProof.Topology.Edges_3D.Edge_Count
        (Session.Current_Session.Links_3D)
        = TopoProof.Topology.Edges_3D.Max_Edges_3D
      then
         Session.Record_Failure ("error: too many edges for one store");
         return;
      end if;
      TopoProof.Topology.Edges_3D.Create
        (Session.Current_Session.Links_3D,
         Session.Current_Session.Vertices_3D, A, B, E);
      Data (3) := Conversions.Edge_Handle_To_HAC (E);
   end Create_Edge_3D_Native;

   procedure Make_Face_3D_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      --  Element layout: Kind at 1.
      use type TopoProof.Topology.Loops_3D.Loop_Validity;
      use type TopoProof.Topology.Faces_3D.Face_Validity;
      N : constant Natural :=
        TopoProof.Topology.Edges_3D.Edge_Count
          (Session.Current_Session.Links_3D);
      Kind : Face_3D_Kind := Face3D_Invalid_Boundary;

   begin
      if N > TopoProof.Topology.Loops_3D.Max_Loop_Length then
         Session.Record_Failure
           ("error: too many edges for one loop");
         Data (1) := Face_3D_To_HAC (Kind);
         return;
      end if;

      --  The created edges, in creation order: the handles carry the
      --  vertex identity, so the loop and face classifications judge
      --  the whole boundary the kernel way.
      declare
         Handles : TopoProof.Topology.Loops_3D.Edge_Handle_Array (1 .. N);
         Status  : TopoProof.Topology.Loops_3D.Loop_Validity;

      begin
         for I in 1 .. N loop
            Handles (I) := TopoProof.Topology.Edges_3D.Edge_Handle (I);
         end loop;
         Status :=
           TopoProof.Topology.Loops_3D.Classify_Loop
             (Session.Current_Session.Links_3D,
              Session.Current_Session.Vertices_3D, Handles);
         if Status = TopoProof.Topology.Loops_3D.Valid_Loop then
            declare
               L : constant TopoProof.Topology.Loops_3D.Loop_3D :=
                 TopoProof.Topology.Loops_3D.Make_Loop
                   (Session.Current_Session.Links_3D,
                    Session.Current_Session.Vertices_3D, Handles);
            begin
               case TopoProof.Topology.Faces_3D.Classify_Face
                    (Session.Current_Session.Links_3D,
                     Session.Current_Session.Vertices_3D, L)
               is
                  when TopoProof.Topology.Faces_3D.Valid_Face =>
                     Kind := Face3D_Planar;
                  when TopoProof.Topology.Faces_3D.Invalid_Boundary =>
                     --  A valid loop classifies as a valid boundary:
                     --  kernel contract.
                     Kind := Face3D_Invalid_Boundary;
                  when TopoProof.Topology.Faces_3D.Collinear_Boundary =>
                     Kind := Face3D_Collinear;
                     Session.Record_Failure
                       (TopoDiagnostics.Face_3D_Diagnostic
                          (TopoProof.Topology.Faces_3D.Collinear_Boundary));
                  when TopoProof.Topology.Faces_3D.Non_Planar_Boundary =>
                     Kind := Face3D_Non_Planar;
                     Session.Record_Failure
                       (TopoDiagnostics.Face_3D_Diagnostic
                          (TopoProof.Topology.Faces_3D.Non_Planar_Boundary));
               end case;
            end;

         else
            --  An open chain names its two unlinked vertices: the
            --  vertex the chain ends at, and the starting vertex the
            --  closure would return to. A chain of one edge or more
            --  has both ends; an empty chain has none.
            if Status = TopoProof.Topology.Loops_3D.Open_Chain
              and then N >= 1
            then
               Session.Record_Failure
                 (TopoDiagnostics.Open_Loop_3D_Diagnostic
                    (Chain_End =>
                       TopoProof.Topology.Edges_3D.Endpoints
                         (Session.Current_Session.Links_3D,
                          Handles (N)).To_Vertex,
                     Chain_Start =>
                       TopoProof.Topology.Edges_3D.Endpoints
                         (Session.Current_Session.Links_3D,
                          Handles (1)).From_Vertex));
            else
               Session.Record_Failure
                 (TopoDiagnostics.Loop_3D_Diagnostic (Status));
            end if;
            Kind := Face3D_Invalid_Boundary;
         end if;
      end;
      Data (1) := Face_3D_To_HAC (Kind);
   end Make_Face_3D_Native;

end TopoScript_API.Topology;

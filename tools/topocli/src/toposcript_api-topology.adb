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
with TopoProof.Topology.Shells;
with TopoProof.Topology.Solids;
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

   procedure Move_Vertex_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      V : TopoProof.Topology.Vertices.Vertex_Handle;

      --  The displacement components are read on the widest native
      --  integer first, then checked against the vector domain: an
      --  exception raised inside the HAC virtual machine would not
      --  propagate to the caller.
      function Raw_Component (From : Positive) return Long_Long_Integer is
        (Conversions.To_Long (Data (From)));

      function In_Vector_Domain (R : Long_Long_Integer) return Boolean is
        (R >= Long_Long_Integer (TopoProof.Numerics.Vector_Component'First)
           and then
         R <= Long_Long_Integer (TopoProof.Numerics.Vector_Component'Last));

      DX, DY : TopoProof.Numerics.Vector_Component;
      NP     : TopoProof.Geometry.Points.Point_2D;

   begin
      if not Conversions.Read_Vertex_Handle (Data, 1, V) then
         Session.Record_Failure ("error: invalid vertex handle");
         return;
      end if;
      --  Existence: a handle is valid only in the store it comes from.
      if not TopoProof.Topology.Vertices.Contains
        (Session.Current_Session.Vertices, V)
      then
         Session.Record_Failure ("error: unknown vertex");
         return;
      end if;
      if not In_Vector_Domain (Raw_Component (2))
        or else not In_Vector_Domain (Raw_Component (3))
      then
         Session.Record_Failure
           ("error: the vertex move is not representable");
         return;
      end if;
      DX := TopoProof.Numerics.Vector_Component (Raw_Component (2));
      DY := TopoProof.Numerics.Vector_Component (Raw_Component (3));
      --  The kernel precondition is read before the call: the kernel
      --  contract is never violated from a script, the same way as
      --  the edge client operation. A rejected move records its
      --  diagnostic, writes nothing, and touches no store.
      if not TopoProof.Topology.Vertices.Move_Is_Representable
        (Session.Current_Session.Vertices, V, DX, DY)
      then
         Session.Record_Failure
           ("error: the vertex move is not representable");
         return;
      end if;
      TopoProof.Topology.Vertices.Move
        (Session.Current_Session.Vertices, V, DX, DY, NP);
      Conversions.Write_Point_2D (Data, 4, NP);
   end Move_Vertex_Native;

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
      M : constant Natural := Session.Current_Session.Face_Start;
      Len : constant Natural := N - M + 1;
      Kind : Face_3D_Kind := Face3D_Invalid_Boundary;

   begin
      if Len > TopoProof.Topology.Loops_3D.Max_Loop_Length then
         Session.Record_Failure
           ("error: too many edges for one loop");
         Session.Current_Session.Face_Start := N + 1;
         Data (1) := Face_3D_To_HAC (Kind);
         return;
      end if;

      --  The edges created since the previous face: one candidate
      --  boundary, in creation order. The handles carry the vertex
      --  identity, so the loop and face classifications judge the
      --  whole boundary the kernel way.
      declare
         Handles : TopoProof.Topology.Loops_3D.Edge_Handle_Array (1 .. Len);
         Status  : TopoProof.Topology.Loops_3D.Loop_Validity;

      begin
         for I in 1 .. Len loop
            Handles (I) := TopoProof.Topology.Edges_3D.Edge_Handle (M + I - 1);
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
                     --  The built face joins the shell assembly.
                     Session.Current_Session.Groups.Append
                       (TopoScript_API.Edge_Group'
                          (First => TopoProof.Topology.Edges_3D.Edge_Handle (M),
                           Last  => TopoProof.Topology.Edges_3D.Edge_Handle (N)));
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
              and then Len >= 1
            then
               Session.Record_Failure
                 (TopoDiagnostics.Open_Loop_3D_Diagnostic
                    (Chain_End =>
                       TopoProof.Topology.Edges_3D.Endpoints
                         (Session.Current_Session.Links_3D,
                          Handles (Len)).To_Vertex,
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
      --  The candidate group is consumed either way: a rejected
      --  boundary builds no face and joins no assembly.
      Session.Current_Session.Face_Start := N + 1;
      Data (1) := Face_3D_To_HAC (Kind);
   end Make_Face_3D_Native;



   --  The first face of the assembly whose boundary slice contains the
   --  flattened use U: the faces are ascending and nonempty.
   function Face_Of_Use (S : TopoProof.Topology.Shells.Shell; U : Natural)
      return Natural
   is
   begin
      for K in 1 .. S.Face_Count loop
         if U <= S.Face_Ends (K) then
            return K;
         end if;
      end loop;
      return S.Face_Count;
   end Face_Of_Use;

   --  The diagnostic of the first defect of the assembly: the
   --  classification kind, completed with the face that carries it.
   function Shell_Failure_Message
     (E     : TopoProof.Topology.Edges_3D.Edge_Store;
      V     : TopoProof.Topology.Vertices_3D.Vertex_Store;
      S     : TopoProof.Topology.Shells.Shell;
      Status : TopoProof.Topology.Shells.Shell_Validity) return String
   is
      use type TopoProof.Topology.Loops_3D.Loop_Validity;
   begin
      case Status is
         when TopoProof.Topology.Shells.Closed_Shell =>
            return "";
         when TopoProof.Topology.Shells.Invalid_Boundary =>
            for K in 1 .. S.Face_Count loop
               if not TopoProof.Topology.Shells.Is_Valid_Boundary (E, V, S, K)
               then
                  declare
                     LV : constant TopoProof.Topology.Loops_3D.Loop_Validity :=
                       TopoProof.Topology.Loops_3D.Classify_Loop
                         (E, V,
                          S.Boundary
                            (TopoProof.Topology.Shells.Boundary_First (S, K)
                             .. S.Face_Ends (K)));
                     Full : constant String :=
                       TopoDiagnostics.Loop_3D_Diagnostic (LV);
                  begin
                     --  The loop reason, without its "error: " prefix.
                     return TopoDiagnostics.Shell_Diagnostic
                       (Status, K, Full (9 .. Full'Last));
                  end;
               end if;
            end loop;
            return TopoDiagnostics.Shell_Diagnostic (Status, 1);
         when others =>
            for U in 1 .. S.Edge_Total loop
               declare
                  SC : constant Natural :=
                    TopoProof.Topology.Shells.Same_Support_Count
                      (E, V, S.Boundary, U, 1);
                  OC : constant Natural :=
                    TopoProof.Topology.Shells.Opposite_Support_Count
                      (E, V, S.Boundary, U, 1);
               begin
                  case Status is
                     when TopoProof.Topology.Shells.Overused_Edge =>
                        if SC + OC >= 2 then
                           return TopoDiagnostics.Shell_Diagnostic
                             (Status, Face_Of_Use (S, U));
                        end if;
                     when TopoProof.Topology.Shells.Misaligned_Edge =>
                        if SC = 1 and then OC = 0 then
                           return TopoDiagnostics.Shell_Diagnostic
                             (Status, Face_Of_Use (S, U));
                        end if;
                     when others =>
                        if SC = 0 and then OC = 0 then
                           return TopoDiagnostics.Shell_Diagnostic
                             (Status, Face_Of_Use (S, U));
                        end if;
                  end case;
               end;
            end loop;
            return TopoDiagnostics.Shell_Diagnostic (Status, 1);
      end case;
   end Shell_Failure_Message;

   --  The assembly of the built faces, flattened over the created
   --  edges: the shared construction of Make_Shell_3D and
   --  Make_Solid_3D.
   function Build_Assembly return TopoProof.Topology.Shells.Shell is
      F : constant Natural :=
        Natural (Session.Current_Session.Groups.Length);
      M : constant Natural := Session.Current_Session.Face_Start - 1;
      S : TopoProof.Topology.Shells.Shell (F, M);
      End_Index : Natural := 0;

   begin
      for K in 1 .. F loop
         declare
            G : constant TopoScript_API.Edge_Group :=
              Session.Current_Session.Groups.Element (K);
         begin
            for U in G.First .. G.Last loop
               End_Index := End_Index + 1;
               S.Boundary (End_Index) := U;
            end loop;
            S.Face_Ends (K) := End_Index;
         end;
      end loop;
      return S;
   end Build_Assembly;

   procedure Make_Shell_3D_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      --  Element layout: Kind at 1.
      F : constant Natural :=
        Natural (Session.Current_Session.Groups.Length);
      M : constant Natural := Session.Current_Session.Face_Start - 1;
      Kind : Shell_3D_Kind;

   begin
      if F > TopoProof.Topology.Shells.Max_Shell_Faces
        or else M > TopoProof.Topology.Loops_3D.Max_Loop_Length
      then
         Session.Record_Failure ("error: too many edges for one shell");
         Data (1) := Shell_3D_To_HAC (Shell3D_Invalid_Face);
         return;
      end if;

      declare
         S : constant TopoProof.Topology.Shells.Shell := Build_Assembly;
         Status : TopoProof.Topology.Shells.Shell_Validity;

      begin
         Status :=
           TopoProof.Topology.Shells.Classify_Shell
             (Session.Current_Session.Links_3D,
              Session.Current_Session.Vertices_3D, S);
         case Status is
            when TopoProof.Topology.Shells.Closed_Shell =>
               Kind := Shell3D_Closed;
            when TopoProof.Topology.Shells.Invalid_Boundary =>
               Kind := Shell3D_Invalid_Face;
               Session.Record_Failure
                 (Shell_Failure_Message
                    (Session.Current_Session.Links_3D,
                     Session.Current_Session.Vertices_3D, S, Status));
            when TopoProof.Topology.Shells.Overused_Edge =>
               Kind := Shell3D_Overused;
               Session.Record_Failure
                 (Shell_Failure_Message
                    (Session.Current_Session.Links_3D,
                     Session.Current_Session.Vertices_3D, S, Status));
            when TopoProof.Topology.Shells.Misaligned_Edge =>
               Kind := Shell3D_Misaligned;
               Session.Record_Failure
                 (Shell_Failure_Message
                    (Session.Current_Session.Links_3D,
                     Session.Current_Session.Vertices_3D, S, Status));
            when TopoProof.Topology.Shells.Free_Edge =>
               Kind := Shell3D_Free;
               Session.Record_Failure
                 (Shell_Failure_Message
                    (Session.Current_Session.Links_3D,
                     Session.Current_Session.Vertices_3D, S, Status));
         end case;
      end;
      Data (1) := Shell_3D_To_HAC (Kind);
   end Make_Shell_3D_Native;

   procedure Make_Solid_3D_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      --  Element layout: Kind at 1.
      use type TopoProof.Topology.Solids.Solid_Kind;
      Kind : Solid_3D_Kind;

   begin
      if Natural (Session.Current_Session.Groups.Length)
        > TopoProof.Topology.Shells.Max_Shell_Faces
        or else Session.Current_Session.Face_Start - 1
                > TopoProof.Topology.Loops_3D.Max_Loop_Length
      then
         Session.Record_Failure ("error: too many edges for one shell");
         Data (1) := Solid_3D_To_HAC (Solid3D_Invalid_Shell);
         return;
      end if;

      declare
         S : constant TopoProof.Topology.Shells.Shell := Build_Assembly;
         SV : constant TopoProof.Topology.Shells.Shell_Validity :=
           TopoProof.Topology.Shells.Classify_Shell
             (Session.Current_Session.Links_3D,
              Session.Current_Session.Vertices_3D, S);

      begin
         if SV /= TopoProof.Topology.Shells.Closed_Shell then
            --  The shell gates the solid: the pairing defects are
            --  reported the shell way, and no solid is built.
            case SV is
               when TopoProof.Topology.Shells.Closed_Shell =>
                  null;
               when others =>
                  Session.Record_Failure
                    (Shell_Failure_Message
                       (Session.Current_Session.Links_3D,
                        Session.Current_Session.Vertices_3D, S, SV));
            end case;
            Kind := Solid3D_Invalid_Shell;

         else
            case TopoProof.Topology.Solids.Classify_Solid
                 (Session.Current_Session.Links_3D,
                  Session.Current_Session.Vertices_3D, S)
            is
               when TopoProof.Topology.Solids.Outward_Solid =>
                  Kind := Solid3D_Outward;
               when TopoProof.Topology.Solids.Inward_Solid =>
                  Kind := Solid3D_Inward;
               when TopoProof.Topology.Solids.Flat_Assembly =>
                  Kind := Solid3D_Flat;
                  Session.Record_Failure ("error: flat shell");
            end case;
         end if;
      end;
      Data (1) := Solid_3D_To_HAC (Kind);
   end Make_Solid_3D_Native;


   --  ----------------------------------------------------------------
   --  The human-level solid primitives (DD-006, increments b and c):
   --  Box builds the whole boundary of a solid value in one call,
   --  Move copies one solid value, every vertex moved by the same
   --  vector, Difference subtracts one axis-aligned box from another
   --  (DD-006, decision 4). All run the exact classification gates
   --  over the shared 3D stores of the run: a rejected construction
   --  records its diagnostic and yields the absent solid. A built
   --  value stays valid for the whole run, like every handle of the
   --  model, and the stored edge chain of a value is never touched
   --  again: the stores are append-only.

   --  The shared construction of an axis-aligned box value (DD-006,
   --  decisions 2 and 4): the eight corners between (X1, Y1, Z1) and
   --  (X2, Y2, Z2), the twelve edges, the six faces wound
   --  counter-clockwise seen from outside, in the verified edge
   --  pattern of the box-solid scenario. The caller checked the
   --  positive extents and the capacity; the vertices and edges
   --  created here are consumed by the assembly's own boundary, so
   --  the caller sets Face_Start after its last call.
   procedure Build_Box
     (X1, Y1, Z1, X2, Y2, Z2 : Long_Long_Integer;
      S                      :    out TopoProof.Topology.Shells.Shell)
   with Pre => S.Face_Count = 6 and then S.Edge_Total = 24
   is
      procedure Corner
        (X, Y, Z : Long_Long_Integer;
         V       :    out TopoProof.Topology.Vertices_3D.Vertex_Handle)
      is
         P : TopoProof.Geometry.Points.Point_3D;
      begin
         P := (X => TopoProof.Numerics.Grid_Coordinate (X),
               Y => TopoProof.Numerics.Grid_Coordinate (Y),
               Z => TopoProof.Numerics.Grid_Coordinate (Z));
         TopoProof.Topology.Vertices_3D.Create
           (Session.Current_Session.Vertices_3D, P, V);
      end Corner;

      procedure Edge
        (A, B : TopoProof.Topology.Vertices_3D.Vertex_Handle;
         E    :    out TopoProof.Topology.Edges_3D.Edge_Handle)
      is
      begin
         TopoProof.Topology.Edges_3D.Create
           (Session.Current_Session.Links_3D,
            Session.Current_Session.Vertices_3D, A, B, E);
      end Edge;

      HA, HB, HC, HD, HE, HF, HG, HH :
        TopoProof.Topology.Vertices_3D.Vertex_Handle;
      E1, E2, E3, E4 : TopoProof.Topology.Edges_3D.Edge_Handle;

      --  The edge handles of this call are consecutive from the count
      --  taken before the first corner.
      First_Edge : constant Natural :=
        TopoProof.Topology.Edges_3D.Edge_Count
          (Session.Current_Session.Links_3D);

   begin
      Corner (X1, Y1, Z1, HA);
      Corner (X2, Y1, Z1, HB);
      Corner (X2, Y2, Z1, HC);
      Corner (X1, Y2, Z1, HD);
      Corner (X1, Y1, Z2, HE);
      Corner (X2, Y1, Z2, HF);
      Corner (X2, Y2, Z2, HG);
      Corner (X1, Y2, Z2, HH);

      Edge (HD, HC, E1);
      Edge (HC, HB, E2);
      Edge (HB, HA, E3);
      Edge (HA, HD, E4);
      Edge (HE, HF, E1);
      Edge (HF, HG, E2);
      Edge (HG, HH, E3);
      Edge (HH, HE, E4);
      Edge (HB, HF, E1);
      Edge (HF, HE, E2);
      Edge (HE, HA, E3);
      Edge (HA, HB, E4);
      Edge (HB, HC, E1);
      Edge (HC, HG, E2);
      Edge (HG, HF, E3);
      Edge (HF, HB, E4);
      Edge (HC, HD, E1);
      Edge (HD, HH, E2);
      Edge (HH, HG, E3);
      Edge (HG, HC, E4);
      Edge (HD, HA, E1);
      Edge (HA, HE, E2);
      Edge (HE, HH, E3);
      Edge (HH, HD, E4);

      --  The boundary list of the assembled value, in creation order:
      --  the edge handles of this call are consecutive from the count
      --  taken before the first corner, and each face range is the
      --  four-use block of the call.
      for K in 1 .. 6 loop
         for U in 1 .. 4 loop
            S.Boundary (4 * (K - 1) + U) :=
              TopoProof.Topology.Edges_3D.Edge_Handle
                (First_Edge + 4 * (K - 1) + U);
         end loop;
         S.Face_Ends (K) := 4 * K;
      end loop;
   end Build_Box;

   procedure Box_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      --  Element layout: Width at 1, Depth at 2, Height at 3, Result
      --  out at 4. The box of the origin corner: its dimensions count
      --  in grid units; once positive and within the grid domain,
      --  the whole box stays on the grid and every face is a
      --  non-degenerate rectangle, exact by construction.
      use type TopoProof.Topology.Solids.Solid_Kind;

      Grid_Last : constant Long_Long_Integer :=
        Long_Long_Integer (TopoProof.Numerics.Grid_Coordinate'Last);

      W : constant Long_Long_Integer := Conversions.To_Long (Data (1));
      D : constant Long_Long_Integer := Conversions.To_Long (Data (2));
      H : constant Long_Long_Integer := Conversions.To_Long (Data (3));

      Old_Edges : constant Natural :=
        TopoProof.Topology.Edges_3D.Edge_Count
          (Session.Current_Session.Links_3D);
      Old_Vertices : constant Natural :=
        TopoProof.Topology.Vertices_3D.Vertex_Count
          (Session.Current_Session.Vertices_3D);

      --  The shell of the built value: 24 uses over the 12 edges of
      --  this call, six faces of four uses each. The edge handles are
      --  consecutive in creation order, so the six face ranges are
      --  the four-use blocks of the call.
      S  : TopoProof.Topology.Shells.Shell (6, 24);
      SV : TopoProof.Topology.Shells.Shell_Validity;
      SK : TopoProof.Topology.Solids.Solid_Kind;

   begin
      if W < 1 or else D < 1 or else H < 1
        or else W > Grid_Last or else D > Grid_Last or else H > Grid_Last
      then
         Session.Record_Failure ("error: invalid box dimensions");
         Conversions.Write_Solid_Handle (Data, 4, TopoScript_API.No_Solid);
         return;
      end if;

      if Old_Vertices + 8 > TopoProof.Topology.Vertices_3D.Max_Vertices_3D
        or else Old_Edges + 24 > TopoProof.Topology.Edges_3D.Max_Edges_3D
      then
         Session.Record_Failure ("error: too many edges for one solid");
         Conversions.Write_Solid_Handle (Data, 4, TopoScript_API.No_Solid);
         return;
      end if;

      Build_Box (0, 0, 0, W, D, H, S);

      SV :=
        TopoProof.Topology.Shells.Classify_Shell
          (Session.Current_Session.Links_3D,
           Session.Current_Session.Vertices_3D, S);

      if SV /= TopoProof.Topology.Shells.Closed_Shell then
         --  The classification gate runs on the built value; a
         --  rejection here would be a construction defect, reported
         --  the shell way.
         Session.Record_Failure ("error: the box boundary is not closed");
         Conversions.Write_Solid_Handle (Data, 4, TopoScript_API.No_Solid);
         return;
      end if;

      SK :=
        TopoProof.Topology.Solids.Classify_Solid
          (Session.Current_Session.Links_3D,
           Session.Current_Session.Vertices_3D, S);

      if SK = TopoProof.Topology.Solids.Flat_Assembly then
         --  A box of positive dimensions encloses something exact: a
         --  flat assembly here would be a construction defect.
         Session.Record_Failure ("error: flat shell");
         Conversions.Write_Solid_Handle (Data, 4, TopoScript_API.No_Solid);
         return;
      end if;

      Session.Current_Session.Solids.Append (S);
      --  The edges of the call are consumed by its own boundary: a
      --  later Make_Face_3D of the same script starts a new face after
      --  them.
      Session.Current_Session.Face_Start := Old_Edges + 25;

      Conversions.Write_Solid_Handle
        (Data, 4,
         TopoScript_API.Solid_Handle_Kind
           (Natural (Session.Current_Session.Solids.Length)));
   end Box_Native;


   procedure Move_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      --  Element layout: solid handle S at 1, X at 2, Y at 3, Z at 4,
      --  Result out at 5.
      use type TopoProof.Topology.Solids.Solid_Kind;
      use type TopoProof.Numerics.Grid_Coordinate;

      H : TopoScript_API.Solid_Handle_Kind;
      DX, DY, DZ : Long_Long_Integer;
      Grid_First : constant Long_Long_Integer :=
        Long_Long_Integer (TopoProof.Numerics.Grid_Coordinate'First);
      Grid_Last  : constant Long_Long_Integer :=
        Long_Long_Integer (TopoProof.Numerics.Grid_Coordinate'Last);

      Source : TopoProof.Topology.Shells.Shell;

      Old_Edges : constant Natural :=
        TopoProof.Topology.Edges_3D.Edge_Count
          (Session.Current_Session.Links_3D);
      Old_Vertices : constant Natural :=
        TopoProof.Topology.Vertices_3D.Vertex_Count
          (Session.Current_Session.Vertices_3D);

      --  One moved copy per distinct source vertex: Seen marks the
      --  source vertices visited by the check pass, Map carries the
      --  handle of the created moved copy, zero when not created.
      Seen : array (1 .. TopoProof.Topology.Vertices_3D.Max_Vertices_3D)
        of Boolean := [others => False];
      Map : array (1 .. TopoProof.Topology.Vertices_3D.Max_Vertices_3D)
        of Natural := [others => 0];

      Rejected : Boolean := False;
      E : TopoProof.Topology.Edges_3D.Edge_Handle;

      --  The check pass, before any creation: the moved position of
      --  the source vertex V stays in the grid domain, so a rejected
      --  move leaves no half-moved copy behind; the mark also counts
      --  the distinct source vertices, one moved copy each.
      procedure Check_Vertex
        (V : TopoProof.Topology.Vertices_3D.Vertex_Handle)
      is
         P : TopoProof.Geometry.Points.Point_3D;
      begin
         if Seen (V) then
            return;
         end if;
         P :=
           TopoProof.Topology.Vertices_3D.Point_Of
             (Session.Current_Session.Vertices_3D, V);
         Seen (V) := True;
         if Grid_First
              > Long_Long_Integer (P.X) + DX
            or else Long_Long_Integer (P.X) + DX > Grid_Last
            or else Grid_First
                     > Long_Long_Integer (P.Y) + DY
                 or else Long_Long_Integer (P.Y) + DY > Grid_Last
            or else Grid_First
                     > Long_Long_Integer (P.Z) + DZ
                 or else Long_Long_Integer (P.Z) + DZ > Grid_Last
         then
            Rejected := True;
         end if;
      end Check_Vertex;

   begin
      if not Conversions.Read_Solid_Handle (Data, 1, H)
        or else H = TopoScript_API.No_Solid
        or else Natural (H)
                > Natural (Session.Current_Session.Solids.Length)
      then
         Session.Record_Failure ("error: unknown solid");
         Conversions.Write_Solid_Handle (Data, 5, TopoScript_API.No_Solid);
         return;
      end if;

      DX := Conversions.To_Long (Data (2));
      DY := Conversions.To_Long (Data (3));
      DZ := Conversions.To_Long (Data (4));

      Source := Session.Current_Session.Solids.Element (Natural (H));

      for U in 1 .. Source.Edge_Total loop
         declare
            Pair : constant TopoProof.Topology.Edges_3D.Vertex_Handle_Pair :=
              TopoProof.Topology.Edges_3D.Endpoints
                (Session.Current_Session.Links_3D, Source.Boundary (U));
         begin
            Check_Vertex (Pair.From_Vertex);
            exit when Rejected;
            Check_Vertex (Pair.To_Vertex);
            exit when Rejected;
         end;
      end loop;

      if Rejected then
         Session.Record_Failure ("error: the moved solid leaves the grid");
         Conversions.Write_Solid_Handle (Data, 5, TopoScript_API.No_Solid);
         return;
      end if;

      --  The capacity of the copy: one new vertex per distinct source
      --  vertex, one new edge per use.
      declare
         Distinct : Natural := 0;
      begin
         for V in 1 .. TopoProof.Topology.Vertices_3D.Max_Vertices_3D loop
            if Seen (V) then
               Distinct := Distinct + 1;
            end if;
         end loop;

         if Distinct + Old_Vertices
              > TopoProof.Topology.Vertices_3D.Max_Vertices_3D
           or else Natural (Source.Edge_Total) + Old_Edges
              > TopoProof.Topology.Edges_3D.Max_Edges_3D
         then
            Session.Record_Failure ("error: too many edges for one solid");
            Conversions.Write_Solid_Handle
              (Data, 5, TopoScript_API.No_Solid);
            return;
         end if;
      end;

      --  The moved copy: one new vertex per distinct source vertex,
      --  then one new edge per use, in the source boundary order; the
      --  pairing is preserved structurally.
      declare
         Target : TopoProof.Topology.Shells.Shell
           (Source.Face_Count, Source.Edge_Total);
         Index  : Natural := 0;

         function Moved
           (V : TopoProof.Topology.Vertices_3D.Vertex_Handle)
            return TopoProof.Geometry.Points.Point_3D
         is
            P : constant TopoProof.Geometry.Points.Point_3D :=
              TopoProof.Topology.Vertices_3D.Point_Of
                (Session.Current_Session.Vertices_3D, V);
         begin
            return
              (X => P.X + TopoProof.Numerics.Grid_Coordinate (DX),
               Y => P.Y + TopoProof.Numerics.Grid_Coordinate (DY),
               Z => P.Z + TopoProof.Numerics.Grid_Coordinate (DZ));
         end Moved;

         function Moved_Copy
           (V : TopoProof.Topology.Vertices_3D.Vertex_Handle)
            return TopoProof.Topology.Vertices_3D.Vertex_Handle
         is
            VV : TopoProof.Topology.Vertices_3D.Vertex_Handle;
         begin
            if Map (V) = 0 then
               TopoProof.Topology.Vertices_3D.Create
                 (Session.Current_Session.Vertices_3D, Moved (V), VV);
               Map (V) := VV;
            end if;
            return TopoProof.Topology.Vertices_3D.Vertex_Handle (Map (V));
         end Moved_Copy;

         Status : TopoProof.Topology.Shells.Shell_Validity;
         SK     : TopoProof.Topology.Solids.Solid_Kind;

      begin
         for K in 1 .. Source.Face_Count loop
            for U in
              (if K = 1 then 1
               else Source.Face_Ends (K - 1) + 1) .. Source.Face_Ends (K)
            loop
               declare
                  Pair : constant TopoProof.Topology.Edges_3D.
                           Vertex_Handle_Pair :=
                    TopoProof.Topology.Edges_3D.Endpoints
                      (Session.Current_Session.Links_3D,
                       Source.Boundary (U));
               begin
                  TopoProof.Topology.Edges_3D.Create
                    (Session.Current_Session.Links_3D,
                     Session.Current_Session.Vertices_3D,
                     Moved_Copy (Pair.From_Vertex),
                     Moved_Copy (Pair.To_Vertex), E);
                  Index := Index + 1;
                  Target.Boundary (Index) := E;
               end;
            end loop;
            Target.Face_Ends (K) := Index;
         end loop;

         Status :=
           TopoProof.Topology.Shells.Classify_Shell
             (Session.Current_Session.Links_3D,
              Session.Current_Session.Vertices_3D, Target);

         if Status /= TopoProof.Topology.Shells.Closed_Shell then
            --  The pairing is preserved structurally; a rejection here
            --  would be a construction defect, reported the shell way.
            Session.Record_Failure
              ("error: the moved boundary is not closed");
            Conversions.Write_Solid_Handle
              (Data, 5, TopoScript_API.No_Solid);
            return;
         end if;

         SK :=
           TopoProof.Topology.Solids.Classify_Solid
             (Session.Current_Session.Links_3D,
              Session.Current_Session.Vertices_3D, Target);

         if SK = TopoProof.Topology.Solids.Flat_Assembly then
            Session.Record_Failure ("error: flat shell");
            Conversions.Write_Solid_Handle
              (Data, 5, TopoScript_API.No_Solid);
            return;
         end if;

         Session.Current_Session.Solids.Append (Target);
         --  The edges of the copy are consumed by its own boundary.
         Session.Current_Session.Face_Start :=
           Old_Edges + Natural (Source.Edge_Total) + 1;

         Conversions.Write_Solid_Handle
           (Data, 5,
            TopoScript_API.Solid_Handle_Kind
              (Natural (Session.Current_Session.Solids.Length)));
      end;
   end Move_Native;



   --  ----------------------------------------------------------------
   --  The exact difference of two axis-aligned box values (DD-006,
   --  decision 4, increment d): the first box minus the second, as
   --  the exact set subtraction of two grid prisms. Either no
   --  positive-volume overlap - the difference is the first box,
   --  unchanged - or a full covering - nothing, reported and never
   --  built - or a decomposition into at most six axis-aligned boxes
   --  over the clipped extents of the second box: the bottom and top
   --  slabs over the full cross-section of the first box, then the
   --  front and back slabs over the clipped depth, then the left and
   --  right slabs over the clipped height. Every piece is built by
   --  the same construction as Box and runs the exact classification
   --  gates, so every piece stays exactly classifiable; the pieces
   --  live in the scripting layer as a compound (a list of solid
   --  handles, the kernel model stays the one shell of DD-005).

   --  The exact extents of one box value, and the input gate of the
   --  Difference: a stored solid value is an axis-aligned box when
   --  six faces of four uses each carry exactly eight distinct
   --  vertices, each on a corner of the bounding box (each coordinate
   --  at the lower or the upper end on each axis). A closed shell
   --  with that boundary is exactly the prism of those extents, so
   --  the exact decomposition below is exact on it.
   type Extents is record
      X1, Y1, Z1, X2, Y2, Z2 : Long_Long_Integer;
   end record;

   function Is_Axis_Box
     (S :        TopoProof.Topology.Shells.Shell;
      E :    out Extents)
      return Boolean
   is
      function Point_Of
        (V : TopoProof.Topology.Vertices_3D.Vertex_Handle)
         return TopoProof.Geometry.Points.Point_3D
      is
      begin
         return TopoProof.Topology.Vertices_3D.Point_Of
           (Session.Current_Session.Vertices_3D, V);
      end Point_Of;

      --  The corner of the bounding box each vertex sits on: eight
      --  distinct vertices on box corners carry exactly the eight
      --  corner codes 0 .. 7.
      Corner : array (1 .. TopoProof.Topology.Vertices_3D.Max_Vertices_3D)
        of Natural := [others => 0];
      Distinct : Natural := 0;
      Failed   : Boolean := False;

      First : Boolean := True;
      Min_X, Max_X, Min_Y, Max_Y, Min_Z, Max_Z : Long_Long_Integer;

   begin
      E := (0, 0, 0, 0, 0, 0);

      --  The structure of a box value: six faces of four uses each.
      if S.Face_Count /= 6 or else S.Edge_Total /= 24 then
         return False;
      end if;
      for K in 1 .. 6 loop
         if S.Face_Ends (K) /= 4 * K then
            return False;
         end if;
      end loop;

      --  The bounding box, over the endpoints of every use.
      for U in 1 .. S.Edge_Total loop
         declare
            Pair : constant TopoProof.Topology.Edges_3D.
                     Vertex_Handle_Pair :=
               TopoProof.Topology.Edges_3D.Endpoints
                 (Session.Current_Session.Links_3D, S.Boundary (U));

            procedure Collect
              (V : TopoProof.Topology.Vertices_3D.Vertex_Handle)
            is
               P : constant TopoProof.Geometry.Points.Point_3D :=
                 Point_Of (V);
               X : constant Long_Long_Integer := Long_Long_Integer (P.X);
               Y : constant Long_Long_Integer := Long_Long_Integer (P.Y);
               Z : constant Long_Long_Integer := Long_Long_Integer (P.Z);
            begin
               if First then
                  Min_X := X; Max_X := X;
                  Min_Y := Y; Max_Y := Y;
                  Min_Z := Z; Max_Z := Z;
                  First := False;
               else
                  Min_X := Long_Long_Integer'Min (Min_X, X);
                  Max_X := Long_Long_Integer'Max (Max_X, X);
                  Min_Y := Long_Long_Integer'Min (Min_Y, Y);
                  Max_Y := Long_Long_Integer'Max (Max_Y, Y);
                  Min_Z := Long_Long_Integer'Min (Min_Z, Z);
                  Max_Z := Long_Long_Integer'Max (Max_Z, Z);
               end if;
            end Collect;

         begin
            Collect (Pair.From_Vertex);
            Collect (Pair.To_Vertex);
         end;
      end loop;

      --  Every vertex on a box corner, eight distinct vertices.
      for U in 1 .. S.Edge_Total loop
         declare
            Pair : constant TopoProof.Topology.Edges_3D.
                     Vertex_Handle_Pair :=
               TopoProof.Topology.Edges_3D.Endpoints
                 (Session.Current_Session.Links_3D, S.Boundary (U));

            procedure Corner_Of
              (V : TopoProof.Topology.Vertices_3D.Vertex_Handle)
            is
               P : constant TopoProof.Geometry.Points.Point_3D :=
                 Point_Of (V);
               X : constant Long_Long_Integer := Long_Long_Integer (P.X);
               Y : constant Long_Long_Integer := Long_Long_Integer (P.Y);
               Z : constant Long_Long_Integer := Long_Long_Integer (P.Z);
            begin
               if (X /= Min_X and then X /= Max_X)
                 or else (Y /= Min_Y and then Y /= Max_Y)
                 or else (Z /= Min_Z and then Z /= Max_Z)
               then
                  Failed := True;
               elsif Corner (V) = 0 then
                  Distinct := Distinct + 1;
                  Corner (V) :=
                    (if X = Max_X then 1 else 0)
                    + (if Y = Max_Y then 2 else 0)
                    + (if Z = Max_Z then 4 else 0)
                    + 1;
               end if;
            end Corner_Of;

         begin
            Corner_Of (Pair.From_Vertex);
            Corner_Of (Pair.To_Vertex);
         end;
      end loop;

      if Failed or else Distinct /= 8 then
         return False;
      end if;

      E := (X1 => Min_X, Y1 => Min_Y, Z1 => Min_Z,
            X2 => Max_X, Y2 => Max_Y, Z2 => Max_Z);
      return True;
   end Is_Axis_Box;

   procedure Difference_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      --  Element layout: box A at 1, box B at 2, piece count out at 3.
      use type TopoProof.Topology.Solids.Solid_Kind;

      A, B   : TopoScript_API.Solid_Handle_Kind;
      EA, EB : Extents;

      Old_Edges : constant Natural :=
        TopoProof.Topology.Edges_3D.Edge_Count
          (Session.Current_Session.Links_3D);
      Old_Vertices : constant Natural :=
        TopoProof.Topology.Vertices_3D.Vertex_Count
          (Session.Current_Session.Vertices_3D);

      Count : Natural := 0;

      --  One piece of the decomposition, built only on positive
      --  extents, classified exactly, appended to the solid store and
      --  to the compound (DD-006, decision 4). The extents of every
      --  piece are inside the extents of the first box, whose
      --  vertices are on the grid, so every piece stays on the grid.
      procedure Build_Piece
        (X1, Y1, Z1, X2, Y2, Z2 : Long_Long_Integer)
      is
         S  : TopoProof.Topology.Shells.Shell (6, 24);
         SV : TopoProof.Topology.Shells.Shell_Validity;
         SK : TopoProof.Topology.Solids.Solid_Kind;

      begin
         if X1 >= X2 or else Y1 >= Y2 or else Z1 >= Z2 then
            return;
         end if;

         Build_Box (X1, Y1, Z1, X2, Y2, Z2, S);

         SV :=
           TopoProof.Topology.Shells.Classify_Shell
             (Session.Current_Session.Links_3D,
              Session.Current_Session.Vertices_3D, S);
         if SV /= TopoProof.Topology.Shells.Closed_Shell then
            --  A rejection here would be a construction defect,
            --  reported the shell way.
            Session.Record_Failure
              ("error: the difference piece is not closed");
            return;
         end if;

         SK :=
           TopoProof.Topology.Solids.Classify_Solid
             (Session.Current_Session.Links_3D,
              Session.Current_Session.Vertices_3D, S);
         if SK = TopoProof.Topology.Solids.Flat_Assembly then
            --  A piece of positive extents encloses something exact.
            Session.Record_Failure ("error: flat shell");
            return;
         end if;

         Session.Current_Session.Solids.Append (S);
         Count := Count + 1;
         Session.Current_Session.Compound.Append
           (TopoScript_API.Solid_Handle_Kind
              (Natural (Session.Current_Session.Solids.Length)));
      end Build_Piece;

   begin
      if not Conversions.Read_Solid_Handle (Data, 1, A)
        or else A = TopoScript_API.No_Solid
        or else Natural (A)
                > Natural (Session.Current_Session.Solids.Length)
        or else not Conversions.Read_Solid_Handle (Data, 2, B)
        or else B = TopoScript_API.No_Solid
        or else Natural (B)
                > Natural (Session.Current_Session.Solids.Length)
      then
         Session.Record_Failure ("error: unknown solid");
         Conversions.Write_Count (Data, 3, 0);
         return;
      end if;

      Session.Current_Session.Compound.Clear;

      if not Is_Axis_Box
               (Session.Current_Session.Solids.Element (Natural (A)), EA)
        or else not Is_Axis_Box
               (Session.Current_Session.Solids.Element (Natural (B)), EB)
      then
         Session.Record_Failure
           ("error: the difference needs axis-aligned box values");
         Conversions.Write_Count (Data, 3, 0);
         return;
      end if;

      --  Six pieces at most, one value each: eight vertices and
      --  twenty-four uses per piece.
      if Old_Vertices + 48
             > TopoProof.Topology.Vertices_3D.Max_Vertices_3D
        or else Old_Edges + 144
             > TopoProof.Topology.Edges_3D.Max_Edges_3D
      then
         Session.Record_Failure ("error: too many edges for one solid");
         Conversions.Write_Count (Data, 3, 0);
         return;
      end if;

      --  The positive-volume overlap of the two boxes.
      declare
         CX1 : constant Long_Long_Integer :=
           Long_Long_Integer'Max (EA.X1, EB.X1);
         CX2 : constant Long_Long_Integer :=
           Long_Long_Integer'Min (EA.X2, EB.X2);
         CY1 : constant Long_Long_Integer :=
           Long_Long_Integer'Max (EA.Y1, EB.Y1);
         CY2 : constant Long_Long_Integer :=
           Long_Long_Integer'Min (EA.Y2, EB.Y2);
         CZ1 : constant Long_Long_Integer :=
           Long_Long_Integer'Max (EA.Z1, EB.Z1);
         CZ2 : constant Long_Long_Integer :=
           Long_Long_Integer'Min (EA.Z2, EB.Z2);

         Overlap : constant Boolean :=
           CX1 < CX2 and then CY1 < CY2 and then CZ1 < CZ2;

         Covered : constant Boolean :=
           EA.X1 >= EB.X1 and then EA.X2 <= EB.X2
           and then EA.Y1 >= EB.Y1 and then EA.Y2 <= EB.Y2
           and then EA.Z1 >= EB.Z1 and then EA.Z2 <= EB.Z2;

      begin
         if not Overlap then
            --  The difference is the first box itself, its stored
            --  value unchanged: the compound carries its handle.
            Session.Current_Session.Compound.Append (A);
            Conversions.Write_Count (Data, 3, 1);
            return;
         end if;

         if Covered then
            Session.Record_Failure
              ("error: the difference encloses nothing");
            Conversions.Write_Count (Data, 3, 0);
            return;
         end if;

         --  The decomposition: bottom and top slabs of the clipped
         --  box over the full cross-section of the first box, then
         --  front and back slabs over the clipped depth, then left
         --  and right slabs over the clipped height, in this order.
         Build_Piece (EA.X1, EA.Y1, EA.Z1, EA.X2, EA.Y2, CZ1);
         Build_Piece (EA.X1, EA.Y1, CZ2, EA.X2, EA.Y2, EA.Z2);
         Build_Piece (EA.X1, EA.Y1, CZ1, EA.X2, CY1, CZ2);
         Build_Piece (EA.X1, CY2, CZ1, EA.X2, EA.Y2, CZ2);
         Build_Piece (EA.X1, CY1, CZ1, CX1, CY2, CZ2);
         Build_Piece (CX2, CY1, CZ1, EA.X2, CY2, CZ2);

         --  Every edge created for the pieces is consumed by their
         --  own boundary.
         Session.Current_Session.Face_Start :=
           TopoProof.Topology.Edges_3D.Edge_Count
             (Session.Current_Session.Links_3D) + 1;

         Conversions.Write_Count (Data, 3, Count);
      end;
   end Difference_Native;

   procedure Piece_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      --  Element layout: piece index K at 1, handle out at 2.
      K : Natural;

   begin
      if not Conversions.Read_Count (Data, 1, K)
        or else K = 0
        or else K > Natural (Session.Current_Session.Compound.Length)
      then
         Session.Record_Failure ("error: unknown piece");
         Conversions.Write_Solid_Handle (Data, 2, TopoScript_API.No_Solid);
         return;
      end if;

      Conversions.Write_Solid_Handle
        (Data, 2, Session.Current_Session.Compound.Element (K));
   end Piece_Native;

   --  Native side of Solid_Bounds: the exact grid bounds of one solid
   --  value of the designated session: the min and max of every vertex
   --  coordinate over all the edge uses of the stored assembly, written
   --  into the two out points (DD-006, the position read-out named by
   --  the moved-solid review: the classification alone does not say
   --  where the value sits, and a moved-box check must see it).
   procedure Solid_Bounds_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      --  Element layout: solid handle S at 1, Min out at 2, Max out at
      --  5 (three grid components each).
      H : TopoScript_API.Solid_Handle_Kind;

      Source : TopoProof.Topology.Shells.Shell;

      Grid_First : constant Long_Long_Integer :=
        Long_Long_Integer (TopoProof.Numerics.Grid_Coordinate'First);
      Grid_Last  : constant Long_Long_Integer :=
        Long_Long_Integer (TopoProof.Numerics.Grid_Coordinate'Last);

      --  Seed bounds: any real vertex tightens them (the solid values
      --  are built inside the grid domain, so the seed never survives
      --  on a nonempty solid).
      Min_X, Min_Y, Min_Z : Long_Long_Integer := Grid_Last;
      Max_X, Max_Y, Max_Z : Long_Long_Integer := Grid_First;

      Seen : array (1 .. TopoProof.Topology.Vertices_3D.Max_Vertices_3D)
        of Boolean := [others => False];

      --  The bounds pass, min and max per axis on each distinct vertex.
      procedure Track_Vertex
        (V : TopoProof.Topology.Vertices_3D.Vertex_Handle)
      is
         P : TopoProof.Geometry.Points.Point_3D;
      begin
         if Seen (V) then
            return;
         end if;
         P :=
           TopoProof.Topology.Vertices_3D.Point_Of
             (Session.Current_Session.Vertices_3D, V);
         Seen (V) := True;

         if Min_X > Long_Long_Integer (P.X) then
            Min_X := Long_Long_Integer (P.X);
         end if;
         if Max_X < Long_Long_Integer (P.X) then
            Max_X := Long_Long_Integer (P.X);
         end if;
         if Min_Y > Long_Long_Integer (P.Y) then
            Min_Y := Long_Long_Integer (P.Y);
         end if;
         if Max_Y < Long_Long_Integer (P.Y) then
            Max_Y := Long_Long_Integer (P.Y);
         end if;
         if Min_Z > Long_Long_Integer (P.Z) then
            Min_Z := Long_Long_Integer (P.Z);
         end if;
         if Max_Z < Long_Long_Integer (P.Z) then
            Max_Z := Long_Long_Integer (P.Z);
         end if;
      end Track_Vertex;

   begin
      if not Conversions.Read_Solid_Handle (Data, 1, H)
        or else H = TopoScript_API.No_Solid
        or else Natural (H)
                > Natural (Session.Current_Session.Solids.Length)
      then
         Session.Record_Failure ("error: unknown solid");
         Conversions.Write_Point_3D
           (Data, 2, (X => 0, Y => 0, Z => 0));
         Conversions.Write_Point_3D
           (Data, 5, (X => 0, Y => 0, Z => 0));
         return;
      end if;

      Source := Session.Current_Session.Solids.Element (Natural (H));

      for U in 1 .. Source.Edge_Total loop
         declare
            Pair : constant TopoProof.Topology.Edges_3D.Vertex_Handle_Pair :=
              TopoProof.Topology.Edges_3D.Endpoints
                (Session.Current_Session.Links_3D, Source.Boundary (U));
         begin
            Track_Vertex (Pair.From_Vertex);
            Track_Vertex (Pair.To_Vertex);
         end;
      end loop;

      Conversions.Write_Point_3D
        (Data, 2,
         (X => TopoProof.Numerics.Grid_Coordinate (Min_X),
          Y => TopoProof.Numerics.Grid_Coordinate (Min_Y),
          Z => TopoProof.Numerics.Grid_Coordinate (Min_Z)));
      Conversions.Write_Point_3D
        (Data, 5,
         (X => TopoProof.Numerics.Grid_Coordinate (Max_X),
          Y => TopoProof.Numerics.Grid_Coordinate (Max_Y),
          Z => TopoProof.Numerics.Grid_Coordinate (Max_Z)));
   end Solid_Bounds_Native;

end TopoScript_API.Topology;

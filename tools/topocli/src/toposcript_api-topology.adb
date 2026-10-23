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
with TopoProof.Topology.Faces;
with TopoProof.Topology.Loops;
with TopoProof.Topology.Vertices;

package body TopoScript_API.Topology is

   package Handle_Vectors is new Ada.Containers.Indefinite_Vectors
     (Positive, TopoProof.Topology.Vertices.Vertex_Handle);

   procedure Add_Point_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      P : TopoProof.Geometry.Points.Point_2D;
   begin
      if not Conversions.Read_Point_2D (Data, 1, P) then
         Session.Record_Failure ("error: coordinate outside the grid");
         return;
      end if;
      Session.Current_Session.Chain.Append
        (Chain_Point'(X => P.X, Y => P.Y));
   end Add_Point_Native;

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

   procedure Make_Loop_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      N : constant Natural :=
        Natural (Session.Current_Session.Chain.Length);
      Kind : Loop_Kind := Open_Chain;

   begin
      if N < 2 then
         Session.Record_Failure
           (TopoDiagnostics.Loop_Diagnostic
              (TopoProof.Topology.Loops.Open_Chain));
         Data (1) := Loop_To_HAC (Kind);
         return;
      elsif N - 1 > TopoProof.Topology.Loops.Max_Loop_Length then
         Session.Record_Failure ("error: too many edges for one loop");
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

   procedure Make_Face_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      N : constant Natural :=
        Natural (Session.Current_Session.Chain.Length);
      Kind : Face_Kind := Face_Invalid_Boundary;

   begin
      if N < 2 then
         Session.Record_Failure
           (TopoDiagnostics.Loop_Diagnostic
              (TopoProof.Topology.Loops.Open_Chain));
         Data (1) := Face_To_HAC (Kind);
         return;
      elsif N - 1 > TopoProof.Topology.Loops.Max_Loop_Length then
         Session.Record_Failure ("error: too many edges for one loop");
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

end TopoScript_API.Topology;

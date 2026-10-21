-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

package body TopoProof.Topology.Loops
   with SPARK_Mode
is

   --  The classification mirrors the definition order of the status
   --  type: every check runs with the previous ones already known, so
   --  the precondition of each predicate is discharged by the branch
   --  taken before it.
   function Classify_Loop
      (E     : Edges.Edge_Store;
       V     : Vertices.Vertex_Store;
       Chain : Edge_Handle_Array) return Loop_Validity
   is
   begin
      if not Is_Orphan_Free (E, Chain) then
         return Orphan_Edge;

      elsif not Has_Existing_Endpoints (E, V, Chain) then
         return Missing_Endpoint;

      elsif not Is_Closed_Chain (E, Chain) then
         return Open_Chain;

      elsif not Is_Connected_Chain (E, Chain) then
         return Disconnected_Chain;

      elsif not Has_No_Degenerate_Support (E, V, Chain) then
         return Degenerate_Support;

      else
         return Valid_Loop;

      end if;
   end Classify_Loop;

   --  The chain is known valid, so it is installed as it is.
   function Make_Loop
      (E     : Edges.Edge_Store;
       V     : Vertices.Vertex_Store;
       Chain : Edge_Handle_Array) return Loop_2D
   is

   begin
      return (Length => Chain'Length, Edges => Chain);
   end Make_Loop;

   --  The candidate is the sequence of the starting vertices of the
   --  edges, closed by a copy of the first position. The invariant of
   --  the filling loop records the points established so far; the
   --  postcondition relations follow: the point an edge arrives at is
   --  the point the next edge starts from, by connectivity; the
   --  closing point is the first position, and the last edge arrives
   --  at it, by closure; no segment is degenerate, because no edge
   --  support is; and a valid loop has at least two edges, since one
   --  stored edge cannot close on itself.
   function Point_Sequence
      (E : Edges.Edge_Store;
       V : Vertices.Vertex_Store;
       L : Loop_2D) return Segment_Sequences.Segment_Sequence_2D
   is
      --  The sequence is fully initialized with the grid origin, like
      --  the store defaults: the positions actually used are all
      --  assigned by the loop and the closing copy below.
      Seq : Segment_Sequences.Segment_Sequence_2D (L.Length + 1) :=
         (Length => L.Length + 1,
          Points => [others => (X => 0, Y => 0)]);

   begin
      for I in 1 .. L.Length loop
         Seq.Points (I) :=
            Vertices.Point_Of (V, Edges.Endpoints (E, L.Edges (I)).From_Vertex);
         pragma Loop_Invariant
           (for all J in 1 .. I =>
               Seq.Points (J)
               = Vertices.Point_Of
                  (V, Edges.Endpoints (E, L.Edges (J)).From_Vertex));
      end loop;
      Seq.Points (L.Length + 1) := Seq.Points (1);
      return Seq;
   end Point_Sequence;

   --  The orientation is the milestone 4 orientation of the geometric
   --  candidate: the precondition of Segment_Sequences.Orientation is
   --  part of the postcondition of Point_Sequence.
   function Loop_Orientation
      (E : Edges.Edge_Store;
       V : Vertices.Vertex_Store;
       L : Loop_2D) return Segment_Sequences.Contour_Orientation
   is
      Seq : constant Segment_Sequences.Segment_Sequence_2D := Point_Sequence (E, V, L);

   begin
      return Segment_Sequences.Orientation (Seq);
   end Loop_Orientation;

end TopoProof.Topology.Loops;

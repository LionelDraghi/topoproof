-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with TopoProof.Geometry.Points;
with TopoProof.Geometry.Segment_Sequences;
with TopoProof.Topology.Edges;
with TopoProof.Topology.Vertices;
use TopoProof.Geometry;
use type TopoProof.Geometry.Points.Point_2D;
use type TopoProof.Geometry.Segment_Sequences.Contour_Orientation;

package TopoProof.Topology.Loops
   with Pure, SPARK_Mode
is
   --  The longest loop: a chain of n edges has a geometric candidate
   --  of n + 1 points, and that candidate is bounded by
   --  Segment_Sequences.Max_Points, so n stays one below
   --  Edges.Max_Edges. Like every length of the topology layer, loop
   --  lengths index and compare only, never multiply.
   Max_Loop_Length : constant := Edges.Max_Edges - 1;

   subtype Loop_Length_Range is Natural range 0 .. Max_Loop_Length;

   --  An ordered chain of edge handles. Chains are indexed from 1 in
   --  every public operation: the contracts state it explicitly.
   type Edge_Handle_Array is array (Positive range <>) of Edges.Edge_Handle;

   --  An oriented loop: an ordered chain of connected edges that
   --  returns to its starting vertex. A loop is a value, not a stored
   --  entity: it has no handle, and its meaning is relative to the
   --  edge and vertex stores its edges come from, which every
   --  validity predicate takes as parameters. The length has a
   --  default so that a loop is a mutable value: being built, then
   --  possibly empty, then rebuilt, is part of the contract of
   --  Create_Loop; unlike a store capacity, a loop length is not an
   --  identity, so changing it by whole-record assignment breaks no
   --  reference.
   type Loop_2D (Length : Loop_Length_Range := 0) is record
      Edges : Edge_Handle_Array (1 .. Length);
   end record;

   --  The exact classification of an edge chain, decided in this order
   --  and without tolerance: the chain is a valid loop when it
   --  contains no orphan edge, every endpoint exists in the vertex
   --  store, the chain closes on its starting vertex, consecutive
   --  edges are connected, and no edge is reduced to a point. The
   --  geometric degeneracy of the support is judged here, at loop
   --  level (DD-002, decision 6): an edge between two distinct
   --  vertices at the same point is a valid edge, but it cannot
   --  appear in a valid loop.
   type Loop_Validity is
     (Valid_Loop,
      Orphan_Edge,
      Missing_Endpoint,
      Open_Chain,
      Disconnected_Chain,
      Degenerate_Support);

   --  Every edge of the chain is stored: no orphan edge.
   function Is_Orphan_Free (E : Edges.Edge_Store; Chain : Edge_Handle_Array)
      return Boolean
   is (for all I in Chain'Range => Edges.Contains (E, Chain (I)));

   --  Both endpoints of every edge exist in the vertex store.
   function Has_Existing_Endpoints
      (E : Edges.Edge_Store;
       V : Vertices.Vertex_Store;
       Chain : Edge_Handle_Array) return Boolean
   is
     (for all I in Chain'Range =>
         Vertices.Contains (V, Edges.Endpoints (E, Chain (I)).From_Vertex)
         and then Vertices.Contains (V, Edges.Endpoints (E, Chain (I)).To_Vertex))
   with Pre => Is_Orphan_Free (E, Chain);

   --  Topological closure: the last edge of the chain returns to the
   --  vertex the first edge starts from. A chain of less than one
   --  edge is never closed.
   function Is_Closed_Chain (E : Edges.Edge_Store; Chain : Edge_Handle_Array)
      return Boolean
   is
     (Chain'Length >= 1
      and then Edges.Endpoints (E, Chain (Chain'Last)).To_Vertex
              = Edges.Endpoints (E, Chain (Chain'First)).From_Vertex)
   with Pre => Is_Orphan_Free (E, Chain);

   --  Connectivity: the vertex an edge arrives at is the vertex the
   --  next edge starts from.
   function Is_Connected_Chain
      (E : Edges.Edge_Store;
       Chain : Edge_Handle_Array) return Boolean
   is
     (for all I in Chain'Range =>
         (if I < Chain'Last
          then Edges.Endpoints (E, Chain (I)).To_Vertex
               = Edges.Endpoints (E, Chain (I + 1)).From_Vertex))
   with Pre => Is_Orphan_Free (E, Chain);

   --  Geometric support: no edge of the chain is reduced to a point.
   function Has_No_Degenerate_Support
      (E : Edges.Edge_Store;
       V : Vertices.Vertex_Store;
       Chain : Edge_Handle_Array) return Boolean
   is
     (for all I in Chain'Range =>
         Vertices.Point_Of (V, Edges.Endpoints (E, Chain (I)).From_Vertex)
         /= Vertices.Point_Of (V, Edges.Endpoints (E, Chain (I)).To_Vertex))
   with
      Pre => Is_Orphan_Free (E, Chain)
             and then Has_Existing_Endpoints (E, V, Chain);

   --  The exact classification of a chain: the first violated property
   --  in the documented order, or Valid_Loop when none is violated.
   function Classify_Loop
      (E     : Edges.Edge_Store;
       V     : Vertices.Vertex_Store;
       Chain : Edge_Handle_Array) return Loop_Validity
   with
      Pre => Chain'First = 1,
      Post =>
        (case Classify_Loop'Result is
            when Valid_Loop =>
               Is_Orphan_Free (E, Chain)
               and then Has_Existing_Endpoints (E, V, Chain)
               and then Is_Closed_Chain (E, Chain)
               and then Is_Connected_Chain (E, Chain)
               and then Has_No_Degenerate_Support (E, V, Chain),
            when Orphan_Edge =>
               not Is_Orphan_Free (E, Chain),
            when Missing_Endpoint =>
               Is_Orphan_Free (E, Chain)
               and then not Has_Existing_Endpoints (E, V, Chain),
            when Open_Chain =>
               Is_Orphan_Free (E, Chain)
               and then Has_Existing_Endpoints (E, V, Chain)
               and then not Is_Closed_Chain (E, Chain),
            when Disconnected_Chain =>
               Is_Orphan_Free (E, Chain)
               and then Has_Existing_Endpoints (E, V, Chain)
               and then Is_Closed_Chain (E, Chain)
               and then not Is_Connected_Chain (E, Chain),
            when Degenerate_Support =>
               Is_Orphan_Free (E, Chain)
               and then Has_Existing_Endpoints (E, V, Chain)
               and then Is_Closed_Chain (E, Chain)
               and then Is_Connected_Chain (E, Chain)
               and then not Has_No_Degenerate_Support (E, V, Chain));

   --  The loop L is valid in the stores E and V: every invariant of
   --  the loop holds. Only valid loops have a geometric candidate
   --  and an orientation.
   function Is_Valid_Loop
      (E : Edges.Edge_Store;
       V : Vertices.Vertex_Store;
       L : Loop_2D) return Boolean
   is (Classify_Loop (E, V, L.Edges) = Valid_Loop);

   --  Build a loop from a chain known to be valid. The chain is
   --  classified first with Classify_Loop: Make_Loop completes the
   --  checked construction, and its precondition requires the chain
   --  to classify as Valid_Loop, so invalid loops cannot be obtained
   --  from the public API.
   function Make_Loop
      (E     : Edges.Edge_Store;
       V     : Vertices.Vertex_Store;
       Chain : Edge_Handle_Array) return Loop_2D
   with
      Pre  =>
         Chain'First = 1
         and then Chain'Length <= Max_Loop_Length
         and then Classify_Loop (E, V, Chain) = Valid_Loop,
      Post =>
         Make_Loop'Result.Length = Chain'Length
         and then Is_Valid_Loop (E, V, Make_Loop'Result)
         and then
           (for all I in Chain'Range => Make_Loop'Result.Edges (I) = Chain (I));

   --  The geometric candidate of a valid loop: the closed point
   --  sequence of its edge chain, the position of the starting vertex
   --  of every edge, closed by the position of the starting vertex of
   --  the first edge. The candidate is closed, valid, and long enough
   --  for orientation: a valid loop has at least two edges, because
   --  one stored edge cannot close on itself.
   function Point_Sequence
      (E : Edges.Edge_Store;
       V : Vertices.Vertex_Store;
       L : Loop_2D) return Segment_Sequences.Segment_Sequence_2D
   with
      Pre  => Is_Valid_Loop (E, V, L),
      Post =>
         Point_Sequence'Result.Length = L.Length + 1
         and then Point_Sequence'Result.Length >= 3
         and then Segment_Sequences.Is_Closed (Point_Sequence'Result)
         and then Segment_Sequences.Is_Valid (Point_Sequence'Result)
         and then
           (for all I in 1 .. L.Length =>
               Point_Sequence'Result.Points (I)
               = Vertices.Point_Of (V, Edges.Endpoints (E, L.Edges (I)).From_Vertex)
               and then
                 Point_Sequence'Result.Points (I + 1)
                 = Vertices.Point_Of (V, Edges.Endpoints (E, L.Edges (I)).To_Vertex));

   --  The orientation of a valid loop, by the sign of the signed area
   --  of its geometric candidate: exactly the milestone 4 orientation
   --  of the closed point sequence the loop induces. A closed
   --  two-edge backtrack is a valid loop of orientation Degenerate:
   --  it is never a valid face boundary (DD-002, decision 3).
   function Loop_Orientation
      (E : Edges.Edge_Store;
       V : Vertices.Vertex_Store;
       L : Loop_2D) return Segment_Sequences.Contour_Orientation
   with
      Pre  => Is_Valid_Loop (E, V, L),
      Post =>
         Loop_Orientation'Result
         = Segment_Sequences.Orientation (Point_Sequence (E, V, L));

end TopoProof.Topology.Loops;

-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with TopoProof.Topology.Vertices;

package TopoProof.Topology.Edges
   with Pure, SPARK_Mode
is
   --  The largest capacity an edge store may declare, hence the largest
   --  handle. A loop on N vertices has N edges, so Max_Edges =
   --  Vertices.Max_Vertices covers the largest loop buildable on the
   --  largest vertex store, and no operation of the current milestone
   --  needs more. Like vertex handles, edge handles are compared only,
   --  never added or multiplied, so no numeric chain constrains the
   --  bound further.
   Max_Edges : constant := Vertices.Max_Vertices;

   --  The number of edges actually stored.
   subtype Edge_Count_Range is Natural range 0 .. Max_Edges;

   --  The identity of one stored edge: valid only in the Edge_Store it
   --  comes from, and valid in a store exactly when the store contains
   --  it. Like vertex handles, edge handles are compared for equality
   --  only.
   subtype Edge_Handle is Positive range 1 .. Max_Edges;

   --  The two endpoints of an edge: the handles of the two connected
   --  vertices, in traversal order. The pair is a topological value: it
   --  carries no geometry, and positions are reached only through the
   --  vertex store. Two pairs are equal exactly when both handles are
   --  equal.
   type Vertex_Handle_Pair is record
      From_Vertex : Vertices.Vertex_Handle;
      To_Vertex   : Vertices.Vertex_Handle;
   end record;

   type Vertex_Pair_Array is array (Edge_Count_Range range <>)
      of Vertex_Handle_Pair;

   --  A store of edges, with the same discipline as Vertex_Store: the
   --  capacity is a discriminant without a default value, so a store
   --  object pays only its declared capacity, and the capacity is
   --  frozen for the object lifetime: no assignment can invalidate
   --  handles. The type predicate guarantees that the pair array
   --  always covers the stored edges, and that degenerate edges are
   --  forbidden: every stored edge connects two distinct vertices.
   type Edge_Store (Capacity : Edge_Count_Range) is record
      --  The default pair is vertex 1 to vertex 1: unreachable, like
      --  the default points of a vertex store, because a freshly
      --  created store contains no edge, and every access to a pair
      --  requires a valid handle, which only Create produces.
      Count : Edge_Count_Range := 0;
      Pairs : Vertex_Pair_Array (1 .. Capacity) :=
         [others => (From_Vertex => 1, To_Vertex => 1)];
   end record
   with Dynamic_Predicate =>
      Count <= Capacity
      and then
        (for all I in 1 .. Count => Pairs (I).From_Vertex /= Pairs (I).To_Vertex);

   --  The handle E designates a stored edge of Store.
   function Contains (Store : Edge_Store; E : Edge_Handle) return Boolean
   is (E <= Store.Count);

   --  The number of edges currently stored.
   function Edge_Count (Store : Edge_Store) return Edge_Count_Range
   is (Store.Count);

   --  The endpoints of the edge E. The reference must be valid: an
   --  invalid handle cannot reach the pair array.
   function Endpoints (Store : Edge_Store; E : Edge_Handle)
      return Vertex_Handle_Pair
   is (Store.Pairs (E))
   with Pre => Contains (Store, E);

   --  Create one oriented edge from vertex A to vertex B, and return its
   --  handle. Degeneracy is topological: both ends must be distinct
   --  vertices, so A /= B; an edge between two distinct vertices at the
   --  same point is a valid edge, because identity is not position
   --  (DD-002), and the geometric degeneracy of its support is judged at
   --  loop level. Both endpoints must exist in Vertex_Store at creation;
   --  since stored vertices are never removed, existing endpoints stay
   --  valid for the whole lifetime of both stores.
   procedure Create
      (Store        : in out Edge_Store;
       Vertex_Store :        Vertices.Vertex_Store;
       A, B         :        Vertices.Vertex_Handle;
       E            :    out Edge_Handle)
   with
      Pre  =>
         Edge_Count (Store) < Store.Capacity
         and then Vertices.Contains (Vertex_Store, A)
         and then Vertices.Contains (Vertex_Store, B)
         and then A /= B,
      Post =>
         Edge_Count (Store) = Edge_Count (Store)'Old + 1
         and then Contains (Store, E)
         and then Endpoints (Store, E) = (From_Vertex => A, To_Vertex => B)
         and then
           (for all F in 1 .. Edge_Count (Store)'Old =>
               Endpoints (Store, F) = Endpoints (Store'Old, F));

end TopoProof.Topology.Edges;

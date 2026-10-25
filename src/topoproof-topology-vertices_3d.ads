-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with TopoProof.Geometry.Points;
use TopoProof.Geometry;
use type TopoProof.Geometry.Points.Point_3D;

package TopoProof.Topology.Vertices_3D
   with Pure, SPARK_Mode
is
   --  The largest capacity a store may declare, hence the largest handle.
   --  The bound follows the representation discipline of
   --  Segment_Sequences.Max_Points: a store must at least hold the
   --  vertices of the largest chain the kernel models, and no operation
   --  of the current milestone needs more. It bounds identities, not
   --  memory: a store object occupies only its declared capacity. Each
   --  vertex carries one Point_3D, that is three grid coordinates.
   --  Handles are compared only, never added or multiplied, so no
   --  numeric chain constrains the bound further.
   Max_Vertices_3D : constant := 2**15;

   --  The number of vertices actually stored.
   subtype Vertex_Count_Range is Natural range 0 .. Max_Vertices_3D;

   --  The identity of one stored vertex. A handle is not a position: two
   --  vertices at the same point have distinct handles (DD-002). Handles
   --  are compared for equality only, and are valid only in the store
   --  they come from.
   subtype Vertex_Handle is Positive range 1 .. Max_Vertices_3D;

   type Point_Array is array (Vertex_Count_Range range <>) of Points.Point_3D;

   --  A store of vertices, each vertex referring to one point. The
   --  capacity is a discriminant without a default value: each
   --  declaration states how many vertices the store will hold, and pays
   --  only for that capacity, never for Max_Vertices_3D. The absence of a
   --  default also freezes the capacity for the whole object lifetime:
   --  no assignment can shrink or grow the store, so handles keep their
   --  meaning. The invariant "every vertex references a valid point" is
   --  structural: the stored points are Point_3D values, whose
   --  components belong to Grid_Coordinate by type. Stored vertices are
   --  never removed, so the stored vertices are exactly the handles
   --  1 .. Count, and the type predicate guarantees that the array
   --  always covers them.
   type Vertex_Store (Capacity : Vertex_Count_Range) is record
      --  The default point is the grid origin: a valid position, so the
      --  store is fully initialized, but an unreachable one: a freshly
      --  created store contains no vertex, and every access to a point
      --  requires a valid handle, which only Create produces.
      Count  : Vertex_Count_Range := 0;
      Points : Point_Array (1 .. Capacity) := [others => (X => 0, Y => 0, Z => 0)];
   end record
   with Dynamic_Predicate => Count <= Capacity;

   --  The handle V designates a stored vertex of Store.
   function Contains (Store : Vertex_Store; V : Vertex_Handle) return Boolean
   is (V <= Store.Count);

   --  The number of vertices currently stored.
   function Vertex_Count (Store : Vertex_Store) return Vertex_Count_Range
   is (Store.Count);

   --  The point the vertex V refers to. The reference must be valid: an
   --  invalid handle cannot reach the point array.
   function Point_Of (Store : Vertex_Store; V : Vertex_Handle) return Points.Point_3D
   is (Store.Points (V))
   with Pre => Contains (Store, V);

   --  Create one vertex referring to the point P, and return its handle.
   --  The new vertex has its own identity: it is never merged with an
   --  existing vertex at the same point. Creation allocates the next
   --  handle, so every previously stored vertex keeps its handle and its
   --  point: reference validity is preserved by construction.
   procedure Create (Store : in out Vertex_Store; P : Points.Point_3D; V : out Vertex_Handle)
   with
      Pre  => Vertex_Count (Store) < Store.Capacity,
      Post =>
         Vertex_Count (Store) = Vertex_Count (Store)'Old + 1
         and then Contains (Store, V)
         and then Point_Of (Store, V) = P
         and then (for all W in 1 .. Vertex_Count (Store)'Old =>
                      Point_Of (Store, W) = Point_Of (Store'Old, W));

end TopoProof.Topology.Vertices_3D;

-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with TopoProof.Geometry.Planes;
with TopoProof.Topology.Edges_3D;
with TopoProof.Topology.Loops_3D;
with TopoProof.Topology.Vertices_3D;
use TopoProof.Geometry;
use type TopoProof.Geometry.Planes.Plane_Side_Kind;
use type TopoProof.Topology.Loops_3D.Loop_3D;

package TopoProof.Topology.Faces_3D
   with Pure, SPARK_Mode
is
   --  A planar face of the three-dimensional structure: a region of a
   --  plane bounded by one loop (DD-005, decision 3). A face is a
   --  value: it carries its boundary loop, and its meaning is relative
   --  to the edge and vertex stores the boundary's edges come from,
   --  which every validity predicate takes as parameters. The plane of
   --  a valid face is derived from its support points, never stored:
   --  the points are the single source, and no stored plane can
   --  diverge from them.
   type Face_3D is record
      Boundary : Loops_3D.Loop_3D;
   end record;

   --  The exact classification of a loop as a planar face boundary,
   --  decided without tolerance: a valid face boundary is a valid loop
   --  whose support points are exactly coplanar and not collinear. The
   --  collinear degeneracy covers the closed two-edge backtrack, whose
   --  two support points are always collinear (DD-002, decision 3).
   type Face_Validity is
     (Valid_Face,
      Invalid_Boundary,
      Collinear_Boundary,
      Non_Planar_Boundary);

   --  Every support point of the chain is exactly on the plane Pl: the
   --  exact classification by the plane equation, which vanishes on
   --  the plane. Both endpoints of every edge are checked; in a closed
   --  connected chain every support point is the starting vertex of
   --  some edge, so the starting points alone would cover them.
   function All_On_Plane
      (E     : Edges_3D.Edge_Store;
       V     : Vertices_3D.Vertex_Store;
       Chain : Loops_3D.Edge_Handle_Array;
       Pl    : Planes.Plane) return Boolean
   is
     (for all K in Chain'Range =>
         Planes.Plane_Side
           (Pl,
            Vertices_3D.Point_Of
              (V, Edges_3D.Endpoints (E, Chain (K)).From_Vertex))
         = Planes.On_Plane
      and then
         Planes.Plane_Side
           (Pl,
            Vertices_3D.Point_Of
              (V, Edges_3D.Endpoints (E, Chain (K)).To_Vertex))
         = Planes.On_Plane)
   with
      Pre => Loops_3D.Is_Orphan_Free (E, Chain)
             and then Loops_3D.Has_Existing_Endpoints (E, V, Chain);

   --  Every support point of the chain lies on the line of its first
   --  edge: the collinear degeneracy, judged exactly by the collinearity
   --  of the first starting point, of the point it arrives at, and of
   --  every later starting point. In a closed connected chain the
   --  support points are exactly the starting points of the edges,
   --  closed by the point the first edge starts from.
   function All_Collinear
      (E     : Edges_3D.Edge_Store;
       V     : Vertices_3D.Vertex_Store;
       Chain : Loops_3D.Edge_Handle_Array) return Boolean
   is
     (for all K in 2 .. Chain'Last =>
         Planes.Are_Collinear
           (Vertices_3D.Point_Of
              (V, Edges_3D.Endpoints (E, Chain (1)).From_Vertex),
            Vertices_3D.Point_Of
              (V, Edges_3D.Endpoints (E, Chain (1)).To_Vertex),
            Vertices_3D.Point_Of
              (V, Edges_3D.Endpoints (E, Chain (K)).From_Vertex)))
   with
      Pre => Chain'First = 1
             and then Chain'Length >= 2
             and then Loops_3D.Is_Orphan_Free (E, Chain)
             and then Loops_3D.Has_Existing_Endpoints (E, V, Chain);

   --  The report of the plane derivation: either the plane of the
   --  first non-collinear triple of the chain, or the collinear
   --  report. The plane field is meaningful only when the kind is
   --  Plane_Found.
   type Plane_Finding_Kind is (Plane_Found, All_Collinear);

   type Found_Plane is record
      K  : Plane_Finding_Kind;
      Pl : Planes.Plane;
   end record;

   --  The exact plane derivation from the support points: the plane
   --  through the starting point of the first edge, the point it
   --  arrives at, and the first later support point off their line.
   --  The starting points are distinct by the non-degenerate support,
   --  so the line of the first edge is well defined, and the found
   --  triple is non-collinear by construction. When every support
   --  point lies on that line, no plane exists, and the report is the
   --  collinear one.
   function Derive_Plane
      (E     : Edges_3D.Edge_Store;
       V     : Vertices_3D.Vertex_Store;
       Chain : Loops_3D.Edge_Handle_Array) return Found_Plane
   with
      Pre  => Chain'First = 1
              and then Chain'Length >= 2
              and then Loops_3D.Is_Orphan_Free (E, Chain)
              and then Loops_3D.Has_Existing_Endpoints (E, V, Chain)
              and then Loops_3D.Has_No_Degenerate_Support (E, V, Chain),
      Post =>
        (if Derive_Plane'Result.K = Plane_Found
         then not Planes.Are_Collinear
                 (Derive_Plane'Result.Pl.A,
                  Derive_Plane'Result.Pl.B,
                  Derive_Plane'Result.Pl.C)
         else All_Collinear (E, V, Chain));

   --  The support of the chain is planar: the derived plane exists, it
   --  is non-degenerate, and every support point lies exactly on it.
   function Is_Planar_Support
      (E     : Edges_3D.Edge_Store;
       V     : Vertices_3D.Vertex_Store;
       Chain : Loops_3D.Edge_Handle_Array) return Boolean
   is
     (declare D : constant Found_Plane := Derive_Plane (E, V, Chain);
      begin D.K = Plane_Found
            and then not Planes.Are_Collinear (D.Pl.A, D.Pl.B, D.Pl.C)
            and then All_On_Plane (E, V, Chain, D.Pl))
   with
      Pre => Chain'First = 1
             and then Chain'Length >= 2
             and then Loops_3D.Is_Orphan_Free (E, Chain)
             and then Loops_3D.Has_Existing_Endpoints (E, V, Chain)
             and then Loops_3D.Has_No_Degenerate_Support (E, V, Chain);

   --  The exact classification of a loop as a face boundary: the first
   --  violated property in the documented order, or Valid_Face when
   --  none is violated. An invalid loop is an invalid boundary; a
   --  valid loop whose support points all lie on one line carries no
   --  plane; a valid loop with a plane and a support point off it is
   --  not planar.
   function Classify_Face
      (E : Edges_3D.Edge_Store;
       V : Vertices_3D.Vertex_Store;
       L : Loops_3D.Loop_3D) return Face_Validity
   with
      Post =>
        (case Classify_Face'Result is
            when Valid_Face =>
               Loops_3D.Is_Valid_Loop (E, V, L)
               and then L.Length >= 2
               and then Is_Planar_Support (E, V, L.Edges),
            when Invalid_Boundary =>
               not Loops_3D.Is_Valid_Loop (E, V, L),
            when Collinear_Boundary =>
               Loops_3D.Is_Valid_Loop (E, V, L)
               and then L.Length >= 2
               and then not Is_Planar_Support (E, V, L.Edges)
               and then All_Collinear (E, V, L.Edges),
            when Non_Planar_Boundary =>
               Loops_3D.Is_Valid_Loop (E, V, L)
               and then L.Length >= 2
               and then not Is_Planar_Support (E, V, L.Edges)
               and then not All_Collinear (E, V, L.Edges));

   --  The face F is valid in the stores E and V: its boundary is a
   --  valid planar face boundary. Only valid faces have a plane.
   function Is_Valid_Face
      (E : Edges_3D.Edge_Store;
       V : Vertices_3D.Vertex_Store;
       F : Face_3D) return Boolean
   is (Classify_Face (E, V, F.Boundary) = Valid_Face);

   --  Build a face from a loop known to be a valid face boundary. The
   --  loop is classified first with Classify_Face: Make_Face completes
   --  the checked construction, and its precondition requires the loop
   --  to classify as Valid_Face, so invalid faces cannot be obtained
   --  from the public API.
   function Make_Face
      (E : Edges_3D.Edge_Store;
       V : Vertices_3D.Vertex_Store;
       L : Loops_3D.Loop_3D) return Face_3D
   with
      Pre  => Classify_Face (E, V, L) = Valid_Face,
      Post =>
         Make_Face'Result.Boundary = L
         and then Is_Valid_Face (E, V, Make_Face'Result);

   --  The exact plane of a valid face: the plane derived from its
   --  support points. It is non-degenerate, and every support point of
   --  the boundary lies exactly on it: the plane is the one the
   --  classification established.
   function Face_Plane
      (E : Edges_3D.Edge_Store;
       V : Vertices_3D.Vertex_Store;
       F : Face_3D) return Planes.Plane
   with
      Pre  => Is_Valid_Face (E, V, F),
      Post =>
         not Planes.Are_Collinear
            (Face_Plane'Result.A, Face_Plane'Result.B, Face_Plane'Result.C)
         and then All_On_Plane (E, V, F.Boundary.Edges, Face_Plane'Result);

end TopoProof.Topology.Faces_3D;

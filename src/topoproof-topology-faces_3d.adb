-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with TopoProof.Geometry.Points;

package body TopoProof.Topology.Faces_3D
   with SPARK_Mode
is
   --  The plane derivation scans the starting points of the edges, in
   --  chain order, for the first one off the line of the first edge.
   --  The scan invariant records the points already known on the line,
   --  so the exhausted scan proves the collinear report, and the found
   --  point proves the non-collinear triple by the branch taken.
   function Derive_Plane
      (E     : Edges_3D.Edge_Store;
       V     : Vertices_3D.Vertex_Store;
       Chain : Loops_3D.Edge_Handle_Array) return Found_Plane
   is
      A : constant Points.Point_3D :=
        Vertices_3D.Point_Of
          (V, Edges_3D.Endpoints (E, Chain (1)).From_Vertex);
      B : constant Points.Point_3D :=
        Vertices_3D.Point_Of
          (V, Edges_3D.Endpoints (E, Chain (1)).To_Vertex);

   begin
      for K in 2 .. Chain'Last loop
         if not Planes.Are_Collinear
                 (A,
                  B,
                  Vertices_3D.Point_Of
                    (V, Edges_3D.Endpoints (E, Chain (K)).From_Vertex))
         then
            return
              (K  => Plane_Found,
               Pl => (A => A,
                      B => B,
                      C =>
                        Vertices_3D.Point_Of
                          (V, Edges_3D.Endpoints (E, Chain (K)).From_Vertex)));
         end if;

         pragma Loop_Invariant
           (for all J in 2 .. K =>
               Planes.Are_Collinear
                 (A,
                  B,
                  Vertices_3D.Point_Of
                    (V, Edges_3D.Endpoints (E, Chain (J)).From_Vertex)));
      end loop;

      return (K => All_Collinear, Pl => (A => A, B => B, C => B));
   end Derive_Plane;

   --  The classification mirrors the definition order of the status
   --  type: the loop invariants first, then the plane, then the
   --  collinear degeneracy, so the precondition of each predicate is
   --  discharged by the branch taken before it.
   function Classify_Face
      (E : Edges_3D.Edge_Store;
       V : Vertices_3D.Vertex_Store;
       L : Loops_3D.Loop_3D) return Face_Validity
   is
   begin
      if not Loops_3D.Is_Valid_Loop (E, V, L) then
         return Invalid_Boundary;

      elsif Is_Planar_Support (E, V, L.Edges) then
         return Valid_Face;

      elsif All_Collinear (E, V, L.Edges) then
         return Collinear_Boundary;

      else
         return Non_Planar_Boundary;

      end if;
   end Classify_Face;

   --  The chain is known to be a valid planar face boundary, so it is
   --  installed as it is.
   function Make_Face
      (E : Edges_3D.Edge_Store;
       V : Vertices_3D.Vertex_Store;
       L : Loops_3D.Loop_3D) return Face_3D
   is
   begin
      return (Boundary => L);
   end Make_Face;

   --  The plane is the one the classification derived: the same exact
   --  derivation over the same chain, whose report the Valid_Face
   --  classification established as found, non-degenerate, and carrying
   --  every support point.
   function Face_Plane
      (E : Edges_3D.Edge_Store;
       V : Vertices_3D.Vertex_Store;
       F : Face_3D) return Planes.Plane
   is
      D : constant Found_Plane := Derive_Plane (E, V, F.Boundary.Edges);

   begin
      return D.Pl;
   end Face_Plane;

end TopoProof.Topology.Faces_3D;

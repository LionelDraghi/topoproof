-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with TopoProof.Geometry.Orientations;
with TopoProof.Geometry.Points;
with TopoProof.Topology.Faces_3D;
with TopoProof.Topology.Loops_3D;
use TopoProof.Geometry;
use type TopoProof.Topology.Loops_3D.Loop_Validity;

package body TopoProof.Topology.Solids
   with SPARK_Mode
is
   --  Every boundary is classified in turn: the shell classification
   --  already proved it a valid loop, so Make_Loop installs it, and
   --  the face classification adds the exact planarity.
   function All_Faces_Planar
      (E : Edges_3D.Edge_Store; V : Vertices_3D.Vertex_Store; S : Shells.Shell) return Boolean is
   begin
      for K in 1 .. S.Face_Count loop
         pragma Loop_Invariant
           (Shells.Classify_Shell (E, V, S) = Shells.Closed_Shell);

         pragma Assert
           (Loops_3D.Classify_Loop
              (E, V,
               S.Boundary (Shells.Boundary_First (S, K) .. S.Face_Ends (K)))
            = Loops_3D.Valid_Loop);

         declare
            Boundary : constant Loops_3D.Loop_3D :=
               Loops_3D.Make_Loop
                  (E, V, S.Boundary (Shells.Boundary_First (S, K) .. S.Face_Ends (K)));
         begin
            if not Faces_3D.Is_Valid_Face (E, V, (Boundary => Boundary)) then
               return False;
            end if;
         end;
      end loop;
      return True;
   end All_Faces_Planar;

   --  The accumulation runs over the fan triangles of every face, in
   --  one running total in the Volume domain. The bound is carried by
   --  the flattened positions themselves: the fan terms processed so
   --  far are bounded by the uses processed so far, so the total is
   --  bounded by the last end reached, and every determinant is
   --  bounded by the Cross_Dot domain. Nothing can leave the Volume
   --  domain, whatever the assembly.
   function Volume_Sum
      (E : Edges_3D.Edge_Store; V : Vertices_3D.Vertex_Store; S : Shells.Shell)
       return Numerics.Volume
   is
      Origin : constant Points.Point_3D := (X => 0, Y => 0, Z => 0);
      Total  : Numerics.Volume := 0;

   begin
      for K in 1 .. S.Face_Count loop
         pragma
            Loop_Invariant
               (abs (Total)
                   <= Numerics.Volume (if K = 1 then 0 else S.Face_Ends (K - 1))
                      * Numerics.Cross_Dot_Amplitude);

         declare
            First : constant Edges_3D.Edge_Handle := Shells.Boundary_First (S, K);
            Last  : constant Edges_3D.Edge_Handle := S.Face_Ends (K);
            V1    : constant Points.Point_3D :=
               Vertices_3D.Point_Of (V, Edges_3D.Endpoints (E, S.Boundary (First)).From_Vertex);

         begin
            for I in First + 1 .. Last - 1 loop
               pragma
                  Loop_Invariant
                     (abs (Total)
                         <= (Numerics.Volume (if K = 1 then 0 else S.Face_Ends (K - 1))
                             + Numerics.Volume (I - First))
                            * Numerics.Cross_Dot_Amplitude);

               Total :=
                  Total
                  + Numerics.Volume
                       (Orientations.Determinant
                           (Origin,
                            V1,
                            Vertices_3D.Point_Of
                               (V, Edges_3D.Endpoints (E, S.Boundary (I)).From_Vertex),
                            Vertices_3D.Point_Of
                               (V, Edges_3D.Endpoints (E, S.Boundary (I + 1)).From_Vertex)));
            end loop;
         end;
      end loop;

      return Total;
   end Volume_Sum;

   --  The classification reads the sign of the exact volume sum.
   function Classify_Solid
      (E : Edges_3D.Edge_Store; V : Vertices_3D.Vertex_Store; S : Shells.Shell) return Solid_Kind
   is
      W : constant Numerics.Volume := Volume_Sum (E, V, S);

   begin
      if W > 0 then
         return Outward_Solid;
      elsif W < 0 then
         return Inward_Solid;
      else
         return Flat_Assembly;
      end if;
   end Classify_Solid;

   --  The assembly is known closed, planar and non-flat, so it is
   --  installed as it is.
   function Make_Solid
      (E : Edges_3D.Edge_Store; V : Vertices_3D.Vertex_Store; S : Shells.Shell) return Solid is
   begin
      return (Assembly => S);
   end Make_Solid;

end TopoProof.Topology.Solids;

-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with TopoProof.Numerics;
with TopoProof.Topology.Edges_3D;
with TopoProof.Topology.Loops_3D;
with TopoProof.Topology.Shells;
with TopoProof.Topology.Vertices_3D;
use type TopoProof.Numerics.Volume;
use type TopoProof.Topology.Shells.Shell;
use type TopoProof.Topology.Shells.Shell_Validity;

package TopoProof.Topology.Solids
   with Pure, SPARK_Mode
is
   --  The first closed solid: the minimal B-Rep model (DD-005,
   --  decision 5) - one solid is bounded by exactly one closed, paired
   --  shell of planar face boundaries, and the exact signed volume of
   --  that shell decides the two orientation worlds: the faces wind
   --  counter-clockwise seen from outside (the volume sum is positive,
   --  the outward orientation) or clockwise (negative, the inward one).
   --  A closed shell whose volume sum vanishes encloses nothing: it is
   --  never a solid, the flat degeneracy is reported, never built, the
   --  same way a closed backtrack is a valid loop but never a face
   --  boundary (DD-002, decision 3).

   --  The structural facts of the assembly, shared by every
   --  precondition below: the edge chain starts at 1, carries no
   --  orphan edge, and every endpoint exists in the vertex store.
   --  Classify_Shell carries them in its own precondition, so every
   --  caller of the solid operations states them first.

   --  Every face boundary of the assembly is a valid planar face. The
   --  shell classification guarantees the loop validity of every
   --  boundary; the face classification adds the exact coplanarity of
   --  the support points and the non-collinearity the plane needs.
   function All_Faces_Planar
      (E : Edges_3D.Edge_Store; V : Vertices_3D.Vertex_Store; S : Shells.Shell) return Boolean
   with
      Pre =>
         S.Boundary'First = 1
         and then Loops_3D.Is_Orphan_Free (E, S.Boundary)
         and then Loops_3D.Has_Existing_Endpoints (E, V, S.Boundary)
         and then Shells.Classify_Shell (E, V, S) = Shells.Closed_Shell;

   --  The exact signed volume sum of a closed shell assembly: the fan
   --  decomposition of every face boundary, one four-point orientation
   --  determinant per fan triangle, summed over the whole assembly in
   --  the 128-bit Volume domain. The sum is six times the enclosed
   --  volume, positive for the outward orientation, negative for the
   --  inward one, zero for a flat assembly; the fan decomposition is
   --  exact for planar faces, and the whole computation stays in its
   --  domain for any closed assembly.
   function Volume_Sum
      (E : Edges_3D.Edge_Store; V : Vertices_3D.Vertex_Store; S : Shells.Shell)
       return Numerics.Volume
   with
      Pre =>
         S.Boundary'First = 1
         and then Loops_3D.Is_Orphan_Free (E, S.Boundary)
         and then Loops_3D.Has_Existing_Endpoints (E, V, S.Boundary)
         and then Shells.Classify_Shell (E, V, S) = Shells.Closed_Shell;

   --  The exact classification of a closed, planar shell assembly as a
   --  solid: outward when the volume sum is positive, inward when it
   --  is negative, flat when it vanishes.
   type Solid_Kind is (Outward_Solid, Inward_Solid, Flat_Assembly);

   function Classify_Solid
      (E : Edges_3D.Edge_Store; V : Vertices_3D.Vertex_Store; S : Shells.Shell) return Solid_Kind
   with
      Pre  =>
         S.Boundary'First = 1
         and then Loops_3D.Is_Orphan_Free (E, S.Boundary)
         and then Loops_3D.Has_Existing_Endpoints (E, V, S.Boundary)
         and then Shells.Classify_Shell (E, V, S) = Shells.Closed_Shell
         and then All_Faces_Planar (E, V, S),
      Post =>
         (case Classify_Solid'Result is
             when Outward_Solid => Volume_Sum (E, V, S) > 0,
             when Inward_Solid  => Volume_Sum (E, V, S) < 0,
             when Flat_Assembly => Volume_Sum (E, V, S) = 0);

   --  The first closed solid: a value carrying its shell assembly.
   type Solid is record
      Assembly : Shells.Shell;
   end record;

   --  Build the solid of a closed, planar, non-flat shell assembly.
   --  The shell is classified first with Classify_Shell, then with
   --  Classify_Solid: Make_Solid completes the checked construction,
   --  and its preconditions require the closed pairing and a non-zero
   --  volume, so invalid solids cannot be obtained from the public
   --  API.
   function Make_Solid
      (E : Edges_3D.Edge_Store; V : Vertices_3D.Vertex_Store; S : Shells.Shell) return Solid
   with
      Pre  =>
         S.Boundary'First = 1
         and then Loops_3D.Is_Orphan_Free (E, S.Boundary)
         and then Loops_3D.Has_Existing_Endpoints (E, V, S.Boundary)
         and then Shells.Classify_Shell (E, V, S) = Shells.Closed_Shell
         and then All_Faces_Planar (E, V, S)
         and then Classify_Solid (E, V, S) /= Flat_Assembly,
      Post =>
         Make_Solid'Result.Assembly = S
         and then Shells.Classify_Shell (E, V, Make_Solid'Result.Assembly) = Shells.Closed_Shell;

end TopoProof.Topology.Solids;

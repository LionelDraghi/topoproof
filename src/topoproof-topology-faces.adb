-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

package body TopoProof.Topology.Faces
   with SPARK_Mode
is

   --  The classification mirrors the definition: an invalid loop is
   --  never a boundary candidate; among valid loops, only the
   --  non-degenerate orientations bound a face.
   function Classify_Face
      (E : Edges.Edge_Store;
       V : Vertices.Vertex_Store;
       L : Loops.Loop_2D) return Face_Validity
   is
   begin
      if not Loops.Is_Valid_Loop (E, V, L) then
         return Invalid_Boundary;

      elsif Loops.Loop_Orientation (E, V, L) = Segment_Sequences.Degenerate then
         return Degenerate_Boundary;

      else
         return Valid_Face;

      end if;
   end Classify_Face;

   --  The loop is known to be a valid face boundary, so it becomes the
   --  boundary as it is.
   function Make_Face
      (E : Edges.Edge_Store;
       V : Vertices.Vertex_Store;
       L : Loops.Loop_2D) return Face_2D
   is
   begin
      return (Boundary => L);
   end Make_Face;

   --  The orientation of a face is the orientation of its boundary:
   --  the precondition of Loop_Orientation holds because a valid face
   --  boundary is a valid loop, and the orientation is not degenerate
   --  because Classify_Face says so.
   function Face_Orientation
      (E : Edges.Edge_Store;
       V : Vertices.Vertex_Store;
       F : Face_2D) return Segment_Sequences.Contour_Orientation
   is
   begin
      return Loops.Loop_Orientation (E, V, F.Boundary);
   end Face_Orientation;

end TopoProof.Topology.Faces;

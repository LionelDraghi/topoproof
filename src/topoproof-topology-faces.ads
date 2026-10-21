-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with TopoProof.Geometry.Segment_Sequences;
with TopoProof.Topology.Edges;
with TopoProof.Topology.Loops;
with TopoProof.Topology.Vertices;
use TopoProof.Geometry;
use type TopoProof.Geometry.Segment_Sequences.Contour_Orientation;
use type TopoProof.Topology.Loops.Loop_2D;

package TopoProof.Topology.Faces
   with Pure, SPARK_Mode
is
   --  A planar face: a region of the plane bounded by one loop. A face
   --  is a value: it carries its boundary loop, and its meaning is
   --  relative to the edge and vertex stores the boundary's edges come
   --  from, which every validity predicate takes as parameters. The
   --  boundary component carries the default discriminant of the loop
   --  type, so a face is a mutable value, like its boundary.
   type Face_2D is record
      Boundary : Loops.Loop_2D;
   end record;

   --  The exact classification of a loop as a face boundary, decided
   --  without tolerance: a valid face boundary is a valid loop whose
   --  orientation is not degenerate. A closed two-edge backtrack is a
   --  valid loop, but never a valid face boundary (DD-002, decision 3).
   type Face_Validity is
     (Valid_Face,
      Invalid_Boundary,
      Degenerate_Boundary);

   --  The exact classification of a loop as a face boundary.
   function Classify_Face
      (E : Edges.Edge_Store;
       V : Vertices.Vertex_Store;
       L : Loops.Loop_2D) return Face_Validity
   with
      Post =>
        (case Classify_Face'Result is
            when Valid_Face =>
               Loops.Is_Valid_Loop (E, V, L)
               and then Loops.Loop_Orientation (E, V, L) /= Segment_Sequences.Degenerate,
            when Invalid_Boundary =>
               not Loops.Is_Valid_Loop (E, V, L),
            when Degenerate_Boundary =>
               Loops.Is_Valid_Loop (E, V, L)
               and then Loops.Loop_Orientation (E, V, L) = Segment_Sequences.Degenerate);

   --  The face F is valid in the stores E and V: its boundary is a
   --  valid face boundary. Only valid faces have an orientation.
   function Is_Valid_Face
      (E : Edges.Edge_Store;
       V : Vertices.Vertex_Store;
       F : Face_2D) return Boolean
   is (Classify_Face (E, V, F.Boundary) = Valid_Face);

   --  Build a face from a loop known to be a valid face boundary. The
   --  loop is classified first with Classify_Face: Make_Face completes
   --  the checked construction, and its precondition requires the
   --  loop to classify as Valid_Face, so invalid faces cannot be
   --  obtained from the public API.
   function Make_Face
      (E : Edges.Edge_Store;
       V : Vertices.Vertex_Store;
       L : Loops.Loop_2D) return Face_2D
   with
      Pre  => Classify_Face (E, V, L) = Valid_Face,
      Post =>
         Make_Face'Result.Boundary = L
         and then Is_Valid_Face (E, V, Make_Face'Result);

   --  The orientation of a valid face: exactly the orientation of its
   --  boundary loop, which a valid face boundary guarantees to be
   --  counter-clockwise or clockwise, never degenerate. Face
   --  orientation is consistent with loop orientation by
   --  construction.
   function Face_Orientation
      (E : Edges.Edge_Store;
       V : Vertices.Vertex_Store;
       F : Face_2D) return Segment_Sequences.Contour_Orientation
   with
      Pre  => Is_Valid_Face (E, V, F),
      Post =>
         Face_Orientation'Result
         = Loops.Loop_Orientation (E, V, F.Boundary)
         and then Face_Orientation'Result /= Segment_Sequences.Degenerate;

end TopoProof.Topology.Faces;

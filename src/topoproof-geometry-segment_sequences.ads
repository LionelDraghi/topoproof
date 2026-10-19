-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with TopoProof.Geometry.Intersections;
with TopoProof.Geometry.Orientations;
with TopoProof.Geometry.Points;
with TopoProof.Geometry.Segments;
with TopoProof.Numerics;
use type TopoProof.Geometry.Intersections.Intersection_Kind;
use type TopoProof.Geometry.Points.Point_2D;
use type TopoProof.Numerics.Area_Sum;

package TopoProof.Geometry.Segment_Sequences
   with Pure, SPARK_Mode
is
   --  Maximum number of points in a sequence. The bound keeps every index
   --  arithmetic on sequences (I - 1, I + 1, I + 2, pair enumeration,
   --  doubled indices in the interface) far from the Natural bounds, and
   --  keeps the shoelace sum of any sequence within the Area_Sum domain:
   --  at most Max_Points terms, each bounded by the determinant amplitude,
   --  stay below 2**79, well inside the 128-bit width of Numerics.Area_Sum.
   --  A contour passed on the command line stays far below this bound.
   Max_Points : constant := 2**15;

   subtype Length_Range is Natural range 0 .. Max_Points;

   --  A variable-length list of 2D points.
   type Point_2D_Array is array (Positive range <>) of Points.Point_2D;

   --  A segment sequence represented by its vertices: n points define the
   --  n - 1 segments (P1, P2), (P2, P3), ..., (Pn-1, Pn). Storing points
   --  instead of segment endpoints makes continuity structural.
   type Segment_Sequence_2D (Length : Length_Range := 0) is record
      Points : Point_2D_Array (1 .. Length);
   end record;

   --  The sequence is closed, that is, forms a loop, when its first and
   --  last points coincide. A single point is trivially closed; an empty
   --  sequence is not.
   function Is_Closed (S : Segment_Sequence_2D) return Boolean is
     (S.Length >= 1 and then S.Points (1) = S.Points (S.Length));

   --  The sequence is valid when no segment is degenerate and no three
   --  consecutive points are collinear, so that every point of the
   --  chain has a well-defined turning direction. Sequences of less
   --  than two points are vacuously valid.
   function Is_Valid (S : Segment_Sequence_2D) return Boolean is
     ((for all I in 2 .. S.Length =>
         not Segments.Is_Degenerate
           (Segments.Segment_2D'
              (From_Point => S.Points (I - 1), To_Point => S.Points (I))))
      and then
      (for all I in 2 .. S.Length =>
        (if I < S.Length then
            not Orientations.Are_Collinear
              (S.Points (I - 1), S.Points (I), S.Points (I + 1)))));

   --  One term of the shoelace sum: the cross determinant of two
   --  consecutive position vectors, P.X * Q.Y - P.Y * Q.X. Coordinates
   --  belong to the grid domain, a subset of the difference domain, so
   --  the term is exactly computed in the Determinant domain.
   function Shoelace_Term (P, Q : Points.Point_2D)
      return Numerics.Determinant is
     (Orientations.Cross_Determinant
        (Numerics.Vector_Component (P.X),
         Numerics.Vector_Component (P.Y),
         Numerics.Vector_Component (Q.X),
         Numerics.Vector_Component (Q.Y)));

   --  Twice the signed area enclosed by a closed sequence, by the
   --  shoelace formula: the sum of the cross determinants of the
   --  consecutive position vectors, including the closing term from
   --  the last vertex back to the first. The factor 1/2 is omitted:
   --  only the sign classifies the orientation, and the exact integer
   --  value stays available.
   function Signed_Area (S : Segment_Sequence_2D) return Numerics.Area_Sum
     with Pre => S.Length >= 3 and then Is_Closed (S);

   --  Orientation of a closed, valid sequence.
   type Contour_Orientation is (Counter_Clockwise, Clockwise, Degenerate);

   --  Exact classification of a closed, valid sequence by the sign of
   --  its signed area: no tolerance, no approximation, no division.
   function Orientation (S : Segment_Sequence_2D) return Contour_Orientation
     with
        Pre =>
          S.Length >= 3 and then Is_Closed (S) and then Is_Valid (S),
        Post =>
          (if Orientation'Result = Counter_Clockwise then
              Signed_Area (S) > 0
           elsif Orientation'Result = Clockwise then
              Signed_Area (S) < 0
           else
              Signed_Area (S) = 0);

   --  A point intersection of two segments is a shared endpoint when the
   --  common position is an endpoint of both: a valid junction, not a
   --  self-intersection.
   function Is_Shared_Endpoint (A, B : Segments.Segment_2D) return Boolean is
     (Intersections.Intersection (A, B).Kind
        = Intersections.Point_Intersection
      and then
      ((Intersections.Intersection (A, B).Point = A.From_Point
        or else Intersections.Intersection (A, B).Point = A.To_Point)
       and then
       (Intersections.Intersection (A, B).Point = B.From_Point
        or else Intersections.Intersection (A, B).Point = B.To_Point)));

   --  Two segments cross when they share a grid position that is not a
   --  shared endpoint, or a sub-segment of positive length: the exact
   --  intersection is an overlap, or a single common position that is
   --  not an endpoint of both segments. Two segments that properly
   --  cross at a non-grid position share no grid position, so they do
   --  not cross in the discrete model.
   function Crosses (A, B : Segments.Segment_2D) return Boolean is
     (Intersections.Intersection (A, B).Kind = Intersections.Overlap
      or else
      (Intersections.Intersection (A, B).Kind
         = Intersections.Point_Intersection
       and then not Is_Shared_Endpoint (A, B)));

   --  The sequence self-intersects when two non-consecutive segments
   --  cross. Consecutive segments, which share an endpoint by
   --  construction, are never compared.
   function Self_Intersects (S : Segment_Sequence_2D) return Boolean is
     (for some I in 1 .. S.Length =>
        (for some J in 1 .. S.Length =>
           (J >= I + 2
            and then J + 1 <= S.Length
            and then
              Crosses
                (Segments.Segment_2D'
                   (From_Point => S.Points (I), To_Point => S.Points (I + 1)),
                 Segments.Segment_2D'
                   (From_Point => S.Points (J),
                    To_Point   => S.Points (J + 1))))));

end TopoProof.Geometry.Segment_Sequences;

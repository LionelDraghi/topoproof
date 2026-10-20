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
   function Is_Closed (S : Segment_Sequence_2D) return Boolean
   is (S.Length >= 1 and then S.Points (1) = S.Points (S.Length));

   --  The sequence is valid when no segment is degenerate: an edge exists
   --  between two consecutive points only when the two points differ.
   --  This is the geometric validity of the chain. Redundant points on
   --  the chain, such as intermediate collinear points, are a matter of
   --  representation, not of validity: they are observable separately
   --  with Has_No_Flat_Turns. Sequences of less than two points are
   --  vacuously valid.
   function Is_Valid (S : Segment_Sequence_2D) return Boolean
   is (for all I in 2 .. S.Length =>
          not Segments.Is_Degenerate
                 (Segments.Segment_2D'(From_Point => S.Points (I - 1), To_Point => S.Points (I))));

   --  The sequence has no flat turns when no three consecutive points are
   --  collinear, so that every point of the chain has a well-defined
   --  turning direction. A valid sequence with a flat turn describes the
   --  same geometry as the same sequence without the redundant point, so
   --  the absence of flat turns is a canonical-representation property,
   --  not a validity rule.
   function Has_No_Flat_Turns (S : Segment_Sequence_2D) return Boolean
   is (for all I in 2 .. S.Length =>
          (if I < S.Length
           then not Orientations.Are_Collinear (S.Points (I - 1), S.Points (I), S.Points (I + 1))));

   --  One term of the shoelace sum: the cross determinant of two
   --  consecutive position vectors, P.X * Q.Y - P.Y * Q.X. Coordinates
   --  belong to the grid domain, a subset of the difference domain, so
   --  the term is exactly computed in the Determinant domain.
   function Shoelace_Term (P, Q : Points.Point_2D) return Numerics.Determinant
   is (Orientations.Cross_Determinant
          (Numerics.Vector_Component (P.X),
           Numerics.Vector_Component (P.Y),
           Numerics.Vector_Component (Q.X),
           Numerics.Vector_Component (Q.Y)));

   --  The largest absolute value of one shoelace term: each term is a
   --  determinant of the proved expression chain, so its amplitude is
   --  bounded by the Determinant domain.
   Max_Shoelace_Term : constant Numerics.Area_Sum := Numerics.Area_Sum (Numerics.Determinant'Last);

   --  The shoelace sum of the terms with indices From .. To - 1 of the
   --  sequence S: the building block of Signed_Area and of the invariance
   --  lemmas. The contract characterizes the sum by its back one-step
   --  decomposition, peeling the last term, and bounds its amplitude;
   --  the body decreases the range by one at a time, so the decomposition
   --  holds at every step. The front decomposition is the object of the
   --  ghost procedure Lemma_Peel_Front below. Partial sums of at most
   --  Max_Points terms, each bounded by Max_Shoelace_Term, stay inside
   --  the Area_Sum domain.
   function Partial_Sum (S : Segment_Sequence_2D; From, To : Positive) return Numerics.Area_Sum
   with
      Pre                => 1 <= From and then From <= To and then To <= S.Length,
      Subprogram_Variant => (Decreases => To - From),
      Post               =>
         (if From = To
          then Partial_Sum'Result = 0
          else
             Partial_Sum'Result
             = Partial_Sum (S, From, To - 1)
               + Numerics.Area_Sum (Shoelace_Term (S.Points (To - 1), S.Points (To))))
         and then abs Partial_Sum'Result <= Numerics.Area_Sum (To - From) * Max_Shoelace_Term;

   --  Twice the signed area enclosed by a closed sequence, by the
   --  shoelace formula: the sum of the cross determinants of the
   --  consecutive position vectors, including the closing term from
   --  the last vertex back to the first. The factor 1/2 is omitted:
   --  only the sign classifies the orientation, and the exact integer
   --  value stays available.
   function Signed_Area (S : Segment_Sequence_2D) return Numerics.Area_Sum
   with
      Pre  => S.Length >= 3 and then Is_Closed (S),
      Post => Signed_Area'Result = Partial_Sum (S, 1, S.Length);

   --  Orientation of a closed, valid sequence.
   type Contour_Orientation is (Counter_Clockwise, Clockwise, Degenerate);

   --  Exact classification of a closed, valid sequence by the sign of
   --  its signed area: no tolerance, no approximation, no division.
   function Orientation (S : Segment_Sequence_2D) return Contour_Orientation
   with
      Pre  => S.Length >= 3 and then Is_Closed (S) and then Is_Valid (S),
      Post =>
         (if Orientation'Result = Counter_Clockwise
          then Signed_Area (S) > 0
          elsif Orientation'Result = Clockwise
          then Signed_Area (S) < 0
          else Signed_Area (S) = 0);

   --  A point intersection of two segments is a shared endpoint when the
   --  common position is an endpoint of both: a valid junction, not a
   --  self-intersection.
   function Is_Shared_Endpoint (A, B : Segments.Segment_2D) return Boolean
   is (Intersections.Intersection (A, B).Kind = Intersections.Point_Intersection
       and then ((Intersections.Intersection (A, B).Point = A.From_Point
                  or else Intersections.Intersection (A, B).Point = A.To_Point)
                 and then (Intersections.Intersection (A, B).Point = B.From_Point
                           or else Intersections.Intersection (A, B).Point = B.To_Point)));

   --  Two segments cross when they share a grid position that is not a
   --  shared endpoint, or a sub-segment of positive length: the exact
   --  intersection is an overlap, or a single common position that is
   --  not an endpoint of both segments. Two segments that properly
   --  cross at a non-grid position share no grid position, so they do
   --  not cross in the discrete model.
   function Crosses (A, B : Segments.Segment_2D) return Boolean
   is (Intersections.Intersection (A, B).Kind = Intersections.Overlap
       or else (Intersections.Intersection (A, B).Kind = Intersections.Point_Intersection
                and then not Is_Shared_Endpoint (A, B)));

   --  The sequence self-intersects when two non-consecutive segments
   --  cross. Consecutive segments, which share an endpoint by
   --  construction, are never compared.
   function Self_Intersects (S : Segment_Sequence_2D) return Boolean
   is (for some I in 1 .. S.Length =>
          (for some J in 1 .. S.Length =>
              (J >= I + 2
               and then J + 1 <= S.Length
               and then Crosses
                           (Segments.Segment_2D'
                               (From_Point => S.Points (I), To_Point => S.Points (I + 1)),
                            Segments.Segment_2D'
                               (From_Point => S.Points (J), To_Point => S.Points (J + 1))))));

   ---------------------------------------------------------------------------
   --  Invariance lemmas
   --
   --  The lemmas below are ghost code: they carry no run-time cost and
   --  cannot influence the kernel results. They establish that the signed
   --  area, hence the orientation, is a property of the closed chain
   --  itself: it does not depend on the vertex where the chain starts,
   --  and traversing the chain in the opposite direction negates the
   --  signed area and mirrors the orientation.
   ---------------------------------------------------------------------------

   --  The closed sequence S rotated by K vertices, 1 <= K: the same
   --  closed chain described from a different vertex. The point contract
   --  states the cyclic index shift explicitly; rotation preserves
   --  closure and validity because it permutes the same edges.
   function Rotated (S : Segment_Sequence_2D; K : Natural) return Segment_Sequence_2D
   with
      Ghost,
      Pre  => S.Length >= 3 and then Is_Closed (S) and then K in 1 .. S.Length - 2,
      Post =>
         Rotated'Result.Length = S.Length
         and then Is_Closed (Rotated'Result)
         and then (if Is_Valid (S) then Is_Valid (Rotated'Result))
         and then (for all J in 1 .. S.Length - 1 =>
                      Rotated'Result.Points (J)
                      = S.Points (if J + K <= S.Length - 1 then J + K else J + K - (S.Length - 1)));

   --  The sequence S traversed in the opposite direction, keeping the
   --  first point as the starting point of the reversed chain.
   function Reversed (S : Segment_Sequence_2D) return Segment_Sequence_2D
   with
      Ghost,
      Pre  => S.Length >= 1,
      Post =>
         Reversed'Result.Length = S.Length
         and then (for all J in 1 .. S.Length =>
                      Reversed'Result.Points (J) = S.Points (S.Length + 1 - J))
         and then (if Is_Closed (S) then Is_Closed (Reversed'Result))
         and then (if Is_Valid (S) then Is_Valid (Reversed'Result));

   --  The front one-term decomposition of the shoelace sum: the term at
   --  From plus the sum of the remaining terms. Proved by induction on
   --  the range, using only the back decomposition of the contract.
   procedure Lemma_Peel_Front (S : Segment_Sequence_2D; From, To : Positive)
   with
      Ghost,
      Pre  => 1 <= From and then From < To and then To <= S.Length,
      Post =>
         Partial_Sum (S, From, To)
         = Numerics.Area_Sum (Shoelace_Term (S.Points (From), S.Points (From + 1)))
           + Partial_Sum (S, From + 1, To);

   --  The shoelace sum splits at every intermediate index.
   procedure Lemma_Sum_Split (S : Segment_Sequence_2D; From, Mid, To : Positive)
   with
      Ghost,
      Pre  => 1 <= From and then From <= Mid and then Mid <= To and then To <= S.Length,
      Post => Partial_Sum (S, From, To) = Partial_Sum (S, From, Mid) + Partial_Sum (S, Mid, To);

   --  Cyclic-start invariance: the signed area of a closed chain does not
   --  depend on the vertex where the chain starts.
   procedure Lemma_Rotation_Invariance (S : Segment_Sequence_2D; K : Natural)
   with
      Ghost,
      Pre  => S.Length >= 3 and then Is_Closed (S) and then K in 1 .. S.Length - 2,
      Post => Signed_Area (Rotated (S, K)) = Signed_Area (S);

   --  Reversal: traversing a closed chain in the opposite direction
   --  negates the signed area.
   procedure Lemma_Reversal (S : Segment_Sequence_2D)
   with
      Ghost,
      Pre  => S.Length >= 3 and then Is_Closed (S),
      Post => Signed_Area (Reversed (S)) = -Signed_Area (S);

   --  Orientation corollaries: the orientation is invariant under
   --  rotation of the starting vertex, and mirrored by reversal.
   procedure Lemma_Orientation_Rotation (S : Segment_Sequence_2D; K : Natural)
   with
      Ghost,
      Pre  =>
         S.Length >= 3 and then Is_Closed (S) and then Is_Valid (S) and then K in 1 .. S.Length - 2,
      Post => Orientation (Rotated (S, K)) = Orientation (S);

   procedure Lemma_Orientation_Reversal (S : Segment_Sequence_2D)
   with
      Ghost,
      Pre  => S.Length >= 3 and then Is_Closed (S) and then Is_Valid (S),
      Post =>
         (case Orientation (S) is
             when Counter_Clockwise => Orientation (Reversed (S)) = Clockwise,
             when Clockwise         => Orientation (Reversed (S)) = Counter_Clockwise,
             when Degenerate        => Orientation (Reversed (S)) = Degenerate);

end TopoProof.Geometry.Segment_Sequences;

-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with TopoProof.Geometry.Orientations;
with TopoProof.Geometry.Points;
with TopoProof.Geometry.Segments;
with TopoProof.Numerics;
use type TopoProof.Geometry.Orientations.Orientation_Kind;
use type TopoProof.Geometry.Segments.Segment_2D;
use type TopoProof.Numerics.Cubic_Product;
use type TopoProof.Numerics.Determinant;
use type TopoProof.Numerics.Extended_Component;
use type TopoProof.Numerics.Grid_Coordinate;
use type TopoProof.Numerics.Vector_Component;
use type TopoProof.Geometry.Points.Point_2D;

package TopoProof.Geometry.Intersections
   with Pure, SPARK_Mode
is
   type Intersection_Kind is
     (No_Intersection,      --  the segments share no common grid position
      Point_Intersection,   --  they share exactly one grid position
      Off_Grid_Crossing,    --  they properly cross, but at a point that is
                            --  not a grid position: stated, not approximated
      Overlap);             --  they are collinear and share a sub-segment

   --  An optional point: the discriminant states whether the point exists,
   --  and the point component exists only when it does.
   type Optional_Point (Found : Boolean := False) is record
      case Found is
         when True =>
            P : Points.Point_2D;
         when False =>
            null;
      end case;
   end record;

   --  The result of the intersection: the discriminant states which data
   --  exists, so no unused field is ever present.
   type Intersection_Result (Kind : Intersection_Kind := No_Intersection) is
   record
      case Kind is
         when No_Intersection | Off_Grid_Crossing =>
            null;
         when Point_Intersection =>
            --  The common point.
            Point : Points.Point_2D;
         when Overlap =>
            --  The shared sub-segment, ordered along the common line.
            Overlap : Segments.Segment_2D;
      end case;
   end record;

   --  Lexicographic orders used to write symmetric definitions: any
   --  order-dependent computation refers to the canonically ordered pair,
   --  so exchanging the two segments cannot change any result.
   function Point_Lex_LE (P, Q : Points.Point_2D) return Boolean is
     (P.X < Q.X or else (P.X = Q.X and then P.Y <= Q.Y));

   function Segment_Lex_LE (S1, S2 : Segments.Segment_2D) return Boolean is
     (Point_Lex_LE (S1.From_Point, S2.From_Point)
      or else (S1.From_Point = S2.From_Point
               and then Point_Lex_LE (S1.To_Point, S2.To_Point)));

   --  Orientation of each endpoint of one segment seen from the other.
   function Kind_S1_S2F (S1, S2 : Segments.Segment_2D)
      return Orientations.Orientation_Kind is
     (Orientations.Orientation
         (S1.From_Point, S1.To_Point, S2.From_Point));

   function Kind_S1_S2T (S1, S2 : Segments.Segment_2D)
      return Orientations.Orientation_Kind is
     (Orientations.Orientation
         (S1.From_Point, S1.To_Point, S2.To_Point));

   function Kind_S2_S1F (S1, S2 : Segments.Segment_2D)
      return Orientations.Orientation_Kind is
     (Orientations.Orientation
         (S2.From_Point, S2.To_Point, S1.From_Point));

   function Kind_S2_S1T (S1, S2 : Segments.Segment_2D)
      return Orientations.Orientation_Kind is
     (Orientations.Orientation
         (S2.From_Point, S2.To_Point, S1.To_Point));

   --  Both segments lie on one common line: all four orientations vanish.
   function All_Four_Collinear (S1, S2 : Segments.Segment_2D) return Boolean is
     (Kind_S1_S2F (S1, S2) = Orientations.Collinear
      and then Kind_S1_S2T (S1, S2) = Orientations.Collinear
      and then Kind_S2_S1F (S1, S2) = Orientations.Collinear
      and then Kind_S2_S1T (S1, S2) = Orientations.Collinear);

   --  The segments properly cross: each segment straddles the supporting
   --  line of the other, with no endpoint on either line.
   function Properly_Crossing (S1, S2 : Segments.Segment_2D) return Boolean is
     (Kind_S1_S2F (S1, S2) /= Orientations.Collinear
      and then Kind_S1_S2T (S1, S2) /= Orientations.Collinear
      and then Kind_S2_S1F (S1, S2) /= Orientations.Collinear
      and then Kind_S2_S1T (S1, S2) /= Orientations.Collinear
      and then Kind_S1_S2F (S1, S2) /= Kind_S1_S2T (S1, S2)
      and then Kind_S2_S1F (S1, S2) /= Kind_S2_S1T (S1, S2));

   --  A point common to both segments.
   function Is_Common (P : Points.Point_2D; S1, S2 : Segments.Segment_2D)
      return Boolean is
     (Segments.Is_On_Segment (P, S1) and then Segments.Is_On_Segment (P, S2));

   --  The exact parameter of the crossing point along the first segment,
   --  as a fraction TN / TD with the second segment off the first line.
   function T_Numerator (X, Y : Segments.Segment_2D)
      return Numerics.Determinant is
     (-Orientations.Determinant
          (Y.From_Point, Y.To_Point, X.From_Point));

   function T_Denominator (X, Y : Segments.Segment_2D)
      return Numerics.Determinant is
     (Orientations.Cross_Determinant
         (Segments.Delta_X (Y), Segments.Delta_Y (Y),
          Segments.Delta_X (X), Segments.Delta_Y (X)));

   --  States whether the exact crossing of the supporting lines of X and Y
   --  falls on a grid position: both exact quotients are integers and both
   --  coordinates remain representable.
   function Crossing_On_Grid_Via (X, Y : Segments.Segment_2D) return Boolean is
     (Properly_Crossing (X, Y)
      and then
        (Numerics.Cubic_Product (T_Numerator (X, Y))
         * Numerics.Cubic_Product (Segments.Delta_X (X)))
        rem Numerics.Cubic_Product (T_Denominator (X, Y)) = 0
      and then
        (Numerics.Cubic_Product (T_Numerator (X, Y))
         * Numerics.Cubic_Product (Segments.Delta_Y (X)))
        rem Numerics.Cubic_Product (T_Denominator (X, Y)) = 0
      and then
        Numerics.Cubic_Product (X.From_Point.X)
          + (Numerics.Cubic_Product (T_Numerator (X, Y))
             * Numerics.Cubic_Product (Segments.Delta_X (X)))
            / Numerics.Cubic_Product (T_Denominator (X, Y))
        <= Numerics.Cubic_Product (Numerics.Grid_Coordinate'Last)
      and then
        Numerics.Cubic_Product (X.From_Point.X)
          + (Numerics.Cubic_Product (T_Numerator (X, Y))
             * Numerics.Cubic_Product (Segments.Delta_X (X)))
            / Numerics.Cubic_Product (T_Denominator (X, Y))
        >= Numerics.Cubic_Product (Numerics.Grid_Coordinate'First)
      and then
        Numerics.Cubic_Product (X.From_Point.Y)
          + (Numerics.Cubic_Product (T_Numerator (X, Y))
             * Numerics.Cubic_Product (Segments.Delta_Y (X)))
            / Numerics.Cubic_Product (T_Denominator (X, Y))
        <= Numerics.Cubic_Product (Numerics.Grid_Coordinate'Last)
      and then
        Numerics.Cubic_Product (X.From_Point.Y)
          + (Numerics.Cubic_Product (T_Numerator (X, Y))
             * Numerics.Cubic_Product (Segments.Delta_Y (X)))
            / Numerics.Cubic_Product (T_Denominator (X, Y))
        >= Numerics.Cubic_Product (Numerics.Grid_Coordinate'First));

   --  The exact crossing point of the supporting lines of X and Y, when
   --  the crossing falls on a grid position. The result is defined by the
   --  exact quotients TN * Delta (X) / TD on both axes.
   function Crossing_Point_Via (X, Y : Segments.Segment_2D)
      return Points.Point_2D
   with
      Pre  =>
         Properly_Crossing (X, Y)
         and then Crossing_On_Grid_Via (X, Y),
      Post =>
         Crossing_Point_Via'Result =
           (X =>
               Numerics.Grid_Coordinate
                 (Numerics.Extended_Component (X.From_Point.X)
                  + Numerics.Extended_Component
                      (Numerics.Vector_Component
                         (Numerics.Cubic_Product (T_Numerator (X, Y))
                          * Numerics.Cubic_Product (Segments.Delta_X (X))
                          / Numerics.Cubic_Product (T_Denominator (X, Y))))),
            Y =>
               Numerics.Grid_Coordinate
                 (Numerics.Extended_Component (X.From_Point.Y)
                  + Numerics.Extended_Component
                      (Numerics.Vector_Component
                         (Numerics.Cubic_Product (T_Numerator (X, Y))
                          * Numerics.Cubic_Product (Segments.Delta_Y (X))
                          / Numerics.Cubic_Product (T_Denominator (X, Y))))));

   --  The crossing helpers refer to the canonically ordered segment pair.
   function Crossing_On_Grid (S1, S2 : Segments.Segment_2D) return Boolean is
     (if Segment_Lex_LE (S1, S2) then Crossing_On_Grid_Via (S1, S2)
      else Crossing_On_Grid_Via (S2, S1));

   function Crossing_Point (S1, S2 : Segments.Segment_2D)
      return Points.Point_2D is
     (if Segment_Lex_LE (S1, S2) then Crossing_Point_Via (S1, S2)
      else Crossing_Point_Via (S2, S1))
   with
      Pre =>
         Properly_Crossing (S1, S2)
         and then Crossing_On_Grid (S1, S2);

   --  The lexicographically least endpoint, among the four endpoints of the
   --  two segments, that is common to both segments, if any.
   function Common_Endpoint (S1, S2 : Segments.Segment_2D)
      return Optional_Point is
     (if Is_Common (S1.From_Point, S1, S2)
          and then (not Is_Common (S1.To_Point, S1, S2)
                    or else Point_Lex_LE (S1.From_Point, S1.To_Point))
          and then (not Is_Common (S2.From_Point, S1, S2)
                    or else Point_Lex_LE (S1.From_Point, S2.From_Point))
          and then (not Is_Common (S2.To_Point, S1, S2)
                    or else Point_Lex_LE (S1.From_Point, S2.To_Point))
      then
         (Found => True, P => S1.From_Point)
      elsif Is_Common (S1.To_Point, S1, S2)
          and then (not Is_Common (S2.From_Point, S1, S2)
                    or else Point_Lex_LE (S1.To_Point, S2.From_Point))
          and then (not Is_Common (S2.To_Point, S1, S2)
                    or else Point_Lex_LE (S1.To_Point, S2.To_Point))
      then
         (Found => True, P => S1.To_Point)
      elsif Is_Common (S2.From_Point, S1, S2)
          and then (not Is_Common (S2.To_Point, S1, S2)
                    or else Point_Lex_LE (S2.From_Point, S2.To_Point))
      then
         (Found => True, P => S2.From_Point)
      elsif Is_Common (S2.To_Point, S1, S2)
      then
         (Found => True, P => S2.To_Point)
      else
         (Found => False));

   --  Axis used to compare positions along the common line of two
   --  collinear segments: X when either segment extends on X, else Y.
   function Along_X (S1, S2 : Segments.Segment_2D) return Boolean is
     (Segments.Delta_X (S1) /= 0 or else Segments.Delta_X (S2) /= 0);

   function Along_Coord (P : Points.Point_2D; S1, S2 : Segments.Segment_2D)
      return Numerics.Grid_Coordinate is
     (if Along_X (S1, S2) then P.X else P.Y);

   --  Interval of a segment along the common line.
   function Seg_Lo (S : Segments.Segment_2D; S1, S2 : Segments.Segment_2D)
      return Numerics.Grid_Coordinate is
     (if Along_X (S1, S2) then
         (if S.From_Point.X <= S.To_Point.X then S.From_Point.X
          else S.To_Point.X)
      else
         (if S.From_Point.Y <= S.To_Point.Y then S.From_Point.Y
          else S.To_Point.Y));

   function Seg_Hi (S : Segments.Segment_2D; S1, S2 : Segments.Segment_2D)
      return Numerics.Grid_Coordinate is
     (if Along_X (S1, S2) then
         (if S.From_Point.X <= S.To_Point.X then S.To_Point.X
          else S.From_Point.X)
      else
         (if S.From_Point.Y <= S.To_Point.Y then S.To_Point.Y
          else S.From_Point.Y));

   function Overlap_Lo (S1, S2 : Segments.Segment_2D)
      return Numerics.Grid_Coordinate is
     (if Seg_Lo (S1, S1, S2) >= Seg_Lo (S2, S1, S2)
      then Seg_Lo (S1, S1, S2) else Seg_Lo (S2, S1, S2));

   function Overlap_Hi (S1, S2 : Segments.Segment_2D)
      return Numerics.Grid_Coordinate is
     (if Seg_Hi (S1, S1, S2) <= Seg_Hi (S2, S1, S2)
      then Seg_Hi (S1, S1, S2) else Seg_Hi (S2, S1, S2));

   --  The endpoint of S whose position along the common line is V.
   function End_At (S : Segments.Segment_2D; S1, S2 : Segments.Segment_2D;
                   V : Numerics.Grid_Coordinate) return Points.Point_2D is
     (if Along_Coord (S.From_Point, S1, S2) = V then S.From_Point
      else S.To_Point);

   --  The endpoints of the shared sub-segment of two collinear segments,
   --  selected symmetrically: the segment achieving the boundary
   --  coordinate, with ties broken by the lexicographic order of points.
   function Overlap_From (S1, S2 : Segments.Segment_2D)
      return Points.Point_2D is
     (if Seg_Lo (S1, S1, S2) > Seg_Lo (S2, S1, S2) then
         End_At (S1, S1, S2, Overlap_Lo (S1, S2))
      elsif Seg_Lo (S2, S1, S2) > Seg_Lo (S1, S1, S2) then
         End_At (S2, S1, S2, Overlap_Lo (S1, S2))
      elsif Point_Lex_LE (End_At (S1, S1, S2, Overlap_Lo (S1, S2)),
                          End_At (S2, S1, S2, Overlap_Lo (S1, S2)))
      then
         End_At (S1, S1, S2, Overlap_Lo (S1, S2))
      else
         End_At (S2, S1, S2, Overlap_Lo (S1, S2)));

   function Overlap_To (S1, S2 : Segments.Segment_2D)
      return Points.Point_2D is
     (if Seg_Hi (S1, S1, S2) < Seg_Hi (S2, S1, S2) then
         End_At (S1, S1, S2, Overlap_Hi (S1, S2))
      elsif Seg_Hi (S2, S1, S2) < Seg_Hi (S1, S1, S2) then
         End_At (S2, S1, S2, Overlap_Hi (S1, S2))
      elsif Point_Lex_LE (End_At (S1, S1, S2, Overlap_Hi (S1, S2)),
                          End_At (S2, S1, S2, Overlap_Hi (S1, S2)))
      then
         End_At (S1, S1, S2, Overlap_Hi (S1, S2))
      else
         End_At (S2, S1, S2, Overlap_Hi (S1, S2)));

   --  Intersection of two collinear segments, by exact one-dimensional
   --  interval arithmetic on the common line.
   function Collinear_Intersection (S1, S2 : Segments.Segment_2D)
      return Intersection_Result is
     (if Segments.Is_Degenerate (S1) and then Segments.Is_Degenerate (S2) then
         (if S1.From_Point = S2.From_Point then
             (Kind => Point_Intersection, Point => S1.From_Point)
          else
             (Kind => No_Intersection))
      elsif Segments.Is_Degenerate (S1) then
         (if Is_Common (S1.From_Point, S1, S2) then
             (Kind => Point_Intersection, Point => S1.From_Point)
          else
             (Kind => No_Intersection))
      elsif Segments.Is_Degenerate (S2) then
         (if Is_Common (S2.From_Point, S1, S2) then
             (Kind => Point_Intersection, Point => S2.From_Point)
          else
             (Kind => No_Intersection))
      elsif Overlap_Lo (S1, S2) > Overlap_Hi (S1, S2) then
         (Kind => No_Intersection)
      elsif Overlap_Lo (S1, S2) = Overlap_Hi (S1, S2) then
         (Kind => Point_Intersection, Point => Overlap_From (S1, S2))
      else
         (Kind => Overlap,
          Overlap =>
            (From_Point => Overlap_From (S1, S2),
             To_Point   => Overlap_To (S1, S2))));

   --  Exact intersection of two segments: one of four kinds, with the
   --  common point or the shared sub-segment as data. Every
   --  order-dependent computation refers to the canonically ordered pair,
   --  so the result does not depend on the argument order.
   function Intersection (S1, S2 : Segments.Segment_2D)
      return Intersection_Result is
     (if All_Four_Collinear (S1, S2) then
         Collinear_Intersection (S1, S2)
      elsif Properly_Crossing (S1, S2) then
         (if Crossing_On_Grid (S1, S2) then
             (Kind => Point_Intersection, Point => Crossing_Point (S1, S2))
          else
             (Kind => Off_Grid_Crossing))
      elsif Common_Endpoint (S1, S2).Found then
         (Kind => Point_Intersection, Point => Common_Endpoint (S1, S2).P)
      else
         (Kind => No_Intersection));

   --  Exchanging the two segments does not change any result: proved over
   --  the whole domain from the symmetric definitions.
   procedure Lemma_Symmetry (Left, Right : Segments.Segment_2D)
   with
      Ghost,
      Post => Intersection (Left, Right) = Intersection (Right, Left);

   --  The reported data belongs to both segments: a point intersection is
   --  a common grid position, and an overlap is a common sub-segment with
   --  canonically ordered endpoints. Proved over the whole domain.
   procedure Lemma_Membership (S1, S2 : Segments.Segment_2D)
   with
      Ghost,
      Post =>
         (if Intersection (S1, S2).Kind = Point_Intersection then
             Is_Common (Intersection (S1, S2).Point, S1, S2)
         elsif Intersection (S1, S2).Kind = Overlap then
             Is_Common (Intersection (S1, S2).Overlap.From_Point, S1, S2)
             and then Is_Common (Intersection (S1, S2).Overlap.To_Point, S1, S2)
             and then Along_Coord (Intersection (S1, S2).Overlap.From_Point,
                                  S1, S2)
                      <= Along_Coord (Intersection (S1, S2).Overlap.To_Point,
                                      S1, S2));

end TopoProof.Geometry.Intersections;

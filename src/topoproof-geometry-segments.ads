-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with TopoProof.Geometry.Orientations;
with TopoProof.Numerics;
with TopoProof.Geometry.Points;
use type TopoProof.Numerics.Extended_Component;
use type TopoProof.Numerics.Grid_Coordinate;
use type TopoProof.Numerics.Product_Component;
use type TopoProof.Numerics.Vector_Component;
use type TopoProof.Geometry.Points.Point_2D;

package TopoProof.Geometry.Segments
   with Pure, SPARK_Mode
is
   type Segment_2D is record
      From_Point : Points.Point_2D;
      To_Point   : Points.Point_2D;
   end record;

   --  Two segments are equal exactly when both endpoints are equal.
   function "=" (Left, Right : Segment_2D) return Boolean
   with Post => "="'Result =
      (Left.From_Point = Right.From_Point and then Left.To_Point = Right.To_Point);

   --  A segment is degenerate when both endpoints coincide.
   function Is_Degenerate (S : Segment_2D) return Boolean is (S.From_Point = S.To_Point);

   --  Exact difference between the two endpoint coordinates on one axis.
   function Delta_X (S : Segment_2D) return Numerics.Vector_Component is
     (Numerics.Vector_Component
         (Numerics.Extended_Component (S.To_Point.X)
          - Numerics.Extended_Component (S.From_Point.X)));

   function Delta_Y (S : Segment_2D) return Numerics.Vector_Component is
     (Numerics.Vector_Component
         (Numerics.Extended_Component (S.To_Point.Y)
          - Numerics.Extended_Component (S.From_Point.Y)));

   --  A point is on the segment exactly when it is collinear with the two
   --  endpoints and inside their bounding box on both axes. Exact: no
   --  tolerance, no approximation.
   function Is_On_Segment (P : Points.Point_2D; S : Segment_2D) return Boolean is
     (Orientations.Are_Collinear (S.From_Point, S.To_Point, P)
      and then
        Orientations.Component_Product
          (Numerics.Vector_Component
              (Numerics.Extended_Component (P.X)
               - Numerics.Extended_Component (S.From_Point.X)),
           Numerics.Vector_Component
              (Numerics.Extended_Component (P.X)
               - Numerics.Extended_Component (S.To_Point.X)))
        <= 0
      and then
        Orientations.Component_Product
          (Numerics.Vector_Component
              (Numerics.Extended_Component (P.Y)
               - Numerics.Extended_Component (S.From_Point.Y)),
           Numerics.Vector_Component
              (Numerics.Extended_Component (P.Y)
               - Numerics.Extended_Component (S.To_Point.Y)))
        <= 0);

   --  Both endpoints are on their own segment.
   procedure Lemma_Endpoints_On (S : Segment_2D)
   with
      Ghost,
      Post => Is_On_Segment (S.From_Point, S) and then Is_On_Segment (S.To_Point, S);

   --  On a non-degenerate segment, a collinear point between the endpoints
   --  on one axis of extent is on the segment: the other axis follows from
   --  collinearity, so the bounding-box test needs only one axis of extent.
   procedure Lemma_Collinear_Between
      (P : Points.Point_2D; S : Segment_2D)
   with
      Ghost,
      Pre =>
         not Is_Degenerate (S)
         and then Orientations.Are_Collinear (S.From_Point, S.To_Point, P)
         and then
           (if Delta_X (S) /= 0 then
               Orientations.Component_Product
                  (Numerics.Vector_Component
                      (Numerics.Extended_Component (P.X)
                       - Numerics.Extended_Component (S.From_Point.X)),
                   Numerics.Vector_Component
                      (Numerics.Extended_Component (P.X)
                       - Numerics.Extended_Component (S.To_Point.X)))
               <= 0
            else
               Orientations.Component_Product
                  (Numerics.Vector_Component
                      (Numerics.Extended_Component (P.Y)
                       - Numerics.Extended_Component (S.From_Point.Y)),
                   Numerics.Vector_Component
                      (Numerics.Extended_Component (P.Y)
                       - Numerics.Extended_Component (S.To_Point.Y)))
               <= 0),
      Post => Is_On_Segment (P, S);

   --  On a non-degenerate segment, two collinear points that share their
   --  coordinate on an axis of extent are the same point: coordinates are
   --  injective along the segment direction.
   procedure Lemma_Collinear_Injective
      (P, Q : Points.Point_2D; S : Segment_2D)
   with
      Ghost,
      Pre =>
         not Is_Degenerate (S)
         and then Orientations.Are_Collinear (S.From_Point, S.To_Point, P)
         and then Orientations.Are_Collinear (S.From_Point, S.To_Point, Q)
         and then
           (if Delta_X (S) /= 0 then P.X = Q.X else P.Y = Q.Y),
      Post => P = Q;

end TopoProof.Geometry.Segments;

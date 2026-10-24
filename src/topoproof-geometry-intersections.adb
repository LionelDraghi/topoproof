-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

package body TopoProof.Geometry.Intersections
   with SPARK_Mode
is
   use type TopoProof.Numerics.Product_Component;

   function Crossing_Point_Via (X, Y : Segments.Segment_2D)
      return Points.Point_2D is
      TN : constant Numerics.Determinant := T_Numerator (X, Y);
      TD : constant Numerics.Determinant := T_Denominator (X, Y);
      QX : constant Numerics.Cubic_Product :=
        (Numerics.Cubic_Product (TN) * Numerics.Cubic_Product (Segments.Delta_X (X)))
        / Numerics.Cubic_Product (TD);
      QY : constant Numerics.Cubic_Product :=
        (Numerics.Cubic_Product (TN) * Numerics.Cubic_Product (Segments.Delta_Y (X)))
        / Numerics.Cubic_Product (TD);
   begin
      --  The precondition Crossing_On_Grid_Via guarantees that both
      --  quotients are exact and that both coordinates stay representable.
      return
        (X =>
             Numerics.Grid_Coordinate
               (Numerics.Extended_Component (X.From_Point.X)
                + Numerics.Extended_Component (Numerics.Vector_Component (QX))),
         Y =>
             Numerics.Grid_Coordinate
               (Numerics.Extended_Component (X.From_Point.Y)
                + Numerics.Extended_Component (Numerics.Vector_Component (QY))));
   end Crossing_Point_Via;

   --  If F and G have strictly opposite signs, then D = G - F has the
   --  strict sign of G and exceeds both F and G in magnitude.
   --  Consequently the exact fraction -F / D lies strictly between 0 and
   --  1, and so does the complementary fraction G / D.
   procedure Lemma_Opposite_Signs (F, G, D : Numerics.Determinant)
   with
      Ghost,
      Pre =>
         (F > 0 and then G < 0
          and then G >= F - Numerics.Determinant'Last
          and then D = G - F)
         or else
           (F < 0 and then G > 0
            and then G <= F + Numerics.Determinant'Last
            and then D = G - F),
      Post =>
         (if F > 0 then
             D < 0 and then -F < 0 and then -F > D
          else
             D > 0 and then -F > 0 and then -F < D)
   is
   begin
      null;
   end Lemma_Opposite_Signs;

   --  The denominator of the parameter along X is the difference of the
   --  two point determinants seen from the Y line.
   procedure Lemma_T_Denominator (X, Y : Segments.Segment_2D)
   with
      Ghost,
      Post =>
         T_Denominator (X, Y)
         = Orientations.Determinant (Y.From_Point, Y.To_Point, X.To_Point)
           - Orientations.Determinant (Y.From_Point, Y.To_Point, X.From_Point)
   is
   begin
      null;
   end Lemma_T_Denominator;

   --  Symmetrically, the denominator of the parameter along Y is the
   --  difference of the two point determinants seen from the X line.
   procedure Lemma_T_Cross_Denominator (X, Y : Segments.Segment_2D)
   with
      Ghost,
      Post =>
         Orientations.Cross_Determinant
            (Segments.Delta_X (X), Segments.Delta_Y (X),
             Segments.Delta_X (Y), Segments.Delta_Y (Y))
         = Orientations.Determinant (X.From_Point, X.To_Point, Y.To_Point)
           - Orientations.Determinant (X.From_Point, X.To_Point, Y.From_Point)
   is
   begin
      null;
   end Lemma_T_Cross_Denominator;

   --  On a common line, the axis of extent is the same for both segments:
   --  if either has a nonzero X extent, both do. This follows from the
   --  vanishing direction determinant of two collinear segments.
   procedure Lemma_Axis_Propagation (S, T : Segments.Segment_2D)
   with
      Ghost,
      Pre =>
         not Segments.Is_Degenerate (S)
         and then not Segments.Is_Degenerate (T)
         and then Orientations.Determinant
            (S.From_Point, S.To_Point, T.From_Point) = 0
         and then Orientations.Determinant
            (S.From_Point, S.To_Point, T.To_Point) = 0
         and then (Segments.Delta_X (S) /= 0 or else Segments.Delta_X (T) /= 0),
      Post =>
         Segments.Delta_X (S) /= 0 and then Segments.Delta_X (T) /= 0
   is
   begin
      null;
   end Lemma_Axis_Propagation;

   --  Both parameterizations describe the same crossing: a point at exact
   --  parameter TN / TD along X is at exact parameter -F1 / TCD along Y.
   --  The ratio TCD / TD is -1 by antisymmetry, which keeps every product
   --  of the identity within the Cubic_Product domain.
   procedure Lemma_Parameter_Equivalence
      (X, Y : Segments.Segment_2D; P : Points.Point_2D)
   with
      Ghost,
      Pre =>
         Properly_Crossing (X, Y)
         and then
           Numerics.Cubic_Product (T_Denominator (X, Y))
             * (Numerics.Cubic_Product (P.X)
                - Numerics.Cubic_Product (X.From_Point.X))
           = Numerics.Cubic_Product (T_Numerator (X, Y))
             * Numerics.Cubic_Product (Segments.Delta_X (X))
         and then
           Numerics.Cubic_Product (T_Denominator (X, Y))
             * (Numerics.Cubic_Product (P.Y)
                - Numerics.Cubic_Product (X.From_Point.Y))
           = Numerics.Cubic_Product (T_Numerator (X, Y))
             * Numerics.Cubic_Product (Segments.Delta_Y (X)),
      Post =>
         Numerics.Cubic_Product
            (Orientations.Cross_Determinant
                 (Segments.Delta_X (X), Segments.Delta_Y (X),
                  Segments.Delta_X (Y), Segments.Delta_Y (Y)))
           * (Numerics.Cubic_Product (P.X)
              - Numerics.Cubic_Product (Y.From_Point.X))
         = Numerics.Cubic_Product
             (-Orientations.Determinant (X.From_Point, X.To_Point, Y.From_Point))
           * Numerics.Cubic_Product (Segments.Delta_X (Y))
         and then
           Numerics.Cubic_Product
              (Orientations.Cross_Determinant
                   (Segments.Delta_X (X), Segments.Delta_Y (X),
                    Segments.Delta_X (Y), Segments.Delta_Y (Y)))
             * (Numerics.Cubic_Product (P.Y)
                - Numerics.Cubic_Product (Y.From_Point.Y))
         = Numerics.Cubic_Product
             (-Orientations.Determinant (X.From_Point, X.To_Point, Y.From_Point))
           * Numerics.Cubic_Product (Segments.Delta_Y (Y))
   is
   begin
      null;
   end Lemma_Parameter_Equivalence;

   --  Two exact quotient identities exchange their axis factors: when the
   --  same nonzero determinant scales both differences, the factors can
   --  be exchanged, as both sides equal UN * DX * DY / TCD. Proved in
   --  isolation: the degree-3 intermediate products exceed the
   --  Cubic_Product domain, so the exchange cannot be decomposed into
   --  writable rungs.
   procedure Lemma_Axis_Exchange
      (TCD, UN : Numerics.Determinant;
       DX, DY, U, V : Numerics.Vector_Component)
   with
      Ghost,
      Pre =>
         TCD /= 0
         and then
           Numerics.Cubic_Product (TCD) * Numerics.Cubic_Product (U)
         = Numerics.Cubic_Product (UN) * Numerics.Cubic_Product (DX)
         and then
           Numerics.Cubic_Product (TCD) * Numerics.Cubic_Product (V)
         = Numerics.Cubic_Product (UN) * Numerics.Cubic_Product (DY),
      Post =>
         Numerics.Cubic_Product (U) * Numerics.Cubic_Product (DY)
         = Numerics.Cubic_Product (V) * Numerics.Cubic_Product (DX)
   is
   begin
      null;
   end Lemma_Axis_Exchange;

   --  A quotient between 0 and the component difference bounds the point
   --  coordinate between the segment endpoints on that axis: the two
   --  differences from the endpoints have opposite signs, so their exact
   --  product is not positive, in the difference domain used by
   --  Is_On_Segment.
   procedure Lemma_Axis_Bounding
      (P, F, T : Numerics.Grid_Coordinate;
       Q       : Numerics.Cubic_Product;
       D       : Numerics.Vector_Component)
   with
      Ghost,
      Pre =>
         Q = Numerics.Cubic_Product (P) - Numerics.Cubic_Product (F)
         and then
           D =
            Numerics.Vector_Component
              (Numerics.Extended_Component (T)
               - Numerics.Extended_Component (F))
         and then
           Q * (Q - Numerics.Cubic_Product (D)) <= 0,
      Post =>
         Numerics.Component_Product
           (Numerics.Vector_Component
              (Numerics.Extended_Component (P)
               - Numerics.Extended_Component (F)),
            Numerics.Vector_Component
              (Numerics.Extended_Component (P)
               - Numerics.Extended_Component (T)))
         <= 0
   is
   begin
      null;
   end Lemma_Axis_Bounding;

   --  Exact quotient ordering: with UN strictly between 0 and TCD, the
   --  quotient UN * DX / TCD lies strictly between 0 and DX, and the
   --  quotient (UN - TCD) * DX / TCD lies strictly between DX and 0.
   --  Proved in isolation, like Lemma_Axis_Exchange.
   procedure Lemma_Quotient_Ordering
      (TCD, UN : Numerics.Determinant;
       DX, U, V : Numerics.Vector_Component)
   with
      Ghost,
      Pre =>
         TCD /= 0
         and then
           (if TCD > 0 then 0 < UN and then UN < TCD
            elsif TCD < 0 then TCD < UN and then UN < 0)
         and then
           Numerics.Cubic_Product (TCD) * Numerics.Cubic_Product (U)
         = Numerics.Cubic_Product (UN) * Numerics.Cubic_Product (DX)
         and then
           Numerics.Cubic_Product (TCD) * Numerics.Cubic_Product (V)
         = Numerics.Cubic_Product (UN - TCD) * Numerics.Cubic_Product (DX),
      Post =>
         (if DX > 0 then U > 0 and then V < 0
          elsif DX < 0 then U < 0 and then V > 0
          else U = 0)
   is
   begin
      null;
   end Lemma_Quotient_Ordering;

   --  When the vector from C to P is parallel to the direction (DX, DY)
   --  of C to D, the three points are collinear: the orientation
   --  determinant vanishes. Bridges the Cubic_Product domain of the
   --  parallelism identity to the Determinant domain of the orientation.
   procedure Lemma_Parallel_Collinear
      (C, D, P : Points.Point_2D;
       DX, DY  : Numerics.Vector_Component)
   with
      Ghost,
      Pre =>
         DX =
            Numerics.Vector_Component
              (Numerics.Extended_Component (D.X)
               - Numerics.Extended_Component (C.X))
         and then
           DY =
            Numerics.Vector_Component
              (Numerics.Extended_Component (D.Y)
               - Numerics.Extended_Component (C.Y))
         and then
           (Numerics.Cubic_Product (P.X) - Numerics.Cubic_Product (C.X))
             * Numerics.Cubic_Product (DY)
         = (Numerics.Cubic_Product (P.Y) - Numerics.Cubic_Product (C.Y))
             * Numerics.Cubic_Product (DX),
      Post => Orientations.Determinant (C, D, P) = 0
   is
   begin
      null;
   end Lemma_Parallel_Collinear;

   --  Membership of the exact crossing point, proved once for the
   --  canonical pair (X, Y): the crossing point of two properly crossing
   --  segments, when it falls on a grid position, is on both segments.
   procedure Crossing_Membership (X, Y : Segments.Segment_2D)
   with
      Ghost,
      Pre =>
         Properly_Crossing (X, Y)
         and then Crossing_On_Grid_Via (X, Y),
      Post => Is_Common (Crossing_Point_Via (X, Y), X, Y)
   is
      A  : Points.Point_2D renames X.From_Point;
      B  : Points.Point_2D renames X.To_Point;
      C  : Points.Point_2D renames Y.From_Point;
      D  : Points.Point_2D renames Y.To_Point;
      F1 : constant Numerics.Determinant :=
        Orientations.Determinant (A, B, C);
      F2 : constant Numerics.Determinant :=
        Orientations.Determinant (A, B, D);
      F3 : constant Numerics.Determinant :=
        Orientations.Determinant (C, D, A);
      F4 : constant Numerics.Determinant :=
        Orientations.Determinant (C, D, B);
      TN : constant Numerics.Determinant := T_Numerator (X, Y);
      TD : constant Numerics.Determinant := T_Denominator (X, Y);
      P  : constant Points.Point_2D := Crossing_Point_Via (X, Y);
      QX : constant Numerics.Cubic_Product := Crossing_Step_X (X, Y);
      QY : constant Numerics.Cubic_Product := Crossing_Step_Y (X, Y);
      TCD : constant Numerics.Determinant :=
        Orientations.Cross_Determinant
          (Segments.Delta_X (X), Segments.Delta_Y (X),
           Segments.Delta_X (Y), Segments.Delta_Y (Y));
      UN : constant Numerics.Determinant := -F1;
   begin
      --  The four orientation kinds give the signs of the four point
      --  determinants: F1 and F2 are opposite, F3 and F4 are opposite.
      Lemma_T_Denominator (X, Y);
      Lemma_T_Cross_Denominator (X, Y);
      Lemma_Opposite_Signs (F3, F4, TD);
      Lemma_Opposite_Signs (F1, F2, TCD);
      Orientations.Lemma_Cross_Antisymmetry
        (Segments.Delta_X (X), Segments.Delta_Y (X),
         Segments.Delta_X (Y), Segments.Delta_Y (Y));

      --  Exact quotients: TD * QX = TN * DX and TD * QY = TN * DY,
      --  and the crossing point is A plus the quotients on both axes.
      pragma Assert
        (Numerics.Cubic_Product (TD) * QX
         = Numerics.Cubic_Product (TN) * Numerics.Cubic_Product (Segments.Delta_X (X)));
      pragma Assert
        (Numerics.Cubic_Product (TD) * QY
         = Numerics.Cubic_Product (TN) * Numerics.Cubic_Product (Segments.Delta_Y (X)));
      pragma Assert
        (Numerics.Cubic_Product (P.X) - Numerics.Cubic_Product (A.X) = QX
         and then Numerics.Cubic_Product (P.Y) - Numerics.Cubic_Product (A.Y) = QY);

      --  The fraction TN / TD is strictly between 0 and 1: TN and TD
      --  share a strict sign, and TD - TN = F4 does too.
      pragma Assert
        ((TN > 0 and then TD > 0) or else (TN < 0 and then TD < 0));
      pragma Assert
        (TD - TN = F4
         and then ((TD - TN > 0 and then TD > 0)
                   or else (TD - TN < 0 and then TD < 0)));
      --  Consequently each quotient lies strictly between 0 and the
      --  corresponding component difference: the fraction TN / TD is
      --  strictly inside (0, 1), and each step is that fraction of
      --  the corresponding component difference.
      pragma Assert
        ((if Segments.Delta_X (X) > 0 then
             0 < QX and then QX < Numerics.Cubic_Product (Segments.Delta_X (X))
         elsif Segments.Delta_X (X) < 0 then
             0 > QX and then QX > Numerics.Cubic_Product (Segments.Delta_X (X))
         else
             QX = 0));
      pragma Assert
        ((if Segments.Delta_Y (X) > 0 then
             0 < QY and then QY < Numerics.Cubic_Product (Segments.Delta_Y (X))
         elsif Segments.Delta_Y (X) < 0 then
             0 > QY and then QY > Numerics.Cubic_Product (Segments.Delta_Y (X))
         else
             QY = 0));

      --  The strict betweenness rewrites as the product identities:
      --  TD * (DX - QX) = (TD - TN) * DX, and likewise on Y. The
      --  betweenness above bounds the left products, so their
      --  overflow checks are immediate.
      pragma Assert
        (Numerics.Cubic_Product (TD)
           * (Numerics.Cubic_Product (Segments.Delta_X (X)) - QX)
         = Numerics.Cubic_Product (TD - TN)
           * Numerics.Cubic_Product (Segments.Delta_X (X)));
      pragma Assert
        (Numerics.Cubic_Product (TD)
           * (Numerics.Cubic_Product (Segments.Delta_Y (X)) - QY)
         = Numerics.Cubic_Product (TD - TN)
           * Numerics.Cubic_Product (Segments.Delta_Y (X)));

      --  The quotients exchange the axis factors: DX * QY = DY * QX,
      --  because both equal TN * DX * DY / TD.
      pragma Assert
        (Numerics.Cubic_Product (Segments.Delta_X (X)) * QY
         = Numerics.Cubic_Product (Segments.Delta_Y (X)) * QX);
      pragma Assert
        (QX * (QX - Numerics.Cubic_Product (Segments.Delta_X (X))) <= 0
         and then QY * (QY - Numerics.Cubic_Product (Segments.Delta_Y (X))) <= 0);

      --  The crossing point is collinear with both supporting lines.
      pragma Assert (Orientations.Determinant (A, B, P) = 0);

      --  Both parameterizations describe the same crossing, so the same
      --  reasoning along Y shows the point is also between C and D.
      Lemma_Parameter_Equivalence (X, Y, P);
      pragma Assert
        ((UN > 0 and then TCD > 0) or else (UN < 0 and then TCD < 0));
      pragma Assert
        (TCD - UN = F2
         and then ((TCD - UN > 0 and then TCD > 0)
                   or else (TCD - UN < 0 and then TCD < 0)));
      --  Along Y, the quotients exchange the axis factors as well, and
      --  the same strict betweenness holds on both axes.
      pragma Assert
        (Numerics.Cubic_Product (TCD)
           * (Numerics.Cubic_Product (P.X) - Numerics.Cubic_Product (C.X))
         = Numerics.Cubic_Product (UN)
           * Numerics.Cubic_Product (Segments.Delta_X (Y)));
      pragma Assert
        (Numerics.Cubic_Product (TCD)
           * (Numerics.Cubic_Product (P.X) - Numerics.Cubic_Product (D.X))
         = Numerics.Cubic_Product (UN - TCD)
           * Numerics.Cubic_Product (Segments.Delta_X (Y)));
      pragma Assert
        (Numerics.Cubic_Product (TCD)
           * (Numerics.Cubic_Product (P.Y) - Numerics.Cubic_Product (C.Y))
         = Numerics.Cubic_Product (UN)
           * Numerics.Cubic_Product (Segments.Delta_Y (Y)));
      pragma Assert
        (Numerics.Cubic_Product (TCD)
           * (Numerics.Cubic_Product (P.Y) - Numerics.Cubic_Product (D.Y))
         = Numerics.Cubic_Product (UN - TCD)
           * Numerics.Cubic_Product (Segments.Delta_Y (Y)));
      --  The quotient along Y lies strictly between the endpoints of Y
      --  on both axes.
      Lemma_Quotient_Ordering
        (TCD,
         UN,
         Segments.Delta_X (Y),
         Numerics.Vector_Component
           (Numerics.Extended_Component (P.X)
            - Numerics.Extended_Component (C.X)),
         Numerics.Vector_Component
           (Numerics.Extended_Component (P.X)
            - Numerics.Extended_Component (D.X)));
      pragma Assert
        ((if Segments.Delta_X (Y) > 0 then
             Numerics.Cubic_Product (C.X) < Numerics.Cubic_Product (P.X)
             and then Numerics.Cubic_Product (P.X) < Numerics.Cubic_Product (D.X)
         elsif Segments.Delta_X (Y) < 0 then
             Numerics.Cubic_Product (C.X) > Numerics.Cubic_Product (P.X)
             and then Numerics.Cubic_Product (P.X) > Numerics.Cubic_Product (D.X)
         else
             P.X = C.X));
      Lemma_Quotient_Ordering
        (TCD,
         UN,
         Segments.Delta_Y (Y),
         Numerics.Vector_Component
           (Numerics.Extended_Component (P.Y)
            - Numerics.Extended_Component (C.Y)),
         Numerics.Vector_Component
           (Numerics.Extended_Component (P.Y)
            - Numerics.Extended_Component (D.Y)));
      pragma Assert
        ((if Segments.Delta_Y (Y) > 0 then
             Numerics.Cubic_Product (C.Y) < Numerics.Cubic_Product (P.Y)
             and then Numerics.Cubic_Product (P.Y) < Numerics.Cubic_Product (D.Y)
         elsif Segments.Delta_Y (Y) < 0 then
             Numerics.Cubic_Product (C.Y) > Numerics.Cubic_Product (P.Y)
             and then Numerics.Cubic_Product (P.Y) > Numerics.Cubic_Product (D.Y)
         else
             P.Y = C.Y));
      --  The two quotient identities exchange their axis factors: the
      --  vector from C to the crossing point is parallel to Y.
      Lemma_Axis_Exchange
        (TCD,
         UN,
         Segments.Delta_X (Y),
         Segments.Delta_Y (Y),
         Numerics.Vector_Component
           (Numerics.Extended_Component (P.X)
            - Numerics.Extended_Component (C.X)),
         Numerics.Vector_Component
           (Numerics.Extended_Component (P.Y)
            - Numerics.Extended_Component (C.Y)));
      pragma Assert
        ((Numerics.Cubic_Product (P.X) - Numerics.Cubic_Product (C.X))
           * Numerics.Cubic_Product (Segments.Delta_Y (Y))
         = (Numerics.Cubic_Product (P.Y) - Numerics.Cubic_Product (C.Y))
           * Numerics.Cubic_Product (Segments.Delta_X (Y)));
      pragma Assert
        ((Numerics.Cubic_Product (P.X) - Numerics.Cubic_Product (C.X))
           * (Numerics.Cubic_Product (P.X) - Numerics.Cubic_Product (D.X)) <= 0
         and then
           (Numerics.Cubic_Product (P.Y) - Numerics.Cubic_Product (C.Y))
           * (Numerics.Cubic_Product (P.Y) - Numerics.Cubic_Product (D.Y)) <= 0);
      --  The vector from C to the crossing point is parallel to Y, so the
      --  three points are collinear.
      Lemma_Parallel_Collinear
        (C, D, P, Segments.Delta_X (Y), Segments.Delta_Y (Y));
      pragma Assert (Orientations.Determinant (C, D, P) = 0);

      --  The bounding boxes of both segments contain the crossing point.
      --  The quotients bound the crossing point between the endpoints of
      --  X on both axes, in the difference domain of Is_On_Segment.
      Lemma_Axis_Bounding
        (P.X, X.From_Point.X, X.To_Point.X, QX, Segments.Delta_X (X));
      Lemma_Axis_Bounding
        (P.Y, X.From_Point.Y, X.To_Point.Y, QY, Segments.Delta_Y (X));
      pragma Assert (Segments.Is_On_Segment (P, X));
      pragma Assert (Segments.Is_On_Segment (P, Y));
   end Crossing_Membership;

   --  Membership for two collinear segments: any point or overlap
   --  boundary reported by the interval analysis is on both segments.
   procedure Collinear_Membership (S1, S2 : Segments.Segment_2D)
   with
      Ghost,
      Pre =>
         All_Four_Collinear (S1, S2)
         and then Collinear_Intersection (S1, S2).Kind
                    = Intersection (S1, S2).Kind,
      Post =>
         (if Intersection (S1, S2).Kind = Point_Intersection then
             Is_Common (Intersection (S1, S2).Point, S1, S2)
          elsif Intersection (S1, S2).Kind = Overlap then
             Is_Common (Intersection (S1, S2).Overlap.From_Point, S1, S2)
             and then Is_Common (Intersection (S1, S2).Overlap.To_Point, S1, S2)
             and then Along_Coord (Intersection (S1, S2).Overlap.From_Point, S1, S2)
                      <= Along_Coord (Intersection (S1, S2).Overlap.To_Point, S1, S2))
   is
      R : constant Intersection_Result := Collinear_Intersection (S1, S2);

      --  A reported point on the common line, between the endpoints of
      --  the other segment on the axis of extent, is on that segment.
      procedure On_Other (P : Points.Point_2D; Own, Other : Segments.Segment_2D)
      with
         Ghost,
         Pre =>
            not Segments.Is_Degenerate (Own)
            and then not Segments.Is_Degenerate (Other)
            and then Orientations.Determinant
               (Own.From_Point, Own.To_Point, Other.From_Point) = 0
            and then Orientations.Determinant
               (Own.From_Point, Own.To_Point, Other.To_Point) = 0
            and then Orientations.Are_Collinear
               (Other.From_Point, Other.To_Point, P)
            and then
              (if Along_X (Own, Other) then
                  (Other.From_Point.X <= P.X and then P.X <= Other.To_Point.X)
                  or else (Other.To_Point.X <= P.X and then P.X <= Other.From_Point.X)
               else
                  (Other.From_Point.Y <= P.Y and then P.Y <= Other.To_Point.Y)
                  or else (Other.To_Point.Y <= P.Y and then P.Y <= Other.From_Point.Y)),
         Post => Segments.Is_On_Segment (P, Other)
      is
         DXF : constant Numerics.Vector_Component :=
           Numerics.Vector_Component
             (Numerics.Extended_Component (P.X)
              - Numerics.Extended_Component (Other.From_Point.X));
         DXT : constant Numerics.Vector_Component :=
           Numerics.Vector_Component
             (Numerics.Extended_Component (P.X)
              - Numerics.Extended_Component (Other.To_Point.X));
         DYF : constant Numerics.Vector_Component :=
           Numerics.Vector_Component
             (Numerics.Extended_Component (P.Y)
              - Numerics.Extended_Component (Other.From_Point.Y));
         DYT : constant Numerics.Vector_Component :=
           Numerics.Vector_Component
             (Numerics.Extended_Component (P.Y)
              - Numerics.Extended_Component (Other.To_Point.Y));
      begin
         if Along_X (Own, Other) then
            Lemma_Axis_Propagation (Own, Other);
            if Other.From_Point.X <= Other.To_Point.X then
               pragma Assert
                 (Other.From_Point.X <= P.X and then P.X <= Other.To_Point.X);
            else
               pragma Assert
                 (Other.To_Point.X <= P.X and then P.X <= Other.From_Point.X);
            end if;
            pragma Assert (Numerics.Component_Product (DXF, DXT) <= 0);
         else
            if Other.From_Point.Y <= Other.To_Point.Y then
               pragma Assert
                 (Other.From_Point.Y <= P.Y and then P.Y <= Other.To_Point.Y);
            else
               pragma Assert
                 (Other.To_Point.Y <= P.Y and then P.Y <= Other.From_Point.Y);
            end if;
            pragma Assert (Numerics.Component_Product (DYF, DYT) <= 0);
         end if;
         Segments.Lemma_Collinear_Between (P, Other);
      end On_Other;

      --  The low boundary of the shared interval: an endpoint of one
      --  segment at the shared lower coordinate, common to both.
      procedure Common_From (P : Points.Point_2D)
      with
         Ghost,
         Pre =>
            P = Overlap_From (S1, S2)
            and then not Segments.Is_Degenerate (S1)
            and then not Segments.Is_Degenerate (S2)
            and then All_Four_Collinear (S1, S2)
            and then Overlap_Lo (S1, S2) <= Overlap_Hi (S1, S2)
            and then (if Along_X (S1, S2)
                      then Segments.Delta_X (S1) /= 0
                           and then Segments.Delta_X (S2) /= 0),
         Post =>
            Is_Common (P, S1, S2)
            and then Along_Coord (P, S1, S2) = Overlap_Lo (S1, S2)
      is
      begin
         Segments.Lemma_Endpoints_On (S1);
         Segments.Lemma_Endpoints_On (S2);
         if Seg_Lo (S1, S1, S2) > Seg_Lo (S2, S1, S2)
            or else
              (Seg_Lo (S1, S1, S2) = Seg_Lo (S2, S1, S2)
               and then
                 Point_Lex_LE (End_At (S1, S1, S2, Overlap_Lo (S1, S2)),
                               End_At (S2, S1, S2, Overlap_Lo (S1, S2))))
         then
            pragma Assert (P = End_At (S1, S1, S2, Overlap_Lo (S1, S2)));
            pragma Assert (Along_Coord (P, S1, S2) = Overlap_Lo (S1, S2));
            pragma Assert (Segments.Is_On_Segment (P, S1));
            pragma Assert (Along_Coord (P, S1, S2) >= Seg_Lo (S2, S1, S2)
               and then Along_Coord (P, S1, S2) <= Seg_Hi (S2, S1, S2));
            pragma Assert
              ((if Along_X (S1, S2) then
                   (S2.From_Point.X <= P.X and then P.X <= S2.To_Point.X)
                   or else (S2.To_Point.X <= P.X and then P.X <= S2.From_Point.X)
                else
                   (S2.From_Point.Y <= P.Y and then P.Y <= S2.To_Point.Y)
                   or else (S2.To_Point.Y <= P.Y and then P.Y <= S2.From_Point.Y)));
            pragma Assert
              (Orientations.Determinant
                  (S1.From_Point, S1.To_Point, S2.From_Point) = 0
               and then Orientations.Determinant
                  (S1.From_Point, S1.To_Point, S2.To_Point) = 0);
            On_Other (P, S1, S2);
         else
            pragma Assert (P = End_At (S2, S1, S2, Overlap_Lo (S1, S2)));
            pragma Assert (Along_Coord (P, S1, S2) = Overlap_Lo (S1, S2));
            pragma Assert (Segments.Is_On_Segment (P, S2));
            pragma Assert (Along_Coord (P, S1, S2) >= Seg_Lo (S1, S1, S2)
               and then Along_Coord (P, S1, S2) <= Seg_Hi (S1, S1, S2));
            pragma Assert
              ((if Along_X (S1, S2) then
                   (S1.From_Point.X <= P.X and then P.X <= S1.To_Point.X)
                   or else (S1.To_Point.X <= P.X and then P.X <= S1.From_Point.X)
                else
                   (S1.From_Point.Y <= P.Y and then P.Y <= S1.To_Point.Y)
                   or else (S1.To_Point.Y <= P.Y and then P.Y <= S1.From_Point.Y)));
            pragma Assert
              (Orientations.Determinant
                  (S2.From_Point, S2.To_Point, S1.From_Point) = 0
               and then Orientations.Determinant
                  (S2.From_Point, S2.To_Point, S1.To_Point) = 0);
            On_Other (P, S2, S1);
         end if;
      end Common_From;

      --  The high boundary of the shared interval, symmetrically.
      procedure Common_To (P : Points.Point_2D)
      with
         Ghost,
         Pre =>
            P = Overlap_To (S1, S2)
            and then not Segments.Is_Degenerate (S1)
            and then not Segments.Is_Degenerate (S2)
            and then All_Four_Collinear (S1, S2)
            and then Overlap_Lo (S1, S2) <= Overlap_Hi (S1, S2)
            and then (if Along_X (S1, S2)
                      then Segments.Delta_X (S1) /= 0
                           and then Segments.Delta_X (S2) /= 0),
         Post =>
            Is_Common (P, S1, S2)
            and then Along_Coord (P, S1, S2) = Overlap_Hi (S1, S2)
      is
      begin
         Segments.Lemma_Endpoints_On (S1);
         Segments.Lemma_Endpoints_On (S2);
         if Seg_Hi (S1, S1, S2) < Seg_Hi (S2, S1, S2)
            or else
              (Seg_Hi (S1, S1, S2) = Seg_Hi (S2, S1, S2)
               and then
                 Point_Lex_LE (End_At (S1, S1, S2, Overlap_Hi (S1, S2)),
                               End_At (S2, S1, S2, Overlap_Hi (S1, S2))))
         then
            pragma Assert (P = End_At (S1, S1, S2, Overlap_Hi (S1, S2)));
            pragma Assert (Along_Coord (P, S1, S2) = Overlap_Hi (S1, S2));
            pragma Assert (Segments.Is_On_Segment (P, S1));
            pragma Assert (Along_Coord (P, S1, S2) >= Seg_Lo (S2, S1, S2)
               and then Along_Coord (P, S1, S2) <= Seg_Hi (S2, S1, S2));
            pragma Assert
              ((if Along_X (S1, S2) then
                   (S2.From_Point.X <= P.X and then P.X <= S2.To_Point.X)
                   or else (S2.To_Point.X <= P.X and then P.X <= S2.From_Point.X)
                else
                   (S2.From_Point.Y <= P.Y and then P.Y <= S2.To_Point.Y)
                   or else (S2.To_Point.Y <= P.Y and then P.Y <= S2.From_Point.Y)));
            pragma Assert
              (Orientations.Determinant
                  (S1.From_Point, S1.To_Point, S2.From_Point) = 0
               and then Orientations.Determinant
                  (S1.From_Point, S1.To_Point, S2.To_Point) = 0);
            On_Other (P, S1, S2);
         else
            pragma Assert (P = End_At (S2, S1, S2, Overlap_Hi (S1, S2)));
            pragma Assert (Along_Coord (P, S1, S2) = Overlap_Hi (S1, S2));
            pragma Assert (Segments.Is_On_Segment (P, S2));
            pragma Assert (Along_Coord (P, S1, S2) >= Seg_Lo (S1, S1, S2)
               and then Along_Coord (P, S1, S2) <= Seg_Hi (S1, S1, S2));
            pragma Assert
              ((if Along_X (S1, S2) then
                   (S1.From_Point.X <= P.X and then P.X <= S1.To_Point.X)
                   or else (S1.To_Point.X <= P.X and then P.X <= S1.From_Point.X)
                else
                   (S1.From_Point.Y <= P.Y and then P.Y <= S1.To_Point.Y)
                   or else (S1.To_Point.Y <= P.Y and then P.Y <= S1.From_Point.Y)));
            pragma Assert
              (Orientations.Determinant
                  (S2.From_Point, S2.To_Point, S1.From_Point) = 0
               and then Orientations.Determinant
                  (S2.From_Point, S2.To_Point, S1.To_Point) = 0);
            On_Other (P, S2, S1);
         end if;
      end Common_To;

   begin
      Segments.Lemma_Endpoints_On (S1);
      Segments.Lemma_Endpoints_On (S2);
      if R.Kind = Point_Intersection or else R.Kind = Overlap then
         if Segments.Is_Degenerate (S1) and then Segments.Is_Degenerate (S2) then
            --  Both degenerate: a common point only when identical, and a
            --  degenerate segment contains its own endpoint.
            pragma Assert (Is_Common (R.Point, S1, S2));

         elsif Segments.Is_Degenerate (S1) then
            --  The guard of the branch is exactly Is_Common.
            pragma Assert (Is_Common (R.Point, S1, S2));

         elsif Segments.Is_Degenerate (S2) then
            --  The point is the degenerate S2, which lies on S1 only when
            --  the branch guard holds; the guard is Is_Common.
            pragma Assert (Is_Common (R.Point, S1, S2));

         else
            --  Both segments are real and collinear: the reported
            --  boundaries are endpoints of one segment inside the
            --  interval of the other on the common line.
            if Along_X (S1, S2) then
               Lemma_Axis_Propagation (S1, S2);
            end if;
            if R.Kind = Point_Intersection then
               --  The single common point is the overlap boundary.
               Common_From (R.Point);
            else
               Common_From (R.Overlap.From_Point);
               Common_To (R.Overlap.To_Point);
               pragma Assert
                 (Along_Coord (R.Overlap.From_Point, S1, S2)
                  <= Along_Coord (R.Overlap.To_Point, S1, S2));
            end if;
         end if;
      end if;
   end Collinear_Membership;

   --  The two lemmas below are proved by GNATprove over the whole grid
   --  domain, from the symmetric definitions.

   --  The three lemmas below decompose the symmetry argument: each
   --  sub-result is symmetric on its own, and the top-level lemma only
   --  matches the branches.

   procedure Lemma_Canonical_Symmetry (Left, Right : Segments.Segment_2D)
   with
      Ghost,
      Post =>
         Crossing_On_Grid (Left, Right) = Crossing_On_Grid (Right, Left)
         and then
           (if Properly_Crossing (Left, Right) and then Crossing_On_Grid (Left, Right)
            then Crossing_Point (Left, Right) = Crossing_Point (Right, Left))
   is
   begin
      null;
   end Lemma_Canonical_Symmetry;

   procedure Lemma_Along_Symmetry
      (P : Points.Point_2D; Left, Right : Segments.Segment_2D)
   with
      Ghost,
      Post =>
         Along_X (Left, Right) = Along_X (Right, Left)
         and then Along_Coord (P, Left, Right) = Along_Coord (P, Right, Left)
   is
   begin
      null;
   end Lemma_Along_Symmetry;

   procedure Lemma_Seg_Interval_Symmetry (S, Left, Right : Segments.Segment_2D)
   with
      Ghost,
      Post =>
         Seg_Lo (S, Left, Right) = Seg_Lo (S, Right, Left)
         and then Seg_Hi (S, Left, Right) = Seg_Hi (S, Right, Left)
   is
   begin
      null;
   end Lemma_Seg_Interval_Symmetry;

   procedure Lemma_Overlap_Bounds_Symmetry (Left, Right : Segments.Segment_2D)
   with
      Ghost,
      Post =>
         Overlap_Lo (Left, Right) = Overlap_Lo (Right, Left)
         and then Overlap_Hi (Left, Right) = Overlap_Hi (Right, Left)
   is
   begin
      null;
   end Lemma_Overlap_Bounds_Symmetry;

   procedure Lemma_Overlap_From_Symmetry (Left, Right : Segments.Segment_2D)
   with
      Ghost,
      Post => Overlap_From (Left, Right) = Overlap_From (Right, Left)
   is
   begin
      Lemma_Along_Symmetry (Left.From_Point, Left, Right);
      Lemma_Along_Symmetry (Left.To_Point, Left, Right);
      Lemma_Along_Symmetry (Right.From_Point, Left, Right);
      Lemma_Along_Symmetry (Right.To_Point, Left, Right);
      Lemma_Overlap_Bounds_Symmetry (Left, Right);
   end Lemma_Overlap_From_Symmetry;

   procedure Lemma_Overlap_To_Symmetry (Left, Right : Segments.Segment_2D)
   with
      Ghost,
      Post => Overlap_To (Left, Right) = Overlap_To (Right, Left)
   is
   begin
      Lemma_Along_Symmetry (Left.From_Point, Left, Right);
      Lemma_Along_Symmetry (Left.To_Point, Left, Right);
      Lemma_Along_Symmetry (Right.From_Point, Left, Right);
      Lemma_Along_Symmetry (Right.To_Point, Left, Right);
      Lemma_Overlap_Bounds_Symmetry (Left, Right);
   end Lemma_Overlap_To_Symmetry;

   procedure Lemma_Collinear_Symmetry (Left, Right : Segments.Segment_2D)
   with
      Ghost,
      Post => Collinear_Intersection (Left, Right) = Collinear_Intersection (Right, Left)
   is
   begin
      Lemma_Along_Symmetry (Left.From_Point, Left, Right);
      Lemma_Along_Symmetry (Left.To_Point, Left, Right);
      Lemma_Along_Symmetry (Right.From_Point, Left, Right);
      Lemma_Along_Symmetry (Right.To_Point, Left, Right);
      Lemma_Seg_Interval_Symmetry (Left, Left, Right);
      Lemma_Seg_Interval_Symmetry (Right, Left, Right);
      Lemma_Overlap_Bounds_Symmetry (Left, Right);
      Lemma_Overlap_From_Symmetry (Left, Right);
      Lemma_Overlap_To_Symmetry (Left, Right);
   end Lemma_Collinear_Symmetry;

   procedure Lemma_Common_Endpoint_Symmetry (Left, Right : Segments.Segment_2D)
   with
      Ghost,
      Post =>
         Common_Endpoint (Left, Right).Found = Common_Endpoint (Right, Left).Found
         and then
           (if Common_Endpoint (Left, Right).Found
            then Common_Endpoint (Left, Right).P = Common_Endpoint (Right, Left).P)
   is
   begin
      null;
   end Lemma_Common_Endpoint_Symmetry;

   procedure Lemma_Symmetry (Left, Right : Segments.Segment_2D) is
   begin
      Lemma_Canonical_Symmetry (Left, Right);
      Lemma_Collinear_Symmetry (Left, Right);
      Lemma_Common_Endpoint_Symmetry (Left, Right);
   end Lemma_Symmetry;

   procedure Lemma_Membership (S1, S2 : Segments.Segment_2D) is
      R : constant Intersection_Result := Intersection (S1, S2);
   begin
      if R.Kind = Point_Intersection or else R.Kind = Overlap then
         if All_Four_Collinear (S1, S2) then
            Collinear_Membership (S1, S2);
         elsif Properly_Crossing (S1, S2) then
            --  The point intersection is the exact crossing, computed on
            --  the canonically ordered pair; membership is symmetric.
            if Segment_Lex_LE (S1, S2) then
               Crossing_Membership (S1, S2);
            else
               Crossing_Membership (S2, S1);
            end if;
         else
            --  Mixed case: the point is a common endpoint by construction.
            pragma Assert (Is_Common (R.Point, S1, S2));
         end if;
      end if;
   end Lemma_Membership;

end TopoProof.Geometry.Intersections;

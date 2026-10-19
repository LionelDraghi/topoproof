-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

package body TopoProof.Geometry.Segments
   with SPARK_Mode
is

   function "=" (Left, Right : Segment_2D) return Boolean
   is (Left.From_Point = Right.From_Point and then Left.To_Point = Right.To_Point);

   --  Both endpoints give a zero factor in the bounding-box products, and
   --  a degenerate path in the orientation determinant.
   procedure Lemma_Endpoints_On (S : Segment_2D) is
   begin
      null;
   end Lemma_Endpoints_On;

   --  Sign chase, isolated from the surrounding context so that the provers
   --  focus on it: with the exact crossed products DX * FY = DY * FX and
   --  DX * TY = DY * TX and DX /= 0, the rational FY * TY is the rational
   --  FX * TX scaled by the positive factor (DY / DX) ** 2, so it cannot be
   --  positive.
   procedure Lemma_Crossed_Signs
      (DX, DY, FX, TX, FY, TY : Numerics.Vector_Component)
   with
      Ghost,
      Pre =>
         DX /= 0
         and then Orientations.Component_Product (DX, FY) = Orientations.Component_Product (DY, FX)
         and then Orientations.Component_Product (DX, TY) = Orientations.Component_Product (DY, TX)
         and then Orientations.Component_Product (FX, TX) <= 0,
      Post => Orientations.Component_Product (FY, TY) <= 0
   is
   begin
      null;
   end Lemma_Crossed_Signs;

   --  Collinearity exchanges the axis factors of the bounding-box products,
   --  so betweenness on one axis of extent implies betweenness on the other.
   --  The proof manipulates only exact degree-2 products and signs: on the
   --  axis of extent, DX * FY = DY * FX and DX * TY = DY * TX hold exactly,
   --  and FY * TY has the sign of FX * TX scaled by the positive rational
   --  (DY / DX) ** 2.
   procedure Lemma_Collinear_Between (P : Points.Point_2D; S : Segment_2D) is
      F  : Points.Point_2D renames S.From_Point;
      T  : Points.Point_2D renames S.To_Point;
      DX : constant Numerics.Vector_Component := Delta_X (S);
      DY : constant Numerics.Vector_Component := Delta_Y (S);
      FX : constant Numerics.Vector_Component :=
        Numerics.Vector_Component
          (Numerics.Extended_Component (P.X) - Numerics.Extended_Component (F.X));
      TX : constant Numerics.Vector_Component :=
        Numerics.Vector_Component
          (Numerics.Extended_Component (P.X) - Numerics.Extended_Component (T.X));
      FY : constant Numerics.Vector_Component :=
        Numerics.Vector_Component
          (Numerics.Extended_Component (P.Y) - Numerics.Extended_Component (F.Y));
      TY : constant Numerics.Vector_Component :=
        Numerics.Vector_Component
          (Numerics.Extended_Component (P.Y) - Numerics.Extended_Component (T.Y));
   begin
      if DX /= 0 then
         --  Collinearity, cross-multiplied on the axis of extent.
         pragma Assert (Orientations.Component_Product (DX, FY)
                         = Orientations.Component_Product (DY, FX));
         pragma Assert (Orientations.Component_Product (DX, TY)
                         = Orientations.Component_Product (DY, TX));
         Lemma_Crossed_Signs (DX, DY, FX, TX, FY, TY);
         pragma Assert (Orientations.Component_Product (FY, TY) <= 0);

      else
         --  Vertical segment: collinearity forces the X factors to zero.
         pragma Assert (FX = 0 and then TX = 0);

      end if;
   end Lemma_Collinear_Between;

   --  On an axis of extent, the collinearity determinant makes the other
   --  coordinate a function of the first, so equal coordinates imply equal
   --  points.
   procedure Lemma_Collinear_Injective (P, Q : Points.Point_2D; S : Segment_2D) is
   begin
      null;
   end Lemma_Collinear_Injective;

end TopoProof.Geometry.Segments;

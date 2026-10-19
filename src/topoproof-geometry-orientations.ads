-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with TopoProof.Geometry.Points;
with TopoProof.Numerics;
use type TopoProof.Geometry.Points.Point_2D;
use type TopoProof.Numerics.Determinant;
use type TopoProof.Numerics.Extended_Component;
use type TopoProof.Numerics.Product_Component;
use type TopoProof.Numerics.Vector_Component;

package TopoProof.Geometry.Orientations
   with Pure, SPARK_Mode
is
   type Orientation_Kind is (Collinear, Counter_Clockwise, Clockwise);

   --  Exact product of two component differences. Each factor belongs to
   --  the Vector_Component domain, so the product is bounded by 2E9 * 2E9,
   --  exactly the Product_Component domain.
   function Component_Product (U, V : Numerics.Vector_Component) return Numerics.Product_Component
   is (Numerics.Product_Component (U) * Numerics.Product_Component (V));

   --  Exact determinant of two direction vectors U and V, that is
   --  U.X * V.Y - U.Y * V.X: positive when V turns counter-clockwise
   --  from U. Both operands are component differences, so the result is
   --  bounded by the Determinant domain.
   function Cross_Determinant (UX, UY, VX, VY : Numerics.Vector_Component)
      return Numerics.Determinant
   is
     (Numerics.Determinant (Component_Product (UX, VY))
      - Numerics.Determinant (Component_Product (UY, VX)));

   --  Antisymmetry: exchanging the two directions negates the determinant.
   procedure Lemma_Cross_Antisymmetry (U1X, U1Y, U2X, U2Y : Numerics.Vector_Component)
   with
      Ghost,
      Post => Cross_Determinant (U2X, U2Y, U1X, U1Y) = -Cross_Determinant (U1X, U1Y, U2X, U2Y);

   --  Exact signed determinant of the orientation test on A, B, C:
   --  (B.X - A.X) * (C.Y - A.Y) - (B.Y - A.Y) * (C.X - A.X), computed as the
   --  difference of two exact products in the Determinant domain.
   function Determinant (A, B, C : Points.Point_2D) return Numerics.Determinant
   is (Numerics.Determinant
          (Component_Product
              (Numerics.Vector_Component
                  (Numerics.Extended_Component (B.X) - Numerics.Extended_Component (A.X)),
               Numerics.Vector_Component
                  (Numerics.Extended_Component (C.Y) - Numerics.Extended_Component (A.Y))))
       - Numerics.Determinant
            (Component_Product
                (Numerics.Vector_Component
                    (Numerics.Extended_Component (B.Y) - Numerics.Extended_Component (A.Y)),
                 Numerics.Vector_Component
                    (Numerics.Extended_Component (C.X) - Numerics.Extended_Component (A.X)))));

   --  Exact classification of the path A -> B -> C: counter-clockwise when
   --  the determinant is positive, clockwise when it is negative, collinear
   --  when it is zero. No tolerance and no approximation are involved.
   function Orientation (A, B, C : Points.Point_2D) return Orientation_Kind
   with
      Contract_Cases =>
         (Determinant (A, B, C) > 0 => Orientation'Result = Counter_Clockwise,
          Determinant (A, B, C) = 0 => Orientation'Result = Collinear,
          Determinant (A, B, C) < 0 => Orientation'Result = Clockwise);

   --  Three points are collinear exactly when the determinant is zero.
   function Are_Collinear (A, B, C : Points.Point_2D) return Boolean
   with Post => Are_Collinear'Result = (Determinant (A, B, C) = 0);

   function Translation_Is_Representable_2D
      (P : Points.Point_2D; DX, DY : Numerics.Vector_Component) return Boolean;

   --  Applies a 2D translation to P. Each coordinate addition is computed
   --  exactly in the extended domain, and is representable on the grid by
   --  precondition.
   function Translate_2D
      (P : Points.Point_2D; DX, DY : Numerics.Vector_Component) return Points.Point_2D
   with
      Pre  => Translation_Is_Representable_2D (P, DX, DY),
      Post =>
         Numerics.Extended_Component (Translate_2D'Result.X)
         = Numerics.Extended_Component (P.X) + Numerics.Extended_Component (DX)
         and then Numerics.Extended_Component (Translate_2D'Result.Y)
                  = Numerics.Extended_Component (P.Y) + Numerics.Extended_Component (DY);

   --  A cyclic permutation of the arguments does not change the orientation.
   procedure Lemma_Cyclic_Permutation (P, Q, R : Points.Point_2D)
   with
      Ghost,
      Post =>
         Orientation (Q, R, P) = Orientation (P, Q, R)
         and then Orientation (R, P, Q) = Orientation (P, Q, R);

   --  Exchanging two arguments mirrors the orientation.
   procedure Lemma_Reversed_Permutation (P, Q, R : Points.Point_2D)
   with
      Ghost,
      Post =>
         (case Orientation (P, Q, R) is
             when Counter_Clockwise => Orientation (P, R, Q) = Clockwise,
             when Clockwise         => Orientation (P, R, Q) = Counter_Clockwise,
             when Collinear         => Orientation (P, R, Q) = Collinear);

   --  Two coincident points make the path degenerate, hence collinear.
   procedure Lemma_Degenerate_Collinear (A, B, C : Points.Point_2D)
   with Ghost, Pre => A = B or else B = C or else A = C, Post => Orientation (A, B, C) = Collinear;

   --  The orientation is invariant under any representable translation of
   --  the three points.
   procedure Lemma_Translation_Invariance
      (A, B, C : Points.Point_2D; DX, DY : Numerics.Vector_Component)
   with
      Ghost,
      Pre  =>
         Translation_Is_Representable_2D (A, DX, DY)
         and then Translation_Is_Representable_2D (B, DX, DY)
         and then Translation_Is_Representable_2D (C, DX, DY),
      Post =>
         Orientation (Translate_2D (A, DX, DY), Translate_2D (B, DX, DY), Translate_2D (C, DX, DY))
         = Orientation (A, B, C);

end TopoProof.Geometry.Orientations;

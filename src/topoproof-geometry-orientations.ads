-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with TopoProof.Geometry.Planes;
with TopoProof.Geometry.Points;
with TopoProof.Geometry.Translations;
with TopoProof.Geometry.Vectors;
with TopoProof.Numerics;
use type TopoProof.Geometry.Points.Point_2D;
use type TopoProof.Geometry.Points.Point_3D;
use type TopoProof.Numerics.Cross_Dot;
use type TopoProof.Numerics.Determinant;
use type TopoProof.Numerics.Extended_Component;
use type TopoProof.Numerics.Product_Component;
use type TopoProof.Numerics.Vector_Component;

package TopoProof.Geometry.Orientations
   with Pure, SPARK_Mode
is
   type Orientation_Kind is (Collinear, Counter_Clockwise, Clockwise);

   --  Exact determinant of two direction vectors U and V, that is
   --  U.X * V.Y - U.Y * V.X: positive when V turns counter-clockwise
   --  from U. Both operands are component differences, so the result is
   --  bounded by the Determinant domain.
   function Cross_Determinant (UX, UY, VX, VY : Numerics.Vector_Component)
      return Numerics.Determinant
   is
     (Numerics.Determinant (Numerics.Component_Product (UX, VY))
      - Numerics.Determinant (Numerics.Component_Product (UY, VX)));

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
          (Numerics.Component_Product
              (Numerics.Vector_Component
                  (Numerics.Extended_Component (B.X) - Numerics.Extended_Component (A.X)),
               Numerics.Vector_Component
                  (Numerics.Extended_Component (C.Y) - Numerics.Extended_Component (A.Y))))
       - Numerics.Determinant
            (Numerics.Component_Product
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

   --  The exact orientation determinant of the ordered point quadruple
   --  A, B, C, D: the mixed product of the three displacements from A,
   --  that is (B - A) x (C - A) . (D - A), six times the signed volume
   --  of the tetrahedron. Every factor belongs to its exact domain, so
   --  the result stays in the 128-bit Cross_Dot domain for any grid
   --  input.
   function Determinant (A, B, C, D : Points.Point_3D)
      return Numerics.Cross_Dot
   is
     (Vectors.Dot_Product
        (Vectors.Cross_Product
            (Vectors.Displacement (A, B), Vectors.Displacement (A, C)),
         Vectors.Displacement (A, D)));

   --  The exact classification of the ordered quadruple: right-handed
   --  when the determinant is positive, left-handed when it is
   --  negative, coplanar when it is zero. No tolerance and no
   --  approximation are involved.
   type Orientation_3D_Kind is (Coplanar, Right_Handed, Left_Handed);

   function Orientation_3D (A, B, C, D : Points.Point_3D)
      return Orientation_3D_Kind
   with
      Contract_Cases =>
         (Determinant (A, B, C, D) > 0 => Orientation_3D'Result = Right_Handed,
          Determinant (A, B, C, D) = 0 => Orientation_3D'Result = Coplanar,
          Determinant (A, B, C, D) < 0 => Orientation_3D'Result = Left_Handed);

   --  Four points are coplanar exactly when their orientation
   --  determinant is zero.
   function Are_Coplanar (A, B, C, D : Points.Point_3D) return Boolean
   with Post => Are_Coplanar'Result = (Determinant (A, B, C, D) = 0);

   --  The orientation determinant is exactly the plane equation of D
   --  relative to the plane through A, B and C: the mixed product of
   --  the normal with the displacement from A to D is the same exact
   --  value.
   procedure Lemma_Determinant_Is_Plane_Equation
      (A, B, C, D : Points.Point_3D)
   with
      Ghost,
      Post => Determinant (A, B, C, D) = Planes.Plane_Equation (A, B, C, D);

   --  Exchanging the last two points negates the determinant: the
   --  exact form of the mirrored orientation.
   procedure Lemma_Determinant_Reversed (A, B, C, D : Points.Point_3D)
   with
      Ghost,
      Post =>
         Determinant (A => A, B => B, C => D, D => C)
         = -Determinant (A, B, C, D);

   --  Exchanging the first two points also negates the determinant.
   procedure Lemma_Determinant_Swapped (A, B, C, D : Points.Point_3D)
   with
      Ghost,
      Post =>
         Determinant (A => B, B => A, C => C, D => D)
         = -Determinant (A, B, C, D);

   --  Exchanging the middle two points negates the determinant as
   --  well: the three displacements keep the same first point, so the
   --  cross antisymmetry applies directly.
   procedure Lemma_Determinant_Middle_Swapped (A, B, C, D : Points.Point_3D)
   with
      Ghost,
      Post =>
         Determinant (A => A, B => C, C => B, D => D)
         = -Determinant (A, B, C, D);

   --  An even permutation of the four points, the exchange of two
   --  pairs, preserves the orientation.
   procedure Lemma_Even_Permutation (A, B, C, D : Points.Point_3D)
   with
      Ghost,
      Post =>
         Orientation_3D (A => B, B => A, C => D, D => C)
         = Orientation_3D (A, B, C, D)
         and then Orientation_3D (A => C, B => D, C => A, D => B)
                  = Orientation_3D (A, B, C, D)
         and then Orientation_3D (A => D, B => C, C => B, D => A)
                  = Orientation_3D (A, B, C, D);

   --  Exchanging two points mirrors the orientation.
   procedure Lemma_Reversed_Permutation (A, B, C, D : Points.Point_3D)
   with
      Ghost,
      Post =>
         (case Orientation_3D (A, B, C, D) is
             when Right_Handed =>
                Orientation_3D (A => A, B => B, C => D, D => C) = Left_Handed,
             when Left_Handed  =>
                Orientation_3D (A => A, B => B, C => D, D => C) = Right_Handed,
             when Coplanar     =>
                Orientation_3D (A => A, B => B, C => D, D => C) = Coplanar);

   --  Two coincident points make the quadruple degenerate, hence
   --  coplanar.
   procedure Lemma_Degenerate_Coplanar (A, B, C, D : Points.Point_3D)
   with
      Ghost,
      Pre  =>
         A = B or else A = C or else A = D
         or else B = C or else B = D or else C = D,
      Post => Orientation_3D (A, B, C, D) = Coplanar;

   --  The orientation is invariant under any representable translation
   --  of the four points.
   procedure Lemma_Translation_Invariance_3D
      (A, B, C, D : Points.Point_3D;
       V          : Vectors.Vector_3D)
   with
      Ghost,
      Pre  =>
         Translations.Translation_Is_Representable (A, V)
         and then Translations.Translation_Is_Representable (B, V)
         and then Translations.Translation_Is_Representable (C, V)
         and then Translations.Translation_Is_Representable (D, V),
      Post =>
         Orientation_3D
           (Translations.Translate (A, V),
            Translations.Translate (B, V),
            Translations.Translate (C, V),
            Translations.Translate (D, V))
         = Orientation_3D (A, B, C, D);

end TopoProof.Geometry.Orientations;

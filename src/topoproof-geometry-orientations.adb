-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

package body TopoProof.Geometry.Orientations
   with SPARK_Mode
is

   function Translation_Is_Representable_2D
      (P : Points.Point_2D; DX, DY : Numerics.Vector_Component) return Boolean
   is (Numerics.In_Range (Numerics.Extended_Component (P.X) + Numerics.Extended_Component (DX))
       and then Numerics.In_Range (Numerics.Extended_Component (P.Y) + Numerics.Extended_Component (DY)));

   function Translate_2D
      (P : Points.Point_2D; DX, DY : Numerics.Vector_Component) return Points.Point_2D is
   begin
      return
         (X =>
             Numerics.Grid_Coordinate
                (Numerics.Extended_Component (P.X) + Numerics.Extended_Component (DX)),
          Y =>
             Numerics.Grid_Coordinate
                (Numerics.Extended_Component (P.Y) + Numerics.Extended_Component (DY)));
   end Translate_2D;

   function Orientation (A, B, C : Points.Point_2D) return Orientation_Kind is
      D : constant Numerics.Determinant := Determinant (A, B, C);
   begin
      if D > 0 then
         return Counter_Clockwise;

      elsif D = 0 then
         return Collinear;

      else
         return Clockwise;

      end if;
   end Orientation;

   function Are_Collinear (A, B, C : Points.Point_2D) return Boolean
   is (Determinant (A, B, C) = 0);

   --  Antisymmetry follows from the commutativity of each exact product.
   procedure Lemma_Cross_Antisymmetry (U1X, U1Y, U2X, U2Y : Numerics.Vector_Component) is
   begin
      null;
   end Lemma_Cross_Antisymmetry;

   --  The postconditions of the four lemmas below are proved by GNATprove
   --  over the whole grid domain, from the exact determinant expression.
   procedure Lemma_Cyclic_Permutation (P, Q, R : Points.Point_2D) is
   begin
      null;
   end Lemma_Cyclic_Permutation;

   procedure Lemma_Reversed_Permutation (P, Q, R : Points.Point_2D) is
   begin
      null;
   end Lemma_Reversed_Permutation;

   procedure Lemma_Degenerate_Collinear (A, B, C : Points.Point_2D) is
   begin
      null;
   end Lemma_Degenerate_Collinear;

   procedure Lemma_Translation_Invariance
      (A, B, C : Points.Point_2D; DX, DY : Numerics.Vector_Component) is
   begin
      null;
   end Lemma_Translation_Invariance;

   function Orientation_3D (A, B, C, D : Points.Point_3D)
      return Orientation_3D_Kind
   is
      E : constant Numerics.Cross_Dot := Determinant (A, B, C, D);

   begin
      if E > 0 then
         return Right_Handed;
      elsif E < 0 then
         return Left_Handed;
      else
         return Coplanar;
      end if;
   end Orientation_3D;

   function Are_Coplanar (A, B, C, D : Points.Point_3D) return Boolean is
     (Determinant (A, B, C, D) = 0);

   --  The postconditions of the lemmas below are proved by GNATprove
   --  over the whole grid domain, from the exact product expressions.
   procedure Lemma_Determinant_Is_Plane_Equation
      (A, B, C, D : Points.Point_3D)
   is
   begin
      null;
   end Lemma_Determinant_Is_Plane_Equation;

   procedure Lemma_Determinant_Reversed (A, B, C, D : Points.Point_3D) is
   begin
      Vectors.Lemma_Mixed_Antisymmetry
        (Vectors.Displacement (A, B),
         Vectors.Displacement (A, C),
         Vectors.Displacement (A, D));
   end Lemma_Determinant_Reversed;

   procedure Lemma_Determinant_Swapped (A, B, C, D : Points.Point_3D) is
   begin
      null;
   end Lemma_Determinant_Swapped;

   procedure Lemma_Determinant_Middle_Swapped
      (A, B, C, D : Points.Point_3D)
   is
   begin
      Vectors.Lemma_Cross_Antisymmetry
        (Vectors.Displacement (A, C), Vectors.Displacement (A, B));
   end Lemma_Determinant_Middle_Swapped;

   procedure Lemma_Even_Permutation (A, B, C, D : Points.Point_3D) is
   begin
      --  (B, A, D, C): the two exchanges compensate each other.
      Lemma_Determinant_Swapped (A => A, B => B, C => D, D => C);
      Lemma_Determinant_Reversed (A, B, C, D);

      --  (C, D, A, B): the exchanges of two adjacent points, taken two
      --  by two, preserve the orientation.
      Lemma_Determinant_Middle_Swapped (A, B, C, D);
      Lemma_Determinant_Swapped (A => A, B => C, C => B, D => D);
      Lemma_Determinant_Middle_Swapped (A => C, B => A, C => B, D => D);
      Lemma_Determinant_Reversed (A => C, B => B, C => A, D => D);
      Lemma_Determinant_Middle_Swapped (A => C, B => B, C => D, D => A);
      Lemma_Determinant_Reversed (A => C, B => D, C => B, D => A);

      --  (D, C, B, A): one more exchange of the first two points.
      Lemma_Determinant_Swapped (A => C, B => D, C => B, D => A);
   end Lemma_Even_Permutation;

   procedure Lemma_Reversed_Permutation (A, B, C, D : Points.Point_3D) is
   begin
      Lemma_Determinant_Reversed (A, B, C, D);
   end Lemma_Reversed_Permutation;

   procedure Lemma_Degenerate_Coplanar (A, B, C, D : Points.Point_3D) is
   begin
      null;
   end Lemma_Degenerate_Coplanar;

   procedure Lemma_Translation_Invariance_3D
      (A, B, C, D : Points.Point_3D;
       V          : Vectors.Vector_3D)
   is
   begin
      null;
   end Lemma_Translation_Invariance_3D;

end TopoProof.Geometry.Orientations;

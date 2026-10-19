-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

package body TopoProof.Geometry.Orientations
   with SPARK_Mode
is

   function In_Range (V : Numerics.Extended_Component) return Boolean
   is (V >= Numerics.Extended_Component (Numerics.Grid_Coordinate'First)
       and then V <= Numerics.Extended_Component (Numerics.Grid_Coordinate'Last));

   function Translation_Is_Representable_2D
      (P : Points.Point_2D; DX, DY : Numerics.Vector_Component) return Boolean
   is (In_Range (Numerics.Extended_Component (P.X) + Numerics.Extended_Component (DX))
       and then In_Range (Numerics.Extended_Component (P.Y) + Numerics.Extended_Component (DY)));

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

end TopoProof.Geometry.Orientations;

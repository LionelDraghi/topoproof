-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

package body TopoProof.Geometry.Planes
   with SPARK_Mode
is
   function Plane_Side (Pl : Plane; P : Points.Point_3D)
      return Plane_Side_Kind
   is
      E : constant Numerics.Cross_Dot :=
        Plane_Equation (Pl.A, Pl.B, Pl.C, P);
   begin
      if E > 0 then
         return In_Front;
      elsif E < 0 then
         return Behind;
      else
         return On_Plane;
      end if;
   end Plane_Side;

   procedure Make_Plane
      (A, B, C : Points.Point_3D;
       Pl      :    out Plane;
       K       :    out Plane_Kind)
   is
   begin
      Pl := (A => A, B => B, C => C);
      if Are_Collinear (A, B, C) then
         K := Plane_Collinear;
      else
         K := Plane_Valid;
      end if;
   end Make_Plane;

   --  The postconditions of the three lemmas below are proved by
   --  GNATprove over the whole grid domain, from the exact product
   --  expressions.
   procedure Lemma_Collinear_On_Plane (A, B, C, P : Points.Point_3D) is
   begin
      null;
   end Lemma_Collinear_On_Plane;

   procedure Lemma_Plane_Side_Invariance
      (A, B, C, P : Points.Point_3D;
       V          : Vectors.Vector_3D)
   is
   begin
      null;
   end Lemma_Plane_Side_Invariance;

end TopoProof.Geometry.Planes;

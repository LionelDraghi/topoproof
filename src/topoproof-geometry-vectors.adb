-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

package body TopoProof.Geometry.Vectors
   with SPARK_Mode
is
   function Displacement (From, To_Point : Points.Point_3D) return Vector_3D is

   begin
      return
         (DX =>
             Numerics.Vector_Component
                (Numerics.Extended_Component (To_Point.X) - Numerics.Extended_Component (From.X)),
          DY =>
             Numerics.Vector_Component
                (Numerics.Extended_Component (To_Point.Y) - Numerics.Extended_Component (From.Y)),
          DZ =>
             Numerics.Vector_Component
                (Numerics.Extended_Component (To_Point.Z) - Numerics.Extended_Component (From.Z)));
   end Displacement;

   function Dot_Product (A, B : Vector_3D) return Numerics.Dot_Product is
   begin
      return Numerics.Dot_Product (Numerics.Component_Product (A.DX, B.DX))
             + Numerics.Dot_Product (Numerics.Component_Product (A.DY, B.DY))
             + Numerics.Dot_Product (Numerics.Component_Product (A.DZ, B.DZ));
   end Dot_Product;

   function Dot_Product (U : Cross_Vector_3D; V : Vector_3D)
      return Numerics.Cross_Dot is
   begin
      return Numerics.Cross_Dot (Numerics.Mixed_Product (U.DX, V.DX))
             + Numerics.Cross_Dot (Numerics.Mixed_Product (U.DY, V.DY))
             + Numerics.Cross_Dot (Numerics.Mixed_Product (U.DZ, V.DZ));
   end Dot_Product;

   function Cross_Product (A, B : Vector_3D) return Cross_Vector_3D is
   begin
      return
         (DX =>
             Numerics.Cross_Component (Numerics.Component_Product (A.DY, B.DZ))
             - Numerics.Cross_Component (Numerics.Component_Product (A.DZ, B.DY)),
          DY =>
             Numerics.Cross_Component (Numerics.Component_Product (A.DZ, B.DX))
             - Numerics.Cross_Component (Numerics.Component_Product (A.DX, B.DZ)),
          DZ =>
             Numerics.Cross_Component (Numerics.Component_Product (A.DX, B.DY))
             - Numerics.Cross_Component (Numerics.Component_Product (A.DY, B.DX)));
   end Cross_Product;

   --  The postconditions of the two lemmas below are proved by GNATprove
   --  over the whole grid domain, from the exact product expressions.
   procedure Lemma_Dot_Commutativity (A, B : Vector_3D) is
   begin
      null;
   end Lemma_Dot_Commutativity;

   procedure Lemma_Cross_Antisymmetry (A, B : Vector_3D) is
   begin
      null;
   end Lemma_Cross_Antisymmetry;

   procedure Lemma_Cross_Orthogonality (A, B : Vector_3D) is
   begin
      null;
   end Lemma_Cross_Orthogonality;

   procedure Lemma_Mixed_Antisymmetry (U, V, W : Vector_3D) is
   begin
      null;
   end Lemma_Mixed_Antisymmetry;

end TopoProof.Geometry.Vectors;

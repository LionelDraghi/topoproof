-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with TopoProof.Geometry.Points;
with TopoProof.Numerics;
use type TopoProof.Numerics.Cross_Component;
use type TopoProof.Numerics.Cross_Dot;
use type TopoProof.Numerics.Dot_Product;
use type TopoProof.Numerics.Extended_Component;
use type TopoProof.Numerics.Product_Component;

package TopoProof.Geometry.Vectors
   with Pure, SPARK_Mode
is
   type Vector_3D is record
      DX : Numerics.Vector_Component;
      DY : Numerics.Vector_Component;
      DZ : Numerics.Vector_Component;
   end record;

   --  The exact cross product of two grid vectors: a mathematical vector
   --  whose components are exact differences of component products, so
   --  they can leave the grid amplitude; each stays in the dedicated
   --  Cross_Component domain. Unlike a grid vector, a cross vector is a
   --  derived quantity, never a grid position.
   type Cross_Vector_3D is record
      DX : Numerics.Cross_Component;
      DY : Numerics.Cross_Component;
      DZ : Numerics.Cross_Component;
   end record;

   --  Displacement (A, B) = B - A, computed exactly in Extended_Component.
   function Displacement (From, To_Point : Points.Point_3D) return Vector_3D
   with
      Post =>
         Numerics.Extended_Component (Displacement'Result.DX)
         = Numerics.Extended_Component (To_Point.X) - Numerics.Extended_Component (From.X)
         and then Numerics.Extended_Component (Displacement'Result.DY)
                  = Numerics.Extended_Component (To_Point.Y) - Numerics.Extended_Component (From.Y)
         and then Numerics.Extended_Component (Displacement'Result.DZ)
                  = Numerics.Extended_Component (To_Point.Z) - Numerics.Extended_Component (From.Z);

   --  Exact dot product of two grid vectors: the sum of the three exact
   --  component products, in the Dot_Product domain.
   function Dot_Product (A, B : Vector_3D) return Numerics.Dot_Product
   with
      Post =>
         Dot_Product'Result
         = Numerics.Dot_Product (Numerics.Component_Product (A.DX, B.DX))
           + Numerics.Dot_Product (Numerics.Component_Product (A.DY, B.DY))
           + Numerics.Dot_Product (Numerics.Component_Product (A.DZ, B.DZ));

   --  Exact dot product of a cross vector and a grid vector: the sum of
   --  the three exact mixed products, in the Cross_Dot domain.
   function Dot_Product (U : Cross_Vector_3D; V : Vector_3D)
      return Numerics.Cross_Dot
   with
      Post =>
         Dot_Product'Result
         = Numerics.Cross_Dot (Numerics.Mixed_Product (U.DX, V.DX))
           + Numerics.Cross_Dot (Numerics.Mixed_Product (U.DY, V.DY))
           + Numerics.Cross_Dot (Numerics.Mixed_Product (U.DZ, V.DZ));

   --  Exact cross product of two grid vectors: each component is the
   --  exact difference of two exact component products.
   function Cross_Product (A, B : Vector_3D) return Cross_Vector_3D
   with
      Post =>
         Cross_Product'Result.DX
         = Numerics.Cross_Component (Numerics.Component_Product (A.DY, B.DZ))
           - Numerics.Cross_Component (Numerics.Component_Product (A.DZ, B.DY))
         and then Cross_Product'Result.DY
                  = Numerics.Cross_Component (Numerics.Component_Product (A.DZ, B.DX))
                    - Numerics.Cross_Component (Numerics.Component_Product (A.DX, B.DZ))
         and then Cross_Product'Result.DZ
                  = Numerics.Cross_Component (Numerics.Component_Product (A.DX, B.DY))
                    - Numerics.Cross_Component (Numerics.Component_Product (A.DY, B.DX));

   --  The dot product is commutative: both operands play the same role in
   --  the exact product sum.
   procedure Lemma_Dot_Commutativity (A, B : Vector_3D)
   with Ghost, Post => Dot_Product (A => A, B => B) = Dot_Product (A => B, B => A);

   --  Exchanging the two operands negates the cross product.
   procedure Lemma_Cross_Antisymmetry (A, B : Vector_3D)
   with
      Ghost,
      Post =>
         Cross_Product (A => A, B => B).DX = -Cross_Product (A => B, B => A).DX
         and then Cross_Product (A => A, B => B).DY = -Cross_Product (A => B, B => A).DY
         and then Cross_Product (A => A, B => B).DZ = -Cross_Product (A => B, B => A).DZ;

   --  The cross product is orthogonal to both operands: the cross dot of
   --  the cross vector with either operand is exactly zero.
   procedure Lemma_Cross_Orthogonality (A, B : Vector_3D)
   with
      Ghost,
      Post =>
         Dot_Product (Cross_Product (A, B), A) = 0
         and then Dot_Product (Cross_Product (A, B), B) = 0;

end TopoProof.Geometry.Vectors;

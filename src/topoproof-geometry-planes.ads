-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with TopoProof.Geometry.Points;
with TopoProof.Geometry.Translations;
with TopoProof.Geometry.Vectors;
with TopoProof.Numerics;
use type TopoProof.Geometry.Points.Point_3D;
use type TopoProof.Geometry.Vectors.Cross_Vector_3D;
use type TopoProof.Numerics.Cross_Dot;

package TopoProof.Geometry.Planes
   with Pure, SPARK_Mode
is
   --  The classification of a point relative to a plane.
   type Plane_Side_Kind is (In_Front, Behind, On_Plane);

   --  The report of a plane construction.
   type Plane_Kind is (Plane_Valid, Plane_Collinear);

   --  A plane through its three defining points. A valid plane has
   --  non-collinear defining points; Make_Plane is the only public
   --  constructor and reports the collinear degeneracy instead of
   --  building the plane.
   type Plane is record
      A, B, C : Points.Point_3D;
   end record;

   --  The exact normal of the plane through A, B and C: the cross
   --  product of the displacement from A to B with the displacement
   --  from A to C. The normal is null exactly when the three points
   --  are collinear.
   function Normal (A, B, C : Points.Point_3D)
      return Vectors.Cross_Vector_3D
   is
     (Vectors.Cross_Product
        (Vectors.Displacement (A, B), Vectors.Displacement (A, C)));

   --  Three points are collinear exactly when their normal is null.
   function Are_Collinear (A, B, C : Points.Point_3D) return Boolean
   is
     (Normal (A, B, C)
        = (DX => 0, DY => 0, DZ => 0));

   --  The exact plane equation of P relative to the plane through A,
   --  B and C: the mixed dot of the normal with the displacement from
   --  A to P. Positive on the side the normal points to, negative on
   --  the other side, zero on the plane, and zero everywhere when the
   --  defining points are collinear.
   function Plane_Equation (A, B, C, P : Points.Point_3D)
      return Numerics.Cross_Dot
   is
     (Vectors.Dot_Product
        (Normal (A, B, C), Vectors.Displacement (A, P)));

   --  Exact classification of the point P relative to the plane Pl:
   --  in front on the side its normal points to, behind on the other
   --  side, on the plane when the equation vanishes. No tolerance and
   --  no approximation are involved.
   function Plane_Side (Pl : Plane; P : Points.Point_3D)
      return Plane_Side_Kind
   with
      Contract_Cases =>
         (Plane_Equation (Pl.A, Pl.B, Pl.C, P) > 0 =>
             Plane_Side'Result = In_Front,
          Plane_Equation (Pl.A, Pl.B, Pl.C, P) = 0 =>
             Plane_Side'Result = On_Plane,
          Plane_Equation (Pl.A, Pl.B, Pl.C, P) < 0 =>
             Plane_Side'Result = Behind);

   --  Build the plane of the three defining points. The collinear
   --  degeneracy is reported, never built: a valid plane has a
   --  non-null normal by construction.
   procedure Make_Plane
      (A, B, C : Points.Point_3D;
       Pl      :    out Plane;
       K       :    out Plane_Kind)
   with
      Post =>
         Pl.A = A and then Pl.B = B and then Pl.C = C
         and then
           ((K = Plane_Valid and then not Are_Collinear (A, B, C))
            or else (K = Plane_Collinear and then Are_Collinear (A, B, C)));

   --  A degenerate plane classifies every point as on the plane.
   procedure Lemma_Collinear_On_Plane (A, B, C, P : Points.Point_3D)
   with
      Ghost,
      Pre  => Are_Collinear (A, B, C),
      Post => Plane_Side ((A, B, C), P) = On_Plane;

   --  The classification is invariant under any representable
   --  translation of the defining points and the classified point:
   --  the normal and the displacements are translation invariant.
   procedure Lemma_Plane_Side_Invariance
      (A, B, C, P : Points.Point_3D;
       V          : Vectors.Vector_3D)
   with
      Ghost,
      Pre  =>
         Translations.Translation_Is_Representable (A, V)
         and then Translations.Translation_Is_Representable (B, V)
         and then Translations.Translation_Is_Representable (C, V)
         and then Translations.Translation_Is_Representable (P, V),
      Post =>
         Plane_Side
           ((Translations.Translate (A, V),
             Translations.Translate (B, V),
             Translations.Translate (C, V)),
            Translations.Translate (P, V))
         = Plane_Side ((A, B, C), P);

end TopoProof.Geometry.Planes;

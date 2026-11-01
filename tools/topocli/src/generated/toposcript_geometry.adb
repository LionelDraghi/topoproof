-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

--  The TopoScript geometry domain, script-facing API: the source of
--  truth hac-bindgen binds (HAC Bindgen Manifesto 2.1). Plain legal
--  Ada, no HAC dependency. This file and its body are the maintained
--  inputs of the generated binding alternative; everything else in
--  this directory is generated.
--  The body delegates every operation to the proved kernel.

with TopoProof.Geometry.Intersections;
with TopoProof.Geometry.Orientations;
with TopoProof.Geometry.Planes;
with TopoProof.Geometry.Points;
with TopoProof.Geometry.Segments;
with TopoProof.Geometry.Translations;
with TopoProof.Geometry.Vectors;
with TopoProof.Numerics;

package body TopoScript_Geometry is

   function To_Kernel (P : Point_3D) return TopoProof.Geometry.Points.Point_3D
 is
      (X => TopoProof.Numerics.Grid_Coordinate (P.X),
       Y => TopoProof.Numerics.Grid_Coordinate (P.Y),
       Z => TopoProof.Numerics.Grid_Coordinate (P.Z));

   function To_Kernel (P : Point_2D) return TopoProof.Geometry.Points.Point_2D
 is
      (X => TopoProof.Numerics.Grid_Coordinate (P.X),
       Y => TopoProof.Numerics.Grid_Coordinate (P.Y));

   function To_Kernel (V : Vector_3D)
      return TopoProof.Geometry.Vectors.Vector_3D is
      (DX => TopoProof.Numerics.Vector_Component (V.DX),
       DY => TopoProof.Numerics.Vector_Component (V.DY),
       DZ => TopoProof.Numerics.Vector_Component (V.DZ));

   procedure Translate
     (P : in Point_3D; V : in Vector_3D; Result : out Point_3D)
   is
      R : constant TopoProof.Geometry.Points.Point_3D :=
        TopoProof.Geometry.Translations.Translate (To_Kernel (P), To_Kernel
 (V));
   begin
      Result := (X => Integer (R.X), Y => Integer (R.Y), Z => Integer
 (R.Z));
   end Translate;

   procedure Displacement
     (A : in Point_3D; B : in Point_3D; Result : out Vector_3D)
   is
      D : constant TopoProof.Geometry.Vectors.Vector_3D :=
        TopoProof.Geometry.Vectors.Displacement (To_Kernel (A), To_Kernel
 (B));
   begin
      Result := (DX => Integer (D.DX), DY => Integer (D.DY), DZ => Integer
 (D.DZ));
   end Displacement;

   procedure Dot_Product
     (A : in Vector_3D; B : in Vector_3D; Result : out Integer)
   is
   begin
      Result := Integer
        (TopoProof.Geometry.Vectors.Dot_Product
           (To_Kernel (A), To_Kernel (B)));
   end Dot_Product;

   procedure Cross_Product
     (A : in Vector_3D; B : in Vector_3D; Result : out Vector_3D)
   is
      C : constant TopoProof.Geometry.Vectors.Cross_Vector_3D :=
        TopoProof.Geometry.Vectors.Cross_Product (To_Kernel (A), To_Kernel
 (B));
   begin
      Result := (DX => Integer (C.DX), DY => Integer (C.DY), DZ => Integer
 (C.DZ));
   end Cross_Product;

   procedure Equal
     (A : in Point_3D; B : in Point_3D; Result : out Equal_Kind)
   is
   begin
      Result := (if TopoProof.Geometry.Points."=" (To_Kernel (A), To_Kernel
 (B))
                 then Equal_True else Equal_False);
   end Equal;

   procedure Orientation
     (A : in Point_2D; B : in Point_2D; C : in Point_2D;
      Result : out Orientation_Kind)
   is
      K : constant TopoProof.Geometry.Orientations.Orientation_Kind :=
        TopoProof.Geometry.Orientations.Orientation
          (To_Kernel (A), To_Kernel (B), To_Kernel (C));
   begin
      Result := (case K is
                    when TopoProof.Geometry.Orientations.Collinear =>
                       Orientation_Collinear,
                    when TopoProof.Geometry.Orientations.Counter_Clockwise
 =>
                       Orientation_Counter_Clockwise,
                    when TopoProof.Geometry.Orientations.Clockwise =>
                       Orientation_Clockwise);
   end Orientation;

   procedure Orientation_3D
     (A : in Point_3D; B : in Point_3D; C : in Point_3D; D : in Point_3D;
      Result : out Orientation_3D_Kind)
   is
      K : constant
        TopoProof.Geometry.Orientations.Orientation_3D_Kind :=
        TopoProof.Geometry.Orientations.Orientation_3D
          (To_Kernel (A), To_Kernel (B), To_Kernel (C), To_Kernel (D));
   begin
      Result := (case K is
                    when TopoProof.Geometry.Orientations.Coplanar =>
                       Orientation_Coplanar,
                    when TopoProof.Geometry.Orientations.Right_Handed =>
                       Orientation_Right_Handed,
                    when TopoProof.Geometry.Orientations.Left_Handed =>
                       Orientation_Left_Handed);
   end Orientation_3D;

   procedure Make_Plane
     (A : in Point_3D; B : in Point_3D; C : in Point_3D;
      Result : out Plane_Kind)
   is
      Pl : TopoProof.Geometry.Planes.Plane;
      K  : TopoProof.Geometry.Planes.Plane_Kind;
   begin
      TopoProof.Geometry.Planes.Make_Plane
        (To_Kernel (A), To_Kernel (B), To_Kernel (C), Pl, K);
      Result := (case K is
                    when TopoProof.Geometry.Planes.Plane_Valid =>
                       Plane_Valid,
                    when TopoProof.Geometry.Planes.Plane_Collinear =>
                       Plane_Collinear);
   end Make_Plane;

   procedure Plane_Side
     (P : in Point_3D; A : in Point_3D; B : in Point_3D; C : in Point_3D;
      Result : out Plane_Side_Kind)
   is
      use type TopoProof.Geometry.Planes.Plane_Kind;
      Pl : TopoProof.Geometry.Planes.Plane;
      K  : TopoProof.Geometry.Planes.Plane_Kind;
      S  : TopoProof.Geometry.Planes.Plane_Side_Kind;
   begin
      TopoProof.Geometry.Planes.Make_Plane
        (To_Kernel (A), To_Kernel (B), To_Kernel (C), Pl, K);
      if K = TopoProof.Geometry.Planes.Plane_Collinear then
         Result := Side_On_Plane;
      else
         S := TopoProof.Geometry.Planes.Plane_Side (Pl, To_Kernel (P));
         Result := (case S is
                       when TopoProof.Geometry.Planes.In_Front =>
                          Side_In_Front,
                       when TopoProof.Geometry.Planes.Behind =>
                          Side_Behind,
                       when TopoProof.Geometry.Planes.On_Plane =>
                          Side_On_Plane);
      end if;
   end Plane_Side;

   procedure Intersection
     (A : in Point_2D; B : in Point_2D; C : in Point_2D; D : in Point_2D;
      Result : out Intersection_Result)
   is
      KR : constant TopoProof.Geometry.Intersections.Intersection_Result :=
        TopoProof.Geometry.Intersections.Intersection
                    (TopoProof.Geometry.Segments.Segment_2D'(From_Point => To_Kernel (A),
                                To_Point   => To_Kernel (B)),
           TopoProof.Geometry.Segments.Segment_2D'(From_Point => To_Kernel (C),
                                To_Point   => To_Kernel (D)));
   begin
      case KR.Kind is
         when TopoProof.Geometry.Intersections.Point_Intersection =>
            Result.K := Point_Intersection;
            Result.PX := Integer (KR.Point.X);
            Result.PY := Integer (KR.Point.Y);
            Result.QX := 0;
            Result.QY := 0;
         when TopoProof.Geometry.Intersections.Overlap =>
            Result.K := Overlap;
            Result.PX := Integer (KR.Overlap.From_Point.X);
            Result.PY := Integer (KR.Overlap.From_Point.Y);
            Result.QX := Integer (KR.Overlap.To_Point.X);
            Result.QY := Integer (KR.Overlap.To_Point.Y);
         when TopoProof.Geometry.Intersections.No_Intersection =>
            Result.K := No_Intersection;
            Result.PX := 0;
            Result.PY := 0;
            Result.QX := 0;
            Result.QY := 0;
         when TopoProof.Geometry.Intersections.Off_Grid_Crossing =>
            Result.K := Off_Grid_Crossing;
            Result.PX := 0;
            Result.PY := 0;
            Result.QX := 0;
            Result.QY := 0;
      end case;
   end Intersection;

end TopoScript_Geometry;

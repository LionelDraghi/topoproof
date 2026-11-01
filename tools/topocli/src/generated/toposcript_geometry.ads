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

package TopoScript_Geometry is

   type Point_3D is record
      X, Y, Z : Integer;
   end record;

   type Vector_3D is record
      DX, DY, DZ : Integer;
   end record;

   type Point_2D is record
      X, Y : Integer;
   end record;

   type Equal_Kind is (Equal_True, Equal_False);

   type Orientation_Kind is
     (Orientation_Collinear, Orientation_Counter_Clockwise, Orientation_Clockwise);

   type Orientation_3D_Kind is
     (Orientation_Coplanar, Orientation_Right_Handed, Orientation_Left_Handed);

   type Plane_Kind is (Plane_Valid, Plane_Collinear);

   type Plane_Side_Kind is (Side_In_Front, Side_Behind, Side_On_Plane);

   type Intersection_Kind is
     (No_Intersection, Point_Intersection, Off_Grid_Crossing, Overlap);

   type Intersection_Result is record
      K             : Intersection_Kind;
      PX, PY        : Integer;
      QX, QY        : Integer;
   end record;

   procedure Translate
     (P : in Point_3D; V : in Vector_3D; Result : out Point_3D);

   procedure Displacement
     (A : in Point_3D; B : in Point_3D; Result : out Vector_3D);

   procedure Dot_Product
     (A : in Vector_3D; B : in Vector_3D; Result : out Integer);

   procedure Cross_Product
     (A : in Vector_3D; B : in Vector_3D; Result : out Vector_3D);

   procedure Equal
     (A : in Point_3D; B : in Point_3D; Result : out Equal_Kind);

   procedure Orientation
     (A : in Point_2D; B : in Point_2D; C : in Point_2D;
      Result : out Orientation_Kind);

   procedure Orientation_3D
     (A : in Point_3D; B : in Point_3D; C : in Point_3D; D : in Point_3D;
      Result : out Orientation_3D_Kind);

   procedure Make_Plane
     (A : in Point_3D; B : in Point_3D; C : in Point_3D;
      Result : out Plane_Kind);

   procedure Plane_Side
     (P : in Point_3D; A : in Point_3D; B : in Point_3D; C : in Point_3D;
      Result : out Plane_Side_Kind);

   procedure Intersection
     (A : in Point_2D; B : in Point_2D; C : in Point_2D; D : in Point_2D;
      Result : out Intersection_Result);

end TopoScript_Geometry;

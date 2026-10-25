-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

--  The geometry domain of the scripting API (development plan,
--  TopoScript consolidation, Increment 2, and the single front-end
--  Increments 3 and 4): the native side of the proved geometric
--  operations.

with HAC_Sys.Interfacing;

with TopoProof.Geometry.Intersections;
with TopoProof.Geometry.Orientations;
with TopoProof.Geometry.Planes;

package TopoScript_API.Geometry is

   --  The exact result of a point equality: the wrapper injects the
   --  same type in the script world, with the same positions.
   type Equal_Kind is (Equal_True, Equal_False);

   function Equal_To_HAC is new HAC_Sys.Interfacing.To_HAC_Any_Enum
     (Equal_Kind);

   function To_Equal_Kind is new HAC_Sys.Interfacing.To_Native_Any_Enum
     (Equal_Kind);

   --  The HAC representations of the kernel classification kinds: the
   --  wrapper injects the same types in the script world, with the
   --  same positions.
   function Orientation_To_HAC is new HAC_Sys.Interfacing.To_HAC_Any_Enum
     (TopoProof.Geometry.Orientations.Orientation_Kind);

   function To_Orientation_Kind is
     new HAC_Sys.Interfacing.To_Native_Any_Enum
       (TopoProof.Geometry.Orientations.Orientation_Kind);

   function Intersection_To_HAC is new HAC_Sys.Interfacing.To_HAC_Any_Enum
     (TopoProof.Geometry.Intersections.Intersection_Kind);

   function To_Intersection_Kind is
     new HAC_Sys.Interfacing.To_Native_Any_Enum
       (TopoProof.Geometry.Intersections.Intersection_Kind);

   function Plane_Side_To_HAC is new HAC_Sys.Interfacing.To_HAC_Any_Enum
     (TopoProof.Geometry.Planes.Plane_Side_Kind);

   function To_Plane_Side_Kind is
     new HAC_Sys.Interfacing.To_Native_Any_Enum
       (TopoProof.Geometry.Planes.Plane_Side_Kind);

   function Plane_Kind_To_HAC is new HAC_Sys.Interfacing.To_HAC_Any_Enum
     (TopoProof.Geometry.Planes.Plane_Kind);

   function To_Plane_Kind is
     new HAC_Sys.Interfacing.To_Native_Any_Enum
       (TopoProof.Geometry.Planes.Plane_Kind);

   function Orientation_3D_To_HAC is new HAC_Sys.Interfacing.To_HAC_Any_Enum
     (TopoProof.Geometry.Orientations.Orientation_3D_Kind);

   function To_Orientation_3D_Kind is
     new HAC_Sys.Interfacing.To_Native_Any_Enum
       (TopoProof.Geometry.Orientations.Orientation_3D_Kind);

   --  Native side of Translate: the script passes the point and the
   --  vector as records; the callback runs the proved Translate and
   --  writes the translated point into the out parameter.
   procedure Translate_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

   --  Native side of Displacement: the script passes the two points;
   --  the callback runs the proved Displacement and writes the exact
   --  vector from A to B into the out parameter.
   procedure Displacement_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

   --  Native side of Dot_Product: the script passes the two vectors;
   --  the callback runs the proved Dot_Product and writes the exact
   --  result into the out parameter, or records the diagnostic when
   --  the exact result leaves the 64-bit script integers.
   procedure Dot_Product_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

   --  Native side of Cross_Product: the callback runs the proved
   --  Cross_Product and writes the exact cross vector into the out
   --  parameter.
   procedure Cross_Product_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

   --  Native side of Make_Plane: the script passes the three defining
   --  points; the callback runs the plane constructor and writes the
   --  construction report, the collinear degeneracy included.
   procedure Make_Plane_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

   --  Native side of Plane_Side: the script passes the classified
   --  point and the three defining points; the callback runs the
   --  proved classification and writes the side kind.
   procedure Plane_Side_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

   --  Native side of Equal: the callback runs the exact point
   --  equality of the kernel and writes the result into the out
   --  parameter.
   procedure Equal_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

   --  Native side of Orientation: the callback runs the exact
   --  orientation classification of the kernel on the 2D path
   --  A -> B -> C, and writes the kind into the out parameter.
   procedure Orientation_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

   --  Native side of Orientation_3D: the callback runs the exact
   --  orientation classification of the kernel on the ordered point
   --  quadruple A, B, C, D, and writes the kind into the out
   --  parameter.
   procedure Orientation_3D_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

   --  Native side of Intersection: the callback runs the exact
   --  intersection classification of the kernel on the segments
   --  A -> B and C -> D, and writes the kind with the common
   --  position, or the two overlap boundaries, into the out record.
   procedure Intersection_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

end TopoScript_API.Geometry;

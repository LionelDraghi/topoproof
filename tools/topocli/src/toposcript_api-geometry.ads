-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

--  The geometry domain of the scripting API (development plan,
--  TopoScript consolidation, Increment 2): the native side of the
--  proved geometric operations.

with HAC_Sys.Interfacing;

package TopoScript_API.Geometry is

   --  The exact result of a point equality: the wrapper injects the
   --  same type in the script world, with the same positions.
   type Equal_Kind is (Equal_True, Equal_False);

   function Equal_To_HAC is new HAC_Sys.Interfacing.To_HAC_Any_Enum
     (Equal_Kind);

   function To_Equal_Kind is new HAC_Sys.Interfacing.To_Native_Any_Enum
     (Equal_Kind);

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

   --  Native side of Equal: the callback runs the exact point
   --  equality of the kernel and writes the result into the out
   --  parameter.
   procedure Equal_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

end TopoScript_API.Geometry;

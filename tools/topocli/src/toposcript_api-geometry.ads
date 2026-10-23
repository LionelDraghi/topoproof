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

   --  Native side of Translate: the script passes the point and the
   --  vector as records; the callback runs the proved Translate and
   --  writes the translated point into the out parameter.
   procedure Translate_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

end TopoScript_API.Geometry;

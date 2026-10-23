-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

--  The output domain of the scripting API (development plan,
--  TopoScript consolidation, Increment 2): the canonical textual
--  results on standard output, the same representations as the
--  topocli commands.

with HAC_Sys.Interfacing;

package TopoScript_API.Output is

   --  Native side of Put: writes the canonical representation of the
   --  point on standard output, the same one as the topocli client.
   procedure Put_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

   --  Native side of Put_Loop: writes `loop closed ...`, or records
   --  the rejection diagnostic of the loop kind.
   procedure Put_Loop_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

   --  Native side of Put_Face: writes `face ...`, or records the
   --  rejection diagnostic of the face kind.
   procedure Put_Face_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

end TopoScript_API.Output;

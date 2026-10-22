-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

--  Native side of the TopoScript scripting API (development plan,
--  Milestone 6): the callbacks run the proved kernel operations and
--  exchange values with the script through HAC elements. The
--  operations are registered before the build, so the script sees them
--  under their TopoScript names.

with HAC_Sys.Builder;

package TopoScript_API is

   --  The drawing colors of the diagnostic images: the wrapper injects
   --  the same type in the script world, with the same positions.
   type Color_Kind is (Blue, Green, Red);

   --  Register every native operation on the build data.
   procedure Register_All (BD : HAC_Sys.Builder.Build_Data);

   --  Empty when the last script run completed every operation
   --  successfully; otherwise the diagnostic of the rejected operation,
   --  reported by the caller on standard error after the run. An
   --  exception raised inside the HAC virtual machine would not
   --  propagate to the caller, so the callbacks record the diagnostic
   --  here instead.
   function Last_Failure return String;

end TopoScript_API;

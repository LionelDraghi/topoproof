-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

--  Compilation diagnostics of the generated wrapper, mapped back to the
--  TopoScript fragment (development plan, Milestone 6, Increment 2).
--
--  HAC reports locations in the wrapped compilation unit; the wrapper
--  knows where each fragment region starts, so the pipe rewrites every
--  line number to the fragment before printing, on standard error.

with HAC_Sys.Defs;

package TopoScript_Diagnostics is

   procedure Set_Mapping
     (Path             : String;
      Declaration_Skip : Positive;
      Begin_Line       : Positive;
      Statement_Adjust : Positive);
   --  Remember the fragment path and the line offsets computed by
   --  TopoScript_Wrapper.Generate. Must be called before the build.

   procedure Pipe (Kit : HAC_Sys.Defs.Diagnostic_Kit);
   --  The HAC error pipe: prints the diagnostic on standard error with
   --  the line mapped to the fragment.

end TopoScript_Diagnostics;

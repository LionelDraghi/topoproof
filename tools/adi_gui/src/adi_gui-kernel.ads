-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

--  The TopoScript front-end driver. Adi_GUI owns no geometry: every
--  kernel decision goes through a `topocli run_code` subprocess, and
--  the GUI only reads what the kernel reports (DD-006, the single
--  front-end). The canonical traces come back through the output
--  file; the kernel diagnostics come back verbatim through the
--  captured standard error.

with Ada.Strings.Unbounded;

package Adi_Gui.Kernel is

   Frontend_Not_Found : exception;
   Frontend_Failed    : exception;

   type Result is record
      Traces : Ada.Strings.Unbounded.Unbounded_String;
      --  Every canonical result line of the run, in order, newlines
      --  preserved.

      Diagnostics : Ada.Strings.Unbounded.Unbounded_String;
      --  The kernel diagnostics, verbatim, as the front-end wrote them.

      Exit_Code : Natural;
   end record;

   --  Run the fragment and answer what the kernel reported. Accepted
   --  is Exit_Code = 0; a rejection carries the diagnostics verbatim.
   function Run_Code (Fragment : String) return Result;

end Adi_Gui.Kernel;

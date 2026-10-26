pragma Ada_2022;

--  The TopoScript front-end driver. TopoGUI owns no geometry: every
--  kernel decision goes through a `topocli run_code` subprocess, and
--  the GUI only reads what the kernel reports (DD-006, the single
--  front-end). The canonical traces come back through the output
--  file; the kernel diagnostics come back verbatim through the
--  captured standard error.

with Ada.Strings.Unbounded;

package Topogui.Kernel is

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

end Topogui.Kernel;

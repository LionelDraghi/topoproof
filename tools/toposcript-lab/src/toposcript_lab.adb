-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

--  TopoScript feasibility prototype (development plan, Milestone 6,
--  Increment 1): this program embeds the HAC interpreter, builds the
--  source given on the command line and runs it. The script calls the
--  proved kernel operations through the native callbacks registered by
--  TopoScript_API. The prototype validates the output contract: the
--  canonical result goes to standard output, the compilation messages
--  and the diagnostics go to standard error, and the process status
--  reports the execution verdict.

with Ada.Command_Line;                use Ada.Command_Line;
with Ada.Text_IO;                     use Ada.Text_IO;

with HAC_Sys.Builder;                 use HAC_Sys.Builder;
with HAC_Sys.PCode.Interpreter;       use HAC_Sys.PCode.Interpreter;

with TopoScript_API;                  use TopoScript_API;

procedure Toposcript_Lab is
begin
   if Argument_Count /= 1 then
      Put_Line (Current_Error, "usage: toposcript_lab FILE.topo");
      Set_Exit_Status (Failure);
      return;
   end if;

   declare
      Path : constant String := Argument (1);
      BD   : Build_Data;
   begin
      --  The native operations are registered before the build, so the
      --  script sees them under their TopoScript names.
      Register_All (BD);

      BD.Build_Main_from_File (Path);

      if BD.Build_Successful then
         declare
            Post_Mortem : Post_Mortem_Data;
         begin
            Interpret_on_Current_IO (BD, 0, Path, Post_Mortem);

            if Is_Exception_Raised (Post_Mortem.Unhandled) then
               Put_Line
                 (Current_Error,
                  "error: " & Image (Post_Mortem.Unhandled) & ": " &
                  Message (Post_Mortem.Unhandled));
               Set_Exit_Status (Failure);

            elsif Last_Failure /= "" then
               Put_Line (Current_Error, Last_Failure);
               Set_Exit_Status (Failure);

            else
               Set_Exit_Status (Success);
            end if;
         end;

      else
         --  The compilation messages went to standard error already,
         --  through the default HAC trace.
         Set_Exit_Status (Failure);
      end if;
   end;
end Toposcript_Lab;

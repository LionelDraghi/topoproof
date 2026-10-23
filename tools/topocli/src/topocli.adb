-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with Ada.Command_Line;      use Ada.Command_Line;
with Ada.Exceptions;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;           use Ada.Text_IO;
with HAC_Sys.Builder;
with HAC_Sys.PCode.Interpreter;
with TopoScript_API;
with TopoScript_API.Output;
with TopoScript_API.Session;
with TopoScript_Diagnostics;
with TopoScript_Wrapper;

procedure TopoCLI is
   Usage_Error : exception;
   Output_Path : Unbounded_String;

   --  TopoScript (development plan, Milestone 6): the fragment
   --  execution, shared by the file entry and the inline entry. The
   --  verdict keeps the topocli conventions: the canonical result goes
   --  to standard output, the diagnostics to standard error, and the
   --  process status carries the outcome.
   procedure Execute_Fragment (Fragment : String; Path : String) is
      --  One run owns one session: the clean state is explicit, and
      --  the callbacks of the run operate on this session.
      Session : aliased TopoScript_API.Script_Session;
   begin
      TopoScript_API.Session.Reset (Session);
      TopoScript_API.Session.Designate (Session'Unchecked_Access);
      --  The run-owned output destination (DD-004, decision 8): with
      --  --output, every canonical Put line goes to the file instead
      --  of the standard output.
      if Length (Output_Path) > 0 then
         TopoScript_API.Output.Set_Output_Path (To_String (Output_Path));
      end if;
      declare
         Wrapped : TopoScript_Wrapper.Wrapped_Source;
      begin
         TopoScript_Wrapper.Generate (Fragment, Path, Wrapped);
         declare
            BD : HAC_Sys.Builder.Build_Data;
         begin
            TopoScript_API.Register_All (BD);
            TopoScript_Diagnostics.Set_Mapping
               (Path, Wrapped.Declaration_Skip, Wrapped.Begin_Line, Wrapped.Statement_Adjust);
            HAC_Sys.Builder.Set_Message_Feedbacks
               (BD,
                (pipe => TopoScript_Diagnostics.Pipe'Access, progress => null, detail_level => 0));
            TopoScript_Wrapper.Set_Source (To_String (Wrapped.Source));
            --  The virtual source name fixes the main unit name
            --  expected by the HAC librarian; the fragment path is
            --  reported by the diagnostics pipe instead.
            BD.Set_Main_Source_Stream (TopoScript_Wrapper.Stream, "toposcript_run.adb", 0);
            BD.Build_Main;

            if BD.Build_Successful then
               declare
                  Post_Mortem : HAC_Sys.PCode.Interpreter.Post_Mortem_Data;
               begin
                  HAC_Sys.PCode.Interpreter.Interpret_on_Current_IO (BD, 0, Path, Post_Mortem);
                  if HAC_Sys.PCode.Interpreter.Is_Exception_Raised (Post_Mortem.Unhandled) then
                     Put_Line
                        (Standard_Error,
                         "error: "
                         & HAC_Sys.PCode.Interpreter.Image (Post_Mortem.Unhandled)
                         & ": "
                         & HAC_Sys.PCode.Interpreter.Message (Post_Mortem.Unhandled));
                     Set_Exit_Status (Failure);

                  elsif TopoScript_API.Session.Last_Failure (Session) /= "" then
                     Put_Line (Standard_Error, TopoScript_API.Session.Last_Failure (Session));
                     Set_Exit_Status (Failure);

                  else
                     Set_Exit_Status (Success);
                  end if;
               end;

            else
               --  The compilation messages went to standard error
               --  already, through the diagnostics pipe.
               Set_Exit_Status (Failure);
            end if;
         end;

         TopoScript_API.Output.Close_Output;

      exception
         when E : TopoScript_Wrapper.Wrapper_Error =>
            TopoScript_API.Output.Close_Output;
            Put_Line (Standard_Error, Ada.Exceptions.Exception_Message (E));
            Set_Exit_Status (Failure);
      end;
   end Execute_Fragment;

   --  The file entry: run FILE.topo, a fragment of declarations
   --  followed by statements.
   procedure Run_Script (Path : String) is
      Fragment : Unbounded_String;
      F        : File_Type;
   begin
      Open (F, In_File, Path);
      while not End_Of_File (F) loop
         Append (Fragment, Get_Line (F));
         Append (Fragment, ASCII.LF);
      end loop;
      Close (F);
      Execute_Fragment (To_String (Fragment), Path);
   exception
      --  The fragment never executed, so no output file was opened:
      --  there is nothing to close, and no session is designated yet.
      when Name_Error | Use_Error =>
         Put_Line (Standard_Error, "error: file not found: " & Path);
         Set_Exit_Status (Failure);
   end Run_Script;

   --  The inline entry (DD-004): run_code, followed by the fragment
   --  as the rest of the command line. The dispatcher hands over the
   --  arguments already joined with spaces; the fragment is split
   --  into lines at every semicolon, so a whole script fits one
   --  command line on every runner, and the wrapper line rules apply
   --  unchanged; the diagnostics point at the inline lines under the
   --  <inline> name. A fragment comment may not carry a semicolon:
   --  the split does not look inside comments.
   procedure Run_Inline (Fragment : String) is
      Normalized : Unbounded_String;
   begin
      for C of Fragment loop
         Append (Normalized, C);
         if C = ';' then
            Append (Normalized, ASCII.LF);
         end if;
      end loop;
      Execute_Fragment (To_String (Normalized), "<inline>");
   end Run_Inline;

begin
   --  The runner owns the whole command line (DD-004): the two entries
   --  are `topocli run FILE.topo` and `topocli run_code FRAGMENT`, the
   --  output file of the canonical results is their only option
   --  (DD-004, decision 8), and the command form of the operations is
   --  retired: every operation runs as a script.
   if Argument_Count >= 2 and then (Argument (1) = "run" or else Argument (1) = "run_code") then
      if Argument (1) = "run" then
         declare
            J : Positive := 3;
         begin
            while J <= Argument_Count loop
               if Argument (J) = "--output" and then J < Argument_Count then
                  Output_Path := To_Unbounded_String (Argument (J + 1));
                  J := J + 1;

               else
                  raise Usage_Error;

               end if;
               J := J + 1;
            end loop;
         end;
         Run_Script (Argument (2));

      else
         --  The inline fragment is the rest of the command line:
         --  every argument joined with spaces, with the --output
         --  pair extracted. A POSIX shell passes the quoted fragment
         --  as one argument, so the join is the identity; a Windows
         --  invocation may reach the tool with the fragment split on
         --  its spaces, and the join restores it.
         declare
            J        : Positive := 2;
            Fragment : Unbounded_String;
         begin
            while J <= Argument_Count loop
               if Argument (J) = "--output" and then J < Argument_Count then
                  Output_Path := To_Unbounded_String (Argument (J + 1));
                  J := J + 1;

               else
                  if Length (Fragment) > 0 then
                     Append (Fragment, " ");
                  end if;
                  Append (Fragment, Argument (J));

               end if;
               J := J + 1;
            end loop;
            if Length (Fragment) = 0 then
               raise Usage_Error;

            end if;
            Run_Inline (To_String (Fragment));
         end;
      end if;
      return;
   end if;

   if Argument_Count = 1 and then (Argument (1) = "--help" or else Argument (1) = "-h") then
      Put_Line ("usage: topocli run FILE.topo [--output FILE]");
      Put_Line ("       topocli run_code FRAGMENT [--output FILE]");
      Put_Line ("run executes a TopoScript source file;");
      Put_Line ("run_code executes an inline fragment, split into");
      Put_Line ("lines at every semicolon;");
      Put_Line ("--output receives every canonical result line of the");
      Put_Line ("run, in order");
      return;
   end if;

   raise Usage_Error;

exception
   when Usage_Error =>
      Put_Line (Standard_Error, "error: invalid command line");
      Put_Line (Standard_Error, "try 'topocli --help'");
      Set_Exit_Status (Failure);
   when Name_Error =>
      Put_Line (Standard_Error, "error: input or output file cannot be opened");
      Set_Exit_Status (Failure);

end TopoCLI;

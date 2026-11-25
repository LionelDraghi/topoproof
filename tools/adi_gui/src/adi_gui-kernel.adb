-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

--  The TopoScript front-end driver. Adi_GUI owns no geometry: every
--  kernel decision goes through a `topocli run` subprocess over a
--  script file, and the GUI only reads what the kernel reports
--  (DD-006, the single front-end). The canonical traces come back
--  through the output file; the kernel diagnostics come back verbatim
--  through the captured standard error.

--  Portage Windows: the same command shape drives every shell. The
--  fragment travels through a script file (`run FILE --output FILE`),
--  never through the command line, so nothing in the script body is
--  quoted or split at semicolons. `2>` is POSIX and cmd syntax alike;
--  only the shell program differs (bash/sh found on the path, cmd
--  otherwise). An infrastructure failure (frontend not found, no
--  shell, spawn refused) reaches the GUI as an ordinary failed Result,
--  displayed in the status line: it never kills the application.

with Ada.Characters.Handling;
with Ada.Command_Line;
with Ada.Directories;
with Ada.Text_IO;
with GNAT.OS_Lib;

package body Adi_Gui.Kernel is

   function Frontend_Path return String;
   --  The runner appears beside the GUI in the delivered layout, or in
   --  `bin` one level up in the repository layout. Every candidate is
   --  tried with and without the `.exe` suffix: on Windows the file on
   --  disk is `topocli.exe`, and Ada.Directories does not append the
   --  suffix on its own.

   function Frontend_Path return String is
      Base : constant String :=
        Ada.Directories.Containing_Directory
          (GNAT.OS_Lib.Normalize_Pathname (Ada.Command_Line.Command_Name));
   begin
      for C in 1 .. 3 loop
         declare
            Candidate : constant String :=
              (case C is
                 when 1 => "topocli",
                 when 2 => Base & "/topocli",
                 when 3 => Base & "/../../bin/topocli");
         begin
            for Suffix in 1 .. 2 loop
               declare
                  Full : constant String :=
                    (case Suffix is
                       when 1 => Candidate,
                       when 2 => Candidate & ".exe");
               begin
                  if Ada.Directories.Exists (Full) then
                     return Full;
                  end if;
               end;
            end loop;
         end;
      end loop;
      raise Frontend_Not_Found with "topocli not found";
   end Frontend_Path;

   --  The shell layer. bash and sh answer `-c CMD`; cmd answers
   --  `/c CMD` with the same command shape.
   function Shell_Path return String is
      Found : GNAT.OS_Lib.String_Access;
      use type GNAT.OS_Lib.String_Access;
   begin
      Found := GNAT.OS_Lib.Locate_Exec_On_Path ("bash");
      if Found /= null then
         return Found.all;
      end if;
      Found := GNAT.OS_Lib.Locate_Exec_On_Path ("sh");
      if Found /= null then
         return Found.all;
      end if;
      Found := GNAT.OS_Lib.Locate_Exec_On_Path ("cmd");
      if Found /= null then
         return Found.all;
      end if;
      return "";
   end Shell_Path;

   function Is_Cmd (Shell : String) return Boolean is
      use Ada.Characters.Handling;
   begin
      return To_Lower (Ada.Directories.Base_Name (Shell)) = "cmd";
   end Is_Cmd;

   function Temp_File (Suffix : String) return String is
     ("adi_gui_" & Suffix & ".tmp");

   --  The whole file, as text. An absent file reads empty.
   function Read_Whole_File (Path : String) return String is
      use Ada.Strings.Unbounded;
      Content : Unbounded_String;
      File    : Ada.Text_IO.File_Type;
   begin
      if not Ada.Directories.Exists (Path) then
         return "";
      end if;
      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         Append (Content, Ada.Text_IO.Get_Line (File) & ASCII.LF);
      end loop;
      Ada.Text_IO.Close (File);
      return To_String (Content);
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         raise;
   end Read_Whole_File;

   function Write_Whole_File (Path : String; Content : String) return Boolean
   is
      File : Ada.Text_IO.File_Type;
   begin
      Ada.Text_IO.Create (File, Ada.Text_IO.Out_File, Path);
      Ada.Text_IO.Put (File, Content);
      Ada.Text_IO.Close (File);
      return True;
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         return False;
   end Write_Whole_File;

   function Run_Code (Fragment : String) return Result is
      use Ada.Strings.Unbounded;
      Frag_File : constant String := Temp_File ("frag.topo");
      Out_File  : constant String := Temp_File ("out");
      Err_File  : constant String := Temp_File ("err");
      R         : Result;
   begin
      if not Write_Whole_File (Frag_File, Fragment) then
         return (Exit_Code   => 3,
                 Traces      => Null_Unbounded_String,
                 Diagnostics => To_Unbounded_String
                   ("error: cannot write the script file"));
      end if;

      declare
         Command : Unbounded_String;
      begin
         Append (Command, Frontend_Path & " run " & Frag_File
                 & " --output " & Out_File & " 2> " & Err_File);

         declare
            Shell  : constant String := Shell_Path;
            Status : Integer;
         begin
            if Shell = "" then
               R.Exit_Code := 3;
               R.Diagnostics := To_Unbounded_String
                 ("error: no shell found to drive the front-end");
            elsif Is_Cmd (Shell) then
               Status := GNAT.OS_Lib.Spawn
                 (Shell,
                  [new String'("/c"), new String'(To_String (Command))]);
               R.Exit_Code := (if Status < 0 then 3 else Natural (Status));
            else
               Status := GNAT.OS_Lib.Spawn
                 (Shell,
                  [new String'("-c"), new String'(To_String (Command))]);
               R.Exit_Code := (if Status < 0 then 3 else Natural (Status));
            end if;
         end;
      exception
         when Frontend_Not_Found =>
            R.Exit_Code := 3;
            R.Diagnostics := To_Unbounded_String
              ("error: topocli not found");
      end;

      if R.Exit_Code < 3 then
         R.Traces := To_Unbounded_String (Read_Whole_File (Out_File));
         R.Diagnostics := To_Unbounded_String (Read_Whole_File (Err_File));
      end if;
      begin
         if Ada.Directories.Exists (Frag_File) then
            Ada.Directories.Delete_File (Frag_File);
         end if;
         if Ada.Directories.Exists (Out_File) then
            Ada.Directories.Delete_File (Out_File);
         end if;
         if Ada.Directories.Exists (Err_File) then
            Ada.Directories.Delete_File (Err_File);
         end if;
      exception
         when others => null;
      end;
      return R;
   end Run_Code;

end Adi_Gui.Kernel;

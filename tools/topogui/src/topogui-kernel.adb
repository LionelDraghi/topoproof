pragma Ada_2022;

with Ada.Command_Line;
with Ada.Directories;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;
with GNAT.OS_Lib;

package body Topogui.Kernel is

   --  The front-end is the repository's runner: `bin/` at the
  --  repository root, next to the GUI executable in the delivered
  --  layout. When the project splits from the repository, this
  --  becomes a configuration item.

   function Frontend_Path return String;

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
            if Ada.Directories.Exists (Candidate) then
               return Candidate;
            end if;
         end;
      end loop;
      raise Frontend_Not_Found with "topocli not found";
   end Frontend_Path;

   --  The whole file, as text. An absent file reads empty.
   function Read_Whole_File (Path : String) return String;

   function Read_Whole_File (Path : String) return String is
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

   function Temp_File (Suffix : String) return String is
      ("topogui_" & Suffix & ".tmp");

   function Run_Code (Fragment : String) return Result is
      Out_File : constant String := Temp_File ("out");
      Err_File : constant String := Temp_File ("err");
      --  The shell owns the redirections: GNAT's spawn answers no
      --  capture. POSIX syntax; a Windows port reconsiders this line.
      Command  : constant String :=
        Frontend_Path & " run_code """ & Fragment
        & """ --output " & Out_File & " 2>" & Err_File;
      Args     : GNAT.OS_Lib.Argument_List :=
        [1 => new String'("-c"),
         2 => new String'(Command)];
      R        : Result;
   begin
      R.Exit_Code := Natural (GNAT.OS_Lib.Spawn ("/bin/sh", Args));
      for A of Args loop
         GNAT.OS_Lib.Free (A);
      end loop;

      R.Traces      := To_Unbounded_String (Read_Whole_File (Out_File));
      R.Diagnostics := To_Unbounded_String (Read_Whole_File (Err_File));
      if Ada.Directories.Exists (Out_File) then
         Ada.Directories.Delete_File (Out_File);
      end if;
      if Ada.Directories.Exists (Err_File) then
         Ada.Directories.Delete_File (Err_File);
      end if;
      return R;
   end Run_Code;

end Topogui.Kernel;

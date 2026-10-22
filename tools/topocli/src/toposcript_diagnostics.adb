-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;           use Ada.Strings.Unbounded;
with Ada.Text_IO;                     use Ada.Text_IO;

with HAC_Sys.Defs;                    use HAC_Sys.Defs;
with HAT;

package body TopoScript_Diagnostics is

   Path             : Unbounded_String;
   Declaration_Skip : Positive := 1;
   Begin_Line       : Positive := 1;
   Statement_Adjust : Positive := 1;

   procedure Set_Mapping
     (Path             : String;
      Declaration_Skip : Positive;
      Begin_Line       : Positive;
      Statement_Adjust : Positive) is
   begin
      TopoScript_Diagnostics.Path := To_Unbounded_String (Path);
      TopoScript_Diagnostics.Declaration_Skip := Declaration_Skip;
      TopoScript_Diagnostics.Begin_Line := Begin_Line;
      TopoScript_Diagnostics.Statement_Adjust := Statement_Adjust;
   end Set_Mapping;

   function Prefix (Kind : Diagnostic_Kind_Type) return String is
   begin
      case Kind is
         when error =>
            return "error";
         when warning =>
            return "warning";
         when note =>
            return "note";
         when style =>
            return "style";
      end case;
   end Prefix;

   procedure Pipe (Kit : HAC_Sys.Defs.Diagnostic_Kit) is
      use Ada.Strings.Fixed;
      Wrapper_Line  : constant Integer := Kit.location.line;
      Fragment_Line : Integer;
   begin
      --  Map the wrapper line back to the fragment: the declaration
      --  region is offset by the fixed header, the statement region by
      --  the injected API block and the begin.
      if Wrapper_Line < Begin_Line then
         Fragment_Line := Wrapper_Line - Declaration_Skip;
      else
         Fragment_Line := Wrapper_Line - Statement_Adjust;
      end if;
      if Fragment_Line < 1 then
         --  The diagnostic points inside the wrapper itself (for
         --  instance a duplicate of an API name): the raw location is
         --  more useful than a clamped one.
         Fragment_Line := Wrapper_Line;
      end if;

      Put_Line
        (Current_Error,
         To_String (Path) & ":" &
         Trim (Fragment_Line'Image, Ada.Strings.Both) & ":" &
         Trim (Kit.location.column_start'Image, Ada.Strings.Both) & ": " &
         Prefix (Kit.diagnostic_kind) & ": " &
         HAT.To_String (Kit.message));
   end Pipe;

end TopoScript_Diagnostics;

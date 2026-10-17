-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with Ada.Command_Line;
with Ada.Exceptions;
with Ada.Text_IO;
with Topodraw;

procedure Topodraw_Main is
   use Ada.Text_IO;

   Total : Natural := 0;
begin

   if Ada.Command_Line.Argument_Count = 0 then
      Put_Line (Standard_Error, "usage: topodraw FILE [FILE ...]");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      return;
   end if;
   for I in 1 .. Ada.Command_Line.Argument_Count loop
      declare
         Path : constant String := Ada.Command_Line.Argument (I);
      begin
         Put_Line ("scanning " & Path);
         Total := Total + Topodraw.Process (Path);
      end;
   end loop;
   Put_Line (Natural'Image (Total) & " diagram(s) generated");

exception
   when E : Topodraw.Scene_Error =>
      Put_Line (Standard_Error,
                "topodraw: " & Ada.Exceptions.Exception_Message (E));
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
end Topodraw_Main;

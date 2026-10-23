-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with Ada.Strings.Unbounded;
use Ada.Strings.Unbounded;

package body TopoScript_API.Session is

   --  The designated session. The HAC callbacks receive only the
   --  element array, so this designation is the single bridge between
   --  the callbacks and the run state: the runner designates the
   --  session of the run before the build, and the designation lives
   --  as long as the caller's session object, which is guaranteed to
   --  outlive the run.
   Current : Session_Access := null;

   procedure Reset (Session : in out Script_Session) is
   begin
      Session.Failure      := Null_Unbounded_String;
      Session.Image_Open   := False;
      Session.Image_Name   := Null_Unbounded_String;
      Session.The_Scene    := (others => <>);
      Session.Anchor_Count := 0;
      Session.Chain.Clear;
   end Reset;

   procedure Designate (Session : Session_Access) is
   begin
      Current := Session;
   end Designate;

   function Current_Session return not null Session_Access is
     (Current);

   procedure Record_Failure (Message : String) is
   begin
      if Length (Current.Failure) = 0 then
         Current.Failure := To_Unbounded_String (Message);
      end if;
   end Record_Failure;

   function Last_Failure (Session : Script_Session) return String is
   begin
      return To_String (Session.Failure);
   end Last_Failure;

end TopoScript_API.Session;

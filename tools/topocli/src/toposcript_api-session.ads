-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

--  The lifecycle of the execution session (development plan,
--  TopoScript consolidation, Increments 1 and 2): the session type
--  and its state live in the root package, and this child package
--  owns the reset, the designation and the diagnostic recording that
--  the domains and the runner operate through.

package TopoScript_API.Session is

   --  Restore the clean state of Session: no recorded failure, no
   --  open image, an empty scene, an empty chain. Every run starts
   --  from a session in this state, so two consecutive executions
   --  share no stale state, without relying on a process restart.
   procedure Reset (Session : in out Script_Session);

   --  Make Session the one the registered callbacks operate on. The
   --  HAC virtual machine calls the native callbacks with the element
   --  array only, so the session cannot travel through the callbacks'
   --  parameters: the runner designates the session of the run before
   --  the build, with an unchecked access, and guarantees that the
   --  session object outlives the run. No callback runs outside a
   --  designated session.
   procedure Designate (Session : Session_Access);

   --  The session designated for the current run: the single bridge
   --  between the domain callbacks and the run state. Called only
   --  within a run: the runner designates the session of the run
   --  before the build, so the designated session is never null
   --  while the callbacks run.
   function Current_Session return not null Session_Access;

   --  Record the diagnostic of the first rejected operation on the
   --  designated session: a script runs on after a rejected
   --  operation, and the later ones must not mask the actual cause
   --  with their own rejection.
   procedure Record_Failure (Message : String);

   --  The diagnostic of the first rejected operation of Session: empty
   --  when the run completed every operation successfully. An
   --  exception raised inside the HAC virtual machine would not
   --  propagate to the caller, so the callbacks record the diagnostic
   --  in the session instead.
   function Last_Failure (Session : Script_Session) return String;

end TopoScript_API.Session;

-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

--  Native side of the TopoScript scripting API: the callbacks run the
--  proved kernel operations and exchange values with the script through
--  HAC elements. The operations are registered before the build, so the
--  script sees them under their TopoScript names. The mutable execution
--  state of a run lives in one Script_Session (development plan,
--  TopoScript consolidation, Increment 1): the runner owns the session
--  of the run, and the callbacks operate on the designated session.

with HAC_Sys.Builder;

with Ada.Containers.Indefinite_Vectors;
with Ada.Strings.Unbounded;
with TopoProof.Numerics;
with Topodraw;

package TopoScript_API is

   --  The drawing colors of the diagnostic images: the wrapper injects
   --  the same type in the script world, with the same positions.
   type Color_Kind is (Blue, Green, Red);

   --  The classification kinds of the loop and face operations: the
   --  wrapper injects the same types in the script world, with the
   --  same positions. The valid kinds carry the canonical result, the
   --  others mirror the kernel validity kinds and their client
   --  diagnostics. HAC does not overload enumeration literals, so the
   --  face literals are prefixed.
   type Loop_Kind is
     (Counter_Clockwise, Clockwise, Degenerate,
      Open_Chain, Orphan_Edge, Missing_Endpoint,
      Disconnected_Chain, Degenerate_Support);

   type Face_Kind is
     (Face_Counter_Clockwise, Face_Clockwise,
      Face_Degenerate_Boundary, Face_Invalid_Boundary);

   --  The execution session of one script run: it owns the whole
   --  mutable execution state, so no library-level variable carries
   --  state between runs. A limited private type: a session is never
   --  copied, and its state is reachable only through its operations
   --  and the designation below.
   type Script_Session is limited private;

   --  Restore the clean state of Session: no recorded failure, no
   --  open image, an empty scene, an empty chain. Every run starts
   --  from a session in this state, so two consecutive executions
   --  share no stale state, without relying on a process restart.
   procedure Reset (Session : in out Script_Session);

   --  Access to one execution session: the designation below crosses
   --  the accessibility rules on purpose, under the lifetime contract
   --  stated here.
   type Session_Access is access all Script_Session;

   --  Make Session the one the registered callbacks operate on. The
   --  HAC virtual machine calls the native callbacks with the element
   --  array only, so the session cannot travel through the callbacks'
   --  parameters: the runner designates the session of the run before
   --  the build, with an unchecked access, and guarantees that the
   --  session object outlives the run. No callback runs outside a
   --  designated session.
   procedure Designate (Session : Session_Access);

   --  Register every native operation on the build data.
   procedure Register_All (BD : HAC_Sys.Builder.Build_Data);

   --  The diagnostic of the first rejected operation of Session: empty
   --  when the run completed every operation successfully. An
   --  exception raised inside the HAC virtual machine would not
   --  propagate to the caller, so the callbacks record the diagnostic
   --  in the session instead.
   function Last_Failure (Session : Script_Session) return String;

private

   --  One 2D point of the topology chain: in the script chain, a
   --  vertex is identified by its position, so a repeated position
   --  closes on the same vertex.
   type Chain_Point is record
      X, Y : TopoProof.Numerics.Grid_Coordinate;
   end record;

   package Chain_Vectors is new Ada.Containers.Indefinite_Vectors
     (Positive, Chain_Point);

   type Script_Session is limited record
      --  The diagnostic of the first rejected operation: a script
      --  runs on after a rejected operation, and the later ones must
      --  not mask the actual cause with their own rejection.
      Failure : Ada.Strings.Unbounded.Unbounded_String;
      --  The image state: one image at a time, written and closed by
      --  End_Image.
      Image_Open : Boolean := False;
      Image_Name : Ada.Strings.Unbounded.Unbounded_String;
      --  The drawing scene of the open image.
      The_Scene : Topodraw.Scene;
      --  The counter of the anchor names of the scene points.
      Anchor_Count : Natural := 0;
      --  The topology chain: it lives for the whole script run.
      --  Add_Point always appends, and Make_Loop and Make_Face
      --  classify the chain as it stands at the call without ever
      --  clearing it, so the same chain can be classified first as a
      --  loop, then as a face boundary.
      Chain : Chain_Vectors.Vector;
   end record;

end TopoScript_API;

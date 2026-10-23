-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

--  The topology domain of the scripting API (development plan,
--  TopoScript consolidation, Increment 2): the classification kinds of
--  the loop and face operations, and the native side of the chain
--  building, running the exact kernel classification, the same one as
--  the loop and face client operations.

with HAC_Sys.Interfacing;

package TopoScript_API.Topology is

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

   --  The HAC representations of the classification kinds.
   function Loop_To_HAC is new HAC_Sys.Interfacing.To_HAC_Any_Enum
     (Loop_Kind);

   function Face_To_HAC is new HAC_Sys.Interfacing.To_HAC_Any_Enum
     (Face_Kind);

   function To_Loop_Kind is new HAC_Sys.Interfacing.To_Native_Any_Enum
     (Loop_Kind);

   function To_Face_Kind is new HAC_Sys.Interfacing.To_Native_Any_Enum
     (Face_Kind);

   --  Native side of Add_Point: appends one 2D point to the topology
   --  chain of the designated session.
   procedure Add_Point_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

   --  Native side of Make_Loop: classifies the accumulated chain of
   --  the designated session as a loop.
   procedure Make_Loop_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

   --  Native side of Make_Face: classifies the same chain as a face
   --  boundary.
   procedure Make_Face_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

end TopoScript_API.Topology;

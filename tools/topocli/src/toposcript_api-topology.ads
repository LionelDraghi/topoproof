-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

--  The topology domain of the scripting API (development plan,
--  TopoScript consolidation, Increment 2, and the single front-end,
--  Increment 5): the classification kinds of the loop and face
--  operations and of the six contour predicates, and the native side
--  of the chain building, running the exact kernel classification,
--  the same one as the loop, face and contour client operations.

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

   --  The result kinds of the contour predicates, the same
   --  classifications as the contour client operations. HAC does not
   --  overload enumeration literals, so the literals colliding with
   --  the loop kinds are prefixed.
   type Continuity_Kind is (Continuous, Discontinuous);

   type Closure_Kind is (Closed, Open);

   type Contour_Orientation_Kind is
     (Contour_Counter_Clockwise, Contour_Clockwise, Contour_Degenerate);

   type Bool_Kind is (Bool_True, Bool_False);

   --  The HAC representations of the classification kinds.
   function Loop_To_HAC is new HAC_Sys.Interfacing.To_HAC_Any_Enum
     (Loop_Kind);

   function Face_To_HAC is new HAC_Sys.Interfacing.To_HAC_Any_Enum
     (Face_Kind);

   function Continuity_To_HAC is new HAC_Sys.Interfacing.To_HAC_Any_Enum
     (Continuity_Kind);

   function Closure_To_HAC is new HAC_Sys.Interfacing.To_HAC_Any_Enum
     (Closure_Kind);

   function Contour_Orientation_To_HAC is
     new HAC_Sys.Interfacing.To_HAC_Any_Enum
       (Contour_Orientation_Kind);

   function Bool_To_HAC is new HAC_Sys.Interfacing.To_HAC_Any_Enum
     (Bool_Kind);

   function To_Loop_Kind is new HAC_Sys.Interfacing.To_Native_Any_Enum
     (Loop_Kind);

   function To_Face_Kind is new HAC_Sys.Interfacing.To_Native_Any_Enum
     (Face_Kind);

   function To_Continuity_Kind is
     new HAC_Sys.Interfacing.To_Native_Any_Enum
       (Continuity_Kind);

   function To_Closure_Kind is new HAC_Sys.Interfacing.To_Native_Any_Enum
     (Closure_Kind);

   function To_Contour_Orientation_Kind is
     new HAC_Sys.Interfacing.To_Native_Any_Enum
       (Contour_Orientation_Kind);

   function To_Bool_Kind is new HAC_Sys.Interfacing.To_Native_Any_Enum
     (Bool_Kind);

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

   --  Native side of Contour_Continuity: reads the accumulated chain
   --  as segment pairs, each segment given by its two endpoints, and
   --  classifies the chaining of the consecutive segments, the same
   --  way as the contour client operation. The chain is continuous
   --  when the endpoint of each segment equals the start point of the
   --  next.
   procedure Contour_Continuity_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

   --  Native side of Contour_Closure: classifies whether the
   --  accumulated chain forms a closed loop, the kernel Is_Closed.
   procedure Contour_Closure_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

   --  Native side of Contour_Orientation: runs the kernel orientation
   --  classification of the chain, with the pre-checks of the contour
   --  client operation recorded as diagnostics.
   procedure Contour_Orientation_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

   --  Native side of Contour_Self_Intersects: runs the kernel
   --  self-intersection classification of the chain.
   procedure Contour_Self_Intersects_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

   --  Native side of Contour_Valid: runs the kernel geometric
   --  validity of the chain.
   procedure Contour_Valid_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

   --  Native side of Contour_No_Flat_Turns: runs the kernel flat-turn
   --  classification of the chain.
   procedure Contour_No_Flat_Turns_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

   --  Native side of Create_Vertex: creates one vertex referring to
   --  the 2D point in the vertex store of the designated session, and
   --  writes the new handle into the out parameter: the handle is
   --  observable, and a script holds it in a variable to build edges
   --  and traces.
   procedure Create_Vertex_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

   --  Native side of Create_Edge: creates one oriented edge between
   --  the two vertex handles in the edge store of the designated
   --  session, and writes the new edge handle into the out parameter.
   --  Both endpoints must be handles of vertices created in the same
   --  run, and an edge back to the same vertex is rejected, the same
   --  degeneracy diagnostic as the edge client operation.
   procedure Create_Edge_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

end TopoScript_API.Topology;

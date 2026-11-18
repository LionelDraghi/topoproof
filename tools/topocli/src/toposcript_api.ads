-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

--  The TopoScript scripting API (development plan, TopoScript
--  consolidation, Increment 2): the root package declares the
--  execution session shared by the domains and coordinates the
--  callback registration only; the domains live in the child packages
--  (Conversions, Geometry, Topology, Drawing, Output, Session). The
--  operations are registered before the build, so the script sees them
--  under their TopoScript names.

with Ada.Containers.Indefinite_Vectors;
with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;
with Ada.Text_IO;
with HAC_Sys.Builder;
with TopoProof.Numerics;
with TopoProof.Topology.Edges;
with TopoProof.Topology.Edges_3D;
with TopoProof.Topology.Shells;
with TopoProof.Topology.Vertices;
with TopoProof.Topology.Vertices_3D;
with Topodraw;

package TopoScript_API is

   --  The execution session of one script run: it owns the whole
   --  mutable execution state, so no library-level variable carries
   --  state between runs. A limited private type: a session is never
   --  copied. The domain callbacks reach it through the designation
   --  of the Session child package.
   type Script_Session is limited private;

   --  Access to one execution session: the designation crosses the
   --  accessibility rules on purpose, under the lifetime contract
   --  stated with Designate.
   type Session_Access is access all Script_Session;

   --  Register every native operation on the build data, from its
   --  domain.
   procedure Register_All (BD : HAC_Sys.Builder.Build_Data);

   --  The handle of one solid value of the run (DD-006): an index into
   --  the solid values built through the shared 3D stores. The count
   --  of solids of one run is bounded by the edge store capacity: each
   --  value carries at least six edges, and the stores never shrink,
   --  so the bound stays valid for the whole run. Zero is the absent
   --  solid: the result of a rejected primitive, never stored.
   type Solid_Handle_Kind is range 0 .. TopoProof.Topology.Edges_3D.Max_Edges_3D;

   No_Solid : constant Solid_Handle_Kind := 0;

private

   --  One 2D point of the topology chain: in the script chain, a
   --  vertex is identified by its position, so a repeated position
   --  closes on the same vertex.
   type Chain_Point is record
      X, Y : TopoProof.Numerics.Grid_Coordinate;
   end record;

   package Chain_Vectors is new Ada.Containers.Indefinite_Vectors
     (Positive, Chain_Point);

   --  One built face of the shell assembly: the edge handle range of
   --  its boundary.
   type Edge_Group is record
      First, Last : TopoProof.Topology.Edges_3D.Edge_Handle;
   end record;

   package Group_Vectors is new Ada.Containers.Indefinite_Vectors
     (Positive, Edge_Group);

   --  The solid values of the run: one shell assembly each, over the
   --  shared 3D stores (DD-006, increment a). Stored values are never
   --  removed, so a handle keeps its meaning for the whole run.
   use TopoProof.Topology.Shells;
   package Solid_Vectors is new Ada.Containers.Indefinite_Vectors
     (Positive, TopoProof.Topology.Shells.Shell);

   --  The compound pieces of the last Difference (DD-006, decision 4):
   --  solid handles, one stored solid value each.
   package Solid_Handle_Vectors is new Ada.Containers.Vectors
     (Positive, Solid_Handle_Kind);

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
      --  The run-owned output destination (DD-004, decision 8): an
      --  empty path keeps the standard output; otherwise every Put
      --  line goes to the file, created at the first line and closed
      --  at the end of the run.
      Output_Path : Ada.Strings.Unbounded.Unbounded_String;
      Output_File : Ada.Text_IO.File_Type;
      --  The topology chain: it lives for the whole script run.
      --  Add_Point always appends, and Make_Loop and Make_Face
      --  classify the chain as it stands at the call without ever
      --  clearing it, so the same chain can be classified first as a
      --  loop, then as a face boundary.
      Chain : Chain_Vectors.Vector;
      --  The construction stores: one vertex store and one edge store
      --  per run, at the kernel maximum capacities, so the kernel
      --  preconditions of Create hold structurally for any script.
      --  Create_Vertex and Create_Edge build the topology of the run
      --  through them, and the Put_Vertex and Put_Edge traces read the
      --  handles back. Handles stay valid for the whole run: stored
      --  entities are never removed.
      Vertices : TopoProof.Topology.Vertices.Vertex_Store
        (TopoProof.Topology.Vertices.Vertex_Count_Range
           (TopoProof.Topology.Vertices.Max_Vertices));
      Links : TopoProof.Topology.Edges.Edge_Store
        (TopoProof.Topology.Edges.Edge_Count_Range
           (TopoProof.Topology.Edges.Max_Edges));
      --  The three-dimensional construction stores (DD-005, increment
      --  a): the same discipline as the 2D stores, over Point_3D.
      --  Create_Vertex_3D and Create_Edge_3D build the planar face
      --  boundaries through them, and Make_Face_3D classifies the
      --  created edges, in creation order, as one face boundary.
      Vertices_3D : TopoProof.Topology.Vertices_3D.Vertex_Store
        (TopoProof.Topology.Vertices_3D.Vertex_Count_Range
           (TopoProof.Topology.Vertices_3D.Max_Vertices_3D));
      Links_3D : TopoProof.Topology.Edges_3D.Edge_Store
        (TopoProof.Topology.Edges_3D.Edge_Count_Range
           (TopoProof.Topology.Edges_3D.Max_Edges_3D));
      --  The shell assembly of the run (DD-005, increment b): the
      --  built faces, as the edge handle ranges of their boundaries,
      --  in build order, and the first edge handle of the face being
      --  built. Make_Face_3D consumes the edges created since the
      --  previous call: a planar boundary joins the assembly, a
      --  rejected one is discarded; Make_Shell_3D classifies the
      --  assembly as it stands.
      Groups     : Group_Vectors.Vector;
      Face_Start : Natural := 1;
      --  The solid values of the run (DD-006, increment a): one shell
      --  assembly each, over the shared 3D stores. Stored values are
      --  never removed, so a handle keeps its meaning for the whole
      --  run, like every handle of the model.
      Solids : Solid_Vectors.Vector;
      --  The pieces of the last Difference (DD-006, decision 4): solid
      --  handles, one stored solid value each, indexed from 1.
      Compound : Solid_Handle_Vectors.Vector;
   end record;

end TopoScript_API;

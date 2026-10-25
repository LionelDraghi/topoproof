-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with Ada.Strings.Unbounded;
use Ada.Strings.Unbounded;

with TopoProof.Topology.Edges;
with TopoProof.Topology.Edges_3D;
with TopoProof.Topology.Vertices;
with TopoProof.Topology.Vertices_3D;

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
      if Ada.Text_IO.Is_Open (Session.Output_File) then
         Ada.Text_IO.Close (Session.Output_File);
      end if;
      Session.Output_Path := Null_Unbounded_String;
      Session.Chain.Clear;
      --  The construction stores restart empty: handles number the
      --  creations of the run, so a fresh run numbers from 1 again.
      Session.Vertices :=
        (Capacity =>
           TopoProof.Topology.Vertices.Vertex_Count_Range
             (TopoProof.Topology.Vertices.Max_Vertices),
         others => <>);
      Session.Links :=
        (Capacity =>
           TopoProof.Topology.Edges.Edge_Count_Range
             (TopoProof.Topology.Edges.Max_Edges),
         others => <>);
      --  The three-dimensional stores restart empty, like the 2D ones.
      Session.Vertices_3D :=
        (Capacity =>
           TopoProof.Topology.Vertices_3D.Vertex_Count_Range
             (TopoProof.Topology.Vertices_3D.Max_Vertices_3D),
         others => <>);
      Session.Links_3D :=
        (Capacity =>
           TopoProof.Topology.Edges_3D.Edge_Count_Range
             (TopoProof.Topology.Edges_3D.Max_Edges_3D),
         others => <>);
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

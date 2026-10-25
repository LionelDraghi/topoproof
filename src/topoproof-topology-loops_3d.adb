-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

package body TopoProof.Topology.Loops_3D
   with SPARK_Mode
is

   --  The classification mirrors the definition order of the status
   --  type: every check runs with the previous ones already known, so
   --  the precondition of each predicate is discharged by the branch
   --  taken before it.
   function Classify_Loop
      (E     : Edges_3D.Edge_Store;
       V     : Vertices_3D.Vertex_Store;
       Chain : Edge_Handle_Array) return Loop_Validity
   is
   begin
      if not Is_Orphan_Free (E, Chain) then
         return Orphan_Edge;

      elsif not Has_Existing_Endpoints (E, V, Chain) then
         return Missing_Endpoint;

      elsif not Is_Closed_Chain (E, Chain) then
         return Open_Chain;

      elsif not Is_Connected_Chain (E, Chain) then
         return Disconnected_Chain;

      elsif not Has_No_Degenerate_Support (E, V, Chain) then
         return Degenerate_Support;

      else
         return Valid_Loop;

      end if;
   end Classify_Loop;

   --  The chain is known valid, so it is installed as it is.
   function Make_Loop
      (E     : Edges_3D.Edge_Store;
       V     : Vertices_3D.Vertex_Store;
       Chain : Edge_Handle_Array) return Loop_3D
   is

   begin
      return (Length => Chain'Length, Edges => Chain);
   end Make_Loop;

end TopoProof.Topology.Loops_3D;

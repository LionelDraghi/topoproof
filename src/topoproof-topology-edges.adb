-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

package body TopoProof.Topology.Edges
   with SPARK_Mode
is

   --  Creation appends the new edge: the next handle is Count + 1, which
   --  the precondition keeps inside the store, then the pair lands at
   --  that index. The returned handle is the index of the new pair, and
   --  the indices of the previous edges are untouched, so their
   --  references keep their meaning.
   procedure Create
      (Store        : in out Edge_Store;
       Vertex_Store :        Vertices.Vertex_Store;
       A, B         :        Vertices.Vertex_Handle;
       E            :    out Edge_Handle)
   is
      pragma Unreferenced (Vertex_Store);

   begin
      Store.Count := Store.Count + 1;
      Store.Pairs (Store.Count) := (From_Vertex => A, To_Vertex => B);
      E := Store.Count;
   end Create;

end TopoProof.Topology.Edges;

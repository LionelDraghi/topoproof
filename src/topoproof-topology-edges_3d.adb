-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

package body TopoProof.Topology.Edges_3D
   with SPARK_Mode
is
   --  Creation appends the new edge. The pair is written before the
   --  count is incremented: the type predicate constrains only the
   --  stored edges, 1 .. Count, so writing the pair at Count + 1 keeps
   --  it, and incrementing the count then covers a pair already known
   --  non-degenerate, instead of exposing arbitrary content to the
   --  predicate for an instant. The returned handle is the index of
   --  the new pair, and the indices of the previous edges are
   --  untouched, so their references keep their meaning.
   procedure Create
      (Store        : in out Edge_Store;
       Vertex_Store :        Vertices_3D.Vertex_Store;
       A, B         :        Vertices_3D.Vertex_Handle;
       E            :    out Edge_Handle)
   is
      pragma Unreferenced (Vertex_Store);

   begin
      Store.Pairs (Store.Count + 1) := (From_Vertex => A, To_Vertex => B);
      Store.Count := Store.Count + 1;
      E := Store.Count;
   end Create;

end TopoProof.Topology.Edges_3D;

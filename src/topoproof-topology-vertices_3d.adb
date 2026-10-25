-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

package body TopoProof.Topology.Vertices_3D
   with SPARK_Mode
is
   --  Creation appends the new vertex: the next handle is Count + 1, which
   --  the precondition keeps inside the store, then the point lands at
   --  that index. The returned handle is the index of the new point, and
   --  the indices of the previous vertices are untouched, so their
   --  references keep their meaning.
   procedure Create
      (Store : in out Vertex_Store;
       P     :        Points.Point_3D;
       V     :    out Vertex_Handle)
   is
   begin
      Store.Count := Store.Count + 1;
      Store.Points (Store.Count) := P;
      V := Store.Count;
   end Create;

end TopoProof.Topology.Vertices_3D;

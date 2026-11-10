-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

package body TopoProof.Topology.Vertices
   with SPARK_Mode
is

   --  Creation appends the new vertex: the next handle is Count + 1, which
   --  the precondition keeps inside the store, then the point lands at
   --  that index. The returned handle is the index of the new point, and
   --  the indices of the previous vertices are untouched, so their
   --  references keep their meaning.
   procedure Create (Store : in out Vertex_Store; P : Points.Point_2D; V : out Vertex_Handle) is
   begin
      Store.Count := Store.Count + 1;
      Store.Points (Store.Count) := P;
      V := Store.Count;
   end Create;

   --  The move replaces the point of one stored vertex: the handle indexes
   --  the point (the precondition entails Contains, hence V <= Count), the
   --  translated point is written at that index, and nothing else changes.
   --  The extended-component intermediates are total on their domain, and
   --  the precondition carries the representability, so the conversions
   --  back to Grid_Coordinate are in range.
   procedure Move
      (Store     : in out Vertex_Store;
       V         :        Vertex_Handle;
       DX, DY    :        Numerics.Vector_Component;
       New_Point :    out Points.Point_2D)
   is
   begin
      Store.Points (V) :=
         (X =>
             Numerics.Grid_Coordinate
                (Numerics.Extended_Component (Store.Points (V).X)
                   + Numerics.Extended_Component (DX)),
          Y =>
             Numerics.Grid_Coordinate
                (Numerics.Extended_Component (Store.Points (V).Y)
                   + Numerics.Extended_Component (DY)));
      New_Point := Store.Points (V);
   end Move;

end TopoProof.Topology.Vertices;

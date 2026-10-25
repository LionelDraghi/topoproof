-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with TopoProof.Geometry.Points;
with TopoProof.Topology.Edges_3D;
with TopoProof.Topology.Loops_3D;
with TopoProof.Topology.Vertices_3D;
use TopoProof.Geometry;
use type TopoProof.Geometry.Points.Point_3D;
use type TopoProof.Topology.Loops_3D.Loop_Validity;

package TopoProof.Topology.Shells
   with Pure, SPARK_Mode
is
   --  The largest number of faces an assembly may carry. Every face of
   --  an assembly carries at least one edge use - an empty chain builds
   --  no face, the face classification rejects it - so an assembly has
   --  no more faces than its edge chain has uses. Like every length of
   --  the topology layer, face counts index and compare only, never
   --  multiply.
   Max_Shell_Faces : constant := Edges_3D.Max_Edges_3D;

   subtype Shell_Face_Count is Natural range 0 .. Max_Shell_Faces;

   --  The last flattened position of one face boundary. Every face
   --  carries at least one use, and no boundary reaches beyond the
   --  edge chain of the largest loop.
   subtype Face_End is Positive range 1 .. Loops_3D.Max_Loop_Length;

   type Face_End_Array is array (Positive range <>) of Face_End;

   --  An assembly of face boundaries over the shared edge and vertex
   --  stores (DD-005, decision 1): the face boundaries in order,
   --  flattened into one edge chain, with the last position of every
   --  boundary. The boundary of the face K is the slice of the chain
   --  from Boundary_First (S, K) to Face_Ends (K). An assembly is a
   --  value, not a stored entity: its meaning is relative to the
   --  stores its edges come from, which every predicate takes as
   --  parameters. The two discriminants have defaults so that an
   --  assembly is a mutable value, built face by face; unlike a store
   --  capacity, an assembly length is not an identity, so changing it
   --  by whole-record assignment breaks no reference.
   type Shell
      (Face_Count : Shell_Face_Count := 0;
       Edge_Total : Loops_3D.Loop_Length_Range := 0)
   is record
      Face_Ends : Face_End_Array (1 .. Face_Count);
      Boundary  : Loops_3D.Edge_Handle_Array (1 .. Edge_Total);
   end record
   with
      Dynamic_Predicate =>
         (if Face_Count = 0
          then Edge_Total = 0
          else
             Face_Ends (Face_Count) = Edge_Total
             and then (for all K in 1 .. Face_Count - 1 => Face_Ends (K) < Face_Ends (K + 1))
             and then (for all K in 1 .. Face_Count => Face_Ends (K) <= Edge_Total));

   --  The first flattened position of the boundary K: one past the end
   --  of the boundary before it. The faces are ascending and nonempty,
   --  so the first position of K is at most its end.
   function Boundary_First (S : Shell; K : Positive) return Positive
   is (if K = 1 then 1 else S.Face_Ends (K - 1) + 1)
   with Pre => K <= S.Face_Count;

   --  The exact support of one flattened use: the starting point and
   --  the arrival point of its edge, in traversal order. The pairing
   --  of the shell is decided on these positions: every directed
   --  support of every face boundary must be matched by exactly one
   --  opposite support of another use, and no two uses may carry the
   --  same directed support. Faces list their own oriented edges, so a
   --  shared geometric segment appears as two directed edges, one per
   --  incident face; two faces carrying one directed support in the
   --  same direction is the signature of an inverted face.
   function Use_From
      (E     : Edges_3D.Edge_Store;
       V     : Vertices_3D.Vertex_Store;
       Chain : Loops_3D.Edge_Handle_Array;
       U     : Positive) return Points.Point_3D
   is (Vertices_3D.Point_Of (V, Edges_3D.Endpoints (E, Chain (U)).From_Vertex))
   with
      Pre =>
         U in Chain'Range
         and then Loops_3D.Is_Orphan_Free (E, Chain)
         and then Loops_3D.Has_Existing_Endpoints (E, V, Chain);

   function Use_To
      (E     : Edges_3D.Edge_Store;
       V     : Vertices_3D.Vertex_Store;
       Chain : Loops_3D.Edge_Handle_Array;
       U     : Positive) return Points.Point_3D
   is (Vertices_3D.Point_Of (V, Edges_3D.Endpoints (E, Chain (U)).To_Vertex))
   with
      Pre =>
         U in Chain'Range
         and then Loops_3D.Is_Orphan_Free (E, Chain)
         and then Loops_3D.Has_Existing_Endpoints (E, V, Chain);

   --  The number of uses from the position From on whose directed
   --  support is the same as the one of the use U: same starting point
   --  and same arrival point. The use U itself is not counted. The
   --  count is bounded by the number of visited positions.
   function Same_Support_Count
      (E       : Edges_3D.Edge_Store;
       V       : Vertices_3D.Vertex_Store;
       Chain   : Loops_3D.Edge_Handle_Array;
       U, From : Positive) return Natural
   is (if From > Chain'Last
       then 0
       elsif From = U
       then Same_Support_Count (E, V, Chain, U, From + 1)
       elsif Use_From (E, V, Chain, From) = Use_From (E, V, Chain, U)
          and then Use_To (E, V, Chain, From) = Use_To (E, V, Chain, U)
       then 1 + Same_Support_Count (E, V, Chain, U, From + 1)
       else Same_Support_Count (E, V, Chain, U, From + 1))
   with
      Pre                =>
         U in Chain'Range
         and then From >= Chain'First
         and then Chain'Last <= Loops_3D.Max_Loop_Length
         and then Loops_3D.Is_Orphan_Free (E, Chain)
         and then Loops_3D.Has_Existing_Endpoints (E, V, Chain),
      Post               =>
         (if From <= Chain'Last
          then Same_Support_Count'Result <= Chain'Last - From + 1
          else Same_Support_Count'Result = 0),
      Subprogram_Variant => (Decreases => Chain'Last - From + 1);

   --  The number of uses from the position From on whose directed
   --  support is the opposite of the one of the use U: the arrival
   --  point of one is the starting point of the other, and the other
   --  way around. The count is bounded by the number of visited
   --  positions.
   function Opposite_Support_Count
      (E       : Edges_3D.Edge_Store;
       V       : Vertices_3D.Vertex_Store;
       Chain   : Loops_3D.Edge_Handle_Array;
       U, From : Positive) return Natural
   is (if From > Chain'Last
       then 0
       elsif Use_To (E, V, Chain, From) = Use_From (E, V, Chain, U)
          and then Use_From (E, V, Chain, From) = Use_To (E, V, Chain, U)
       then 1 + Opposite_Support_Count (E, V, Chain, U, From + 1)
       else Opposite_Support_Count (E, V, Chain, U, From + 1))
   with
      Pre                =>
         U in Chain'Range
         and then From >= Chain'First
         and then Chain'Last <= Loops_3D.Max_Loop_Length
         and then Loops_3D.Is_Orphan_Free (E, Chain)
         and then Loops_3D.Has_Existing_Endpoints (E, V, Chain),
      Post               =>
         (if From <= Chain'Last
          then Opposite_Support_Count'Result <= Chain'Last - From + 1
          else Opposite_Support_Count'Result = 0),
      Subprogram_Variant => (Decreases => Chain'Last - From + 1);

   --  The boundary K of the assembly is a valid loop: its slice of the
   --  edge chain closes, is connected, and carries no orphan edge, no
   --  missing endpoint and no degenerate support.
   function Is_Valid_Boundary
      (E : Edges_3D.Edge_Store; V : Vertices_3D.Vertex_Store; S : Shell; K : Positive)
       return Boolean
   is (Loops_3D.Classify_Loop (E, V, S.Boundary (Boundary_First (S, K) .. S.Face_Ends (K)))
       = Loops_3D.Valid_Loop)
   with Pre => K <= S.Face_Count and then S.Boundary'First = 1;

   --  The exact classification of a shell assembly, decided in this
   --  order and without tolerance: the shell is closed when every face
   --  boundary is a valid loop and every directed support is carried
   --  by exactly one use, matched by exactly one opposite support and
   --  no same-support use. The first violated property in the
   --  documented order is reported: an invalid boundary, a support
   --  used more than twice (a non-manifold assembly), two uses of one
   --  support in the same direction (the signature of an inverted
   --  face on an otherwise closed assembly), or a support carried by
   --  one use only (a free edge, the signature of a missing face).
   type Shell_Validity is
      (Closed_Shell, Invalid_Boundary, Overused_Edge, Misaligned_Edge, Free_Edge);

   function Classify_Shell
      (E : Edges_3D.Edge_Store; V : Vertices_3D.Vertex_Store; S : Shell) return Shell_Validity
   with
      Pre  =>
         S.Boundary'First = 1
         and then Loops_3D.Is_Orphan_Free (E, S.Boundary)
         and then Loops_3D.Has_Existing_Endpoints (E, V, S.Boundary),
      Post =>
         (case Classify_Shell'Result is
             when Closed_Shell     =>
                (for all K in 1 .. S.Face_Count => Is_Valid_Boundary (E, V, S, K))
                and then (for all U in 1 .. S.Edge_Total =>
                             Same_Support_Count (E, V, S.Boundary, U, 1) = 0
                             and then Opposite_Support_Count (E, V, S.Boundary, U, 1) = 1),
             when Invalid_Boundary =>
                (for some K in 1 .. S.Face_Count => not Is_Valid_Boundary (E, V, S, K)),
             when Overused_Edge    =>
                (for all K in 1 .. S.Face_Count => Is_Valid_Boundary (E, V, S, K))
                and then (for some U in 1 .. S.Edge_Total =>
                             Same_Support_Count (E, V, S.Boundary, U, 1)
                             + Opposite_Support_Count (E, V, S.Boundary, U, 1)
                             >= 2),
             when Misaligned_Edge  =>
                (for all K in 1 .. S.Face_Count => Is_Valid_Boundary (E, V, S, K))
                and then (for all U in 1 .. S.Edge_Total =>
                             Same_Support_Count (E, V, S.Boundary, U, 1)
                             + Opposite_Support_Count (E, V, S.Boundary, U, 1)
                             <= 1)
                and then (for some U in 1 .. S.Edge_Total =>
                             Same_Support_Count (E, V, S.Boundary, U, 1) = 1
                             and then Opposite_Support_Count (E, V, S.Boundary, U, 1) = 0),
             when Free_Edge        =>
                (for all K in 1 .. S.Face_Count => Is_Valid_Boundary (E, V, S, K))
                and then (for all U in 1 .. S.Edge_Total =>
                             Same_Support_Count (E, V, S.Boundary, U, 1)
                             + Opposite_Support_Count (E, V, S.Boundary, U, 1)
                             <= 1)
                and then (for all U in 1 .. S.Edge_Total =>
                             Same_Support_Count (E, V, S.Boundary, U, 1) /= 1
                             or else Opposite_Support_Count (E, V, S.Boundary, U, 1) /= 0)
                and then (for some U in 1 .. S.Edge_Total =>
                             Same_Support_Count (E, V, S.Boundary, U, 1) = 0
                             and then Opposite_Support_Count (E, V, S.Boundary, U, 1) = 0));

end TopoProof.Topology.Shells;

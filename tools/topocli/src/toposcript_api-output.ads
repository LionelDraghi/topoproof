-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

--  The output domain of the scripting API (development plan,
--  TopoScript consolidation, Increment 2, and the single front-end,
--  Increments 1 and 5): the canonical textual results, one
--  implementation per public representation, and the run-owned output
--  destination (DD-004, decision 8).

with HAC_Sys.Interfacing;
with TopoProof.Geometry.Intersections;
with TopoProof.Geometry.Orientations;
with TopoProof.Geometry.Points;
with TopoProof.Geometry.Vectors;
with TopoProof.Topology.Edges;
with TopoProof.Topology.Vertices;
with TopoScript_API.Geometry;
with TopoScript_API.Topology;

package TopoScript_API.Output is

   --  The canonical image of a 3D point: `point X Y Z`, the exact text
   --  of the topocli commands.
   function Image (P : TopoProof.Geometry.Points.Point_3D) return String;

   --  The canonical image of a 3D vector: `vector DX DY DZ`.
   function Image
     (V : TopoProof.Geometry.Vectors.Vector_3D) return String;

   --  The canonical image of an exact dot product: `dot D`.
   function Image (D : TopoProof.Numerics.Dot_Product) return String;

   --  The canonical image of an exact cross vector: `cross DX DY DZ`.
   function Image (V : TopoProof.Geometry.Vectors.Cross_Vector_3D) return String;

   --  The valid results of the loop and face classifications.
   subtype Loop_Result is Topology.Loop_Kind
     range Topology.Counter_Clockwise .. Topology.Degenerate;

   subtype Face_Result is Topology.Face_Kind
     range Topology.Face_Counter_Clockwise .. Topology.Face_Clockwise;

   --  The canonical image of a loop result: `loop closed ...`.
   function Image (K : Loop_Result) return String;

   --  The canonical image of a face result: `face ...`.
   function Image (K : Face_Result) return String;

   --  The canonical image of an equality result: `equal true` or
   --  `equal false`.
   function Image (K : Geometry.Equal_Kind) return String;

   --  The canonical image of a continuity result:
   --  `continuity continuous` or `continuity discontinuous`.
   function Image (K : Topology.Continuity_Kind) return String;

   --  The canonical image of a closure result: `closure closed` or
   --  `closure open`.
   function Image (K : Topology.Closure_Kind) return String;

   --  The canonical image of a contour orientation result:
   --  `orientation counter_clockwise`, `orientation clockwise` or
   --  `orientation degenerate`.
   function Image (K : Topology.Contour_Orientation_Kind) return String;

   --  The canonical image of a contour boolean: `true` or `false`.
   function Image (K : Topology.Bool_Kind) return String;

   --  The canonical image of a vertex trace: `vertex H point X Y`,
   --  the handle and the point of one created vertex.
   function Image
     (H : TopoProof.Topology.Vertices.Vertex_Handle;
      P : TopoProof.Geometry.Points.Point_2D) return String;

   --  The canonical image of an edge trace: `edge E vertex A vertex
   --  B`, the handle and the two endpoint handles of one created edge.
   function Image
     (E     : TopoProof.Topology.Edges.Edge_Handle;
      A, B  : TopoProof.Topology.Vertices.Vertex_Handle)
      return String;

   --  The canonical image of an orientation result:
   --  `orientation counter_clockwise`, `orientation clockwise` or
   --  `orientation collinear`.
   function Image
     (K : TopoProof.Geometry.Orientations.Orientation_Kind) return String;

   --  The canonical image of an intersection result: the kind line,
   --  with the common position of a point intersection, or the two
   --  boundaries of an overlap. The coordinates are the ones the kind
   --  reports: PX, PY for a point intersection, PX, PY, QX, QY for an
   --  overlap.
   function Image
     (K            : TopoProof.Geometry.Intersections.Intersection_Kind;
      PX, PY, QX, QY : TopoProof.Numerics.Grid_Coordinate) return String;

   --  The run-owned output destination: the Put operations write
   --  through it, standard output by default.

   --  Record the output file of the run: every Put line goes to it,
   --  instead of the standard output. The file is created at the
   --  first line and closed by Close_Output.
   procedure Set_Output_Path (Path : String);

   --  Write one canonical line to the destination of the run.
   procedure Put_Line (S : String);

   --  Close the output file of the run, if one was opened.
   procedure Close_Output;

   --  Native side of Put: writes the canonical image of the point,
   --  the same one as the topocli client.
   procedure Put_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

   --  Native side of Put_Vector: writes the canonical image of the
   --  vector.
   procedure Put_Vector_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

   --  Native side of Put_Dot: writes the canonical image of the
   --  exact dot product.
   procedure Put_Dot_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

   --  Native side of Put_Cross_Vector: writes the canonical image of
   --  the cross vector.
   procedure Put_Cross_Vector_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

   --  Native side of Put_Equal: writes the canonical image of the
   --  equality result.
   procedure Put_Equal_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

   --  Native side of Put_Continuity: writes the canonical image of
   --  the continuity result.
   procedure Put_Continuity_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

   --  Native side of Put_Closure: writes the canonical image of the
   --  closure result.
   procedure Put_Closure_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

   --  Native side of Put_Contour_Orientation: writes the canonical
   --  image of the contour orientation result.
   procedure Put_Contour_Orientation_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

   --  Native side of Put_Bool: writes the canonical image of the
   --  contour boolean.
   procedure Put_Bool_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

   --  Native side of Put_Vertex: writes the canonical vertex trace of
   --  the handle, or records the diagnostic of an unknown handle.
   procedure Put_Vertex_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

   --  Native side of Put_Edge: writes the canonical edge trace of the
   --  handle, or records the diagnostic of an unknown handle.
   procedure Put_Edge_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

   --  Native side of Put_Orientation: writes the canonical image of
   --  the orientation result.
   procedure Put_Orientation_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

   --  Native side of Put_Intersection: writes the canonical image of
   --  the intersection result, kind and reported positions.
   procedure Put_Intersection_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

   --  Native side of Put_Loop: writes `loop closed ...`, or records
   --  the rejection diagnostic of the loop kind.
   procedure Put_Loop_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

   --  Native side of Put_Face: writes `face ...`, or records the
   --  rejection diagnostic of the face kind.
   procedure Put_Face_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

end TopoScript_API.Output;

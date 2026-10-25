-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

--  The client diagnostics of the rejected chain classifications: one
--  message per classification, owned here so that every front-end (the
--  command line and TopoScript) reports the same rejection for the same
--  chain.

with TopoProof.Topology.Faces;
with TopoProof.Topology.Faces_3D;
with TopoProof.Topology.Loops;
with TopoProof.Topology.Loops_3D;
with TopoProof.Topology.Vertices_3D;

package TopoDiagnostics is

   --  A rejected loop classification: every classification but the
   --  valid one.
   subtype Rejected_Loop is TopoProof.Topology.Loops.Loop_Validity
      range TopoProof.Topology.Loops.Orphan_Edge
         ..  TopoProof.Topology.Loops.Degenerate_Support;

   --  A rejected loop classification of the three-dimensional
   --  structure: the same classifications over the 3D stores.
   subtype Rejected_Loop_3D is TopoProof.Topology.Loops_3D.Loop_Validity
      range TopoProof.Topology.Loops_3D.Orphan_Edge
         ..  TopoProof.Topology.Loops_3D.Degenerate_Support;

   --  A rejected face classification: every classification but the
   --  valid one.
   subtype Rejected_Face is TopoProof.Topology.Faces.Face_Validity
      range TopoProof.Topology.Faces.Invalid_Boundary
         ..  TopoProof.Topology.Faces.Degenerate_Boundary;

   --  A rejected planar face classification: every classification but
   --  the valid one.
   subtype Rejected_Face_3D is TopoProof.Topology.Faces_3D.Face_Validity
      range TopoProof.Topology.Faces_3D.Invalid_Boundary
         ..  TopoProof.Topology.Faces_3D.Non_Planar_Boundary;

   --  The client diagnostic of a rejected loop classification.
   function Loop_Diagnostic (Status : Rejected_Loop) return String;

   --  The client diagnostic of a rejected loop classification of the
   --  three-dimensional structure.
   function Loop_3D_Diagnostic (Status : Rejected_Loop_3D) return String;

   --  The client diagnostic of an open chain of the three-dimensional
   --  structure, naming the two unlinked vertices: the vertex the
   --  chain ends at, and the starting vertex it should return to.
   function Open_Loop_3D_Diagnostic
      (Chain_End   : TopoProof.Topology.Vertices_3D.Vertex_Handle;
       Chain_Start : TopoProof.Topology.Vertices_3D.Vertex_Handle)
      return String;

   --  The client diagnostic of a rejected face classification.
   function Face_Diagnostic (Status : Rejected_Face) return String;

   --  The client diagnostic of a rejected planar face classification.
   function Face_3D_Diagnostic (Status : Rejected_Face_3D) return String;

   --  The client diagnostic of a script coordinate outside the grid:
   --  the conversion layer rejects it on every operation reading a
   --  position from the script.
   Outside_Grid_Diagnostic : constant String :=
     "error: coordinate outside the grid";

   --  The client diagnostic of a drawing operation with no open
   --  image: the image must be opened first.
   No_Image_Diagnostic : constant String := "error: no open image";

end TopoDiagnostics;

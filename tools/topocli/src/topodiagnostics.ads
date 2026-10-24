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
with TopoProof.Topology.Loops;

package TopoDiagnostics is

   --  A rejected loop classification: every classification but the
   --  valid one.
   subtype Rejected_Loop is TopoProof.Topology.Loops.Loop_Validity
      range TopoProof.Topology.Loops.Orphan_Edge
         ..  TopoProof.Topology.Loops.Degenerate_Support;

   --  A rejected face classification: every classification but the
   --  valid one.
   subtype Rejected_Face is TopoProof.Topology.Faces.Face_Validity
      range TopoProof.Topology.Faces.Invalid_Boundary
         ..  TopoProof.Topology.Faces.Degenerate_Boundary;

   --  The client diagnostic of a rejected loop classification.
   function Loop_Diagnostic (Status : Rejected_Loop) return String;

   --  The client diagnostic of a rejected face classification.
   function Face_Diagnostic (Status : Rejected_Face) return String;

   --  The client diagnostic of a script coordinate outside the grid:
   --  the conversion layer rejects it on every operation reading a
   --  position from the script.
   Outside_Grid_Diagnostic : constant String :=
     "error: coordinate outside the grid";

   --  The client diagnostic of a drawing operation with no open
   --  image: the image must be opened first.
   No_Image_Diagnostic : constant String := "error: no open image";

end TopoDiagnostics;

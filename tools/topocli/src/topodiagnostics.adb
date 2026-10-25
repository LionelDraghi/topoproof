-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with Ada.Strings.Fixed;

package body TopoDiagnostics is

   use TopoProof.Topology.Faces;
   use TopoProof.Topology.Loops;

   function Loop_Diagnostic (Status : Rejected_Loop) return String is
   begin
      case Status is
         when Orphan_Edge =>
            return "error: orphan edge";
         when Missing_Endpoint =>
            return "error: missing endpoint";
         when Open_Chain =>
            return "error: open loop";
         when Disconnected_Chain =>
            return "error: disconnected chain";
         when Degenerate_Support =>
            return "error: degenerate edge support";
      end case;
   end Loop_Diagnostic;

   function Face_Diagnostic (Status : Rejected_Face) return String is
   begin
      case Status is
         when Invalid_Boundary =>
            return "error: invalid loop";
         when Degenerate_Boundary =>
            return "error: degenerate face boundary";
      end case;
   end Face_Diagnostic;

   function Face_3D_Diagnostic (Status : Rejected_Face_3D) return String is
   begin
      case Status is
         when TopoProof.Topology.Faces_3D.Invalid_Boundary =>
            return "error: invalid loop";
         when TopoProof.Topology.Faces_3D.Collinear_Boundary =>
            return "error: collinear face boundary";
         when TopoProof.Topology.Faces_3D.Non_Planar_Boundary =>
            return "error: non-planar face boundary";
      end case;
   end Face_3D_Diagnostic;

   function Loop_3D_Diagnostic (Status : Rejected_Loop_3D) return String is
   begin
      case Status is
         when TopoProof.Topology.Loops_3D.Orphan_Edge =>
            return "error: orphan edge";
         when TopoProof.Topology.Loops_3D.Missing_Endpoint =>
            return "error: missing endpoint";
         when TopoProof.Topology.Loops_3D.Open_Chain =>
            return "error: open loop";
         when TopoProof.Topology.Loops_3D.Disconnected_Chain =>
            return "error: disconnected chain";
         when TopoProof.Topology.Loops_3D.Degenerate_Support =>
            return "error: degenerate edge support";
      end case;
   end Loop_3D_Diagnostic;

   function Open_Loop_3D_Diagnostic
      (Chain_End   : TopoProof.Topology.Vertices_3D.Vertex_Handle;
       Chain_Start : TopoProof.Topology.Vertices_3D.Vertex_Handle)
      return String
   is
      use Ada.Strings.Fixed;

   begin
      return "error: open loop, vertex "
             & Trim (Chain_End'Image, Ada.Strings.Both)
             & " is not linked back to vertex "
             & Trim (Chain_Start'Image, Ada.Strings.Both);
   end Open_Loop_3D_Diagnostic;

end TopoDiagnostics;

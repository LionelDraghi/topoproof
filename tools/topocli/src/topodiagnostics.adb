-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

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

end TopoDiagnostics;

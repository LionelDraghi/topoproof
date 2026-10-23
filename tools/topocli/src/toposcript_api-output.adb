-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with Ada.Text_IO;
use Ada.Text_IO;

with TopoDiagnostics;
with TopoScript_API.Conversions;
with TopoScript_API.Session;
with TopoScript_API.Topology;

with TopoProof.Geometry.Points;
with TopoProof.Numerics;
with TopoProof.Topology.Faces;
with TopoProof.Topology.Loops;

package body TopoScript_API.Output is

   procedure Put_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      PX, PY, PZ : Long_Long_Integer;
   begin
      PX := Conversions.To_Long (Data (1));
      PY := Conversions.To_Long (Data (2));
      PZ := Conversions.To_Long (Data (3));
      if not Conversions.Grid_In_Range (PX)
        or else not Conversions.Grid_In_Range (PY)
        or else not Conversions.Grid_In_Range (PZ)
      then
         Session.Record_Failure ("error: coordinate outside the grid");
         return;
      end if;

      declare
         P : constant TopoProof.Geometry.Points.Point_3D :=
           (X => TopoProof.Numerics.Grid_Coordinate (PX),
            Y => TopoProof.Numerics.Grid_Coordinate (PY),
            Z => TopoProof.Numerics.Grid_Coordinate (PZ));
      begin
         Put ("point ");
         Conversions.Grid_IO.Put (P.X, Width => 0);
         Put (" ");
         Conversions.Grid_IO.Put (P.Y, Width => 0);
         Put (" ");
         Conversions.Grid_IO.Put (P.Z, Width => 0);
         New_Line;
      end;
   end Put_Native;

   procedure Put_Loop_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
   begin
      case Topology.To_Loop_Kind (Data (1)) is
         when Topology.Counter_Clockwise =>
            Put_Line ("loop closed counter_clockwise");
         when Topology.Clockwise =>
            Put_Line ("loop closed clockwise");
         when Topology.Degenerate =>
            Put_Line ("loop closed degenerate");
         when Topology.Open_Chain =>
            Session.Record_Failure
              (TopoDiagnostics.Loop_Diagnostic
                 (TopoProof.Topology.Loops.Open_Chain));
         when Topology.Orphan_Edge =>
            Session.Record_Failure
              (TopoDiagnostics.Loop_Diagnostic
                 (TopoProof.Topology.Loops.Orphan_Edge));
         when Topology.Missing_Endpoint =>
            Session.Record_Failure
              (TopoDiagnostics.Loop_Diagnostic
                 (TopoProof.Topology.Loops.Missing_Endpoint));
         when Topology.Disconnected_Chain =>
            Session.Record_Failure
              (TopoDiagnostics.Loop_Diagnostic
                 (TopoProof.Topology.Loops.Disconnected_Chain));
         when Topology.Degenerate_Support =>
            Session.Record_Failure
              (TopoDiagnostics.Loop_Diagnostic
                 (TopoProof.Topology.Loops.Degenerate_Support));
      end case;
   end Put_Loop_Native;

   procedure Put_Face_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
   begin
      case Topology.To_Face_Kind (Data (1)) is
         when Topology.Face_Counter_Clockwise =>
            Put_Line ("face counter_clockwise");
         when Topology.Face_Clockwise =>
            Put_Line ("face clockwise");
         when Topology.Face_Degenerate_Boundary =>
            Session.Record_Failure
              (TopoDiagnostics.Face_Diagnostic
                 (TopoProof.Topology.Faces.Degenerate_Boundary));
         when Topology.Face_Invalid_Boundary =>
            Session.Record_Failure
              (TopoDiagnostics.Face_Diagnostic
                 (TopoProof.Topology.Faces.Invalid_Boundary));
      end case;
   end Put_Face_Native;

end TopoScript_API.Output;

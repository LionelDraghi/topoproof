-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
use Ada.Strings.Unbounded;
with Ada.Text_IO;

with TopoDiagnostics;
with TopoScript_API.Conversions;
with TopoScript_API.Session;

with TopoProof.Numerics;
with TopoProof.Topology.Faces;
with TopoProof.Topology.Loops;

package body TopoScript_API.Output is

   --  The trimmed decimal image of one grid coordinate: the canonical
   --  form of every coordinate in a result line.
   function Img (C : TopoProof.Numerics.Grid_Coordinate) return String is
     (Ada.Strings.Fixed.Trim (C'Image, Ada.Strings.Both));

   function Image (P : TopoProof.Geometry.Points.Point_3D) return String is
     ("point " & Img (P.X) & " " & Img (P.Y) & " " & Img (P.Z));

   function Image (K : Loop_Result) return String is
     (case K is
         when Topology.Counter_Clockwise => "loop closed counter_clockwise",
         when Topology.Clockwise         => "loop closed clockwise",
         when Topology.Degenerate        => "loop closed degenerate");

   function Image (K : Face_Result) return String is
     (case K is
         when Topology.Face_Counter_Clockwise => "face counter_clockwise",
         when Topology.Face_Clockwise         => "face clockwise");

   procedure Set_Output_Path (Path : String) is
   begin
      Session.Current_Session.Output_Path := To_Unbounded_String (Path);
   end Set_Output_Path;

   procedure Put_Line (S : String) is
   begin
      if Length (Session.Current_Session.Output_Path) = 0 then
         Ada.Text_IO.Put_Line (S);

      else
         if not Ada.Text_IO.Is_Open (Session.Current_Session.Output_File)
         then
            Ada.Text_IO.Create
              (Session.Current_Session.Output_File,
               Ada.Text_IO.Out_File,
               To_String (Session.Current_Session.Output_Path));
         end if;
         Ada.Text_IO.Put_Line (Session.Current_Session.Output_File, S);

      end if;
   end Put_Line;

   procedure Close_Output is
   begin
      if Ada.Text_IO.Is_Open (Session.Current_Session.Output_File) then
         Ada.Text_IO.Close (Session.Current_Session.Output_File);

      end if;
   end Close_Output;

   procedure Put_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      P : TopoProof.Geometry.Points.Point_3D;

   begin
      if not Conversions.Read_Point_3D (Data, 1, P) then
         Session.Record_Failure ("error: coordinate outside the grid");
         return;
      end if;

      Put_Line (Image (P));
   end Put_Native;

   procedure Put_Loop_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array)
   is
      K : constant Topology.Loop_Kind := Topology.To_Loop_Kind (Data (1));

   begin
      case K is
         when Topology.Counter_Clockwise
            | Topology.Clockwise
            | Topology.Degenerate
         =>
            Put_Line (Image (K));
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
      K : constant Topology.Face_Kind := Topology.To_Face_Kind (Data (1));

   begin
      case K is
         when Topology.Face_Counter_Clockwise
            | Topology.Face_Clockwise
         =>
            Put_Line (Image (K));
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

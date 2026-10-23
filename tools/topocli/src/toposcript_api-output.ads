-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

--  The output domain of the scripting API (development plan,
--  TopoScript consolidation, Increment 2, and the single front-end,
--  Increment 1): the canonical textual results, one implementation
--  per public representation, and the run-owned output destination
--  (DD-004, decision 8).

with HAC_Sys.Interfacing;
with TopoProof.Geometry.Points;
with TopoScript_API.Topology;

package TopoScript_API.Output is

   --  The canonical image of a 3D point: `point X Y Z`, the exact text
   --  of the topocli commands.
   function Image (P : TopoProof.Geometry.Points.Point_3D) return String;

   --  The valid results of the loop and face classifications.
   subtype Loop_Result is Topology.Loop_Kind
     range Topology.Counter_Clockwise .. Topology.Degenerate;

   subtype Face_Result is Topology.Face_Kind
     range Topology.Face_Counter_Clockwise .. Topology.Face_Clockwise;

   --  The canonical image of a loop result: `loop closed ...`.
   function Image (K : Loop_Result) return String;

   --  The canonical image of a face result: `face ...`.
   function Image (K : Face_Result) return String;

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

   --  Native side of Put_Loop: writes `loop closed ...`, or records
   --  the rejection diagnostic of the loop kind.
   procedure Put_Loop_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

   --  Native side of Put_Face: writes `face ...`, or records the
   --  rejection diagnostic of the face kind.
   procedure Put_Face_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

end TopoScript_API.Output;

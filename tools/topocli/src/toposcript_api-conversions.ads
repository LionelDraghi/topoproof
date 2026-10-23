-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

--  The conversions between the HAC element arrays and the TopoProof
--  grid types (development plan, TopoScript consolidation,
--  Increment 2 and the single front-end Increment 1): every domain
--  callback reads and writes its script values through these helpers,
--  instead of repeating the widest-integer decoding and the
--  grid-domain checks.

with Ada.Text_IO;
with HAC_Sys.Interfacing;
with TopoProof.Geometry.Points;
with TopoProof.Geometry.Vectors;
with TopoProof.Numerics;

package TopoScript_API.Conversions is

   --  HAC integers are 64-bit while the grid coordinates are not: the
   --  script values are read on the widest native integer first, then
   --  checked against the grid domain, because an exception raised
   --  inside the HAC virtual machine would not propagate to the
   --  caller.
   function To_Long is new HAC_Sys.Interfacing.To_Native_Any_Integer
     (Long_Long_Integer);

   function Grid_To_HAC is new HAC_Sys.Interfacing.To_HAC_Any_Integer
     (TopoProof.Numerics.Grid_Coordinate);

   --  The script value is one position of one grid axis.
   function Grid_In_Range (Value : Long_Long_Integer) return Boolean;

   --  The canonical decimal image of one grid coordinate.
   package Grid_IO is new Ada.Text_IO.Integer_IO
     (TopoProof.Numerics.Grid_Coordinate);

   --  Read one script point from the HAC elements at From: the
   --  components are read on the widest native integer and checked
   --  against the grid domain. False means at least one component is
   --  outside the grid: P is then left unassigned, and the caller
   --  records its own diagnostic.
   function Read_Point_2D
     (Data : HAC_Sys.Interfacing.HAC_Element_Array;
      From : Positive;
      P    : out TopoProof.Geometry.Points.Point_2D) return Boolean;

   function Read_Point_3D
     (Data : HAC_Sys.Interfacing.HAC_Element_Array;
      From : Positive;
      P    : out TopoProof.Geometry.Points.Point_3D) return Boolean;

   --  Read one script vector from the HAC elements at From. The script
   --  vector components are checked against the grid domain, the
   --  documented input contract of the scripting API (DD-003), which
   --  is narrower than the Vector_Component domain of the kernel.
   function Read_Vector_3D
     (Data : HAC_Sys.Interfacing.HAC_Element_Array;
      From : Positive;
      V    : out TopoProof.Geometry.Vectors.Vector_3D) return Boolean;

   --  Write one point into the HAC elements at From.
   procedure Write_Point_3D
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array;
      From :        Positive;
      P    :        TopoProof.Geometry.Points.Point_3D);

end TopoScript_API.Conversions;

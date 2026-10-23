-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

--  The conversions between the HAC element arrays and the TopoProof
--  grid types (development plan, TopoScript consolidation,
--  Increment 2): every domain callback reads the script values through
--  these helpers, instead of repeating the widest-integer decoding and
--  the grid-domain checks.

with Ada.Text_IO;
with HAC_Sys.Interfacing;
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

end TopoScript_API.Conversions;

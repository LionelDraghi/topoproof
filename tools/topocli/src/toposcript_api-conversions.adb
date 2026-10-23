-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

package body TopoScript_API.Conversions is

   function Grid_In_Range (Value : Long_Long_Integer) return Boolean is
   begin
      return Value >= Long_Long_Integer (TopoProof.Numerics.Grid_Coordinate'First)
        and then Value <= Long_Long_Integer (TopoProof.Numerics.Grid_Coordinate'Last);
   end Grid_In_Range;

end TopoScript_API.Conversions;

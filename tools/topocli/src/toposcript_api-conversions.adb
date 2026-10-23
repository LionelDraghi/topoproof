-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

package body TopoScript_API.Conversions is

   use TopoProof.Numerics;

   function Grid_In_Range (Value : Long_Long_Integer) return Boolean is
   begin
      return Value >= Long_Long_Integer (Grid_Coordinate'First)
        and then Value <= Long_Long_Integer (Grid_Coordinate'Last);
   end Grid_In_Range;

   function Read_Point_2D
     (Data : HAC_Sys.Interfacing.HAC_Element_Array;
      From : Positive;
      P    : out TopoProof.Geometry.Points.Point_2D) return Boolean
   is
      X, Y : Long_Long_Integer;

   begin
      X := To_Long (Data (From));
      Y := To_Long (Data (From + 1));
      if not Grid_In_Range (X) or else not Grid_In_Range (Y) then
         return False;
      end if;
      P := (X => Grid_Coordinate (X), Y => Grid_Coordinate (Y));
      return True;
   end Read_Point_2D;

   function Read_Point_3D
     (Data : HAC_Sys.Interfacing.HAC_Element_Array;
      From : Positive;
      P    : out TopoProof.Geometry.Points.Point_3D) return Boolean
   is
      X, Y, Z : Long_Long_Integer;

   begin
      X := To_Long (Data (From));
      Y := To_Long (Data (From + 1));
      Z := To_Long (Data (From + 2));
      if not Grid_In_Range (X)
        or else not Grid_In_Range (Y)
        or else not Grid_In_Range (Z)
      then
         return False;
      end if;
      P := (X => Grid_Coordinate (X),
            Y => Grid_Coordinate (Y),
            Z => Grid_Coordinate (Z));
      return True;
   end Read_Point_3D;

   function Read_Vector_3D
     (Data : HAC_Sys.Interfacing.HAC_Element_Array;
      From : Positive;
      V    : out TopoProof.Geometry.Vectors.Vector_3D) return Boolean
   is
      DX, DY, DZ : Long_Long_Integer;

   begin
      DX := To_Long (Data (From));
      DY := To_Long (Data (From + 1));
      DZ := To_Long (Data (From + 2));
      if not Grid_In_Range (DX)
        or else not Grid_In_Range (DY)
        or else not Grid_In_Range (DZ)
      then
         return False;
      end if;
      V := (DX => Vector_Component (DX),
            DY => Vector_Component (DY),
            DZ => Vector_Component (DZ));
      return True;
   end Read_Vector_3D;

   procedure Write_Point_3D
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array;
      From :        Positive;
      P    :        TopoProof.Geometry.Points.Point_3D)
   is
   begin
      Data (From)     := Grid_To_HAC (P.X);
      Data (From + 1) := Grid_To_HAC (P.Y);
      Data (From + 2) := Grid_To_HAC (P.Z);
   end Write_Point_3D;

end TopoScript_API.Conversions;

-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------
package body TopoProof.Geometry.Segment_Sequences
   with SPARK_Mode
is

   ---------------------------------------------------------------------------
   --  Signed_Area
   ---------------------------------------------------------------------------

   function Signed_Area (S : Segment_Sequence_2D) return Numerics.Area_Sum is
      Term_Bound : constant Numerics.Area_Sum :=
        Numerics.Area_Sum (Numerics.Determinant'Last);
      Sum : Numerics.Area_Sum := 0;
   begin
      --  A closed sequence stores its first point again as its last point.
      --  The range therefore includes every edge, including the closing edge.
      for I in 1 .. S.Length - 1 loop
         pragma Loop_Invariant
           (abs Sum <= Numerics.Area_Sum (I - 1) * Term_Bound);

         declare
            Term : constant Numerics.Area_Sum :=
              Numerics.Area_Sum (Shoelace_Term (S.Points (I), S.Points (I + 1)));
         begin
            pragma Assert (abs Term <= Term_Bound);
            Sum := Sum + Term;
         end;
      end loop;

      return Sum;
   end Signed_Area;

   ---------------------------------------------------------------------------
   --  Orientation
   ---------------------------------------------------------------------------

   function Orientation
     (S : Segment_Sequence_2D) return Contour_Orientation
   is
      Area : constant Numerics.Area_Sum := Signed_Area (S);
   begin
      if Area > 0 then
         return Counter_Clockwise;
      elsif Area < 0 then
         return Clockwise;
      else
         return Degenerate;
      end if;
   end Orientation;

end TopoProof.Geometry.Segment_Sequences;

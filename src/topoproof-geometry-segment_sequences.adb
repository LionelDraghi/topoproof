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
      --  The largest absolute value of one shoelace term: a determinant of
      --  the proved orientation chain.
      Term_Bound : constant := Numerics.Determinant'Last;
      Sum        : Numerics.Area_Sum := 0;

   begin
      --  After I - 1 iterations, the partial sum is the sum of I - 1
      --  terms, each bounded by the determinant amplitude.
      for I in 1 .. S.Length - 1 loop
         pragma Loop_Invariant
           (abs Sum <= (Numerics.Area_Sum (I - 1)) * Term_Bound);

         Sum :=
           Sum
           + Numerics.Area_Sum
               (Shoelace_Term (S.Points (I), S.Points (I + 1)));

      end loop;

      --  Closing term: from the last vertex back to the first.
      Sum :=
        Sum
        + Numerics.Area_Sum (Shoelace_Term (S.Points (S.Length),
                                             S.Points (1)));

      return Sum;
   end Signed_Area;

   ---------------------------------------------------------------------------
   --  Orientation
   ---------------------------------------------------------------------------

   function Orientation (S : Segment_Sequence_2D) return Contour_Orientation
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

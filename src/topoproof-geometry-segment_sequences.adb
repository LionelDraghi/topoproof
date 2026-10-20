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
   --  Partial_Sum
   ---------------------------------------------------------------------------

   --  The body decreases the range by one at a time, so every recursive
   --  call sees a strictly smaller range: the contract is established by
   --  induction, the induction hypothesis being the assumed contract of
   --  the recursive call. The amplitude bound is exact at each step:
   --  one more term adds at most Max_Shoelace_Term to a sum already
   --  bounded by the number of accumulated terms.
   function Partial_Sum (S : Segment_Sequence_2D; From, To : Positive) return Numerics.Area_Sum is
   begin
      if From = To then
         return 0;
      end if;
      return
         Partial_Sum (S, From, To - 1)
         + Numerics.Area_Sum (Shoelace_Term (S.Points (To - 1), S.Points (To)));
   end Partial_Sum;

   ---------------------------------------------------------------------------
   --  Signed_Area
   ---------------------------------------------------------------------------

   function Signed_Area (S : Segment_Sequence_2D) return Numerics.Area_Sum is
   begin
      --  The closed sequence stores its first point again as its last
      --  point, so the full range covers every edge, including the
      --  closing edge.
      return Partial_Sum (S, 1, S.Length);
   end Signed_Area;

   ---------------------------------------------------------------------------
   --  Orientation
   ---------------------------------------------------------------------------

   function Orientation (S : Segment_Sequence_2D) return Contour_Orientation is
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

   ---------------------------------------------------------------------------
   --  Rotated
   ---------------------------------------------------------------------------

   function Rotated (S : Segment_Sequence_2D; K : Natural) return Segment_Sequence_2D is
      M : constant Positive := S.Length - 1;
      R : Segment_Sequence_2D (S.Length) :=
         (Length => S.Length, Points => [1 .. S.Length => S.Points (1)]);
      J : Positive := 1;
   begin
      while J <= M loop
         pragma Loop_Invariant (J in 1 .. M + 1);
         pragma Loop_Variant (Increases => J);
         pragma
            Loop_Invariant
               (for all I in 1 .. J - 1 =>
                   R.Points (I) = S.Points (if I + K <= M then I + K else I + K - M));
         R.Points (J) := S.Points (if J + K <= M then J + K else J + K - M);
         J := J + 1;
      end loop;
      R.Points (S.Length) := R.Points (1);

      if Is_Valid (S) then
         --  The edges of the original chain, with the closing edge back
         --  to the first point stored at index S.Length.
         pragma
            Assert
               (for all A in 1 .. M =>
                   not Segments.Is_Degenerate
                          (Segments.Segment_2D'
                              (From_Point => S.Points (A),
                               To_Point   => S.Points (if A = M then S.Length else A + 1))));
         --  Every edge of the rotated chain is one of the edges above,
         --  cyclically, so the rotation preserves validity.
         pragma
            Assert
               (for all I in 2 .. S.Length =>
                   not Segments.Is_Degenerate
                          (Segments.Segment_2D'
                              (From_Point => R.Points (I - 1), To_Point => R.Points (I))));
      end if;
      return R;
   end Rotated;

   ---------------------------------------------------------------------------
   --  Reversed
   ---------------------------------------------------------------------------

   function Reversed (S : Segment_Sequence_2D) return Segment_Sequence_2D is
      R : Segment_Sequence_2D (S.Length) :=
         (Length => S.Length, Points => [1 .. S.Length => S.Points (1)]);
      J : Positive := 1;
   begin
      while J <= S.Length loop
         pragma Loop_Invariant (J in 1 .. S.Length + 1);
         pragma Loop_Variant (Increases => J);
         pragma
            Loop_Invariant (for all I in 1 .. J - 1 => R.Points (I) = S.Points (S.Length + 1 - I));
         R.Points (J) := S.Points (S.Length + 1 - J);
         J := J + 1;
      end loop;

      if Is_Closed (S) then
         --  The first and last points of the reversed chain are the last
         --  and first points of the original one, which coincide.
         pragma Assert (Is_Closed (R));
      end if;
      if Is_Valid (S) then
         --  The edge from I - 1 to I of the reversed chain is the edge
         --  from S.Length + 2 - I to S.Length + 1 - I of the original
         --  chain, so the reversal permutes the same edges.
         pragma
            Assert
               (for all I in 2 .. S.Length =>
                   not Segments.Is_Degenerate
                          (Segments.Segment_2D'
                              (From_Point => R.Points (I - 1), To_Point => R.Points (I))));
      end if;
      return R;
   end Reversed;

   ---------------------------------------------------------------------------
   --  Lemma_Peel_Front
   ---------------------------------------------------------------------------

   --  Induction upward from the single-term range: at each step, the
   --  term peeled from the back of both sides is the same term, and the
   --  single-term base is the back decomposition with an empty head.
   procedure Lemma_Peel_Front (S : Segment_Sequence_2D; From, To : Positive) is
      I : Positive := From + 1;
   begin
      while I < To loop
         pragma Loop_Invariant (I in From + 1 .. To);
         pragma Loop_Variant (Increases => I);
         pragma
            Loop_Invariant
               (Partial_Sum (S, From, I)
                   = Numerics.Area_Sum (Shoelace_Term (S.Points (From), S.Points (From + 1)))
                     + Partial_Sum (S, From + 1, I));
         I := I + 1;
      end loop;
   end Lemma_Peel_Front;

   ---------------------------------------------------------------------------
   --  Lemma_Sum_Split
   ---------------------------------------------------------------------------

   --  Induction on the split index: at each step, the term peeled from
   --  the back of the left part is the term peeled from the front of the
   --  right part.
   procedure Lemma_Sum_Split (S : Segment_Sequence_2D; From, Mid, To : Positive) is
      I : Positive := From;
   begin
      while I < Mid loop
         pragma Loop_Invariant (I in From .. Mid);
         pragma
            Loop_Invariant
               (Partial_Sum (S, From, To) = Partial_Sum (S, From, I) + Partial_Sum (S, I, To));
         Lemma_Peel_Front (S, I, To);
         I := I + 1;
      end loop;
   end Lemma_Sum_Split;

   ---------------------------------------------------------------------------
   --  Lemma_Rotation_Invariance
   ---------------------------------------------------------------------------

   --  The rotated sum accumulates the same terms as the original sum,
   --  cyclically shifted: the terms up to the shift are the original
   --  terms K + 1 .. M, the terms after it are the original terms
   --  1 .. K - 1, and the closing term of the rotated chain is the
   --  original term K. The loop invariant accumulates both sums in
   --  lockstep, and the assembly reorders the pieces with Lemma_Sum_Split
   --  and the one-term peels of Partial_Sum.
   procedure Lemma_Rotation_Invariance (S : Segment_Sequence_2D; K : Natural) is
      M : constant Positive := S.Length - 1;
      R : constant Segment_Sequence_2D (S.Length) := Rotated (S, K);
      J : Positive := 1;
   begin
      pragma
         Assert
            (for all I in 1 .. S.Length - 1 =>
                R.Points (I) = S.Points (if I + K <= M then I + K else I + K - M));
      pragma Assert (R.Points (S.Length) = R.Points (1));

      while J <= M - 1 loop
         pragma Loop_Invariant (J in 1 .. M);
         pragma
            Loop_Invariant
               (Partial_Sum (R, 1, J)
                   = (if J <= M - K + 1
                      then Partial_Sum (S, K + 1, K + J)
                      else Partial_Sum (S, K + 1, S.Length) + Partial_Sum (S, 1, J + K - M)));
         J := J + 1;
      end loop;

      --  The closing term of the rotated chain is the term K of the
      --  original chain.
      pragma
         Assert
            (Numerics.Area_Sum (Shoelace_Term (R.Points (M), R.Points (S.Length)))
                = Numerics.Area_Sum (Shoelace_Term (S.Points (K), S.Points (K + 1))));
      --  hence the rotated sum is the original sum split at K + 1
      pragma
         Assert
            (Partial_Sum (R, 1, S.Length)
                = Partial_Sum (S, K + 1, S.Length) + Partial_Sum (S, 1, K + 1));
      Lemma_Sum_Split (S, 1, K + 1, S.Length);
      pragma Assert (Partial_Sum (R, 1, S.Length) = Partial_Sum (S, 1, S.Length));
      pragma Assert (Signed_Area (Rotated (S, K)) = Signed_Area (S));
   end Lemma_Rotation_Invariance;

   ---------------------------------------------------------------------------
   --  Lemma_Reversal
   ---------------------------------------------------------------------------

   --  Each term of the reversed chain is the negation of the opposite
   --  term of the original chain, by antisymmetry of the cross
   --  determinant; the loop accumulates both sums in lockstep.
   procedure Lemma_Reversal (S : Segment_Sequence_2D) is
      R : constant Segment_Sequence_2D (S.Length) := Reversed (S);
      J : Positive := 1;
   begin
      pragma Assert (for all I in 1 .. S.Length => R.Points (I) = S.Points (S.Length + 1 - I));

      while J <= S.Length - 1 loop
         pragma Loop_Invariant (J in 1 .. S.Length);
         pragma
            Loop_Invariant (Partial_Sum (R, 1, J) = -Partial_Sum (S, S.Length + 1 - J, S.Length));
         Lemma_Peel_Front (S, S.Length - J, S.Length);
         Orientations.Lemma_Cross_Antisymmetry
            (Numerics.Vector_Component (S.Points (S.Length + 1 - J).X),
             Numerics.Vector_Component (S.Points (S.Length + 1 - J).Y),
             Numerics.Vector_Component (S.Points (S.Length - J).X),
             Numerics.Vector_Component (S.Points (S.Length - J).Y));
         pragma
            Assert
               (Numerics.Area_Sum (Shoelace_Term (R.Points (J), R.Points (J + 1)))
                   = -Numerics.Area_Sum
                         (Shoelace_Term (S.Points (S.Length - J), S.Points (S.Length + 1 - J))));
         J := J + 1;
      end loop;

      pragma Assert (Partial_Sum (R, 1, S.Length) = -Partial_Sum (S, 1, S.Length));
      pragma Assert (Signed_Area (R) = -Signed_Area (S));
   end Lemma_Reversal;

   ---------------------------------------------------------------------------
   --  Orientation corollaries
   ---------------------------------------------------------------------------

   procedure Lemma_Orientation_Rotation (S : Segment_Sequence_2D; K : Natural) is
   begin
      Lemma_Rotation_Invariance (S, K);
      case Orientation (S) is
         when Counter_Clockwise =>
            pragma Assert (Orientation (Rotated (S, K)) = Counter_Clockwise);

         when Clockwise         =>
            pragma Assert (Orientation (Rotated (S, K)) = Clockwise);

         when Degenerate        =>
            pragma Assert (Orientation (Rotated (S, K)) = Degenerate);
      end case;
   end Lemma_Orientation_Rotation;

   procedure Lemma_Orientation_Reversal (S : Segment_Sequence_2D) is
   begin
      Lemma_Reversal (S);
      case Orientation (S) is
         when Counter_Clockwise =>
            pragma Assert (Signed_Area (Reversed (S)) < 0);
            pragma Assert (Orientation (Reversed (S)) = Clockwise);

         when Clockwise         =>
            pragma Assert (Signed_Area (Reversed (S)) > 0);
            pragma Assert (Orientation (Reversed (S)) = Counter_Clockwise);

         when Degenerate        =>
            pragma Assert (Signed_Area (Reversed (S)) = 0);
            pragma Assert (Orientation (Reversed (S)) = Degenerate);
      end case;
   end Lemma_Orientation_Reversal;

end TopoProof.Geometry.Segment_Sequences;

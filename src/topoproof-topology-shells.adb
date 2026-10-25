-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

package body TopoProof.Topology.Shells
   with SPARK_Mode
is
   --  The classification mirrors the definition order of the status
   --  type: every boundary first, then the pairing of the uses, worst
   --  defect first. Bad records the first invalid boundary, 0 when
   --  every boundary is valid; Result records the worst pairing
   --  defect seen so far. A later, worse defect overrides an earlier
   --  one, and an earlier one is never masked by a later, lesser one.
   function Classify_Shell
      (E : Edges_3D.Edge_Store; V : Vertices_3D.Vertex_Store; S : Shell) return Shell_Validity
   is
      Result : Shell_Validity := Closed_Shell;
      Bad    : Natural := 0;

   begin
      for K in 1 .. S.Face_Count loop
         if Bad = 0 and then not Is_Valid_Boundary (E, V, S, K) then
            Bad := K;
         end if;
         pragma
            Loop_Invariant (if Bad > 0 then Bad <= K and then not Is_Valid_Boundary (E, V, S, Bad));
         pragma
            Loop_Invariant
               (if Bad = 0 then (for all J in 1 .. K => Is_Valid_Boundary (E, V, S, J)));
      end loop;

      if Bad > 0 then
         return Invalid_Boundary;
      end if;

      for U in 1 .. S.Edge_Total loop
         declare
            SC : constant Natural := Same_Support_Count (E, V, S.Boundary, U, 1);
            OC : constant Natural := Opposite_Support_Count (E, V, S.Boundary, U, 1);
         begin
            if SC + OC >= 2 then
               return Overused_Edge;

            elsif SC = 1 and then OC = 0 then
               Result := Misaligned_Edge;

            elsif SC = 0 and then OC = 0 and then Result = Closed_Shell then
               Result := Free_Edge;
            end if;
         end;

         pragma
            Loop_Invariant
               (Result = Closed_Shell or else Result = Misaligned_Edge or else Result = Free_Edge);
         pragma
            Loop_Invariant
               (for all W in 1 .. U =>
                   Same_Support_Count (E, V, S.Boundary, W, 1)
                   + Opposite_Support_Count (E, V, S.Boundary, W, 1)
                   <= 1);
         pragma
            Loop_Invariant
               (if Result = Closed_Shell
                   then
                      (for all W in 1 .. U =>
                          Same_Support_Count (E, V, S.Boundary, W, 1) = 0
                          and then Opposite_Support_Count (E, V, S.Boundary, W, 1) = 1));
         pragma
            Loop_Invariant
               (if (for some W in 1 .. U =>
                       Same_Support_Count (E, V, S.Boundary, W, 1) = 1
                       and then Opposite_Support_Count (E, V, S.Boundary, W, 1) = 0)
                   then Result = Misaligned_Edge);
         pragma
            Loop_Invariant
               (if Result = Misaligned_Edge
                   then
                      (for some W in 1 .. U =>
                          Same_Support_Count (E, V, S.Boundary, W, 1) = 1
                          and then Opposite_Support_Count (E, V, S.Boundary, W, 1) = 0));
         pragma
            Loop_Invariant
               (if Result = Free_Edge
                   then
                      (for some W in 1 .. U =>
                          Same_Support_Count (E, V, S.Boundary, W, 1) = 0
                          and then Opposite_Support_Count (E, V, S.Boundary, W, 1) = 0));
      end loop;

      return Result;
   end Classify_Shell;

end TopoProof.Topology.Shells;

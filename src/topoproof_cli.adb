-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- ----------------------------------------------------------------------------- 
with Ada.Command_Line;                 use Ada.Command_Line;
with Ada.Strings;                      use Ada.Strings;
with Ada.Strings.Fixed;                use Ada.Strings.Fixed;
with Ada.Strings.Unbounded;            use Ada.Strings.Unbounded;
with Ada.Text_IO;                      use Ada.Text_IO;
with TopoProof.Geometry.Intersections; use TopoProof.Geometry.Intersections;
with TopoProof.Geometry.Orientations;  use TopoProof.Geometry.Orientations;
with TopoProof.Geometry.Segments;      use TopoProof.Geometry.Segments;
with TopoProof.Geometry.Segment_Sequences; use TopoProof.Geometry.Segment_Sequences;
with TopoProof.Geometry.Points;            use TopoProof.Geometry.Points;
with TopoProof.Geometry.Translations;      use TopoProof.Geometry.Translations;
with TopoProof.Geometry.Vectors;           use TopoProof.Geometry.Vectors;
with TopoProof.Numerics;                   use TopoProof.Numerics;

procedure TopoProof_CLI is
   Usage_Error             : exception;
   Input_Path, Output_Path : Unbounded_String;

   procedure Emit (S : String);

   procedure Emit (S : String) is
      F : File_Type;

   begin
      if Length (Output_Path) = 0 then
         Put_Line (S);

      else
         Create (F, Out_File, To_String (Output_Path));
         Put_Line (F, S);
         Close (F);

      end if;
   end Emit;

   function Token (S : in out Unbounded_String) return String;

   function Token (S : in out Unbounded_String) return String is
      T : constant String := Trim (To_String (S), Both);
      I : constant Natural := Index (T, " ");

   begin
      if T'Length = 0 then
         return "";

      elsif I = 0 then
         S := Null_Unbounded_String;
         return T;

      else
         S := To_Unbounded_String (T (I + 1 .. T'Last));
         return T (T'First .. I - 1);

      end if;
   end Token;

   function C (S : String) return Grid_Coordinate
   is (Grid_Coordinate'Value (S));

   function V (S : String) return Vector_Component
   is (Vector_Component'Value (S));

   function Img (N : Grid_Coordinate) return String
   is (Trim (Grid_Coordinate'Image (N), Both));

   function Img (N : Vector_Component) return String
   is (Trim (Vector_Component'Image (N), Both));

   procedure Execute (Line : String);

   procedure Execute (Line : String) is
      R  : Unbounded_String := To_Unbounded_String (Line);
      Op : constant String := Token (R);

   begin
      if Op = "translate" then
         declare
            P : constant Point_3D := (C (Token (R)), C (Token (R)), C (Token (R)));
            D : constant Vector_3D := (V (Token (R)), V (Token (R)), V (Token (R)));

         begin
            if Token (R) /= "" then
               raise Usage_Error;

            elsif not Translation_Is_Representable (P, D) then
               Emit ("error: translation is not representable");
               Set_Exit_Status (Failure);

            else
               declare
                  Q : constant Point_3D := Translate (P, D);

               begin
                  Emit ("point " & Img (Q.X) & " " & Img (Q.Y) & " " & Img (Q.Z));
               end;

            end if;
         end;

      elsif Op = "displacement" then
         declare
            A : constant Point_3D := (C (Token (R)), C (Token (R)), C (Token (R)));
            B : constant Point_3D := (C (Token (R)), C (Token (R)), C (Token (R)));
            D : constant Vector_3D := Displacement (A, B);

         begin
            if Token (R) /= "" then
               raise Usage_Error;

            end if;
            Emit ("vector " & Img (D.DX) & " " & Img (D.DY) & " " & Img (D.DZ));
         end;

      elsif Op = "equal" then
         declare
            A : constant Point_3D := (C (Token (R)), C (Token (R)), C (Token (R)));
            B : constant Point_3D := (C (Token (R)), C (Token (R)), C (Token (R)));

         begin
            if Token (R) /= "" then
               raise Usage_Error;

            end if;
            if A = B then
               Emit ("equal true");

            else
               Emit ("equal false");

            end if;
         end;

      elsif Op = "orientation" then
         declare
            A : constant Point_2D := (C (Token (R)), C (Token (R)));
            B : constant Point_2D := (C (Token (R)), C (Token (R)));
            P : constant Point_2D := (C (Token (R)), C (Token (R)));

         begin
            if Token (R) /= "" then
               raise Usage_Error;

            end if;
            case Orientation (A, B, P) is
               when Counter_Clockwise =>
                  Emit ("orientation counter_clockwise");

               when Clockwise         =>
                  Emit ("orientation clockwise");

               when Collinear         =>
                  Emit ("orientation collinear");

            end case;
         end;

      elsif Op = "intersect" then
         declare
            S1 : constant Segment_2D :=
              ((C (Token (R)), C (Token (R))), (C (Token (R)), C (Token (R))));
            S2 : constant Segment_2D :=
              ((C (Token (R)), C (Token (R))), (C (Token (R)), C (Token (R))));

         begin
            if Token (R) /= "" then
               raise Usage_Error;

            end if;
            declare
               Res : constant Intersection_Result := Intersection (S1, S2);

            begin
               case Res.Kind is
                  when No_Intersection =>
                     Emit ("intersection no_intersection");
                  when Point_Intersection =>
                     Emit
                       ("intersection point_intersection "
                        & Img (Res.Point.X) & " " & Img (Res.Point.Y));
                  when Off_Grid_Crossing =>
                     Emit ("intersection off_grid_crossing");
                  when Overlap =>
                     Emit
                       ("intersection overlap "
                        & Img (Res.Overlap.From_Point.X) & " "
                        & Img (Res.Overlap.From_Point.Y) & " "
                        & Img (Res.Overlap.To_Point.X) & " "
                        & Img (Res.Overlap.To_Point.Y));

               end case;
            end;
         end;

      elsif Op = "contour_continuity" then
         --  The n segments are given by their explicit endpoints,
         --  four coordinates each: S_i = (P_2i-1, P_2i).
         declare
            N : constant Natural := Natural'Value (Token (R));
         begin
            if N = 0 then
               if Token (R) /= "" then
                  raise Usage_Error;

               end if;
               Emit ("continuity continuous");

            else
               declare
                  Pts : Point_2D_Array (1 .. 2 * N);

               begin
                  for I in Pts'Range loop
                     Pts (I) := (C (Token (R)), C (Token (R)));
                  end loop;
                  if Token (R) /= "" then
                     raise Usage_Error;

                  end if;
                  declare
                     Continuous : Boolean := True;

                  begin
                     for I in 1 .. N - 1 loop
                        if Pts (2 * I) /= Pts (2 * I + 1) then
                           Continuous := False;

                        end if;
                     end loop;
                     if Continuous then
                        Emit ("continuity continuous");

                     else
                        Emit ("continuity discontinuous");

                     end if;
                  end;
               end;
            end if;
         end;

      elsif Op = "contour_closure" then
         declare
            N   : constant Natural              := Natural'Value (Token (R));
            Seq : Segment_Sequence_2D (N);
         begin
            for I in 1 .. N loop
               Seq.Points (I) := (C (Token (R)), C (Token (R)));
            end loop;
            if Token (R) /= "" then
               raise Usage_Error;

            end if;
            if Is_Closed (Seq) then
               Emit ("closure closed");

            else
               Emit ("closure open");

            end if;
         end;

      elsif Op = "contour_orientation" then
         declare
            N : constant Natural := Natural'Value (Token (R));
            Seq : Segment_Sequence_2D (N);
         begin
            for I in 1 .. N loop
               Seq.Points (I) := (C (Token (R)), C (Token (R)));
            end loop;
            if Token (R) /= "" then
               raise Usage_Error;
            end if;
            if N < 3 then
               Emit ("error: at least 3 points required for orientation");
               Set_Exit_Status (Failure);
            else
               if not Is_Closed (Seq) then
                  Emit ("error: sequence is not closed");
                  Set_Exit_Status (Failure);
               elsif not Is_Valid (Seq) then
                  Emit ("error: sequence is not valid");
                  Set_Exit_Status (Failure);
               else
                  case Orientation (Seq) is
                     when Counter_Clockwise =>
                        Emit ("orientation counter_clockwise");
                     when Clockwise =>
                        Emit ("orientation clockwise");
                     when Degenerate =>
                        Emit ("orientation degenerate");
                  end case;
               end if;
            end if;
         end;

      elsif Op = "contour_self_intersects" then
         declare
            N   : constant Natural              := Natural'Value (Token (R));
            Seq : Segment_Sequence_2D (N);
         begin
            for I in 1 .. N loop
               Seq.Points (I) := (C (Token (R)), C (Token (R)));
            end loop;
            if Token (R) /= "" then
               raise Usage_Error;

            end if;
            if Self_Intersects (Seq) then
               Emit ("true");

            else
               Emit ("false");

            end if;
         end;

      elsif Op = "contour_valid" then
         declare
            N   : constant Natural              := Natural'Value (Token (R));
            Seq : Segment_Sequence_2D (N);
         begin
            for I in 1 .. N loop
               Seq.Points (I) := (C (Token (R)), C (Token (R)));
            end loop;
            if Token (R) /= "" then
               raise Usage_Error;

            end if;
            if Is_Valid (Seq) then
               Emit ("true");

            else
               Emit ("false");

            end if;
         end;

      else
         raise Usage_Error;

      end if;

   exception
      when Constraint_Error =>
         Emit ("error: invalid or out-of-range numeric parameter");
         Set_Exit_Status (Failure);
   end Execute;

   Args : Unbounded_String;
   I    : Positive := 1;

begin
   while I <= Argument_Count loop
      if Argument (I) = "--input" or else Argument (I) = "--output" then
         declare
            Is_Input : constant Boolean := Argument (I) = "--input";

         begin
            I := I + 1;
            if I > Argument_Count then
               raise Usage_Error;

            end if;
            if Is_Input then
               Input_Path := To_Unbounded_String (Argument (I));

            else
               Output_Path := To_Unbounded_String (Argument (I));

            end if;
         end;

      elsif Argument (I) = "--help" or else Argument (I) = "-h" then
         Emit ("usage: topoproof OPERATION PARAMETERS [--output FILE]");
         Emit ("       topoproof --input FILE [--output FILE]");
         Emit ("operations: translate, displacement, equal, orientation, intersect");
         Emit ("             contour_continuity, contour_closure, contour_orientation");
         Emit ("             contour_self_intersects, contour_valid");
         return;

      else
         if Length (Args) > 0 then
            Append (Args, " ");

         end if;
         Append (Args, Argument (I));

      end if;
      I := I + 1;
   end loop;
   if Length (Input_Path) > 0 then
      if Length (Args) > 0 then
         raise Usage_Error;

      end if;
      declare
         F : File_Type;

      begin
         Open (F, In_File, To_String (Input_Path));
         if End_Of_File (F) then
            Close (F);
            raise Usage_Error;

         end if;
         Execute (Get_Line (F));
         Close (F);
      end;

   elsif Length (Args) > 0 then
      Execute (To_String (Args));

   else
      raise Usage_Error;

   end if;

exception
   when Usage_Error =>
      Put_Line (Standard_Error, "error: invalid command line");
      Put_Line (Standard_Error, "try 'topoproof --help'");
      Set_Exit_Status (Failure);
   when Name_Error =>
      Put_Line (Standard_Error, "error: input or output file cannot be opened");
      Set_Exit_Status (Failure);

end TopoProof_CLI;

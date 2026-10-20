-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with Ada.Command_Line;                use Ada.Command_Line;
with Ada.Containers.Indefinite_Vectors;
with Ada.Strings;                     use Ada.Strings;
with Ada.Strings.Fixed;               use Ada.Strings.Fixed;
with Ada.Strings.Unbounded;           use Ada.Strings.Unbounded;
with Ada.Text_IO;                     use Ada.Text_IO;
with TopoProof.Geometry.Intersections; use TopoProof.Geometry.Intersections;
with TopoProof.Geometry.Orientations;  use TopoProof.Geometry.Orientations;
with TopoProof.Geometry.Segments;      use TopoProof.Geometry.Segments;
with TopoProof.Geometry.Segment_Sequences;
use TopoProof.Geometry.Segment_Sequences;
with TopoProof.Geometry.Points;       use TopoProof.Geometry.Points;
with TopoProof.Geometry.Translations; use TopoProof.Geometry.Translations;
with TopoProof.Geometry.Vectors;      use TopoProof.Geometry.Vectors;
with TopoProof.Numerics;              use TopoProof.Numerics;
with Topodraw;                        use Topodraw;

procedure TopoCLI is
   Usage_Error             : exception;
   Input_Path, Output_Path : Unbounded_String;
   Draw_Path               : Unbounded_String;
   Draw_With               : Unbounded_String;
   Short_Labels            : Boolean := False;

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

   function C (N : Integer) return Grid_Coordinate
   is (Grid_Coordinate (N));

   function V (N : Integer) return Vector_Component
   is (Vector_Component (N));

   function Img (N : Grid_Coordinate) return String
   is (Trim (Grid_Coordinate'Image (N), Both));

   function Img (N : Vector_Component) return String
   is (Trim (Vector_Component'Image (N), Both));

   function Img (N : Integer) return String
   is (Trim (Integer'Image (N), Both));

   ---------------------------------------------------------------------------
   --  Named points
   ---------------------------------------------------------------------------

   --  A point token is either a definition NAME=(X, Y) or NAME=(X, Y, Z),
   --  which also records the name for later reference and for drawing
   --  labels, or a bare NAME referring to a point defined earlier in the
   --  same command. Repeating a name makes the closure of a chain visible.
   type Arity_Kind is (Two_D, Three_D);

   --  Wide arithmetic for diagram geometry: the sum of two Integer
   --  coordinates may leave Integer, so it is computed in a wide type.
   --  The range is stated here rather than borrowed from a predefined
   --  type such as Long_Integer, whose size, and therefore the
   --  reachable values and the meaningful checks, depends on the
   --  platform.
   type Wide_Coordinate is range -2**32 .. 2**32;

   type Parsed_Point is record
      Name  : Unbounded_String;
      X, Y, Z : Integer;
      Arity : Arity_Kind;
   end record;

   package Point_Vectors is new Ada.Containers.Indefinite_Vectors
     (Positive, Parsed_Point);

   procedure Skip_Spaces (S : String; I : in out Natural) is
   begin
      while I <= S'Last and then S (I) = ' ' loop
         I := I + 1;
      end loop;
   end Skip_Spaces;

   function Is_Name_Char (C : Character) return Boolean is
     ((C in 'A' .. 'Z') or else (C in 'a' .. 'z')
      or else (C in '0' .. '9') or else C = '_');

   function Parse_Int (S : String; I : in out Natural) return Integer is
      First : Natural;

   begin
      Skip_Spaces (S, I);
      First := I;
      if I <= S'Last and then S (I) = '-' then
         I := I + 1;

      end if;
      if I > S'Last or else S (I) not in '0' .. '9' then
         raise Usage_Error;

      end if;
      while I <= S'Last and then S (I) in '0' .. '9' loop
         I := I + 1;
      end loop;
      return Integer'Value (S (First .. I - 1));
   end Parse_Int;

   function At_End (R : Unbounded_String) return Boolean is
      T : constant String := Trim (To_String (R), Both);

   begin
      return T'Length = 0;
   end At_End;

   --  Parse one point token from R, updating R to the unconsumed tail.
   function Next_Point
      (R : in out Unbounded_String; Defs : in out Point_Vectors.Vector)
      return Parsed_Point
   is
      S : constant String  := Trim (To_String (R), Left);
      I : Natural          := S'First;
      J : Natural;

   begin
      Skip_Spaces (S, I);
      if I > S'Last then
         raise Usage_Error;

      end if;
      J := I;
      while J <= S'Last and then Is_Name_Char (S (J)) loop
         J := J + 1;
      end loop;
      if J = I or else S (I) not in 'A' .. 'Z' | 'a' .. 'z' | '_' then
         raise Usage_Error;

      end if;
      declare
         Name : constant String := S (I .. J - 1);
         K    : Natural        := J;
         P    : Parsed_Point;

      begin
         Skip_Spaces (S, K);
         if K <= S'Last and then S (K) = '=' then
            --  Definition: NAME=(X, Y) or NAME=(X, Y, Z)
            K := K + 1;
            Skip_Spaces (S, K);
            if K > S'Last or else S (K) /= '(' then
               raise Usage_Error;

            end if;
            K := K + 1;
            P.X := Parse_Int (S, K);
            Skip_Spaces (S, K);
            if K > S'Last or else S (K) /= ',' then
               raise Usage_Error;

            end if;
            K := K + 1;
            P.Y := Parse_Int (S, K);
            Skip_Spaces (S, K);
            if K <= S'Last and then S (K) = ',' then
               K := K + 1;
               P.Z   := Parse_Int (S, K);
               P.Arity := Three_D;
               Skip_Spaces (S, K);

            else
               P.Z     := 0;
               P.Arity := Two_D;

            end if;
            if K > S'Last or else S (K) /= ')' then
               raise Usage_Error;

            end if;
            K := K + 1;
            P.Name := To_Unbounded_String (Name);

            for E of Defs loop
               if To_String (E.Name) = Name then
                  if E.X /= P.X or else E.Y /= P.Y or else E.Z /= P.Z then
                     raise Usage_Error;

                  end if;
                  R := To_Unbounded_String (S (K .. S'Last));
                  return E;

               end if;
            end loop;
            Defs.Append (P);
            R := To_Unbounded_String (S (K .. S'Last));
            return P;

         else
            --  Reference: a bare NAME
            for E of Defs loop
               if To_String (E.Name) = Name then
                  R := To_Unbounded_String (S (K .. S'Last));
                  return E;

               end if;
            end loop;
            raise Usage_Error;

         end if;
      end;
   end Next_Point;

   procedure Require_2D (P : Parsed_Point) is
   begin
      if P.Arity /= Two_D then
         raise Usage_Error;

      end if;
   end Require_2D;

   procedure Require_3D (P : Parsed_Point) is
   begin
      if P.Arity /= Three_D then
         raise Usage_Error;

      end if;
   end Require_3D;

   procedure Require_End (R : Unbounded_String) is
   begin
      if not At_End (R) then
         raise Usage_Error;

      end if;
   end Require_End;

   --  Parse all remaining point tokens.
   function Parse_Chain
      (R : in out Unbounded_String; Defs : in out Point_Vectors.Vector)
      return Point_Vectors.Vector
   is
      Chain : Point_Vectors.Vector;

   begin
      while not At_End (R) loop
         Chain.Append (Next_Point (R, Defs));
      end loop;
      return Chain;
   end Parse_Chain;

   function Point_Of (P : Parsed_Point) return Point_2D is
     ((C (P.X), C (P.Y)));

   ---------------------------------------------------------------------------
   --  Drawing
   ---------------------------------------------------------------------------

   --  When --draw FILE is given, the command synthesizes the scene of its
   --  own data and results, and writes the isometric SVG diagram to FILE:
   --  the tested command is the single source of its documentation image.
   function New_Scene return Scene is
     ((Draw_Axes => True, Tick_Step => 0, Anchors => True, others => <>));

   function Pair_Label (DX, DY : Integer) return String is
     ("(" & Img (DX) & ", " & Img (DY) & ")");

   function Triple_Label (DX, DY, DZ : Integer) return String is
     ("(" & Img (DX) & ", " & Img (DY) & ", " & Img (DZ) & ")");

   procedure Add_Point (S : in out Scene; Name : String; X, Y, Z : Integer) is
   begin
      S.Points.Append
        (Point_Rec'
           (Name => To_Unbounded_String (Name), X => X, Y => Y, Z => Z));
   end Add_Point;

   --  Points are added once per name: a repeated name is the same position.
   procedure Add_Once (S : in out Scene; P : Parsed_Point) is
   begin
      for E of S.Points loop
         if To_String (E.Name) = To_String (P.Name) then
            return;

         end if;
      end loop;
      Add_Point (S, To_String (P.Name), P.X, P.Y, 0);
   end Add_Once;

   procedure Add_Vector
      (S : in out Scene; From_Name, To_Name, Label : String)
   is
   begin
      S.Vectors.Append
        (Vector_Rec'
           (From_Name => To_Unbounded_String (From_Name),
            To_Name   => To_Unbounded_String (To_Name),
            Label     => To_Unbounded_String (Label)));
   end Add_Vector;

   --  Draw the arrow from P to Q, labeled with the displacement. A
   --  degenerate segment (coincident endpoints) draws as nothing: the
   --  renderer rejects arrows between coincident points.
   procedure Add_Segment (S : in out Scene; P, Q : Parsed_Point) is
   begin
      if P.X = Q.X and then P.Y = Q.Y and then P.Z = Q.Z then
         return;

      end if;
      Add_Vector (S, To_String (P.Name), To_String (Q.Name),
                  Pair_Label (Q.X - P.X, Q.Y - P.Y));
   end Add_Segment;

   procedure Add_Segment_3D (S : in out Scene; P, Q : Parsed_Point) is
   begin
      if P.X = Q.X and then P.Y = Q.Y and then P.Z = Q.Z then
         return;

      end if;
      Add_Vector (S, To_String (P.Name), To_String (Q.Name),
                  Triple_Label (Q.X - P.X, Q.Y - P.Y, Q.Z - P.Z));
   end Add_Segment_3D;

   --  Draw the point chain of a contour command, with one vector per
   --  consecutive pair of positions.
   procedure Draw_Chain (S : in out Scene; Chain : Point_Vectors.Vector) is
   begin
      for P of Chain loop
         Add_Once (S, P);
      end loop;
      for I in 1 .. Natural (Chain.Length) - 1 loop
         Add_Segment (S, Chain (I), Chain (I + 1));
      end loop;
   end Draw_Chain;

   --  Draw the scene: optionally add the extra chain of --draw-with, and
   --  optionally relabel the vectors S1, S2, ... instead of the deltas.
   procedure Draw (S : in out Scene; With_Chain : Point_Vectors.Vector) is
      F : File_Type;

   begin
      if Length (Draw_Path) = 0 then
         return;

      end if;
      Draw_Chain (S, With_Chain);
      if Short_Labels then
         for I in 1 .. Natural (S.Vectors.Length) loop
            S.Vectors (I).Label :=
              To_Unbounded_String ("S" & Img (I));

         end loop;
      end if;
      Create (F, Out_File, To_String (Draw_Path));
      Put_Line (F, Render (S));
      Close (F);
   end Draw;

   procedure Execute (Line : String);

   procedure Execute (Line : String) is
      R    : Unbounded_String := To_Unbounded_String (Line);
      Op   : constant String  := Token (R);
      Defs : Point_Vectors.Vector;
      With_Defs  : Point_Vectors.Vector;
      With_Chain : Point_Vectors.Vector;

   begin
      --  The extra geometry of --draw-with, drawn alongside the data of
      --  the operation.
      if Length (Draw_With) > 0 then
         declare
            W : Unbounded_String := Draw_With;

         begin
            while not At_End (W) loop
               With_Chain.Append (Next_Point (W, With_Defs));
            end loop;
         end;
      end if;
      if Op = "translate" then
         declare
            P : constant Parsed_Point := Next_Point (R, Defs);
            D : constant Parsed_Point := Next_Point (R, Defs);

         begin
            Require_3D (P);
            Require_3D (D);
            Require_End (R);
            declare
               Pt : constant Point_3D  := (C (P.X), C (P.Y), C (P.Z));
               Vc : constant Vector_3D := (V (D.X), V (D.Y), V (D.Z));

            begin
               if Length (Draw_Path) > 0 then
                  declare
                     S  : Scene := New_Scene;
                     QX : constant Wide_Coordinate :=
                       Wide_Coordinate (P.X) + Wide_Coordinate (D.X);
                     QY : constant Wide_Coordinate :=
                       Wide_Coordinate (P.Y) + Wide_Coordinate (D.Y);
                     QZ : constant Wide_Coordinate :=
                       Wide_Coordinate (P.Z) + Wide_Coordinate (D.Z);

                  begin
                     Add_Point (S, To_String (P.Name), P.X, P.Y, P.Z);
                     if QX >= Wide_Coordinate (Integer'First)
                       and then QX <= Wide_Coordinate (Integer'Last)
                       and then QY >= Wide_Coordinate (Integer'First)
                       and then QY <= Wide_Coordinate (Integer'Last)
                       and then QZ >= Wide_Coordinate (Integer'First)
                       and then QZ <= Wide_Coordinate (Integer'Last)
                     then
                        declare
                           Q : constant Parsed_Point :=
                             (To_Unbounded_String ("Q"), Integer (QX),
                              Integer (QY), Integer (QZ), Three_D);

                        begin
                           Add_Point (S, "Q", Q.X, Q.Y, Q.Z);
                           Add_Segment_3D (S, P, Q);
                        end;

                     end if;
                     Draw (S, With_Chain);
                  end;
               end if;
               if not Translation_Is_Representable (Pt, Vc) then
                  Emit ("error: translation is not representable");
                  Set_Exit_Status (Failure);

               else
                  declare
                     Q : constant Point_3D := Translate (Pt, Vc);

                  begin
                     Emit
                       ("point " & Img (Q.X) & " " & Img (Q.Y) & " "
                        & Img (Q.Z));
                  end;
               end if;
            end;
         end;

      elsif Op = "displacement" then
         declare
            A : constant Parsed_Point := Next_Point (R, Defs);
            B : constant Parsed_Point := Next_Point (R, Defs);

         begin
            Require_3D (A);
            Require_3D (B);
            Require_End (R);
            declare
               Pa : constant Point_3D := (C (A.X), C (A.Y), C (A.Z));
               Pb : constant Point_3D := (C (B.X), C (B.Y), C (B.Z));
               D  : constant Vector_3D := Displacement (Pa, Pb);

            begin
               if Length (Draw_Path) > 0 then
                  declare
                     S : Scene := New_Scene;

                  begin
                     Add_Point (S, To_String (A.Name), A.X, A.Y, A.Z);
                     Add_Point (S, To_String (B.Name), B.X, B.Y, B.Z);
                     Add_Segment_3D (S, A, B);
                     Draw (S, With_Chain);
                  end;
               end if;
               Emit
                 ("vector " & Img (D.DX) & " " & Img (D.DY) & " " & Img (D.DZ));
            end;
         end;

      elsif Op = "equal" then
         declare
            A : constant Parsed_Point := Next_Point (R, Defs);
            B : constant Parsed_Point := Next_Point (R, Defs);

         begin
            Require_3D (A);
            Require_3D (B);
            Require_End (R);
            declare
               Pa : constant Point_3D := (C (A.X), C (A.Y), C (A.Z));
               Pb : constant Point_3D := (C (B.X), C (B.Y), C (B.Z));

            begin
               if Length (Draw_Path) > 0 then
                  declare
                     S : Scene := New_Scene;

                  begin
                     Add_Point (S, To_String (A.Name), A.X, A.Y, A.Z);
                     Add_Point (S, To_String (B.Name), B.X, B.Y, B.Z);
                     Draw (S, With_Chain);
                  end;
               end if;
               if Pa = Pb then
                  Emit ("equal true");

               else
                  Emit ("equal false");

               end if;
            end;
         end;

      elsif Op = "orientation" then
         declare
            A : constant Parsed_Point := Next_Point (R, Defs);
            B : constant Parsed_Point := Next_Point (R, Defs);
            P : constant Parsed_Point := Next_Point (R, Defs);

         begin
            Require_2D (A);
            Require_2D (B);
            Require_2D (P);
            Require_End (R);
            declare
               Pa : constant Point_2D := Point_Of (A);
               Pb : constant Point_2D := Point_Of (B);
               Pp : constant Point_2D := Point_Of (P);

            begin
               if Length (Draw_Path) > 0 then
                  declare
                     S : Scene := New_Scene;

                  begin
                     Add_Point (S, To_String (A.Name), A.X, A.Y, 0);
                     Add_Point (S, To_String (B.Name), B.X, B.Y, 0);
                     Add_Point (S, To_String (P.Name), P.X, P.Y, 0);
                     Add_Segment (S, A, B);
                     Add_Segment (S, B, P);
                     Draw (S, With_Chain);
                  end;
               end if;
               case Orientation (Pa, Pb, Pp) is
                  when Counter_Clockwise =>
                     Emit ("orientation counter_clockwise");

                  when Clockwise =>
                     Emit ("orientation clockwise");

                  when Collinear =>
                     Emit ("orientation collinear");

               end case;
            end;
         end;

      elsif Op = "intersect" then
         declare
            A : constant Parsed_Point := Next_Point (R, Defs);
            B : constant Parsed_Point := Next_Point (R, Defs);
            C : constant Parsed_Point := Next_Point (R, Defs);
            D : constant Parsed_Point := Next_Point (R, Defs);

         begin
            Require_2D (A);
            Require_2D (B);
            Require_2D (C);
            Require_2D (D);
            Require_End (R);
            declare
               S1 : constant Segment_2D :=
                 (Point_Of (A), Point_Of (B));
               S2 : constant Segment_2D :=
                 (Point_Of (C), Point_Of (D));
               Res : constant Intersection_Result := Intersection (S1, S2);

            begin
               if Length (Draw_Path) > 0 then
                  declare
                     S : Scene := New_Scene;

                  begin
                     Add_Point (S, To_String (A.Name), A.X, A.Y, 0);
                     Add_Point (S, To_String (B.Name), B.X, B.Y, 0);
                     Add_Point (S, To_String (C.Name), C.X, C.Y, 0);
                     Add_Point (S, To_String (D.Name), D.X, D.Y, 0);
                     Add_Segment (S, A, B);
                     Add_Segment (S, C, D);
                     if Res.Kind = Point_Intersection then
                        Add_Point (S, "P", Integer (Res.Point.X),
                                   Integer (Res.Point.Y), 0);

                     end if;
                     Draw (S, With_Chain);
                  end;
               end if;
               case Res.Kind is
                  when No_Intersection =>
                     Emit ("intersection no_intersection");
                  when Point_Intersection =>
                     Emit
                       ("intersection point_intersection " & Img (Res.Point.X)
                        & " " & Img (Res.Point.Y));
                  when Off_Grid_Crossing =>
                     Emit ("intersection off_grid_crossing");
                  when Overlap =>
                     Emit
                       ("intersection overlap " & Img (Res.Overlap.From_Point.X)
                        & " " & Img (Res.Overlap.From_Point.Y) & " "
                        & Img (Res.Overlap.To_Point.X) & " "
                        & Img (Res.Overlap.To_Point.Y));

               end case;
            end;
         end;

      elsif Op = "contour_continuity" then
         declare
            Chain : constant Point_Vectors.Vector := Parse_Chain (R, Defs);

         begin
            Require_End (R);
            if Natural (Chain.Length) mod 2 /= 0 then
               raise Usage_Error;

            end if;
            declare
               S         : Scene := New_Scene;
               Continuous : Boolean := True;

            begin
               if Length (Draw_Path) > 0 then
                  Draw_Chain (S, Chain);
               end if;
               for I in 1 .. Natural (Chain.Length) / 2 - 1 loop
                  if Point_Of (Chain (2 * I)) /= Point_Of (Chain (2 * I + 1))
                  then
                     Continuous := False;

                  end if;
               end loop;
               if Continuous then
                  Emit ("continuity continuous");

               else
                  Emit ("continuity discontinuous");

               end if;
               Draw (S, With_Chain);
            end;
         end;

      elsif Op = "contour_closure" then
         declare
            Chain : constant Point_Vectors.Vector := Parse_Chain (R, Defs);

         begin
            Require_End (R);
            declare
               N   : constant Natural := Natural (Chain.Length);
               Seq : Segment_Sequence_2D (N);

            begin
               for I in 1 .. N loop
                  Seq.Points (I) := Point_Of (Chain (I));
               end loop;
               if Length (Draw_Path) > 0 then
                  declare
                     S : Scene := New_Scene;

                  begin
                     Draw_Chain (S, Chain);
                     Draw (S, With_Chain);
                  end;
               end if;
               if Is_Closed (Seq) then
                  Emit ("closure closed");

               else
                  Emit ("closure open");

               end if;
            end;
         end;

      elsif Op = "contour_orientation" then
         declare
            Chain : constant Point_Vectors.Vector := Parse_Chain (R, Defs);

         begin
            Require_End (R);
            declare
               N   : constant Natural := Natural (Chain.Length);
               Seq : Segment_Sequence_2D (N);

            begin
               for I in 1 .. N loop
                  Seq.Points (I) := Point_Of (Chain (I));
               end loop;
               if Length (Draw_Path) > 0 then
                  declare
                     S : Scene := New_Scene;

                  begin
                     Draw_Chain (S, Chain);
                     Draw (S, With_Chain);
                  end;
               end if;
               if N < 3 then
                  Emit ("error: at least 3 points required for orientation");
                  Set_Exit_Status (Failure);

               elsif not Is_Closed (Seq) then
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
            end;
         end;

      elsif Op = "contour_self_intersects" then
         declare
            Chain : constant Point_Vectors.Vector := Parse_Chain (R, Defs);

         begin
            Require_End (R);
            declare
               N   : constant Natural := Natural (Chain.Length);
               Seq : Segment_Sequence_2D (N);

            begin
               for I in 1 .. N loop
                  Seq.Points (I) := Point_Of (Chain (I));
               end loop;
               if Length (Draw_Path) > 0 then
                  declare
                     S : Scene := New_Scene;

                  begin
                     Draw_Chain (S, Chain);
                     Draw (S, With_Chain);
                  end;
               end if;
               if Self_Intersects (Seq) then
                  Emit ("true");

               else
                  Emit ("false");

               end if;
            end;
         end;

      elsif Op = "contour_valid" then
         declare
            Chain : constant Point_Vectors.Vector := Parse_Chain (R, Defs);

         begin
            Require_End (R);
            declare
               N   : constant Natural := Natural (Chain.Length);
               Seq : Segment_Sequence_2D (N);

            begin
               for I in 1 .. N loop
                  Seq.Points (I) := Point_Of (Chain (I));
               end loop;
               if Length (Draw_Path) > 0 then
                  declare
                     S : Scene := New_Scene;

                  begin
                     Draw_Chain (S, Chain);
                     Draw (S, With_Chain);
                  end;
               end if;
               if Is_Valid (Seq) then
                  Emit ("true");

               else
                  Emit ("false");

               end if;
            end;
         end;

      elsif Op = "contour_no_flat_turns" then
         declare
            Chain : constant Point_Vectors.Vector := Parse_Chain (R, Defs);

         begin
            Require_End (R);
            declare
               N   : constant Natural := Natural (Chain.Length);
               Seq : Segment_Sequence_2D (N);

            begin
               for I in 1 .. N loop
                  Seq.Points (I) := Point_Of (Chain (I));
               end loop;
               if Length (Draw_Path) > 0 then
                  declare
                     S : Scene := New_Scene;

                  begin
                     Draw_Chain (S, Chain);
                     Draw (S, With_Chain);
                  end;
               end if;
               if Has_No_Flat_Turns (Seq) then
                  Emit ("true");

               else
                  Emit ("false");

               end if;
            end;
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
      if Argument (I) = "--input" or else Argument (I) = "--output"
        or else Argument (I) = "--draw"
      then
         declare
            Is_Input : constant Boolean := Argument (I) = "--input";

         begin
            I := I + 1;
            if I > Argument_Count then
               raise Usage_Error;

            end if;
            if Is_Input then
               Input_Path := To_Unbounded_String (Argument (I));

            elsif Argument (I - 1) = "--output" then
               Output_Path := To_Unbounded_String (Argument (I));

            else
               Draw_Path := To_Unbounded_String (Argument (I));

            end if;
         end;

      elsif Argument (I) = "--draw-with" then
         I := I + 1;
         if I > Argument_Count then
            raise Usage_Error;

         end if;
         Draw_With := To_Unbounded_String (Argument (I));

      elsif Argument (I) = "--draw-short-labels" then
         Short_Labels := True;

      elsif Argument (I) = "--help" or else Argument (I) = "-h" then
         Emit ("usage: topocli OPERATION POINTS [--output FILE] "
               & "[--draw FILE] [--draw-with POINTS] "
               & "[--draw-short-labels]");
         Emit ("       topocli --input FILE [--output FILE] [--draw FILE]");
         Emit ("points are named: NAME=(X, Y) or NAME=(X, Y, Z); a bare NAME");
         Emit ("refers to a point defined earlier in the same command");
         Emit ("--draw writes the SVG diagram of the command data and");
         Emit ("results; --draw-with adds extra named points to the diagram;");
         Emit ("--draw-short-labels names the vectors S1, S2, ...");
         Emit ("operations: translate, displacement, equal, orientation, "
               & "intersect");
         Emit ("             contour_continuity, contour_closure, "
               & "contour_orientation");
         Emit ("             contour_self_intersects, contour_valid, "
               & "contour_no_flat_turns");
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
      Put_Line (Standard_Error, "try 'topocli --help'");
      Set_Exit_Status (Failure);
   when Name_Error =>
      Put_Line (Standard_Error, "error: input or output file cannot be opened");
      Set_Exit_Status (Failure);

end TopoCLI;

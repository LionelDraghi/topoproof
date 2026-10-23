-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with Ada.Command_Line;                use Ada.Command_Line;
with Ada.Containers.Indefinite_Vectors;
with Ada.Exceptions;
with Ada.Strings;                     use Ada.Strings;
with Ada.Strings.Fixed;               use Ada.Strings.Fixed;
with Ada.Strings.Unbounded;           use Ada.Strings.Unbounded;
with Ada.Text_IO;                     use Ada.Text_IO;
with HAC_Sys.Builder;
with HAC_Sys.PCode.Interpreter;
with TopoProof.Geometry.Intersections; use TopoProof.Geometry.Intersections;
with TopoProof.Geometry.Orientations;  use TopoProof.Geometry.Orientations;
with TopoProof.Geometry.Segments;      use TopoProof.Geometry.Segments;
with TopoProof.Geometry.Segment_Sequences;
use TopoProof.Geometry.Segment_Sequences;
with TopoProof.Geometry.Points;       use TopoProof.Geometry.Points;
with TopoProof.Geometry.Translations; use TopoProof.Geometry.Translations;
with TopoProof.Geometry.Vectors;      use TopoProof.Geometry.Vectors;
with TopoProof.Numerics;              use TopoProof.Numerics;
with TopoProof.Topology.Edges;        use TopoProof.Topology.Edges;
with TopoProof.Topology.Faces;        use TopoProof.Topology.Faces;
with TopoProof.Topology.Loops;        use TopoProof.Topology.Loops;
with TopoProof.Topology.Vertices;    use TopoProof.Topology.Vertices;
with TopoScript_API;
with TopoScript_Diagnostics;
with TopoScript_Wrapper;
with TopoDiagnostics;                 use TopoDiagnostics;
with Topodraw;                        use Topodraw;

procedure TopoCLI is
   Usage_Error             : exception;
   Input_Path, Output_Path : Unbounded_String;
   Draw_Path               : Unbounded_String;
   Draw_With               : Unbounded_String;
   Short_Labels            : Boolean := False;

   --  The file of --output, created once per run: every line of the
   --  canonical output accumulates in it, instead of each line
   --  recreating the file and erasing the previous ones.
   Output_File : File_Type;

   procedure Emit (S : String);

   procedure Emit (S : String) is
   begin
      if Length (Output_Path) = 0 then
         Put_Line (S);

      else
         if not Is_Open (Output_File) then
            Create (Output_File, Out_File, To_String (Output_Path));
         end if;
         Put_Line (Output_File, S);

      end if;
   end Emit;

   --  Close the output file, if the run opened one.
   procedure Close_Output;

   procedure Close_Output is
   begin
      if Is_Open (Output_File) then
         Close (Output_File);

      end if;
   end Close_Output;

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

   --  The handles of the vertices created by the edge command, parallel
   --  to the names of Point_Vectors.
   package Handle_Vectors is new Ada.Containers.Indefinite_Vectors
     (Positive, Vertex_Handle);

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
           (Name => To_Unbounded_String (Name), X => X, Y => Y, Z => Z,
            others => <>));
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
            Label     => To_Unbounded_String (Label),
            others    => <>));
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

   --  The number of distinct names in a chain: a repeated name is one
   --  vertex.
   function Distinct_Names (Chain : Point_Vectors.Vector) return Natural is
      Distinct : Natural := 0;
      Seen     : Boolean;

   begin
      for I in 1 .. Natural (Chain.Length) loop
         Seen := False;
         for J in 1 .. I - 1 loop
            if To_String (Chain (J).Name) = To_String (Chain (I).Name) then
               Seen := True;

            end if;
         end loop;
         if not Seen then
            Distinct := Distinct + 1;

         end if;
      end loop;
      return Distinct;
   end Distinct_Names;

   --  Return the handle of the vertex designated by P, creating the
   --  vertex on first use: within one command, a name designates one
   --  vertex. The vertex store capacity is the number of distinct
   --  names, so the kernel precondition of Create holds structurally.
   --  The vertex line is emitted at creation, and the vertex joins the
   --  diagram under its name.
   procedure Ensure_Vertex
      (Store   : in out Vertex_Store;
       Names   : in out Point_Vectors.Vector;
       Handles : in out Handle_Vectors.Vector;
       S       : in out Scene;
       P       :        Parsed_Point;
       H       :    out Vertex_Handle)
   is
   begin
      for K in 1 .. Natural (Names.Length) loop
         if To_String (Names (K).Name) = To_String (P.Name) then
            H := Handles (K);
            return;

         end if;
      end loop;
      Create (Store, Point_Of (P), H);
      Names.Append (P);
      Handles.Append (H);
      if Length (Draw_Path) > 0 then
         Add_Point (S, To_String (P.Name), P.X, P.Y, 0);
      end if;
      Emit
        ("vertex " & Img (H) & " point "
         & Img (Point_Of (Store, H).X) & " "
         & Img (Point_Of (Store, H).Y));
   end Ensure_Vertex;

   --  The closed point sequence of a command chain: the chain points,
   --  in order.
   function Sequence_Of (Chain : Point_Vectors.Vector)
      return Segment_Sequence_2D
   is
      Seq : Segment_Sequence_2D (Natural (Chain.Length));

   begin
      for I in 1 .. Natural (Chain.Length) loop
         Seq.Points (I) := Point_Of (Chain (I));
      end loop;
      return Seq;
   end Sequence_Of;

   --  Write the diagram of one contour command: the chain of the
   --  command, plus the extra geometry of --draw-with.
   procedure Draw_Contour
      (Chain      : Point_Vectors.Vector;
       With_Chain : Point_Vectors.Vector)
   is
   begin
      if Length (Draw_Path) > 0 then
         declare
            S : Scene := New_Scene;

         begin
            Draw_Chain (S, Chain);
            Draw (S, With_Chain);
         end;
      end if;
   end Draw_Contour;

   --  Build the vertex and edge stores of the loop and face commands
   --  from their command chain: the chain closes when it returns to its
   --  first name, one vertex is created per distinct name, and one edge
   --  per consecutive pair, so the chain of N points builds N - 1 edges.
   --  The vertex and edge lines are emitted as they are created, and the
   --  diagram grows alongside. The degeneracy precondition of the edge
   --  is checked before the call: the kernel contract is never violated
   --  from the command line, and a degenerate edge stops the
   --  construction with its diagnostic, leaving OK to False.
   procedure Build_Edge_Chain
      (Chain   :        Point_Vectors.Vector;
       Store   : in out Vertex_Store;
       Edges   : in out Edge_Store;
       Handles :    out Edge_Handle_Array;
       S       : in out Scene;
       OK      :    out Boolean)
   is
      Names    : Point_Vectors.Vector;
      Vertices : Handle_Vectors.Vector;
      Tokens   : Handle_Vectors.Vector;

   begin
      OK := True;
      for I in 1 .. Natural (Chain.Length) loop
         declare
            H : Vertex_Handle;

         begin
            Ensure_Vertex (Store, Names, Vertices, S, Chain (I), H);
            Tokens.Append (H);
         end;
      end loop;
      for I in 2 .. Natural (Chain.Length) loop
         if Tokens (I - 1) = Tokens (I) then
            Emit ("error: degenerate edge");
            Set_Exit_Status (Failure);
            OK := False;
            return;

         end if;
         declare
            E : Edge_Handle;

         begin
            Create (Edges, Store, Tokens (I - 1), Tokens (I), E);
            Handles (I - 1) := E;
            if Length (Draw_Path) > 0 then
               Add_Segment (S, Chain (I - 1), Chain (I));
            end if;
            Emit
              ("edge " & Img (E) & " vertex " & Img (Tokens (I - 1))
               & " vertex " & Img (Tokens (I)));
         end;
      end loop;
   end Build_Edge_Chain;

   ---------------------------------------------------------------------------
   --  One procedure per command
   --
   --  Each handler runs at one level of abstraction: parse the operands
   --  from R, draw the scene of the command, run the kernel operation,
   --  emit the canonical result or the diagnostic. R and Defs are shared
   --  with the caller: the point names defined by one command are
   --  visible to the whole command line.
   ---------------------------------------------------------------------------

   procedure Handle_Translate
      (R          : in out Unbounded_String;
       Defs       : in out Point_Vectors.Vector;
       With_Chain :        Point_Vectors.Vector)
   is
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
   end Handle_Translate;

   procedure Handle_Displacement
      (R          : in out Unbounded_String;
       Defs       : in out Point_Vectors.Vector;
       With_Chain :        Point_Vectors.Vector)
   is
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
   end Handle_Displacement;

   procedure Handle_Equal
      (R          : in out Unbounded_String;
       Defs       : in out Point_Vectors.Vector;
       With_Chain :        Point_Vectors.Vector)
   is
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
   end Handle_Equal;

   procedure Handle_Orientation
      (R          : in out Unbounded_String;
       Defs       : in out Point_Vectors.Vector;
       With_Chain :        Point_Vectors.Vector)
   is
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
   end Handle_Orientation;

   procedure Handle_Intersect
      (R          : in out Unbounded_String;
       Defs       : in out Point_Vectors.Vector;
       With_Chain :        Point_Vectors.Vector)
   is
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
   end Handle_Intersect;

   procedure Handle_Contour_Continuity
      (R          : in out Unbounded_String;
       Defs       : in out Point_Vectors.Vector;
       With_Chain :        Point_Vectors.Vector)
   is
      Chain : constant Point_Vectors.Vector := Parse_Chain (R, Defs);

   begin
      Require_End (R);
      if Natural (Chain.Length) mod 2 /= 0 then
         raise Usage_Error;

      end if;
      declare
         Continuous : Boolean := True;

      begin
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
         Draw_Contour (Chain, With_Chain);
      end;
   end Handle_Contour_Continuity;

   procedure Handle_Contour_Closure
      (R          : in out Unbounded_String;
       Defs       : in out Point_Vectors.Vector;
       With_Chain :        Point_Vectors.Vector)
   is
      Chain : constant Point_Vectors.Vector := Parse_Chain (R, Defs);
      Seq   : constant Segment_Sequence_2D := Sequence_Of (Chain);

   begin
      Require_End (R);
      Draw_Contour (Chain, With_Chain);
      if Is_Closed (Seq) then
         Emit ("closure closed");

      else
         Emit ("closure open");

      end if;
   end Handle_Contour_Closure;

   procedure Handle_Contour_Orientation
      (R          : in out Unbounded_String;
       Defs       : in out Point_Vectors.Vector;
       With_Chain :        Point_Vectors.Vector)
   is
      Chain : constant Point_Vectors.Vector := Parse_Chain (R, Defs);
      Seq   : constant Segment_Sequence_2D := Sequence_Of (Chain);

   begin
      Require_End (R);
      Draw_Contour (Chain, With_Chain);
      if Natural (Chain.Length) < 3 then
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
   end Handle_Contour_Orientation;

   procedure Handle_Contour_Self_Intersects
      (R          : in out Unbounded_String;
       Defs       : in out Point_Vectors.Vector;
       With_Chain :        Point_Vectors.Vector)
   is
      Chain : constant Point_Vectors.Vector := Parse_Chain (R, Defs);
      Seq   : constant Segment_Sequence_2D := Sequence_Of (Chain);

   begin
      Require_End (R);
      Draw_Contour (Chain, With_Chain);
      if Self_Intersects (Seq) then
         Emit ("true");

      else
         Emit ("false");

      end if;
   end Handle_Contour_Self_Intersects;

   procedure Handle_Contour_Valid
      (R          : in out Unbounded_String;
       Defs       : in out Point_Vectors.Vector;
       With_Chain :        Point_Vectors.Vector)
   is
      Chain : constant Point_Vectors.Vector := Parse_Chain (R, Defs);
      Seq   : constant Segment_Sequence_2D := Sequence_Of (Chain);

   begin
      Require_End (R);
      Draw_Contour (Chain, With_Chain);
      if Is_Valid (Seq) then
         Emit ("true");

      else
         Emit ("false");

      end if;
   end Handle_Contour_Valid;

   procedure Handle_Contour_No_Flat_Turns
      (R          : in out Unbounded_String;
       Defs       : in out Point_Vectors.Vector;
       With_Chain :        Point_Vectors.Vector)
   is
      Chain : constant Point_Vectors.Vector := Parse_Chain (R, Defs);
      Seq   : constant Segment_Sequence_2D := Sequence_Of (Chain);

   begin
      Require_End (R);
      Draw_Contour (Chain, With_Chain);
      if Has_No_Flat_Turns (Seq) then
         Emit ("true");

      else
         Emit ("false");

      end if;
   end Handle_Contour_No_Flat_Turns;

   procedure Handle_Vertex
      (R          : in out Unbounded_String;
       Defs       : in out Point_Vectors.Vector;
       With_Chain :        Point_Vectors.Vector)
   is
      Chain : constant Point_Vectors.Vector := Parse_Chain (R, Defs);

   begin
      Require_End (R);
      if Natural (Chain.Length) = 0 then
         raise Usage_Error;

      end if;
      for C of Chain loop
         Require_2D (C);
      end loop;
      --  One command builds one store, sized exactly for its
      --  points: the capacity is known before any creation, so the
      --  kernel precondition of Create holds structurally.
      if Natural (Chain.Length) > Max_Vertices then
         Emit ("error: too many vertices for one store");
         Set_Exit_Status (Failure);
         return;

      end if;
      declare
         Store : Vertex_Store (Vertex_Count_Range (Natural (Chain.Length)));
         H     : Vertex_Handle;
         S     : Scene := New_Scene;

      begin
         for I in 1 .. Natural (Chain.Length) loop
            Create (Store, Point_Of (Chain (I)), H);
            if Length (Draw_Path) > 0 then
               Add_Point (S, "V" & Img (H), Chain (I).X, Chain (I).Y, 0);
            end if;
            Emit
              ("vertex " & Img (H) & " point "
               & Img (Point_Of (Store, H).X) & " "
               & Img (Point_Of (Store, H).Y));
         end loop;
         Draw (S, With_Chain);
      end;
   end Handle_Vertex;

   procedure Handle_Edge
      (R          : in out Unbounded_String;
       Defs       : in out Point_Vectors.Vector;
       With_Chain :        Point_Vectors.Vector)
   is
      Chain : constant Point_Vectors.Vector := Parse_Chain (R, Defs);

   begin
      Require_End (R);
      if Natural (Chain.Length) = 0
        or else Natural (Chain.Length) mod 2 /= 0
      then
         raise Usage_Error;

      end if;
      for C of Chain loop
         Require_2D (C);
      end loop;
      --  Within the command, a name designates one vertex: a
      --  repeated name is the same handle, never a new vertex.
      --  Distinct names at the same position are distinct
      --  vertices: identity is not position. One store holds
      --  the distinct names, the other one edge per pair.
      declare
         Store   : Vertex_Store (Vertex_Count_Range (Distinct_Names (Chain)));
         Edges   : Edge_Store (Edge_Count_Range (Natural (Chain.Length) / 2));
         Names   : Point_Vectors.Vector;
         Handles : Handle_Vectors.Vector;
         S       : Scene := New_Scene;

      begin
         for P in 1 .. Natural (Chain.Length) / 2 loop
            declare
               A, B : Vertex_Handle;
               E    : Edge_Handle;

            begin
               Ensure_Vertex (Store, Names, Handles, S, Chain (2 * P - 1), A);
               Ensure_Vertex (Store, Names, Handles, S, Chain (2 * P), B);
               --  The degeneracy precondition is checked before
               --  the call: the kernel contract is never
               --  violated from the command line.
               if A = B then
                  Emit ("error: degenerate edge");
                  Set_Exit_Status (Failure);
                  return;

               end if;
               Create (Edges, Store, A, B, E);
               if Length (Draw_Path) > 0 then
                  Add_Segment (S, Chain (2 * P - 1), Chain (2 * P));
               end if;
               Emit
                 ("edge " & Img (E) & " vertex " & Img (A) & " vertex "
                  & Img (B));
            end;
         end loop;
         Draw (S, With_Chain);
      end;
   end Handle_Edge;

   procedure Handle_Loop
      (R          : in out Unbounded_String;
       Defs       : in out Point_Vectors.Vector;
       With_Chain :        Point_Vectors.Vector)
   is
      Chain : constant Point_Vectors.Vector := Parse_Chain (R, Defs);
      N     : constant Natural := Natural (Chain.Length);

   begin
      Require_End (R);
      if N < 2 then
         raise Usage_Error;

      end if;
      for C of Chain loop
         Require_2D (C);
      end loop;
      --  The loop of N - 1 edges must fit the longest loop.
      if N - 1 > Max_Loop_Length then
         Emit ("error: too many edges for one loop");
         Set_Exit_Status (Failure);
         return;

      end if;
      declare
         Store   : Vertex_Store (Vertex_Count_Range (Distinct_Names (Chain)));
         Edges   : Edge_Store (Edge_Count_Range (N - 1));
         Handles : Edge_Handle_Array (1 .. N - 1);
         S       : Scene := New_Scene;
         OK      : Boolean;

      begin
         Build_Edge_Chain (Chain, Store, Edges, Handles, S, OK);
         if not OK then
            return;

         end if;
         declare
            --  The loop is classified exactly before it is
            --  built: only a valid loop reaches Make_Loop, so
            --  the kernel precondition holds.
            Status : constant Loop_Validity :=
               Classify_Loop (Edges, Store, Handles);

         begin
            case Status is
               when Valid_Loop =>
                  declare
                     L : constant Loop_2D := Make_Loop (Edges, Store, Handles);

                  begin
                     case Loop_Orientation (Edges, Store, L) is
                        when Counter_Clockwise =>
                           Emit ("loop closed counter_clockwise");
                        when Clockwise =>
                           Emit ("loop closed clockwise");
                        when Degenerate =>
                           Emit ("loop closed degenerate");

                     end case;
                  end;
               when Orphan_Edge | Missing_Endpoint | Open_Chain
                  | Disconnected_Chain | Degenerate_Support
               =>
                  Emit (Loop_Diagnostic (Status));
                  Set_Exit_Status (Failure);

            end case;
         end;
         Draw (S, With_Chain);
      end;
   end Handle_Loop;

   procedure Handle_Face
      (R          : in out Unbounded_String;
       Defs       : in out Point_Vectors.Vector;
       With_Chain :        Point_Vectors.Vector)
   is
      Chain : constant Point_Vectors.Vector := Parse_Chain (R, Defs);
      N     : constant Natural := Natural (Chain.Length);

   begin
      Require_End (R);
      if N < 2 then
         raise Usage_Error;

      end if;
      for C of Chain loop
         Require_2D (C);
      end loop;
      --  Same construction as the loop command. The face
      --  classification then completes the loop classification.
      if N - 1 > Max_Loop_Length then
         Emit ("error: too many edges for one loop");
         Set_Exit_Status (Failure);
         return;

      end if;
      declare
         Store   : Vertex_Store (Vertex_Count_Range (Distinct_Names (Chain)));
         Edges   : Edge_Store (Edge_Count_Range (N - 1));
         Handles : Edge_Handle_Array (1 .. N - 1);
         S       : Scene := New_Scene;
         OK      : Boolean;

      begin
         Build_Edge_Chain (Chain, Store, Edges, Handles, S, OK);
         if not OK then
            return;

         end if;
         declare
            --  The chain is classified exactly, then a valid
            --  loop is classified again as a face boundary:
            --  only a valid boundary reaches Make_Face, so the
            --  kernel precondition holds.
            Status : constant Loop_Validity :=
               Classify_Loop (Edges, Store, Handles);

         begin
            if Status /= Valid_Loop then
               Emit (Loop_Diagnostic (Status));
               Set_Exit_Status (Failure);

            else
               declare
                  L : constant Loop_2D := Make_Loop (Edges, Store, Handles);

               begin
                  case Classify_Face (Edges, Store, L) is
                     when Valid_Face =>
                        declare
                           F : constant Face_2D :=
                              Make_Face (Edges, Store, L);

                        begin
                           case Face_Orientation (Edges, Store, F) is
                              when Counter_Clockwise =>
                                 Emit ("face counter_clockwise");
                              when Clockwise =>
                                 Emit ("face clockwise");
                              when Degenerate =>
                                 Emit ("face degenerate");

                           end case;
                        end;
                     when Invalid_Boundary =>
                        Emit (Face_Diagnostic (Invalid_Boundary));
                        Set_Exit_Status (Failure);
                     when Degenerate_Boundary =>
                        Emit (Face_Diagnostic (Degenerate_Boundary));
                        Set_Exit_Status (Failure);

                  end case;
               end;
            end if;
         end;
         Draw (S, With_Chain);
      end;
   end Handle_Face;

   --  Dispatch one command line to its handler: the operand tokens are
   --  consumed from R, the operation runs, and the canonical result or
   --  the diagnostic is emitted.
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
         Handle_Translate (R, Defs, With_Chain);

      elsif Op = "displacement" then
         Handle_Displacement (R, Defs, With_Chain);

      elsif Op = "equal" then
         Handle_Equal (R, Defs, With_Chain);

      elsif Op = "orientation" then
         Handle_Orientation (R, Defs, With_Chain);

      elsif Op = "intersect" then
         Handle_Intersect (R, Defs, With_Chain);

      elsif Op = "contour_continuity" then
         Handle_Contour_Continuity (R, Defs, With_Chain);

      elsif Op = "contour_closure" then
         Handle_Contour_Closure (R, Defs, With_Chain);

      elsif Op = "contour_orientation" then
         Handle_Contour_Orientation (R, Defs, With_Chain);

      elsif Op = "contour_self_intersects" then
         Handle_Contour_Self_Intersects (R, Defs, With_Chain);

      elsif Op = "contour_valid" then
         Handle_Contour_Valid (R, Defs, With_Chain);

      elsif Op = "contour_no_flat_turns" then
         Handle_Contour_No_Flat_Turns (R, Defs, With_Chain);

      elsif Op = "vertex" then
         Handle_Vertex (R, Defs, With_Chain);

      elsif Op = "edge" then
         Handle_Edge (R, Defs, With_Chain);

      elsif Op = "loop" then
         Handle_Loop (R, Defs, With_Chain);

      elsif Op = "face" then
         Handle_Face (R, Defs, With_Chain);

      else
         raise Usage_Error;

      end if;

   exception
      when Constraint_Error =>
         Emit ("error: invalid or out-of-range numeric parameter");
         Set_Exit_Status (Failure);
   end Execute;

   --  TopoScript (development plan, Milestone 6): run FILE.topo, a
   --  fragment of declarations followed by statements, through the
   --  wrapper and the embedded HAC interpreter. The verdict keeps the
   --  topocli conventions: the canonical result goes to standard
   --  output, the diagnostics to standard error, and the process status
   --  carries the outcome.
   procedure Run_Script (Path : String) is
   begin
      declare
         Fragment : Unbounded_String;
         F        : File_Type;
      begin
         Open (F, In_File, Path);
         while not End_Of_File (F) loop
            Append (Fragment, Get_Line (F));
            Append (Fragment, ASCII.LF);
         end loop;
         Close (F);

         declare
            Wrapped : TopoScript_Wrapper.Wrapped_Source;
         begin
            TopoScript_Wrapper.Generate
              (To_String (Fragment), Path, Wrapped);
            declare
               BD : HAC_Sys.Builder.Build_Data;
            begin
               TopoScript_API.Register_All (BD);
               TopoScript_Diagnostics.Set_Mapping
                 (Path,
                  Wrapped.Declaration_Skip,
                  Wrapped.Begin_Line,
                  Wrapped.Statement_Adjust);
               HAC_Sys.Builder.Set_Message_Feedbacks
                 (BD,
                  (pipe         => TopoScript_Diagnostics.Pipe'Access,
                   progress     => null,
                   detail_level => 0));
               TopoScript_Wrapper.Set_Source (To_String (Wrapped.Source));
               --  The virtual source name fixes the main unit name
               --  expected by the HAC librarian; the fragment path is
               --  reported by the diagnostics pipe instead.
               BD.Set_Main_Source_Stream
                 (TopoScript_Wrapper.Stream, "toposcript_run.adb", 0);
               BD.Build_Main;

               if BD.Build_Successful then
                  declare
                     Post_Mortem :
                       HAC_Sys.PCode.Interpreter.Post_Mortem_Data;
                  begin
                     HAC_Sys.PCode.Interpreter.Interpret_on_Current_IO
                       (BD, 0, Path, Post_Mortem);
                     if HAC_Sys.PCode.Interpreter.Is_Exception_Raised
                       (Post_Mortem.Unhandled)
                     then
                        Put_Line
                          (Standard_Error,
                           "error: " &
                           HAC_Sys.PCode.Interpreter.Image
                             (Post_Mortem.Unhandled) &
                           ": " &
                           HAC_Sys.PCode.Interpreter.Message
                             (Post_Mortem.Unhandled));
                        Set_Exit_Status (Failure);

                     elsif TopoScript_API.Last_Failure /= "" then
                        Put_Line
                          (Standard_Error, TopoScript_API.Last_Failure);
                        Set_Exit_Status (Failure);

                     else
                        Set_Exit_Status (Success);
                     end if;
                  end;

               else
                  --  The compilation messages went to standard error
                  --  already, through the diagnostics pipe.
                  Set_Exit_Status (Failure);
               end if;
            end;

         exception
            when E : TopoScript_Wrapper.Wrapper_Error =>
               Put_Line
                 (Standard_Error, Ada.Exceptions.Exception_Message (E));
               Set_Exit_Status (Failure);
         end;

      exception
         when Name_Error | Use_Error =>
            Put_Line (Standard_Error, "error: file not found: " & Path);
            Set_Exit_Status (Failure);
      end;
   end Run_Script;

   Args : Unbounded_String;
   I    : Positive := 1;

begin
   --  TopoScript: `topocli run FILE.topo` owns the whole command line.
   if Argument_Count = 2 and then Argument (1) = "run" then
      Run_Script (Argument (2));
      return;
   end if;

   while I <= Argument_Count loop
      if Argument (I) = "--input" or else Argument (I) = "--output"
        or else Argument (I) = "--draw"
      then
         declare
            Option : constant String := Argument (I);

         begin
            I := I + 1;
            if I > Argument_Count then
               raise Usage_Error;

            end if;
            if Option = "--input" then
               Input_Path := To_Unbounded_String (Argument (I));

            elsif Option = "--output" then
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
         Emit ("       topocli run FILE.topo (TopoScript source)");
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
         Emit ("             vertex, edge, loop, face");
         Close_Output;
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
   Close_Output;

exception
   when Usage_Error =>
      Close_Output;
      Put_Line (Standard_Error, "error: invalid command line");
      Put_Line (Standard_Error, "try 'topocli --help'");
      Set_Exit_Status (Failure);
   when Name_Error =>
      Close_Output;
      Put_Line (Standard_Error, "error: input or output file cannot be opened");
      Set_Exit_Status (Failure);

end TopoCLI;

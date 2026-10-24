-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Maps;
with Ada.Strings.Unbounded;           use Ada.Strings.Unbounded;
with Ada.Unchecked_Deallocation;

package body TopoScript_Wrapper is

   use type Ada.Streams.Stream_Element_Offset;

   Whitespace : constant Ada.Strings.Maps.Character_Set :=
     Ada.Strings.Maps.To_Set (" " & ASCII.CR & ASCII.HT);

   function Trimmed (Line : String) return String is
   begin
      return Ada.Strings.Fixed.Trim (Line, Whitespace, Whitespace);
   end Trimmed;

   function Is_Neutral (Line : String) return Boolean is
      T : constant String := Trimmed (Line);
   begin
      return T'Length = 0
        or else (T'Length >= 2
                 and then T (T'First .. T'First + 1) = "--");
   end Is_Neutral;

   --  The line cut at the first comment marker outside a string
   --  literal, so a trailing comment does not hide the final ';'.
   function Comment_Stripped (Line : String) return String is
      In_String : Boolean := False;
   begin
      for I in Line'Range loop
         if In_String then
            In_String := Line (I) /= '"';
         elsif Line (I) = '"' then
            In_String := True;
         elsif Line (I) = '-'
           and then I < Line'Last
           and then Line (I + 1) = '-'
         then
            return Line (Line'First .. I - 1);
         end if;
      end loop;
      return Line;
   end Comment_Stripped;

   function Is_Word_Char (C : Character) return Boolean is
      package CH renames Ada.Characters.Handling;
   begin
      return CH.Is_Alphanumeric (C) or else C = '_';
   end Is_Word_Char;

   --  The Rank'th word of the line, lowercased, after the trailing
   --  comment is stripped; "" when there is no such word.
   function Word (Line : String; Rank : Positive) return String is
      package CH renames Ada.Characters.Handling;
      T : constant String := Trimmed (Comment_Stripped (Line));
      I : Natural := T'First;
   begin
      for R in 1 .. Rank loop
         while I <= T'Last
           and then (T (I) = ' ' or else T (I) = ASCII.HT)
         loop
            I := I + 1;
         end loop;
         if I > T'Last or else not CH.Is_Letter (T (I)) then
            return "";
         end if;
         declare
            First : constant Natural := I;
         begin
            while I <= T'Last and then Is_Word_Char (T (I)) loop
               I := I + 1;
            end loop;
            if R = Rank then
               return CH.To_Lower (T (First .. I - 1));
            end if;
         end;
      end loop;
      return "";
   end Word;

   function First_Word (Line : String) return String is
   begin
      return Word (Line, 1);
   end First_Word;

   function Second_Word (Line : String) return String is
   begin
      return Word (Line, 2);
   end Second_Word;

   --  A line ending with ';': the terminator of a single-line
   --  declaration, of a continuation, or of a unit closer.
   function Ends_With_Semicolon (Line : String) return Boolean is
      T : constant String := Trimmed (Comment_Stripped (Line));
   begin
      return T'Length > 0 and then T (T'Last) = ';';
   end Ends_With_Semicolon;

   --  A line ending with the bare word 'is', the opener of a nested
   --  unit body: its content, statements included, belongs to the
   --  declarative part of the generated unit.
   function Ends_In_Body_Opener (Line : String) return Boolean is
      package CH renames Ada.Characters.Handling;
      T : constant String :=
        CH.To_Lower (Trimmed (Comment_Stripped (Line)));
   begin
      return T'Length >= 2
        and then T (T'Last - 1 .. T'Last) = "is"
        and then (T'Length = 2
                  or else not Is_Word_Char (T (T'Last - 2)));
   end Ends_In_Body_Opener;

   function Opens_A_Body (W : String) return Boolean is
   begin
      return W = "procedure"
        or else W = "function"
        or else W = "package"
        or else W = "separate"
        or else W = "overriding";
   end Opens_A_Body;

   function Is_Declaration_Word (W : String) return Boolean is
   begin
      return W = "type"
        or else W = "subtype"
        or else W = "procedure"
        or else W = "function"
        or else W = "package"
        or else W = "generic"
        or else W = "separate"
        or else W = "use"
        or else W = "with"
        or else W = "overriding";
   end Is_Declaration_Word;

   --  An object declaration starts with one or more identifiers
   --  separated by commas, directly followed by ':' (not ':=').
   function Has_Object_Declaration_Form (Line : String) return Boolean is
      package CH renames Ada.Characters.Handling;
      T : constant String := Trimmed (Line);
      I : Natural := T'First;
   begin
      if T'Length = 0 or else not CH.Is_Letter (T (T'First)) then
         return False;
      end if;
      loop
         while I <= T'Last
           and then (CH.Is_Alphanumeric (T (I)) or else T (I) = '_')
         loop
            I := I + 1;
         end loop;
         while I <= T'Last and then T (I) = ' ' loop
            I := I + 1;
         end loop;
         exit when I > T'Last;
         if T (I) = ',' then
            I := I + 1;
            while I <= T'Last and then T (I) = ' ' loop
               I := I + 1;
            end loop;
            if I > T'Last or else not CH.Is_Letter (T (I)) then
               return False;
            end if;
         elsif T (I) = ':'
           and then (I = T'Last or else T (I + 1) /= '=')
         then
            return True;
         else
            return False;
         end if;
      end loop;
      return False;
   end Has_Object_Declaration_Form;

   --  True when the text from the given line to the first line ending
   --  with ';' assembles into an object declaration form: a
   --  declaration split across several lines stays in the declarative
   --  part, and HAC judges the assembled declaration.
   function Is_Split_Declaration
     (Fragment : String;
      From     : Positive) return Boolean
   is
      Joined : Unbounded_String;
      Start  : Positive := From;
      Finish : Natural;
   begin
      while Start <= Fragment'Last loop
         Finish := Start;
         while Finish <= Fragment'Last
           and then Fragment (Finish) /= ASCII.LF
         loop
            Finish := Finish + 1;
         end loop;
         declare
            Raw  : constant String := Fragment (Start .. Finish - 1);
            Text : constant String := Trimmed (Comment_Stripped (Raw));
         begin
            if Text'Length > 0 then
               Append (Joined, Text);
               if Text (Text'Last) = ';' then
                  return Has_Object_Declaration_Form (To_String (Joined));
               end if;
            end if;
         end;
         Start := Finish + 1;
      end loop;
      return False;
   end Is_Split_Declaration;

   --  The placement classifier: the wrapper is not an Ada analyser, it
   --  never judges the fragment (DD-003, 2026-10-24). It only decides,
   --  line by line, whether the line belongs to the declaration region
   --  or to the statement region of the generated unit: a recognised
   --  declaration form, or the continuation of one, goes to the
   --  declarative part, and a line it does not recognise goes to the
   --  statement region. A misplacement surfaces as a HAC diagnostic,
   --  mapped back to the fragment by TopoScript_Diagnostics.
   function Is_Declaration (Line : String) return Boolean is
   begin
      return Is_Declaration_Word (First_Word (Line))
        or else Has_Object_Declaration_Form (Line);
   end Is_Declaration;

   procedure Generate
     (Fragment :     String;
      Result   : out Wrapped_Source)
   is
      Source : Unbounded_String;
      Count  : Natural := 0;

      First_Statement  : Natural := 0;
      Line_Count       : Natural := 0;
      Declaration_Skip : Positive;
      Begin_Line       : Natural;

      --  The placement state: inside a multi-line declaration, inside
      --  a nested unit body, and the block nesting inside it.
      In_Continuation : Boolean := False;
      Depth           : Natural := 0;
      Unit_Begin_Seen : Boolean := False;
      Block_Depth     : Natural := 0;

      Start, Finish : Positive;

      procedure Append_Line (Content : String) is
      begin
         Append (Source, Content);
         Append (Source, ASCII.LF);
         Count := Count + 1;
      end Append_Line;

   begin
      --  Pass 1: locate the first statement line. The wrapper places
      --  the fragment, it never judges it (DD-003, 2026-10-24): the
      --  recognised declaration forms go to the declarative part,
      --  everything from the first unrecognised line on goes to the
      --  body. Nothing is rejected: HAC owns the diagnostics, and a
      --  misplacement surfaces as a HAC diagnostic mapped back to the
      --  fragment by TopoScript_Diagnostics.
      Start := Fragment'First;
      while Start <= Fragment'Last loop
         Finish := Start;
         while Finish <= Fragment'Last
           and then Fragment (Finish) /= ASCII.LF
         loop
            Finish := Finish + 1;
         end loop;
         Line_Count := Line_Count + 1;
         declare
            Line : constant String := Fragment (Start .. Finish - 1);
         begin
            if First_Statement = 0 and then not Is_Neutral (Line) then
               if In_Continuation then
                  --  A multi-line declaration continues.
                  if Ends_With_Semicolon (Line) then
                     In_Continuation := False;
                  end if;
               elsif Depth > 0 then
                  --  The content of a nested unit, its declarations
                  --  and its body, stays in the declarative part
                  --  until the unit's final end. The unit's own begin
                  --  is not a block; a block statement inside the
                  --  body pairs with its own end.
                  if First_Word (Line) = "begin" then
                     if Unit_Begin_Seen then
                        Block_Depth := Block_Depth + 1;
                     else
                        Unit_Begin_Seen := True;
                     end if;
                  elsif Ends_With_Semicolon (Line)
                    and then First_Word (Line) = "end"
                    and then Second_Word (Line) /= "if"
                    and then Second_Word (Line) /= "loop"
                    and then Second_Word (Line) /= "case"
                    and then Second_Word (Line) /= "record"
                  then
                     if Block_Depth > 0 then
                        Block_Depth := Block_Depth - 1;
                     else
                        Depth := Depth - 1;
                        Unit_Begin_Seen := False;
                     end if;
                  end if;
               elsif Is_Declaration (Line) then
                  In_Continuation := not Ends_With_Semicolon (Line);
                  if In_Continuation
                    and then Ends_In_Body_Opener (Line)
                    and then Opens_A_Body (First_Word (Line))
                  then
                     In_Continuation := False;
                     Depth := Depth + 1;
                  end if;
               else
                  --  An unrecognised line: the first line of a
                  --  construct. When the text from this line to its
                  --  first ';' assembles into an object declaration
                  --  form, the construct is a declaration split
                  --  across lines: it stays in the declarative part,
                  --  and the continuation branch consumes its lines
                  --  up to the ';'. Otherwise the line starts the
                  --  statement region, and HAC owns the diagnostic.
                  if Is_Split_Declaration (Fragment, Start) then
                     In_Continuation := True;
                  else
                     First_Statement := Line_Count;
                  end if;
               end if;
            end if;
         end;
         Start := Finish + 1;
      end loop;

      if First_Statement = 0 then
         --  The fragment declares and does nothing: the statement
         --  region is empty.
         First_Statement := Line_Count + 1;
      end if;

      --  Pass 2: assemble the wrapped compilation unit. The scripting
      --  API comes first: Ada visibility is textual, so the user
      --  declarations must follow the injected types and operations.
      Append_Line ("with HAT;");
      Append_Line ("use HAT;");
      Append_Line ("");
      Append_Line ("procedure TopoScript_Run is");
      Append_Line ("");
      Append_Line ("   --  The TopoProof scripting API, injected by the");
      Append_Line ("   --  wrapper: HAC imports procedures only, so each");
      Append_Line ("   --  operation returns its result through an out");
      Append_Line ("   --  parameter; the native callbacks are registered");
      Append_Line ("   --  by the tool.");
      Append_Line ("");
      Append_Line ("   type Point_3D is record");
      Append_Line ("      X, Y, Z : Integer;");
      Append_Line ("   end record;");
      Append_Line ("");
      Append_Line ("   type Vector_3D is record");
      Append_Line ("      DX, DY, DZ : Integer;");
      Append_Line ("   end record;");
      Append_Line ("");
      Append_Line ("   type Point_2D is record");
      Append_Line ("      X, Y : Integer;");
      Append_Line ("   end record;");
      Append_Line ("");
      Append_Line ("   procedure Translate");
      Append_Line
        ("      (P : in Point_3D; V : in Vector_3D; Result : out Point_3D)");
      Append_Line ("      with Import => True;");
      Append_Line ("");
      Append_Line ("   procedure Put (P : in Point_3D)");
      Append_Line ("      with Import => True;");
      Append_Line ("");
      Append_Line ("   type Equal_Kind is (Equal_True, Equal_False);");
      Append_Line ("");
      Append_Line ("   procedure Displacement");
      Append_Line
        ("      (A : in Point_3D; B : in Point_3D; " &
         "Result : out Vector_3D)");
      Append_Line ("      with Import => True;");
      Append_Line ("");
      Append_Line ("   procedure Dot_Product");
      Append_Line
        ("      (A : in Vector_3D; B : in Vector_3D; " &
         "Result : out Integer)");
      Append_Line ("      with Import => True;");
      Append_Line ("");
      Append_Line ("   procedure Cross_Product");
      Append_Line
        ("      (A : in Vector_3D; B : in Vector_3D; " &
         "Result : out Vector_3D)");
      Append_Line ("      with Import => True;");
      Append_Line ("");
      Append_Line ("   procedure Put_Dot (D : in Integer)");
      Append_Line ("      with Import => True;");
      Append_Line ("");
      Append_Line ("   procedure Put_Cross_Vector (V : in Vector_3D)");
      Append_Line ("      with Import => True;");
      Append_Line ("");
      Append_Line ("   procedure Equal");
      Append_Line
        ("      (A : in Point_3D; B : in Point_3D; " &
         "Result : out Equal_Kind)");
      Append_Line ("      with Import => True;");
      Append_Line ("");
      Append_Line ("   procedure Put_Vector (D : in Vector_3D)");
      Append_Line ("      with Import => True;");
      Append_Line ("");
      Append_Line ("   procedure Put_Equal (K : in Equal_Kind)");
      Append_Line ("      with Import => True;");
      Append_Line ("");
      Append_Line ("   type Orientation_Kind is");
      Append_Line ("      (Orientation_Collinear, " &
                   "Orientation_Counter_Clockwise, Orientation_Clockwise);");
      Append_Line ("");
      Append_Line ("   procedure Orientation");
      Append_Line
        ("      (A : in Point_2D; B : in Point_2D; C : in Point_2D; " &
         "Result : out Orientation_Kind)");
      Append_Line ("      with Import => True;");
      Append_Line ("");
      Append_Line ("   procedure Put_Orientation (K : in Orientation_Kind)");
      Append_Line ("      with Import => True;");
      Append_Line ("");
      Append_Line ("   type Intersection_Kind is");
      Append_Line ("      (No_Intersection, Point_Intersection,");
      Append_Line ("       Off_Grid_Crossing, Overlap);");
      Append_Line ("");
      Append_Line ("   type Intersection_Result is record");
      Append_Line ("      K : Intersection_Kind;");
      Append_Line ("      PX, PY, QX, QY : Integer;");
      Append_Line ("   end record;");
      Append_Line ("");
      Append_Line ("   procedure Intersection");
      Append_Line
        ("      (A : in Point_2D; B : in Point_2D; C : in Point_2D; " &
         "D : in Point_2D; Result : out Intersection_Result)");
      Append_Line ("      with Import => True;");
      Append_Line ("");
      Append_Line ("   procedure Put_Intersection " &
                   "(R : in Intersection_Result)");
      Append_Line ("      with Import => True;");
      Append_Line ("");
      Append_Line ("   type Color_Kind is (Blue, Green, Red);");
      Append_Line ("");
      Append_Line ("   procedure Begin_Image (Name : in VString)");
      Append_Line ("      with Import => True;");
      Append_Line ("");
      Append_Line ("   procedure Draw_Axes");
      Append_Line ("      with Import => True;");
      Append_Line ("");
      Append_Line
        ("   procedure Draw_Point (P : in Point_3D; Color : in Color_Kind)");
      Append_Line ("      with Import => True;");
      Append_Line ("");
      Append_Line
        ("   procedure Draw_Vector (Origin : in Point_3D; " &
         "Value : in Vector_3D; Color : in Color_Kind)");
      Append_Line ("      with Import => True;");
      Append_Line ("");
      Append_Line
        ("   procedure Draw_Point_2D (P : in Point_2D; " &
         "Color : in Color_Kind)");
      Append_Line ("      with Import => True;");
      Append_Line ("");
      Append_Line
        ("   procedure Draw_Edge (P, Q : in Point_2D; " &
         "Color : in Color_Kind)");
      Append_Line ("      with Import => True;");
      Append_Line ("");
      Append_Line
        ("   procedure Draw_Segment_2D (P, Q : in Point_2D; " &
         "Color : in Color_Kind)");
      Append_Line ("      with Import => True;");
      Append_Line ("");
      Append_Line ("   procedure End_Image");
      Append_Line ("      with Import => True;");
      Append_Line ("");
      Append_Line ("   type Loop_Kind is");
      Append_Line ("      (Counter_Clockwise, Clockwise, Degenerate,");
      Append_Line ("       Open_Chain, Orphan_Edge, Missing_Endpoint,");
      Append_Line ("       Disconnected_Chain, Degenerate_Support);");
      Append_Line ("");
      Append_Line ("   type Face_Kind is");
      Append_Line ("      (Face_Counter_Clockwise, Face_Clockwise,");
      Append_Line ("       Face_Degenerate_Boundary, Face_Invalid_Boundary);");
      Append_Line ("");
      Append_Line ("   procedure Add_Point (P : in Point_2D)");
      Append_Line ("      with Import => True;");
      Append_Line ("");
      Append_Line ("   procedure Make_Loop (K : out Loop_Kind)");
      Append_Line ("      with Import => True;");
      Append_Line ("");
      Append_Line ("   procedure Make_Face (K : out Face_Kind)");
      Append_Line ("      with Import => True;");
      Append_Line ("");
      Append_Line ("   procedure Put_Loop (K : in Loop_Kind)");
      Append_Line ("      with Import => True;");
      Append_Line ("");
      Append_Line ("   procedure Put_Face (K : in Face_Kind)");
      Append_Line ("      with Import => True;");
      Append_Line ("");
      Append_Line ("   type Continuity_Kind is");
      Append_Line ("      (Continuous, Discontinuous);");
      Append_Line ("");
      Append_Line ("   type Closure_Kind is");
      Append_Line ("      (Closed, Open);");
      Append_Line ("");
      Append_Line ("   type Contour_Orientation_Kind is");
      Append_Line ("      (Contour_Counter_Clockwise, Contour_Clockwise,");
      Append_Line ("       Contour_Degenerate);");
      Append_Line ("");
      Append_Line ("   type Bool_Kind is");
      Append_Line ("      (Bool_True, Bool_False);");
      Append_Line ("");
      Append_Line ("   procedure Contour_Continuity");
      Append_Line ("      (K : out Continuity_Kind)");
      Append_Line ("      with Import => True;");
      Append_Line ("");
      Append_Line ("   procedure Contour_Closure");
      Append_Line ("      (K : out Closure_Kind)");
      Append_Line ("      with Import => True;");
      Append_Line ("");
      Append_Line ("   procedure Contour_Orientation");
      Append_Line ("      (K : out Contour_Orientation_Kind)");
      Append_Line ("      with Import => True;");
      Append_Line ("");
      Append_Line ("   procedure Contour_Self_Intersects");
      Append_Line ("      (B : out Bool_Kind)");
      Append_Line ("      with Import => True;");
      Append_Line ("");
      Append_Line ("   procedure Contour_Valid");
      Append_Line ("      (B : out Bool_Kind)");
      Append_Line ("      with Import => True;");
      Append_Line ("");
      Append_Line ("   procedure Contour_No_Flat_Turns");
      Append_Line ("      (B : out Bool_Kind)");
      Append_Line ("      with Import => True;");
      Append_Line ("");
      Append_Line ("   procedure Put_Continuity (K : in Continuity_Kind)");
      Append_Line ("      with Import => True;");
      Append_Line ("");
      Append_Line ("   procedure Put_Closure (K : in Closure_Kind)");
      Append_Line ("      with Import => True;");
      Append_Line ("");
      Append_Line ("   procedure Put_Contour_Orientation");
      Append_Line ("      (K : in Contour_Orientation_Kind)");
      Append_Line ("      with Import => True;");
      Append_Line ("");
      Append_Line ("   procedure Put_Bool (B : in Bool_Kind)");
      Append_Line ("      with Import => True;");
      Append_Line ("");
      Append_Line ("   subtype Vertex_Handle is Integer;");
      Append_Line ("");
      Append_Line ("   subtype Edge_Handle is Integer;");
      Append_Line ("");
      Append_Line ("   procedure Create_Vertex");
      Append_Line ("      (P : in Point_2D; H : out Vertex_Handle)");
      Append_Line ("      with Import => True;");
      Append_Line ("");
      Append_Line ("   procedure Create_Edge");
      Append_Line ("      (A : in Vertex_Handle; B : in Vertex_Handle;");
      Append_Line ("       E : out Edge_Handle)");
      Append_Line ("      with Import => True;");
      Append_Line ("");
      Append_Line ("   procedure Put_Vertex (H : in Vertex_Handle)");
      Append_Line ("      with Import => True;");
      Append_Line ("");
      Append_Line ("   procedure Put_Edge (E : in Edge_Handle)");
      Append_Line ("      with Import => True;");
      Append_Line ("");
      Append_Line ("   procedure Make_Loop_From_Edges");
      Append_Line ("      (K : out Loop_Kind)");
      Append_Line ("      with Import => True;");
      Append_Line ("");
      Append_Line ("   --  User declarations (TopoScript fragment):");
      Declaration_Skip := Count;
      Line_Count := 0;
      Start := Fragment'First;
      while Start <= Fragment'Last loop
         Finish := Start;
         while Finish <= Fragment'Last
           and then Fragment (Finish) /= ASCII.LF
         loop
            Finish := Finish + 1;
         end loop;
         Line_Count := Line_Count + 1;
         if Line_Count < First_Statement then
            Append_Line (Fragment (Start .. Finish - 1));
         end if;
         Start := Finish + 1;
      end loop;

      Append_Line ("");
      Append_Line ("begin");
      Begin_Line := Count;

      declare
         No_Statement : Boolean := True;

      begin
         Line_Count := 0;
         Start := Fragment'First;
         while Start <= Fragment'Last loop
            Finish := Start;
            while Finish <= Fragment'Last
              and then Fragment (Finish) /= ASCII.LF
            loop
               Finish := Finish + 1;
            end loop;
            Line_Count := Line_Count + 1;
            if Line_Count >= First_Statement then
               Append_Line (Fragment (Start .. Finish - 1));
               No_Statement := False;
            end if;
            Start := Finish + 1;
         end loop;
         --  The body must carry at least one statement: an empty
         --  fragment, or a fragment of declarations only, executes
         --  as a null statement.
         if No_Statement then
            Append_Line ("   null;");
         end if;
      end;

      Append_Line ("end TopoScript_Run;");

      Result :=
        (Source           => Source,
         Declaration_Skip => Declaration_Skip,
         Begin_Line       => Begin_Line,
         Statement_Adjust => Begin_Line + 1 - First_Statement);
   end Generate;

   --  The in-memory source stream and its buffer live at library
   --  level: HAC holds an access to the stream for the whole build, and
   --  a tool run wraps exactly one source.

   Text_Buffer : String_Access := new String'("");
   The_Stream  : aliased Memory_Stream;

   procedure Open
     (S    : in out Memory_Stream;
      Data : not null access constant String) is
   begin
      S.Data := Data;
      S.Pos  := 0;
   end Open;

   procedure Set_Source (Content : String) is
      procedure Free is new Ada.Unchecked_Deallocation
        (String, String_Access);
   begin
      --  One run wraps one source: the previous allocation, if any,
      --  is reclaimed (development plan, TopoScript consolidation,
      --  Increment 4), so a persistent host wrapping successive
      --  sources leaks none of them.
      Free (Text_Buffer);
      Text_Buffer := new String'(Content);
      Open (The_Stream, Text_Buffer.all'Access);
   end Set_Source;

   function Stream return Ada.Streams.Stream_IO.Stream_Access is
   begin
      return The_Stream'Access;
   end Stream;

   overriding procedure Read
     (S    : in out Memory_Stream;
      Item :    out Ada.Streams.Stream_Element_Array;
      Last :    out Ada.Streams.Stream_Element_Offset)
   is
      use Ada.Streams;
      Remaining : constant Stream_Element_Offset :=
        Stream_Element_Offset (S.Data'Length - S.Pos);
      Count_Copy : constant Stream_Element_Offset :=
        (if Item'Length <= Remaining then Item'Length else Remaining);
      Src : Positive := S.Pos + 1;
   begin
      if Count_Copy = 0 then
         --  The empty read reports the end of the stream, which is the
         --  convention the HAC scanner expects.
         Last := Item'First - 1;
      else
         for J in Item'First .. Item'First + Count_Copy - 1 loop
            Item (J) := Stream_Element (Character'Pos (S.Data (Src)));
            Src := Src + 1;
         end loop;
         Last := Item'First + Count_Copy - 1;
         S.Pos := S.Pos + Positive (Count_Copy);
      end if;
   end Read;

   overriding procedure Write
     (S    : in out Memory_Stream;
      Item :        Ada.Streams.Stream_Element_Array)
   is
      pragma Unreferenced (S, Item);
   begin
      --  The wrapper source is read-only.
      null;
   end Write;

end TopoScript_Wrapper;

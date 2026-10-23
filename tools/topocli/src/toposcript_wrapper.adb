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

   --  An object declaration starts with an identifier directly
   --  followed by ':' (not ':=').
   function Is_Declaration (Line : String) return Boolean is
      package CH renames Ada.Characters.Handling;
      T : constant String := Trimmed (Line);
      I : Natural := T'First;
   begin
      if T'Length = 0 or else not CH.Is_Letter (T (T'First)) then
         return False;
      end if;
      while I <= T'Last
        and then (CH.Is_Alphanumeric (T (I)) or else T (I) = '_')
      loop
         I := I + 1;
      end loop;
      while I <= T'Last and then T (I) = ' ' loop
         I := I + 1;
      end loop;
      return I <= T'Last
        and then T (I) = ':'
        and then (I = T'Last or else T (I + 1) /= '=');
   end Is_Declaration;

   --  Keywords that open a declaration form the initial subset does
   --  not cover; they would end up in the statement region and produce
   --  a confusing HAC message, so they are rejected up front.
   function Is_Out_Of_Subset (Line : String) return Boolean is
      package CH renames Ada.Characters.Handling;
      T : constant String := Trimmed (Line);
      I : Natural := T'First;
   begin
      if T'Length = 0 or else not CH.Is_Letter (T (T'First)) then
         return False;
      end if;
      while I <= T'Last
        and then (CH.Is_Alphanumeric (T (I)) or else T (I) = '_')
      loop
         I := I + 1;
      end loop;
      declare
         Keyword : constant String := CH.To_Lower (T (T'First .. I - 1));
      begin
         return Keyword = "type"
           or else Keyword = "subtype"
           or else Keyword = "procedure"
           or else Keyword = "function"
           or else Keyword = "package"
           or else Keyword = "use"
           or else Keyword = "with"
           or else Keyword = "pragma"
           or else Keyword = "generic"
           or else Keyword = "separate";
      end;
   end Is_Out_Of_Subset;

   --  A line reduced to one bare identifier: neither a complete
   --  object declaration nor a statement of the subset (a statement
   --  is a call or an assignment, both of which carry more than the
   --  identifier). A declaration split across several lines leaves
   --  such a line, so it is rejected here, with the fragment
   --  location, instead of reaching the HAC compilation with a
   --  confusing message.
   function Is_Identifier_Only (Line : String) return Boolean is
      package CH renames Ada.Characters.Handling;
      T : constant String := Trimmed (Line);
      I : Natural := T'First;
   begin
      if T'Length = 0 or else not CH.Is_Letter (T (T'First)) then
         return False;
      end if;
      while I <= T'Last
        and then (CH.Is_Alphanumeric (T (I)) or else T (I) = '_')
      loop
         I := I + 1;
      end loop;
      return I > T'Last;
   end Is_Identifier_Only;

   procedure Generate
     (Fragment :     String;
      Path     :     String;
      Result   : out Wrapped_Source)
   is
      Source : Unbounded_String;
      Count  : Natural := 0;

      First_Statement : Natural := 0;
      Line_Count      : Natural := 0;
      Declaration_Skip : Positive;
      Begin_Line      : Natural;

      Start, Finish : Positive;

      procedure Append_Line (Content : String) is
      begin
         Append (Source, Content);
         Append (Source, ASCII.LF);
         Count := Count + 1;
      end Append_Line;

      procedure Reject
        (Line : Positive;
         What : String) is
      begin
         raise Wrapper_Error with
           "error: " & Path & ":" &
           Ada.Strings.Fixed.Trim (Line'Image, Ada.Strings.Both) & ": " &
           What;
      end Reject;

   begin
      --  Pass 1: locate the first executable statement, and reject the
      --  constructs outside the initial subset.
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
            if not Is_Neutral (Line) then
               if Is_Out_Of_Subset (Line) then
                  Reject (Line_Count,
                          "the initial TopoScript subset accepts " &
                          "object declarations and statements only");
               elsif Is_Identifier_Only (Line) then
                  Reject (Line_Count,
                          "a bare identifier is neither a complete " &
                          "object declaration nor a statement: the " &
                          "initial subset rejects a declaration " &
                          "split across several lines");
               elsif First_Statement = 0 then
                  if not Is_Declaration (Line) then
                     First_Statement := Line_Count;
                  end if;
               elsif Is_Declaration (Line) then
                  Reject (Line_Count,
                          "declaration after the first executable statement");
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

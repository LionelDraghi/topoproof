-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with Ada.Directories;
with Ada.Numerics.Long_Elementary_Functions;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Text_IO;

package body Topodraw is

   use Ada.Strings;
   use Ada.Strings.Fixed;
   use Ada.Strings.Unbounded;
   use Ada.Text_IO;

   package LF_IO is new Ada.Text_IO.Float_IO (Long_Float);

   W : constant := 640;
   H : constant := 400;
   Margin : constant Long_Float := 48.0;
   Cos30 : constant Long_Float := 0.866_025_403_784_438_6;
   Sin30 : constant Long_Float := 0.5;

   Pt_Fill  : constant String := "#1f6feb";
   Pt_Text  : constant String := "#0d2b3e";
   Vec_Col  : constant String := "#1a7f37";
   Axis_Col : constant String := "#8b949e";
   Path_Col : constant String := "#6e7781";
   Font_Attr : constant String :=
     "font-family=""sans-serif"" font-size=""13""";

   type Coord3 is record
      X, Y, Z : Integer;
   end record;

   package Coord_Vectors is new Ada.Containers.Indefinite_Vectors
     (Positive, Coord3);

   type Screen2 is record
      X, Y : Long_Float;
   end record;

   type Scene_Span is record
      Target     : Unbounded_String;
      Scene_Body : Unbounded_String;
      Start      : Natural;
      Finish     : Natural;
   end record;

   package Scene_Span_Vectors is new Ada.Containers.Indefinite_Vectors
     (Positive, Scene_Span);

   type Axis_Def is record
      Tip    : Coord3;
      Letter : String (1 .. 1);
      Off    : Screen2;
   end record;

   type Pair_Def is record
      Axis : Coord3;
      Perp : Coord3;
   end record;

   procedure Head
     (S : String; Word : out Unbounded_String;
      Rest : out Unbounded_String);

   procedure Head
     (S : String; Word : out Unbounded_String; Rest : out Unbounded_String)
   is
      Sp : constant Natural := Index (S, " ");
   begin

      if Sp = 0 then
         Word := To_Unbounded_String (S);
         Rest := Null_Unbounded_String;
      else
         Word := To_Unbounded_String (S (S'First .. Sp - 1));
         Rest := To_Unbounded_String (Trim (S (Sp + 1 .. S'Last), Both));
      end if;
   end Head;

   function Int_Image (V : Integer) return String is
     (Trim (Integer'Image (V), Both));

   function Same_Position (A, B : Point_Rec) return Boolean is
     (A.X = B.X and then A.Y = B.Y and then A.Z = B.Z);

   function Find_Point (S : Scene; Name : String) return Point_Rec;

   function Find_Point (S : Scene; Name : String) return Point_Rec is
   begin

      for Pt of S.Points loop
         if To_String (Pt.Name) = Name then
            return Pt;
         end if;
      end loop;
      raise Scene_Error with "unknown point '" & Name & "'";
   end Find_Point;

   function Parse_Scene (Source : String) return Scene is
      S : Scene;
      Pos : Natural := Source'First;
      Line_No : Natural := 0;

   begin
      while Pos <= Source'Last loop
         declare
            Line_End : constant Natural :=
              Index (Source, [1 => ASCII.LF], Pos);
            Raw_Line : constant String :=
              (if Line_End = 0 then Source (Pos .. Source'Last)
               else Source (Pos .. Line_End - 1));
            Hash : constant Natural := Index (Raw_Line, "#");
            Line : constant String :=
              (if Hash = 0 then Raw_Line
               else Trim (Raw_Line (Raw_Line'First .. Hash - 1), Both));
            Word, Rest : Unbounded_String;

         begin
            Line_No := Line_No + 1;
            if Line /= "" then
               Head (Line, Word, Rest);
               if To_String (Word) = "axes" then
                  if Rest /= "" then
                     raise Scene_Error
                       with "line" & Integer'Image (Line_No)
                            & ": 'axes' takes no argument";
                  end if;
                  S.Draw_Axes := True;

               elsif To_String (Word) = "ticks" then
                  if Rest = "" then
                     S.Tick_Step := 0;
                  else
                     S.Tick_Step := Integer'Value (To_String (Rest));
                  end if;
                  if S.Tick_Step < 0 then
                     raise Scene_Error
                       with "line" & Integer'Image (Line_No)
                            & ": STEP must not be negative";
                  end if;
                  S.Draw_Axes := True;

               elsif To_String (Word) = "anchors" then
                  if Rest /= "" then
                     raise Scene_Error
                       with "line" & Integer'Image (Line_No)
                            & ": 'anchors' takes no argument";
                  end if;
                  S.Anchors := True;

               elsif To_String (Word) = "point" then
                  declare
                     Name, Coords : Unbounded_String;
                     Cx, Cy, Cz : Unbounded_String;

                  begin
                     Head (To_String (Rest), Name, Coords);
                     Head (To_String (Coords), Cx, Coords);
                     Head (To_String (Coords), Cy, Coords);
                     Cz := Coords;
                     S.Points.Append
                       (Point_Rec'(Name     => Name,
                         X         => Integer'Value (To_String (Cx)),
                         Y         => Integer'Value (To_String (Cy)),
                         Z         => Integer'Value (To_String (Cz)),
                         others    => <>));
                  exception
                     when Constraint_Error =>
                        raise Scene_Error
                          with "line" & Integer'Image (Line_No)
                               & ": 'point NAME X Y Z' expected";
                  end;

               elsif To_String (Word) = "vector" then
                  declare
                     From_Name, To_Name, Rest_Label : Unbounded_String;

                  begin
                     Head (To_String (Rest), From_Name, To_Name);
                     Head (To_String (To_Name), To_Name, Rest_Label);
                     S.Vectors.Append (Vector_Rec'(From_Name => From_Name,
                                    To_Name   => To_Name,
                                    Label     => Rest_Label,
                                    others    => <>));
                  end;

               else
                  raise Scene_Error
                    with "line" & Integer'Image (Line_No)
                         & ": unknown statement '"
                         & To_String (Word) & "'";
               end if;
            end if;
            if Line_End = 0 then
               Pos := Source'Last + 1;
            else
               Pos := Line_End + 1;
            end if;
         end;
      end loop;

      if Natural (S.Points.Length) = 0 and then not S.Draw_Axes then
         raise Scene_Error with "empty scene";
      end if;
      return S;
   end Parse_Scene;

   --  Wide arithmetic for the automatic tick step: the intermediate
   --  products (8 * B * 5, 8 * B * K) may leave Integer, so they are
   --  computed in a wide type with an explicit range rather than a
   --  predefined type whose size, and therefore the reachable values,
   --  depends on the platform. Any point accepted on input (an Integer
   --  coordinate, including points outside the kernel domain) stays
   --  drawable.
   type Wide_Integer is range -2**35 .. 2**35;

   --  The automatic tick step: the smallest round 1-2-5 number keeping at
   --  most eight tick marks over the scene extent.
   function Nice_Step (Extent : Integer) return Integer is
      B  : Wide_Integer := 1;
      Ks : constant array (1 .. 3) of Wide_Integer := [1, 2, 5];

   begin
      while Wide_Integer (Extent) > 8 * B * 5 loop
         B := B * 10;

      end loop;
      for K of Ks loop
         if Wide_Integer (Extent) <= 8 * B * K then
            return Integer'Max (1, Integer (B * K));

         end if;
      end loop;
      return Integer'Max (1, Integer (B));
   end Nice_Step;

   ---------------------------------------------------------------------------
   --  Isometric projection
   ---------------------------------------------------------------------------

   --  The raw isometric coordinates of one grid position, before the
   --  scene is fitted onto the canvas.
   function Raw_X (C : Coord3) return Long_Float is
     ((Long_Float (C.X) - Long_Float (C.Y)) * Cos30);

   function Raw_Y (C : Coord3) return Long_Float is
     ((Long_Float (C.X) + Long_Float (C.Y)) * Sin30
      - Long_Float (C.Z));

   --  The fitted projection of a scene: the scale and the origin that
   --  map the raw coordinates of the scene extent onto the canvas,
   --  leaving the margin on every side.
   type Projection is record
      Scale : Long_Float;
      Ox, Oy : Long_Float;
   end record;

   function To_Screen (P : Projection; C : Coord3) return Screen2 is
     (Raw_X (C) * P.Scale + P.Ox, Raw_Y (C) * P.Scale + P.Oy);

   --  The projection fitted to the anchors: the extent of their raw
   --  coordinates on both axes, centered and scaled into the canvas.
   function Fit (Anchors : Coord_Vectors.Vector) return Projection is
      Min_X : Long_Float := Long_Float'Last;
      Max_X : Long_Float := Long_Float'First;
      Min_Y : Long_Float := Long_Float'Last;
      Max_Y : Long_Float := Long_Float'First;

   begin
      for C of Anchors loop
         Min_X := Long_Float'Min (Min_X, Raw_X (C));
         Max_X := Long_Float'Max (Max_X, Raw_X (C));
         Min_Y := Long_Float'Min (Min_Y, Raw_Y (C));
         Max_Y := Long_Float'Max (Max_Y, Raw_Y (C));
      end loop;

      declare
         Dx : constant Long_Float :=
           Long_Float'Max (0.000_000_001, Max_X - Min_X);
         Dy : constant Long_Float :=
           Long_Float'Max (0.000_000_001, Max_Y - Min_Y);
         Scale : constant Long_Float :=
           Long_Float'Min
             ((Long_Float (W) - 2.0 * Margin) / Dx,
              (Long_Float (H) - 2.0 * Margin) / Dy);
         Ox : constant Long_Float :=
           (Long_Float (W) - (Max_X - Min_X) * Scale) / 2.0
           - Min_X * Scale;
         Oy : constant Long_Float :=
           (Long_Float (H) - (Max_Y - Min_Y) * Scale) / 2.0
           - Min_Y * Scale;

      begin
         return (Scale => Scale, Ox => Ox, Oy => Oy);
      end;
   end Fit;

   ---------------------------------------------------------------------------
   --  SVG emission
   ---------------------------------------------------------------------------

   --  The SVG document under construction: the fitted projection of
   --  the scene, and the text emitted so far. The primitives append
   --  to the buffer; nothing is written to a file here.
   type SVG_Document is record
      Proj   : Projection;
      Buffer : Unbounded_String;
   end record;

   procedure Append_F (Doc : in out SVG_Document; V : Long_Float) is
      Tmp : String (1 .. 24);

   begin
      LF_IO.Put (Tmp, V, Aft => 1, Exp => 0);
      Append (Doc.Buffer, Trim (Tmp, Both));
   end Append_F;

   procedure Line
     (Doc : in out SVG_Document;
      A, B : Screen2; Color : String;
      Width : Long_Float; Dash : String := "";
      Marker : String := "")
   is
   begin

      Append (Doc.Buffer, "<line x1=""");
      Append_F (Doc, A.X);
      Append (Doc.Buffer, """ y1=""");
      Append_F (Doc, A.Y);
      Append (Doc.Buffer, """ x2=""");
      Append_F (Doc, B.X);
      Append (Doc.Buffer, """ y2=""");
      Append_F (Doc, B.Y);
      Append (Doc.Buffer, """ stroke=""" & Color);
      Append (Doc.Buffer, """ stroke-width=""");
      Append_F (Doc, Width);
      if Dash /= "" then
         Append (Doc.Buffer, """ stroke-dasharray=""" & Dash);
      end if;
      if Marker /= "" then
         Append (Doc.Buffer, """ marker-end=""" & Marker);
      end if;
      Append (Doc.Buffer, """/>" & ASCII.LF);
   end Line;

   procedure Circle
     (Doc : in out SVG_Document;
      C : Screen2; R : Long_Float; Fill : String;
      Stroke : String := ""; Stroke_Width : Long_Float := 1.0;
      Dash : String := "")
   is
   begin

      Append (Doc.Buffer, "<circle cx=""");
      Append_F (Doc, C.X);
      Append (Doc.Buffer, """ cy=""");
      Append_F (Doc, C.Y);
      Append (Doc.Buffer, """ r=""");
      Append_F (Doc, R);
      Append (Doc.Buffer, """ fill=""" & Fill);
      if Stroke /= "" then
         Append (Doc.Buffer, """ stroke=""" & Stroke);
         Append (Doc.Buffer, """ stroke-width=""");
         Append_F (Doc, Stroke_Width);
         if Dash /= "" then
            Append (Doc.Buffer, """ stroke-dasharray=""" & Dash);
         end if;
      end if;
      Append (Doc.Buffer, """/>" & ASCII.LF);
   end Circle;

   procedure Text_At
     (Doc : in out SVG_Document;
      X, Y : Long_Float; Content : String;
      Color : String)
   is
   begin
      Append (Doc.Buffer, "<text x=""");
      Append_F (Doc, X);
      Append (Doc.Buffer, """ y=""");
      Append_F (Doc, Y);
      Append (Doc.Buffer, """ fill=""" & Color & """ " & Font_Attr);
      Append (Doc.Buffer, ">" & Content & "</text>" & ASCII.LF);
   end Text_At;

   ---------------------------------------------------------------------------
   --  The phases of one diagram
   ---------------------------------------------------------------------------

   --  The largest absolute coordinate of the scene points: the unit
   --  the axes and the automatic ticks are graduated in.
   function Scene_Unit (S : Scene) return Integer is
      M : Integer := 0;

   begin
      for Pt of S.Points loop
         M := Integer'Max (M, abs Pt.X);
         M := Integer'Max (M, abs Pt.Y);
         M := Integer'Max (M, abs Pt.Z);
      end loop;
      return Integer'Max (1, M);
   end Scene_Unit;

   --  Every position the projection must fit: the scene points, the
   --  tips of the drawn axes, and the coordinate paths of the
   --  anchored points.
   function Collect_Anchors
      (S : Scene; Unit : Integer) return Coord_Vectors.Vector
   is
      Anchors : Coord_Vectors.Vector;

   begin
      for Pt of S.Points loop
         Anchors.Append (Coord3'(X => Pt.X, Y => Pt.Y, Z => Pt.Z));
      end loop;
      if S.Draw_Axes then
         Anchors.Append (Coord3'(X => 0, Y => 0, Z => 0));
         Anchors.Append (Coord3'(X => Unit, Y => 0, Z => 0));
         Anchors.Append (Coord3'(X => 0, Y => Unit, Z => 0));
         Anchors.Append (Coord3'(X => 0, Y => 0, Z => Unit));
      end if;
      if S.Anchors then

         for Pt of S.Points loop
            Anchors.Append (Coord3'(X => 0, Y => 0, Z => 0));
            Anchors.Append (Coord3'(X => Pt.X, Y => 0, Z => 0));
            Anchors.Append (Coord3'(X => Pt.X, Y => Pt.Y, Z => 0));
         end loop;
      end if;
      return Anchors;
   end Collect_Anchors;

   --  The SVG header and the white background rectangle.
   procedure Emit_Background (Doc : in out SVG_Document) is
   begin
      Append (Doc.Buffer, "<svg xmlns=""http://www.w3.org/2000/svg"" "
              & "viewBox=""0 0 " & Int_Image (W) & " "
              & Int_Image (H) & """ width=""" & Int_Image (W)
              & """ height=""" & Int_Image (H) & """>" & ASCII.LF);
      Append (Doc.Buffer, "<rect width=""" & Int_Image (W)
              & """ height=""" & Int_Image (H)
              & """ fill=""#ffffff""/>" & ASCII.LF);
   end Emit_Background;

   --  The coordinate path of each anchored point: dashed segments
   --  from the origin along X, then parallel to Y, then parallel
   --  to Z, with a small circle on every intermediate corner.
   procedure Emit_Anchor_Paths (Doc : in out SVG_Document; S : Scene) is
   begin
      if S.Anchors then
         for Pt of S.Points loop
            declare
               Path : constant array (1 .. 4) of Coord3 :=
                 [(0, 0, 0), (Pt.X, 0, 0), (Pt.X, Pt.Y, 0),
                  (Pt.X, Pt.Y, Pt.Z)];
               Prev : Coord3 := Path (1);
               Found : Boolean := False;
            begin

               for K in 2 .. 4 loop
                  if Path (K) /= Prev then
                     Line (Doc,
                           To_Screen (Doc.Proj, Prev),
                           To_Screen (Doc.Proj, Path (K)),
                           Path_Col, 1.0, "4 3");
                     Found := True;
                  end if;
                  Prev := Path (K);
               end loop;
               pragma Assert (Found or else Path (1) = Path (4));
               for K in 2 .. 3 loop
                  Circle (Doc, To_Screen (Doc.Proj, Path (K)), 2.5,
                          "#ffffff", Path_Col, 1.0);
               end loop;
            end;
         end loop;
      end if;
   end Emit_Anchor_Paths;

   --  The three axes with their letters, and the origin circle.
   procedure Emit_Axes (Doc : in out SVG_Document; S : Scene) is
   begin
      if S.Draw_Axes then
         declare
            O : constant Screen2 := To_Screen (Doc.Proj, (0, 0, 0));
            Axes : constant array (1 .. 3) of Axis_Def :=
                [((1, 0, 0), "X", (6.0, 14.0)),
                 ((0, 1, 0), "Y", (-16.0, 14.0)),
                 ((0, 0, 1), "Z", (0.0, -6.0))];
         begin

            for A of Axes loop
               declare
                  Tip : constant Screen2 := To_Screen (Doc.Proj, A.Tip);
               begin
                  Line (Doc, O, Tip, Axis_Col, 1.0, "4 3");
                  Text_At (Doc, Tip.X + A.Off.X, Tip.Y + A.Off.Y,
                           A.Letter, Axis_Col);
               end;
            end loop;
            Circle (Doc, O, 2.5, Axis_Col);
         end;
      end if;
   end Emit_Axes;

   --  The tick marks along the axes, every STEP units, or every
   --  automatic step when STEP is zero.
   procedure Emit_Ticks
     (Doc : in out SVG_Document; S : Scene; Unit : Integer)
   is
   begin
      if S.Tick_Step >= 0 then
         declare
            use Ada.Numerics.Long_Elementary_Functions;
            Step : constant Integer :=
              (if S.Tick_Step = 0
               then Nice_Step (Unit)
               else S.Tick_Step);
            Pairs : constant array (1 .. 3) of Pair_Def :=
                [((1, 0, 0), (0, 1, 0)),
                 ((0, 1, 0), (0, 0, 1)),
                 ((0, 0, 1), (1, 0, 0))];
         begin

            for P of Pairs loop
               declare
                  T : Integer := Step;
               begin
                  while T <= Unit loop
                     declare
                        Pos : constant Coord3 :=
                          (P.Axis.X * T, P.Axis.Y * T, P.Axis.Z * T);
                        A : constant Screen2 := To_Screen (Doc.Proj, Pos);
                        B : constant Screen2 :=
                          To_Screen
                            (Doc.Proj,
                             (Pos.X + P.Perp.X, Pos.Y + P.Perp.Y,
                              Pos.Z + P.Perp.Z));
                        Vx : constant Long_Float := B.X - A.X;
                        Vy : constant Long_Float := B.Y - A.Y;
                        Norm : constant Long_Float :=
                          Long_Float'Max
                            (0.000_000_001, Sqrt (Vx * Vx + Vy * Vy));
                        Dx : constant Long_Float := 5.0 * Vx / Norm;
                        Dy : constant Long_Float := 5.0 * Vy / Norm;
                     begin
                        Line (Doc, (A.X - Dx, A.Y - Dy),
                              (A.X + Dx, A.Y + Dy),
                              Axis_Col, 1.0);
                     end;
                     --  A tick position one step beyond the extent
                     --  would leave Integer: the last representable
                     --  tick is the last one drawn.
                     exit when T > Integer'Last - Step;
                     T := T + Step;
                  end loop;
               end;
            end loop;
         end;
      end if;
   end Emit_Ticks;

   --  The scene points: one circle and one label each; coincident
   --  points stack up as concentric circles instead of duplicating.
   procedure Emit_Points (Doc : in out SVG_Document; S : Scene) is
   begin
      for I in S.Points.First_Index .. S.Points.Last_Index loop
         declare
            Pt : constant Point_Rec := S.Points (I);
            Pos : constant Screen2 :=
              To_Screen (Doc.Proj, (Pt.X, Pt.Y, Pt.Z));
            Dup : Natural := 0;
         begin

            for J in S.Points.First_Index .. I - 1 loop
               if Same_Position (S.Points (J), Pt) then
                  Dup := Dup + 1;
               end if;
            end loop;
            if Dup = 0 then
               Circle (Doc, Pos, 5.0,
                       (if Pt.Color = "" then Pt_Fill
                        else To_String (Pt.Color)),
                       "#ffffff", 1.5);
            else
               Circle (Doc, Pos, Long_Float (5 + 4 * Dup), "none",
                       (if Pt.Color = "" then Pt_Fill
                        else To_String (Pt.Color)),
                       1.5, "3 2");
            end if;
            declare
               Label : constant String :=
                 To_String (Pt.Name) & " (" & Int_Image (Pt.X)
                 & ", " & Int_Image (Pt.Y) & ", "
                 & Int_Image (Pt.Z) & ")";
            begin
               Text_At (Doc, Pos.X + 10.0,
                        Pos.Y - 10.0 + Long_Float (30 * Dup),
                        Label, Pt_Text);
            end;
         end;
      end loop;
   end Emit_Points;

   --  The arrow markers of the vector colors, then one arrow per
   --  vector, with its label at the middle.
   procedure Emit_Vectors (Doc : in out SVG_Document; S : Scene) is
   begin
      declare
         --  One arrow marker per distinct vector color: the
         --  default color keeps the plain arrow marker, so the
         --  CLI scenes render exactly as before.
         Max_Colors : constant := 8;
         Colors : array (1 .. Max_Colors) of Unbounded_String;
         Count  : Natural := 0;

         procedure Register_Color (Color : Unbounded_String) is
            Found : Boolean := False;
         begin
            if Color /= "" then
               for K in 1 .. Count loop
                  if Colors (K) = Color then
                     Found := True;
                  end if;
               end loop;
               if not Found then
                  if Count = Max_Colors then
                     raise Scene_Error with "too many vector colors";
                  end if;
                  Count := Count + 1;
                  Colors (Count) := Color;
               end if;
            end if;
         end Register_Color;

         function Id_Of (Color : Unbounded_String) return String is
         begin
            if Color = "" then
               return "arrow";
            end if;
            for K in 1 .. Count loop
               if Colors (K) = Color then
                  return "arrow" & Trim (K'Image, Both);
               end if;
            end loop;
            return "arrow";
         end Id_Of;

      begin
         for V of S.Vectors loop
            Register_Color (V.Color);
         end loop;

         Append (Doc.Buffer, "<defs><marker id=""arrow"" markerWidth=""10"" "
                 & "markerHeight=""10"" refX=""8"" refY=""3"" "
                 & "orient=""auto""><path d=""M0,0 L8,3 L0,6 z"" fill="""
                 & Vec_Col & """/></marker>");
         for K in 1 .. Count loop
            Append (Doc.Buffer, "<marker id=""arrow" & Trim (K'Image, Both)
                    & """ markerWidth=""10"" "
                    & "markerHeight=""10"" refX=""8"" refY=""3"" "
                    & "orient=""auto""><path d=""M0,0 L8,3 L0,6 z"""
                    & " fill=""" & To_String (Colors (K))
                    & """/></marker>");
         end loop;
         Append (Doc.Buffer, "</defs>" & ASCII.LF);

         for V of S.Vectors loop
            declare
               From : constant Point_Rec :=
                 Find_Point (S, To_String (V.From_Name));
               To   : constant Point_Rec :=
                 Find_Point (S, To_String (V.To_Name));
               A : constant Screen2 :=
                 To_Screen (Doc.Proj, (From.X, From.Y, From.Z));
               B : constant Screen2 := To_Screen (Doc.Proj, (To.X, To.Y, To.Z));
               Line_Color : constant String :=
                 (if V.Color = "" then Vec_Col
                  else To_String (V.Color));
            begin

               if Same_Position (From, To) then
                  raise Scene_Error
                    with "vector " & To_String (V.From_Name) & " -> "
                         & To_String (V.To_Name)
                         & ": coincident points";
               end if;
               Line (Doc, A, B, Line_Color, 2.0, "",
                     "url(#" & Id_Of (V.Color) & ")");
               if To_String (V.Label) /= "" then
                  Text_At (Doc, (A.X + B.X) / 2.0,
                           (A.Y + B.Y) / 2.0 - 8.0,
                           To_String (V.Label), Line_Color);
               end if;
            end;
         end loop;
      end;
   end Emit_Vectors;

   function Render (S : Scene) return String is
      Unit    : constant Integer := Scene_Unit (S);
      Anchors : constant Coord_Vectors.Vector :=
        Collect_Anchors (S, Unit);
      Doc     : SVG_Document :=
        (Proj   => Fit (Anchors),
         Buffer => Null_Unbounded_String);

   begin
      Emit_Background (Doc);
      Emit_Anchor_Paths (Doc, S);
      Emit_Axes (Doc, S);
      Emit_Ticks (Doc, S, Unit);
      Emit_Points (Doc, S);
      Emit_Vectors (Doc, S);
      Append (Doc.Buffer, "</svg>");
      return To_String (Doc.Buffer);
   end Render;

   function Directory_Of (Path : String) return String;

   function Directory_Of (Path : String) return String is
   begin

      for I in reverse Path'Range loop
         if Path (I) = '/' then
            return Path (Path'First .. I - 1);
         end if;
      end loop;
      return ".";
   end Directory_Of;

   --  The scene comments of one Markdown page: every
   --  <!-- topodraw TARGET ... --> comment, with its target file and
   --  its scene source. Raise Scene_Error on an unterminated comment,
   --  or on a scene source that contains '--', which would close the
   --  HTML comment early.
   function Scan_Scenes
      (Markdown_Path : String; T : String)
      return Scene_Span_Vectors.Vector
   is
      Scenes : Scene_Span_Vectors.Vector;
      I : Natural := Index (T, "<!--");

   begin
      while I /= 0 loop
         declare
            J : Natural := I + 4;
            Target, Scene_Body : Unbounded_String;
            Finish : Natural;
         begin
            while J <= T'Last
              and then (T (J) = ' ' or else T (J) = ASCII.HT
                        or else T (J) = ASCII.LF or else T (J) = ASCII.CR)
            loop
               J := J + 1;
            end loop;
            if J + 7 <= T'Last
              and then T (J .. J + 7) = "topodraw"
              and then J + 8 <= T'Last
              and then (T (J + 8) = ' ' or else T (J + 8) = ASCII.HT)
            then
               declare
                  K : Natural := J + 9;
                  Target_Start : Natural;
                  Body_Start, Body_End : Natural;

                  --  The first position at or after From that is
                  --  neither a space nor a tab.
                  function Skip_Blanks (From : Natural) return Natural is
                     P : Natural := From;
                  begin
                     while P <= T'Last
                       and then (T (P) = ' ' or else T (P) = ASCII.HT)
                     loop
                        P := P + 1;
                     end loop;
                     return P;
                  end Skip_Blanks;

               begin
                  K := Skip_Blanks (K);
                  Target_Start := K;
                  while K <= T'Last
                    and then T (K) /= ' ' and then T (K) /= ASCII.HT
                    and then T (K) /= ASCII.LF and then T (K) /= ASCII.CR
                  loop
                     K := K + 1;
                  end loop;
                  Target := To_Unbounded_String
                    (T (Target_Start .. K - 1));
                  K := Skip_Blanks (K);
                  if K <= T'Last and then T (K) = ASCII.LF then
                     Body_Start := K + 1;
                     Body_End := Index (T, "-->", Body_Start);
                     if Body_End = 0 then
                        raise Scene_Error
                          with Markdown_Path
                               & ": unterminated scene comment";
                     end if;
                     Scene_Body := To_Unbounded_String
                       (T (Body_Start .. Body_End - 1));
                     Finish := Body_End + 2;
                     if Index (To_String (Scene_Body), "--") /= 0 then
                        raise Scene_Error
                          with "scene sources must not contain '--' "
                               & "(it would close the HTML comment)";
                     end if;
                     Scenes.Append
                       (Scene_Span'(Target     => Target,
                         Scene_Body => Scene_Body,
                         Start      => I,
                         Finish     => Finish));
                  end if;
               end;
            end if;
         end;
         I := Index (T, "<!--", I + 4);
      end loop;
      return Scenes;
   end Scan_Scenes;

   --  The page with its scene comments removed: the scenes are
   --  rendered into their own files, not into the page.
   function Stripped_Of
      (T : String; Scenes : Scene_Span_Vectors.Vector) return String
   is
      Stripped : Unbounded_String;
      Last_Copied : Natural := T'First - 1;

   begin
      for Scene_Item of Scenes loop
         Append (Stripped, T (Last_Copied + 1 .. Scene_Item.Start - 1));
         Last_Copied := Scene_Item.Finish;
      end loop;
      Append (Stripped, T (Last_Copied + 1 .. T'Last));
      return To_String (Stripped);
   end Stripped_Of;

   function Process (Markdown_Path : String) return Natural is
      File : File_Type;
      Text : Unbounded_String;

   begin
      Open (File, In_File, Markdown_Path);
      while not End_Of_File (File) loop
         Append (Text, Get_Line (File));
         Append (Text, [1 => ASCII.LF]);
      end loop;
      Close (File);

      declare
         T : constant String := To_String (Text);
         Scenes : constant Scene_Span_Vectors.Vector :=
            Scan_Scenes (Markdown_Path, T);
         Stripped : constant String := Stripped_Of (T, Scenes);
      begin

         for Scene_Item of Scenes loop
            declare
               Target : constant String :=
                 To_String (Scene_Item.Target);
            begin
               if Index (Stripped, Target) = 0 then
                  raise Scene_Error
                    with Target & " is generated by a scene comment "
                         & "but not referenced in " & Markdown_Path;
               end if;
               declare
                  Output_Path : constant String :=
                    (if Directory_Of (Markdown_Path) = "."
                     then Target
                     else Directory_Of (Markdown_Path) & "/" & Target);
                  Directory : constant String :=
                    Directory_Of (Output_Path);
                  S : constant Scene :=
                    Parse_Scene (To_String (Scene_Item.Scene_Body));
                  Svg : constant String := Render (S);
                  Svg_File : File_Type;
               begin
                  if Directory /= "."
                    and then not Ada.Directories.Exists (Directory)
                  then
                     Ada.Directories.Create_Path (Directory);
                  end if;
                  Create (Svg_File, Out_File, Output_Path);
                  Put (Svg_File, Svg);
                  Close (Svg_File);
                  Put_Line ("  " & Output_Path);
               end;
            end;
         end loop;
         return Natural (Scenes.Length);
      end;
   end Process;

end Topodraw;

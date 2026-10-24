-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with Ada.Numerics;
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

   --  The font size of the diagram text, in pixels: every label
   --  metric derives from it, so a font change moves the whole
   --  label layout along.
   Font_Size : constant := 13;

   Margin : constant Long_Float := 48.0;

   --  The smallest positive divisor of the fitting and tick
   --  divisions: only the non-zero division matters, the value
   --  itself is arbitrary smallness. A guard, not an epsilon: two
   --  positions are never compared to it.
   Min_Divisor : constant Long_Float := 0.000_000_001;

   --  The dip of each horizontal axis under the horizon, in degrees:
   --  the X axis dips toward the lower right, the Y axis toward the
   --  lower left, and the Z axis stays vertical at full length. The
   --  dips are unequal and lower than the classic 30-30 isometry: the
   --  viewpoint is lower and off the (1, 1) diagonal, so the main
   --  diagonal of the grid, the exact blind direction of the 30-30
   --  view, projects apart.
   X_Dip : constant Long_Float := 22.0;
   Y_Dip : constant Long_Float := 17.0;

   X_Cos : constant Long_Float :=
     Ada.Numerics.Long_Elementary_Functions.Cos
       (X_Dip * Ada.Numerics.Pi / 180.0);
   X_Sin : constant Long_Float :=
     Ada.Numerics.Long_Elementary_Functions.Sin
       (X_Dip * Ada.Numerics.Pi / 180.0);
   Y_Cos : constant Long_Float :=
     Ada.Numerics.Long_Elementary_Functions.Cos
       (Y_Dip * Ada.Numerics.Pi / 180.0);
   Y_Sin : constant Long_Float :=
     Ada.Numerics.Long_Elementary_Functions.Sin
       (Y_Dip * Ada.Numerics.Pi / 180.0);

   Pt_Fill  : constant String := "#1f6feb";
   Pt_Text  : constant String := "#0d2b3e";
   Vec_Col  : constant String := "#1a7f37";
   Axis_Col : constant String := "#8b949e";
   Path_Col : constant String := "#6e7781";
   Font_Attr : constant String :=
     "font-family=""sans-serif"" font-size=""" &
     Trim (Font_Size'Image, Both) & """";

   type Coord3 is record
      X, Y, Z : Integer;
   end record;

   package Coord_Vectors is new Ada.Containers.Indefinite_Vectors
     (Positive, Coord3);

   type Screen2 is record
      X, Y : Long_Float;
   end record;

   type Axis_Def is record
      Tip    : Coord3;
      Letter : String (1 .. 1);
      Off    : Screen2;
   end record;

   type Pair_Def is record
      Axis : Coord3;
      Perp : Coord3;
   end record;

   function Int_Image (V : Integer) return String is
     (Trim (Integer'Image (V), Both));

   function Same_Position (A, B : Point_Rec) return Boolean is
     (A.X = B.X and then A.Y = B.Y and then A.Z = B.Z);

   --  The color of one scene item: the color given by the scene, or
   --  the default of the rendered diagrams when the scene left it
   --  empty.
   function Effective_Color
     (Color : Unbounded_String; Default : String) return String is
     (if Color = "" then Default else To_String (Color));

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
   --  Axonometric projection
   ---------------------------------------------------------------------------

   --  The raw screen coordinates of one grid position, before the
   --  scene is fitted onto the canvas: X and Y dip under the horizon
   --  by their axis dip, Z stays vertical.
   function Raw_X (C : Coord3) return Long_Float is
     (Long_Float (C.X) * X_Cos - Long_Float (C.Y) * Y_Cos);

   function Raw_Y (C : Coord3) return Long_Float is
     (Long_Float (C.X) * X_Sin + Long_Float (C.Y) * Y_Sin
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
           Long_Float'Max (Min_Divisor, Max_X - Min_X);
         Dy : constant Long_Float :=
           Long_Float'Max (Min_Divisor, Max_Y - Min_Y);
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

   --  The bounding box of one placed label, in screen coordinates: the
   --  width is the label length times the character width of the
   --  diagram font, the height is one label line.
   type Label_Box is record
      Left, Top, Right, Bottom : Long_Float;
   end record;

   --  The bound of the placed label boxes: one box per scene point
   --  label and one per labeled vector, far above the largest
   --  documentation scene; beyond it the placement raises
   --  Scene_Error instead of overflowing the array.
   Max_Placed_Labels : constant := 256;

   type Placed_Labels is array (1 .. Max_Placed_Labels) of Label_Box;

   --  The label metrics, derived from the font size so a font
   --  change moves the label layout along: the average character
   --  width was measured at font size 13 and scales linearly, one
   --  label line is two characters high, and the stacking shift is
   --  the font size plus a little air between two stacked lines.
   Char_Width           : constant Long_Float :=
     Long_Float (Font_Size) * 7.0 / 13.0;
   Line_Height          : constant Long_Float := 2.0 * Char_Width;
   Label_Vertical_Shift : constant Long_Float :=
     Long_Float (Font_Size) + 2.0;

   --  The SVG document under construction: the fitted projection of
   --  the scene, the text emitted so far, and the placed label boxes.
   --  The primitives append to the buffer; nothing is written to a
   --  file here.
   type SVG_Document is record
      Proj        : Projection;
      Buffer      : Unbounded_String;
      Labels      : Placed_Labels;
      Labels_Last : Natural := 0;
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

   --  True when no already placed label box overlaps the candidate.
   --  The deconfliction is decided in screen coordinates: two distinct
   --  scene positions can project to the same screen position, and the
   --  3D equality of the scene points would leave their labels stacked.
   function Label_Free (Doc : SVG_Document; B : Label_Box) return Boolean is
   begin
      for K in 1 .. Doc.Labels_Last loop
         if B.Left < Doc.Labels (K).Right
           and then Doc.Labels (K).Left < B.Right
           and then B.Top < Doc.Labels (K).Bottom
           and then Doc.Labels (K).Top < B.Bottom
         then
            return False;
         end if;
      end loop;
      return True;
   end Label_Free;

   --  Place one label, shifted down in screen coordinates while its
   --  box overlaps an already placed label box. The box width is the
   --  label length times the character width of the diagram font, its
   --  height is one label line.
   procedure Place_Label
     (Doc : in out SVG_Document; X, Y : Long_Float;
      Content, Color : String)
   is
      Left   : constant Long_Float := X;
      Right  : constant Long_Float :=
        X + Long_Float (Content'Length) * Char_Width;
      Top    : Long_Float := Y - Line_Height;
      Bottom : Long_Float := Y;
   begin
      while not Label_Free (Doc, (Left, Top, Right, Bottom)) loop
         Top    := Top + Label_Vertical_Shift;
         Bottom := Bottom + Label_Vertical_Shift;
      end loop;
      Text_At (Doc, Left, Bottom, Content, Color);
      if Doc.Labels_Last = Doc.Labels'Last then
         raise Scene_Error with "too many labels";
      end if;
      Doc.Labels_Last := Doc.Labels_Last + 1;
      Doc.Labels (Doc.Labels_Last) := (Left, Top, Right, Bottom);
   end Place_Label;

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

   --  The three axes with their letters, and the origin circle. The
   --  axis letters are placed labels: emitted before the scene labels,
   --  they take part in the label deconfliction, so a point label
   --  shifts down rather than covering an axis letter.
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
                  Place_Label (Doc, Tip.X + A.Off.X, Tip.Y + A.Off.Y,
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
                            (Min_Divisor, Sqrt (Vx * Vx + Vy * Vy));
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
                       Effective_Color (Pt.Color, Pt_Fill),
                       "#ffffff", 1.5);
            else
               Circle (Doc, Pos, Long_Float (5 + 4 * Dup), "none",
                       Effective_Color (Pt.Color, Pt_Fill),
                       1.5, "3 2");
            end if;
            declare
               Label : constant String :=
                 To_String (Pt.Name) & " (" & Int_Image (Pt.X)
                 & ", " & Int_Image (Pt.Y) & ", "
                 & Int_Image (Pt.Z) & ")";
            begin
               Place_Label (Doc, Pos.X + 10.0,
                            Pos.Y - 10.0 + Label_Vertical_Shift
                              * Long_Float (Dup),
                            Label, Pt_Text);
            end;
         end;
      end loop;
   end Emit_Points;

   --  The arrow markers of the vector colors, then one arrow per
   --  vector, with its label at the middle. A label that would overlap
   --  an already placed one is shifted down until its box is free,
   --  through the shared Place_Label of the document.
   procedure Emit_Vectors (Doc : in out SVG_Document; S : Scene) is

      --  The bound of the arrow marker colors: one marker per distinct
      --  vector color, far above the largest documentation scene;
      --  beyond it the registration raises Scene_Error instead of
      --  overflowing the array.
      Max_Colors : constant := 8;
      Colors     : array (1 .. Max_Colors) of Unbounded_String;
      Count      : Natural := 0;

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

      --  One arrow marker: a small filled triangle, in the color of
      --  the vectors it points.
      procedure Emit_Marker (Id : String; Color : String) is
      begin
         Append (Doc.Buffer, "<marker id=""" & Id
                 & """ markerWidth=""10"" "
                 & "markerHeight=""10"" refX=""8"" refY=""3"" "
                 & "orient=""auto""><path d=""M0,0 L8,3 L0,6 z"" fill="""
                 & Color & """/></marker>");
      end Emit_Marker;

   begin
      for V of S.Vectors loop
         Register_Color (V.Color);
      end loop;

      Append (Doc.Buffer, "<defs>");
      Emit_Marker ("arrow", Vec_Col);
      for K in 1 .. Count loop
         Emit_Marker ("arrow" & Trim (K'Image, Both),
                      To_String (Colors (K)));
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
              Effective_Color (V.Color, Vec_Col);
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
               Place_Label (Doc, (A.X + B.X) / 2.0,
                            (A.Y + B.Y) / 2.0 - 8.0,
                            To_String (V.Label), Line_Color);
            end if;
         end;
      end loop;
   end Emit_Vectors;

   function Render (S : Scene) return String is
      Unit    : constant Integer := Scene_Unit (S);
      Anchors : constant Coord_Vectors.Vector :=
        Collect_Anchors (S, Unit);
      Doc     : SVG_Document :=
        (Proj        => Fit (Anchors),
         Buffer      => Null_Unbounded_String,
         Labels      => [others => (0.0, 0.0, 0.0, 0.0)],
         Labels_Last => 0);
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

end Topodraw;

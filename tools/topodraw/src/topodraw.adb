-- -----------------------------------------------------------------------------
-- TopoProof, provable geometry application
-- (https://github.com/LionelDraghi/topoproof)
-- SPDX-License-Identifier: Apache-2.0
-- SPDX-FileCopyrightText: 2026, Lionel Draghi
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
                  if S.Tick_Step <= 0 then
                     raise Scene_Error
                       with "line" & Integer'Image (Line_No)
                            & ": STEP must be positive";
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
                         Z         => Integer'Value (To_String (Cz))));
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
                                    Label     => Rest_Label));
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

   function Render (S : Scene) return String is
      use Ada.Numerics.Long_Elementary_Functions;

      Buffer : Unbounded_String;
      Anchors : Coord_Vectors.Vector;
      Unit : Integer := 1;

   begin
      declare
         M : Integer := 0;
      begin

         for Pt of S.Points loop
            M := Integer'Max (M, abs Pt.X);
            M := Integer'Max (M, abs Pt.Y);
            M := Integer'Max (M, abs Pt.Z);
         end loop;
         Unit := Integer'Max (1, M);
      end;

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

      declare
         Min_X : Long_Float := Long_Float'Last;
         Max_X : Long_Float := Long_Float'First;
         Min_Y : Long_Float := Long_Float'Last;
         Max_Y : Long_Float := Long_Float'First;

         function Raw_X (C : Coord3) return Long_Float is
           ((Long_Float (C.X) - Long_Float (C.Y)) * Cos30);

         function Raw_Y (C : Coord3) return Long_Float is
           ((Long_Float (C.X) + Long_Float (C.Y)) * Sin30
            - Long_Float (C.Z));

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

            function To_Screen (C : Coord3) return Screen2 is
              (Raw_X (C) * Scale + Ox, Raw_Y (C) * Scale + Oy);

            procedure Append_F (V : Long_Float) is
               Tmp : String (1 .. 24);
            begin

               LF_IO.Put (Tmp, V, Aft => 1, Exp => 0);
               Append (Buffer, Trim (Tmp, Both));
            end Append_F;

            procedure Line
              (A, B : Screen2; Color : String; Width : Long_Float;
               Dash : String := ""; Marker : String := "")
            is
            begin

               Append (Buffer, "<line x1=""");
               Append_F (A.X);
               Append (Buffer, """ y1=""");
               Append_F (A.Y);
               Append (Buffer, """ x2=""");
               Append_F (B.X);
               Append (Buffer, """ y2=""");
               Append_F (B.Y);
               Append (Buffer, """ stroke=""" & Color);
               Append (Buffer, """ stroke-width=""");
               Append_F (Width);
               if Dash /= "" then
                  Append (Buffer, """ stroke-dasharray=""" & Dash);
               end if;
               if Marker /= "" then
                  Append (Buffer, """ marker-end=""" & Marker);
               end if;
               Append (Buffer, """/>" & ASCII.LF);
            end Line;

            procedure Circle
              (C : Screen2; R : Long_Float; Fill : String;
               Stroke : String := ""; Stroke_Width : Long_Float := 1.0;
               Dash : String := "")
            is
            begin

               Append (Buffer, "<circle cx=""");
               Append_F (C.X);
               Append (Buffer, """ cy=""");
               Append_F (C.Y);
               Append (Buffer, """ r=""");
               Append_F (R);
               Append (Buffer, """ fill=""" & Fill);
               if Stroke /= "" then
                  Append (Buffer, """ stroke=""" & Stroke);
                  Append (Buffer, """ stroke-width=""");
                  Append_F (Stroke_Width);
                  if Dash /= "" then
                     Append (Buffer, """ stroke-dasharray=""" & Dash);
                  end if;
               end if;
               Append (Buffer, """/>" & ASCII.LF);
            end Circle;

            procedure Text_At
              (X, Y : Long_Float; Content : String; Color : String)
            is
            begin

               Append (Buffer, "<text x=""");
               Append_F (X);
               Append (Buffer, """ y=""");
               Append_F (Y);
               Append (Buffer, """ fill=""" & Color & """ " & Font_Attr);
               Append (Buffer, ">" & Content & "</text>" & ASCII.LF);
            end Text_At;

         begin
            Append (Buffer, "<svg xmlns=""http://www.w3.org/2000/svg"" "
                    & "viewBox=""0 0 " & Int_Image (W) & " "
                    & Int_Image (H) & """ width=""" & Int_Image (W)
                    & """ height=""" & Int_Image (H) & """>" & ASCII.LF);
            Append (Buffer, "<rect width=""" & Int_Image (W)
                    & """ height=""" & Int_Image (H)
                    & """ fill=""#ffffff""/>" & ASCII.LF);

            if S.Anchors then
               --  coordinate path of each point: dashed segments from the
               --  origin along X, then parallel to Y, then parallel to Z
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
                           Line (To_Screen (Prev), To_Screen (Path (K)),
                                 Path_Col, 1.0, "4 3");
                           Found := True;
                        end if;
                        Prev := Path (K);
                     end loop;
                     pragma Assert (Found or else Path (1) = Path (4));
                     for K in 2 .. 3 loop
                        Circle (To_Screen (Path (K)), 2.5, "#ffffff",
                                Path_Col, 1.0);
                     end loop;
                  end;
               end loop;
            end if;

            if S.Draw_Axes then
               declare
                  O : constant Screen2 := To_Screen ((0, 0, 0));
                  Axes : constant array (1 .. 3) of Axis_Def :=
                      [((1, 0, 0), "X", (6.0, 14.0)),
                       ((0, 1, 0), "Y", (-16.0, 14.0)),
                       ((0, 0, 1), "Z", (0.0, -6.0))];
               begin

                  for A of Axes loop
                     declare
                        Tip : constant Screen2 := To_Screen (A.Tip);
                     begin
                        Line (O, Tip, Axis_Col, 1.0, "4 3");
                        Text_At (Tip.X + A.Off.X, Tip.Y + A.Off.Y,
                                 A.Letter, Axis_Col);
                     end;
                  end loop;
                  Circle (O, 2.5, Axis_Col);
               end;
            end if;

            if S.Tick_Step >= 0 then
               --  tick marks along the axes, every STEP units
               declare
                  Step : constant Integer :=
                    (if S.Tick_Step = 0
                     then Integer'Max (1, (Unit + 9) / 10)
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
                              A : constant Screen2 := To_Screen (Pos);
                              B : constant Screen2 :=
                                To_Screen
                                  ((Pos.X + P.Perp.X, Pos.Y + P.Perp.Y,
                                    Pos.Z + P.Perp.Z));
                              Vx : constant Long_Float := B.X - A.X;
                              Vy : constant Long_Float := B.Y - A.Y;
                              Norm : constant Long_Float :=
                                Long_Float'Max
                                  (0.000_000_001, Sqrt (Vx * Vx + Vy * Vy));
                              Dx : constant Long_Float := 5.0 * Vx / Norm;
                              Dy : constant Long_Float := 5.0 * Vy / Norm;
                           begin
                              Line ((A.X - Dx, A.Y - Dy),
                                    (A.X + Dx, A.Y + Dy),
                                    Axis_Col, 1.0);
                           end;
                           T := T + Step;
                        end loop;
                     end;
                  end loop;
               end;
            end if;

            for I in S.Points.First_Index .. S.Points.Last_Index loop
               declare
                  Pt : constant Point_Rec := S.Points (I);
                  Pos : constant Screen2 := To_Screen ((Pt.X, Pt.Y, Pt.Z));
                  Dup : Natural := 0;
               begin

                  for J in S.Points.First_Index .. I - 1 loop
                     if Same_Position (S.Points (J), Pt) then
                        Dup := Dup + 1;
                     end if;
                  end loop;
                  if Dup = 0 then
                     Circle (Pos, 5.0, Pt_Fill, "#ffffff", 1.5);
                  else
                     Circle (Pos, Long_Float (5 + 4 * Dup), "none",
                             Pt_Fill, 1.5, "3 2");
                  end if;
                  declare
                     Label : constant String :=
                       To_String (Pt.Name) & " (" & Int_Image (Pt.X)
                       & ", " & Int_Image (Pt.Y) & ", "
                       & Int_Image (Pt.Z) & ")";
                  begin
                     Text_At (Pos.X + 10.0,
                              Pos.Y - 10.0 + Long_Float (30 * Dup),
                              Label, Pt_Text);
                  end;
               end;
            end loop;

            Append (Buffer, "<defs><marker id=""arrow"" markerWidth=""10"" "
                    & "markerHeight=""10"" refX=""8"" refY=""3"" "
                    & "orient=""auto""><path d=""M0,0 L8,3 L0,6 z"" fill="""
                    & Vec_Col & """/></marker></defs>" & ASCII.LF);
            for V of S.Vectors loop
               declare
                  From : constant Point_Rec :=
                    Find_Point (S, To_String (V.From_Name));
                  To   : constant Point_Rec :=
                    Find_Point (S, To_String (V.To_Name));
                  A : constant Screen2 := To_Screen ((From.X, From.Y, From.Z));
                  B : constant Screen2 := To_Screen ((To.X, To.Y, To.Z));
               begin

                  if Same_Position (From, To) then
                     raise Scene_Error
                       with "vector " & To_String (V.From_Name) & " -> "
                            & To_String (V.To_Name)
                            & ": coincident points";
                  end if;
                  Line (A, B, Vec_Col, 2.0, "", "url(#arrow)");
                  if To_String (V.Label) /= "" then
                     Text_At ((A.X + B.X) / 2.0, (A.Y + B.Y) / 2.0 - 8.0,
                              To_String (V.Label), Vec_Col);
                  end if;
               end;
            end loop;

            Append (Buffer, "</svg>");
         end;
      end;
      return To_String (Buffer);
   end Render;

   function Directory_Of (Path : String) return String is
   begin

      for I in reverse Path'Range loop
         if Path (I) = '/' then
            return Path (Path'First .. I - 1);
         end if;
      end loop;
      return ".";
   end Directory_Of;

   function Process (Markdown_Path : String) return Natural is
      File : File_Type;
      Text : Unbounded_String;
      Scenes : Scene_Span_Vectors.Vector;

   begin
      Open (File, In_File, Markdown_Path);
      while not End_Of_File (File) loop
         Append (Text, Get_Line (File));
         Append (Text, [1 => ASCII.LF]);
      end loop;
      Close (File);

      declare
         T : constant String := To_String (Text);
         I : Natural := Index (T, "<!--");
         Stripped : Unbounded_String;
         Last_Copied : Natural := T'First - 1;
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
                  begin
                     while K <= T'Last
                       and then (T (K) = ' ' or else T (K) = ASCII.HT)
                     loop
                        K := K + 1;
                     end loop;
                     Target_Start := K;
                     while K <= T'Last
                       and then T (K) /= ' ' and then T (K) /= ASCII.HT
                       and then T (K) /= ASCII.LF
                       and then T (K) /= ASCII.CR
                     loop
                        K := K + 1;
                     end loop;
                     Target := To_Unbounded_String
                       (T (Target_Start .. K - 1));
                     while K <= T'Last
                       and then (T (K) = ' ' or else T (K) = ASCII.HT)
                     loop
                        K := K + 1;
                     end loop;
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

         for Scene_Item of Scenes loop
            Append (Stripped,
                    T (Last_Copied + 1 .. Scene_Item.Start - 1));
            Last_Copied := Scene_Item.Finish;
         end loop;
         Append (Stripped, T (Last_Copied + 1 .. T'Last));

         for Scene_Item of Scenes loop
            declare
               Target : constant String :=
                 To_String (Scene_Item.Target);
            begin
               if Index (To_String (Stripped), Target) = 0 then
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

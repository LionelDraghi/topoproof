pragma Ada_2022;

--  The archived visual direction (2026-10-25): the soft-extruded
--  slate sketchbook. One surface colour everywhere - the window, the
--  menu bar, the status line and the widgets share it - and the
--  relief comes from a soft dark shadow towards the bottom right,
--  completed by a light top and left border edge (Adi2 carries one
--  box shadow per widget, not the dual shadow of the classic
--  neumorphism). The pressed state inverts the edges: the widget
--  reads as pressed in. The canvas is the hero: same surface, a large
--  quiet inset.
--
--  Archived by the owner's decision of 2026-10-29: TopoGUI moved to
--  the light, flat Material direction (Topogui.Theme.Material). This
--  package is the return path: bind it from Topogui.Theme's body to
--  restore the look. It predates the context-menu styles (Menu_*),
--  which the direction never styled - supply them when switching
--  back.

with Adi.CSS_Styles;

package Topogui.Theme.Neumorphic is

   use Adi.CSS_Styles;

   --  The one surface colour, shared by everything.

   Surface : constant Color_Value := RGB (224, 229, 236);

   --  The relief.

   Shadow_Dark : constant Color_Value := RGBA (163, 177, 198, 0.7);
   Edge_Light  : constant Color_Value := RGB (255, 255, 255);
   Edge_Shade  : constant Color_Value := RGB (184, 194, 206);

   --  The inks.

   Slate_Text : constant Color_Value := RGB (90, 100, 115);
   Muted_Text : constant Color_Value := RGB (150, 160, 175);

   --  The drawing inks (v0 increment 2, drawing-model.md): the accent
   --  colours the constructed geometry, the grid inks stay quieter
   --  than the text.

   Accent    : constant Color_Value := RGB (58, 90, 140);
   Grid_Line : constant Color_Value := RGB (213, 218, 226);
   Grid_Axis : constant Color_Value := RGB (185, 192, 204);

   --  The same inks in the SVG text form the canvas renders with
   --  (hex notation, as the kernel's own SVG output).

   Surface_Svg   : constant String := "#e0e5ec";
   Accent_Svg    : constant String := "#3a5a8c";
   Grid_Line_Svg : constant String := "#d5dae2";
   Grid_Axis_Svg : constant String := "#b9c0cc";

   Extruded_Edge : constant Border_Width_Value := Border_Width (Px (1.0));
   --  A border width or colour only paints if the border style is set:
   --  the Adi2 renderer honours the CSS rule that suppresses borders
   --  whose style is none (the default).

   Solid_Edges : constant Border_Style_Value := Border_Style (Solid);

   Extruded_Edge_Colors : constant Border_Color_Value :=
     Border_Color (Top    => Edge_Light,
                   Left   => Edge_Light,
                   Right  => Edge_Shade,
                   Bottom => Edge_Shade);

   Pressed_Edge_Colors : constant Border_Color_Value :=
     Border_Color (Top    => Edge_Shade,
                   Left   => Edge_Shade,
                   Right  => Edge_Light,
                   Bottom => Edge_Light);

   Root_Style : constant Style_Rules :=
     (Display          => Set (Flex),
      Flex_Direction   => Set (Column),
      Background_Color => Set_Bg (Surface),
      others           => <>);

   Bar_Style : constant Style_Rules :=
     (Display          => Set (Flex),
      Flex_Direction   => Set (Row),
      Gap              => Set (Gap (Px (10.0))),
      Padding          => Set (CSS_Box (Px (8.0), Px (12.0))),
      Background_Color => Set_Bg (Surface),
      Box_Shadow       => Set (Shadow
        (Px (6.0), Px (6.0), Px (14.0), Px (0.0), Shadow_Dark)),
      Border_Radius    => Set (Radius (Px (12.0))),
      Border_Width     => Set (Extruded_Edge),
      Border_Color     => Set (Extruded_Edge_Colors),
      Border_Style     => Set (Solid_Edges),
      others           => <>);

   Button_Base : constant Style_Rules :=
     (Display          => Set (Inline_Flex),
      Justify_Content  => Set (Justify_Content_Value'(Center)),
      Align_Items      => Set (Align_Items_Value'(Center)),
      Background_Color => Set_Bg (Surface),
      Padding          => Set (CSS_Box (Px (8.0), Px (14.0))),
      Box_Shadow       => Set (Shadow
        (Px (5.0), Px (5.0), Px (10.0), Px (0.0), Shadow_Dark)),
      Border_Radius    => Set (Radius (Px (10.0))),
      Border_Width     => Set (Extruded_Edge),
      Border_Color     => Set (Extruded_Edge_Colors),
      Border_Style     => Set (Solid_Edges),
      Cursor           => Set (Cursor_Pointer),
      others           => <>);

   --  The pressed state swaps the edge colours and drops the shadow:
   --  the widget reads as pressed in.

   Button_Pressed : constant Style_Rules :=
     (Background_Color => Set_Bg (Surface),
      Box_Shadow       => Set (No_Shadow),
      Border_Width     => Set (Extruded_Edge),
      Border_Color     => Set (Pressed_Edge_Colors),
      Border_Style     => Set (Solid_Edges),
      others           => <>);

   Button_Label : constant Style_Rules :=
     (Color       => Set (Slate_Text),
      Font_Size   => Set_Font (Px (15.0)),
      Font_Weight => Set (Weight_Bold),
      others      => <>);

   Canvas_Style : constant Style_Rules :=
     (Display          => Set (Flex),
      Flex_Grow        => Set (Flex_Grow_Value'(1.0)),
      Background_Color => Set_Bg (Surface),
      Border_Width     => Set (Extruded_Edge),
      Border_Color     => Set (Pressed_Edge_Colors),
      Border_Style     => Set (Solid_Edges),
      others           => <>);

   Status_Style : constant Style_Rules :=
     (Display          => Set (Flex),
      Flex_Direction   => Set (Row),
      Padding          => Set (CSS_Box (Px (8.0), Px (14.0))),
      Background_Color => Set_Bg (Surface),
      Border_Width     => Set (Extruded_Edge),
      Border_Color     => Set (Pressed_Edge_Colors),
      Border_Style     => Set (Solid_Edges),
      others           => <>);

   Status_Text : constant Style_Rules :=
     (Color     => Set (Muted_Text),
      Font_Size => Set_Font (Px (14.0)),
      others    => <>);

end Topogui.Theme.Neumorphic;

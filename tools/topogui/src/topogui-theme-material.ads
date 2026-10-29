pragma Ada_2022;

--  The current visual direction (2026-10-29): the light, flat,
--  Flutter-like look, in the spirit of the PaliCAD reference - a
--  minimal, uncluttered CAD front-end. White panels and canvas on a
--  near-white ground, hairline dividers where the panels meet, one
--  blue accent, and the relief reduced to the soft shadow a raised
--  card deserves. No extrusion, no pressed-depth inversion: the
--  pressed state is a shade, the way Material buttons read. The
--  context menus are plain white cards with shaded item rows.

with Adi.CSS_Styles;

package Topogui.Theme.Material is

   use Adi.CSS_Styles;

   --  The surface hierarchy, from the app ground to the raised cards.

   Ground  : constant Color_Value := RGB (247, 248, 250);
   Panel   : constant Color_Value := RGB (255, 255, 255);
   Divider : constant Color_Value := RGB (229, 231, 235);
   Shade   : constant Color_Value := RGB (241, 243, 245);
   Pressed : constant Color_Value := RGB (232, 234, 237);

   --  The inks.

   Text_High : constant Color_Value := RGB (32, 33, 36);
   Text_Mid  : constant Color_Value := RGB (110, 119, 129);
   Accent    : constant Color_Value := RGB (30, 136, 229);

   --  The drawing inks: the canvas is the hero, pure white, and the
   --  grid stays quieter than the ink.

   Grid_Line : constant Color_Value := RGB (238, 240, 243);
   Grid_Axis : constant Color_Value := RGB (213, 218, 226);

   --  The SVG text forms the canvas renders with (hex notation, as
   --  the kernel's own SVG output).

   Surface_Svg   : constant String := "#ffffff";
   Accent_Svg    : constant String := "#1e88e5";
   Grid_Line_Svg : constant String := "#eef0f3";
   Grid_Axis_Svg : constant String := "#d5dae2";

   --  The card relief: one soft shadow below, no borders.

   Card_Shadow : constant Box_Shadow_Value :=
     Shadow (Px (0.0), Px (1.0), Px (3.0), Px (0.0), RGBA (0, 0, 0, 0.12));
   Menu_Shadow : constant Box_Shadow_Value :=
     Shadow (Px (0.0), Px (2.0), Px (8.0), Px (0.0), RGBA (0, 0, 0, 0.15));

   Root_Style : constant Style_Rules :=
     (Display          => Set (Flex),
      Flex_Direction   => Set (Column),
      Background_Color => Set_Bg (Ground),
      others           => <>);

   Bar_Style : constant Style_Rules :=
     (Display          => Set (Flex),
      Flex_Direction   => Set (Row),
      Gap              => Set (Gap (Px (8.0))),
      Padding          => Set (CSS_Box (Px (8.0), Px (12.0))),
      Background_Color => Set_Bg (Panel),
      Box_Shadow       => Set (Card_Shadow),
      others           => <>);

   Button_Base : constant Style_Rules :=
     (Display          => Set (Inline_Flex),
      Justify_Content  => Set (Justify_Content_Value'(Center)),
      Align_Items      => Set (Align_Items_Value'(Center)),
      Background_Color => Set_Bg (C (Transparent)),
      Padding          => Set (CSS_Box (Px (8.0), Px (14.0))),
      Border_Radius    => Set (Radius (Px (8.0))),
      Cursor           => Set (Cursor_Pointer),
      others           => <>);

   Button_Hover : constant Style_Rules :=
     (Background_Color => Set_Bg (Shade),
      others           => <>);

   Button_Pressed : constant Style_Rules :=
     (Background_Color => Set_Bg (Pressed),
      Box_Shadow       => Set (No_Shadow),
      others           => <>);

   Button_Label : constant Style_Rules :=
     (Color       => Set (Text_High),
      Font_Size   => Set_Font (Px (14.0)),
      Font_Weight => Set (Weight_Medium),
      others      => <>);

   Canvas_Style : constant Style_Rules :=
     (Display          => Set (Flex),
      Flex_Grow        => Set (Flex_Grow_Value'(1.0)),
      Background_Color => Set_Bg (C (Transparent)),
      Border_Width     => Set (Border_Width (Px (1.0))),
      Border_Color     => Set (Border_Color (Divider)),
      Border_Style     => Set (Border_Style (Solid)),
      Overflow_X       => Set (Overflow_Hidden),
      Overflow_Y       => Set (Overflow_Hidden),
      others           => <>);

   Status_Style : constant Style_Rules :=
     (Display          => Set (Flex),
      Flex_Direction   => Set (Row),
      Padding          => Set (CSS_Box (Px (8.0), Px (14.0))),
      Background_Color => Set_Bg (Panel),
      Border_Width     => Set (Border_Width (Top    => Px (1.0),
                                             Right  => Px (0.0),
                                             Bottom => Px (0.0),
                                             Left   => Px (0.0))),
      Border_Color     => Set (Border_Color (Divider)),
      Border_Style     => Set (Border_Style (Solid)),
      others           => <>);

   Status_Text : constant Style_Rules :=
     (Color     => Set (Text_Mid),
      Font_Size => Set_Font (Px (14.0)),
      others    => <>);

   --  The context menu: a white card, and the item rows shaded on
   --  hover, the way a Material menu reads.

   Menu_Style : constant Style_Rules :=
     (Background_Color => Set_Bg (Panel),
      Border_Width     => Set (Border_Width (Px (1.0))),
      Border_Color     => Set (Border_Color (Divider)),
      Border_Style     => Set (Border_Style (Solid)),
      Border_Radius    => Set (Radius (Px (8.0))),
      Box_Shadow       => Set (Menu_Shadow),
      Padding          => Set (CSS_Box (Px (4.0), Px (0.0))),
      others           => <>);

   Menu_Item_Style : constant Style_Rules :=
     (Color        => Set (Text_High),
      Font_Size    => Set_Font (Px (14.0)),
      Padding      => Set (CSS_Box (Px (8.0), Px (16.0))),
      Border_Radius => Set (Radius (Px (6.0))),
      others       => <>);

   Menu_Item_Hover : constant Style_Rules :=
     (Background_Color => Set_Bg (Shade),
      others           => <>);

end Topogui.Theme.Material;

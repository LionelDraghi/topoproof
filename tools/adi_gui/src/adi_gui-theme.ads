-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

--  The theme contract of the Adi_GUI views: the widget styles and the
--  SVG ink colours the views consume, independent of the visual
--  direction in effect. The body binds the contract to one direction
--  package; the directions live in their own child packages, one per
--  look:
--
--  - Adi_Gui.Theme.Neumorphic: the soft-extruded slate sketchbook
--    (2026-10-25), archived as built;
--  - Adi_Gui.Theme.Material: the light, flat, Flutter-like direction
--    (2026-10-29) - the PaliCAD clarity: white panels, one blue
--    accent, hairline dividers, no extrusion.
--
--  Switching direction is a body change, not a view change. The
--  accessors are parameterless functions, not deferred constants: a
--  deferred composite constant freezes on its first use, before its
--  completion is reached.

with Adi.CSS_Styles;

package Adi_Gui.Theme is

   --  The widget styles, one rule set per widget role. The state
   --  variants (hover, press) are separate rule sets: the views
   --  compose base + variants with the style builder, the way Adi2
   --  styles are stated.

   function Root_Style     return Adi.CSS_Styles.Style_Rules;
   function Bar_Style      return Adi.CSS_Styles.Style_Rules;
   function Canvas_Style   return Adi.CSS_Styles.Style_Rules;
   function Status_Style   return Adi.CSS_Styles.Style_Rules;
   function Status_Text    return Adi.CSS_Styles.Style_Rules;
   function Button_Base    return Adi.CSS_Styles.Style_Rules;
   function Button_Hover   return Adi.CSS_Styles.Style_Rules;
   function Button_Pressed return Adi.CSS_Styles.Style_Rules;
   function Button_Label   return Adi.CSS_Styles.Style_Rules;

   --  The context menus: the popup box, the item row, and its hover
   --  shade.

   function Menu_Style      return Adi.CSS_Styles.Style_Rules;
   function Menu_Item_Style return Adi.CSS_Styles.Style_Rules;
   function Menu_Item_Hover return Adi.CSS_Styles.Style_Rules;

   --  The drawing inks in the SVG text form the canvas renders with
   --  (hex notation, as the kernel's own SVG output). The selection
   --  ink is distinct from the accent: it names the selected vertex of
   --  the Select mode, not the drawing ink (drawing-model.md).

   function Surface_Svg   return String;
   function Accent_Svg    return String;
   function Selection_Svg return String;
   function Grid_Line_Svg return String;
   function Grid_Axis_Svg return String;

end Adi_Gui.Theme;

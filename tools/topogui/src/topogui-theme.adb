pragma Ada_2022;

--  The theme selection: the contract binds to the light Material
--  direction. To return to the soft-extruded slate sketchbook, bind
--  Topogui.Theme.Neumorphic here instead - its rule sets carry the
--  same names (see that package for the Menu_* caveat).

with Adi.CSS_Styles;
with Topogui.Theme.Material;

use Adi.CSS_Styles;

package body Topogui.Theme is

   function Root_Style return Style_Rules is (Material.Root_Style);
   function Bar_Style  return Style_Rules is (Material.Bar_Style);
   function Canvas_Style return Style_Rules is (Material.Canvas_Style);
   function Status_Style return Style_Rules is (Material.Status_Style);
   function Status_Text  return Style_Rules is (Material.Status_Text);
   function Button_Base    return Style_Rules is (Material.Button_Base);
   function Button_Hover   return Style_Rules is (Material.Button_Hover);
   function Button_Pressed return Style_Rules is (Material.Button_Pressed);
   function Button_Label   return Style_Rules is (Material.Button_Label);

   function Menu_Style      return Style_Rules is (Material.Menu_Style);
   function Menu_Item_Style return Style_Rules is (Material.Menu_Item_Style);
   function Menu_Item_Hover return Style_Rules is (Material.Menu_Item_Hover);

   function Surface_Svg   return String is (Material.Surface_Svg);
   function Accent_Svg    return String is (Material.Accent_Svg);
   function Grid_Line_Svg return String is (Material.Grid_Line_Svg);
   function Grid_Axis_Svg return String is (Material.Grid_Axis_Svg);

end Topogui.Theme;

pragma Ada_2022;

with Adi.App;
with Adi.CSS_Styles;
with Adi.Log;
with Adi.Widget;
with Adi.Widget.Box;
with Adi.Widget.Button;
with Adi.Widget.Context_Menu;
with Adi.Widget.Label;
with Adi.Widget_Styles;
with Adi.Window;
with Topogui.Canvas;
with Topogui.Theme;

use Adi.CSS_Styles;
use Adi.Widget;
use Adi.Widget_Styles;
use Adi.Window;
use Topogui.Theme;

use type Adi.Widget.Box.Box_Handle;
use type Adi.Widget.Label.Label_Handle;
use type Adi.Widget.Button.Button_Handle;

package body Topogui.Main_Window is

   function Style return Style_Builder renames Adi.Widget_Styles.Create;

   --  The context menus open just below the menu bar, over the canvas.
   --  The X offsets track the horizontal position of their bar buttons,
   --  which the bar style owns; if the bar layout changes, these move
   --  with it.

   File_Menu_X   : constant := 8.0;
   Sketch_Menu_X : constant := 62.0;
   Menu_Y        : constant := 38.0;

   File_Menu   : Adi.Widget.Context_Menu.Menu_Handle;
   Sketch_Menu : Adi.Widget.Context_Menu.Menu_Handle;

   --  The status line reports the kernel traces and rejections; the
   --  label handle lives here because the canvas reports from its own
   --  gesture handling.
   Status_Label : Adi.Widget.Label.Label_Handle;

   procedure On_Status (Text : String) is
   begin
      Adi.Widget.Label.Set_Text (Status_Label, Text);
   end On_Status;

   procedure On_File_Click (Btn : Widget_Handle) is
      pragma Unreferenced (Btn);
   begin
      Adi.Widget.Context_Menu.Show_At (File_Menu, File_Menu_X, Menu_Y);
   end On_File_Click;

   procedure On_Sketch_Click (Btn : Widget_Handle) is
      pragma Unreferenced (Btn);
   begin
      Adi.Widget.Context_Menu.Show_At (Sketch_Menu, Sketch_Menu_X, Menu_Y);
   end On_Sketch_Click;

   procedure On_File_Item
     (Menu  : Adi.Widget.Context_Menu.Menu_Handle;
      Index : Positive;
      Text  : String)
   is
      pragma Unreferenced (Menu, Index);
   begin
      if Text = "Quit" then
         Adi.App.Request_Quit;
      else
         Adi.Log.Info ("File: " & Text & " (not implemented yet)");
      end if;
   end On_File_Item;

   procedure On_Sketch_Item
     (Menu  : Adi.Widget.Context_Menu.Menu_Handle;
      Index : Positive;
      Text  : String)
   is
      pragma Unreferenced (Menu, Index);
   begin
      if Text = "Point" then
         Topogui.Canvas.Set_Mode (Topogui.Canvas.Draw_Point);
      elsif Text = "Edge" then
         Topogui.Canvas.Set_Mode (Topogui.Canvas.Draw_Edge);
      elsif Text = "Loop" then
         Topogui.Canvas.Set_Mode (Topogui.Canvas.Draw_Loop);
      elsif Text = "Face" then
         Topogui.Canvas.Submit_Face;
      end if;
   end On_Sketch_Item;

   procedure Make_Menu_Button
     (Parent   : Widget_Handle;
      Text     : String;
      On_Click : Adi.Widget.Button.Click_Callback)
   is
      Btn : constant Adi.Widget.Button.Button_Handle :=
        Adi.Widget.Button.Create_Handle (Text);
   begin
      Set_Part_Style (Widget_Handle'(+Btn), Main_Part,
                      Style.Base (Button_Base)
                        .On_Hover (Button_Hover)
                        .On_Press (Button_Pressed).Build);
      Set_Part_Style (Widget_Handle'(+Btn), Label_Part,
                      Style.Base (Button_Label).Build);
      Adi.Widget.Button.Connect_Clicked (Btn, On_Click);
      Add_Child (Parent, Widget_Handle'(+Btn));
   end Make_Menu_Button;

   --  The context menus are white cards with shaded item rows (the
   --  theme owns the look): the popup box takes Menu_Style, the item
   --  rows Menu_Item_Style with their hover shade.

   procedure Style_Menu
     (Menu : Adi.Widget.Context_Menu.Menu_Handle)
   is
      Box : constant Adi.Widget_Styles.Widget_Style :=
        Style.Base (Menu_Style).Build;
      Row : constant Adi.Widget_Styles.Widget_Style :=
        Style.Base (Menu_Item_Style).On_Hover (Menu_Item_Hover).Build;
   begin
      Adi.Widget.Context_Menu.Set_Menu_Part_Styles
        (Menu, [Adi.Widget.Main_Part => (Style => Box, others => <>),
                others               => <>]);
      Adi.Widget.Context_Menu.Set_Item_Part_Styles
        (Menu, [Adi.Widget.Main_Part => (Style => Row, others => <>),
                others               => <>]);
   end Style_Menu;

   function Build return Window_Handle is
      W : constant Window_Handle :=
        Create_Window_Handle
          ("TopoGUI", Adi.Window.Extent (Px (800.0), Px (560.0)));
   begin
      declare
         Root   : constant Adi.Widget.Box.Box_Handle :=
           Adi.Widget.Box.Create_Handle;
         Bar    : constant Adi.Widget.Box.Box_Handle :=
           Adi.Widget.Box.Create_Handle;
         Canvas : constant Adi.Widget.Widget_Handle :=
           Topogui.Canvas.Create (W);
         Status : constant Adi.Widget.Box.Box_Handle :=
           Adi.Widget.Box.Create_Handle;
      begin
         Status_Label := Adi.Widget.Label.Create_Handle ("Ready.");

         Set_Part_Style (Widget_Handle'(+Root), Main_Part,
                         Style.Base (Root_Style).Build);
         Set_Part_Style (Widget_Handle'(+Bar), Main_Part,
                         Style.Base (Bar_Style).Build);
         Set_Part_Style (Canvas, Main_Part,
                         Style.Base (Canvas_Style).Build);
         Set_Part_Style (Widget_Handle'(+Status), Main_Part,
                         Style.Base (Status_Style).Build);
         Set_Part_Style (Widget_Handle'(+Status_Label), Label_Part,
                         Style.Base (Status_Text).Build);

         Make_Menu_Button (Widget_Handle'(+Bar), "File",
                           On_File_Click'Unrestricted_Access);
         Make_Menu_Button (Widget_Handle'(+Bar), "Sketch",
                           On_Sketch_Click'Unrestricted_Access);
         Add_Child (Widget_Handle'(+Status), Widget_Handle'(+Status_Label));

         Add_Child (Widget_Handle'(+Root), Widget_Handle'(+Bar));
         Add_Child (Widget_Handle'(+Root), Canvas);
         Add_Child (Widget_Handle'(+Root), Widget_Handle'(+Status));

         Topogui.Canvas.Set_Status_Handler (On_Status'Unrestricted_Access);

         Set_Root (W, Widget_Handle'(+Root));
      end;

      File_Menu := Adi.Widget.Context_Menu.Create_Handle;
      Adi.Widget.Context_Menu.Attach_Window (File_Menu, W);
      Style_Menu (File_Menu);
      Adi.Widget.Context_Menu.Add_Item (File_Menu, "New");
      Adi.Widget.Context_Menu.Add_Item (File_Menu, "Open ...");
      Adi.Widget.Context_Menu.Add_Item (File_Menu, "Save");
      Adi.Widget.Context_Menu.Add_Item (File_Menu, "Quit");
      Adi.Widget.Context_Menu.Connect_Item_Selected
        (File_Menu, On_File_Item'Unrestricted_Access);

      --  The drawing modes of v0 increments 2 and 3 (drawing-model.md):
      --  Point and Edge draw, Loop closes a figure, Face classifies
      --  the accumulated chain.
      Sketch_Menu := Adi.Widget.Context_Menu.Create_Handle;
      Adi.Widget.Context_Menu.Attach_Window (Sketch_Menu, W);
      Style_Menu (Sketch_Menu);
      Adi.Widget.Context_Menu.Add_Item (Sketch_Menu, "Point");
      Adi.Widget.Context_Menu.Add_Item (Sketch_Menu, "Edge");
      Adi.Widget.Context_Menu.Add_Item (Sketch_Menu, "Loop");
      Adi.Widget.Context_Menu.Add_Item (Sketch_Menu, "Face");
      Adi.Widget.Context_Menu.Connect_Item_Selected
        (Sketch_Menu, On_Sketch_Item'Unrestricted_Access);

      return W;
   end Build;

end Topogui.Main_Window;

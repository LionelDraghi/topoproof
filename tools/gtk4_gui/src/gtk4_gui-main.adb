pragma Ada_2022;

with Gtk.Main;
with Gtk.Window; use Gtk.Window;
with Gtk.Box; use Gtk.Box;
with Gtk.Button; use Gtk.Button;
with Gtk.Label; use Gtk.Label;
with Gtk.Enums; use Gtk.Enums;
with Gtk.Container; use Gtk.Container;
with Gtk.Widget; use Gtk.Widget;

procedure Gtk4_Gui.Main is
   Window : Gtk_Window;
   Box    : Gtk_Box;
   Button : Gtk_Button;
   Label  : Gtk_Label;
begin
   Gtk.Main.Init;

   Window := Gtk_Window_New (Window_Toplevel);
   Set_Title (Window, "gtk4_gui");
   Set_Default_Size (Window, 640, 420);

   Box := Gtk_Box_New (Orientation_Vertical, 12);
   Label := Gtk_Label_New ("TopoProof GTK skeleton");
   Button := Gtk_Button_New_With_Label ("Open");

   Pack_Start (Box, Label, False, False, 0);
   Pack_Start (Box, Button, False, False, 0);

   Add (Window, Box);
   Show_All (Window);

   Gtk.Main.Main;
end Gtk4_Gui.Main;

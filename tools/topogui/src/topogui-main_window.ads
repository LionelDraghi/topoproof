pragma Ada_2022;

--  The main window of TopoGUI: menu bar (File, Sketch), drawing
--  canvas, and status line. The File and Sketch menus are Adi2 context
--  menus opened under their bar buttons, because Adi2 has no classic
--  menu bar widget. Build returns the window ready for the
--  application run loop.

with Adi.Window;

package Topogui.Main_Window is

   function Build return Adi.Window.Window_Handle;

end Topogui.Main_Window;

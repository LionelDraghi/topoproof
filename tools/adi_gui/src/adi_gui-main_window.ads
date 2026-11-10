-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

--  The main window of Adi_GUI: menu bar (File, Sketch), drawing
--  canvas, and status line. The File and Sketch menus are Adi2 context
--  menus opened under their bar buttons, because Adi2 has no classic
--  menu bar widget. Build returns the window ready for the
--  application run loop.

with Adi.Window;

package Adi_Gui.Main_Window is

   function Build return Adi.Window.Window_Handle;

end Adi_Gui.Main_Window;

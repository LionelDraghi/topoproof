pragma Ada_2022;

--  TopoGUI v0 skeleton (DD-006, development plan, v0 increment 1):
--  a window with a File menu and a Sketch menu, both placeholders
--  until the drawing actions of v0. The main procedure owns only the
--  application life cycle; the window construction lives in
--  Topogui.Main_Window, the design tokens in Topogui.Theme. The MCP
--  module is initialized so the running window can be introspected
--  and driven (AGENTS.md, testing policy).

with Adi.App;
with Adi.Layout_Util;
with Adi.MCP;
with Adi.Window;
with Topogui.Main_Window;

procedure Topogui.Main is

   A : Adi.App.App;

begin
   A.Init;
   Adi.Layout_Util.Set_Px_Maps_To_Dip (True);
   A.Set_Target_FPS (60);

   declare
      W : constant Adi.Window.Window_Handle := Topogui.Main_Window.Build;
   begin
      Adi.MCP.Initialize (W);
      A.Add_Window (W);
   end;

   A.Run;
   Adi.MCP.Finalize;
end Topogui.Main;

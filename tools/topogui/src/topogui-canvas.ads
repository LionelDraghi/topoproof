pragma Ada_2022;

--  The drawing canvas (v0 increment 2, drawing-model.md): a styled box
--  holding the session rendered as an SVG image, plus a per-frame tick
--  that turns left presses inside the box into kernel gestures. The
--  kernel arbitrates every gesture through the front-end; the canvas
--  never draws a position the kernel did not accept, and reports every
--  rejection verbatim.

with Adi.Widget;
with Adi.Window;

package Topogui.Canvas is

   type Mode_Kind is (Draw_Point, Draw_Edge);

   --  What the status line displays: the kernel traces of accepted
   --  gestures, the kernel diagnostics verbatim of the rejected ones.
   type Status_Callback is access procedure (Text : String);

   procedure Set_Status_Handler (CB : Status_Callback);

   procedure Set_Mode (M : Mode_Kind);
   function  Current_Mode return Mode_Kind;

   --  The canvas box, ready to add as a child. The tick that polls
  --  the mouse connects to the window here.
   function Create (W : Adi.Window.Window_Handle)
                    return Adi.Widget.Widget_Handle;

end Topogui.Canvas;

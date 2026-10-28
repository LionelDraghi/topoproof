pragma Ada_2022;

with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO;
with Adi.Core;
with Adi.CSS_Styles;
with Adi.Image;
with Adi.Log;
with GNAT.OS_Lib;
with Adi.SDL.Mouse;
with Adi.Widget.Box;
with Adi.Widget.Image;
with Adi.Widget_Styles;
with Interfaces.C;
with Interfaces.C.Extensions;
with Topogui.Session;
with Topogui.Theme;

use Adi.CSS_Styles;
use type Adi.Image.Image_Handle;
use type Interfaces.C.Extensions.Unsigned_32;

package body Topogui.Canvas is

   --  Pixels per grid unit. The mapped coordinate is bounded by half
   --  the canvas size over the scale — a few thousand units for any
   --  real window, far below Grid_Last (2**30 - 1,
   --  docs/numeric-model.md); the mapping still checks before a
   --  gesture reaches the kernel.

   Px_Per_Unit : constant Integer := 10;
   Grid_Last   : constant Integer := 2**30 - 1;

   --  One canvas per application: the drawing state lives here.

   Canvas_Box : Adi.Widget.Widget_Handle;
   Drawing_W  : Adi.Widget.Image.Image_Handle;

   Mode       : Mode_Kind := Draw_Point;
   The_Status : Status_Callback := null;

   The_Session : Topogui.Session.Model := Topogui.Session.Empty;

   --  The edge gesture waits for its second point.
   Pending        : Boolean := False;
   Pending_Vertex : Natural := 0;

   --  The loop gesture accumulates the clicked points GUI-side; the
   --  closing click, on the first point exactly, submits the whole
   --  figure atomically (drawing-model.md, increment 3).
   Pending_Figure : Topogui.Session.Click_Array (1 .. 512);
   Pending_Count  : Natural := 0;

   --  The rendered drawing; replaced on every redraw. The owner must
   --  outlive the widget item that draws it (layout_item_system.md).
   Drawing_Owner : Adi.Image.Image_Owner := Adi.Image.Null_Image_Owner;

   --  The tick polls the mouse: a left-press rising edge is a
   --  gesture; a canvas resize redraws.
   Prev_Left_Down : Boolean := False;
   Last_W, Last_H : Integer := 0;

   procedure Report (Text : String) is
   begin
      if The_Status /= null then
         The_Status (Text);
      else
         Adi.Log.Info (Text);
      end if;
   end Report;

   function Img (V : Integer) return String is
     (Ada.Strings.Fixed.Trim (Integer'Image (V), Ada.Strings.Both));

   --  Integer floor division; Ada's / truncates toward zero.
   function Floor_Div (A, B : Integer) return Integer is
     (if A >= 0 then A / B else -((-A + B - 1) / B))
     with Pre => B > 0;

   --  The canvas maps window pixels to grid units with the origin at
   --  the canvas centre and grid Y up (drawing-model.md).

   procedure Quantize
     (Local_X, Local_Y : Integer; W, H : Integer; X, Y : out Integer)
   with
     Pre  => Px_Per_Unit > 0,
     Post => X in -Grid_Last .. Grid_Last
             and then Y in -Grid_Last .. Grid_Last
   is
      DX : constant Integer := Local_X - W / 2;
      DY : constant Integer := Local_Y - H / 2;
   begin
      X := Floor_Div (2 * DX + Px_Per_Unit, 2 * Px_Per_Unit);
      Y := Floor_Div (Px_Per_Unit - 2 * DY, 2 * Px_Per_Unit);
   end Quantize;

   --  The SVG document of the whole session, at the canvas size.
   --  Exact integer coordinates; the toolkit rasterizes.

   function To_Svg (W, H : Integer) return String is
      S        : Unbounded_String;
      Origin_X : constant Integer := W / 2;
      Origin_Y : constant Integer := H / 2;
   begin
      Append (S, "<svg xmlns='http://www.w3.org/2000/svg' width='"
              & Img (W) & "' height='" & Img (H) & "'>" & ASCII.LF);
      Append (S, "<rect x='0' y='0' width='" & Img (W)
              & "' height='" & Img (H)
              & "' fill='" & Topogui.Theme.Surface_Svg & "'/>" & ASCII.LF);

      --  The unit grid, quieter than the text ink; the axes cover the
      --  origin lines.
      for GX in -W / (2 * Px_Per_Unit) .. W / (2 * Px_Per_Unit) loop
         if GX /= 0 then
            Append (S, "<line x1='" & Img (Origin_X + GX * Px_Per_Unit)
                    & "' y1='0' x2='" & Img (Origin_X + GX * Px_Per_Unit)
                    & "' y2='" & Img (H)
                    & "' stroke='" & Topogui.Theme.Grid_Line_Svg
                    & "' stroke-width='1'/>" & ASCII.LF);
         end if;
      end loop;
      for GY in -H / (2 * Px_Per_Unit) .. H / (2 * Px_Per_Unit) loop
         if GY /= 0 then
            Append (S, "<line x1='0' y1='"
                    & Img (Origin_Y + GY * Px_Per_Unit)
                    & "' x2='" & Img (W) & "' y2='"
                    & Img (Origin_Y + GY * Px_Per_Unit)
                    & "' stroke='" & Topogui.Theme.Grid_Line_Svg
                    & "' stroke-width='1'/>" & ASCII.LF);
         end if;
      end loop;

      --  The axes.
      Append (S, "<line x1='0' y1='" & Img (Origin_Y)
              & "' x2='" & Img (W) & "' y2='" & Img (Origin_Y)
              & "' stroke='" & Topogui.Theme.Grid_Axis_Svg
              & "' stroke-width='1'/>" & ASCII.LF);
      Append (S, "<line x1='" & Img (Origin_X) & "' y1='0' x2='"
              & Img (Origin_X) & "' y2='" & Img (H)
              & "' stroke='" & Topogui.Theme.Grid_Axis_Svg
              & "' stroke-width='1'/>" & ASCII.LF);

      --  The kernel-accepted edges, then the vertices above them.
      --  An accepted face fills its polygon under the ink.
      if Topogui.Session.Face_Count (The_Session) > 0 then
         Append (S, "<polygon points='");
         for I in 1 .. Topogui.Session.Face_Count (The_Session) loop
            declare
               Vertex : constant Topogui.Session.Vertex_Record :=
                 Topogui.Session.Vertex_At
                   (The_Session, Topogui.Session.Face_Handle (The_Session, I));
            begin
               Append (S, Img (Origin_X + Vertex.X * Px_Per_Unit) & ","
                       & Img (Origin_Y - Vertex.Y * Px_Per_Unit));
               if I < Topogui.Session.Face_Count (The_Session) then
                  Append (S, " ");
               end if;
            end;
         end loop;
         Append (S, "' fill='" & Topogui.Theme.Accent_Svg
                 & "' fill-opacity='0.15'/>" & ASCII.LF);
      end if;

      for E in 1 .. Topogui.Session.Edge_Count (The_Session) loop
         declare
            Edge : constant Topogui.Session.Edge_Record :=
              Topogui.Session.Edge_At (The_Session, E);
            A : constant Topogui.Session.Vertex_Record :=
              Topogui.Session.Vertex_At (The_Session, Edge.A);
            B : constant Topogui.Session.Vertex_Record :=
              Topogui.Session.Vertex_At (The_Session, Edge.B);
         begin
            Append (S, "<line x1='" & Img (Origin_X + A.X * Px_Per_Unit)
                    & "' y1='" & Img (Origin_Y - A.Y * Px_Per_Unit)
                    & "' x2='" & Img (Origin_X + B.X * Px_Per_Unit)
                    & "' y2='" & Img (Origin_Y - B.Y * Px_Per_Unit)
                    & "' stroke='" & Topogui.Theme.Accent_Svg
                    & "' stroke-width='2'/>" & ASCII.LF);
         end;
      end loop;

      for V in 1 .. Topogui.Session.Vertex_Count (The_Session) loop
         declare
            Vertex : constant Topogui.Session.Vertex_Record :=
              Topogui.Session.Vertex_At (The_Session, V);
            PX : constant Integer := Origin_X + Vertex.X * Px_Per_Unit;
            PY : constant Integer := Origin_Y - Vertex.Y * Px_Per_Unit;
         begin
            Append (S, "<rect x='" & Img (PX - 3) & "' y='"
                    & Img (PY - 3) & "' width='6' height='6' fill='"
                    & Topogui.Theme.Accent_Svg & "'/>"
                    & ASCII.LF);
         end;
      end loop;

      --  The pending edge start: an outline square waiting for the
      --  second point.
      if Pending then
         declare
            Vertex : constant Topogui.Session.Vertex_Record :=
              Topogui.Session.Vertex_At (The_Session, Pending_Vertex);
            PX : constant Integer :=
              Origin_X + Vertex.X * Px_Per_Unit;
            PY : constant Integer :=
              Origin_Y - Vertex.Y * Px_Per_Unit;
         begin
            Append (S, "<rect x='" & Img (PX - 5) & "' y='"
                    & Img (PY - 5) & "' width='10' height='10' fill='none'"
                    & " stroke='" & Topogui.Theme.Accent_Svg
                    & "' stroke-width='2'/>" & ASCII.LF);
         end;
      end if;

      --  The pending loop figure: an outline square per clicked point,
      --  waiting for the closing click.
      for I in 1 .. Pending_Count loop
         declare
            PX : constant Integer :=
              Origin_X + Pending_Figure (I).X * Px_Per_Unit;
            PY : constant Integer :=
              Origin_Y - Pending_Figure (I).Y * Px_Per_Unit;
         begin
            Append (S, "<rect x='" & Img (PX - 5) & "' y='"
                    & Img (PY - 5) & "' width='10' height='10'"
                    & " fill='none' stroke='"
                    & Topogui.Theme.Accent_Svg
                    & "' stroke-width='2'/>" & ASCII.LF);
         end;
      end loop;

      Append (S, "</svg>" & ASCII.LF);
      return To_String (S);
   end To_Svg;

   --  Re-render the session into the image widget, at the current
   --  canvas size.

   procedure Refresh is
      Geo : constant Adi.Core.Rectangle :=
        Adi.Widget.Get_Geometry (Canvas_Box);
      W_Px : constant Integer := Integer (Geo.Width);
      H_Px : constant Integer := Integer (Geo.Height);
   begin
      if not Adi.Widget.Is_Valid (Canvas_Box)
        or else W_Px <= 2 or else H_Px <= 2
      then
         return;  --  Not laid out yet: nothing to draw into.
      end if;

      Adi.Image.Release (Drawing_Owner);
      Drawing_Owner :=
        Adi.Image.Load_SVG_From_String (To_Svg (W_Px - 2, H_Px - 2));

      if Adi.Image.Is_Valid (Adi.Image.To_Handle (Drawing_Owner)) then
         Adi.Widget.Image.Set_Image
           (Drawing_W, Adi.Image.To_Handle (Drawing_Owner));
         --  The drawing fills the box, inside the 1px border.
         Adi.Widget.Set_Part_Style
           (Adi.Widget.Image.To_Widget_Handle (Drawing_W), Adi.Widget.Main_Part,
            Adi.Widget_Styles.Create.Base
              ((Width      => Set (Size (Px (Float (W_Px - 2)))),
                Height     => Set (Size (Px (Float (H_Px - 2)))),
                others     => <>)).Build);
         Adi.Widget.Mark_Dirty (Adi.Widget.Image.To_Widget_Handle (Drawing_W));
      end if;
   end Refresh;

   --  The kernel gesture, from an exact grid point.

   procedure Gesture (GX, GY : Integer) is
   begin
      case Mode is

         when Draw_Point =>
            declare
               H      : Natural;
               OK     : Boolean;
               Reject : Unbounded_String;
            begin
               Topogui.Session.Add_Vertex (The_Session, GX, GY, H, OK, Reject);
               if OK then
                  Report ("vertex" & Natural'Image (H) & " point "
                          & Img (GX) & " " & Img (GY));
                  Refresh;
               else
                  Report (To_String (Reject));
               end if;
            end;

         when Draw_Edge =>
            declare
               H : constant Natural :=
                 Topogui.Session.Snap (The_Session, GX, GY);
            begin
               if not Pending then
                  Pending := True;
                  if H = 0 then
                     --  A first point that no vertex holds yet creates
                     --  its vertex through the kernel.
                     declare
                        NH     : Natural;
                        OK     : Boolean;
                        Reject : Unbounded_String;
                     begin
                        Topogui.Session.Add_Vertex (The_Session, GX, GY,
                                                    NH, OK, Reject);
                        if OK then
                           Pending_Vertex := NH;
                           Report ("edge: first point "
                                   & Img (GX) & " " & Img (GY));
                           Refresh;
                        else
                           Pending := False;
                           Report (To_String (Reject));
                        end if;
                     end;
                  else
                     Pending_Vertex := H;
                     Report ("edge: first point "
                             & Img (GX) & " " & Img (GY));
                     Refresh;
                  end if;
               else
                  --  The second point; a point no vertex holds yet
                  --  creates its vertex first. The same vertex as the
                  --  pending one is submitted anyway, for the kernel
                  --  to reject the degenerate edge.
                  declare
                     NH     : Natural;
                     OK     : Boolean;
                     Reject : Unbounded_String;
                     Second : Natural := H;
                  begin
                     Pending := False;
                     if Second = 0 then
                        Topogui.Session.Add_Vertex (The_Session, GX, GY,
                                                    Second, OK, Reject);
                        if not OK then
                           Report (To_String (Reject));
                           return;
                        end if;
                     end if;
                     Topogui.Session.Add_Edge
                       (The_Session, Pending_Vertex, Second, NH, OK, Reject);
                     if OK then
                        Report ("edge" & Natural'Image (NH) & " accepted");
                        Refresh;
                     else
                        Report (To_String (Reject));
                     end if;
                  end;
               end if;
            end;
         when Draw_Loop =>
            declare
               Snap_H : constant Natural :=
                 Topogui.Session.Snap (The_Session, GX, GY);
            begin
               if Pending_Count = 0 then
                  Pending_Count := 1;
                  Pending_Figure (1) := (X => GX, Y => GY, Snap => Snap_H);
                  Report ("loop: first point " & Img (GX) & " " & Img (GY));
                  Refresh;

               elsif GX = Pending_Figure (1).X
                 and then GY = Pending_Figure (1).Y
               then
                  --  The closing click, on the first point exactly:
                  --  the whole figure is submitted atomically, and the
                  --  kernel decides.
                  declare
                     Figure : constant Topogui.Session.Click_Array :=
                       Pending_Figure (1 .. Pending_Count);
                     OK     : Boolean;
                     Line   : Unbounded_String;
                     Reject : Unbounded_String;
                  begin
                     Pending_Count := 0;
                     Topogui.Session.Close_Loop
                       (The_Session, Figure, OK, Line, Reject);
                     if OK then
                        Report (To_String (Line));
                     else
                        Report (To_String (Reject));
                     end if;
                     Refresh;
                  end;

               else
                  Pending_Count := Pending_Count + 1;
                  Pending_Figure (Pending_Count) :=
                    (X => GX, Y => GY, Snap => Snap_H);
                  Report ("loop: point " & Img (GX) & " " & Img (GY));
                  Refresh;
               end if;
            end;

      end case;
   end Gesture;

   --  The per-frame poll: a left-press rising edge inside the canvas
   --  box is a gesture; a canvas resize redraws. A `click` file in the
   --  application's MCP channel directory ("X Y", canvas-local pixels)
   --  injects the same gesture path: the automated-testing channel,
   --  because the MCP widget clicks do not carry raw mouse events.

   Injection_Path : constant String := "/tmp/adi_mcp/";  --  & pid & "/click"

   function Own_Pid return String;

   procedure Poll_Click_File is
      Path : constant String :=
        Injection_Path & Own_Pid & "/click";
      File : Ada.Text_IO.File_Type;
      Line : String (1 .. 64);
      Last : Natural;
      Space : Natural;
   begin
      if not Ada.Directories.Exists (Path) then
         return;
      end if;
      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
      Ada.Text_IO.Get_Line (File, Line, Last);
      Ada.Text_IO.Close (File);
      Ada.Directories.Delete_File (Path);

      Space := 0;
      for I in 1 .. Last loop
         if Line (I) = ' ' then
            Space := I;
            exit;
         end if;
      end loop;
      if Space = 0 then
         return;
      end if;

      declare
         Local_X : constant Integer :=
           Integer'Value (Line (1 .. Space - 1));
         Local_Y : constant Integer :=
           Integer'Value (Line (Space + 1 .. Last));
         GX, GY  : Integer;
      begin
         Quantize (Local_X, Local_Y, Last_W, Last_H, GX, GY);
         Gesture (GX, GY);
      end;
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         Report ("error: malformed click injection");
   end Poll_Click_File;

   function Own_Pid return String is
     (Ada.Strings.Fixed.Trim
        (Integer'Image
           (GNAT.OS_Lib.Pid_To_Integer (GNAT.OS_Lib.Current_Process_Id)),
         Ada.Strings.Both));

   procedure Tick (DT : Duration) is
      pragma Unreferenced (DT);
      use type Adi.Core.Pixel_Type;
      MX, MY  : aliased Float;
      Buttons : constant Adi.SDL.Mouse.SDL_MouseButtonFlags :=
        Adi.SDL.Mouse.SDL_GetMouseState (MX'Access, MY'Access);
      Left_Down : constant Boolean := (Buttons and 1) /= 0;
      Geo : constant Adi.Core.Rectangle :=
        Adi.Widget.Get_Geometry (Canvas_Box);
   begin
      Poll_Click_File;

      if Integer (Geo.Width) /= Last_W
        or else Integer (Geo.Height) /= Last_H
      then
         Last_W := Integer (Geo.Width);
         Last_H := Integer (Geo.Height);
         Refresh;
      end if;

      if Left_Down and then not Prev_Left_Down
        and then MX >= Float (Geo.X) and then MX < Float (Geo.X + Geo.Width)
        and then MY >= Float (Geo.Y) and then MY < Float (Geo.Y + Geo.Height)
      then
         declare
            GX, GY : Integer;
         begin
            Quantize (Integer (MX) - Integer (Geo.X), Integer (MY) - Integer (Geo.Y),
                      Integer (Geo.Width), Integer (Geo.Height), GX, GY);
            Gesture (GX, GY);
         end;
      end if;
      Prev_Left_Down := Left_Down;
   end Tick;

   procedure Submit_Face is
      OK     : Boolean;
      Line   : Unbounded_String;
      Reject : Unbounded_String;
   begin
      Topogui.Session.Build_Face (The_Session, OK, Line, Reject);
      if OK then
         Report (To_String (Line));
         Refresh;
      else
         Report (To_String (Reject));
      end if;
   end Submit_Face;

   procedure Set_Status_Handler (CB : Status_Callback) is
   begin
      The_Status := CB;
   end Set_Status_Handler;

   procedure Set_Mode (M : Mode_Kind) is
   begin
      Mode := M;
      Pending := False;
      Pending_Count := 0;
      case M is
         when Draw_Point => Report ("Point mode: click to create a vertex.");
         when Draw_Edge  => Report ("Edge mode: click two points.");
         when Draw_Loop  =>
            Report ("Loop mode: click the figure points, close on the first.");
      end case;
      Refresh;
   end Set_Mode;

   function Current_Mode return Mode_Kind is (Mode);

   function Create (W : Adi.Window.Window_Handle)
                    return Adi.Widget.Widget_Handle
   is
      Box : constant Adi.Widget.Box.Box_Handle :=
        Adi.Widget.Box.Create_Handle;
      Image_W : constant Adi.Widget.Image.Image_Handle :=
        Adi.Widget.Image.Create_Handle;
   begin
      Drawing_W := Image_W;
      Adi.Widget.Box.Add_Child (Box, Adi.Widget.Image.To_Widget_Handle (Image_W));
      Canvas_Box := Adi.Widget.Box.To_Widget_Handle (Box);
      Adi.Window.Connect_Tick (W, Tick'Unrestricted_Access);
      return Canvas_Box;
   end Create;

end Topogui.Canvas;

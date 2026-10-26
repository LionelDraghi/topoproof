pragma Ada_2022;

--  The drawing session: the state the kernel accepted, plus the
--  replayable TopoScript that produced it (drawing-model.md). The GUI
--  records exactly what the kernel traces report; every gesture is
--  arbitrated by a full replay through the front-end, and a kernel
--  rejection surfaces verbatim.

with Ada.Strings.Unbounded;

package Topogui.Session is

   --  An exact grid point, as the kernel reports it. The GUI never
   --  computes kernel geometry: these are copied from the traces.

   type Vertex_Record is record
      X, Y : Integer;
   end record;

   type Edge_Record is record
      A, B : Integer;  --  Vertex handles, kernel numbering (1-based).
   end record;

   type Model is private;

   function Empty return Model;
   --  A session with nothing drawn and an empty replay script.

   --  The accumulated TopoScript statements of the accepted gestures.
   function Replay_Script (M : Model) return String;

   --  The kernel-known state, in kernel order.
   function Vertex_Count (M : Model) return Natural;
   function Edge_Count   (M : Model) return Natural;
   function Vertex_At (M : Model; Index : Positive) return Vertex_Record
     with Pre => Index <= Vertex_Count (M);
   function Edge_At (M : Model; Index : Positive) return Edge_Record
     with Pre => Index <= Edge_Count (M);

   --  The handle of the most recently created vertex whose kernel
   --  point equals (X, Y) exactly, 0 when none does. This is the
   --  snap: exact integer equality on kernel-reported points, no
   --  tolerance.
   function Snap (M : Model; X, Y : Integer) return Natural;

   --  Submit one vertex creation at the exact grid point. Accepted
   --  extends the session and answers True; a kernel rejection
   --  answers False and reports the diagnostic verbatim, leaving the
   --  session unchanged.
   procedure Add_Vertex
     (M           : in out Model;
      X, Y        : Integer;
      New_Handle  : out Natural;
      Accepted    : out Boolean;
      Rejection   : out Ada.Strings.Unbounded.Unbounded_String);

   --  Submit one edge between two known vertex handles. The kernel
   --  arbitrates; a rejection (the degenerate edge, for one) leaves
   --  the session unchanged.
   procedure Add_Edge
     (M         : in out Model;
      VA, VB    : Natural;
      New_Handle : out Natural;
      Accepted   : out Boolean;
      Rejection  : out Ada.Strings.Unbounded.Unbounded_String);

private

   type Vertex_List is array (1 .. 512) of Vertex_Record;
   type Edge_List is array (1 .. 512) of Edge_Record;

   type Model is record
      Vertices     : Vertex_List;
      Edges        : Edge_List;
      NV           : Natural := 0;
      NE           : Natural := 0;
      Declarations : Ada.Strings.Unbounded.Unbounded_String;
      Statements   : Ada.Strings.Unbounded.Unbounded_String;
   end record;

end Topogui.Session;

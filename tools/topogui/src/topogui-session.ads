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

   --  One clicked point of a pending loop figure: the exact grid
   --  point, and the vertex handle it snaps to, 0 when the point is
   --  new and the submission must create its vertex.
   type Point_Click is record
      X, Y : Integer;
      Snap : Natural;
   end record;

   type Click_Array is array (Positive range <>) of Point_Click;

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

   --  The Add_Point chain of the session, in accumulation order: the
   --  kernel-reported vertex handles of the accepted loop figure,
   --  closed on the first one.
   function Chain_Count (M : Model) return Natural;
   function Chain_Handle (M : Model; Index : Positive) return Natural
     with Pre => Index <= Chain_Count (M);

   --  Submit the whole pending loop figure atomically (v0 increment
   --  3, drawing-model.md): the points are the clicked figure in
   --  traversal order, at least two; the submission creates the new
   --  vertices, the edges along the traversal and back to the first
   --  point, the closed Add_Point chain, and classifies the created
   --  edges with Make_Loop_From_Edges. Accepted only when the run
   --  exits 0 and the canonical trace is a valid loop orientation;
   --  any other classification or diagnostic drops the candidate and
   --  is reported verbatim, leaving the session unchanged.
   procedure Close_Loop
     (M         : in out Model;
      Points    : Click_Array;
      Accepted  : out Boolean;
      Result_Line : out Ada.Strings.Unbounded.Unbounded_String;
      Rejection : out Ada.Strings.Unbounded.Unbounded_String)
     with Pre => Points'Length >= 1;
   --  Accepted carries the canonical Put_Loop line in Result_Line: the
   --  GUI reads the orientation from the kernel, it never computes it.
   --  A rejected figure carries the diagnostics in Rejection.

   --  Classify the accumulated chain as a face boundary: one menu
   --  action over the chain the accepted loop appended. The same
   --  acceptance rule as the loop, with the canonical face kinds;
   --  the accepted face is recorded with its boundary handles, for
   --  the view to fill the enclosed polygon.
   procedure Build_Face
     (M         : in out Model;
      Accepted  : out Boolean;
      Result_Line : out Ada.Strings.Unbounded.Unbounded_String;
      Rejection : out Ada.Strings.Unbounded.Unbounded_String);

   --  The accepted face boundary, closed on the first handle; empty
   --  when no face was accepted yet.
   function Face_Count (M : Model) return Natural;
   function Face_Handle (M : Model; Index : Positive) return Natural
     with Pre => Index <= Face_Count (M);

private

   type Vertex_List is array (1 .. 512) of Vertex_Record;
   type Edge_List is array (1 .. 512) of Edge_Record;
   type Handle_List is array (1 .. 512) of Natural;

   type Model is record
      Vertices     : Vertex_List;
      Edges        : Edge_List;
      NV           : Natural := 0;
      NE           : Natural := 0;
      Chain        : Handle_List;
      NC           : Natural := 0;
      Face         : Handle_List;
      NF           : Natural := 0;
      Declarations : Ada.Strings.Unbounded.Unbounded_String;
      Statements   : Ada.Strings.Unbounded.Unbounded_String;
   end record;

end Topogui.Session;

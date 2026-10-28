pragma Ada_2022;

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Topogui.Kernel;
with Ada.Strings.Fixed;

package body Topogui.Session is

   function Trim (S : String) return String is
     (Ada.Strings.Fixed.Trim (S, Ada.Strings.Both));

   function Empty return Model is
     (NV => 0, NE => 0, NC => 0, NF => 0, others => <>);

   function Replay_Script (M : Model) return String is
     (To_String (M.Declarations) & To_String (M.Statements));

   function Vertex_Count (M : Model) return Natural is (M.NV);
   function Edge_Count   (M : Model) return Natural is (M.NE);
   function Chain_Count  (M : Model) return Natural is (M.NC);
   function Face_Count   (M : Model) return Natural is (M.NF);

   function Vertex_At (M : Model; Index : Positive) return Vertex_Record is
     (M.Vertices (Index));

   function Edge_At (M : Model; Index : Positive) return Edge_Record is
     (M.Edges (Index));

   function Chain_Handle (M : Model; Index : Positive) return Natural is
     (M.Chain (Index));

   function Face_Handle (M : Model; Index : Positive) return Natural is
     (M.Face (Index));

   function Snap (M : Model; X, Y : Integer) return Natural is
   begin
      --  Creation order scanned backwards: the most recently created
      --  vertex at the point wins.
      for I in reverse 1 .. M.NV loop
         if M.Vertices (I).X = X and then M.Vertices (I).Y = Y then
            return I;
         end if;
      end loop;
      return 0;
   end Snap;

   --  The kernel numbers handles in creation order, so the replay
   --  declares every point and handle first, then states the
   --  operations in the accepted order.

   --  Append one vertex creation to a candidate: the point and handle
   --  declarations, then the construction statements with the
   --  canonical trace. The candidate stores the kernel-reported point.
   procedure Append_Vertex
     (Cand : in out Model; X, Y : Integer; New_Handle : out Natural)
   is
      N : constant String := Trim (Natural'Image (Cand.NV + 1));
   begin
      Append (Cand.Declarations,
              "P" & N & " : constant Point_2D := ("
              & Trim (Integer'Image (X)) & ", " & Trim (Integer'Image (Y))
              & ");" & ASCII.LF
              & "V" & N & " : Vertex_Handle;" & ASCII.LF);
      Append (Cand.Statements,
              "Create_Vertex (P" & N & ", V" & N & ");" & ASCII.LF
              & "Put_Vertex (V" & N & ");" & ASCII.LF);
      Cand.NV := Cand.NV + 1;
      Cand.Vertices (Cand.NV) := (X, Y);
      New_Handle := Cand.NV;
   end Append_Vertex;

   --  Append one edge creation to a candidate, between two known
   --  vertex handles.
   procedure Append_Edge
     (Cand : in out Model; VA, VB : Natural; New_Handle : out Natural)
   is
      N  : constant String := Trim (Natural'Image (Cand.NE + 1));
      VA_Name : constant String :=
        "V" & Trim (Natural'Image (VA));
      VB_Name : constant String :=
        "V" & Trim (Natural'Image (VB));
   begin
      Append (Cand.Declarations,
              "E" & N & " : Edge_Handle;" & ASCII.LF);
      Append (Cand.Statements,
              "Create_Edge (" & VA_Name & ", " & VB_Name & ", E" & N
              & ");" & ASCII.LF
              & "Put_Edge (E" & N & ");" & ASCII.LF);
      Cand.NE := Cand.NE + 1;
      Cand.Edges (Cand.NE) := (VA, VB);
      New_Handle := Cand.NE;
   end Append_Edge;

   --  Append one chain point to a candidate: the Add_Point statement
   --  over the declared point constant of the vertex handle.
   procedure Append_Chain_Point
     (Cand : in out Model; VH : Natural)
   is
      Name : constant String := "P" & Trim (Natural'Image (VH));
   begin
      Append (Cand.Statements, "Add_Point (" & Name & ");" & ASCII.LF);
   end Append_Chain_Point;

   procedure Add_Vertex
     (M          : in out Model;
      X, Y       : Integer;
      New_Handle : out Natural;
      Accepted   : out Boolean;
      Rejection  : out Unbounded_String)
   is
      Candidate : Model := M;
      R         : Topogui.Kernel.Result;
   begin
      New_Handle := 0;
      Accepted := False;
      Rejection := Null_Unbounded_String;

      declare
         H : Natural;
      begin
         Append_Vertex (Candidate, X, Y, H);
         R := Kernel.Run_Code (Replay_Script (Candidate));

         if R.Exit_Code = 0
           and then Index (R.Traces,
                           "vertex" & Natural'Image (H)
                           & " point") > 0
         then
            M := Candidate;
            New_Handle := H;
            Accepted := True;
         else
            Rejection := R.Diagnostics;
         end if;
      end;
   end Add_Vertex;

   procedure Add_Edge
     (M          : in out Model;
      VA, VB     : Natural;
      New_Handle : out Natural;
      Accepted   : out Boolean;
      Rejection  : out Unbounded_String)
   is
      Candidate : Model := M;
      R         : Topogui.Kernel.Result;
   begin
      New_Handle := 0;
      Accepted := False;
      Rejection := Null_Unbounded_String;

      declare
         E : Natural;
      begin
         Append_Edge (Candidate, VA, VB, E);
         R := Kernel.Run_Code (Replay_Script (Candidate));

         if R.Exit_Code = 0
           and then Index (R.Traces,
                           "edge" & Natural'Image (E)
                           & " vertex") > 0
         then
            M := Candidate;
            New_Handle := E;
            Accepted := True;
         else
            Rejection := R.Diagnostics;
         end if;
      end;
   end Add_Edge;

   --  The valid loop orientations, the only accepted loop kinds; any
   --  other classification, diagnostic or status drops the candidate.
   --  Index is qualified: the Unbounded overloads are use-visible.
   function Valid_Loop_Trace (Traces : String) return Boolean is
     (Ada.Strings.Fixed.Index (Traces, "loop closed counter_clockwise") > 0
      or else Ada.Strings.Fixed.Index (Traces, "loop closed clockwise") > 0);

   function Valid_Face_Trace (Traces : String) return Boolean is
     (Ada.Strings.Fixed.Index (Traces, "face counter_clockwise") > 0
      or else Ada.Strings.Fixed.Index (Traces, "face clockwise") > 0);

   --  The last non-empty line of a trace block: the canonical line the
   --  gesture's Put wrote, after the construction traces.
   function Last_Line (Traces : String) return String is
      Best_First, Best_Last : Natural := 0;
      Start : Natural := Traces'First;
   begin
      for I in Traces'Range loop
         if Traces (I) = ASCII.LF then
            if I > Start then
               Best_First := Start;
               Best_Last := I - 1;
            end if;
            Start := I + 1;
         end if;
      end loop;
      --  A final segment without a closing LF.
      if Traces'Last >= Start then
         Best_First := Start;
         Best_Last := Traces'Last;
      end if;
      if Best_First = 0 then
         return "";
      end if;
      return Trim (Traces (Best_First .. Best_Last));
   end Last_Line;

   procedure Close_Loop
     (M         : in out Model;
      Points    : Click_Array;
      Accepted  : out Boolean;
      Result_Line : out Unbounded_String;
      Rejection : out Unbounded_String)
   is
      Candidate : Model := M;
      R         : Topogui.Kernel.Result;
      Handles   : Handle_List;
      N         : constant Natural := Points'Length;
   begin
      Accepted := False;
      Result_Line := Null_Unbounded_String;
      Rejection := Null_Unbounded_String;

      --  The vertices: the snapped points reuse their handle, the new
      --  points go through the kernel.
      for I in Points'Range loop
         if Points (I).Snap = 0 then
            Append_Vertex (Candidate, Points (I).X, Points (I).Y,
                           Handles (I - Points'First + 1));
         else
            Handles (I - Points'First + 1) := Points (I).Snap;
         end if;
      end loop;

      --  The edges along the traversal, then back to the first point:
      --  the creation order is the traversal order the loop
      --  classification reads.
      for I in 1 .. N - 1 loop
         declare
            E : Natural;
         begin
            Append_Edge (Candidate, Handles (I), Handles (I + 1), E);
         end;
      end loop;
      declare
         E : Natural;
      begin
         Append_Edge (Candidate, Handles (N), Handles (1), E);
      end;

      --  The closed chain the face gesture classifies later: the
      --  traversal points, then the first one again.
      for I in 1 .. N loop
         Append_Chain_Point (Candidate, Handles (I));
      end loop;
      Append_Chain_Point (Candidate, Handles (1));

      Append (Candidate.Declarations, "LK : Loop_Kind;" & ASCII.LF);
      Append (Candidate.Statements,
              "Make_Loop_From_Edges (LK);" & ASCII.LF
              & "Put_Loop (LK);" & ASCII.LF);

      R := Kernel.Run_Code (Replay_Script (Candidate));

      if R.Exit_Code = 0
        and then Valid_Loop_Trace (To_String (R.Traces))
      then
         M := Candidate;
         for I in 1 .. N loop
            M.Chain (I) := Handles (I);
         end loop;
         M.Chain (N + 1) := Handles (1);
         M.NC := N + 1;
         Accepted := True;
         Result_Line := To_Unbounded_String (Last_Line (To_String (R.Traces)));
      else
         --  A non-zero exit carries the diagnostics verbatim; an exit
         --  0 with a non-accepted classification (the degenerate
         --  backtrack, for one) carries the canonical line the Put
         --  wrote: displayed, never softened.
         if Trim (To_String (R.Diagnostics)) = "" then
            Rejection := To_Unbounded_String (Last_Line (To_String (R.Traces)));
         else
            Rejection := R.Diagnostics;
         end if;
      end if;
   end Close_Loop;

   procedure Build_Face
     (M         : in out Model;
      Accepted  : out Boolean;
      Result_Line : out Unbounded_String;
      Rejection : out Unbounded_String)
   is
      Candidate : Model := M;
      R         : Topogui.Kernel.Result;
   begin
      Accepted := False;
      Result_Line := Null_Unbounded_String;
      Rejection := Null_Unbounded_String;

      Append (Candidate.Declarations, "FK : Face_Kind;" & ASCII.LF);
      Append (Candidate.Statements,
              "Make_Face (FK);" & ASCII.LF
              & "Put_Face (FK);" & ASCII.LF);

      R := Kernel.Run_Code (Replay_Script (Candidate));

      if R.Exit_Code = 0
        and then Valid_Face_Trace (To_String (R.Traces))
      then
         M := Candidate;
         M.Face := M.Chain;
         M.NF := M.NC;
         Accepted := True;
         Result_Line := To_Unbounded_String (Last_Line (To_String (R.Traces)));
      else
         if Trim (To_String (R.Diagnostics)) = "" then
            Rejection := To_Unbounded_String (Last_Line (To_String (R.Traces)));
         else
            Rejection := R.Diagnostics;
         end if;
      end if;
   end Build_Face;

end Topogui.Session;

pragma Ada_2022;

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Topogui.Kernel;
with Ada.Strings.Fixed;

package body Topogui.Session is

   function Trim (S : String) return String is
     (Ada.Strings.Fixed.Trim (S, Ada.Strings.Both));

   function Empty return Model is
      (NV => 0, NE => 0, others => <>);

   function Replay_Script (M : Model) return String is
     (To_String (M.Declarations) & To_String (M.Statements));

   function Vertex_Count (M : Model) return Natural is (M.NV);
   function Edge_Count   (M : Model) return Natural is (M.NE);

   function Vertex_At (M : Model; Index : Positive) return Vertex_Record is
     (M.Vertices (Index));

   function Edge_At (M : Model; Index : Positive) return Edge_Record is
     (M.Edges (Index));

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

   procedure Add_Vertex
     (M          : in out Model;
      X, Y       : Integer;
      New_Handle : out Natural;
      Accepted   : out Boolean;
      Rejection  : out Unbounded_String)
   is
      Candidate : Model := M;
      R         : Topogui.Kernel.Result;
      N         : constant String := Trim (Natural'Image (Candidate.NV + 1));
   begin
      New_Handle := 0;
      Accepted := False;
      Rejection := Null_Unbounded_String;

      Append (Candidate.Declarations,
              "P" & N & " : constant Point_2D := ("
              & Trim (Integer'Image (X)) & ", " & Trim (Integer'Image (Y))
              & ");" & ASCII.LF
              & "V" & N & " : Vertex_Handle;" & ASCII.LF);
      Append (Candidate.Statements,
              "Create_Vertex (P" & N & ", V" & N & ");" & ASCII.LF
              & "Put_Vertex (V" & N & ");" & ASCII.LF);
      Candidate.NV := Candidate.NV + 1;
      Candidate.Vertices (Candidate.NV) := (X, Y);

      R := Kernel.Run_Code (Replay_Script (Candidate));

      if R.Exit_Code = 0
        and then Index (R.Traces,
                        "vertex" & Natural'Image (Candidate.NV)
                        & " point") > 0
      then
         M := Candidate;
         New_Handle := Candidate.NV;
         Accepted := True;
      else
         Rejection := R.Diagnostics;
      end if;
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
      N         : constant String := Trim (Natural'Image (Candidate.NE + 1));
   begin
      New_Handle := 0;
      Accepted := False;
      Rejection := Null_Unbounded_String;

      Append (Candidate.Declarations,
              "E" & N & " : Edge_Handle;" & ASCII.LF);
      Append (Candidate.Statements,
              "Create_Edge (V" & Trim (Natural'Image (VA))
              & ", V" & Trim (Natural'Image (VB)) & ", E" & N & ");" & ASCII.LF
              & "Put_Edge (E" & N & ");" & ASCII.LF);
      Candidate.NE := Candidate.NE + 1;
      Candidate.Edges (Candidate.NE) := (VA, VB);

      R := Kernel.Run_Code (Replay_Script (Candidate));

      if R.Exit_Code = 0
        and then Index (R.Traces,
                        "edge" & Natural'Image (Candidate.NE)
                        & " vertex") > 0
      then
         M := Candidate;
         New_Handle := Candidate.NE;
         Accepted := True;
      else
         Rejection := R.Diagnostics;
      end if;
   end Add_Edge;

end Topogui.Session;

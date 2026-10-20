--  Fail when retained GNATprove evidence violates TopoProof integration
--  rules. Scans the artefacts left by make proof (results.log,
--  gnatprove.out, assumptions.log) for unproved checks, risky flow
--  messages and unreviewed assumptions. Exits with a non-zero status and
--  a diagnostic on standard error when the gate is not satisfied.
--
--  On success, prints a short summary of the analysis, read from the
--  gnatprove.out totals table.

with Ada.Characters.Handling;
with Ada.Command_Line;
with Ada.Directories;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Ada.Text_IO;

procedure Check_Evidence is

   package CH  renames Ada.Characters.Handling;
   package CL  renames Ada.Command_Line;
   package DIR renames Ada.Directories;
   package FX  renames Ada.Strings.Fixed;
   package US  renames Ada.Strings.Unbounded;
   package TIO renames Ada.Text_IO;

   --  The artefacts directory, given as the sole optional argument.
   Root : constant String :=
     (if CL.Argument_Count >= 1
        then CL.Argument (1)
        else "artifacts/gnatprove");

   type String_Access is access constant String;

   Evidence_Files : constant array (Positive range <>) of String_Access :=
     [new String'("results.log"),
      new String'("gnatprove.out"),
      new String'("assumptions.log")];

   --  A hit on any of these strings fails the gate. The comparison is
   --  case-insensitive, like the former Python gate (casefold).
   Needles : constant array (Positive range <>) of String_Access :=
     [new String'("might fail"),
      new String'("not proved"),
      new String'("unproved"),
      new String'("medium: flow"),
      new String'("high: flow"),
      new String'("assumption introduced")];

   --  The gnatprove.out summary table header ends with "Unproved" as a
   --  column name; lines carrying it are skipped, so that a fully proved
   --  run does not trip the "unproved" needle. The column positions are
   --  read from that same header line to extract the totals of the
   --  "Total" row: lines are aligned on the header, whatever the value
   --  width.
   Header : constant String := "spark analysis results";

   Found : array (Needles'Range) of Boolean := [others => False];

   Missing : US.Unbounded_String;
   Hits    : US.Unbounded_String;

   --  Column positions in the totals table; 0 until the header is seen,
   --  and Column_Number answers 0 while they are unset.
   Total_Pos     : Natural := 0;
   Justified_Pos : Natural := 0;
   Unproved_Pos  : Natural := 0;

   --  Totals extracted from the gnatprove.out totals table and from the
   --  per-unit flow analysis reports.
   Total_Checks : Natural := 0;
   Justified    : Natural := 0;
   Unproved     : Natural := 0;
   Flow_Errors  : Natural := 0;
   Proved       : Natural := 0;

   Check_Mark   : constant String := "✓";
   Warning_Mark : constant String := "⚠";

   function Full_Name (Name : String) return String is
     (DIR.Compose (Root, Name));

   function Lower (S : String) return String is
     (CH.To_Lower (S));

   function Leading_Number (S : String) return Natural is
      Result : Natural := 0;
      I      : Integer := S'First;
   begin
      while I <= S'Last and then S (I) in '0' .. '9' loop
         Result :=
           Result * 10 + (Character'Pos (S (I)) - Character'Pos ('0'));
         I := I + 1;
      end loop;
      return Result;
   end Leading_Number;

   --  The number written at Column in a table row: skip the blanks, read
   --  the leading digits. A "." column holds no number.
   function Column_Number (Line : String; Column : Natural) return Natural is
      From : Integer := Column;
   begin
      if Column not in Line'Range then
         return 0;
      end if;
      while From <= Line'Last and then Line (From) = ' ' loop
         From := From + 1;
      end loop;
      if From > Line'Last then
         return 0;
      end if;
      return Leading_Number (Line (From .. Line'Last));
   end Column_Number;

begin
   Check_Files :
   for F of Evidence_Files loop
      if not DIR.Exists (Full_Name (F.all)) then
         if US.Length (Missing) > 0 then
            US.Append (Missing, ", ");
         end if;
         US.Append (Missing, F.all);
      end if;
   end loop Check_Files;

   if US.Length (Missing) > 0 then
      TIO.Put_Line
        (TIO.Standard_Error,
         "missing proof evidence: " & US.To_String (Missing));
      CL.Set_Exit_Status (CL.Failure);
      return;
   end if;

   Scan_Files :
   for F of Evidence_Files loop
      Read_Evidence :
      declare
         File : TIO.File_Type;
      begin
         TIO.Open (File, TIO.In_File, Full_Name (F.all));
         Read_Lines :
         loop
            One_Line :
            declare
               Raw  : constant String := TIO.Get_Line (File);
               Line : constant String := Lower (Raw);
            begin
               --  The table header gives the column positions, but is not
               --  scanned for needles: it carries "Unproved" as a name.
               if FX.Index (Raw, "SPARK Analysis results") > 0 then
                  Total_Pos := FX.Index (Raw, "Total");
                  Justified_Pos := FX.Index (Raw, "Justified");
                  Unproved_Pos := FX.Index (Raw, "Unproved");
               end if;

               if FX.Index (Line, Header) = 0 then
                  Check_Needles :
                  for N in Needles'Range loop
                     if FX.Index (Line, Needles (N).all) > 0 then
                        Found (N) := True;
                     end if;
                  end loop Check_Needles;
               end if;

               --  The totals row. Its label "Total" is aligned on the
               --  first column, before the Total column itself.
               if Raw'Length >= 5 and then Raw (1 .. 5) = "Total" then
                  Total_Checks := Column_Number (Raw, Total_Pos);
                  Justified := Column_Number (Raw, Justified_Pos);
                  Unproved := Column_Number (Raw, Unproved_Pos);
               end if;

               --  Per-unit reports: "flow analyzed (N errors, ...)".
               Flow_Report :
               declare
                  Pos : constant Natural :=
                    FX.Index (Line, "flow analyzed (");
               begin
                  if Pos + 14 < Line'Last then
                     Flow_Errors :=
                       Flow_Errors
                       + Leading_Number (Line (Pos + 15 .. Line'Last));
                  end if;
               end Flow_Report;
            end One_Line;
         end loop Read_Lines;
      exception
         when TIO.End_Error => TIO.Close (File);
      end Read_Evidence;
   end loop Scan_Files;

   for N in Needles'Range loop
      if Found (N) then
         if US.Length (Hits) > 0 then
            US.Append (Hits, ", ");
         end if;
         US.Append (Hits, Needles (N).all);
      end if;
   end loop;

   --  The Total column counts every check; proved is what remains once
   --  the justified and unproved checks are taken out.
   if Total_Checks >= Justified + Unproved then
      Proved := Total_Checks - Justified - Unproved;
   end if;

   TIO.Put_Line ("GNATprove Summary");
   TIO.Put_Line (Check_Mark & Natural'Image (Proved) & " checks proved");
   TIO.Put_Line
     ((if Flow_Errors = 0 then Check_Mark else Warning_Mark)
      & Natural'Image (Flow_Errors)
      & " flow errors");
   TIO.Put_Line
     ((if Unproved = 0 then Check_Mark else Warning_Mark)
      & Natural'Image (Unproved)
      & " unproved checks");

   if US.Length (Hits) > 0 then
      TIO.Put_Line
        (TIO.Standard_Error,
         "proof integration conditions not met: " & US.To_String (Hits));
      CL.Set_Exit_Status (CL.Failure);
      return;
   end if;

   TIO.Put_Line ("GNATprove evidence satisfies the repository integration gate");
   CL.Set_Exit_Status (CL.Success);

end Check_Evidence;

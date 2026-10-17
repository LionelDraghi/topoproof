with Ada.Command_Line; use Ada.Command_Line;
with Ada.Strings; use Ada.Strings;
with Ada.Strings.Fixed; use Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Text_IO; use Ada.Text_IO;
with TopoProof.Geometry.Points; use TopoProof.Geometry.Points;
with TopoProof.Geometry.Translations; use TopoProof.Geometry.Translations;
with TopoProof.Geometry.Vectors; use TopoProof.Geometry.Vectors;
with TopoProof.Numerics; use TopoProof.Numerics;
procedure TopoProof_CLI is
   Usage_Error : exception;
   Input_Path, Output_Path : Unbounded_String;
   procedure Emit (S : String) is F : File_Type; begin
      if Length (Output_Path) = 0 then Put_Line (S); else Create (F, Out_File, To_String (Output_Path)); Put_Line (F, S); Close (F); end if;
   end Emit;
   function Token (S : in out Unbounded_String) return String is
      T : constant String := Trim (To_String (S), Both); I : constant Natural := Index (T, " ");
   begin
      if T'Length = 0 then return ""; elsif I = 0 then S := Null_Unbounded_String; return T;
      else S := To_Unbounded_String (T (I + 1 .. T'Last)); return T (T'First .. I - 1); end if;
   end Token;
   function C (S : String) return Grid_Coordinate is (Grid_Coordinate'Value (S));
   function V (S : String) return Vector_Component is (Vector_Component'Value (S));
   function Img (N : Grid_Coordinate) return String is (Trim (Grid_Coordinate'Image (N), Both));
   function Img (N : Vector_Component) return String is (Trim (Vector_Component'Image (N), Both));
   procedure Execute (Line : String) is
      R : Unbounded_String := To_Unbounded_String (Line); Op : constant String := Token (R);
   begin
      if Op = "translate" then
         declare P : constant Point_3D := (C (Token (R)), C (Token (R)), C (Token (R)));
                 D : constant Vector_3D := (V (Token (R)), V (Token (R)), V (Token (R)));
         begin
            if Token (R) /= "" then raise Usage_Error;
            elsif not Translation_Is_Representable (P, D) then Emit ("error: translation is not representable"); Set_Exit_Status (Failure);
            else declare Q : constant Point_3D := Translate (P, D); begin Emit ("point " & Img (Q.X) & " " & Img (Q.Y) & " " & Img (Q.Z)); end; end if;
         end;
      elsif Op = "displacement" then
         declare A : constant Point_3D := (C (Token (R)), C (Token (R)), C (Token (R)));
                 B : constant Point_3D := (C (Token (R)), C (Token (R)), C (Token (R)));
                 D : constant Vector_3D := Displacement (A, B);
         begin if Token (R) /= "" then raise Usage_Error; end if; Emit ("vector " & Img (D.DX) & " " & Img (D.DY) & " " & Img (D.DZ)); end;
      else raise Usage_Error; end if;
   exception when Constraint_Error => Emit ("error: invalid or out-of-range numeric parameter"); Set_Exit_Status (Failure); end Execute;
   Args : Unbounded_String; I : Positive := 1;
begin
   while I <= Argument_Count loop
      if Argument (I) = "--input" or else Argument (I) = "--output" then
         declare Is_Input : constant Boolean := Argument (I) = "--input"; begin I := I + 1; if I > Argument_Count then raise Usage_Error; end if;
            if Is_Input then Input_Path := To_Unbounded_String (Argument (I)); else Output_Path := To_Unbounded_String (Argument (I)); end if; end;
      elsif Argument (I) = "--help" or else Argument (I) = "-h" then Emit ("usage: topoproof OPERATION PARAMETERS [--output FILE]"); Emit ("       topoproof --input FILE [--output FILE]"); Emit ("operations: translate, displacement"); return;
      else if Length (Args) > 0 then Append (Args, " "); end if; Append (Args, Argument (I)); end if; I := I + 1;
   end loop;
   if Length (Input_Path) > 0 then
      if Length (Args) > 0 then raise Usage_Error; end if;
      declare F : File_Type; begin Open (F, In_File, To_String (Input_Path)); if End_Of_File (F) then Close (F); raise Usage_Error; end if; Execute (Get_Line (F)); Close (F); end;
   elsif Length (Args) > 0 then Execute (To_String (Args)); else raise Usage_Error; end if;
exception when Usage_Error => Put_Line (Standard_Error, "error: invalid command line"); Put_Line (Standard_Error, "try 'topoproof --help'"); Set_Exit_Status (Failure);
when Name_Error => Put_Line (Standard_Error, "error: input or output file cannot be opened"); Set_Exit_Status (Failure);
end TopoProof_CLI;

-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

package body TopoScript_API.Conversions is

   use TopoProof.Numerics;

   function Grid_In_Range (Value : Long_Long_Integer) return Boolean is
   begin
      return Value >= Long_Long_Integer (Grid_Coordinate'First)
        and then Value <= Long_Long_Integer (Grid_Coordinate'Last);
   end Grid_In_Range;

   function Dot_In_HAC_Range (V : Dot_Product) return Boolean is
   begin
      return V >= Dot_Product (Long_Long_Integer'First)
        and then V <= Dot_Product (Long_Long_Integer'Last);
   end Dot_In_HAC_Range;

   function Read_Point_2D
     (Data : HAC_Sys.Interfacing.HAC_Element_Array;
      From : Positive;
      P    : out TopoProof.Geometry.Points.Point_2D) return Boolean
   is
      X, Y : Long_Long_Integer;

   begin
      X := To_Long (Data (From));
      Y := To_Long (Data (From + 1));
      if not Grid_In_Range (X) or else not Grid_In_Range (Y) then
         return False;
      end if;
      P := (X => Grid_Coordinate (X), Y => Grid_Coordinate (Y));
      return True;
   end Read_Point_2D;

   function Read_Point_3D
     (Data : HAC_Sys.Interfacing.HAC_Element_Array;
      From : Positive;
      P    : out TopoProof.Geometry.Points.Point_3D) return Boolean
   is
      X, Y, Z : Long_Long_Integer;

   begin
      X := To_Long (Data (From));
      Y := To_Long (Data (From + 1));
      Z := To_Long (Data (From + 2));
      if not Grid_In_Range (X)
        or else not Grid_In_Range (Y)
        or else not Grid_In_Range (Z)
      then
         return False;
      end if;
      P := (X => Grid_Coordinate (X),
            Y => Grid_Coordinate (Y),
            Z => Grid_Coordinate (Z));
      return True;
   end Read_Point_3D;

   function Read_Vector_3D
     (Data : HAC_Sys.Interfacing.HAC_Element_Array;
      From : Positive;
      V    : out TopoProof.Geometry.Vectors.Vector_3D) return Boolean
   is
      DX, DY, DZ : Long_Long_Integer;

   begin
      DX := To_Long (Data (From));
      DY := To_Long (Data (From + 1));
      DZ := To_Long (Data (From + 2));
      if not Grid_In_Range (DX)
        or else not Grid_In_Range (DY)
        or else not Grid_In_Range (DZ)
      then
         return False;
      end if;
      V := (DX => Vector_Component (DX),
            DY => Vector_Component (DY),
            DZ => Vector_Component (DZ));
      return True;
   end Read_Vector_3D;

   --  Read three script integers from the HAC elements at From,
   --  each checked against the component domain: False means at
   --  least one component is outside the domain, and the components
   --  are then left unassigned, the caller recording its own
   --  diagnostic.
   generic
      type Component is range <>;
   function Read_Domain_Vector
     (Data    : HAC_Sys.Interfacing.HAC_Element_Array;
      From    :        Positive;
      X, Y, Z :    out Component) return Boolean;

   function Read_Domain_Vector
     (Data    : HAC_Sys.Interfacing.HAC_Element_Array;
      From    :        Positive;
      X, Y, Z :    out Component) return Boolean
   is
      VX, VY, VZ : Long_Long_Integer;
   begin
      VX := To_Long (Data (From));
      VY := To_Long (Data (From + 1));
      VZ := To_Long (Data (From + 2));
      if VX < Long_Long_Integer (Component'First)
        or else VX > Long_Long_Integer (Component'Last)
        or else VY < Long_Long_Integer (Component'First)
        or else VY > Long_Long_Integer (Component'Last)
        or else VZ < Long_Long_Integer (Component'First)
        or else VZ > Long_Long_Integer (Component'Last)
      then
         return False;
      end if;
      X := Component (VX);
      Y := Component (VY);
      Z := Component (VZ);
      return True;
   end Read_Domain_Vector;

   function Read_Grid_Vector_3D is new Read_Domain_Vector
     (TopoProof.Numerics.Vector_Component);
   function Read_Cross_Components is new Read_Domain_Vector
     (TopoProof.Numerics.Cross_Component);

   function Read_Vector_Result_3D
     (Data : HAC_Sys.Interfacing.HAC_Element_Array;
      From : Positive;
      V    : out TopoProof.Geometry.Vectors.Vector_3D) return Boolean
   is
   begin
      return Read_Grid_Vector_3D (Data, From, V.DX, V.DY, V.DZ);
   end Read_Vector_Result_3D;

   function Read_Cross_Vector_3D
     (Data : HAC_Sys.Interfacing.HAC_Element_Array;
      From : Positive;
      V    : out TopoProof.Geometry.Vectors.Cross_Vector_3D) return Boolean
   is
   begin
      return Read_Cross_Components (Data, From, V.DX, V.DY, V.DZ);
   end Read_Cross_Vector_3D;

   procedure Write_Point_3D
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array;
      From :        Positive;
      P    :        TopoProof.Geometry.Points.Point_3D)
   is
   begin
      Data (From)     := Grid_To_HAC (P.X);
      Data (From + 1) := Grid_To_HAC (P.Y);
      Data (From + 2) := Grid_To_HAC (P.Z);
   end Write_Point_3D;

   procedure Write_Vector_3D
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array;
      From :        Positive;
      V    :        TopoProof.Geometry.Vectors.Vector_3D)
   is
   begin
      Data (From)     := Vector_To_HAC (V.DX);
      Data (From + 1) := Vector_To_HAC (V.DY);
      Data (From + 2) := Vector_To_HAC (V.DZ);
   end Write_Vector_3D;

   procedure Write_Cross_Vector_3D
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array;
      From :        Positive;
      V    :        TopoProof.Geometry.Vectors.Cross_Vector_3D)
   is
   begin
      Data (From)     := Cross_To_HAC (V.DX);
      Data (From + 1) := Cross_To_HAC (V.DY);
      Data (From + 2) := Cross_To_HAC (V.DZ);
   end Write_Cross_Vector_3D;

   function Read_Vertex_Handle
     (Data : HAC_Sys.Interfacing.HAC_Element_Array;
      From : Positive;
      H    : out TopoProof.Topology.Vertices.Vertex_Handle)
      return Boolean
   is
      V : constant Long_Long_Integer := To_Long (Data (From));

   begin
      if V < 1
        or else V > Long_Long_Integer
                   (TopoProof.Topology.Vertices.Max_Vertices)
      then
         return False;
      end if;
      H := TopoProof.Topology.Vertices.Vertex_Handle (V);
      return True;
   end Read_Vertex_Handle;

   function Read_Edge_Handle
     (Data : HAC_Sys.Interfacing.HAC_Element_Array;
      From : Positive;
      E    : out TopoProof.Topology.Edges.Edge_Handle)
      return Boolean
   is
      V : constant Long_Long_Integer := To_Long (Data (From));

   begin
      if V < 1
        or else V > Long_Long_Integer
                   (TopoProof.Topology.Edges.Max_Edges)
      then
         return False;
      end if;
      E := TopoProof.Topology.Edges.Edge_Handle (V);
      return True;
   end Read_Edge_Handle;

end TopoScript_API.Conversions;

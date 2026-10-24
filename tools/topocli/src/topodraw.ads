-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with Ada.Containers.Indefinite_Vectors;
with Ada.Strings.Unbounded;

package Topodraw is

   type Point_Rec is record
      Name : Ada.Strings.Unbounded.Unbounded_String;
      X, Y, Z : Integer;
      --  SVG fill color of the point: empty keeps the default blue of
      --  the rendered diagrams.
      Color : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   package Scene_Point_Vectors is new Ada.Containers.Indefinite_Vectors
     (Positive, Point_Rec);

   type Vector_Rec is record
      From_Name : Ada.Strings.Unbounded.Unbounded_String;
      To_Name   : Ada.Strings.Unbounded.Unbounded_String;
      Label     : Ada.Strings.Unbounded.Unbounded_String;
      --  SVG stroke color of the vector: empty keeps the default green
      --  of the rendered diagrams, arrow head included.
      Color : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   package Scene_Vector_Vectors is new Ada.Containers.Indefinite_Vectors
     (Positive, Vector_Rec);

   --  One plane patch: the parallelogram of the three defining
   --  points, closed by the fourth corner B + C - A, filled
   --  translucent behind every other primitive.
   type Plane_Rec is record
      AX, AY, AZ : Integer;
      BX, BY, BZ : Integer;
      CX, CY, CZ : Integer;
      --  SVG fill and stroke color of the patch: empty keeps the
      --  default gray of the rendered diagrams.
      Color : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
   end record;

   package Scene_Plane_Vectors is new Ada.Containers.Indefinite_Vectors
     (Positive, Plane_Rec);

   type Scene is record
      Draw_Axes : Boolean := False;
      Tick_Step : Integer := -1;  -- -1: no ticks, 0: automatic step
      Anchors   : Boolean := False;
      Points    : Scene_Point_Vectors.Vector;
      Vectors   : Scene_Vector_Vectors.Vector;
      Planes    : Scene_Plane_Vectors.Vector;
   end record;

   Scene_Error : exception;

   --  Render a scene as a deterministic axonometric SVG image.
   function Render (S : Scene) return String;

end Topodraw;

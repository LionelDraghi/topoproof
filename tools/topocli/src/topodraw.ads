-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with Ada.Containers.Indefinite_Vectors;
with Ada.Strings.Unbounded;

package Topodraw is

   package Point_Vectors is new Ada.Containers.Indefinite_Vectors
     (Positive, String);

   type Point_Rec is record
      Name : Ada.Strings.Unbounded.Unbounded_String;
      X, Y, Z : Integer;
   end record;

   package Scene_Point_Vectors is new Ada.Containers.Indefinite_Vectors
     (Positive, Point_Rec);

   type Vector_Rec is record
      From_Name : Ada.Strings.Unbounded.Unbounded_String;
      To_Name   : Ada.Strings.Unbounded.Unbounded_String;
      Label     : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   package Scene_Vector_Vectors is new Ada.Containers.Indefinite_Vectors
     (Positive, Vector_Rec);

   type Scene is record
      Draw_Axes : Boolean := False;
      Tick_Step : Integer := -1;  -- -1: no ticks, 0: automatic step
      Anchors   : Boolean := False;
      Points    : Scene_Point_Vectors.Vector;
      Vectors   : Scene_Vector_Vectors.Vector;
   end record;

   Scene_Error : exception;

   --  Parse one scene source into a Scene value. Raise Scene_Error with a
   --  message prefixed by the source line number on any invalid statement.
   function Parse_Scene (Source : String) return Scene;

   --  Render a scene as a deterministic isometric SVG image.
   function Render (S : Scene) return String;

   --  Scan one Markdown file for scene comments (<!-- topodraw <file>),
   --  render each scene to its declared SVG file, and return the number of
   --  diagrams generated. Raise Scene_Error if a scene source contains
   --  '--', or if a generated file is not referenced elsewhere in the page.
   function Process (Markdown_Path : String) return Natural;

end Topodraw;

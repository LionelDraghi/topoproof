-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

--  The drawing domain of the scripting API (development plan,
--  TopoScript consolidation, Increment 2): the diagnostic images. The
--  script builds one scene of the designated session through the
--  drawing operations, and End_Image renders it as an SVG file through
--  the topodraw renderer. The image is a generated file: it never
--  pollutes the canonical standard output.

with HAC_Sys.Interfacing;

package TopoScript_API.Drawing is

   --  The drawing colors of the diagnostic images: the wrapper
   --  injects the same type in the script world, with the same
   --  positions.
   type Color_Kind is (Blue, Green, Red);

   --  Native side of Begin_Image: opens one image under the given
   --  VString name, with an empty scene.
   procedure Begin_Image_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

   --  Native side of Draw_Axes: axes with automatic tick marks and
   --  the dashed coordinate paths of every point.
   procedure Draw_Axes_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

   --  Native side of Draw_Point: the point colors the scene, and the
   --  script may call it before or after any operation.
   procedure Draw_Point_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

   --  Native side of Draw_Vector: the arrow runs from the origin to
   --  the tip; both anchor on points, drawn or reused, colored with
   --  the vector color.
   procedure Draw_Vector_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

   --  Native side of Draw_Point_2D: the point colors the scene at
   --  (X, Y, 0), the plane the 2D operations live in.
   procedure Draw_Point_2D_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

   --  Native side of Draw_Edge: the arrow runs from P to Q, labeled
   --  with the displacement, like the segment diagrams of the client
   --  operations; a degenerate edge draws nothing.
   procedure Draw_Edge_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

   --  Native side of Draw_Segment_2D: the plain 2D segment from P to
   --  Q, without label: the diagrams of crossing segments, where the
   --  displacement labels of Draw_Edge would overlap at the common
   --  midpoint.
   procedure Draw_Segment_2D_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

   --  Native side of End_Image: renders the scene of the open image
   --  through the topodraw renderer, and closes the image.
   procedure End_Image_Native
     (Data : in out HAC_Sys.Interfacing.HAC_Element_Array);

end TopoScript_API.Drawing;

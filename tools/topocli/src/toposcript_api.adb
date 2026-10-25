-- -----------------------------------------------------------------------------
--  TopoProof, provable geometry application
--  (https://github.com/LionelDraghi/topoproof)
--  SPDX-License-Identifier: Apache-2.0
--  SPDX-FileCopyrightText: 2026, Lionel Draghi
-- -----------------------------------------------------------------------------

with HAC_Sys.Interfacing;
use HAC_Sys.Interfacing;

with TopoScript_API.Drawing;
with TopoScript_API.Geometry;
with TopoScript_API.Output;
with TopoScript_API.Topology;

package body TopoScript_API is

   procedure Register_All (BD : HAC_Sys.Builder.Build_Data) is
   begin
      Register (BD, Geometry.Translate_Native'Access, "Translate");
      Register (BD, Geometry.Displacement_Native'Access, "Displacement");
      Register (BD, Geometry.Dot_Product_Native'Access, "Dot_Product");
      Register (BD, Geometry.Cross_Product_Native'Access, "Cross_Product");
      Register (BD, Geometry.Make_Plane_Native'Access, "Make_Plane");
      Register (BD, Geometry.Plane_Side_Native'Access, "Plane_Side");
      Register (BD, Geometry.Equal_Native'Access, "Equal");
      Register (BD, Geometry.Orientation_Native'Access, "Orientation");
      Register (BD, Geometry.Intersection_Native'Access, "Intersection");
      Register (BD, Output.Put_Native'Access, "Put");
      Register (BD, Output.Put_Vector_Native'Access, "Put_Vector");
      Register (BD, Output.Put_Dot_Native'Access, "Put_Dot");
      Register (BD, Output.Put_Cross_Vector_Native'Access,
                "Put_Cross_Vector");
      Register (BD, Output.Put_Equal_Native'Access, "Put_Equal");
      Register (BD, Output.Put_Orientation_Native'Access,
                "Put_Orientation");
      Register (BD, Geometry.Orientation_3D_Native'Access,
                "Orientation_3D");
      Register (BD, Output.Put_Orientation_3D_Native'Access,
                "Put_Orientation_3D");
      Register (BD, Output.Put_Plane_Side_Native'Access,
                "Put_Plane_Side");
      Register (BD, Output.Put_Plane_Kind_Native'Access,
                "Put_Plane_Kind");
      Register (BD, Output.Put_Intersection_Native'Access,
                "Put_Intersection");
      Register (BD, Drawing.Begin_Image_Native'Access, "Begin_Image");
      Register (BD, Drawing.Draw_Axes_Native'Access, "Draw_Axes");
      Register (BD, Drawing.Draw_Point_Native'Access, "Draw_Point");
      Register (BD, Drawing.Draw_Named_Point_Native'Access,
                "Draw_Named_Point");
      Register (BD, Drawing.Draw_Named_Point_2D_Native'Access,
                "Draw_Named_Point_2D");
      Register (BD, Drawing.Draw_Named_Vector_Native'Access,
                "Draw_Named_Vector");
      Register (BD, Drawing.Draw_Vector_Native'Access, "Draw_Vector");
      Register (BD, Drawing.Draw_Plane_Native'Access, "Draw_Plane");
      Register (BD, Drawing.Draw_Point_2D_Native'Access,
                "Draw_Point_2D");
      Register (BD, Drawing.Draw_Edge_Native'Access, "Draw_Edge");
      Register (BD, Drawing.Draw_Segment_2D_Native'Access,
                "Draw_Segment_2D");
      Register (BD, Drawing.End_Image_Native'Access, "End_Image");
      Register (BD, Topology.Add_Point_Native'Access, "Add_Point");
      Register (BD, Topology.Make_Loop_Native'Access, "Make_Loop");
      Register (BD, Topology.Make_Face_Native'Access, "Make_Face");
      Register (BD, Output.Put_Loop_Native'Access, "Put_Loop");
      Register (BD, Output.Put_Face_Native'Access, "Put_Face");
      Register (BD, Topology.Contour_Continuity_Native'Access,
                "Contour_Continuity");
      Register (BD, Topology.Contour_Closure_Native'Access,
                "Contour_Closure");
      Register (BD, Topology.Contour_Orientation_Native'Access,
                "Contour_Orientation");
      Register (BD, Topology.Contour_Self_Intersects_Native'Access,
                "Contour_Self_Intersects");
      Register (BD, Topology.Contour_Valid_Native'Access,
                "Contour_Valid");
      Register (BD, Topology.Contour_No_Flat_Turns_Native'Access,
                "Contour_No_Flat_Turns");
      Register (BD, Output.Put_Continuity_Native'Access,
                "Put_Continuity");
      Register (BD, Output.Put_Closure_Native'Access, "Put_Closure");
      Register (BD, Output.Put_Contour_Orientation_Native'Access,
                "Put_Contour_Orientation");
      Register (BD, Output.Put_Bool_Native'Access, "Put_Bool");
      Register (BD, Topology.Create_Vertex_Native'Access,
                "Create_Vertex");
      Register (BD, Topology.Create_Edge_Native'Access, "Create_Edge");
      Register (BD, Topology.Make_Loop_From_Edges_Native'Access,
                "Make_Loop_From_Edges");
      Register (BD, Output.Put_Vertex_Native'Access, "Put_Vertex");
      Register (BD, Output.Put_Edge_Native'Access, "Put_Edge");
   end Register_All;

end TopoScript_API;

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
      Register (BD, Geometry.Equal_Native'Access, "Equal");
      Register (BD, Output.Put_Native'Access, "Put");
      Register (BD, Output.Put_Vector_Native'Access, "Put_Vector");
      Register (BD, Output.Put_Equal_Native'Access, "Put_Equal");
      Register (BD, Drawing.Begin_Image_Native'Access, "Begin_Image");
      Register (BD, Drawing.Draw_Axes_Native'Access, "Draw_Axes");
      Register (BD, Drawing.Draw_Point_Native'Access, "Draw_Point");
      Register (BD, Drawing.Draw_Vector_Native'Access, "Draw_Vector");
      Register (BD, Drawing.Draw_Point_2D_Native'Access,
                "Draw_Point_2D");
      Register (BD, Drawing.Draw_Edge_Native'Access, "Draw_Edge");
      Register (BD, Drawing.End_Image_Native'Access, "End_Image");
      Register (BD, Topology.Add_Point_Native'Access, "Add_Point");
      Register (BD, Topology.Make_Loop_Native'Access, "Make_Loop");
      Register (BD, Topology.Make_Face_Native'Access, "Make_Face");
      Register (BD, Output.Put_Loop_Native'Access, "Put_Loop");
      Register (BD, Output.Put_Face_Native'Access, "Put_Face");
   end Register_All;

end TopoScript_API;

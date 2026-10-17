with TopoProof.Geometry.Points;
with TopoProof.Numerics;
package TopoProof.Geometry.Vectors with Pure, SPARK_Mode is
   type Vector_3D is record
      DX : Numerics.Vector_Component;
      DY : Numerics.Vector_Component;
      DZ : Numerics.Vector_Component;
   end record;
   function Displacement (From, To_Point : Points.Point_3D) return Vector_3D
   with Post =>
     Numerics.Extended_Component (Displacement'Result.DX) = Numerics.Extended_Component (To_Point.X) - Numerics.Extended_Component (From.X)
     and then Numerics.Extended_Component (Displacement'Result.DY) = Numerics.Extended_Component (To_Point.Y) - Numerics.Extended_Component (From.Y)
     and then Numerics.Extended_Component (Displacement'Result.DZ) = Numerics.Extended_Component (To_Point.Z) - Numerics.Extended_Component (From.Z);
end TopoProof.Geometry.Vectors;

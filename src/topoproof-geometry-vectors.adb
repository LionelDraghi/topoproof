package body TopoProof.Geometry.Vectors with SPARK_Mode is
   function Displacement (From, To_Point : Points.Point_3D) return Vector_3D is
   begin
      return (DX => Numerics.Vector_Component (Numerics.Extended_Component (To_Point.X) - Numerics.Extended_Component (From.X)),
              DY => Numerics.Vector_Component (Numerics.Extended_Component (To_Point.Y) - Numerics.Extended_Component (From.Y)),
              DZ => Numerics.Vector_Component (Numerics.Extended_Component (To_Point.Z) - Numerics.Extended_Component (From.Z)));
   end Displacement;
end TopoProof.Geometry.Vectors;

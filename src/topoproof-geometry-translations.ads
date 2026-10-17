with TopoProof.Geometry.Points;
with TopoProof.Geometry.Vectors;
with TopoProof.Numerics;
package TopoProof.Geometry.Translations with Pure, SPARK_Mode is
   function Translation_Is_Representable (P : Points.Point_3D; V : Vectors.Vector_3D) return Boolean;
   function Translate (P : Points.Point_3D; V : Vectors.Vector_3D) return Points.Point_3D
   with Pre => Translation_Is_Representable (P, V),
        Post => Numerics.Extended_Component (Translate'Result.X) = Numerics.Extended_Component (P.X) + Numerics.Extended_Component (V.DX)
          and then Numerics.Extended_Component (Translate'Result.Y) = Numerics.Extended_Component (P.Y) + Numerics.Extended_Component (V.DY)
          and then Numerics.Extended_Component (Translate'Result.Z) = Numerics.Extended_Component (P.Z) + Numerics.Extended_Component (V.DZ);
end TopoProof.Geometry.Translations;

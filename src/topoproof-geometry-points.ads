with TopoProof.Numerics;
package TopoProof.Geometry.Points with Pure, SPARK_Mode is
   type Point_3D is record
      X : Numerics.Grid_Coordinate;
      Y : Numerics.Grid_Coordinate;
      Z : Numerics.Grid_Coordinate;
   end record;
end TopoProof.Geometry.Points;


# Document: [command-line.md](../features/command-line.md)  
   ### Scenario: [display help](../features/command-line.md): 
   - OK : When I successfully run `../bin/topocli --help`  
   - OK : Then the output is  
   - [X] scenario   [display help](../features/command-line.md) pass  

   ### Scenario: [a command-line operation is rejected](../features/command-line.md): 
   - OK : When I run `../bin/topocli translate P=(10, -20, 30) D=(5, 7, -9)`  
   - OK : Then the error output is  
   - OK : And the exit code is `1`  
   - [X] scenario   [a command-line operation is rejected](../features/command-line.md) pass  

   ### Scenario: [an entry without its operand is rejected](../features/command-line.md): 
   - OK : When I run `../bin/topocli run`  
   - OK : Then the error output is  
   - OK : And the exit code is `1`  
   - [X] scenario   [an entry without its operand is rejected](../features/command-line.md) pass  

   ### Scenario: [a script file that does not exist is rejected](../features/command-line.md): 
   - OK : When I run `../bin/topocli run no_such_file.topo`  
   - OK : Then the error output is `error: file not found: no_such_file.topo`  
   - OK : And the exit code is `1`  
   - [X] scenario   [a script file that does not exist is rejected](../features/command-line.md) pass  


# Document: [translation.md](../features/translation.md)  
   ### Scenario: [translate a point by a vector](../features/translation.md): 
   - OK : Given the file `translate.topo`  
   - OK : When I successfully run `../bin/topocli run translate.topo`  
   - OK : Then the output is `point 15 -13 21`  
   - OK : And the file `../docs/features/images/translation_1.svg` contains `#cf222e`    
   - [X] scenario   [translate a point by a vector](../features/translation.md) pass  

   ### Scenario: [reject an unrepresentable result](../features/translation.md): 
   - OK : Given the file `translate_beyond.topo`  
   - OK : When I run `../bin/topocli run translate_beyond.topo`  
   - OK : Then the error output is `error: translation is not representable`  
   - OK : And the exit code is `1`  
   - OK : And the file `../docs/features/images/translation_2.svg` contains `#1f6feb`    
   - [X] scenario   [reject an unrepresentable result](../features/translation.md) pass  

   ### Scenario: [write the result to a file](../features/translation.md): 
   - OK : Given the file `translate_output.topo`  
   - OK : When I successfully run `../bin/topocli run translate_output.topo --output translation.out`  
   - OK : Then the output is  
   - OK : And the file `translation.out` is `point 5 7 9`  
   - [X] scenario   [write the result to a file](../features/translation.md) pass  

   ### Scenario: [translation and displacement compose to the identity](../features/translation.md): 
   - OK : Given the file `compose.topo`  
   - OK : When I successfully run `../bin/topocli run compose.topo`  
   - OK : Then the output is  
   - [X] scenario   [translation and displacement compose to the identity](../features/translation.md) pass  


# Document: [displacement.md](../features/displacement.md)  
   ### Scenario: [compute the displacement between two points](../features/displacement.md): 
   - OK : Given the file `displacement.topo`  
   - OK : When I successfully run `../bin/topocli run displacement.topo`  
   - OK : Then the output is `vector 5 -7 9`  
   - OK : And the file `../docs/features/images/displacement_1.svg` contains `#cf222e`    
   - [X] scenario   [compute the displacement between two points](../features/displacement.md) pass  

   ### Scenario: [the result of a script run goes to the output file](../features/displacement.md): 
   - OK : Given the file `displacement_output.topo`  
   - OK : When I successfully run `../bin/topocli run displacement_output.topo --output displacement-file.out`  
   - OK : Then the output is  
   - OK : And the file `displacement-file.out` is `vector -4 5 -6`  
   - [X] scenario   [the result of a script run goes to the output file](../features/displacement.md) pass  


# Document: [vectors.md](../features/vectors.md)  
   ### Scenario: [the dot product of two vectors](../features/vectors.md): 
   - OK : Given the file `dot_product.topo`  
   - OK : When I successfully run `../bin/topocli run dot_product.topo`  
   - OK : Then the output is `dot -2`  
   - [X] scenario   [the dot product of two vectors](../features/vectors.md) pass  

   ### Scenario: [the cross product of two vectors](../features/vectors.md): 
   - OK : Given the file `cross_product.topo`  
   - OK : When I successfully run `../bin/topocli run cross_product.topo`  
   - OK : Then the output is `cross -1 6 5`  
   - OK : And the file `../docs/features/images/cross_product_1.svg` contains `#cf222e`  
   - [X] scenario   [the cross product of two vectors](../features/vectors.md) pass  

   ### Scenario: [the cross product is orthogonal to both operands](../features/vectors.md): 
   - OK : Given the file `cross_orthogonality.topo`  
   - OK : When I successfully run `../bin/topocli run cross_orthogonality.topo`  
   - OK : Then the output is  
   - [X] scenario   [the cross product is orthogonal to both operands](../features/vectors.md) pass  

   ### Scenario: [the exact results leave the grid amplitude](../features/vectors.md): 
   - OK : Given the file `cross_amplitude.topo`  
   - OK : When I successfully run `../bin/topocli run cross_amplitude.topo`  
   - OK : Then the output is `cross 0 0 2500000000`  
   - [X] scenario   [the exact results leave the grid amplitude](../features/vectors.md) pass  

   ### Scenario: [a vector operand outside the grid input contract is rejected](../features/vectors.md): 
   - OK : Given the file `vector_contract.topo`  
   - OK : When I run `../bin/topocli run vector_contract.topo`  
   - OK : Then there is no output  
   - OK : And the error output is `error: coordinate outside the grid`  
   - OK : And the exit code is `1`  
   - [X] scenario   [a vector operand outside the grid input contract is rejected](../features/vectors.md) pass  


# Document: [planes.md](../features/planes.md)  
   ### Scenario: [the coordinate plane classifies its points](../features/planes.md): 
   - OK : Given the file `coordinate_plane.topo`  
   - OK : When I successfully run `../bin/topocli run coordinate_plane.topo`  
   - OK : Then the output is  
   - OK : And the file `../docs/features/images/planes_1.svg` contains `#1a7f37`  
   - [X] scenario   [the coordinate plane classifies its points](../features/planes.md) pass  

   ### Scenario: [coplanar points classify as on the plane](../features/planes.md): 
   - OK : Given the file `coplanar_points.topo`  
   - OK : When I successfully run `../bin/topocli run coplanar_points.topo`  
   - OK : Then the output is  
   - OK : And the file `../docs/features/images/planes_2.svg` contains `#cf222e`  
   - [X] scenario   [coplanar points classify as on the plane](../features/planes.md) pass  

   ### Scenario: [a collinear definition is rejected](../features/planes.md): 
   - OK : Given the file `collinear_plane.topo`  
   - OK : When I successfully run `../bin/topocli run collinear_plane.topo`  
   - OK : Then the output is  
   - [X] scenario   [a collinear definition is rejected](../features/planes.md) pass  

   ### Scenario: [the classification is translation invariant](../features/planes.md): 
   - OK : Given the file `translated_plane.topo`  
   - OK : When I successfully run `../bin/topocli run translated_plane.topo`  
   - OK : Then the output is  
   - [X] scenario   [the classification is translation invariant](../features/planes.md) pass  

   ### Scenario: [the grid boundary classifies exactly](../features/planes.md): 
   - OK : Given the file `boundary_plane.topo`  
   - OK : When I successfully run `../bin/topocli run boundary_plane.topo`  
   - OK : Then the output is  
   - [X] scenario   [the grid boundary classifies exactly](../features/planes.md) pass  


# Document: [orientation3d.md](../features/orientation3d.md)  
   ### Scenario: [a tetrahedron along the axes classifies right-handed](../features/orientation3d.md): 
   - OK : Given the file `tetrahedron.topo`  
   - OK : When I successfully run `../bin/topocli run tetrahedron.topo`  
   - OK : Then the output is  
   - OK : And the file `../docs/features/images/orientation3d_1.svg` contains `#1a7f37`  
   - [X] scenario   [a tetrahedron along the axes classifies right-handed](../features/orientation3d.md) pass  

   ### Scenario: [exchanging two points mirrors the orientation](../features/orientation3d.md): 
   - OK : Given the file `exchanged_tetrahedron.topo`  
   - OK : When I successfully run `../bin/topocli run exchanged_tetrahedron.topo`  
   - OK : Then the output is  
   - OK : And the file `../docs/features/images/orientation3d_2.svg` contains `#cf222e`  
   - [X] scenario   [exchanging two points mirrors the orientation](../features/orientation3d.md) pass  

   ### Scenario: [coplanar points classify as coplanar](../features/orientation3d.md): 
   - OK : Given the file `coplanar_tetrahedron.topo`  
   - OK : When I successfully run `../bin/topocli run coplanar_tetrahedron.topo`  
   - OK : Then the output is  
   - OK : And the file `../docs/features/images/orientation3d_3.svg` contains `#1a7f37`  
   - [X] scenario   [coplanar points classify as coplanar](../features/orientation3d.md) pass  

   ### Scenario: [the classification is translation invariant](../features/orientation3d.md): 
   - OK : Given the file `translated_tetrahedron.topo`  
   - OK : When I successfully run `../bin/topocli run translated_tetrahedron.topo`  
   - OK : Then the output is  
   - OK : And the file `../docs/features/images/orientation3d_4.svg` contains `#cf222e`  
   - [X] scenario   [the classification is translation invariant](../features/orientation3d.md) pass  

   ### Scenario: [the grid corners do not overflow](../features/orientation3d.md): 
   - OK : Given the file `corner_tetrahedron.topo`  
   - OK : When I successfully run `../bin/topocli run corner_tetrahedron.topo`  
   - OK : Then the output is  
   - [X] scenario   [the grid corners do not overflow](../features/orientation3d.md) pass  


# Document: [equality.md](../features/equality.md)  
   ### Scenario: [identical points are equal](../features/equality.md): 
   - OK : Given the file `equal_true.topo`  
   - OK : When I successfully run `../bin/topocli run equal_true.topo`  
   - OK : Then the output is `equal true`  
   - OK : And the file `../docs/features/images/equality_1.svg` contains `#1a7f37`    
   - [X] scenario   [identical points are equal](../features/equality.md) pass  

   ### Scenario: [different points are not equal](../features/equality.md): 
   - OK : Given the file `equal_false.topo`  
   - OK : When I successfully run `../bin/topocli run equal_false.topo`  
   - OK : Then the output is `equal false`  
   - OK : And the file `../docs/features/images/equality_2.svg` contains `#1a7f37`    
   - [X] scenario   [different points are not equal](../features/equality.md) pass  

   ### Scenario: [opposite points are not equal](../features/equality.md): 
   - OK : Given the file `equal_opposite.topo`  
   - OK : When I successfully run `../bin/topocli run equal_opposite.topo`  
   - OK : Then the output is `equal false`  
   - OK : And the file `../docs/features/images/equality_3.svg` contains `#1a7f37`    
   - [X] scenario   [opposite points are not equal](../features/equality.md) pass  


# Document: [orientation.md](../features/orientation.md)  
   ### Scenario: [a counter-clockwise path](../features/orientation.md): 
   - OK : Given the file `ccw_path.topo`  
   - OK : When I successfully run `../bin/topocli run ccw_path.topo`  
   - OK : Then the output is `orientation counter_clockwise`  
   - OK : And the file `../docs/features/images/orientation_1.svg` contains `#cf222e`    
   - [X] scenario   [a counter-clockwise path](../features/orientation.md) pass  

   ### Scenario: [a clockwise path](../features/orientation.md): 
   - OK : Given the file `cw_path.topo`  
   - OK : When I successfully run `../bin/topocli run cw_path.topo`  
   - OK : Then the output is `orientation clockwise`  
   - [X] scenario   [a clockwise path](../features/orientation.md) pass  

   ### Scenario: [three aligned points are collinear](../features/orientation.md): 
   - OK : Given the file `collinear_path.topo`  
   - OK : When I successfully run `../bin/topocli run collinear_path.topo`  
   - OK : Then the output is `orientation collinear`  
   - [X] scenario   [three aligned points are collinear](../features/orientation.md) pass  

   ### Scenario: [two coincident points make a degenerate collinear path](../features/orientation.md): 
   - OK : Given the file `degenerate_path.topo`  
   - OK : When I successfully run `../bin/topocli run degenerate_path.topo`  
   - OK : Then the output is `orientation collinear`  
   - [X] scenario   [two coincident points make a degenerate collinear path](../features/orientation.md) pass  

   ### Scenario: [the extreme corners of the grid do not overflow](../features/orientation.md): 
   - OK : Given the file `corners_path.topo`  
   - OK : When I successfully run `../bin/topocli run corners_path.topo`  
   - OK : Then the output is `orientation counter_clockwise`  
   - [X] scenario   [the extreme corners of the grid do not overflow](../features/orientation.md) pass  

   ### Scenario: [a cyclic permutation keeps the orientation](../features/orientation.md): 
   - OK : Given the file `cyclic_path.topo`  
   - OK : When I successfully run `../bin/topocli run cyclic_path.topo`  
   - OK : Then the output is  
   - [X] scenario   [a cyclic permutation keeps the orientation](../features/orientation.md) pass  

   ### Scenario: [exchanging two points mirrors the orientation](../features/orientation.md): 
   - OK : Given the file `exchanged_path.topo`  
   - OK : When I successfully run `../bin/topocli run exchanged_path.topo`  
   - OK : Then the output is `orientation clockwise`  
   - OK : And the file `../docs/features/images/orientation_2.svg` contains `#cf222e`    
   - [X] scenario   [exchanging two points mirrors the orientation](../features/orientation.md) pass  

   ### Scenario: [the orientation is invariant under translation](../features/orientation.md): 
   - OK : Given the file `translated_path.topo`  
   - OK : When I successfully run `../bin/topocli run translated_path.topo`  
   - OK : Then the output is  
   - OK : And the file `../docs/features/images/orientation_7.svg` contains `#cf222e`    
   - [X] scenario   [the orientation is invariant under translation](../features/orientation.md) pass  


# Document: [intersection.md](../features/intersection.md)  
   ### Scenario: [a proper crossing on a grid position](../features/intersection.md): 
   - OK : Given the file `crossing_grid.topo`  
   - OK : When I successfully run `../bin/topocli run crossing_grid.topo`  
   - OK : Then the output is `intersection point_intersection 1 1`  
   - OK : And the file `../docs/features/images/intersection_1.svg` contains `#1a7f37`    
   - [X] scenario   [a proper crossing on a grid position](../features/intersection.md) pass  

   ### Scenario: [a proper crossing off the grid](../features/intersection.md): 
   - OK : Given the file `crossing_off_grid.topo`  
   - OK : When I successfully run `../bin/topocli run crossing_off_grid.topo`  
   - OK : Then the output is `intersection off_grid_crossing`  
   - [X] scenario   [a proper crossing off the grid](../features/intersection.md) pass  

   ### Scenario: [collinear segments overlap](../features/intersection.md): 
   - OK : Given the file `overlap.topo`  
   - OK : When I successfully run `../bin/topocli run overlap.topo`  
   - OK : Then the output is `intersection overlap 2 0 4 0`  
   - [X] scenario   [collinear segments overlap](../features/intersection.md) pass  

   ### Scenario: [collinear segments touch at one point](../features/intersection.md): 
   - OK : Given the file `touch.topo`  
   - OK : When I successfully run `../bin/topocli run touch.topo`  
   - OK : Then the output is `intersection point_intersection 2 0`  
   - [X] scenario   [collinear segments touch at one point](../features/intersection.md) pass  

   ### Scenario: [collinear segments do not meet](../features/intersection.md): 
   - OK : Given the file `gap.topo`  
   - OK : When I successfully run `../bin/topocli run gap.topo`  
   - OK : Then the output is `intersection no_intersection`  
   - [X] scenario   [collinear segments do not meet](../features/intersection.md) pass  

   ### Scenario: [an endpoint on the other segment](../features/intersection.md): 
   - OK : Given the file `junction.topo`  
   - OK : When I successfully run `../bin/topocli run junction.topo`  
   - OK : Then the output is `intersection point_intersection 1 0`  
   - [X] scenario   [an endpoint on the other segment](../features/intersection.md) pass  

   ### Scenario: [a degenerate point segment on another segment](../features/intersection.md): 
   - OK : Given the file `point_on_segment.topo`  
   - OK : When I successfully run `../bin/topocli run point_on_segment.topo`  
   - OK : Then the output is `intersection point_intersection 2 1`  
   - [X] scenario   [a degenerate point segment on another segment](../features/intersection.md) pass  

   ### Scenario: [two identical degenerate point segments](../features/intersection.md): 
   - OK : Given the file `two_points.topo`  
   - OK : When I successfully run `../bin/topocli run two_points.topo`  
   - OK : Then the output is `intersection point_intersection 1 1`  
   - [X] scenario   [two identical degenerate point segments](../features/intersection.md) pass  

   ### Scenario: [disjoint segments](../features/intersection.md): 
   - OK : Given the file `disjoint.topo`  
   - OK : When I successfully run `../bin/topocli run disjoint.topo`  
   - OK : Then the output is `intersection no_intersection`  
   - [X] scenario   [disjoint segments](../features/intersection.md) pass  

   ### Scenario: [the grid corners do not overflow](../features/intersection.md): 
   - OK : Given the file `corner_diagonals.topo`  
   - OK : When I successfully run `../bin/topocli run corner_diagonals.topo`  
   - OK : Then the output is `intersection point_intersection 0 0`  
   - [X] scenario   [the grid corners do not overflow](../features/intersection.md) pass  

   ### Scenario: [the order of the arguments does not matter](../features/intersection.md): 
   - OK : Given the file `symmetric_crossing.topo`  
   - OK : When I successfully run `../bin/topocli run symmetric_crossing.topo`  
   - OK : Then the output is  
   - [X] scenario   [the order of the arguments does not matter](../features/intersection.md) pass  

   ### Scenario: [the overlap is returned identically in both orders](../features/intersection.md): 
   - OK : Given the file `symmetric_overlap.topo`  
   - OK : When I successfully run `../bin/topocli run symmetric_overlap.topo`  
   - OK : Then the output is  
   - [X] scenario   [the overlap is returned identically in both orders](../features/intersection.md) pass  


# Document: [contours.md](../features/contours.md)  
   ### Scenario: [a continuous sequence of two segments](../features/contours.md): 
   - OK : Given the file `continuity_chain.topo`  
   - OK : When I successfully run `../bin/topocli run continuity_chain.topo`  
   - OK : Then the output is `continuity continuous`  
   - OK : And the file `../docs/features/images/contour_4.svg` contains `#1f6feb`    
   - [X] scenario   [a continuous sequence of two segments](../features/contours.md) pass  

   ### Scenario: [a discontinuous sequence](../features/contours.md): 
   - OK : Given the file `continuity_gap.topo`  
   - OK : When I successfully run `../bin/topocli run continuity_gap.topo`  
   - OK : Then the output is `continuity discontinuous`  
   - OK : And the file `../docs/features/images/contour_5.svg` contains `#1f6feb`    
   - [X] scenario   [a discontinuous sequence](../features/contours.md) pass  

   ### Scenario: [a single segment is trivially continuous](../features/contours.md): 
   - OK : Given the file `continuity_single.topo`  
   - OK : When I successfully run `../bin/topocli run continuity_single.topo`  
   - OK : Then the output is `continuity continuous`  
   - [X] scenario   [a single segment is trivially continuous](../features/contours.md) pass  

   ### Scenario: [an empty sequence is continuous](../features/contours.md): 
   - OK : Given the file `continuity_empty.topo`  
   - OK : When I successfully run `../bin/topocli run continuity_empty.topo`  
   - OK : Then the output is `continuity continuous`  
   - [X] scenario   [an empty sequence is continuous](../features/contours.md) pass  

   ### Scenario: [a closed loop (square)](../features/contours.md): 
   - OK : Given the file `closure_square.topo`  
   - OK : When I successfully run `../bin/topocli run closure_square.topo`  
   - OK : Then the output is `closure closed`  
   - OK : And the file `../docs/features/images/contour_1.svg` contains `#1f6feb`    
   - [X] scenario   [a closed loop (square)](../features/contours.md) pass  

   ### Scenario: [an open chain](../features/contours.md): 
   - OK : Given the file `closure_open.topo`  
   - OK : When I successfully run `../bin/topocli run closure_open.topo`  
   - OK : Then the output is `closure open`  
   - OK : And the file `../docs/features/images/contour_6.svg` contains `#1f6feb`    
   - [X] scenario   [an open chain](../features/contours.md) pass  

   ### Scenario: [closure with a repeated point](../features/contours.md): 
   - OK : Given the file `closure_repeat.topo`  
   - OK : When I successfully run `../bin/topocli run closure_repeat.topo`  
   - OK : Then the output is `closure closed`  
   - [X] scenario   [closure with a repeated point](../features/contours.md) pass  

   ### Scenario: [counter-clockwise square](../features/contours.md): 
   - OK : Given the file `orientation_ccw.topo`  
   - OK : When I successfully run `../bin/topocli run orientation_ccw.topo`  
   - OK : Then the output is `orientation counter_clockwise`  
   - [X] scenario   [counter-clockwise square](../features/contours.md) pass  

   ### Scenario: [clockwise square](../features/contours.md): 
   - OK : Given the file `orientation_cw.topo`  
   - OK : When I successfully run `../bin/topocli run orientation_cw.topo`  
   - OK : Then the output is `orientation clockwise`  
   - OK : And the file `../docs/features/images/contour_2.svg` contains `#1f6feb`    
   - [X] scenario   [clockwise square](../features/contours.md) pass  

   ### Scenario: [degenerate loop of zero area](../features/contours.md): 
   - OK : Given the file `orientation_bowtie.topo`  
   - OK : When I successfully run `../bin/topocli run orientation_bowtie.topo`  
   - OK : Then the output is `orientation degenerate`  
   - OK : And the file `../docs/features/images/contour_3.svg` contains `#1f6feb`    
   - [X] scenario   [degenerate loop of zero area](../features/contours.md) pass  

   ### Scenario: [counter-clockwise triangle](../features/contours.md): 
   - OK : Given the file `orientation_triangle.topo`  
   - OK : When I successfully run `../bin/topocli run orientation_triangle.topo`  
   - OK : Then the output is `orientation counter_clockwise`  
   - OK : And the file `../docs/features/images/contour_7.svg` contains `#1f6feb`    
   - [X] scenario   [counter-clockwise triangle](../features/contours.md) pass  

   ### Scenario: [orientation of a contour with a flat turn](../features/contours.md): 
   - OK : Given the file `orientation_flat.topo`  
   - OK : When I successfully run `../bin/topocli run orientation_flat.topo`  
   - OK : Then the output is `orientation counter_clockwise`  
   - OK : And the file `../docs/features/images/contour_13.svg` contains `#1f6feb`    
   - [X] scenario   [orientation of a contour with a flat turn](../features/contours.md) pass  

   ### Scenario: [a simple loop does not self-intersect](../features/contours.md): 
   - OK : Given the file `self_square.topo`  
   - OK : When I successfully run `../bin/topocli run self_square.topo`  
   - OK : Then the output is `false`  
   - [X] scenario   [a simple loop does not self-intersect](../features/contours.md) pass  

   ### Scenario: [a bowtie self-intersects](../features/contours.md): 
   - OK : Given the file `self_bowtie.topo`  
   - OK : When I successfully run `../bin/topocli run self_bowtie.topo`  
   - OK : Then the output is `true`  
   - [X] scenario   [a bowtie self-intersects](../features/contours.md) pass  

   ### Scenario: [three segments meeting at a point is not a self-intersection](../features/contours.md): 
   - OK : Given the file `self_junction.topo`  
   - OK : When I successfully run `../bin/topocli run self_junction.topo`  
   - OK : Then the output is `false`  
   - OK : And the file `../docs/features/images/contour_8.svg` contains `#1f6feb`    
   - [X] scenario   [three segments meeting at a point is not a self-intersection](../features/contours.md) pass  

   ### Scenario: [a single segment does not self-intersect](../features/contours.md): 
   - OK : Given the file `self_single.topo`  
   - OK : When I successfully run `../bin/topocli run self_single.topo`  
   - OK : Then the output is `false`  
   - [X] scenario   [a single segment does not self-intersect](../features/contours.md) pass  

   ### Scenario: [a valid contour (non-degenerate)](../features/contours.md): 
   - OK : Given the file `valid_square.topo`  
   - OK : When I successfully run `../bin/topocli run valid_square.topo`  
   - OK : Then the output is `true`  
   - [X] scenario   [a valid contour (non-degenerate)](../features/contours.md) pass  

   ### Scenario: [invalid due to degenerate segment](../features/contours.md): 
   - OK : Given the file `valid_degenerate.topo`  
   - OK : When I successfully run `../bin/topocli run valid_degenerate.topo`  
   - OK : Then the output is `false`  
   - OK : And the file `../docs/features/images/contour_9.svg` contains `#1f6feb`    
   - [X] scenario   [invalid due to degenerate segment](../features/contours.md) pass  

   ### Scenario: [valid with a flat turn](../features/contours.md): 
   - OK : Given the file `valid_flat.topo`  
   - OK : When I successfully run `../bin/topocli run valid_flat.topo`  
   - OK : Then the output is `true`  
   - OK : And the file `../docs/features/images/contour_10.svg` contains `#1f6feb`    
   - [X] scenario   [valid with a flat turn](../features/contours.md) pass  

   ### Scenario: [a contour with a flat turn is not reduced](../features/contours.md): 
   - OK : Given the file `flat_not_reduced.topo`  
   - OK : When I successfully run `../bin/topocli run flat_not_reduced.topo`  
   - OK : Then the output is `false`  
   - [X] scenario   [a contour with a flat turn is not reduced](../features/contours.md) pass  

   ### Scenario: [continuity at grid corners](../features/contours.md): 
   - OK : Given the file `continuity_extreme.topo`  
   - OK : When I successfully run `../bin/topocli run continuity_extreme.topo`  
   - OK : Then the output is `continuity continuous`  
   - OK : And the file `../docs/features/images/contour_11.svg` contains `#1f6feb`    
   - [X] scenario   [continuity at grid corners](../features/contours.md) pass  

   ### Scenario: [orientation of extreme loop](../features/contours.md): 
   - OK : Given the file `orientation_extreme.topo`  
   - OK : When I successfully run `../bin/topocli run orientation_extreme.topo`  
   - OK : Then the output is `orientation clockwise`  
   - OK : And the file `../docs/features/images/contour_12.svg` contains `#1f6feb`    
   - [X] scenario   [orientation of extreme loop](../features/contours.md) pass  


# Document: [vertices.md](../features/vertices.md)  
   ### Scenario: [create a vertex from a point](../features/vertices.md): 
   - OK : Given the file `create_vertex.topo`  
   - OK : When I successfully run `../bin/topocli run create_vertex.topo`  
   - OK : Then the output is `vertex 1 point 10 -20`  
   - OK : And the file `../docs/features/images/vertices_1.svg` contains `#1f6feb`    
   - [X] scenario   [create a vertex from a point](../features/vertices.md) pass  

   ### Scenario: [two vertices at the same point are distinct](../features/vertices.md): 
   - OK : Given the file `same_point_vertices.topo`  
   - OK : When I successfully run `../bin/topocli run same_point_vertices.topo`  
   - OK : Then the output is  
   - [X] scenario   [two vertices at the same point are distinct](../features/vertices.md) pass  

   ### Scenario: [vertices are numbered in creation order](../features/vertices.md): 
   - OK : Given the file `creation_order.topo`  
   - OK : When I successfully run `../bin/topocli run creation_order.topo`  
   - OK : Then the output is  
   - [X] scenario   [vertices are numbered in creation order](../features/vertices.md) pass  


# Document: [edges.md](../features/edges.md)  
   ### Scenario: [create an edge between two vertices](../features/edges.md): 
   - OK : Given the file `create_edge.topo`  
   - OK : When I successfully run `../bin/topocli run create_edge.topo`  
   - OK : Then the output is  
   - OK : And the file `../docs/features/images/edges_1.svg` contains `#1f6feb`    
   - [X] scenario   [create an edge between two vertices](../features/edges.md) pass  

   ### Scenario: [edges share vertices](../features/edges.md): 
   - OK : Given the file `shared_vertex.topo`  
   - OK : When I successfully run `../bin/topocli run shared_vertex.topo`  
   - OK : Then the output is  
   - OK : And the file `../docs/features/images/edges_2.svg` contains `#1f6feb`    
   - [X] scenario   [edges share vertices](../features/edges.md) pass  

   ### Scenario: [an edge between two vertices at the same point is valid](../features/edges.md): 
   - OK : Given the file `same_point_edge.topo`  
   - OK : When I successfully run `../bin/topocli run same_point_edge.topo`  
   - OK : Then the output is  
   - [X] scenario   [an edge between two vertices at the same point is valid](../features/edges.md) pass  

   ### Scenario: [an edge back to the same vertex is degenerate](../features/edges.md): 
   - OK : Given the file `degenerate_edge.topo`  
   - OK : When I run `../bin/topocli run degenerate_edge.topo`  
   - OK : Then the output is `vertex 1 point 1 2`  
   - OK : And the error output is `error: degenerate edge`  
   - OK : And the exit code is `1`  
   - [X] scenario   [an edge back to the same vertex is degenerate](../features/edges.md) pass  


# Document: [loops.md](../features/loops.md)  
   ### Scenario: [a triangle loop](../features/loops.md): 
   - OK : Given the file `triangle.topo`  
   - OK : When I successfully run `../bin/topocli run triangle.topo`  
   - OK : Then the output is `loop closed counter_clockwise`  
   - OK : And the file `../docs/features/images/loops_1.svg` contains `#1f6feb`    
   - [X] scenario   [a triangle loop](../features/loops.md) pass  

   ### Scenario: [a clockwise square](../features/loops.md): 
   - OK : Given the file `clockwise_square.topo`  
   - OK : When I successfully run `../bin/topocli run clockwise_square.topo`  
   - OK : Then the output is `loop closed clockwise`  
   - OK : And the file `../docs/features/images/loops_2.svg` contains `#1f6feb`    
   - [X] scenario   [a clockwise square](../features/loops.md) pass  

   ### Scenario: [a closed backtrack is a degenerate loop](../features/loops.md): 
   - OK : Given the file `backtrack.topo`  
   - OK : When I successfully run `../bin/topocli run backtrack.topo`  
   - OK : Then the output is `loop closed degenerate`  
   - [X] scenario   [a closed backtrack is a degenerate loop](../features/loops.md) pass  

   ### Scenario: [an open chain is rejected](../features/loops.md): 
   - OK : Given the file `open_chain.topo`  
   - OK : When I run `../bin/topocli run open_chain.topo`  
   - OK : Then the error output is `error: open loop`  
   - OK : And the exit code is `1`  
   - [X] scenario   [an open chain is rejected](../features/loops.md) pass  

   ### Scenario: [a degenerate edge support is rejected](../features/loops.md): 
   - OK : Given the file `degenerate_support.topo`  
   - OK : When I run `../bin/topocli run degenerate_support.topo`  
   - OK : Then the output is  
   - OK : And the error output is `error: degenerate edge support`  
   - OK : And the exit code is `1`  
   - [X] scenario   [a degenerate edge support is rejected](../features/loops.md) pass  


# Document: [faces.md](../features/faces.md)  
   ### Scenario: [a counter-clockwise face](../features/faces.md): 
   - OK : Given the file `face.topo`  
   - OK : When I successfully run `../bin/topocli run face.topo`  
   - OK : Then the output is `face counter_clockwise`  
   - OK : And the file `../docs/features/images/faces_1.svg` contains `#1f6feb`    
   - [X] scenario   [a counter-clockwise face](../features/faces.md) pass  

   ### Scenario: [a clockwise face](../features/faces.md): 
   - OK : Given the file `clockwise_face.topo`  
   - OK : When I successfully run `../bin/topocli run clockwise_face.topo`  
   - OK : Then the output is `face clockwise`  
   - OK : And the file `../docs/features/images/faces_2.svg` contains `#1f6feb`    
   - [X] scenario   [a clockwise face](../features/faces.md) pass  

   ### Scenario: [a degenerate boundary is rejected](../features/faces.md): 
   - OK : Given the file `degenerate_boundary.topo`  
   - OK : When I run `../bin/topocli run degenerate_boundary.topo`  
   - OK : Then the error output is `error: degenerate face boundary`  
   - OK : And the exit code is `1`  
   - [X] scenario   [a degenerate boundary is rejected](../features/faces.md) pass  


# Document: [faces3d.md](../features/faces3d.md)  
   ### Scenario: [a triangular face on a coordinate plane](../features/faces3d.md): 
   - OK : Given the file `triangular_face.topo`  
   - OK : When I successfully run `../bin/topocli run triangular_face.topo`  
   - OK : Then the output is  
   - OK : And the file `../docs/features/images/faces3d_1.svg` contains `#1a7f37`  
   - [X] scenario   [a triangular face on a coordinate plane](../features/faces3d.md) pass  

   ### Scenario: [an oblique face is planar too](../features/faces3d.md): 
   - OK : Given the file `oblique_face.topo`  
   - OK : When I successfully run `../bin/topocli run oblique_face.topo`  
   - OK : Then the output is  
   - OK : And the file `../docs/features/images/faces3d_2.svg` contains `#1a7f37`  
   - [X] scenario   [an oblique face is planar too](../features/faces3d.md) pass  

   ### Scenario: [a lifted vertex is rejected as non-planar](../features/faces3d.md): 
   - OK : Given the file `lifted_face.topo`  
   - OK : When I run `../bin/topocli run lifted_face.topo`  
   - OK : Then the error output is `error: non-planar face boundary`  
   - OK : And the exit code is `1`  
   - OK : And the file `../docs/features/images/faces3d_3.svg` contains `#cf222e`  
   - [X] scenario   [a lifted vertex is rejected as non-planar](../features/faces3d.md) pass  

   ### Scenario: [collinear support points carry no plane](../features/faces3d.md): 
   - OK : Given the file `collinear_face.topo`  
   - OK : When I run `../bin/topocli run collinear_face.topo`  
   - OK : Then the error output is `error: collinear face boundary`  
   - OK : And the exit code is `1`  
   - OK : And the file `../docs/features/images/faces3d_4.svg` contains `#1f6feb`  
   - [X] scenario   [collinear support points carry no plane](../features/faces3d.md) pass  

   ### Scenario: [a closed backtrack is never a face boundary](../features/faces3d.md): 
   - OK : Given the file `backtrack_face.topo`  
   - OK : When I run `../bin/topocli run backtrack_face.topo`  
   - OK : Then the error output is `error: collinear face boundary`  
   - OK : And the exit code is `1`  
   - [X] scenario   [a closed backtrack is never a face boundary](../features/faces3d.md) pass  

   ### Scenario: [an open chain is rejected](../features/faces3d.md): 
   - OK : Given the file `open_face.topo`  
   - OK : When I run `../bin/topocli run open_face.topo`  
   - OK : Then the error output is `error: open loop, vertex 2 is not linked back to vertex 1`  
   - OK : And the exit code is `1`  
   - OK : And the file `../docs/features/images/faces3d_5.svg` contains `#cf222e`  
   - [X] scenario   [an open chain is rejected](../features/faces3d.md) pass  


# Document: [shells.md](../features/shells.md)  
   ### Scenario: [a tetrahedron closes its shell](../features/shells.md): 
   - OK : Given the file `tetrahedron_shell.topo`  
   - OK : When I successfully run `../bin/topocli run tetrahedron_shell.topo`  
   - OK : Then the output is  
   - OK : And the file `../docs/features/images/shells_1.svg` contains `#cf222e`  
   - [X] scenario   [a tetrahedron closes its shell](../features/shells.md) pass  

   ### Scenario: [the box closes its shell](../features/shells.md): 
   - OK : Given the file `box_shell.topo`  
   - OK : When I successfully run `../bin/topocli run box_shell.topo`  
   - OK : Then the output is  
   - OK : And the file `../docs/features/images/shells_2.svg` contains `#cf222e`  
   - [X] scenario   [the box closes its shell](../features/shells.md) pass  

   ### Scenario: [a missing face leaves a free edge](../features/shells.md): 
   - OK : Given the file `missing_face_shell.topo`  
   - OK : When I run `../bin/topocli run missing_face_shell.topo`  
   - OK : Then the error output is `error: an edge has no opposite use (face 1)`  
   - OK : And the exit code is `1`  
   - [X] scenario   [a missing face leaves a free edge](../features/shells.md) pass  

   ### Scenario: [an inverted face pairs in the same direction](../features/shells.md): 
   - OK : Given the file `inverted_face_shell.topo`  
   - OK : When I run `../bin/topocli run inverted_face_shell.topo`  
   - OK : Then the error output is `error: an edge is used twice in the same direction (face 1)`  
   - OK : And the exit code is `1`  
   - [X] scenario   [an inverted face pairs in the same direction](../features/shells.md) pass  

   ### Scenario: [three faces on one edge are rejected](../features/shells.md): 
   - OK : Given the file `overused_edge_shell.topo`  
   - OK : When I run `../bin/topocli run overused_edge_shell.topo`  
   - OK : Then the error output is `error: an edge is used more than twice (face 1)`  
   - OK : And the exit code is `1`  
   - [X] scenario   [three faces on one edge are rejected](../features/shells.md) pass  


# Document: [toposcript.md](../features/toposcript.md)  
   ### Scenario: [an empty fragment executes silently](../features/toposcript.md): 
   - OK : Given the file `empty.topo`  
   - OK : When I successfully run `../bin/topocli run empty.topo`  
   - OK : Then there is no output  
   - [X] scenario   [an empty fragment executes silently](../features/toposcript.md) pass  

   ### Scenario: [a fragment of declarations only executes silently](../features/toposcript.md): 
   - OK : Given the file `declarations_only.topo`  
   - OK : When I successfully run `../bin/topocli run declarations_only.topo`  
   - OK : Then there is no output  
   - [X] scenario   [a fragment of declarations only executes silently](../features/toposcript.md) pass  

   ### Scenario: [a compilation diagnostic points at the declaration line](../features/toposcript.md): 
   - OK : Given the file `bad_declaration.topo`  
   - OK : When I run `../bin/topocli run bad_declaration.topo`  
   - OK : Then the error output is `bad_declaration.topo:1:29: error: undefined identifier: Q`  
   - OK : And the exit code is `1`  
   - [X] scenario   [a compilation diagnostic points at the declaration line](../features/toposcript.md) pass  

   ### Scenario: [a declaration split across several lines runs](../features/toposcript.md): 
   - OK : Given the file `split_declaration.topo`  
   - OK : When I successfully run `../bin/topocli run split_declaration.topo`  
   - OK : Then the output is `point 1 2 3`  
   - [X] scenario   [a declaration split across several lines runs](../features/toposcript.md) pass  

   ### Scenario: [a semicolon inside a string literal does not end a declaration](../features/toposcript.md): 
   - OK : Given the file `string_semicolon.topo`  
   - OK : When I successfully run `../bin/topocli run string_semicolon.topo`  
   - OK : Then the output is `;`  
   - [X] scenario   [a semicolon inside a string literal does not end a declaration](../features/toposcript.md) pass  

   ### Scenario: [a declaration form beyond the former subset runs](../features/toposcript.md): 
   - OK : Given the file `local_type.topo`  
   - OK : When I successfully run `../bin/topocli run local_type.topo`  
   - OK : Then there is no output  
   - [X] scenario   [a declaration form beyond the former subset runs](../features/toposcript.md) pass  

   ### Scenario: [a control structure runs through HAC](../features/toposcript.md): 
   - OK : Given the file `control.topo`  
   - OK : When I successfully run `../bin/topocli run control.topo`  
   - OK : Then the output is  
   - [X] scenario   [a control structure runs through HAC](../features/toposcript.md) pass  

   ### Scenario: [a local procedure body runs through HAC](../features/toposcript.md): 
   - OK : Given the file `local_procedure.topo`  
   - OK : When I successfully run `../bin/topocli run local_procedure.topo`  
   - OK : Then the output is `point 15 -13 21`  
   - [X] scenario   [a local procedure body runs through HAC](../features/toposcript.md) pass  

   ### Scenario: [two consecutive image sessions produce two images](../features/toposcript.md): 
   - OK : Given the file `two_images.topo`  
   - OK : When I successfully run `../bin/topocli run two_images.topo`  
   - OK : Then the file `../docs/features/images/toposcript_2.svg` contains `#1f6feb`    
   - OK : And the file `../docs/features/images/toposcript_3.svg` contains `#1a7f37`    
   - [X] scenario   [two consecutive image sessions produce two images](../features/toposcript.md) pass  

   ### Scenario: [End_Image without Begin_Image records the rejection](../features/toposcript.md): 
   - OK : Given the file `no_image.topo`  
   - OK : When I run `../bin/topocli run no_image.topo`  
   - OK : Then the error output is `error: no open image`  
   - OK : And the exit code is `1`  
   - [X] scenario   [End_Image without Begin_Image records the rejection](../features/toposcript.md) pass  

   ### Scenario: [a chain continues after a rejected operation, the first failure is retained](../features/toposcript.md): 
   - OK : Given the file `first_failure.topo`  
   - OK : When I run `../bin/topocli run first_failure.topo`  
   - OK : Then the output is `point 15 -13 21`  
   - OK : And the error output is `error: open loop`  
   - OK : And the exit code is `1`  
   - [X] scenario   [a chain continues after a rejected operation, the first failure is retained](../features/toposcript.md) pass  

   ### Scenario: [translate a point and a vector](../features/toposcript.md): 
   - OK : Given the file `translate.topo`  
   - OK : When I successfully run `../bin/topocli run translate.topo`  
   - OK : Then the output is `point 15 -13 21`  
   - [X] scenario   [translate a point and a vector](../features/toposcript.md) pass  

   ### Scenario: [reject an unrepresentable translation](../features/toposcript.md): 
   - OK : Given the file `translate_beyond.topo`  
   - OK : When I run `../bin/topocli run translate_beyond.topo`  
   - OK : Then the error output is `error: translation is not representable`  
   - OK : And the exit code is `1`  
   - [X] scenario   [reject an unrepresentable translation](../features/toposcript.md) pass  

   ### Scenario: [a declaration after the first statement is a HAC diagnostic](../features/toposcript.md): 
   - OK : Given the file `late_declaration.topo`  
   - OK : When I run `../bin/topocli run late_declaration.topo`  
   - OK : Then the error output is  
   - OK : And the exit code is `1`  
   - [X] scenario   [a declaration after the first statement is a HAC diagnostic](../features/toposcript.md) pass  

   ### Scenario: [draw the diagnostic image of the translation](../features/toposcript.md): 
   - OK : Given the file `translate_draw.topo`  
   - OK : When I successfully run `../bin/topocli run translate_draw.topo`  
   - OK : Then the output is `point 15 -13 21`  
   - OK : And the file `../docs/features/images/toposcript_1.svg` contains `#cf222e`    
   - [X] scenario   [draw the diagnostic image of the translation](../features/toposcript.md) pass  

   ### Scenario: [--output receives the canonical result of a script](../features/toposcript.md): 
   - OK : Given the file `translate_output.topo`  
   - OK : When I successfully run `../bin/topocli run translate_output.topo --output result.out`  
   - OK : Then there is no output  
   - OK : And the file `result.out` is `point 15 -13 21`  
   - [X] scenario   [--output receives the canonical result of a script](../features/toposcript.md) pass  

   ### Scenario: [an inline fragment runs without a file](../features/toposcript.md): 
   - OK : When I successfully run `../bin/topocli run_code "P : constant Point_3D := (10, -20, 30); D : constant Vector_3D := (5, 7, -9); Result : Point_3D; Translate (P, D, Result); Put (Result);"`  
   - OK : Then the output is `point 15 -13 21`  
   - [X] scenario   [an inline fragment runs without a file](../features/toposcript.md) pass  

   ### Scenario: [an inline rejection points at the inline line](../features/toposcript.md): 
   - OK : When I run `../bin/topocli run_code "P : constant Point_3D := (10, -20, 30); Put (P); Q : Point_3D;"`  
   - OK : Then the error output is  
   - OK : And the exit code is `1`  
   - [X] scenario   [an inline rejection points at the inline line](../features/toposcript.md) pass  

   ### Scenario: [an inline run writes to the output file](../features/toposcript.md): 
   - OK : When I successfully run `../bin/topocli run_code "A : constant Point_2D := (0, 0); B : constant Point_2D := (2, 0); K : Continuity_Kind; Add_Point (A); Add_Point (B); Add_Point (B); Add_Point (A); Contour_Continuity (K); Put_Continuity (K);" --output inline.out`  
   - OK : Then there is no output  
   - OK : And the file `inline.out` is `continuity continuous`  
   - [X] scenario   [an inline run writes to the output file](../features/toposcript.md) pass  


## Summary : **Success**, 115 scenarios OK

| Status     | Count |
|------------|-------|
| Failed     | 0     |
| Successful | 115   |
| Empty      | 0     |
| Not Run    | 0     |


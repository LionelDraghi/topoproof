
# Document: [command-line.md](../features/command-line.md)  
   ### Scenario: [display help](../features/command-line.md): 
   - OK : When I successfully run `../bin/topocli --help`  
   - OK : Then the output contains `usage: topocli`  
   - OK : And the output contains `operations: translate, displacement, equal, orientation, intersect`  
   - [X] scenario   [display help](../features/command-line.md) pass  

   ### Scenario: [--output receives the whole multi-line result](../features/command-line.md): 
   - OK : When I successfully run `../bin/topocli vertex A=(0, 0) B=(1, 1) C=(2, 3) --output vertices.out`  
   - OK : Then the file `vertices.out` is  
   - [X] scenario   [--output receives the whole multi-line result](../features/command-line.md) pass  

   ### Scenario: [inject parameters from an input file](../features/command-line.md): 
   - OK : Given the new file `displacement.in` containing `displacement A=(10, 20, 30) B=(13, 18, 37)`  
   - OK : When I successfully run `../bin/topocli --input displacement.in`  
   - OK : Then the output is `vector 3 -2 7`  
   - [X] scenario   [inject parameters from an input file](../features/command-line.md) pass  

   ### Scenario: [read and write files](../features/command-line.md): 
   - OK : Given the new file `displacement-file.in` containing `displacement A=(0, 0, 0) B=(-4, 5, -6)`  
   - OK : And there is no file `displacement-file.out`  
   - OK : When I successfully run `../bin/topocli --input displacement-file.in --output displacement-file.out`  
   - OK : Then the `displacement-file.out` file contains `vector -4 5 -6`  
   - [X] scenario   [read and write files](../features/command-line.md) pass  


# Document: [translation.md](../features/translation.md)  
   ### Scenario: [translate command-line values](../features/translation.md): 
   - OK : When I successfully run `../bin/topocli translate P=(10, -20, 30) D=(5, 7, -9) --draw ../docs/features/images/translation_1.svg`  
   - OK : Then the output is `point 15 -13 21`  
   - [X] scenario   [translate command-line values](../features/translation.md) pass  

   ### Scenario: [reject an unrepresentable result](../features/translation.md): 
   - OK : When I run `../bin/topocli translate P=(1073741823, 0, 0) D=(1, 0, 0) --draw ../docs/features/images/translation_2.svg`  
   - OK : Then the output is `error: translation is not representable`  
   - OK : And there is an error  
   - [X] scenario   [reject an unrepresentable result](../features/translation.md) pass  

   ### Scenario: [write the result to a file](../features/translation.md): 
   - OK : Given there is no file `translation.out`  
   - OK : When I successfully run `../bin/topocli translate P=(1, 2, 3) D=(4, 5, 6) --output translation.out`  
   - OK : Then the `translation.out` file contains `point 5 7 9`  
   - [X] scenario   [write the result to a file](../features/translation.md) pass  

   ### Scenario: [translation and displacement compose to the identity](../features/translation.md): 
   - OK : When I successfully run `../bin/topocli displacement A=(10, -20, 30) B=(15, -13, 21)`  
   - OK : Then the output is `vector 5 7 -9`  
   - OK : When I successfully run `../bin/topocli translate P=(10, -20, 30) D=(5, 7, -9) --draw ../docs/features/images/translation_1.svg`  
   - OK : Then the output is `point 15 -13 21`  
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
   - OK : When I successfully run `../bin/topocli orientation A=(0, 0) B=(1, 0) C=(1, 1) --draw ../docs/features/images/orientation_1.svg`  
   - OK : Then the output is `orientation counter_clockwise`  
   - [X] scenario   [a counter-clockwise path](../features/orientation.md) pass  

   ### Scenario: [a clockwise path](../features/orientation.md): 
   - OK : When I successfully run `../bin/topocli orientation A=(0, 0) B=(1, 0) C=(1, -1) --draw ../docs/features/images/orientation_3.svg`  
   - OK : Then the output is `orientation clockwise`  
   - [X] scenario   [a clockwise path](../features/orientation.md) pass  

   ### Scenario: [three aligned points are collinear](../features/orientation.md): 
   - OK : When I successfully run `../bin/topocli orientation A=(0, 0) B=(2, 2) C=(4, 4) --draw ../docs/features/images/orientation_4.svg`  
   - OK : Then the output is `orientation collinear`  
   - [X] scenario   [three aligned points are collinear](../features/orientation.md) pass  

   ### Scenario: [two coincident points make a degenerate collinear path](../features/orientation.md): 
   - OK : When I successfully run `../bin/topocli orientation A=(5, 7) B=(5, 7) C=(9, -3) --draw ../docs/features/images/orientation_5.svg`  
   - OK : Then the output is `orientation collinear`  
   - [X] scenario   [two coincident points make a degenerate collinear path](../features/orientation.md) pass  

   ### Scenario: [the extreme corners of the grid do not overflow](../features/orientation.md): 
   - OK : When I successfully run `../bin/topocli orientation A=(1073741823, 0) B=(0, 1073741823) C=(-1073741823, -1073741823) --draw ../docs/features/images/orientation_6.svg --draw-short-labels`  
   - OK : Then the output is `orientation counter_clockwise`  
   - [X] scenario   [the extreme corners of the grid do not overflow](../features/orientation.md) pass  

   ### Scenario: [a cyclic permutation keeps the orientation](../features/orientation.md): 
   - OK : When I successfully run `../bin/topocli orientation A=(0, 0) B=(1, 0) C=(1, 1) --draw ../docs/features/images/orientation_1.svg`  
   - OK : Then the output is `orientation counter_clockwise`  
   - OK : When I successfully run `../bin/topocli orientation A=(1, 0) B=(1, 1) C=(0, 0)`  
   - OK : Then the output is `orientation counter_clockwise`  
   - [X] scenario   [a cyclic permutation keeps the orientation](../features/orientation.md) pass  

   ### Scenario: [exchanging two points mirrors the orientation](../features/orientation.md): 
   - OK : When I successfully run `../bin/topocli orientation A=(0, 0) B=(1, 1) C=(1, 0) --draw ../docs/features/images/orientation_2.svg`  
   - OK : Then the output is `orientation clockwise`  
   - [X] scenario   [exchanging two points mirrors the orientation](../features/orientation.md) pass  

   ### Scenario: [the orientation is invariant under translation](../features/orientation.md): 
   - OK : When I successfully run `../bin/topocli orientation A=(0, 0) B=(1, 0) C=(1, 1) --draw ../docs/features/images/orientation_7.svg --draw-with E=(3,2)F=(4,2)G=(4,3)`  
   - OK : Then the output is `orientation counter_clockwise`  
   - OK : When I successfully run `../bin/topocli orientation A=(3, 2) B=(4, 2) C=(4, 3)`  
   - OK : Then the output is `orientation counter_clockwise`  
   - [X] scenario   [the orientation is invariant under translation](../features/orientation.md) pass  


# Document: [intersection.md](../features/intersection.md)  
   ### Scenario: [a proper crossing on a grid position](../features/intersection.md): 
   - OK : When I successfully run `../bin/topocli intersect A=(0, 0) B=(2, 2) C=(2, 0) D=(0, 2) --draw ../docs/features/images/intersection_1.svg`  
   - OK : Then the output is `intersection point_intersection 1 1`  
   - [X] scenario   [a proper crossing on a grid position](../features/intersection.md) pass  

   ### Scenario: [a proper crossing off the grid](../features/intersection.md): 
   - OK : When I successfully run `../bin/topocli intersect A=(0, 0) B=(1, 1) C=(0, 1) D=(1, 0) --draw ../docs/features/images/intersection_2.svg`  
   - OK : Then the output is `intersection off_grid_crossing`  
   - [X] scenario   [a proper crossing off the grid](../features/intersection.md) pass  

   ### Scenario: [collinear segments overlap](../features/intersection.md): 
   - OK : When I successfully run `../bin/topocli intersect A=(0, 0) B=(4, 0) C=(2, 0) D=(6, 0) --draw ../docs/features/images/intersection_3.svg`  
   - OK : Then the output is `intersection overlap 2 0 4 0`  
   - [X] scenario   [collinear segments overlap](../features/intersection.md) pass  

   ### Scenario: [collinear segments touch at one point](../features/intersection.md): 
   - OK : When I successfully run `../bin/topocli intersect A=(0, 0) B=(2, 0) C=(2, 0) D=(4, 0) --draw ../docs/features/images/intersection_4.svg`  
   - OK : Then the output is `intersection point_intersection 2 0`  
   - [X] scenario   [collinear segments touch at one point](../features/intersection.md) pass  

   ### Scenario: [collinear segments do not meet](../features/intersection.md): 
   - OK : When I successfully run `../bin/topocli intersect A=(0, 0) B=(1, 0) C=(2, 0) D=(3, 0) --draw ../docs/features/images/intersection_5.svg`  
   - OK : Then the output is `intersection no_intersection`  
   - [X] scenario   [collinear segments do not meet](../features/intersection.md) pass  

   ### Scenario: [an endpoint on the other segment](../features/intersection.md): 
   - OK : When I successfully run `../bin/topocli intersect A=(0, 0) B=(2, 0) C=(1, 0) D=(1, 1) --draw ../docs/features/images/intersection_6.svg`  
   - OK : Then the output is `intersection point_intersection 1 0`  
   - [X] scenario   [an endpoint on the other segment](../features/intersection.md) pass  

   ### Scenario: [a degenerate point segment on another segment](../features/intersection.md): 
   - OK : When I successfully run `../bin/topocli intersect A=(2, 1) A C=(0, 0) D=(4, 2) --draw ../docs/features/images/intersection_7.svg`  
   - OK : Then the output is `intersection point_intersection 2 1`  
   - [X] scenario   [a degenerate point segment on another segment](../features/intersection.md) pass  

   ### Scenario: [two identical degenerate point segments](../features/intersection.md): 
   - OK : When I successfully run `../bin/topocli intersect A=(1, 1) A B=(1, 1) B`  
   - OK : Then the output is `intersection point_intersection 1 1`  
   - [X] scenario   [two identical degenerate point segments](../features/intersection.md) pass  

   ### Scenario: [disjoint segments](../features/intersection.md): 
   - OK : When I successfully run `../bin/topocli intersect A=(0, 0) B=(1, 0) C=(0, 2) D=(1, 2)`  
   - OK : Then the output is `intersection no_intersection`  
   - [X] scenario   [disjoint segments](../features/intersection.md) pass  

   ### Scenario: [the grid corners do not overflow](../features/intersection.md): 
   - OK : When I successfully run `../bin/topocli intersect A=(0, -1073741823) B=(0, 1073741823) C=(-1073741823, 0) D=(1073741823, 0) --draw ../docs/features/images/intersection_8.svg --draw-short-labels`  
   - OK : Then the output is `intersection point_intersection 0 0`  
   - [X] scenario   [the grid corners do not overflow](../features/intersection.md) pass  

   ### Scenario: [the order of the arguments does not matter](../features/intersection.md): 
   - OK : When I successfully run `../bin/topocli intersect A=(0, 0) B=(2, 2) C=(2, 0) D=(0, 2) --draw ../docs/features/images/intersection_1.svg`  
   - OK : Then the output is `intersection point_intersection 1 1`  
   - OK : When I successfully run `../bin/topocli intersect A=(2, 0) B=(0, 2) C=(0, 0) D=(2, 2)`  
   - OK : Then the output is `intersection point_intersection 1 1`  
   - [X] scenario   [the order of the arguments does not matter](../features/intersection.md) pass  

   ### Scenario: [the overlap is returned identically in both orders](../features/intersection.md): 
   - OK : When I successfully run `../bin/topocli intersect A=(0, 0) B=(4, 0) C=(2, 0) D=(6, 0) --draw ../docs/features/images/intersection_3.svg`  
   - OK : Then the output is `intersection overlap 2 0 4 0`  
   - OK : When I successfully run `../bin/topocli intersect A=(2, 0) B=(6, 0) C=(0, 0) D=(4, 0)`  
   - OK : Then the output is `intersection overlap 2 0 4 0`  
   - [X] scenario   [the overlap is returned identically in both orders](../features/intersection.md) pass  


# Document: [contours.md](../features/contours.md)  
   ### Scenario: [a continuous sequence of two segments](../features/contours.md): 
   - OK : When I successfully run `../bin/topocli contour_continuity A=(0, 0) B=(1, 0) B C=(1, 1) --draw ../docs/features/images/contour_4.svg`  
   - OK : Then the output is `continuity continuous`  
   - [X] scenario   [a continuous sequence of two segments](../features/contours.md) pass  

   ### Scenario: [a discontinuous sequence](../features/contours.md): 
   - OK : When I successfully run `../bin/topocli contour_continuity A=(0, 0) B=(1, 0) C=(2, 1) D=(2, 2) --draw ../docs/features/images/contour_5.svg`  
   - OK : Then the output is `continuity discontinuous`  
   - [X] scenario   [a discontinuous sequence](../features/contours.md) pass  

   ### Scenario: [a single segment is trivially continuous](../features/contours.md): 
   - OK : When I successfully run `../bin/topocli contour_continuity A=(0, 0) B=(1, 1)`  
   - OK : Then the output is `continuity continuous`  
   - [X] scenario   [a single segment is trivially continuous](../features/contours.md) pass  

   ### Scenario: [an empty sequence is continuous](../features/contours.md): 
   - OK : When I successfully run `../bin/topocli contour_continuity`  
   - OK : Then the output is `continuity continuous`  
   - [X] scenario   [an empty sequence is continuous](../features/contours.md) pass  

   ### Scenario: [a closed loop (square)](../features/contours.md): 
   - OK : When I successfully run `../bin/topocli contour_closure A=(0, 0) B=(2, 0) C=(2, 2) D=(0, 2) A --draw ../docs/features/images/contour_1.svg`  
   - OK : Then the output is `closure closed`  
   - [X] scenario   [a closed loop (square)](../features/contours.md) pass  

   ### Scenario: [an open chain](../features/contours.md): 
   - OK : When I successfully run `../bin/topocli contour_closure A=(0, 0) B=(1, 0) C=(1, 1) --draw ../docs/features/images/contour_6.svg`  
   - OK : Then the output is `closure open`  
   - [X] scenario   [an open chain](../features/contours.md) pass  

   ### Scenario: [closure with a repeated point](../features/contours.md): 
   - OK : When I successfully run `../bin/topocli contour_closure A=(5, 5) A`  
   - OK : Then the output is `closure closed`  
   - [X] scenario   [closure with a repeated point](../features/contours.md) pass  

   ### Scenario: [counter-clockwise square](../features/contours.md): 
   - OK : When I successfully run `../bin/topocli contour_orientation A=(0, 0) B=(2, 0) C=(2, 2) D=(0, 2) A --draw ../docs/features/images/contour_1.svg`  
   - OK : Then the output is `orientation counter_clockwise`  
   - [X] scenario   [counter-clockwise square](../features/contours.md) pass  

   ### Scenario: [clockwise square](../features/contours.md): 
   - OK : When I successfully run `../bin/topocli contour_orientation A=(0, 0) B=(0, 2) C=(2, 2) D=(2, 0) A --draw ../docs/features/images/contour_2.svg`  
   - OK : Then the output is `orientation clockwise`  
   - [X] scenario   [clockwise square](../features/contours.md) pass  

   ### Scenario: [degenerate loop of zero area](../features/contours.md): 
   - OK : When I successfully run `../bin/topocli contour_orientation A=(0, 0) B=(2, 2) C=(2, 0) D=(0, 2) A --draw ../docs/features/images/contour_3.svg`  
   - OK : Then the output is `orientation degenerate`  
   - [X] scenario   [degenerate loop of zero area](../features/contours.md) pass  

   ### Scenario: [counter-clockwise triangle](../features/contours.md): 
   - OK : When I successfully run `../bin/topocli contour_orientation A=(0, 0) B=(2, 0) C=(1, 2) A --draw ../docs/features/images/contour_7.svg`  
   - OK : Then the output is `orientation counter_clockwise`  
   - [X] scenario   [counter-clockwise triangle](../features/contours.md) pass  

   ### Scenario: [orientation of a contour with a flat turn](../features/contours.md): 
   - OK : When I successfully run `../bin/topocli contour_orientation A=(0, 0) B=(1, 0) C=(2, 0) D=(2, 2) E=(0, 2) A --draw ../docs/features/images/contour_13.svg`  
   - OK : Then the output is `orientation counter_clockwise`  
   - [X] scenario   [orientation of a contour with a flat turn](../features/contours.md) pass  

   ### Scenario: [a simple loop does not self-intersect](../features/contours.md): 
   - OK : When I successfully run `../bin/topocli contour_self_intersects A=(0, 0) B=(2, 0) C=(2, 2) D=(0, 2) A --draw ../docs/features/images/contour_1.svg`  
   - OK : Then the output is `false`  
   - [X] scenario   [a simple loop does not self-intersect](../features/contours.md) pass  

   ### Scenario: [a bowtie self-intersects](../features/contours.md): 
   - OK : When I successfully run `../bin/topocli contour_self_intersects A=(0, 0) B=(2, 2) C=(2, 0) D=(0, 2) A --draw ../docs/features/images/contour_3.svg`  
   - OK : Then the output is `true`  
   - [X] scenario   [a bowtie self-intersects](../features/contours.md) pass  

   ### Scenario: [three segments meeting at a point is not a self-intersection](../features/contours.md): 
   - OK : When I successfully run `../bin/topocli contour_self_intersects A=(0, 0) B=(1, 0) C=(1, 1) B --draw ../docs/features/images/contour_8.svg`  
   - OK : Then the output is `false`  
   - [X] scenario   [three segments meeting at a point is not a self-intersection](../features/contours.md) pass  

   ### Scenario: [a single segment does not self-intersect](../features/contours.md): 
   - OK : When I successfully run `../bin/topocli contour_self_intersects A=(0, 0) B=(1, 1)`  
   - OK : Then the output is `false`  
   - [X] scenario   [a single segment does not self-intersect](../features/contours.md) pass  

   ### Scenario: [a valid contour (non-degenerate)](../features/contours.md): 
   - OK : When I successfully run `../bin/topocli contour_valid A=(0, 0) B=(2, 0) C=(2, 2) D=(0, 2) A --draw ../docs/features/images/contour_1.svg`  
   - OK : Then the output is `true`  
   - [X] scenario   [a valid contour (non-degenerate)](../features/contours.md) pass  

   ### Scenario: [invalid due to degenerate segment](../features/contours.md): 
   - OK : When I successfully run `../bin/topocli contour_valid A=(0, 0) A B=(1, 0) A --draw ../docs/features/images/contour_9.svg`  
   - OK : Then the output is `false`  
   - [X] scenario   [invalid due to degenerate segment](../features/contours.md) pass  

   ### Scenario: [valid with a flat turn](../features/contours.md): 
   - OK : When I successfully run `../bin/topocli contour_valid A=(0, 0) B=(1, 0) C=(2, 0) A --draw ../docs/features/images/contour_10.svg`  
   - OK : Then the output is `true`  
   - [X] scenario   [valid with a flat turn](../features/contours.md) pass  

   ### Scenario: [a contour with a flat turn is not reduced](../features/contours.md): 
   - OK : When I successfully run `../bin/topocli contour_no_flat_turns A=(0, 0) B=(1, 0) C=(2, 0) A`  
   - OK : Then the output is `false`  
   - [X] scenario   [a contour with a flat turn is not reduced](../features/contours.md) pass  

   ### Scenario: [continuity at grid corners](../features/contours.md): 
   - OK : When I successfully run `../bin/topocli contour_continuity A=(1073741823, 1073741823) B=(-1073741823, -1073741823) B C=(1073741823, 1073741823) --draw ../docs/features/images/contour_11.svg --draw-short-labels`  
   - OK : Then the output is `continuity continuous`  
   - [X] scenario   [continuity at grid corners](../features/contours.md) pass  

   ### Scenario: [orientation of extreme loop](../features/contours.md): 
   - OK : When I successfully run `../bin/topocli contour_orientation A=(1073741823, 1073741823) B=(1073741823, -1073741823) C=(-1073741823, -1073741823) D=(-1073741823, 1073741823) A --draw ../docs/features/images/contour_12.svg --draw-short-labels`  
   - OK : Then the output is `orientation clockwise`  
   - [X] scenario   [orientation of extreme loop](../features/contours.md) pass  


# Document: [vertices.md](../features/vertices.md)  
   ### Scenario: [create a vertex from a point](../features/vertices.md): 
   - OK : When I successfully run `../bin/topocli vertex A=(10, -20) --draw ../docs/features/images/vertices_1.svg`  
   - OK : Then the output is `vertex 1 point 10 -20`  
   - [X] scenario   [create a vertex from a point](../features/vertices.md) pass  

   ### Scenario: [two vertices at the same point are distinct](../features/vertices.md): 
   - OK : When I successfully run `../bin/topocli vertex A=(1, 2) B=(1, 2)`  
   - OK : Then the output is  
   - [X] scenario   [two vertices at the same point are distinct](../features/vertices.md) pass  

   ### Scenario: [vertices are numbered in creation order](../features/vertices.md): 
   - OK : When I successfully run `../bin/topocli vertex A=(0, 0) B=(5, 5) C=(-5, 3)`  
   - OK : Then the output is  
   - [X] scenario   [vertices are numbered in creation order](../features/vertices.md) pass  

   ### Scenario: [a planar vertex needs a 2D point](../features/vertices.md): 
   - OK : When I run `../bin/topocli vertex A=(1, 2, 3)`  
   - OK : Then there is an error  
   - [X] scenario   [a planar vertex needs a 2D point](../features/vertices.md) pass  


# Document: [edges.md](../features/edges.md)  
   ### Scenario: [create an edge between two vertices](../features/edges.md): 
   - OK : When I successfully run `../bin/topocli edge A=(0, 0) B=(5, 5) --draw ../docs/features/images/edges_1.svg`  
   - OK : Then the output is  
   - [X] scenario   [create an edge between two vertices](../features/edges.md) pass  

   ### Scenario: [edges share vertices](../features/edges.md): 
   - OK : When I successfully run `../bin/topocli edge A=(0, 0) B=(5, 5) C=(0, 5) B --draw ../docs/features/images/edges_2.svg`  
   - OK : Then the output is  
   - [X] scenario   [edges share vertices](../features/edges.md) pass  

   ### Scenario: [an edge between two vertices at the same point is valid](../features/edges.md): 
   - OK : When I successfully run `../bin/topocli edge A=(1, 2) B=(1, 2)`  
   - OK : Then the output is  
   - [X] scenario   [an edge between two vertices at the same point is valid](../features/edges.md) pass  

   ### Scenario: [an edge back to the same vertex is degenerate](../features/edges.md): 
   - OK : When I run `../bin/topocli edge A=(1, 2) A`  
   - OK : Then the output is  
   - OK : And there is an error  
   - [X] scenario   [an edge back to the same vertex is degenerate](../features/edges.md) pass  

   ### Scenario: [an odd number of points is not a chain of pairs](../features/edges.md): 
   - OK : When I run `../bin/topocli edge A=(1, 2)`  
   - OK : Then there is an error  
   - [X] scenario   [an odd number of points is not a chain of pairs](../features/edges.md) pass  


# Document: [loops.md](../features/loops.md)  
   ### Scenario: [a triangle loop](../features/loops.md): 
   - OK : When I successfully run `../bin/topocli loop A=(0, 0) B=(5, 5) C=(0, 5) A --draw ../docs/features/images/loops_1.svg`  
   - OK : Then the output is  
   - [X] scenario   [a triangle loop](../features/loops.md) pass  

   ### Scenario: [a triangle loop built by script](../features/loops.md): 
   - OK : Given the file `triangle.topo`  
   - OK : When I successfully run `../bin/topocli run triangle.topo`  
   - OK : Then the output is `loop closed counter_clockwise`  
   - OK : And the file `../docs/features/images/loops_1_script.svg` contains `(5, 5)`  
   - [X] scenario   [a triangle loop built by script](../features/loops.md) pass  

   ### Scenario: [a clockwise square](../features/loops.md): 
   - OK : When I successfully run `../bin/topocli loop A=(0, 0) B=(0, 5) C=(5, 5) D=(5, 0) A --draw ../docs/features/images/loops_2.svg`  
   - OK : Then the output is  
   - [X] scenario   [a clockwise square](../features/loops.md) pass  

   ### Scenario: [a closed backtrack is a degenerate loop](../features/loops.md): 
   - OK : When I successfully run `../bin/topocli loop A=(0, 0) B=(5, 5) A`  
   - OK : Then the output is  
   - [X] scenario   [a closed backtrack is a degenerate loop](../features/loops.md) pass  

   ### Scenario: [an open chain is rejected](../features/loops.md): 
   - OK : When I run `../bin/topocli loop A=(0, 0) B=(5, 5) C=(0, 5)`  
   - OK : Then the output is  
   - OK : And there is an error  
   - [X] scenario   [an open chain is rejected](../features/loops.md) pass  

   ### Scenario: [a degenerate edge support is rejected](../features/loops.md): 
   - OK : When I run `../bin/topocli loop A=(1, 2) B=(1, 2) A`  
   - OK : Then the output is  
   - OK : And there is an error  
   - [X] scenario   [a degenerate edge support is rejected](../features/loops.md) pass  


# Document: [faces.md](../features/faces.md)  
   ### Scenario: [a counter-clockwise face](../features/faces.md): 
   - OK : When I successfully run `../bin/topocli face A=(0, 0) B=(5, 5) C=(0, 5) A --draw ../docs/features/images/faces_1.svg`  
   - OK : Then the output is  
   - [X] scenario   [a counter-clockwise face](../features/faces.md) pass  

   ### Scenario: [a counter-clockwise face built by script](../features/faces.md): 
   - OK : Given the file `face.topo`  
   - OK : When I successfully run `../bin/topocli run face.topo`  
   - OK : Then the output is `face counter_clockwise`  
   - OK : And the file `../docs/features/images/faces_1_script.svg` contains `(5, 5)`  
   - [X] scenario   [a counter-clockwise face built by script](../features/faces.md) pass  

   ### Scenario: [a clockwise face](../features/faces.md): 
   - OK : When I successfully run `../bin/topocli face A=(0, 0) B=(0, 5) C=(5, 5) D=(5, 0) A --draw ../docs/features/images/faces_2.svg`  
   - OK : Then the output is  
   - [X] scenario   [a clockwise face](../features/faces.md) pass  

   ### Scenario: [a degenerate boundary is rejected](../features/faces.md): 
   - OK : When I run `../bin/topocli face A=(0, 0) B=(5, 5) A`  
   - OK : Then the output is  
   - OK : And there is an error  
   - [X] scenario   [a degenerate boundary is rejected](../features/faces.md) pass  


# Document: [toposcript.md](../features/toposcript.md)  
   ### Scenario: [an empty fragment executes silently](../features/toposcript.md): 
   - OK : Given the file `empty.topo`  
   - OK : When I successfully run `../bin/topocli run empty.topo`  
   - OK : Then the output is  
   - [X] scenario   [an empty fragment executes silently](../features/toposcript.md) pass  

   ### Scenario: [a fragment of declarations only executes silently](../features/toposcript.md): 
   - OK : Given the file `declarations_only.topo`  
   - OK : When I successfully run `../bin/topocli run declarations_only.topo`  
   - OK : Then the output is  
   - [X] scenario   [a fragment of declarations only executes silently](../features/toposcript.md) pass  

   ### Scenario: [a compilation diagnostic points at the declaration line](../features/toposcript.md): 
   - OK : Given the file `bad_declaration.topo`  
   - OK : When I run `../bin/topocli run bad_declaration.topo`  
   - OK : Then the error output contains `bad_declaration.topo:1:`  
   - OK : And there is an error  
   - [X] scenario   [a compilation diagnostic points at the declaration line](../features/toposcript.md) pass  

   ### Scenario: [a declaration split across several lines is rejected cleanly](../features/toposcript.md): 
   - OK : Given the file `split_declaration.topo`  
   - OK : When I run `../bin/topocli run split_declaration.topo`  
   - OK : Then the error output is  
   - OK : And there is an error  
   - [X] scenario   [a declaration split across several lines is rejected cleanly](../features/toposcript.md) pass  

   ### Scenario: [a declaration form outside the subset is rejected before compilation](../features/toposcript.md): 
   - OK : Given the file `out_of_subset.topo`  
   - OK : When I run `../bin/topocli run out_of_subset.topo`  
   - OK : Then the error output is  
   - OK : And there is an error  
   - [X] scenario   [a declaration form outside the subset is rejected before compilation](../features/toposcript.md) pass  

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
   - OK : And there is an error  
   - [X] scenario   [End_Image without Begin_Image records the rejection](../features/toposcript.md) pass  

   ### Scenario: [a chain continues after a rejected operation, the first failure is retained](../features/toposcript.md): 
   - OK : Given the file `first_failure.topo`  
   - OK : When I run `../bin/topocli run first_failure.topo`  
   - OK : Then the output is `point 15 -13 21`  
   - OK : And the error output is `error: open loop`  
   - OK : And there is an error  
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
   - OK : And there is an error  
   - [X] scenario   [reject an unrepresentable translation](../features/toposcript.md) pass  

   ### Scenario: [reject a declaration after the first statement](../features/toposcript.md): 
   - OK : Given the file `late_declaration.topo`  
   - OK : When I run `../bin/topocli run late_declaration.topo`  
   - OK : Then the error output is  
   - OK : And there is an error  
   - [X] scenario   [reject a declaration after the first statement](../features/toposcript.md) pass  

   ### Scenario: [draw the diagnostic image of the translation](../features/toposcript.md): 
   - OK : Given the file `translate_draw.topo`  
   - OK : When I successfully run `../bin/topocli run translate_draw.topo`  
   - OK : Then the output is `point 15 -13 21`  
   - OK : And the file `../docs/features/images/toposcript_1.svg` contains `#cf222e`    
   - [X] scenario   [draw the diagnostic image of the translation](../features/toposcript.md) pass  

   ### Scenario: [--output receives the canonical result of a script](../features/toposcript.md): 
   - OK : Given the file `translate_output.topo`  
   - OK : When I successfully run `../bin/topocli run translate_output.topo --output result.out`  
   - OK : Then the output is  
   - OK : And the file `result.out` is `point 15 -13 21`  
   - [X] scenario   [--output receives the canonical result of a script](../features/toposcript.md) pass  


## Summary : **Success**, 87 scenarios OK

| Status     | Count |
|------------|-------|
| Failed     | 0     |
| Successful | 87    |
| Empty      | 0     |
| Not Run    | 0     |


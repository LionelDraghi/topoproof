# TopoProof terminology <!-- omit from toc -->

This document defines the project's vocabulary. Terms used by the public API are normative once marked as such; others remain provisional or research-oriented.

- [Normative for milestone 1](#normative-for-milestone-1)
  - [`Grid_Coordinate`](#grid_coordinate)
  - [`Vector_Component`](#vector_component)
  - [`Point_3D`](#point_3d)
  - [`Vector_3D`](#vector_3d)
  - [`Displacement`](#displacement)
  - [`Translate`](#translate)
  - [`Translation_Is_Representable`](#translation_is_representable)
  - [Exact geometric equality](#exact-geometric-equality)
- [Normative for milestone 2](#normative-for-milestone-2)
  - [`Point_2D`](#point_2d)
  - [`Orientation`](#orientation)
  - [`Orientation_Kind`](#orientation_kind)
  - [Exact collinearity](#exact-collinearity)
  - [2D translation](#2d-translation)
- [Normative for milestone 3](#normative-for-milestone-3)
  - [`Segment_2D`](#segment_2d)
  - [Exact point-on-segment](#exact-point-on-segment)
  - [`Intersection`](#intersection)
  - [`Off_Grid_Crossing`](#off_grid_crossing)
- [Normative for milestone 4](#normative-for-milestone-4)
  - [`Segment_Sequence_2D`](#segment_sequence_2d)
  - [Closed sequence](#closed-sequence)
  - [Validity](#validity)
  - [Flat turn](#flat-turn)
  - [Signed area](#signed-area)
  - [Contour orientation](#contour-orientation)
- [Normative for milestone 5](#normative-for-milestone-5)
  - [`Vertex`](#vertex)
  - [`Vertex_Handle`](#vertex_handle)
  - [`Vertex_Store`](#vertex_store)
  - [`Create`](#create)
  - [`Edge`](#edge)
  - [`Edge_Handle`](#edge_handle)
  - [`Edge_Store`](#edge_store)
  - [`Loop_2D`](#loop_2d)
  - [`Loop_Validity`](#loop_validity)
  - [Loop orientation](#loop-orientation)
  - [`Face_2D`](#face_2d)
  - [`Face_Validity`](#face_validity)
  - [Face orientation](#face-orientation)
- [Normative for milestone 7](#normative-for-milestone-7)
  - [`Dot_Product`](#dot_product)
  - [`Cross_Product`](#cross_product)
  - [`Cross_Vector_3D`](#cross_vector_3d)
  - [`Plane`](#plane)
  - [`Plane_Side`](#plane_side)
  - [`Normal`](#normal)
- [Provisional geometric terms](#provisional-geometric-terms)
  - [`Grid_Quantum`](#grid_quantum)
  - [`Grid_Unit`](#grid_unit)
  - [`Length`](#length)
  - [Geometric predicate](#geometric-predicate)
- [Provisional topological terms](#provisional-topological-terms)
  - [B-Rep](#b-rep)
- [Open decisions](#open-decisions)

## Contents <!-- omit from toc -->

- [Normative for milestone 1](#normative-for-milestone-1)
  - [Grid_Coordinate](#grid_coordinate)
  - [Vector_Component](#vector_component)
  - [Point_3D](#point_3d)
  - [Vector_3D](#vector_3d)
  - [Displacement](#displacement)
  - [Translate](#translate)
  - [Translation_Is_Representable](#translation_is_representable)
  - [Exact geometric equality](#exact-geometric-equality)
- [Normative for milestone 2](#normative-for-milestone-2)
  - [Point_2D](#point_2d)
  - [Orientation](#orientation)
  - [Orientation_Kind](#orientation_kind)
  - [Exact collinearity](#exact-collinearity)
  - [2D translation](#2d-translation)
- [Normative for milestone 3](#normative-for-milestone-3)
  - [Segment_2D](#segment_2d)
  - [Exact point-on-segment](#exact-point-on-segment)
  - [Intersection](#intersection)
  - [Off_Grid_Crossing](#off_grid_crossing)
- [Normative for milestone 4](#normative-for-milestone-4)
  - [Segment_Sequence_2D](#segment_sequence_2d)
  - [Closed sequence](#closed-sequence)
  - [Validity](#validity)
  - [Flat turn](#flat-turn)
  - [Signed area](#signed-area)
  - [Contour orientation](#contour-orientation)
- [Normative for milestone 5](#normative-for-milestone-5)
  - [Vertex](#vertex)
  - [Vertex_Handle](#vertex_handle)
  - [Vertex_Store](#vertex_store)
  - [Create](#create)
  - [Edge](#edge)
  - [Edge_Handle](#edge_handle)
  - [Edge_Store](#edge_store)
  - [Loop_2D](#loop_2d)
  - [Loop_Validity](#loop_validity)
  - [Loop orientation](#loop-orientation)
  - [Face_2D](#face_2d)
  - [Face_Validity](#face_validity)
  - [Face orientation](#face-orientation)
- [Normative for milestone 7](#normative-for-milestone-7)
  - [Dot_Product](#dot_product)
  - [Cross_Product](#cross_product)
  - [Cross_Vector_3D](#cross_vector_3d)
  - [Plane](#plane)
  - [Plane_Side](#plane_side)
  - [Normal](#normal)
- [Provisional geometric terms](#provisional-geometric-terms)
  - [Grid_Quantum](#grid_quantum)
  - [Grid_Unit](#grid_unit)
  - [Length](#length)
  - [Geometric predicate](#geometric-predicate)
- [Provisional topological terms](#provisional-topological-terms)
  - [B-Rep](#b-rep)
- [Open decisions](#open-decisions)

## Normative for milestone 1

### `Grid_Coordinate`

A signed integer position on one axis of the discrete grid. It represents a position, not a length, carries no tolerance, and belongs to the domain defined by the numeric model.

### `Vector_Component`

A signed displacement on one axis. Its domain must represent the difference between any two valid coordinates required by the current milestone.

### `Point_3D`

An absolute position with three `Grid_Coordinate` components. Two points are equal exactly when all three components are equal. A point is not a vector and is not a topological vertex.

### `Vector_3D`

An oriented displacement with three `Vector_Component` values.

Dimensionally valid operations are:

```text
Point - Point   = Vector
Point + Vector  = Point
Vector + Vector = Vector
Vector - Vector = Vector
```

`Point + Point` is not defined.

### `Displacement`

The vector from point `A` to point `B`:

```text
Displacement (A, B) = B - A
```

### `Translate`

Applies a vector to a point and returns a point. The operation is defined only when each resulting coordinate is representable.

### `Translation_Is_Representable`

States whether all exact component additions performed by `Translate` belong to `Grid_Coordinate`. The check must not itself overflow.

### Exact geometric equality

Represented points are equal by component-wise integer equality. `Almost_Equal` is not used for points already placed on the grid.

## Normative for milestone 2

### `Point_2D`

An absolute position with two `Grid_Coordinate` components, in the same grid as `Point_3D`. Two points are equal exactly when both components are equal. A point is not a vector and is not a topological vertex.

### `Orientation`

Classification of the path `A -> B -> C` as counter-clockwise, clockwise or collinear, decided exactly by the sign of the determinant
`(B.X - A.X) * (C.Y - A.Y) - (B.Y - A.Y) * (C.X - A.X)`. There is no tolerance and no angle computation.

### `Orientation_Kind`

The result type of `Orientation`: `Counter_Clockwise`, `Clockwise`, or `Collinear`.

### Exact collinearity

Three points are collinear exactly when the orientation determinant is zero. Two coincident points among the three make the path degenerate, hence collinear.

### 2D translation

`Translate_2D` applies two vector components to a `Point_2D` when the results are representable, exactly as `Translate` does for `Point_3D`. It is used to state and prove the invariance of `Orientation` under translation.

## Normative for milestone 3

### `Segment_2D`

An oriented pair of 2D endpoints. A segment is a geometric value, not the topological `Edge`. A segment is degenerate when both endpoints coincide.

### Exact point-on-segment

A point is on a segment exactly when it is collinear with both endpoints and inside their bounding box on both axes. No tolerance and no neighbourhood are involved.

### `Intersection`

The exact classification of two segments as sharing no grid position, exactly one grid position, a crossing at a point that is not a grid position, or a collinear sub-segment. The result data, when present, belongs to both segments, and does not depend on the order of the arguments.

### `Off_Grid_Crossing`

A properly crossing pair of segments whose crossing point is not a grid position. The discrete model states this case exactly instead of snapping the crossing to a nearby grid position: on the grid, positions that do not exist are not fabricated.

## Normative for milestone 4

### `Segment_Sequence_2D`

An ordered list of `Point_2D` values in which consecutive points define the segments of a polygonal chain. Storing points instead of duplicated endpoints makes continuity structural.

### Closed sequence

A segment sequence whose first and last points coincide. A closed sequence is the geometric candidate for a loop.

### Validity

A segment sequence is valid when no segment is degenerate. Validity is geometric: an intermediate collinear point never invalidates a sequence, because the chain describes the same geometry with or without it.

### Flat turn

Three consecutive collinear points: the chain has no well-defined turning direction at the middle point. The absence of flat turns is a canonical-representation property, observable with `Has_No_Flat_Turns`, and is not a validity rule (decision DD-001).

### Signed area

Twice the area enclosed by a closed sequence, by the shoelace formula: the exact integer sum of the cross determinants of the consecutive position vectors, including the closing term. Only the sign classifies the orientation; the exact value stays available.

### Contour orientation

The classification of a closed, valid sequence as counter-clockwise, clockwise or degenerate, by the sign of its signed area. The orientation is a property of the closed chain itself: it is invariant under rotation of the starting vertex, and mirrored by reversal of the traversal direction.

## Normative for milestone 5

### `Vertex`

A topological entity with its own identity, referring to exactly one geometric point. A vertex is not a point: a point is a geometric value without identity, and two vertices may carry the same point and remain distinct. Identity is not position (DD-002): no operation merges vertices, and merging remains an open question.

### `Vertex_Handle`

The identity of one stored vertex: the only way to designate a vertex. A handle is valid only in the `Vertex_Store` it comes from, and valid in a store exactly when the store contains it. Handles are compared for equality only, never added or multiplied.

### `Vertex_Store`

A store of vertices with a declared capacity. Stored vertices are never removed, so the stored vertices are exactly the handles `1 .. Count`, and the invariant "every vertex references a valid point" is structural: the stored points are `Point_2D` values. The capacity is a discriminant without a default value: a store object occupies only its declared capacity, and the capacity is frozen for the whole object lifetime, so no assignment can invalidate handles. The type predicate guarantees `Count <= Capacity`.

### `Create`

Creates one vertex referring to a given point and returns its handle. Creation allocates the next handle and never merges with an existing vertex at the same point, so every previously stored vertex keeps its handle and its point: reference validity is preserved by construction.

### `Edge`

An oriented topological entity connecting two distinct vertices, by handles. An edge refers to its endpoints, never to positions: geometry is reached only through the vertex store. Degeneracy is topological: creation rejects only an edge whose two ends are the same vertex; an edge between two distinct vertices at the same point is a valid edge, and the geometric degeneracy of its support is judged at loop level (DD-002).

### `Edge_Handle`

The identity of one stored edge: valid only in the `Edge_Store` it comes from, and valid in a store exactly when the store contains it. Like vertex handles, edge handles are compared for equality only.

### `Edge_Store`

A store of edges with a declared capacity, with the same discipline as `Vertex_Store`: the capacity is a discriminant without a default value, so an object occupies only its declared capacity, and the capacity is frozen for the object lifetime. The type predicate guarantees `Count <= Capacity`, and that every stored edge connects two distinct vertices. Edge endpoints are vertex handles that must exist in the vertex store at creation; since stored vertices are never removed, endpoints stay valid for the whole lifetime of both stores.

### `Loop_2D`

An oriented loop: an ordered chain of connected edges that returns to its starting vertex. `loop` is an Ada reserved word, so the type is named `Loop_2D`. A loop is a value, not a stored entity: it has no handle, and its validity is relative to the edge and vertex stores its edges come from. A valid loop contains no orphan edge, every endpoint exists in the vertex store, consecutive edges are connected, the chain closes on its starting vertex, and no edge support is reduced to a point: the geometric degeneracy is judged at loop level (DD-002, decisions 3 and 6). A closed two-edge backtrack is a valid loop of degenerate orientation, and is never a valid face boundary.

### `Loop_Validity`

The exact classification of an edge chain as a valid loop, or as rejected for its first violated property, decided in a fixed order without tolerance: orphan edge, missing endpoint, open chain, disconnected chain, degenerate support. `Make_Loop` builds a loop only from a chain classifying as valid, so invalid loops cannot be obtained from the public API.

### Loop orientation

The orientation of a valid loop is exactly the contour orientation (milestone 4) of the closed point sequence the loop induces: the positions of the starting vertices of its edges, closed by the position of the first one.

### `Face_2D`

A planar face: a region of the plane bounded by one loop. A face is a value carrying its boundary loop, relative to the edge and vertex stores the boundary's edges come from. A valid face boundary is a valid loop whose orientation is not degenerate: a closed two-edge backtrack is a valid loop, but never a valid face boundary (DD-002, decision 3).

### `Face_Validity`

The exact classification of a loop as a face boundary: valid, invalid boundary, or degenerate boundary orientation. `Make_Face` builds a face only from a loop classifying as a valid boundary, so invalid faces cannot be obtained from the public API.

### Face orientation

The orientation of a valid face is exactly the orientation of its boundary loop, which a valid boundary guarantees to be counter-clockwise or clockwise: face orientation is consistent with loop orientation by construction.

## Normative for milestone 7

### `Dot_Product`

The exact scalar product of two vectors:

```text
Dot_Product (A, B) = A.DX * B.DX + A.DY * B.DY + A.DZ * B.DZ
```

The result is exact and may exceed the component domain; it is never
rounded. The same name also dots a cross vector with a grid vector,
component by component, in a wider exact domain.

### `Cross_Product`

The exact vector product of two vectors. Its result is an exact
mathematical vector whose components are the three product differences:

```text
Cross_Product (A, B) = (A.DY * B.DZ - A.DZ * B.DY,
                        A.DZ * B.DX - A.DX * B.DZ,
                        A.DX * B.DY - A.DY * B.DX)
```

The result is exact and may leave the component domain; it is never
rounded. A cross result is a derived quantity, never a grid position.
The cross vector is orthogonal to both operands: its dot with either
operand is exactly zero, proved over the whole grid domain.

### `Cross_Vector_3D`

The exact result type of `Cross_Product`: a derived mathematical vector
whose components may leave the component domain of a grid vector. A
cross vector is never a grid position and never a displacement.

### `Plane`

A plane is defined only by three non-collinear points; the collinear
degeneracy is reported at construction, never built. A plane carries its
three defining points, everything else is derived exactly on demand.

### `Plane_Side`

The exact classification of a point relative to a plane: in front on
the side the normal points to, behind on the other side, on the plane
when the plane equation vanishes. No tolerance is involved, and the
classification is invariant under any representable translation.

### `Normal`

The exact normal of the plane through three non-collinear points: the
cross product of the two displacements from the first defining point.
The normal of a valid plane is never null, and a null normal is exactly
the collinear degeneracy.

## Provisional geometric terms

### `Grid_Quantum`

The smallest spatial distinction in the model. It is explicit and is not an epsilon.

### `Grid_Unit`

One integer displacement step on the grid.

### `Length`

A non-negative physical magnitude. It is distinct from a coordinate and from an oriented displacement even if representations are related.

### Geometric predicate

A function that classifies a configuration without constructing a new geometric entity. A predicate used for topology must return an exact result or explicitly report that it cannot conclude.

## Provisional topological terms

### B-Rep

A boundary representation composed progressively of vertices, edges, loops, faces, shells, and solids. Its invariants must be guaranteed by construction or demonstrated with SPARK.

## Open decisions

- final public name of `Grid_Coordinate`;
- representation of physical lengths;
- configurable or fixed geometric quantum;
- grid-node versus grid-cell convention;
- physical/internal unit conversions and import rounding;
- uniqueness of vertices at the same point;
- edge, half-edge, or radial-edge topology;
- exact use of `Loop`, `Wire`, `Contour`, and `Ring`;
- representation of certified enclosures and indeterminate results.

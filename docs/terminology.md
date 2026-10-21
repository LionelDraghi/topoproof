- [TopoProof terminology](#topoproof-terminology)
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
  - [Normative for milestone 5](#normative-for-milestone-5)
    - [`Vertex`](#vertex)
    - [`Vertex_Handle`](#vertex_handle)
    - [`Vertex_Store`](#vertex_store)
    - [`Create`](#create)
  - [Provisional geometric terms](#provisional-geometric-terms)
    - [`Grid_Quantum`](#grid_quantum)
    - [`Grid_Unit`](#grid_unit)
    - [`Length`](#length)
    - [Geometric predicate](#geometric-predicate)
  - [Provisional topological terms](#provisional-topological-terms)
    - [`Edge`](#edge)
    - [`Loop`](#loop)
    - [`Face`](#face)
    - [B-Rep](#b-rep)
  - [Open decisions](#open-decisions)

# TopoProof terminology

This document defines the project's vocabulary. Terms used by the public API are normative once marked as such; others remain provisional or research-oriented.

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

### `Edge`

An oriented topological entity connecting two valid vertices.

### `Loop`

An oriented closed sequence of connected edges forming a boundary. The term should be reserved for a chain whose closure is guaranteed by construction or proof.

### `Face`

A topological entity bounded by an outer loop and optionally inner loops, associated with a geometric support.

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

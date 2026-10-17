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

## Provisional geometric terms

### `Grid_Quantum`

The smallest spatial distinction in the model. It is explicit and is not an epsilon.

### `Grid_Unit`

One integer displacement step on the grid.

### `Length`

A non-negative physical magnitude. It is distinct from a coordinate and from an oriented displacement even if representations are related.

### `Point_2D`

An exact position with two grid-coordinate components.

### `Orientation`

Classification of three 2D points as clockwise, counterclockwise, or collinear according to the exact determinant sign.

### Geometric predicate

A function that classifies a configuration without constructing a new geometric entity. A predicate used for topology must return an exact result or explicitly report that it cannot conclude.

## Provisional topological terms

### `Vertex`

A topological entity associated with a geometric point. A vertex has topological identity; a point is a geometric value.

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

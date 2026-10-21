# Edges

`edge` creates topological edges between vertices:
`topocli edge A=(X, Y) B=(X, Y) ...`.
The command takes the points in pairs: each consecutive pair is one oriented
edge, from the first point to the second. Vertices are created as needed:
within the command, a name designates one vertex, and a repeated name is the
same vertex, never a new one. The canonical result of creating the edge
between the vertices at `(0, 0)` and `(5, 5)` is
`edge 1 vertex 1 vertex 2`.

An edge is a topological entity: it connects two distinct vertices by
handles, and carries no geometry (see `docs/terminology.md`). Degeneracy is
topological: an edge whose two ends are the same vertex is rejected. An edge
between two distinct vertices at the same point is a valid edge: identity is
not position (design decision DD-002), and the geometric degeneracy of its
support is judged at loop level.

![Edge diagram](images/edges_1.svg)

## Contents

- [Edges](#edges)
  - [Contents](#contents)
  - [Scenario: create an edge between two vertices](#scenario-create-an-edge-between-two-vertices)
  - [Scenario: edges share vertices](#scenario-edges-share-vertices)
  - [Scenario: an edge between two vertices at the same point is valid](#scenario-an-edge-between-two-vertices-at-the-same-point-is-valid)
  - [Proved property](#proved-property)
  - [Scenario: an edge back to the same vertex is degenerate](#scenario-an-edge-back-to-the-same-vertex-is-degenerate)
  - [Scenario: an odd number of points is not a chain of pairs](#scenario-an-odd-number-of-points-is-not-a-chain-of-pairs)

## Scenario: create an edge between two vertices

- When I successfully run `../bin/topocli edge A=(0, 0) B=(5, 5) --draw ../docs/features/images/edges_1.svg`
- Then the output is
   ```
   vertex 1 point 0 0
   vertex 2 point 5 5
   edge 1 vertex 1 vertex 2
   ```

## Scenario: edges share vertices

The second edge reuses the vertex `B`: a repeated name is the same handle,
so the two edges meet at one vertex.

![Edges sharing a vertex](images/edges_2.svg)

- When I successfully run `../bin/topocli edge A=(0, 0) B=(5, 5) C=(0, 5) B --draw ../docs/features/images/edges_2.svg`
- Then the output is
   ```
   vertex 1 point 0 0
   vertex 2 point 5 5
   edge 1 vertex 1 vertex 2
   vertex 3 point 0 5
   edge 2 vertex 3 vertex 2
   ```

## Scenario: an edge between two vertices at the same point is valid

Two distinct names at the same position are two distinct vertices: the edge
between them is a valid topological edge, and the degeneracy of its
geometric support is judged later, at loop level.

- When I successfully run `../bin/topocli edge A=(1, 2) B=(1, 2)`
- Then the output is
   ```
   vertex 1 point 1 2
   vertex 2 point 1 2
   edge 1 vertex 1 vertex 2
   ```

## Proved property

Edge endpoints exist at creation: the SPARK precondition of `Edges.Create`
requires both vertex handles to be contained in the vertex store, and since
stored vertices are never removed, existing endpoints stay valid for the
whole lifetime of both stores. The postcondition states that the new handle
is contained, that its endpoints are exactly the given pair, and that every
previously stored edge is unchanged. Both contracts are proved by GNATprove
over the whole domain, as is the absence of run-time errors of every
operation of the unit.

## Scenario: an edge back to the same vertex is degenerate

The repeated name designates the same vertex, so the pair is degenerate: the
edge is rejected.

- When I run `../bin/topocli edge A=(1, 2) A`
- Then the output is
   ```
   vertex 1 point 1 2
   error: degenerate edge
   ```
- And there is an error

## Scenario: an odd number of points is not a chain of pairs

- When I run `../bin/topocli edge A=(1, 2)`
- Then there is an error

# TopoProof design discussions

This document records design topics. A discussion is not a normative rule
until its status becomes **decided** and the decision is reflected in the
terminology, contracts, executable documentation, and implementation.

## DD-001: validity of segment sequences and future B-Rep boundaries

- **Status:** decided (2026-10-20)
- **Related task:** former `TDL-DESIGN-001`
- **Scope:** `Segment_Sequence_2D`, contours, loops, and future planar face boundaries

### Former situation

`Segment_Sequences.Is_Valid` used to mean:

1. no segment has coincident endpoints; and
2. no three consecutive points are collinear.

This definition gave every retained vertex a non-flat turning direction,
mixing the geometric validity of the chain with a canonical-representation
property of its vertex list.

### Decision

Collinear intermediate points are **not an invalidity**: they are a matter
of representation. Concretely:

- validity is geometric: `Is_Valid` rejects only degenerate segments;
- the former rule (2) becomes the separate predicate
  `Has_No_Flat_Turns`, a canonical-representation property: a valid chain
  with a flat turn describes exactly the same geometry as the chain
  without the redundant point;
- consequently, `Orientation` accepts any closed, valid sequence: the
  signed area of a contour with a flat turn is well defined, and refusing
  to classify it was a functional defect, not a safety rule;
- canonicalisation (removing redundant points) is not specified at this
  stage: it may enter the development plan with milestone 5, when loops
  and face boundaries are introduced, as a representation choice and
  never as a validity rule.

### Rationale

A redundant collinear vertex creates no geometric or topological
ambiguity: the contour delimits exactly the same region. Treating it as
an invalidity would have forced milestone 5 either to reopen the
predicate or to reject geometrically correct face boundaries.

### Remaining questions, deferred to milestone 5

The questions below were part of this discussion and are not settled by
the decision above; they concern the future topological types:

1. Is a closed two-edge backtrack a loop, a degenerate loop, or invalid?
2. Are repeated non-consecutive vertices allowed when they are shared
   endpoints?
3. Does loop simplicity follow the discrete model only, or must
   off-grid crossings also invalidate a face boundary?
4. Which properties belong to geometry, and which belong to the future
   `Is_Valid_Loop` and `Is_Valid_Face_Boundary` predicates?

## DD-002: geometry and topology separation, and the vertex store

- **Status:** proposed (2026-10-21)
- **Related milestone:** 5, first topological structure
- **Scope:** `Vertex`, `Edge`, `Loop`, `Face`, and the answers to the
  questions DD-001 deferred to milestone 5

### Problem

Milestones 1 to 4 deliver geometry as values: a `Point_2D` has no
identity, and two equal points are interchangeable. Milestone 5
introduces entities with identity: a vertex is not a point. SPARK
excludes allocators, so topological references cannot be pointers.

### Proposed decisions

1. **Store-and-handle representation.** Topological entities live in
   explicit bounded stores (arrays); references are handles into a
   store, and validity is a predicate over the store. Each store
   declares its capacity as a discriminant without a default value: an
   object pays only its declared capacity, and the capacity is frozen
   for the whole object lifetime, so no assignment can invalidate
   handles. The growth-by-reassignment of a mutable discriminated
   record was rejected: it would copy the whole store at every
   creation. This keeps the
   reference-validity objectives (`every vertex references a valid
   point`, `edge endpoints exist`) provable, and lets invalid states be
   rejected by construction through contracts on the store.
2. **Identity is not position.** Two distinct vertices may carry the
   same point. Connectivity is decided on handles, never on positions;
   geometric predicates (closure, degeneracy, self-intersection,
   orientation) are decided on the underlying point sequence and reused
   as-is. Automatic merging of same-point vertices is not introduced;
   it stays an open question.
3. **Closed two-edge backtrack (`A -> B -> A`).** It is a degenerate
   loop: closed, valid, zero-area, classified `Degenerate`. It is never
   a valid face boundary.
4. **Simplicity follows the discrete model.** An off-grid crossing of
   two edges shares no grid position, so it does not invalidate a face
   boundary. This is consistent with `Segment_Sequences.Crosses` and is
   a documented representational limit of the discrete model, not a
   defect.
5. **Predicate ownership.** Geometry owns position-level predicates
   (already delivered by milestones 1 to 4). Topology owns
   handle-level predicates: reference validity, connectivity, absence of
   orphan edges, and orientation consistency; each reuses the geometric
   predicates of the underlying point sequence. `Is_Valid_Loop` and
   `Is_Valid_Face_Boundary` are topological compositions.
6. **Edge degeneracy is topological.** Edge creation rejects only an
   edge whose two ends are the same vertex (`A = B`): a repeated handle
   is one vertex twice. An edge between two distinct vertices at the
   same point is a valid edge, because identity is not position; the
   geometric degeneracy of its support is judged later, at loop level,
   where `Segment_Sequences.Is_Valid` applies.

### Vertical increments

```text
a) Vertex: creation from a point, reference validity
b) Edge: between two distinct vertices, degenerate rejection
c) Loop: connected edges, closure guaranteed
d) Face: valid loop, orientation consistency
```

### Open questions

- half-edge versus simple edge representation (minimal milestone 5
  proposes simple oriented edges; half-edge is a milestone 8 concern);
- final names among `Loop`, `Wire`, `Contour`, `Ring`.

## DD-003: TopoScript source form and bbt integration

- **Status:** not decided
- **Related task:** `TDL-DESIGN-003`
- **Scope:** TopoScript source form, bbt scenario embedding, HAC execution, scripting API security
- **Reference:** [Ada and a mini-Ada interpreter, FOSDEM 2025](https://github.com/zertovitch/hac/blob/master/doc/ada_mini_ada_fosdem_2025.pdf),
  the HAC author's presentation of the interpreter, its Ada subset, and
  embedding a scripting facility in an Ada application

### Current situation

bbt scenarios invoke `topocli` with increasingly long command lines. As operations
become richer, those command lines become difficult to write, read, review, and
maintain. Milestone 6 of the development plan proposes TopoScript: a lightweight
Ada scripting form where the user writes only declarations and statements, and
`topocli` generates the hidden Ada compilation-unit wrapper before passing the
complete source to HAC.

The source form preserves ordinary Ada notation: `:=` for assignment, `=>` for
named associations, `;` as the statement terminator, `--` for comments, explicit
types and constants. Names may remain qualified where qualification improves
clarity or removes ambiguity, for example `STEP_Files.Export (P, "piece.step");`.

A script may draw one coherent diagnostic image (axes, input geometry, expected
result, actual result in a single scene, actual result in red on failure), and a
script may declare the expected geometry for visual explanation only: the
expected textual result and the verdict remain in the bbt `Then` step.

The feature must use existing bbt syntax and existing generic file and
command-execution steps: the embedded block is materialised as a scenario-local
`.topo` execution artefact, and the exact `Given` and execution step wording
must be selected from syntax already supported by bbt. Introducing shorter or
TopoScript-specific bbt wording is out of scope.

### Security and API exposure

The restriction of APIs available to user scripts is intentionally deferred. The
architecture must nevertheless make it possible to expose a dedicated scripting
API rather than the complete internal implementation. Sandboxing, resource
limits, filesystem access, extension trust, and failure isolation require
separate design decisions before untrusted extensions are enabled. These
questions must not block an initial test-oriented prototype executed from the
trusted TopoProof test suite.

### Questions to arbitrate

1. Which exact existing bbt `Given` step should hold the embedded source block?
2. Can HAC consume the wrapped source directly from memory, or should the first
   integration use a temporary file?
3. Which subset of Ada declarations and statements will TopoScript initially
   support?
4. How should generated-wrapper line numbers be mapped back to lines in the
   Markdown scenario?
5. What canonical `Put` representations are required for TopoProof public types?
6. Which drawing primitives are needed for the first migrated scenarios?
7. How should script and scripting-API compatibility be versioned?
8. Which capabilities must be restricted before standalone user extensions are
   considered safe?

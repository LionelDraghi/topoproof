# Changelog <!-- omit from toc -->

All notable changes **from a user perspective** to this project will be documented in this file.  
The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.1.0/), (guidelines at the bottom of the page).  
Version numbering adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

- **[0.1.5-dev] - 2026-??-??**

- **[0.1.4] - 2026-10-23**
  - [Added]   TopoScript parity for every proved operation: displacement,
              equality, translation, orientation, intersection, the six
              contour predicates and the vertex and edge creations all run
              as scripts, with the explicit `Put` operations writing the
              canonical results and `Make_Loop_From_Edges` classifying
              loops over created edges
  - [Added]   the `run_code` inline entry: `topocli run_code FRAGMENT`
              executes a short script given on the command line, split
              into lines at every semicolon, so the same command line runs
              on every platform
  - [Changed] `--output FILE` receives the whole multi-line result of one
              run, in order, instead of the last line only
  - [Changed] every feature page runs scripts only, and its diagrams are
              written by the tested scripts through `Begin_Image` and
              `End_Image`, no longer synthesized from command data
  - [Removed] the command form of the operations (`translate`,
              `displacement`, `equal`, `orientation`, `intersect`, the six
              `contour_*` commands, `vertex`, `edge`, `loop`, `face`) and
              its `--input`, `--draw`, `--draw-with` and
              `--draw-short-labels` options: TopoScript is the single
              front-end, `topocli` runs scripts only (DD-004)
  - [Fixed]   `topocli run` on a missing file reports `error: file not
              found` instead of crashing with an access-check failure

- **[0.1.3] - 2026-10-22**
  - [Added]   TopoScript, the embedded Ada scripting facility executed
              by HAC: `topocli run FILE.topo` runs fragments against
              the proved kernel operations (development plan,
              Milestone 6)

- **[0.1.2] - 2026-10-22**
  - [Added]   the topological operations `vertex`, `edge`, `loop` and
              `face`, closing milestone 5: vertices are a proved store
              with creation handles, edges connect two distinct vertices
              by handles, loops are oriented closed chains of connected
              edges, and faces are planar regions bounded by one valid
              loop; degeneracy is rejected by construction, and a closed
              two-edge backtrack is a valid loop but never a valid face
              boundary. This records design decision DD-002
  - [Changed] contour validity is now geometric: a sequence is valid when
              no segment is degenerate; intermediate collinear points no
              longer invalidate it, they are a matter of representation.
              The former validity rule (no three consecutive collinear
              points) is now the separate `contour_no_flat_turns`
              operation, and `contour_orientation` accepts contours with
              flat turns, whose signed area is well defined. This records
              design decision DD-001
  - [Added]   the contour invariance lemmas, closing milestone 4: the
              signed area of a closed contour is invariant under
              rotation of the starting vertex, and negated by reversal of
              the traversal direction; the orientation is invariant under
              rotation and mirrored by reversal. The public `Partial_Sum`
              operation carries the proofs
  - [Changed] the command line now names its points: `NAME=(X, Y)` defines
              and uses a point, a bare `NAME` refers to an earlier point of
              the same command, and the point counts are gone; the closure
              of a chain is visible as a repeated name
  - [Added]   the `--draw` option: each command generates the SVG diagram
              of its own data and results with the topodraw renderer, so
              the tested command is the single source of its documentation
              image; `--draw-with` adds extra named points to the diagram,
              and `--draw-short-labels` names the vectors S1, S2, ...;
              the diagrams carry tick marks again, with an automatic
              round step
  - [Added]   the topodraw scene parser and renderer as a library, shared
              by the topodraw tool and the TopoProof application

- **[0.1.1] - 2026-10-19**
  - [Changed] the grid domain is now derived from the machine, not the other
              way around: coordinates run to 2**30 - 1, the largest domain
              for which the whole arithmetic chain stays on native widths,
              with differences saturating 32 bits and determinants exactly
              saturating 64 bits
  - [Added]   the `intersect` operation: exact classification of the intersection
              of two 2D segments as no intersection, single grid position,
              crossing at a non-grid position, or collinear overlap, with the
              shared point or sub-segment returned
  - [Added]   the intersection properties proved by SPARK over the whole grid
              domain: invariance under exchange of the two segments, and
              membership of every reported point and overlap boundary in both
              segments
  - [Added]   the `orientation` operation: exact classification of three 2D points
              as counter-clockwise, clockwise or collinear from the determinant
              sign, documented with executable scenarios under `docs/features/`
  - [Added]   the orientation properties proved by SPARK over the whole grid
              domain: invariance under cyclic permutation, mirroring under
              exchange of two points, degenerate collinearity of paths with
              coincident points, and invariance under representable translation
  - [Added]   the contour operations: exact classification of 2D segment
              sequences with `contour_continuity`, `contour_closure`,
              `contour_orientation`, `contour_self_intersects` and
              `contour_valid`, documented with executable scenarios under
              `docs/features/`
  - [Added]   the contour properties proved by SPARK over the whole grid
              domain: closure and validity by contract, orientation as the
              exact sign of the shoelace sum, and signed-area sums that
              cannot overflow for any sequence up to the maximum length
  - [Added]   a diagram illustrating the geometry of every documentation
              scenario, tables of contents in every page, and a README for
              the topodraw diagram tool

- **[0.1.0] - 2026-10-17**
  - [Added]   the TopoProof application and its first three operations: `translate`,
              `displacement` and `equal`, computing exactly on integer grid points,
              documented with executable scenarios under `docs/features/`
  - [Added]   the fundamental identity `Translate (A, Displacement (A, B)) = B` is
              proved by SPARK over the whole grid domain
  - [Added]   the complete verification chain `make check`: build, execution of the
              documentation, and GNATprove proofs, operational from a clean clone

---

[Keep a Changelog](http://keepachangelog.com/en/1.1.0/) Guiding Principles
  - Changelogs are for humans, not machines.
  - There should be an entry for every single version.
  - The same types of changes should be grouped.
  - Versions and sections should be linkable.
  - The latest version comes first.
  - The release date of each version is displayed.
  - Mention whether you follow Semantic Versioning.

Types of changes
  - Added for new features.
  - Changed for changes in existing functionality.
  - Deprecated for soon-to-be removed features.
  - Removed for now removed features.
  - Fixed for any bug fixes.
  - Security in case of vulnerabilities.

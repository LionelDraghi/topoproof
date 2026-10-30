# Concerns <!-- omit from toc -->

This is a lightweight index, not a duplicate issue tracker. Each row
supplies priority, a short label, kind, authoritative link, and status;
the details remain in the authoritative source.

| Priority | Concern | Kind | Source | Status |
|---|---|---|---|---|
| P2 | Arbitrate the remaining TopoScript API questions | Design | `TDL-DESIGN-004`, below | Open |
| P3 | Load the wrapper prelude from an external source file | Debt | `TDL-IMPROVE-007`, below | Open |
| P3 | Describe the scripting API once | Debt | `TDL-IMPROVE-008`, below | Open |
| P3 | Give the drawing output semantic identifiers | Debt | `TDL-IMPROVE-010`, below | Open |
| P3 | Tame the hard proof points of `Collinear_Membership` | Proof | `TDL-PROOF-002`, below | Open |

## Contents <!-- omit from toc -->

- [TDL-DESIGN-004: arbitrate the remaining TopoScript API questions](#tdl-design-004-arbitrate-the-remaining-toposcript-api-questions)
- [TDL-IMPROVE-007: load the wrapper prelude from an external source file](#tdl-improve-007-load-the-wrapper-prelude-from-an-external-source-file)
- [TDL-IMPROVE-008: describe the scripting API once](#tdl-improve-008-describe-the-scripting-api-once)
- [TDL-IMPROVE-010: give the drawing output semantic identifiers](#tdl-improve-010-give-the-drawing-output-semantic-identifiers)
- [TDL-PROOF-002: tame the hard proof points of Collinear_Membership](#tdl-proof-002-tame-the-hard-proof-points-of-collinear_membership)
- [Completed or decided](#completed-or-decided)

## TDL-DESIGN-004: arbitrate the remaining TopoScript API questions

- **Category:** DESIGN
- **Status:** open, low priority (2026-10-24)
- **Context:** Milestone 6 delivers the initial TopoScript facility through
  `topocli run` and the injected scripting API. The canonical `Put`
  representations and the drawing primitives were settled by DD-004 and the
  single front-end waves; the subset question was decided on 2026-10-24
  (DD-003 amendment): the wrapper is a non-rejecting boilerplate generator
  and the subset is everything HAC handles, tracked by `TDL-IMPROVE-009`.
- **Priority rationale:** TopoProof is in alpha development. The only
  TopoScripts are the test-suite scenarios, there are no scripts in the
  wild and no external users; any scripting-API evolution changes the test
  scripts in the same change, and the security model can wait until a
  standalone user or an extension host actually exists. Both remaining
  questions are therefore kept at low priority.
- **Decision required:** the arbitration questions of `DD-003`.
- **Acceptance:** each question of `DD-003` is either decided and recorded,
  or explicitly rejected with its reason.

## TDL-IMPROVE-007: load the wrapper prelude from an external source file

- **Category:** IMPROVE
- **Status:** open, later
- **Context:** the fixed scripting-API prelude is emitted through many
  `Append_Line` calls, unreadable as Ada and hard to review. The GNAT
  `External_Initialization` aspect, an experimental GNAT extension
  already exercised by bbt, can initialise a text constant from a file
  at build time; the toolchain support must be validated before
  adoption (development plan, TopoScript consolidation,
  Increment 6).
- **Acceptance:** the prelude lives as one Ada source fragment outside
  the wrapper body, the source-mapping offsets are derived from the
  loaded content, a test compiles the loaded prelude through HAC, and
  the build tracks the file as an input.

## TDL-IMPROVE-008: describe the scripting API once

- **Category:** IMPROVE
- **Status:** open, later
- **Context:** the same API is represented in the generated
  declarations, the callback registration, the callbacks and the
  feature documentation, with a divergence risk (development plan,
  TopoScript consolidation, Increment 7).
- **Acceptance:** the generated declarations and the registrations
  derive from one internal description, and the documented scripting
  API is verified against it.

## TDL-IMPROVE-010: give the drawing output semantic identifiers

- **Category:** IMPROVE
- **Status:** open, later
- **Context:** the drawing scenarios check the mere presence of a hex
  colour in the SVG, which proves too little; stable semantic
  identifiers in the topodraw output would let a scenario verify the
  intended object (development plan, TopoScript consolidation,
  Increment 9).
- **Acceptance:** topodraw writes stable identifiers for the drawn
  objects, and the drawing scenarios check the intended object rather
  than a colour.

## TDL-PROOF-002: tame the hard proof points of Collinear_Membership

- **Category:** PROOF
- **Status:** open, later
- **Context:** the proof effort of the kernel is concentrated in three
  checks of the ghost lemma `Collinear_Membership`
  (`topoproof-geometry-intersections.adb`): the strict-betweenness
  overflow check of the crossing quotient (line 353, 20 s), the
  `Lemma_Quotient_Ordering` precondition on the Y axis (line 386, 11 s),
  and the product identity TD·(DX−QX) = (TD−TN)·DX (line 368, 3 s);
  every other proved check of the project is at 1 s or less
  (statistics of 2026-10-24, level 2). The running prover order
  (`--prover=z3,cvc5,altergo`) halves the subprogram cost, but the
  structural lever is to promote the repeated quotient-betweenness
  reasoning into reusable lemmas, as the growth of the 3D structure
  will multiply the uses of the cubic-product identities.
- **Acceptance:** no check of the project exceeds a few seconds at
  level 2 with the default prover configuration, and the
  quotient-betweenness reasoning is factored in named lemmas with their
  own proved contracts.

## Completed or decided

The former entries are completed or decided; they are recorded in the
changelog and in the design decisions (`docs/dev/design_discussions.md`).

- TDL-DESIGN-001 (validity of segment sequences): decided as DD-001, see
  `docs/dev/design_discussions.md`;
- TDL-DESIGN-002 (split the kernel crate from tools): completed with the
  `topocli` client crate pinning the root library crate;
- TDL-DESIGN-003 (implement TopoScript embedded scripting): completed with
  the `topocli run` facility of Milestone 6, Increments 1 to 6; the
  follow-up questions are tracked by TDL-DESIGN-004 and `DD-003`;
- TDL-PROOF-001 (retain auditable GNATprove evidence): completed with the
  `check-evidence` gate and the CI artefact uploads;
- TDL-TOOLING-001 (simplify GPR projects): completed with one minimal project
  for the kernel and one for the client;
- TDL-IMPROVE-001 (complete milestone 4 algebraic invariants): completed with
  the rotation and reversal lemmas of `Segment_Sequences`;
- TDL-IMPROVE-002 (introduce an explicit TopoScript execution session):
  completed with the limited private `Script_Session` and its reliable
  `Reset` (TopoScript consolidation, Increment 1);
- TDL-IMPROVE-003 (split the native scripting API by domain): completed
  with the `.Conversions`, `.Geometry`, `.Topology`, `.Drawing`, `.Output`
  and `.Session` children, the root coordinating the registration only
  (consolidation, Increment 2);
- TDL-IMPROVE-004 (centralise HAC conversions and canonical output):
  completed with the shared `Read_*`/`Write_*` conversions and the single
  `Image` formatters of the callbacks and the diagnostics (consolidation,
  Increment 3);
- TDL-IMPROVE-005 (fix the wrapper source-buffer ownership): completed
  with the wrapper reclaiming its source buffers (consolidation,
  Increment 4);
- TDL-IMPROVE-006 (add the TopoScript edge-case bbt scenarios): completed
  with the edge-case scenarios of `docs/features/toposcript.md`
  (consolidation, Increment 5);
- TDL-IMPROVE-011 (bring the geometry family to scripting parity):
  completed with the displacement, equality and translation `Put`
  operations and their pages running scripts only (single front-end,
  Increment 3);
- TDL-IMPROVE-012 (bring the predicates to scripting parity): completed
  with the orientation and intersection `Put` operations and their pages
  running scripts only (single front-end, Increment 4);
- TDL-IMPROVE-013 (bring the contour predicates to scripting parity):
  completed with the six contour `Put` operations and the contours page
  running scripts only (single front-end, Increment 5);
- TDL-IMPROVE-014 (bring the construction operations to scripting
  parity): completed with the vertex and edge creations with observable
  handles and the explicit `Put_Vertex` and `Put_Edge` traces (single
  front-end, Increment 6);
- TDL-IMPROVE-015 (migrate the loop and face pages to scripts):
  completed with the loops and faces pages running scripts only and the
  new `Make_Loop_From_Edges` (single front-end, Increment 7);
- TDL-IMPROVE-016 (run a script inline from the command line): completed
  with the `run_code` entry, its fragment quoting documented and
  exercised on the three CI runners (single front-end, Increment 8);
- TDL-IMPROVE-017 (retire the command form): completed with the deletion
  of the operation parser, the command dispatcher and the command scene
  synthesis, and `command-line.md` documenting the runner only (single
  front-end, Increment 9);
- TDL-IMPROVE-009 (make the wrapper a non-rejecting boilerplate generator):
  completed with the placement-only classifier of `TopoScript_Wrapper`
  (declarations, continuations and nested unit bodies in the declarative
  part, everything else in the statement region, no rejection), the removal
  of `Wrapper_Error`, and the former pre-compilation rejection scenarios
  expecting HAC diagnostics (DD-003 decision of 2026-10-24);
- TDL-DOC-001 (keep executable documentation and diagrams authoritative):
  completed with the `--draw` diagrams generated by the tested commands.

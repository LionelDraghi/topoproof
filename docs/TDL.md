# TopoProof task and decision list <!-- omit from toc -->

This file records unfinished work that must remain visible in the repository.
Entries use one of the following categories:

- **FIXME**: known defect or incomplete behaviour that can invalidate a claim.
- **IMPROVE**: worthwhile improvement that does not invalidate current behaviour.
- **DESIGN**: architectural work requiring an explicit design decision.
- **PROOF**: missing, incomplete, or insufficiently auditable proof work.
- **DOC**: missing or inconsistent executable or design documentation.
- **TOOLING**: build, packaging, CI, or developer-experience work.

Each entry has a stable identifier, a status, and an acceptance criterion. Completed
entries are removed from this file and recorded in `docs/changelog.md` or the relevant
design decision.

## Open

### TDL-DESIGN-004: arbitrate the remaining TopoScript API questions

- **Category:** DESIGN
- **Status:** open
- **Context:** Milestone 6 delivers the initial TopoScript facility through
  `topocli run` and the injected scripting API. The follow-up questions
  (control structures and composite declarations in the subset, canonical
  `Put` representations beyond points and chain kinds, extra drawing
  primitives, API versioning, restricted capabilities before untrusted
  extensions) stay listed in `DD-003`.
- **Decision required:** the arbitration questions of `DD-003`.
- **Acceptance:** each question of `DD-003` is either decided and recorded,
  or explicitly rejected with its reason.

### TDL-IMPROVE-002: introduce an explicit TopoScript execution session

- **Category:** IMPROVE
- **Status:** open
- **Context:** the scripting API keeps the failure, the image state, the
  drawing scene, the anchor counter and the topology chain as
  library-level variables of `toposcript_api.adb`. Acceptable while one
  `topocli` process runs one script, unreliable for repeated execution
  in a persistent host (development plan, TopoScript consolidation,
  Increment 1).
- **Acceptance:** a limited private `Script_Session` owns the whole
  mutable execution state, `Reset` restores a clean state, and no
  library-level mutable state remains.

### TDL-IMPROVE-003: split the native scripting API by domain

- **Category:** IMPROVE
- **Status:** open
- **Context:** `toposcript_api.adb` (754 lines) mixes conversion,
  geometry, topology, drawing, output, registration and execution state.
  The 3D types of the next milestones will make the single package
  difficult to maintain (development plan, TopoScript consolidation,
  Increment 2).
- **Acceptance:** the root `TopoScript_API` coordinates the callback
  registration only, the domains live in child packages (conversions,
  geometry, topology, drawing, output, session), and the bbt scenarios
  stay unchanged and green.

### TDL-IMPROVE-004: centralise HAC conversions and canonical output

- **Category:** IMPROVE
- **Status:** open
- **Context:** every callback repeats the widest-integer decoding and
  the grid-domain checks, and the canonical textual representations are
  duplicated between the `topocli` commands and the `Put` callbacks
  (`point X Y Z`, `loop closed ...`, `face ...`). The canonical
  representation is part of the observable interface and must have one
  implementation (development plan, TopoScript consolidation,
  Increment 3).
- **Acceptance:** conversion helpers between the HAC element arrays and
  the TopoProof types exist and are used by every callback, and the
  `Image` formatters are shared by the callbacks and the diagnostics,
  with no duplicated textual representation left. Amended by DD-004:
  the routing through the command-line commands is dropped, the
  commands are retired instead (development plan, TopoScript as the
  single front-end, Increment 1).

### TDL-IMPROVE-005: fix the wrapper source-buffer ownership

- **Category:** IMPROVE
- **Status:** open
- **Context:** `TopoScript_Wrapper.Set_Source` replaces its allocated
  text buffer without reclaiming the previous allocation, negligible
  for a short-lived CLI process, unsuitable for repeated execution
  (development plan, TopoScript consolidation, Increment 4).
- **Acceptance:** the previous allocation is reclaimed (or the source
  lives in the stream object), and repeated script executions do not
  leak.

### TDL-IMPROVE-006: add the TopoScript edge-case bbt scenarios

- **Category:** IMPROVE
- **Status:** open
- **Context:** the wrapper and session edge cases observable through
  `topocli run` are not covered yet: empty fragment, declarations
  without statements, CRLF input, final line without a newline,
  declaration split across lines, declaration forms outside the
  subset, two consecutive images, `End_Image` without `Begin_Image`,
  chain continuing after a rejection
  (development plan, TopoScript consolidation, Increment 5).
- **Acceptance:** every scenario of the consolidation section is
  executable, green, and documented in `docs/features/toposcript.md`.

### TDL-IMPROVE-007: load the wrapper prelude from an external source file

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

### TDL-IMPROVE-008: describe the scripting API once

- **Category:** IMPROVE
- **Status:** open, later
- **Context:** the same API is represented in the generated
  declarations, the callback registration, the callbacks and the
  feature documentation, with a divergence risk (development plan,
  TopoScript consolidation, Increment 7).
- **Acceptance:** the generated declarations and the registrations
  derive from one internal description, and the documented scripting
  API is verified against it.

### TDL-IMPROVE-009: strengthen the fragment scanner incrementally

- **Category:** IMPROVE
- **Status:** open, later
- **Context:** the line-based classifier of `TopoScript_Wrapper` is
  appropriate for the documented subset but fragile for multiline
  declarations and richer Ada syntax (development plan, TopoScript
  consolidation, Increment 8).
- **Acceptance:** the scanner tracks comments, string literals,
  parenthesis depth and semicolon-terminated constructs, the
  declarations-before-statements rule is kept, and a multiline
  declaration is rejected with a clean diagnostic at the right line.

### TDL-IMPROVE-010: give the drawing output semantic identifiers

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

### TDL-IMPROVE-011: bring the geometry family to scripting parity

- **Category:** IMPROVE
- **Status:** open
- **Context:** DD-004 decides the pivot to the single front-end: the
  command operations are retired by waves, after the scripting API
  reaches parity. The geometry wave covers `displacement` and `equal`
  (development plan, TopoScript as the single front-end, Increment 3).
- **Acceptance:** the scripting API exposes the displacement and the
  equality operations with their canonical `Put` representations, and
  the `translation.md`, `displacement.md` and `equality.md` pages run
  scripts only, with their images regenerated in the same change. The
  migration also fixes the label collision of `translation_2.svg`,
  where the point of the rejection scenario sits exactly on the tip of
  the X axis, under its letter.

### TDL-IMPROVE-012: bring the predicates to scripting parity

- **Category:** IMPROVE
- **Status:** open
- **Context:** the orientation and intersection wave of the DD-004
  pivot (development plan, TopoScript as the single front-end,
  Increment 4).
- **Acceptance:** the scripting API exposes the three-point orientation
  and the exact intersection classification with their canonical `Put`
  representations, and the `orientation.md` and `intersection.md` pages
  run scripts only, with their images regenerated in the same change.

### TDL-IMPROVE-013: bring the contour predicates to scripting parity

- **Category:** IMPROVE
- **Status:** open
- **Context:** the contour wave of the DD-004 pivot (development plan,
  TopoScript as the single front-end, Increment 5).
- **Acceptance:** the scripting API exposes continuity, closure,
  orientation, self-intersection, validity and flat turns over a chain
  of points with their canonical `Put` representations, and the
  `contours.md` page runs scripts only, with its images regenerated in
  the same change.

### TDL-IMPROVE-014: bring the construction operations to scripting parity

- **Category:** IMPROVE
- **Status:** open
- **Context:** the construction wave of the DD-004 pivot: `vertex` and
  `edge` become script operations, the handles stay observable values,
  and the trace lines are printed by the explicit `Put_Vertex` and
  `Put_Edge` (DD-004, decision 3) (development plan, TopoScript as
  the single front-end, Increment 6).
- **Acceptance:** the scripting API exposes the vertex and edge
  creation with observable handles and the explicit trace operations,
  and the `vertices.md` and `edges.md` pages run scripts only, with
  their images regenerated in the same change.

### TDL-IMPROVE-015: migrate the loop and face pages to scripts

- **Category:** IMPROVE
- **Status:** open
- **Context:** the loop and face wave of the DD-004 pivot: the
  operations already exist, only the pages remain in the command form
  (development plan, TopoScript as the single front-end, Increment 7).
- **Acceptance:** the `loops.md` and `faces.md` pages run scripts only,
  under the anti-tautology invariant, with their images regenerated in
  the same change.

### TDL-IMPROVE-016: run a script inline from the command line

- **Category:** IMPROVE
- **Status:** open
- **Context:** the inline entry of the DD-004 pivot: short scripts
  replace the ergonomics of the command form (development plan,
  TopoScript as the single front-end, Increment 8).
- **Acceptance:** `topocli run` accepts an inline fragment, the
  fragment quoting is documented, and the entry is exercised by a
  bbt scenario on each CI platform.

### TDL-IMPROVE-017: retire the command form

- **Category:** IMPROVE
- **Status:** open
- **Context:** the retirement wave of the DD-004 pivot: the last wave
  deletes what no scenario uses anymore (development plan, TopoScript
  as the single front-end, Increment 9).
- **Acceptance:** `command-line.md` documents the runner only, and the
  client contains no operation parser, no command dispatcher and no
  command scene synthesis.

## Completed

The former entries were completed or decided:

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
- TDL-DOC-001 (keep executable documentation and diagrams authoritative):
  completed with the `--draw` diagrams generated by the tested commands.

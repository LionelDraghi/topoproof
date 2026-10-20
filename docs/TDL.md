# TopoProof task and decision list

This file records unfinished work that must remain visible in the repository.
Entries use one of the following categories:

- **FIXME**: known defect or incomplete behaviour that can invalidate a claim.
- **IMPROVE**: worthwhile improvement that does not invalidate current behaviour.
- **DESIGN**: architectural work requiring an explicit design decision.
- **PROOF**: missing, incomplete, or insufficiently auditable proof work.
- **DOC**: missing or inconsistent executable or design documentation.
- **TOOLING**: build, packaging, CI, or developer-experience work.

Each entry has a stable identifier, a status, and an acceptance criterion. Completed
entries are removed from this file and recorded in `CHANGELOG.md` or the relevant
design decision.

## Open

### TDL-DESIGN-001: define B-Rep boundary validity

- **Category:** DESIGN
- **Status:** open, not decided
- **Context:** `Segment_Sequences.Is_Valid` currently rejects degenerate segments and
  three consecutive collinear points. It mixes geometric cleanliness with the future
  validity rules of a topological loop or face boundary.
- **Decision required:** decide whether collinear intermediate points are invalid,
  merely non-minimal, or subject to canonicalisation.
- **Acceptance:** the decision is recorded in `docs/design-discussions.md`; public
  predicates are renamed or split consistently; contracts and bbt scenarios follow
  the selected semantics.

### TDL-DESIGN-002: split the kernel crate from tools

- **Category:** DESIGN
- **Status:** open
- **Context:** the root crate currently builds the `topoproof` executable and imports
  rendering support. The product of the root crate should become the proved kernel
  library; the CLI test driver and drawing support should live in a tools sub-crate.
- **Target structure:**

  ```text
  topoproof/                 proved library crate
  tools/topoproof/           CLI and bbt system-under-test crate
  ```

- **Constraints:** the tools crate may use non-SPARK facilities; the root library
  remains SPARK-compatible; GNATprove analyses every kernel unit even when no main
  imports it; rendering is integrated in the tools crate without a separate
  `topodraw` library at this stage.
- **Acceptance:** `alire.toml` describes a library crate; the tools crate pins the
  root crate; `make prove` uses `-U` on the kernel project; bbt still drives the CLI.

### TDL-PROOF-001: retain auditable GNATprove evidence

- **Category:** PROOF
- **Status:** open
- **Context:** proof must leave reviewable evidence comparable to bbt output.
- **Acceptance:** local and CI proof runs retain the command line, tool version,
  complete console output, analysis summary, and assumptions report as build
  artefacts; CI fails on any unmet integration condition in `docs/development.md`.

### TDL-TOOLING-001: simplify GPR projects

- **Category:** TOOLING
- **Status:** open
- **Context:** project files currently mix kernel, CLI, profile, and rendering concerns.
- **Acceptance:** one minimal GPR project defines the proved library and one minimal
  project defines the tools executable; compilation and proof switches have one
  authoritative location each.

### TDL-IMPROVE-001: complete milestone 4 algebraic invariants

- **Category:** IMPROVE
- **Status:** open
- **Context:** signed area and contour orientation are implemented, but invariance
  under rotation of the starting point and reversal of traversal remain deferred.
- **Acceptance:** ghost lemmas state and prove cyclic-start invariance and orientation
  reversal over the advertised sequence domain.

### TDL-DOC-001: keep executable documentation and diagrams authoritative

- **Category:** DOC
- **Status:** open
- **Context:** generated diagrams, CLI output, and Markdown scenarios must represent
  the same tested data.
- **Acceptance:** `make test` regenerates/checks the relevant artefacts and fails when
  executable documentation diverges from behaviour.

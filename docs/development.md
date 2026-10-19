# Development guide

## Repository responsibilities

```text
src/           delivered Ada/SPARK sources and contracts
tests/         executable tests
docs/          central documents: manifesto, terminology, numeric model,
               development plan and guide, perspectives
docs/features/ one page per user-visible operation, with executable bbt
               scenarios
docs/dev/      development procedures (release procedure)
tools/         development scripts
```

Proof contracts and annotations belong with the SPARK sources. Human explanations of proof strategy belong in `docs/`; a separate `proof/` source tree is not used.

## Workflow

```text
Inspect -> specify -> implement -> prove -> test -> document
```

## Commands

The project skeleton should expose these stable entry points:

```sh
make build   # compile the project
make test    # run executable tests
make prove   # run GNATprove (level 2: the daily, fast policy)
make prove+  # escalate unproved checks (level 4: larger solver budgets
             # and counterexamples; proved checks come from the cache)
make check   # run the complete verification chain
make doc     # regenerate the feature diagrams from their topodraw sources
alr test     # build, then run the executable documentation through bbt
```

Proof policy: `make prove` uses level 2 (three provers, short budgets), which
is the policy for day-to-day development. If checks remain unproved, run
`make prove+`: level 4 gives each remaining check a much larger budget and
generates counterexamples, which often suggest the missing intermediate
assertion or a test scenario. GNATprove caches proved checks, so escalation
only re-attempts the failures. Before declaring a milestone complete, the
escalation must leave no unproved check.

## Build profiles

The profiles are selected in `topoproof.gpr` by the `Topoproof_Build_Profile`
external, owned by the project itself (the Alire profile remains unused):

- **development** (default, `make build`): all run-time checks and all
  contracts are verified at execution (`-gnatVa -gnata`). In particular,
  `make test` runs the bbt scenarios against a build where every kernel
  precondition and postcondition is checked dynamically: the executable
  documentation also exercises the contracts.
- **release** (`make release`): the proved kernel units are compiled with
  `-O2 -gnatp`, suppressing the run-time checks whose absence is proved
  (the silver payoff). The command-line interface keeps `-gnatVa`: its
  input validation relies on `Constraint_Error` to reject out-of-domain
  parameters, so its checks are never suppressed.

Three rules keep this sound:

- Run-time check suppression lives in the build configuration only,
  never in the sources: GNATprove honours `pragma Suppress`, so a source
  suppression would stop checking the very property it is meant to
  guarantee.
- The interface validates external input before it enters the kernel,
  so the kernel never receives arguments outside its proved domain.
- The project does not import the Alire-generated configuration:
  pulling it would drag the whole dependency tree (including bbt) into
  the project graph, which confuses GNATprove's binding step.

Each feature page may embed one or more `topodraw` scene sources: statements
in an X, Y, Z frame (`point`, `vector`, `axes`, `ticks`, `anchors`), whose
coordinates are the very literals of the surrounding scenarios. The
sources are wrapped in HTML comments, invisible in the rendered page, and name
their generated SVG file on the first line. `make doc` builds and runs
`tools/topodraw`, an Ada Alire crate compiled by the project toolchain, to
render every scene into a deterministic isometric SVG under
`docs/features/images/`, and fails if a generated file is not referenced
in its page. Update the scenes and their scenarios in the same change.

These commands are operational and require Alire. The toolchain and the tool
crates (`gnat`, `bbt`, `gnatprove`, `gnatformat_bin`) are declared in
`alire.toml` and resolved in the root workspace; the Alire-generated
configuration under `src/Alire_config/` is version-controlled.

## Change acceptance

A change is acceptable only when:

- public operations have explicit contracts;
- numeric bounds are justified;
- no floating-point or epsilon comparison enters the core;
- GNATprove establishes the properties required by the current milestone;
- tests cover observable boundary cases;
- terminology and design documents remain consistent.

## Repository hygiene

Use Ada/GNAT semantic navigation when available. Avoid generated files in version control unless explicitly required. Keep commits focused and update `CHANGELOG.md` once releases begin.

## Executable documentation
SPARK proves contracts and absence of run-time errors. bbt executes the public Markdown documentation against the compiled command-line application. A user-visible operation is incomplete until its Markdown page contains an executable scenario for its canonical output.

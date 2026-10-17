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
make prove   # run GNATprove
make check   # run the complete verification chain
make doc     # regenerate the feature diagrams from their topodraw sources
alr test     # build, then run the executable documentation through bbt
```

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

# Development guide

## Repository responsibilities

```text
src/    delivered Ada/SPARK sources and contracts
tests/  executable tests
docs/   design, rationale, roadmap, and research notes
tools/  development scripts
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
```

Until the project skeleton exists, these commands describe the intended interface and must not be presented as operational.

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

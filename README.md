# TopoProof <!-- omit from toc -->

[![image](https://img.shields.io/badge/-inside-blue?logo=ada&logoColor=white&labelColor=grey&logoSize=auto)](https://ada-lang.io/)
[![Alire](https://img.shields.io/endpoint?url=https://alire.ada.dev/badges/topoproof.json)](https://alire.ada.dev/crates/topoproof.html)
[![Version](https://img.shields.io/badge/dynamic/toml?url=https%3A%2F%2Fraw.githubusercontent.com%2FLionelDraghi%2Ftopoproof%2Fmain%2Falire.toml&query=%24.version&label=latest&style=flat-square)](https://github.com/LionelDraghi/topoproof/blob/main/alire.toml)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg?style=flat-square)](https://opensource.org/licenses/Apache-2.0)

**A provable 3D CAD kernel based on discrete geometry, exact arithmetic, and formal proof.**

TopoProof replaces the historical model of continuous geometry, approximate computation, and tolerances with an explicit discrete model:

- integer grid coordinates;
- deterministic comparisons and exact equality;
- explicit representability domains;
- Ada/SPARK contracts and proofs;
- topological invariants preserved by construction.

Why? Because of one too many of these:
> Job 1, 'freecad&' terminated by signal SIGSEGV

## Contents <!-- omit from toc -->

- [Status](#status)
- [Documentation](#documentation)
- [Licence](#licence)
- [Command-line application and executable documentation](#command-line-application-and-executable-documentation)

## Status

[![CI](https://github.com/LionelDraghi/topoproof/actions/workflows/ci.yml/badge.svg)](https://github.com/LionelDraghi/topoproof/actions/workflows/ci.yml)
[![Tests](docs/tests_results/badge.svg)](docs/tests_results/results.md)
[![SPARK](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2FLionelDraghi%2Ftopoproof%2Fmain%2Fproof-status.json)](docs/dev/development_workflow.md)
[![Coverage](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2FLionelDraghi%2Ftopoproof%2Fmain%2Fcoverage-status.json)](docs/dev/development_workflow.md)

TopoProof targets a provable 3D CAD kernel. The current implementation establishes
the exact 2D predicates and contour foundations required before introducing 3D
topology and B-Rep structures.

## Documentation

- [Manifesto](docs/manifesto.md): vision and founding rationale.
- [Terminology](docs/terminology.md): project vocabulary and conceptual invariants.
- [Numeric model](docs/numeric-model.md): units, numeric domains, representability, and overflow policy.
- [Development plan](docs/dev/development-plan.md): milestones and completion criteria.
- [Development guide](docs/dev/development_workflow.md): repository workflow and verification commands.
- [Release procedure](docs/dev/release_procedure.md): versioning, tagging, GitHub and Alire publication.
- [Perspectives](docs/perspectives.md): non-normative research directions.

## Licence

Apache License 2.0 — see [LICENSE](LICENSE).

## Command-line application and executable documentation

```sh
make build
./bin/topocli run script.topo --output result.txt
./bin/topocli run_code "P : constant Point_3D := (10, -20, 30); Put (P);"
```

Each user-visible operation has one page under `docs/features/`, with its
contract and executable bbt scenarios:

- [Command-line interface](docs/features/command-line.md)
- [Translation](docs/features/translation.md)
- [Displacement](docs/features/displacement.md)
- [Point equality](docs/features/equality.md)
- [Orientation](docs/features/orientation.md)
- [Intersection](docs/features/intersection.md)
- [Contours](docs/features/contours.md)
- [Vertices](docs/features/vertices.md)
- [Edges](docs/features/edges.md)
- [Loops](docs/features/loops.md)
- [Faces](docs/features/faces.md)

`make test` executes the documentation against the compiled application; `make prove` runs SPARK; `make check` runs both.

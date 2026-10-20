# TopoProof

**A provable 3D CAD kernel based on discrete geometry, exact arithmetic, and formal proof.**

TopoProof replaces the historical model of continuous geometry, approximate computation, and tolerances with an explicit discrete model:

- integer grid coordinates;
- deterministic comparisons and exact equality;
- explicit representability domains;
- Ada/SPARK contracts and proofs;
- topological invariants preserved by construction.

Why? Because of one too many of these:
> Job 1, 'freecad&' terminated by signal SIGSEGV

## Contents

- [TopoProof](#topoproof)
  - [Contents](#contents)
  - [Status](#status)
  - [Documentation](#documentation)
  - [Licence](#licence)
  - [Command-line application and executable documentation](#command-line-application-and-executable-documentation)

## Status

TopoProof targets a provable 3D CAD kernel. The current implementation establishes
the exact 2D predicates and contour foundations required before introducing 3D
topology and B-Rep structures.

## Documentation

- [Manifesto](docs/manifesto.md): vision and founding rationale.
- [Terminology](docs/terminology.md): project vocabulary and conceptual invariants.
- [Numeric model](docs/numeric-model.md): units, numeric domains, representability, and overflow policy.
- [Development plan](docs/development-plan.md): milestones and completion criteria.
- [Development guide](docs/development.md): repository workflow and verification commands.
- [Release procedure](docs/dev/release_procedure.md): versioning, tagging, GitHub and Alire publication.
- [Perspectives](docs/perspectives.md): non-normative research directions.

## Licence

Apache License 2.0 — see [LICENSE](LICENSE).

## Command-line application and executable documentation

```sh
alr run -- translate P=(10, -20, 30) D=(5, 7, -9)
alr run -- displacement A=(-1, 2, -3) B=(4, -5, 6)
alr run -- --input request.txt --output result.txt
```

Each user-visible operation has one page under `docs/features/`, with its
contract and executable bbt scenarios:

- [Command-line interface](docs/features/command-line.md)
- [Translation](docs/features/translation.md)
- [Displacement](docs/features/displacement.md)
- [Point equality](docs/features/equality.md)
- [Orientation](docs/features/orientation.md)
- [Intersection](docs/features/intersection.md)

`make test` executes the documentation against the compiled application; `make prove` runs SPARK; `make check` runs both.

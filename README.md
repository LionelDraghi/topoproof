# TopoProof

**A provable 3D CAD kernel based on discrete geometry, exact arithmetic, and formal proof.**

TopoProof replaces the historical model of continuous geometry, approximate computation, and tolerances with an explicit discrete model:

- integer grid coordinates;
- deterministic comparisons and exact equality;
- explicit representability domains;
- Ada/SPARK contracts and proofs;
- topological invariants preserved by construction.

## Status

TopoProof is in its initial development phase. The first deliverable is a complete verified vertical slice covering numeric types, points, vectors, translation, displacement, SPARK contracts, proofs, executable tests, and documentation.

## Development cycle

```text
Specify -> implement -> prove -> test -> document
```

The intended commands are:

```sh
make build
make test
make prove
make check
```

They will be enabled with the initial Alire/SPARK project skeleton.

## Documentation

- [Manifesto](docs/manifesto.md): vision and founding rationale.
- [Terminology](docs/terminology.md): project vocabulary and conceptual invariants.
- [Numeric model](docs/numeric-model.md): units, numeric domains, representability, and overflow policy.
- [Development plan](docs/development-plan.md): milestones and completion criteria.
- [Development guide](docs/development.md): repository workflow and verification commands.
- [Perspectives](docs/perspectives.md): non-normative research directions.

## Licence

To be defined.

## Command-line application and executable documentation

```sh
alr run -- translate 10 -20 30 5 7 -9
alr run -- displacement -1 2 -3 4 -5 6
alr run -- --input request.txt --output result.txt
```

Each mathematical operation is documented in Markdown with executable bbt scenarios:

- [Command-line interface](docs/command-line.md)
- [Translation](docs/translation.md)
- [Displacement](docs/displacement.md)

`make test` executes the documentation against the compiled application; `make prove` runs SPARK; `make check` runs both.

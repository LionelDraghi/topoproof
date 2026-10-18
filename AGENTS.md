# AGENTS.md

TopoProof is a provable 3D CAD kernel based on discrete geometry, exact integer arithmetic, and formal proofs in Ada/SPARK.

## Read first

1. `README.md`
2. `docs/manifesto.md`
3. `docs/terminology.md`
4. `docs/numeric-model.md`
5. `docs/development-plan.md`
6. `docs/development.md`
7. `docs/perspectives.md`

## Mandatory rules

- Geometry is discrete.
- Do not use floating-point arithmetic in the core kernel.
- Do not use epsilon-based comparisons.
- Proofs come before additional features.
- Every public operation requires explicit contracts.
- SPARK compatibility is mandatory.
- Use the project terminology consistently.
- Distinguish `Point` from `Vertex`.
- Distinguish `Grid_Coordinate` from `Vector_Component`.
- Do not implement research perspectives before they enter the development plan.
- Never commit without the owner's review: stage the change, present it, and wait for explicit approval.

## Development discipline

```text
Inspect -> specify -> implement -> prove -> test -> document
```

Before considering a change complete, run:

```sh
make build
make test
make prove
make check
```

Do not add a public operation without a contract. Keep each change within the current milestone. Justify all numeric bounds. Prefer Ada/GNAT semantic tools over textual search when inspecting declarations and references.

## Executable documentation
- TopoProof is an application, not a library product.
- Every user-visible mathematical operation has one Markdown page in `docs/` with its exact input/output contract and executable bbt scenarios.
- Exercise the compiled executable through command-line arguments or `--input FILE`; use standard output or `--output FILE` for results.
- Keep output deterministic and line-oriented. Diagnostics go to standard error and failures return non-zero status.
- `make test` means black-box execution of the Markdown documentation through bbt.
- Update behaviour and its Markdown scenario in the same change.
- Prefer Ada Language Server for semantic navigation and symbol references.

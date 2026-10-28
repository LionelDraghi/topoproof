# AGENTS.md

TopoProof is a provable 3D CAD kernel based on discrete geometry, exact integer arithmetic, and formal proofs in Ada/SPARK.

**Before any other action, read the shared template referenced below
and follow it.**

The shared rules for Lionel's Ada projects live in the [reference repository on GitHub](https://github.com/LionelDraghi/ada-project-template/blob/main/AGENTS.md) and apply here in full: non-negotiable git rules (in brief: no `git add`, commit, push, tag, release or Alire publish without the owner's explicit, post-review consent), procedure choice, reference policy, skills, Ada tooling (Serena MCP first). This file keeps only what is specific to TopoProof. The owner reviews files in the source control tool; a file validated there is approved.

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

## Development discipline

```text
Inspect -> specify -> implement -> prove -> test -> document
```

During development, run the target of the step under work: `make build`,
`make test` or `make prove`; `make check` chains the three at once, so
running the four commands in sequence is redundant, since `check` is
`build` + `test` + `prove`.

Before considering a change complete, run the complete chain from a
clean state:

```sh
make clean
make all
```

Do not add a public operation without a contract. Keep each change within the current milestone. Justify all numeric bounds. Prefer Ada/GNAT semantic tools over textual search when inspecting declarations and references.

## Build pointers

The shared build pointers apply ([reference repository on GitHub](https://github.com/LionelDraghi/ada-project-template/blob/main/AGENTS.md)); `make help` is the documentation of record. TopoProof specifics:

- `make test`: build, then run the Markdown documentation in `docs/features` through bbt, then validate every generated diagram as XML; the results log and badge evidence go to `artifacts/`.
- `make prove`: run GNATprove on every kernel unit (`-U`, level 2) and validate the proof evidence; `make prove+` escalates to level 4 with counterexamples.
- `make check`: build, test, prove and validate the evidence — the complete verification chain; `make all` is the same target (deviation: `all` covers no doc, since TopoProof executes its documentation instead of generating it).
- `make release`: build with the release profile (run-time checks suppressed on the proved kernel, kept on the client).
- `make format`: reformat the Ada sources with GNATformat.
- No `doc` and no `install` target: TopoProof is a library, its documentation is executed by `test`.

## Conditional readings

Read a document only when the task requires it; do not open them all up front.

- To plan any change, place work in a milestone, or check what comes next: `docs/dev/development-plan.md`
- To choose the next task or find already-tracked work: `docs/dev/concerns.md` and `docs/roadmap.md`
- To follow the development workflow: `docs/dev/development_workflow.md`
- To prepare or run a release: the [common release procedure on GitHub](https://github.com/LionelDraghi/ada-project-template/blob/main/release_procedure.md), with the TopoProof parameters and additions in `docs/dev/release_procedure.md`
- To write, convert or debug bbt scenarios: the bbt skill, installed from GitHub (`npx skills add LionelDraghi/bbt --skill bbt-skill`)
- To make, review or challenge a design decision: `docs/dev/design_discussions.md`
- To understand the project's goals and philosophy: `docs/manifesto.md`, `README.md`
- To write or review any text using the project's terms (`Point`, `Vertex`, `Grid_Coordinate`, `Vector_Component`, ...): `docs/terminology.md`
- To touch arithmetic, coordinates, bounds, or any numeric reasoning: `docs/numeric-model.md`
- To check whether a research idea is committed work: `docs/perspectives.md` — non-normative; never implement it before it enters the development plan.

## Executable documentation

> **Doc is code**, not merely docs-as-code: public behaviour, examples, diagrams,
> contracts, and bbt scenarios form one reviewed change. Documentation divergence
> is a functional defect and blocks integration.

- `TopoProof` is a library. `topocli` is the test driver.
- Every user-visible mathematical operation has one Markdown page in `docs/` with its exact input/output contract and executable bbt scenarios.
- Exercise the compiled executable through command-line arguments or `--input FILE`; use standard output or `--output FILE` for results.
- Keep output deterministic and line-oriented. Diagnostics go to standard error and failures return non-zero status.
- `make test` means black-box execution of the Markdown documentation through bbt.
- Update behaviour and its Markdown scenario in the same change.

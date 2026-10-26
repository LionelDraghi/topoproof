# AGENTS.md — TopoGUI

TopoGUI is the user-facing application of TopoProof: a thin GUI client
over the proved kernel, reached through the single TopoScript front-end
(`topocli run`). Its authority is DD-006 in the TopoProof repository
(`docs/dev/design_discussions.md`).

TopoGUI lives in `tools/topogui` and has the vocation to split from the
TopoProof repository as its own project. Everything TopoGUI needs to
work independently (documentation, tests, project rules) lives here.

## Mandatory rules

- The shared TopoProof rules (`AGENTS.md` at the repository root) apply
  in full: discrete geometry, exact integer arithmetic, no epsilon,
  SPARK compatibility of anything that enters the kernel, explicit
  contracts.
- The GUI never re-implements or bypasses the proved kernel: every
  geometric decision comes from the kernel through the TopoScript
  front-end.
- Nothing that serves future TopoProof kernel functions is developed
  here: such work enters the TopoProof development plan instead
  (DD-006, repartition rule). Only GUI concerns live in this directory.
- Every kernel rejection surfaced by the GUI is displayed verbatim:
  no reinterpreted, softened, or approximate diagnostic.

## Testing policy

- Headless testing uses HAC and TopoScript as far as possible: the
  logic that drives the kernel is tested through `topocli run`, like
  the TopoProof executable documentation.
- The GUI itself has no "run the doc" harness. The project delivers
  the executable; the owner tests it manually.
- The MCP interface eases automated GUI testing; use it before
  resorting to manual checks.
- No visual regression infrastructure is built until a real need is
  demonstrated.

## Toolkit

- Adi2 first. This choice is not definitive; the view-model code keeps
  the toolkit dependency contained so it can be revisited.

## Development discipline

```text
Inspect -> specify -> implement -> test (headless first) -> document
```

- The proof step of the kernel discipline does not apply inside
  TopoGUI: nothing here is proved, everything here is tested.
- The development plan of TopoGUI is `docs/dev/development-plan.md` in
  this directory. It tracks user-facing versions (v0, v1), not kernel
  milestones.
- Product scope is set by DD-006: v0 is 2D drawing; v1 is extrusion
  plus the direct creation of a rectangular parallelepiped and a
  cylinder; v2 (candidate, not committed) may attack the fusion of
  arbitrary volumes.

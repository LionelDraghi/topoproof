# AGENTS.md — TopoGUI

TopoGUI is the user-facing application of TopoProof: a thin GUI client
over the proved kernel, reached through the single TopoScript front-end
(`topocli run`). Its authority is DD-006 in the TopoProof repository
(`docs/dev/design_discussions.md`).

TopoGUI lives in `tools/topogui` and has the vocation to split from the
TopoProof repository as its own project. Everything TopoGUI needs to
work independently (documentation, tests, project rules) lives here.

## Shared instructions

The shared rules of Lionel's Ada projects apply in full:
[ada-project-template/AGENTS.md](https://github.com/LionelDraghi/ada-project-template/blob/main/AGENTS.md).
**Read them immediately, before any other reading or any action.** The
TopoProof `AGENTS.md` at the repository root carries the project-level
rules and applies here too; this file keeps only what is specific to
TopoGUI.

The development lifecycle is the shared one — Explore, Propose,
Implement, Refactor, Finalize, Release — detailed in
[lifecycle.md](https://github.com/LionelDraghi/ada-project-template/blob/main/lifecycle.md)
and specialized for TopoGUI in
[development_workflow.md](docs/dev/development_workflow.md). One skill
per phase: `explore`, `propose`, `implement`, `refactor`, `finalize`,
`release`; `next-task` when the next work is unclear. Read the current
`SKILL.md` of a skill before using it, never a remembered copy.

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

## Project identity

- Name: TopoGUI
- Purpose: the user-facing graphical client of the proved TopoProof
  kernel, driven through the single TopoScript front-end
- Primary language: Ada, on the Adi2 toolkit

## Enabled capabilities

| Capability | Enabled | Project parameter, if any |
|---|---:|---|
| bbt executable specifications | no | no CLI surface of its own; the kernel-facing logic is headless-tested through `topocli run` |
| Unit tests | no | the GUI deliverable is the executable; the owner tests it manually |
| SPARK analysis | no | nothing here enters the kernel |
| Formal proof | no | the kernel carries the proofs |
| Static analysis / metrics | no | warnings are errors on every build |
| Alire release | no | local crate, never published; dev versions `x.y.z-dev` |
| Platform packages | no | Linux first |

## Project commands

- Build (development profile, the MCP introspection module live):
  `alr exec -- gprbuild -s -j0 -XADI_BUILD_PROFILE=development
  -XADI_PLATFORM=linux -XTopogui_Build_Profile=development -P topogui.gpr`
- Build (default profile): `alr build`
- Run: `./topogui`
- Inspection and driving of the running application: the MCP channel
  `/tmp/adi_mcp/<pid>/` with the adi2 crate's
  `tools/adi_mcp_server.py` (`widget_tree`, `screenshot`,
  `click_widget`, `css_values`, ...); see `README.md`.

## Project-specific paths

- Development plan (product scope, v0, v1): `docs/dev/development-plan.md`
- Drawing model (session, gestures, kernel arbitration): `docs/dev/drawing-model.md`
- Design tokens (the visual direction): `src/topogui-theme.ads`

## Exceptions

- The kernel discipline step "prove" does not apply: nothing here is
  proved, everything here is tested. The full reasoning and the testing
  policy are in `docs/dev/development_workflow.md`.
- No bbt harness and no `docs/features/` pages: the GUI deliverable is
  the executable, tested headlessly through TopoScript and manually by
  the owner.

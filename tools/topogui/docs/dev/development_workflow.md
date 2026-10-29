# Development workflow — TopoGUI

This project follows the shared lifecycle — Explore, Propose,
Implement, Refactor, Finalize, Release — defined in the reference
repository's
[lifecycle.md](https://github.com/LionelDraghi/ada-project-template/blob/main/lifecycle.md).
Read it before any work; this file only records what is specific to
TopoGUI.

## Project conventions

- Quick validation: the development-profile build, warnings as errors:
  `alr exec -- gprbuild -s -j0 -XADI_BUILD_PROFILE=development
  -XADI_PLATFORM=linux -XTopogui_Build_Profile=development -P topogui.gpr`
  (`alr build` covers the default profile only).
- Full validation: the development build, the MCP-driven inspection of
  the running application (widget tree, screenshots, synthesized
  clicks on the `/tmp/adi_mcp/<pid>/` channel — `README.md` for the
  server invocation), and the headless TopoScript check of every
  kernel-facing logic change: the exact replay script the GUI would
  execute, run under `topocli run`.
- Domain rules the agent must know: the kernel is never re-implemented
  or bypassed (DD-006, repartition rule); every kernel rejection is
  displayed verbatim; a kernel gap discovered here becomes a TopoProof
  development-plan item, never TopoGUI code.

## Phase adaptations

- **Explore, Propose:** the candidate specifications live in
  `docs/proposed/` (the directory is created with the first proposal);
  the product scope — v0, v1, the visual direction included — is set
  by `docs/dev/development-plan.md` and only that file commits it. A
  pure-view change (theme, layout) needs no executable scenario; a
  kernel-facing behaviour change is specified by the replay script it
  must produce.
- **Implement:** the proof obligations of the shared workflow do not
  apply — nothing in TopoGUI is proved, everything is tested. The
  verification is the build, the headless replay of the changed
  construction logic, and the MCP-driven check of the changed
  interaction. The user-visible behaviour and its documentation
  (`drawing-model.md`, or the development plan) change together, in
  the same change. No visual regression infrastructure is built until
  a real need is demonstrated; the MCP screenshots are development
  evidence, not a regression suite.
- **Refactor:** the view keeps the toolkit dependency contained
  (`topogui-theme.ads`, the canvas being the one Adi2-heavy unit); a
  refactor that leaks toolkit types into the session or the kernel
  driver fails this phase.
- **Finalize:** the durable specifications are the development plan
  and the drawing model; the changelog (below) is updated; no
  `docs/features/` page exists here — the TopoProof documentation
  covers the kernel operations the GUI calls.
- **Release:** TopoGUI is never published to Alire. A release is the
  version bump of `alire.toml` (`x.y.z-dev` to `x.y.z`) with its
  changelog section closed; the delivery gate is the owner's manual
  test of the executable, assisted by the MCP channel.

## Conditional readings

- To know what to build next, or the product scope: `docs/dev/development-plan.md`
- To touch the session, the gestures, or the kernel arbitration: `docs/dev/drawing-model.md`
- To change the visual direction, or add a design token: the development plan, section "Visual direction", and `src/topogui-theme.ads`
- To inspect or drive the running application: `README.md`, section "Development profile and MCP introspection"
- To decide what belongs where (GUI vs kernel): DD-006 in the TopoProof `docs/dev/design_discussions.md`

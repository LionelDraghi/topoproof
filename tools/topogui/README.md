# TopoGUI

Graphical client of the TopoProof kernel (DD-006). Thin GUI over the
proved kernel, driven through the single TopoScript front-end; see
`AGENTS.md` for the rules and `docs/dev/development-plan.md` for the
product plan.

## Build and run

```sh
cd tools/topogui
alr build
../../bin/topogui
```

## System prerequisites

- SDL3, SDL3_ttf, SDL3_image: installed as the distribution packages
  `libsdl3-dev`, `libsdl3-ttf-dev`, `libsdl3-image-dev`.
- Adi2 is not published to the community index yet: the crate pins it
  to its repository at a fixed commit.

## Development profile and MCP introspection

`alr build` compiles the adi2 dependency in release profile, where the
MCP introspection module is a stub. For a development build that
answers the MCP channel (widget tree, screenshots, synthesized
clicks):

```sh
alr exec -- gprbuild -s -j0 -XADI_BUILD_PROFILE=development \
  -XADI_PLATFORM=linux -XTopogui_Build_Profile=development -P topogui.gpr
```

While the application runs, the channel lives under
`/tmp/adi_mcp/<pid>/`; the server is the adi2 crate's
`tools/adi_mcp_server.py`:

```sh
python3 $ADI2_TOOLS/adi_mcp_server.py --cli --pid <PID> widget_tree
python3 $ADI2_TOOLS/adi_mcp_server.py --cli --pid <PID> screenshot
```

See the testing policy in `AGENTS.md`.

# Topodraw

Topodraw renders small 3D scene scripts embedded in Markdown files as
deterministic isometric SVG diagrams. It exists to keep the TopoProof
feature documentation executable and readable: every diagram in
`docs/features` is generated from a scene written next to the text that
explains it.

## Usage

From the TopoProof root, regenerate all feature diagrams:

```sh
make doc
```

or run the tool directly on one or more Markdown files:

```sh
topodraw FILE [FILE ...]
```

Each file is scanned for scene comments; the tool reports each generated
diagram and the total count on standard output. Any scene error is
reported on standard error with the failing scene line number, and the
exit status is a failure.

## Scene source

A scene is an HTML comment whose first line names the SVG file to
generate:

```text
<!-- topodraw images/example.svg
axes
ticks 1
anchors
point A 0 0 0
point B 2 0 0
vector A B (2, 0)
-->

![Example](images/example.svg)
```

Rules:

- one scene per comment, and one diagram per scene;
- the scene source must not contain `--`, which would close the comment;
- the generated file must be referenced elsewhere in the same page
  (typically the `![...](...)` image line right below), otherwise the
  scene is rejected;
- the coordinates are plain integers, possibly negative, and several
  points may share one position.

Statements, one per line:

- `axes`: draw the three axes (no argument);
- `ticks STEP`: draw tick marks along the axes every STEP units; STEP
  must be positive, and this statement implies `axes`;
- `anchors`: draw the dashed coordinate paths of each point (no
  argument);
- `point NAME X Y Z`: declare a named position;
- `vector FROM TO LABEL`: draw an arrow from point FROM to point TO;
  both points must be declared, distinct, and LABEL is free text, by
  convention the displacement or the segment name.

## Rendering

The renderer projects the scene isometrically and normalizes it by the
largest coordinate magnitude, so a scene on the grid corners
(+/-2**30) renders at the same scale as a scene on a unit square. The
output is deterministic: the same scene source always produces the same
SVG file.

# TopoScript

> **Status: proposed (Milestone 6).** TopoScript is not implemented yet.
> This page is not registered in the `make test` scenario list, and its
> scenario blocks describe the intended structure without authorising a
> change to the bbt language. The step wording is arbitrated in
> `DD-003`.

TopoScript is a lightweight Ada-based scripting facility, implemented with
HAC, for two complementary uses: readable executable inputs for bbt
scenarios, and the future language for user macros, modules, and extensions.
TopoScript complements the graphical user interface; it does not turn
TopoProof into an Ada equivalent of OpenSCAD. The HAC interpreter and its
Ada subset are presented in
[Ada and a mini-Ada interpreter, FOSDEM 2025](https://github.com/zertovitch/hac/blob/master/doc/ada_mini_ada_fosdem_2025.pdf).

## Contents

- [Source form](#source-form)
- [Use in bbt scenarios](#use-in-bbt-scenarios)
- [Observable result and verdict](#observable-result-and-verdict)
- [Output contract](#output-contract)
- [Diagnostic drawing](#diagnostic-drawing)
- [User macros and extensions](#user-macros-and-extensions)
- [CLI direction](#cli-direction)

## Source form

A TopoScript contains Ada declarations followed by Ada statements, without
compilation-unit boilerplate:

```ada
P      : constant Point_3D := Point (10, -20, 30);
D      : constant Vector_3D := Vector (5, 7, -9);
Result : Point_3D;

Result := Translate (P, D);

Put (Result);
```

The user does not write:

```ada
with ...;
use ...;

procedure ... is
begin
   ...
end ...;
```

`topocli` generates that wrapper before passing the complete source to HAC.
Names may remain qualified where qualification improves clarity or removes
ambiguity:

```ada
STEP_Files.Export (P, "piece.step");
```

TopoScript preserves ordinary Ada notation, including:

- `:=` for assignment;
- `=>` for named associations;
- `;` as the statement terminator;
- `--` for comments;
- explicit types and constants;
- the control structures supported by the selected HAC subset.

Declarations must precede executable statements: a declaration appearing
after the first executable statement is rejected.

## Use in bbt scenarios

The TopoScript source is embedded directly in a `Given` step, because the
scenario must remain self-contained. The temporary, scenario-local `.topo`
file is an execution artefact produced from the embedded block; it is not a
separately maintained test source.

The intended scenario structure is:

````markdown
## Scenario: translate command-line values

- Given the file `translation.topo` contains:
  ```ada
  P      : constant Point_3D := Point (10, -20, 30);
  D      : constant Vector_3D := Vector (5, 7, -9);
  Result : Point_3D;

  Result := Translate (P, D);

  Put (Result);
  ```

- When I successfully run `../bin/topocli run translation.topo`
- Then the output is `point 15 -13 21`
````

The exact wording of the `Given` and execution steps must be selected from
syntax already supported by bbt (see `DD-003`).

## Observable result and verdict

The script computes the actual result and writes its canonical textual
representation:

```ada
Put (Result);
```

The scenario retains the expected value:

```markdown
- Then the output is `point 15 -13 21`
```

This separation is mandatory:

- TopoScript defines the input and performs the operation;
- `Put` exposes the actual observable result;
- the bbt scenario defines the expected result;
- bbt compares actual and expected values and determines the verdict.

TopoScript introduces no parallel assertion framework such as `Check.Equal`
for these scenarios.

## Output contract

Script execution preserves a stable separation between outputs:

- standard output contains the canonical value inspected by bbt;
- standard error contains diagnostics and execution errors;
- generated files contain optional visual or model artefacts;
- the process status reports successful or failed execution.

Diagnostic messages must not pollute the canonical value written to standard
output. Known TopoProof failures remain observable through the same textual
and process-status conventions used by existing bbt scenarios.

## Diagnostic drawing

A TopoScript may generate a single diagnostic image containing all useful
elements of the scenario:

```ada
P        : constant Point_3D := Point (10, -20, 30);
D        : constant Vector_3D := Vector (5, 7, -9);
Expected : constant Point_3D := Point (15, -13, 21);
Result   : Point_3D;

Drawing.Begin_Image ("translation.svg");
Drawing.Draw_Axes;
Drawing.Draw_Point (P, Color => Blue);
Drawing.Draw_Vector (Origin => P, Value => D, Color => Blue);
Drawing.Draw_Point (Expected, Color => Green);

Result := Translate (P, D);

Drawing.Draw_Point (Result, Color => Red);
Drawing.End_Image;

Put (Result);
```

In this example, `Expected` is used only to explain the scenario visually. It
does not determine the test verdict; the expected textual result remains in
the bbt `Then` step. This replaces multiple disconnected image-generation
commands with one script-controlled scene and makes failures easier to
diagnose.

## User macros and extensions

The same TopoScript language should later be usable in standalone `.topo`
files for user automation:

```ada
P : Shape;

P := Box (100, 50, 20);
P := Fillet (P, Radius => 5);
Model.Add (P);
```

The example above is illustrative: `Shape`, `Box`, `Fillet`, and `Model` do
not exist yet. The first implementation avoids designing GUI metadata or a
complete plugin lifecycle; those concerns can be added after script execution
and the scripting API are stable.

## CLI direction

The intended command form is:

```text
topocli run FILE.topo
```

For bbt, `FILE.topo` is created by an existing `Given` step from the source
embedded in the scenario. Useful diagnostic options may later include:

```text
topocli run FILE.topo --show-generated-source
topocli check FILE.topo
```

These options are suggestions, not requirements for the first increment.

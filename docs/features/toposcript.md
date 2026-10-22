# TopoScript <!-- omit from toc -->

> **Status: implemented (Milestone 6).** `topocli run FILE.topo` executes
> a TopoScript through the embedded HAC interpreter. The scenario blocks
> of this page are run by `make test`, like every feature page under
> `docs/features/`. The arbitration record lives in `DD-003`.

TopoScript is a lightweight Ada-based scripting facility, implemented with
HAC, for two complementary uses: readable executable inputs for bbt
scenarios, and the future language for user macros, modules, and
extensions. TopoScript complements the graphical user interface; it does
not turn TopoProof into an Ada equivalent of OpenSCAD. The HAC interpreter
and its Ada subset are presented in
[Ada and a mini-Ada interpreter, FOSDEM 2025](https://github.com/zertovitch/hac/blob/master/doc/ada_mini_ada_fosdem_2025.pdf).

## Contents <!-- omit from toc -->

- [Source form](#source-form)
- [Observable result and verdict](#observable-result-and-verdict)
- [Output contract](#output-contract)
- [Scripting API](#scripting-api)
- [Standalone scripts](#standalone-scripts)
- [Scenarios](#scenarios)
- [Scenario: translate a point and a vector](#scenario-translate-a-point-and-a-vector)
- [Scenario: reject an unrepresentable translation](#scenario-reject-an-unrepresentable-translation)
- [Scenario: reject a declaration after the first statement](#scenario-reject-a-declaration-after-the-first-statement)
- [Scenario: draw the diagnostic image of the translation](#scenario-draw-the-diagnostic-image-of-the-translation)
- [Diagnostic drawing](#diagnostic-drawing)
- [User macros and extensions](#user-macros-and-extensions)
- [CLI direction](#cli-direction)

## Source form

A TopoScript contains object declarations followed by executable
statements, without compilation-unit boilerplate:

```ada
P      : constant Point_3D := (10, -20, 30);
D      : constant Vector_3D := (5, 7, -9);
Result : Point_3D;

Translate (P, D, Result);

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

`topocli` generates that wrapper before passing the complete source to
HAC. The scripting API (`Point_3D`, `Vector_3D`, the operations) is
injected before the user declarations: HAC imports native procedures
only, so each operation returns its result through an `out` parameter,
and `Put` writes the canonical representation of its value natively,
the same one as the other topocli operations.

TopoScript preserves ordinary Ada notation, including:

- `:=` for assignment;
- `=>` for named associations, in aggregates; the calls to the
  scripting operations are positional, like every native operation;
- `;` as the statement terminator;
- `--` for comments;
- explicit types and constants;
- the control structures supported by the selected HAC subset.

Declarations must precede executable statements: a declaration appearing
after the first executable statement is rejected before any compilation,
and so are the declaration forms the initial subset does not cover.

## Observable result and verdict

The script computes the actual result and writes its canonical textual
representation:

```ada
Put (Result);
```

The scenario retains the expected value. This separation is mandatory:

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
- the process status reports successful or failed execution.

Diagnostic messages must not pollute the canonical value written to
standard output. Compilation diagnostics refer to the fragment: the
path, the line and the column are the ones of the `.topo` source, not
of the generated wrapper.

## Scripting API

The wrapper injects the following declarations ahead of every
fragment. They are the initial stable scripting API of the milestone;
the compatibility-versioning question stays open in `DD-003`.

Types:

| type | values |
|------|--------|
| `Point_3D`, `Vector_3D`, `Point_2D` | grid values, built from integer aggregates |
| `Color_Kind` | `Blue`, `Green`, `Red` |
| `Loop_Kind` | `Counter_Clockwise`, `Clockwise`, `Degenerate`, or the kernel rejection kinds |
| `Face_Kind` | `Face_Counter_Clockwise`, `Face_Clockwise`, `Face_Degenerate_Boundary`, `Face_Invalid_Boundary` |

Operations:

| operation | effect |
|-----------|--------|
| `Translate (P, V, Result)` | runs the proved `Translate` on the point `P` and the vector `V` |
| `Put (P)` | writes `point X Y Z` on standard output |
| `Add_Point (P)` | appends a 2D point to the chain |
| `Make_Loop (K)` | classifies the accumulated chain as a loop, the kernel classification |
| `Make_Face (K)` | classifies the same chain as a face boundary |
| `Put_Loop (K)` | writes `loop closed ...`, or records the rejection diagnostic |
| `Put_Face (K)` | writes `face ...`, or records the rejection diagnostic |
| `Begin_Image (Name)` | opens one image under the `VString` name |
| `Draw_Axes` | axes with automatic ticks and dashed coordinate paths |
| `Draw_Point (P, Color)` | colors a 3D point of the image |
| `Draw_Vector (Origin, Value, Color)` | draws the labeled arrow of the vector |
| `Draw_Point_2D (P, Color)` | colors a 2D point of the image |
| `Draw_Edge (P, Q, Color)` | draws the labeled segment arrow from `P` to `Q` |
| `End_Image` | renders the image through the topodraw renderer |

The rejected operations record the same diagnostics as the client
operations, on standard error, and the process status carries the
verdict.

## Standalone scripts

The scenarios of this page are one use of TopoScript; any `.topo`
fragment runs the same way outside the test suite:

```text
topocli run FILE.topo
```

The output contract holds identically: the canonical values go to
standard output, the diagnostics to standard error with the fragment
path, line and column, and the process status carries the verdict.

## Scenarios

The scenario embeds the TopoScript in a `Given` step: the temporary
`.topo` file is an execution artefact produced by bbt, not a separately
maintained test source.

## Scenario: translate a point and a vector

- Given the file `translate.topo`
  ```ada
  P      : constant Point_3D := (10, -20, 30);
  D      : constant Vector_3D := (5, 7, -9);
  Result : Point_3D;

  Translate (P, D, Result);

  Put (Result);
  ```
- When I successfully run `../bin/topocli run translate.topo`
- Then the output is `point 15 -13 21`

## Scenario: reject an unrepresentable translation

The point starts on the corner of the grid; the translation would move
it one unit beyond the largest representable position.

- Given the file `translate_beyond.topo`
  ```ada
  P      : constant Point_3D := (1073741823, 0, 0);
  D      : constant Vector_3D := (1, 0, 0);
  Result : Point_3D;

  Translate (P, D, Result);

  Put (Result);
  ```
- When I run `../bin/topocli run translate_beyond.topo`
- Then the error output is `error: translation is not representable`
- And there is an error

## Scenario: reject a declaration after the first statement

The wrapper rejects the fragment before any compilation: declarations
must precede the executable statements.

- Given the file `late_declaration.topo`
  ```ada
  P : constant Point_3D := (10, -20, 30);

  Put (P);

  Q : Point_3D;
  ```
- When I run `../bin/topocli run late_declaration.topo`
- Then the error output is
  ```text
  error: late_declaration.topo:5: declaration after the first executable statement
  ```
- And there is an error

## Scenario: draw the diagnostic image of the translation

The script draws one image containing the axes, the input geometry
(`P`, blue), the expected result (`Expected`, green) and the actual
result (`Result`, red on the same position): a failure is immediately
visible. The image is a generated file: the canonical standard output
carries the result only.

- Given the file `translate_draw.topo`
  ```ada
  P        : constant Point_3D := (10, -20, 30);
  D        : constant Vector_3D := (5, 7, -9);
  Expected : constant Point_3D := (15, -13, 21);
  Result   : Point_3D;
  Name     : VString := +"../docs/features/images/toposcript_1.svg";

  Begin_Image (Name);
  Draw_Axes;
  Draw_Point (P, Blue);
  Draw_Vector (P, D, Blue);
  Draw_Point (Expected, Green);

  Translate (P, D, Result);

  Draw_Point (Result, Red);
  End_Image;

  Put (Result);
  ```
- When I successfully run `../bin/topocli run translate_draw.topo`
- Then the output is `point 15 -13 21`
- And the file `../docs/features/images/toposcript_1.svg` contains `#cf222e`  
  (The `#cf222e` value is the red of `Color_Kind`: the check ensures the
  actual result point, the target of the scenario, is drawn red.)

![Diagnostic image of the translation](images/toposcript_1.svg)

## Diagnostic drawing

A script generates one diagnostic image through the drawing API,
rendered by the topodraw renderer:

```ada
P        : constant Point_3D := (10, -20, 30);
D        : constant Vector_3D := (5, 7, -9);
Expected : constant Point_3D := (15, -13, 21);
Result   : Point_3D;
Name     : VString := +"translation.svg";

Begin_Image (Name);
Draw_Axes;
Draw_Point (P, Blue);
Draw_Vector (P, D, Blue);
Draw_Point (Expected, Green);

Translate (P, D, Result);

Draw_Point (Result, Red);
End_Image;

Put (Result);
```

In this example, `Expected` is used only to explain the scenario visually. It
does not determine the test verdict; the expected textual result remains in
the bbt `Then` step. The image name is a `VString` variable: HAC passes
strings by reference, and the calls to the operations are positional. The
2D chain scenarios draw through `Draw_Point_2D` and `Draw_Edge`, the
labeled segment arrows of the client diagrams.

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

The command form is:

```text
topocli run FILE.topo
```

Useful diagnostic options may later include:

```text
topocli run FILE.topo --show-generated-source
topocli check FILE.topo
```

These options are suggestions, not requirements for the next increments.

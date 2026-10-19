# Displacement

`displacement` computes the exact vector between two points: `topoproof displacement AX AY AZ BX BY BZ`.
The canonical result is `vector DX DY DZ`.

The diagram shows the geometry of the first scenario below: point `A`, point `B`,
and the displacement `D = B - A` with the coordinates of the test inputs and
outputs.

<!-- topodraw images/displacement_1.svg
axes
ticks 5
anchors
point A -1 2 -3
point B 4 -5 6
vector A B (5, -7, 9)
-->

![Displacement diagram](images/displacement_1.svg)

## Contents

- [Scenario: compute command-line values](#scenario-compute-command-line-values)
- [Scenario: inject parameters from an input file](#scenario-inject-parameters-from-an-input-file)
- [Scenario: read and write files](#scenario-read-and-write-files)

## Scenario: compute command-line values

![Displacement diagram](images/displacement_1.svg)

- When I successfully run `../bin/topoproof displacement -1 2 -3 4 -5 6`
- Then the output is `vector 5 -7 9`

## Scenario: inject parameters from an input file
- Given the new file `displacement.in` containing `displacement 10 20 30 13 18 37`
- When I successfully run `../bin/topoproof --input displacement.in`
- Then the output is `vector 3 -2 7`

## Scenario: read and write files
- Given the new file `displacement-file.in` containing `displacement 0 0 0 -4 5 -6`
- And there is no file `displacement-file.out`
- When I successfully run `../bin/topoproof --input displacement-file.in --output displacement-file.out`
- Then the `displacement-file.out` file contains `vector -4 5 -6`

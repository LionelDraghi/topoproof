# Command-line interface

TopoProof exposes proved operations through a stable black-box interface. Parameters may be passed directly or in a file containing one command. Results go to standard output by default, or to `--output FILE`, which receives every result line of the run, in order.

## Scenario: display help
- When I successfully run `../bin/topocli --help`
- Then the output contains `usage: topocli`
- And the output contains `operations: translate, displacement, equal, orientation, intersect`

## Scenario: --output receives the whole multi-line result

The file is created once per run and accumulates the canonical output:
a multi-line result is complete, not reduced to its last line.

- When I successfully run `../bin/topocli vertex A=(0, 0) B=(1, 1) C=(2, 3) --output vertices.out`
- Then the file `vertices.out` is
   ```text
   vertex 1 point 0 0
   vertex 2 point 1 1
   vertex 3 point 2 3
   ```

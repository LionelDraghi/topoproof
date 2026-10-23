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

## Scenario: inject parameters from an input file

The command form reads one command from a file passed with `--input`.

- Given the new file `displacement.in` containing `displacement A=(10, 20, 30) B=(13, 18, 37)`
- When I successfully run `../bin/topocli --input displacement.in`
- Then the output is `vector 3 -2 7`

## Scenario: read and write files

The command form reads its command from `--input` and writes the
canonical result to `--output`.

- Given the new file `displacement-file.in` containing `displacement A=(0, 0, 0) B=(-4, 5, -6)`
- And there is no file `displacement-file.out`
- When I successfully run `../bin/topocli --input displacement-file.in --output displacement-file.out`
- Then the `displacement-file.out` file contains `vector -4 5 -6`

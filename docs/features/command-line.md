# Command-line interface

TopoProof exposes proved operations through a stable black-box interface. Parameters may be passed directly or in a file containing one command. Results go to standard output by default, or to `--output FILE`.

## Scenario: display help
- When I successfully run `../bin/topoproof --help`
- Then the output contains `usage: topoproof`
- And the output contains `operations: translate, displacement, equal, orientation, intersect`

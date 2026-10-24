# Command-line interface <!-- omit from toc -->

`topocli` is the runner of the executable documentation: every proved
operation is a script operation, run from a file or inline. The command
form of the operations is retired (DD-004): the runner has two entries
only, and the output file of the canonical results is their single
option.

```text
topocli run FILE.topo [--output FILE]
topocli run_code FRAGMENT [--output FILE]
```

`run` executes a TopoScript source file; `run_code` executes an inline
fragment, split into lines at every semicolon, so the same command line
runs on every platform. `--output FILE` receives every canonical result
line of the run, in order; without it, the results go to the standard
output. The scenarios of each operation page and of
[toposcript.md](toposcript.md) exercise the two entries; this page owns
the runner contract itself.

## Contents <!-- omit from toc -->

- [Scenario: display help](#scenario-display-help)
- [Scenario: a command-line operation is rejected](#scenario-a-command-line-operation-is-rejected)
- [Scenario: an entry without its operand is rejected](#scenario-an-entry-without-its-operand-is-rejected)
- [Scenario: a script file that does not exist is rejected](#scenario-a-script-file-that-does-not-exist-is-rejected)

## Scenario: display help

- When I successfully run `../bin/topocli --help`
- Then the output is
  ```text
  usage: topocli run FILE.topo [--output FILE]
         topocli run_code FRAGMENT [--output FILE]
  run executes a TopoScript source file;
  run_code executes an inline fragment, split into
  lines at every semicolon;
  --output receives every canonical result line of the
  run, in order
  ```

## Scenario: a command-line operation is rejected

The retired command form no longer exists: an operation name on the
command line is a usage error, with the help hint on the standard error.

- When I run `../bin/topocli translate P=(10, -20, 30) D=(5, 7, -9)`
- Then the error output is
  ```text
  error: invalid command line
  try 'topocli --help'
  ```
- And there is an error

## Scenario: an entry without its operand is rejected

- When I run `../bin/topocli run`
- Then the error output is
  ```text
  error: invalid command line
  try 'topocli --help'
  ```
- And there is an error

## Scenario: a script file that does not exist is rejected

- When I run `../bin/topocli run no_such_file.topo`
- Then the error output is `error: file not found: no_such_file.topo`
- And there is an error

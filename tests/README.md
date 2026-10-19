# Tests

This directory is the working directory of `bbt`, the tool that executes
the executable documentation. `make test` runs `bbt` here, against the
scenario pages in `../docs/features/`.

The `*.in` and `*.out` files created by the scenarios and by the
application during a run are ephemeral artifacts: they are removed before
each run and are not version-controlled.

See `docs/development.md` for the complete verification workflow.

# TopoProof Makefile
#
# The complete verification chain is: build -> test -> prove.
# Run `make` or `make check` before considering any change complete.
# See README.md, AGENTS.md and docs/development.md for the workflow.

ALR ?= alr
SCENARII := ../docs/features/command-line.md \
            ../docs/features/translation.md \
            ../docs/features/displacement.md \
            ../docs/features/equality.md \
            ../docs/features/orientation.md

.SILENT:

.DEFAULT_GOAL := all
.PHONY: help all build test prove format doc check clean

help:
	echo "Usage: make [target]"
	echo ""
	echo "Targets:"
	echo "  all        : build, test and prove (default when no target given)"
	echo "  build      : compile the application (alr build)"
	echo "  test       : build, then run the Markdown documentation in"
	echo "               docs/features through bbt"
	echo "  prove      : run GNATprove on the SPARK sources"
	echo "  check      : test and prove: the complete verification chain"
	echo "  format     : reformat the Ada sources with GNATformat"
	echo "  doc        : regenerate the feature diagrams (SVG) from the"
	echo "               topodraw blocks in docs/features"
	echo "  clean      : remove the build and test artifacts"
	echo ""
	echo "Refer to AGENTS.md and docs/development.md for more details."

all: check

build:
	echo
	echo === building topoproof

	$(ALR) build

# bbt runs from tests/, where the documentation scenarios create their
# files; --cleanup removes the files created by Given steps, and the
# files created by the application in When steps are removed before the
# run so that each run starts from a clean state.
test: build
	echo
	echo === running the executable documentation

	$(ALR) exec -- sh -c 'cd tests && rm -f *.out && bbt --cleanup $(SCENARII)'

prove:
	echo
	echo === running GNATprove

	$(ALR) exec -- gnatprove -P topoproof.gpr --mode=prove --level=2 --warnings=error --report=all

format:
	echo
	echo === reformatting the sources

	$(ALR) exec -- gnatformat -P topoproof.gpr

doc:
	echo
	echo === regenerating the feature diagrams

	cd tools/topodraw && $(ALR) build
	tools/topodraw/bin/topodraw docs/features/*.md

check: test prove

clean:
	echo
	echo === cleaning

	$(ALR) clean
	rm -rf obj bin gnatprove
	find tests -name '*.in' -delete -o -name '*.out' -delete

	echo OK

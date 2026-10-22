# TopoProof Makefile
#
# The complete verification chain is: build -> test -> prove.
# Run `make` or `make check` before considering any change complete.
# See README.md, AGENTS.md and docs/development.md for the workflow.

ALR ?= alr
# The recipes use pipefail, which requires a POSIX-shell feature set that
# /bin/sh does not guarantee (dash lacks it). The shell is resolved from
# the PATH, not from an absolute path, so that a native make on Windows
# can run the recipes with Git Bash.
SHELL := bash
SCENARII := ../docs/features/command-line.md \
            ../docs/features/translation.md \
            ../docs/features/displacement.md \
            ../docs/features/equality.md \
            ../docs/features/orientation.md \
            ../docs/features/intersection.md \
            ../docs/features/contours.md \
            ../docs/features/vertices.md \
            ../docs/features/edges.md \
            ../docs/features/loops.md \
            ../docs/features/faces.md \
            ../docs/features/toposcript.md

ARTIFACTS_DIR ?= artifacts
BBT_ARTIFACTS := $(ARTIFACTS_DIR)/bbt
PROOF_ARTIFACTS := $(ARTIFACTS_DIR)/gnatprove
CHECK_EVIDENCE_DIR := tools/check-evidence
CHECK_EVIDENCE := $(CHECK_EVIDENCE_DIR)/bin/check-evidence

# GNATprove invocation, shared by every proof recipe below. Every run
# analyses the whole kernel: -U covers units not reachable from a main.
GNATPROVE := $(ALR) exec -- gnatprove
KERNEL := -P topoproof.gpr -U
# Common analysis switches: all checks, full report, warnings as errors.
ANALYSIS := --mode=all --report=all --warnings=error

# SARIF evidence for code scanning. GNATprove >= 26 takes these switches;
# the Alire index offers 16.1.0, which rejects them, so they stay here,
# ready for the toolchain upgrade.
SARIF_FILE := $(PROOF_ARTIFACTS)/gnatprove.sarif
SARIF_BASE_URI := file://$(CURDIR)/
SARIF_SWITCHES := --sarif-file=$(SARIF_FILE) --sarif-base-uri=$(SARIF_BASE_URI)

.SILENT:

.DEFAULT_GOAL := all
.PHONY: help all build release test prove prove+ proof-badge format check clean
.PHONY: evidence-dirs proof-evidence evidence-checker check-proof-evidence

help:
	echo "Usage: make [target]"
	echo ""
	echo "Targets:"
	echo "  all        : build, test and prove (default when no target given)"
	echo "  build      : compile the kernel (topoproof.gpr) and the client"
	echo "               (tools/topocli/topocli.gpr), dev profile"
	echo "  release    : build with the release profile (fast proved kernel)"
	echo "  test       : build, then run the Markdown documentation in"
	echo "               docs/features through bbt"
	echo "  prove      : run GNATprove on every kernel unit (-U, level 2)"
	echo "               and validate the proof evidence"
	echo "  prove+     : escalate unproved checks (level 4, counterexamples)"
	echo "  check      : build, test, prove and validate the evidence:"
	echo "               the complete verification chain"
	echo "  format     : reformat the Ada sources with GNATformat"
	echo "  clean      : remove the build and test artifacts"
	echo ""
	echo "Refer to AGENTS.md and docs/development.md for more details."

all: check

build:
	echo
	echo === building the topoproof kernel

	$(ALR) build
	cd tools/topocli && $(ALR) build

# Release build: run-time checks suppressed on the proved kernel (the
# silver payoff), kept on the client.
release:
	echo
	echo === building topoproof and topocli, release profile

	$(ALR) exec -- gprbuild -P topoproof.gpr -XTopoproof_Build_Profile=release
	$(ALR) exec -- gprbuild -P tools/topocli/topocli.gpr -XTopoproof_Build_Profile=release

# bbt runs from tests/, where the documentation scenarios create their
# files; --cleanup removes the files created by Given steps, and the
# files created by the application in When steps are removed before the
# run so that each run starts from a clean state. The complete output
# is teed to $(BBT_ARTIFACTS)/results.log as reviewable evidence.
test: build evidence-dirs
	echo
	echo === running the executable documentation

	$(ALR) exec -- bash -c 'set -o pipefail; cd tests && rm -f *.out && bbt --cleanup=full --yes --index ../docs/tests/results.md --generate_badge ../$(BBT_ARTIFACTS)/badge.url $(SCENARII) 2>&1 | tee ../$(BBT_ARTIFACTS)/results.log'
	# The bbt run stores the scenario paths as given on the command
	# line, relative to tests/: reanchored to the index location, the
	# links resolve from docs/tests/results.md. The reanchoring goes
	# through a temporary file and a move: sed -i has no portable
	# syntax across its BSD and GNU implementations.
	sed 's|](\.\./docs/features/|](\.\./features/|g' docs/tests/results.md > docs/tests/results.tmp
	mv docs/tests/results.tmp docs/tests/results.md
	# The tests badge of the README: the bbt run writes the shields.io
	# URL of the badge, and the badge is fetched from it, published with
	# the repository through docs/tests/badge.svg. Like every evidence,
	# the committed file must match the fresh run.
	curl -s -o docs/tests/badge.svg "$$(cat $(BBT_ARTIFACTS)/badge.url)" 

evidence-dirs:
	mkdir -p $(BBT_ARTIFACTS) $(PROOF_ARTIFACTS)

# The -U switch analyses every kernel unit, including units not reachable
# from a main. --checks-as-errors makes an unproved check fail the command.
# --output-header stamps the generated gnatprove.out with the date, host
# and command line: the evidence identifies the machine that produced it.
# SARIF: add $(SARIF_SWITCHES) to the command when GNATprove >= 26 lands
# in the Alire index, and copy $(SARIF_FILE) next to the other evidence.
proof-evidence: evidence-dirs
	$(GNATPROVE) --version > $(PROOF_ARTIFACTS)/version.txt
	printf '%s\n' 'gnatprove $(KERNEL) $(ANALYSIS) --level=2 --checks-as-errors=on --assumptions --output-header' > $(PROOF_ARTIFACTS)/command.txt
	set -o pipefail; \
	$(GNATPROVE) $(KERNEL) $(ANALYSIS) \
	  --level=2 \
	  --checks-as-errors=on \
	  --assumptions \
	  --output-header \
	  2>&1 | tee $(PROOF_ARTIFACTS)/results.log
	cp obj/gnatprove/gnatprove.out $(PROOF_ARTIFACTS)/gnatprove.out
	$(GNATPROVE) $(KERNEL) --output-msg-only --assumptions \
	  > $(PROOF_ARTIFACTS)/assumptions.log

# The evidence gate itself is an Ada program, built with the same
# warnings-as-errors policy as the kernel and the client, so the
# verification chain needs no scripting language beyond the GNAT
# toolchain.
evidence-checker:
	$(ALR) exec -- gprbuild -P $(CHECK_EVIDENCE_DIR)/check_evidence.gpr

check-proof-evidence: evidence-checker proof-evidence
	$(CHECK_EVIDENCE) $(PROOF_ARTIFACTS)

# The SPARK badge data of the README: the shields.io endpoint badge
# published with the repository serves this JSON, refreshed by every
# proof run. The gate summarizes the analysis: green when every check
# is proved, red as soon as one check or one flow error remains. The
# committed file is part of the reviewed change, and must always match
# the fresh evidence.
proof-badge: check-proof-evidence
	$(CHECK_EVIDENCE) $(PROOF_ARTIFACTS) > $(PROOF_ARTIFACTS)/gate-summary.log
	PROVED=$$(grep -o '[0-9]\+ checks proved' $(PROOF_ARTIFACTS)/gate-summary.log | grep -o '[0-9]\+'); \
	UNPROVED=$$(grep -o '[0-9]\+ unproved checks' $(PROOF_ARTIFACTS)/gate-summary.log | grep -o '[0-9]\+'); \
	FLOW=$$(grep -o '[0-9]\+ flow errors' $(PROOF_ARTIFACTS)/gate-summary.log | grep -o '[0-9]\+'); \
	if [ "$$UNPROVED" = "0" ] && [ "$$FLOW" = "0" ]; then \
	  printf '{"schemaVersion": 1, "label": "spark", "message": "%s checks proved", "color": "green"}\n' "$$PROVED" > proof-status.json; \
	else \
	  printf '{"schemaVersion": 1, "label": "spark", "message": "%s checks proved, %s unproved, %s flow errors", "color": "red"}\n' "$$PROVED" "$$UNPROVED" "$$FLOW" > proof-status.json; \
	fi

prove: proof-badge
	echo
	echo === running GNATprove on every kernel unit and checking the evidence

# Escalation for unproved checks: level 4 gives the provers a larger
# budget and generates counterexamples; already-proved checks are taken
# from the GNATprove cache and are not redone.
prove+:
	echo
	echo === running GNATprove, escalation level

	$(GNATPROVE) $(KERNEL) $(ANALYSIS) \
	  --level=4

format:
	echo
	echo === reformatting the sources

	$(ALR) exec -- gnatformat -P topoproof.gpr
	$(ALR) exec -- gnatformat -P tools/topocli/topocli.gpr
	$(ALR) exec -- gnatformat -P $(CHECK_EVIDENCE_DIR)/check_evidence.gpr

check: build test proof-badge

clean:
	echo
	echo === cleaning

	$(ALR) clean
	rm -rf obj bin gnatprove tools/topocli/obj \
	  $(CHECK_EVIDENCE_DIR)/obj $(CHECK_EVIDENCE_DIR)/bin
	find tests -name '*.in' -delete -o -name '*.out' -delete

	echo OK

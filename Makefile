# TopoProof Makefile
#
# The complete verification chain is: build -> test -> prove.
# Run `make` or `make check` before considering any change complete.
# See README.md, AGENTS.md and docs/dev/development_workflow.md for the workflow.

ALR ?= alr
# The recipes use pipefail, which requires a POSIX-shell feature set that
# /bin/sh does not guarantee (dash lacks it). The shell is resolved from
# the PATH, not from an absolute path, so that a native make on Windows
# can run the recipes with Git Bash.
SHELL := bash
SCENARII := ../docs/features/command-line.md \
            ../docs/features/translation.md \
            ../docs/features/displacement.md \
            ../docs/features/vectors.md \
            ../docs/features/planes.md \
            ../docs/features/orientation3d.md \
            ../docs/features/equality.md \
            ../docs/features/orientation.md \
            ../docs/features/intersection.md \
            ../docs/features/contours.md \
            ../docs/features/vertices.md \
            ../docs/features/edges.md \
            ../docs/features/loops.md \
            ../docs/features/faces.md \
            ../docs/features/faces3d.md \
            ../docs/features/shells.md \
            ../docs/features/toposcript.md

ARTIFACTS_DIR ?= artifacts
BBT_ARTIFACTS := $(ARTIFACTS_DIR)/bbt
PROOF_ARTIFACTS := $(ARTIFACTS_DIR)/gnatprove
COVERAGE_ARTIFACTS := $(ARTIFACTS_DIR)/coverage
# Coverage metric of the coverage target: stmt by default, decision or
# mcdc for stronger metrics (make coverage COVERAGE_LEVEL=decision).
COVERAGE_LEVEL ?= stmt
# Extra report formats of the coverage consolidation, next to the xcov
# annotated sources that the coverage check always produces. Any comma
# separated list of gnatcov --annotate forms applies: report (text
# summary), sarif, cobertura, xml, xcov+ (make coverage
# COVERAGE_FORMATS=report,sarif). html is not installable: the
# gnatcov_bin crate lacks the dynamic HTML support.
COVERAGE_FORMATS ?= report
# Set to on by the coverage target: the test target then runs against the
# instrumented build, and consolidates the execution traces at the end.
COVERAGE_RUN ?=
# GNATcoverage invocation, shared by every coverage recipe below. The
# tool comes from the gnatcov_bin crate (alire.toml), like gnatprove.
GNATCOV := $(ALR) exec -- gnatcov
CHECK_EVIDENCE_DIR := tools/check-evidence
CHECK_EVIDENCE := $(CHECK_EVIDENCE_DIR)/bin/check-evidence

# GNATprove invocation, shared by every proof recipe below. Every run
# analyses the whole kernel: -U covers units not reachable from a main.
GNATPROVE := $(ALR) exec -- gnatprove
KERNEL := -P topoproof.gpr -U
# Common analysis switches: all checks, full report, warnings as errors.
ANALYSIS := --mode=all --report=all --warnings=error

# The proof-result cache: gnatprove saves every successful proof result
# in this folder (--memcached-server=file:..., no server involved), and
# reuses it on later runs, even after a source change, so only the
# checks touched by the change are proved again. On a CI runner, the
# folder is saved by the workflow and restored by the next run. It
# holds no evidence: make clean removes it with obj/. The path must be
# absolute: gnatprove rejects a relative one ("no such directory"),
# whatever the working directory.
PROOF_CACHE := $(CURDIR)/obj/gnatprove-cache
# The cache is disabled on Windows: with the switch, gnatprove 16.1
# crashes in its front end on the CI runner (GNAT bug box, "unexpected
# character", reproducible run after run on the same unit), whatever
# the path form. The OS variable is Windows_NT on every Windows
# environment, and unset on Linux and macOS.
ifeq ($(OS),Windows_NT)
PROOF_CACHE_SWITCH :=
else
PROOF_CACHE_SWITCH := --memcached-server=file:$(PROOF_CACHE)
endif

# SARIF evidence for code scanning. GNATprove >= 26 takes these switches;
# the Alire index offers 16.1.0, which rejects them, so they stay here,
# ready for the toolchain upgrade.
SARIF_FILE := $(PROOF_ARTIFACTS)/gnatprove.sarif
SARIF_BASE_URI := file://$(CURDIR)/
SARIF_SWITCHES := --sarif-file=$(SARIF_FILE) --sarif-base-uri=$(SARIF_BASE_URI)

.SILENT:

.DEFAULT_GOAL := all
.PHONY: help all build release test test-run prove prove+ prove-stats proof-badge format coverage check clean
.PHONY: evidence-dirs test-run proof-evidence evidence-checker check-proof-evidence

help:
	echo "Usage: make [target]"
	echo ""
	echo "Targets:"
	echo "  all        : build, test and prove (default when no target given)"
	echo "  build      : compile the kernel (topoproof.gpr) and the client"
	echo "               (tools/topocli/topocli.gpr), dev profile"
	echo "  release    : build with the release profile (fast proved kernel)"
	echo "  test       : build, then run the Markdown documentation in"
	echo "               docs/features through bbt, and validate the"
	echo "               generated diagrams as XML"
	echo "  prove      : run GNATprove on every kernel unit (-U, level 2)"
	echo "               and validate the proof evidence"
	echo "  prove+     : escalate unproved checks (level 4, counterexamples)"
	echo "  prove-stats: run the same analysis with per-check statistics"
	echo "               (prover steps and times), to target optimizations"
	echo "  coverage   : make test against an instrumented kernel build,"
	echo "               then consolidate the GNATcoverage traces into"
	echo "               artifacts/coverage; COVERAGE_LEVEL=stmt|decision|"
	echo "               mcdc (stmt default), COVERAGE_FORMATS=report|"
	echo "               cobertura|xml|sarif (report default)"
	echo "  check      : build, test, prove and validate the evidence:"
	echo "               the complete verification chain"
	echo "  format     : reformat the Ada sources with GNATformat"
	echo "  clean      : remove the build and test artifacts"
	echo ""
	echo "Refer to AGENTS.md and docs/dev/development_workflow.md for more details."

all: check

build:
	echo
	echo === building the topoproof kernel

	$(ALR) build
	cd tools/topocli && $(ALR) build

# Release build: run-time checks suppressed on the proved kernel (the
# silver payoff), kept on the client. Each crate builds in its own
# Alire environment: the client imports HAC, which the root crate
# environment does not know.
release:
	echo
	echo === building topoproof and topocli, release profile

	$(ALR) exec -- gprbuild -P topoproof.gpr -XTopoproof_Build_Profile=release
	cd tools/topocli && $(ALR) exec -- gprbuild -P topocli.gpr -XTopoproof_Build_Profile=release

# bbt runs from tests/, where the documentation scenarios create their
# files; --cleanup removes the files created by Given steps, and the
# files created by the application in When steps are removed before the
# run so that each run starts from a clean state. The complete output
# is teed to $(BBT_ARTIFACTS)/results.log as reviewable evidence.
# The test run itself, without any build: the coverage target invokes it
# with the instrumented build in place (make test keeps the build
# prerequisite for the normal path).
test: build test-run

test-run: evidence-dirs
	echo
	echo === running the executable documentation

	$(ALR) exec -- bash -c 'set -o pipefail; cd tests && rm -f *.out && bbt --cleanup=full --yes --index ../docs/tests_results/results.md --generate_badge ../$(BBT_ARTIFACTS)/badge.url $(SCENARII) 2>&1 | tee ../$(BBT_ARTIFACTS)/results.log'

	# The bbt run stores the scenario paths as given on the command
	# line, relative to tests/: reanchored to the index location, the
	# links resolve from docs/tests_results/results.md. The reanchoring goes
	# through a temporary file and a move: sed -i has no portable
	# syntax across its BSD and GNU implementations.
	sed 's|](\.\./docs/features/|](\.\./features/|g' docs/tests_results/results.md > docs/tests_results/results.tmp
	mv docs/tests_results/results.tmp docs/tests_results/results.md

	# The tests badge of the README: the bbt run writes the shields.io
	# URL of the badge, and the badge is fetched from it, published with
	# the repository through docs/tests_results/badge.svg. Like every evidence,
	# the committed file must match the fresh run.
	curl -s -o docs/tests_results/badge.svg "$$(cat $(BBT_ARTIFACTS)/badge.url)"

	# Every generated diagram is validated as XML: a malformed SVG
	# would preview as a missing image instead of failing loudly.
	# --nonet keeps the validation offline: a document declaring an
	# external entity or DTD never triggers a network fetch. No
	# --valid: the diagrams are DTD-less by design, and DTD validation
	# would flood every run with "no DTD found" errors.
	# xmllint comes with libxml2; Linux is the platform of record.
	command -v xmllint >/dev/null 2>&1 || { echo "error: xmllint is required (libxml2-utils)"; exit 1; }
	xmllint --nonet --noout docs/features/images/*.svg
	echo "  $$(ls docs/features/images/*.svg | wc -l) diagrams well formed"

ifeq ($(COVERAGE_RUN),on)
	# Coverage consolidation, on the run that just went through the
	# instrumented build (see the coverage target): every topocli
	# invocation wrote a trace in $(COVERAGE_ARTIFACTS)/traces. The
	# "no SID file found" warnings are expected: they list the units
	# outside the analysis scope (client, HAC). The whole output, report
	# formats included, is teed to coverage.log as reviewable evidence
	# (the report format prints on standard output, it writes no file).
	cd tools/topocli && $(ALR) exec -- bash -c 'set -o pipefail; \
	  export GPR_PROJECT_PATH="$$GPR_PROJECT_PATH:$(CURDIR)/obj/coverage/rts/share/gpr"; \
	  gnatcov coverage -P topocli.gpr --level=$(COVERAGE_LEVEL) \
	    --annotate=xcov,$(COVERAGE_FORMATS) \
	    --output-dir=$(CURDIR)/$(COVERAGE_ARTIFACTS) \
	    $(CURDIR)/$(COVERAGE_ARTIFACTS)/traces/*.srctrace \
	    2>&1 | sed "/no SID file found/d" | tee $(CURDIR)/$(COVERAGE_ARTIFACTS)/coverage.log'

	# The check: the global statement coverage, summed from the per-unit
	# xcov summaries ("N% statement coverage (a out of b)"). The xcov
	# files are searched wherever gnatcov dropped them this run: at the
	# root of the output dir, or in a per-format subdirectory when
	# COVERAGE_FORMATS repeats xcov or combines formats. The summary
	# goes to the console, and to coverage-status.json: the coverage
	# badge data of the README, served by the shields.io endpoint badge
	# through the committed file, like the SPARK one. The committed file
	# is part of the reviewed change, and must always match the fresh
	# evidence; green from 90% statements on.
	find $(COVERAGE_ARTIFACTS) -name '*.xcov' -print0 \
	  | xargs -0 -r grep -h "statement coverage (" \
	  | awk '{ gsub(/[()]/, ""); \
	           for (i = 1; i <= NF; i++) \
	             if ($$i == "out") { covered += $$(i - 1); total += $$(i + 2) } } \
	         END { if (total <= 0) { \
	                 print "error: no coverage data found"; exit 1 } \
	               pct = 100 * covered / total; \
	               color = (pct >= 90) ? "green" : (pct >= 75) ? "orange" : "red"; \
	               printf "kernel statement coverage: %d/%d statements (%.1f%%)\n", \
	                      covered, total, pct; \
	               printf "{\"schemaVersion\": 1, \"label\": \"coverage\", " \
	                      "\"message\": \"%.1f%% statements\", \"color\": \"%s\"}\n", \
	                      pct, color > "coverage-status.json" }'
endif

evidence-dirs:
	mkdir -p $(BBT_ARTIFACTS) $(PROOF_ARTIFACTS) $(PROOF_CACHE)

# The -U switch analyses every kernel unit, including units not reachable
# from a main. --checks-as-errors makes an unproved check fail the command.
# --output-header stamps the generated gnatprove.out with the date, host
# and command line: the evidence identifies the machine that produced it.
# SARIF: add $(SARIF_SWITCHES) to the command when GNATprove >= 26 lands
# in the Alire index, and copy $(SARIF_FILE) next to the other evidence.
proof-evidence: evidence-dirs
	$(GNATPROVE) --version > $(PROOF_ARTIFACTS)/version.txt
	printf '%s\n' 'gnatprove $(KERNEL) $(ANALYSIS) --level=2 --checks-as-errors=on --assumptions --output-header $(PROOF_CACHE_SWITCH)' > $(PROOF_ARTIFACTS)/command.txt
	set -o pipefail; \
	$(GNATPROVE) $(KERNEL) $(ANALYSIS) \
	  --level=2 \
	  --checks-as-errors=on \
	  --assumptions \
	  --output-header \
	  $(PROOF_CACHE_SWITCH) \
	  2>&1 | tee $(PROOF_ARTIFACTS)/results.log
	cp obj/gnatprove/gnatprove.out $(PROOF_ARTIFACTS)/gnatprove.out
	$(GNATPROVE) $(KERNEL) --output-msg-only --assumptions \
	  $(PROOF_CACHE_SWITCH) \
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

# The escalation reuses the level-2 results saved in the cache.
	mkdir -p $(PROOF_CACHE)
	$(GNATPROVE) $(KERNEL) $(ANALYSIS) \
	  --level=4 \
	  $(PROOF_CACHE_SWITCH)

# Proof statistics: the same analysis as `make prove`, with
# --report=statistics, so every proved check reports the number of
# prover steps and its time, and the report lists the most difficult
# checks. The run writes to the isolated obj/stats (--subdirs), so the
# canonical evidence of obj/gnatprove is left untouched; the report is
# kept with the other proof artifacts. No --assumptions: that extra pass
# produces no statistics and doubles the wall time.
prove-stats: evidence-dirs
	echo
	echo === collecting the proof statistics

	$(ALR) exec -- bash -c 'set -o pipefail; gnatprove $(KERNEL) --mode=all --report=statistics --warnings=error --level=2 --output-header --subdirs=stats $(PROOF_CACHE_SWITCH) 2>&1 | tee $(PROOF_ARTIFACTS)/prove-stats.log'
	cp obj/stats/gnatprove/gnatprove.out $(PROOF_ARTIFACTS)/gnatprove-stats.out
	echo
	echo The most difficult proved checks:
	sed -n '/Most difficult proved checks/,+12p' $(PROOF_ARTIFACTS)/gnatprove-stats.out
	sed -n 's/^max steps used for successful proof: /max steps used for a successful proof: /p' $(PROOF_ARTIFACTS)/gnatprove-stats.out

# Test coverage of the proved kernel with GNATcoverage (gnatcov_bin crate):
# the executable documentation runs against an instrumented kernel build
# through the client — the test target itself, invoked with COVERAGE_RUN=on
# so the whole suite runs once, producing the badge, the index and the
# traces together — and the test target consolidates the traces at the end.
# The instrumented sources live in <objdir>/...gnatcov-instr and share the
# obj/ directories with the normal build: the target ends with a clean
# rebuild, leaving the normal (uninstrumented) binaries in place.
# Only the kernel is instrumented (--projects): the client and the HAC
# interpreter stay out of the analysis scope, the mains are instrumented
# anyway, since they dump the traces.
# The normal build goes first: it synchronizes both Alire workspaces,
# so the nested client crate resolves its HAC dependency before the
# instrumentation runs — a fresh clone has no resolved client crate,
# and gnatcov instrument would fail to load topocli.gpr (observed on
# the CI runner).
coverage: build evidence-dirs
	echo
	echo === collecting the kernel test coverage, $(COVERAGE_LEVEL) level

	# Fresh traces only: traces of a previous run belong to another
	# instrumentation session (other counters, other SIDs) and would
	# corrupt the consolidation. The consolidated reports stay in place:
	# they are only overwritten by the fresh run, and make doc may read
	# them (make clean is the only step that removes them).
	rm -f $(COVERAGE_ARTIFACTS)/traces/*.srctrace
	mkdir -p $(COVERAGE_ARTIFACTS)/traces

	# The instrumentation runtime, installed in obj/ (make clean removes
	# it with the rest of the build state).
	$(GNATCOV) setup --prefix=$(CURDIR)/obj/coverage/rts

	# Instrument the kernel, from the client crate (its Alire
	# environment resolves the HAC import). The RTS location goes through
	# GPR_PROJECT_PATH, so gprbuild resolves gnatcov_rts.gpr below, and
	# gnatcov coverage finds the same installation. The stale instrumented
	# copies go first: instrumented sources of a previous run (other
	# counters, other SIDs, or units out of the current scope) would
	# shadow the real ones, through the source subdirectory mechanism.
	rm -rf $(CURDIR)/obj/*-gnatcov-instr $(CURDIR)/tools/topocli/obj/*-gnatcov-instr
	cd tools/topocli && $(ALR) exec -- bash -c 'set -o pipefail; \
	  export GPR_PROJECT_PATH="$$GPR_PROJECT_PATH:$(CURDIR)/obj/coverage/rts/share/gpr"; \
	  gnatcov instrument -P topocli.gpr \
	    --level=$(COVERAGE_LEVEL) \
	    --projects=$(CURDIR)/topoproof.gpr \
	    --dump-trigger=atexit \
	    --dump-filename-prefix=$(CURDIR)/$(COVERAGE_ARTIFACTS)/traces/topocli'
	# Build through the client, instrumented sources first: --src-subdirs
	# must always be exactly gnatcov-instr (GNATcoverage user guide) —
	# gprbuild 26 resolves the <project>-gnatcov-instr directories itself,
	# through the gnatcov-instr.json marker that instrument drops in the
	# object directories. The kernel and client objects are removed by
	# hand instead of forcing a full rebuild (-f): HAC is not instrumented,
	# its objects stay valid, and its style warnings stay out of the run.
	rm -f obj/*.o obj/*.ali tools/topocli/obj/*.o tools/topocli/obj/*.ali
	cd tools/topocli && $(ALR) exec -- bash -c 'set -o pipefail; \
	  export GPR_PROJECT_PATH="$$GPR_PROJECT_PATH:$(CURDIR)/obj/coverage/rts/share/gpr"; \
	  gprbuild -p -P topocli.gpr --src-subdirs=gnatcov-instr \
	    --implicit-with=gnatcov_rts.gpr'

	# The whole suite, once: badge, index and traces together.
	$(MAKE) --no-print-directory test-run COVERAGE_RUN=on

	# Restore the normal build: the instrumented objects share obj/ with
	# the plain ones, so the kernel and client object trees are removed
	# and rebuilt uninstrumented. No gnatclean -r: it would also wipe the
	# HAC objects of the shared Alire build cache, and the next build
	# would recompile the whole interpreter (and resurface its style
	# warnings, which are HAC's own business).
	rm -f obj/*.o obj/*.ali tools/topocli/obj/*.o tools/topocli/obj/*.ali
	rm -rf obj/*-gnatcov-instr tools/topocli/obj/*-gnatcov-instr
	$(MAKE) --no-print-directory build

format:
	echo
	echo === reformatting the sources

	$(ALR) exec -- gnatformat -P topoproof.gpr
	cd tools/topocli && $(ALR) exec -- gnatformat -P topocli.gpr
	$(ALR) exec -- gnatformat -P $(CHECK_EVIDENCE_DIR)/check_evidence.gpr

check: build test proof-badge

clean:
	echo
	echo === cleaning

	$(ALR) clean
	rm -rf obj bin gnatprove tools/topocli/obj \
	  $(CHECK_EVIDENCE_DIR)/obj $(CHECK_EVIDENCE_DIR)/bin \
	  $(COVERAGE_ARTIFACTS)
	find tests -name '*.in' -delete -o -name '*.out' -delete

	echo OK

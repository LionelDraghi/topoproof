ALR ?= alr
BBT_DOCS := ../docs/command-line.md ../docs/translation.md ../docs/displacement.md
.PHONY: all build test prove format check clean
all: check
build:
	$(ALR) build
test: build
	cd tests && $(ALR) exec -- bbt $(BBT_DOCS)
prove:
	cd tests && $(ALR) exec -- gnatprove -P ../topoproof.gpr --mode=prove --level=2 --warnings=error --report=all
format:
	cd tests && $(ALR) exec -- gnatformat -P ../topoproof.gpr
check: build test prove
clean:
	$(ALR) clean
	cd tests && $(ALR) clean
	rm -rf obj bin tests/*.in tests/*.out gnatprove

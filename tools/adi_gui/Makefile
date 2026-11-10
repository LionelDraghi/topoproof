# =============================================================================
#  TopoProof, provable geometry application
#  (https://github.com/LionelDraghi/topoproof)
#  SPDX-License-Identifier: Apache-2.0
#  SPDX-FileCopyrightText: 2026, Lionel Draghi
# =============================================================================
#  Adi_GUI, the graphical client of the proved kernel (DD-006). See
#  AGENTS.md for the project rules and commands.

.PHONY: all check build clean help

all: check

#  The verification chain of the GUI: one build, warnings as errors.
#  There is no test and no prove target here: the GUI deliverable is
#  the executable, tested headlessly through TopoScript and manually
#  by the owner (AGENTS.md, exceptions).

check: build

build:
	alr exec -- gprbuild -s -j0 \
		-XADI_BUILD_PROFILE=development \
		-XADI_PLATFORM=linux \
		-XAdi_Gui_Build_Profile=development \
		-P adi_gui.gpr

clean:
	alr clean

help:
	@echo "Adi_GUI (the graphical client of the proved TopoProof kernel)"
	@echo
	@echo "  make all    the complete chain: build (default target)"
	@echo "  make check  the verification chain: build, warnings as errors"
	@echo "  make build  the development profile build (AGENTS.md command)"
	@echo "  make clean  remove obj/ and the executable (alr clean)"
	@echo
	@echo "  run:        ./adi_gui (owner testing; MCP channel when built"
	@echo "              in the development profile)"


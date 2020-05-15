THIS_DIR := $(patsubst %/,%,$(dir $(realpath $(firstword $(MAKEFILE_LIST)))))
QUIET ?= @

ifeq ($(OS),Windows_NT)
  SHELL := pwsh.exe
  THIS_DIR := $(subst /,\,$(THIS_DIR))
  PATH := $(PATH);$(THIS_DIR)\test\bin
else
  SHELL := /bin/bash
  PATH := $(PATH):$(THIS_DIR)/test/bin
endif

SHELLCHECK_IGNORE := \
  *.bats \
  *.conf \
  *.config \
  *.md \
  *.keep \
  *.ps1 \
  *gitconfig \
  *gitignore \
  Makefile \
  home/* \
  windows-home/* \
  test/fixtures/*

SHELLCHECK_GIT_IGNORE := $(addsuffix ',$(addprefix ':!:,$(SHELLCHECK_IGNORE)))

PS_SCRIPT_ANALYZER_INCLUDE := \
  *.ps1 \
  *.ps1xml \
  *.psc1 \
  *.psd1 \
  *.psm1 \
  *.pssc \
  *.cdxml

PS_SCRIPT_ANALYZER_GIT_INCLUDE := $(addsuffix ',$(addprefix ':,$(PS_SCRIPT_ANALYZER_INCLUDE)))

.PHONY: guards
guards: guards-bash guards-posh

.PHONY: test
test: test-bash test-posh

.PHONY: lint
lint: lint-bash lint-posh

.PHONY: guards-bash
guards-bash: test-bash lint-bash

# NOTE: No scoop port of bats so need to wrap in bash call for windows
.PHONY: test-bash
test-bash:
ifeq ($(OS),Windows_NT)
	bash -c "bats --pretty --recursive test/"
else
	bats --pretty --recursive test/
endif

.PHONY: lint-bash
lint-bash:
	shellcheck $(shell git ls-files -- . $(SHELLCHECK_GIT_IGNORE))

.PHONY: guards-posh
guards-posh: test-posh lint-posh

# NOTE:
#   GNU make will not invoke a shell if it's not convinced that a shell is required.
#   It will be convinced if the command includes any of the predefined commands or characters.
#   Both parentheses and ampersand trigger the need for invoking a shell,
#   lack of those make make believe that the command/cmdlet is a binary to run,
#   so it tries to invoke it directly with CreateProcess
#   See predefined lists:
#     - sh: http://git.savannah.gnu.org/cgit/make.git/tree/src/job.c#n2799
#     - dos: http://git.savannah.gnu.org/cgit/make.git/tree/src/job.c#n2774
#     - unix shells: http://git.savannah.gnu.org/cgit/make.git/tree/src/job.c#n428
#
.PHONY: test-posh
test-posh:
	$(QUIET)(pester.ps1)

.PHONY: lint-posh
lint-posh:
	@echo "poshcheck.ps1 $(shell git ls-files -- $(PS_SCRIPT_ANALYZER_GIT_INCLUDE))"
	${QUIET}(poshcheck.ps1 $(shell git ls-files -- $(PS_SCRIPT_ANALYZER_GIT_INCLUDE)))

SHELL := /bin/bash
PATH := $(PATH):$(PWD)/test/bin

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

.PHONY: test-bash
test-bash:
	bats --pretty --recursive test/

.PHONY: lint-bash
lint-bash:
	shellcheck $$(git ls-files -- . $(SHELLCHECK_GIT_IGNORE))

.PHONY: guards-posh
guards-posh: test-posh lint-posh

.PHONY: test-posh
test-posh:
	pwsh -Command 'Invoke-Pester test/ -EnableExit'

.PHONY: lint-posh
lint-posh:
	poshcheck.ps1 $$(git ls-files -- $(PS_SCRIPT_ANALYZER_GIT_INCLUDE))
